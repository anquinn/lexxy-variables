module LexxyVariables
  # Mixed into Action View by the engine. `context` is opaque to the gem and is
  # passed straight through to the host's catalog/assigns/resolve callables.
  module Helper
    def render_lexxy_content(rich_text, context: nil, locale: I18n.locale)
      LexxyVariables::Pipeline.new(self).call(rich_text, context: context, locale: locale)
    end

    # Renders the <lexxy-prompt> the editor extension reads, built from the
    # configured catalog. `context` is passed to the catalog callable.
    def lexxy_variables_prompt(context: nil, trigger: "{{", empty_results: "No variables found")
      items = Array(LexxyVariables.config.resolve_catalog(context))
      render partial: "lexxy_variables/prompt",
             locals: { items: items, trigger: trigger, empty_results: empty_results }
    end

    # Default variable/attachment chip shown in the editor. `block:` renders the
    # block style, for chips that expand to a rich fragment (e.g. snippets).
    def lexxy_variable_chip(name, key:, block: false)
      tag.span name,
        class: [ "lexxy-variable", ("lexxy-variable--block" if block) ],
        data: { lexxy_key: key }
    end
  end
end
