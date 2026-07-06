module LexxyVariables
  module Renderers
    # Default renderer. Replaces nonce placeholders with resolved values by plain
    # string substitution. There is no template engine, so author-typed text can
    # never be interpreted as code. Each value is HTML-escaped, so it is inert and
    # cannot reintroduce markup the sanitizer already stripped.
    #
    # `assigns` is a Hash of key => value. Values are coerced to escaped strings.
    class Substitution
      def render(html, nonce:, assigns:)
        html.gsub(Placeholder.pattern(nonce)) { ERB::Util.html_escape(assigns[$1].to_s) }
      end
    end
  end
end
