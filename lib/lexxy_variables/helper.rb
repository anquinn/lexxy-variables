module LexxyVariables
  # Editor-side view helpers. LexxyVariables::Engine includes this module into
  # Action View when the host app boots, so lexxy_variables_prompt and
  # lexxy_variable_chip are callable from any view with no setup. `context` is
  # opaque to the gem and is passed straight through to the host's catalog.
  module Helper
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
