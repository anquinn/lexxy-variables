module LexxyVariables
  # Turns stored rich text into rendered HTML with attachment chips resolved.
  #
  # Security invariants (do not weaken):
  #   1. A random per-render nonce guards placeholder tokens, so an author cannot
  #      forge a substitution by typing the token pattern into the body.
  #   2. Attachments are swapped for nonce tokens BEFORE sanitization and resolved
  #      values are injected AFTER. :text output is HTML-escaped and therefore
  #      inert. :html output is spliced pre-sanitize so the sanitizer cleans it.
  #   3. Any template-engine escaping (Liquid braces) lives only in that renderer.
  #
  # Needs a view context (self, from the helper) for Action Text rendering.
  # Build a fresh Pipeline per render, as the helper does. #call stores
  # per-render state on the instance.
  class Pipeline
    def initialize(view, config = LexxyVariables.config)
      @view = view
      @config = config
    end

    def call(rich_text, context: nil, locale: I18n.locale)
      body = rich_text&.body
      return "".html_safe if body.blank?

      @context = context
      @nonce = SecureRandom.hex(8)
      @used_keys = []

      I18n.with_locale(locale || I18n.locale) do
        fragment = substitute(body.fragment, 0)
        html = @view.render_action_text_content(
          ActionText::Content.new(fragment.to_html, canonicalize: false)
        )

        assigns = @config.resolve_assigns(@context, @used_keys.uniq)
        rendered = @config.renderer.render(html, nonce: @nonce, assigns: assigns)

        @view.render(layout: @config.content_layout) { rendered.html_safe }
      end
    end

    private

    def substitute(fragment, depth)
      fragment.replace(ActionText::Attachment.tag_name) do |node|
        type = @config.registry.match(node)
        next node unless type # images, files, and unknown attachments pass through

        if type.renders_as_text?
          resolve_text(node, type)
        elsif type.renders_as_html?
          resolve_html(node, type, depth)
        else
          node
        end
      end
    end

    def resolve_text(node, type)
      key = type.resolve.call(node, @context)
      return empty_text(node) if key.nil?

      @used_keys << key
      Nokogiri::XML::Text.new(Placeholder.token(@nonce, key), node.document)
    end

    def resolve_html(node, type, depth)
      return empty_text(node) if depth >= @config.max_fragment_depth

      inner = coerce_fragment(type.resolve.call(node, @context))
      return empty_text(node) if inner.nil?

      substitute(inner, depth + 1)
    end

    # Accepts whatever a :html resolver returns (ActionText content, rich
    # text, a Nokogiri node, or an HTML string) and coerces it to the
    # ActionText::Fragment that #substitute needs, or nil to drop the chip.
    # The Nokogiri checks come before the respond_to? checks because Nokogiri
    # nodes also respond to #fragment, with different behavior.
    def coerce_fragment(value)
      return nil if value.nil?
      return nil if value.respond_to?(:blank?) && value.blank?
      return value if value.is_a?(ActionText::Fragment)
      return ActionText::Fragment.wrap(value) if value.is_a?(Nokogiri::XML::DocumentFragment)
      return ActionText::Fragment.from_html(value.to_html) if value.is_a?(Nokogiri::XML::Node)
      return value.fragment if value.respond_to?(:fragment)         # ActionText::Content
      return value.body&.fragment if value.respond_to?(:body)       # ActionText::RichText

      ActionText::Fragment.from_html(value.to_s)
    end

    def empty_text(node)
      Nokogiri::XML::Text.new("", node.document)
    end
  end
end
