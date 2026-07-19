module LexxyVariables
  # Resolves the attachment chips in stored rich text, returning a new
  # ActionText::Content with every chip replaced by its value. The result is a
  # plain content object, so Action Text's own conversions chain from it:
  # #to_s (sanitized HTML), #to_plain_text, #to_markdown, #to_html.
  #
  # Security invariants (do not weaken):
  #   1. A random per-render nonce guards placeholder tokens, so an author cannot
  #      forge a substitution by typing the token pattern into the body.
  #   2. Resolved values are injected as DOM text nodes, never parsed as markup.
  #      HTML serialization escapes them, and the sanitizer still runs when the
  #      content is rendered. :html output is spliced as markup here, before that
  #      render-time sanitization, so the sanitizer cleans it too.
  #   3. Any template-engine parsing (Liquid) sees only chip keys, never body text.
  #
  # Build a fresh Resolver per call. #call stores per-render state on the instance.
  class Resolver
    def initialize(config = LexxyVariables.config)
      @config = config
    end

    def call(content, context: nil, locale: nil, assigns: {})
      @context = context
      @nonce = SecureRandom.hex(8)
      @used_keys = []

      I18n.with_locale(locale || I18n.locale) do
        fragment = substitute(content.fragment, 0)
        resolved = @config.resolve_assigns(@context, @used_keys.uniq)
        resolved = resolved.merge(assigns.transform_keys(&:to_s)) if assigns.any?
        inject_values(fragment, resolved)
        ActionText::Content.new(fragment, canonicalize: false)
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

    # Swaps each nonce-guarded token for its value, staying at the text-node
    # level so values serialize as escaped text and read back raw in plain-text
    # and markdown conversions. #substitute returned a fresh fragment, so
    # mutating it in place is safe.
    def inject_values(fragment, assigns)
      pattern = Placeholder.pattern(@nonce)
      fragment.source.traverse do |node|
        next unless node.text? && node.content.match?(pattern)

        node.content = node.content.gsub(pattern) { @config.renderer.resolve_value($1, assigns) }
      end
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
