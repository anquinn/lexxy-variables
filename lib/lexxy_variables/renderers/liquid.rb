module LexxyVariables
  module Renderers
    # Opt-in renderer that resolves placeholders through Liquid, enabling dotted
    # access, drops (e.g. {{ company.name }}), and filters. Requires the `liquid`
    # gem. It is loaded here, when a host instantiates this renderer, so apps on
    # the default renderer never pull it in.
    #
    # Security: because Liquid does interpret {{ }} and {% %}, any such syntax the
    # author typed as plain text is entity-escaped BEFORE our own placeholders are
    # revealed, so users cannot forge Liquid. Only the nonce-protected placeholders
    # this pipeline emitted become real Liquid tags.
    #
    # `assigns` is the Hash passed to Liquid: string values and/or Liquid::Drop
    # instances. Drops must escape their own output, since Liquid output is emitted
    # html_safe after sanitization.
    class Liquid
      def initialize(error_mode: :lax)
        require "liquid"
        @error_mode = error_mode
      end

      def render(html, nonce:, assigns:)
        html = html.gsub("{{", "&#123;&#123;").gsub("{%", "&#123;%")
        html = html.gsub(Placeholder.pattern(nonce)) { "{{ #{$1} }}" }

        ::Liquid::Template.parse(html, error_mode: @error_mode).render(assigns)
      end
    end
  end
end
