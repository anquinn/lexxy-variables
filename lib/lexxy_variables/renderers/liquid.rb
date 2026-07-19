module LexxyVariables
  module Renderers
    # Opt-in renderer that resolves each key through Liquid, enabling dotted
    # access, drops (e.g. {{ company.name }}), and filters. Requires the `liquid`
    # gem. It is loaded here, when a host instantiates this renderer, so apps on
    # the default renderer never pull it in.
    #
    # Security: only the chip's key is parsed as a Liquid template, never body
    # text, so {{ }} or {% %} an author types stays literal. The resolved value
    # is injected as a DOM text node and escaped per output format by the
    # resolver, so drops must NOT pre-escape their values.
    #
    # `assigns` is the Hash passed to Liquid: string values and/or Liquid::Drop
    # instances.
    class Liquid
      def initialize(error_mode: :lax)
        require "liquid"
        @error_mode = error_mode
      end

      def resolve_value(key, assigns)
        ::Liquid::Template.parse("{{ #{key} }}", error_mode: @error_mode).render(assigns)
      end
    end
  end
end
