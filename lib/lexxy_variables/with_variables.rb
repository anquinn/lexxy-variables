module LexxyVariables
  # Mixed into ActionText::Content via the :action_text_content load hook.
  module WithVariables
    # Returns a new ActionText::Content with every variable chip resolved, so
    # Action Text's own conversions chain from the result:
    #
    #   @post.body.with_variables(first_name: "Ada").to_plain_text
    #   @post.body.with_variables(context: tenant).to_s
    #   @post.body.with_variables.to_markdown  # on Rails versions that ship it
    #
    # Takes `context:`, `locale:`, and per-render values as keyword args or an
    # `assigns:` hash.
    def with_variables(context: nil, locale: nil, assigns: {}, **inline_assigns)
      LexxyVariables::Resolver.new.call(
        self, context: context, locale: locale, assigns: assigns.merge(inline_assigns)
      )
    end
  end

  # Mixed into ActionText::RichText via the :action_text_rich_text load hook,
  # so `@post.body.with_variables` works straight off the association.
  module RichTextWithVariables
    def with_variables(context: nil, locale: nil, assigns: {}, **inline_assigns)
      (body || ActionText::Content.new(nil, canonicalize: false))
        .with_variables(context: context, locale: locale, assigns: assigns.merge(inline_assigns))
    end
  end
end

ActiveSupport.on_load(:action_text_content) { include LexxyVariables::WithVariables }
ActiveSupport.on_load(:action_text_rich_text) { include LexxyVariables::RichTextWithVariables }
