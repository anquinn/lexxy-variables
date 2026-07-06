module LexxyVariables
  # Host-supplied policy. The gem ships working defaults, so the smallest
  # integration is just `config.catalog = [...]`. Everything else is optional.
  #
  #   LexxyVariables.configure do |c|
  #     c.catalog = [ { key: "company", name: "Company", value: "Acme" } ]
  #   end
  #
  # catalog: the insertable items for the editor prompt. A list, a zero-arg
  #   callable, or a ->(context) callable. Items respond to #key, #name,
  #   optional #value (used by the default assigns), and #attachable_sgid.
  # assigns: ->(context, used_keys) or ->(used_keys) returning a Hash of
  #   key => value for a render. Omit to read #value off catalog items.
  # renderer: Renderers::Substitution (default, no Liquid) or Renderers::Liquid.
  # max_fragment_depth: how deep :fragment chips (e.g. snippets) expand. The
  #   default of 1 resolves a snippet's inner variables and drops nested snippets.
  # content_layout: the ActionText content layout wrapper for rendered output.
  # sort: how the catalog is ordered in the prompt and dropdown. Defaults to
  #   :name (case-insensitive alphabetical). Use :key to sort by key, false to
  #   preserve the catalog's given order, or a callable: a ->(item) sort key, or
  #   a ->(a, b) comparator.
  class Configuration
    attr_accessor :assigns, :renderer, :content_layout, :max_fragment_depth, :sort
    attr_reader :registry
    attr_writer :catalog

    def initialize
      @registry = Registry.new
      @renderer = Renderers::Substitution.new
      @content_layout = "layouts/action_text/contents/content"
      @max_fragment_depth = 1
      @catalog = []
      @sort = :name
      register_default_variable_type
    end

    # Adds or overrides an attachment type. Variables are pre-registered. A host
    # calls this to add types like snippets, or to override the variable resolver.
    # `label` is an optional badge name shown in the prompt when types are mixed.
    def register_attachment(content_type:, phase:, resolve:, label: nil)
      registry.register(AttachmentType.new(content_type:, phase:, resolve:, label:))
    end

    def resolve_catalog(context)
      sort_catalog(Array(call_with_context(@catalog, context)))
    end

    def resolve_assigns(context, keys)
      return default_assigns(context, keys) unless @assigns

      if @assigns.arity == 1
        @assigns.call(keys)
      else
        @assigns.call(context, keys)
      end
    end

    private

    # The gem's built-in variable resolver. Prefers an sgid-backed attachable
    # (models that respond to #key), and otherwise falls back to the key that
    # lexxy_variable_chip embeds as data-lexxy-key in the chip content. The
    # fallback is what makes a plain-hash catalog (no sgid) resolve. Hosts with
    # extra policy (e.g. tenant scoping) override this by re-registering the type.
    def register_default_variable_type
      register_attachment(
        content_type: LexxyVariables::VARIABLE_CONTENT_TYPE,
        phase: :value,
        resolve: ->(node, _context) {
          attachable = LexxyVariables.attachable_from(node)
          next attachable.key if attachable.respond_to?(:key)

          LexxyVariables.chip_key(node)
        }
      )
    end

    # Default value resolution: look each used key up in the catalog and read
    # #value. Used only when no custom `assigns` is configured.
    def default_assigns(context, keys)
      items = Array(resolve_catalog(context))
      keys.each_with_object({}) do |key, hash|
        item = items.find { |i| LexxyVariables.item_key(i) == key }
        hash[key] = LexxyVariables.item_value(item) if item
      end
    end

    # Orders the resolved catalog per the `sort` policy. Both the prompt DOM and
    # the dropdown read from this, so ordering stays consistent across them.
    def sort_catalog(items)
      case @sort
      when nil, false
        items
      when :name
        items.sort_by { |item| LexxyVariables.item_name(item).to_s.downcase }
      when :key
        items.sort_by { |item| LexxyVariables.item_key(item).to_s.downcase }
      else
        if @sort.arity == 1
          items.sort_by { |item| @sort.call(item) }
        else
          items.sort { |a, b| @sort.call(a, b) }
        end
      end
    end

    def call_with_context(value, context)
      return value unless value.respond_to?(:call)

      if value.arity == 0
        value.call
      else
        value.call(context)
      end
    end
  end
end
