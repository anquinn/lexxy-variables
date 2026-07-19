module LexxyVariables
  module Renderers
    # Default renderer. Looks each key up in the assigns hash, no template
    # engine, so author-typed text can never be interpreted as code. The value
    # is returned raw: the resolver injects it as a DOM text node, where HTML
    # serialization escapes it and plain-text/markdown conversions read it as-is.
    class Substitution
      def resolve_value(key, assigns)
        assigns[key].to_s
      end
    end
  end
end
