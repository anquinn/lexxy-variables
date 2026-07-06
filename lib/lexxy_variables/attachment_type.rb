module LexxyVariables
  # Describes one kind of attachment chip the pipeline knows how to resolve.
  # A chip is identified solely by its content-type, which the editor always
  # writes and the model always persists.
  #
  # phase:
  #   :value    the resolver returns a String key. The pipeline records it, emits
  #             a nonce-protected placeholder, and later substitutes the resolved
  #             HTML-escaped value. Safe by construction. Variables use this.
  #   :fragment the resolver returns rich content (ActionText content, RichText,
  #             or an HTML String) spliced into the document BEFORE sanitization,
  #             so the sanitizer cleans it and inner :value chips resolve in the
  #             same pass. Snippets use this. Bounded by max_fragment_depth.
  #
  # resolve: ->(node, context) { ... } returning a key (:value) or rich content
  #   (:fragment), or nil to drop the chip.
  #
  # label: optional short type name (e.g. "Variable", "Snippet"). The prompt shows
  #   it as a badge only when the list mixes more than one type, so users can tell
  #   them apart without noise when there is only one. nil shows no badge.
  AttachmentType = Struct.new(:content_type, :phase, :resolve, :label, keyword_init: true) do
    def value?    = phase == :value
    def fragment? = phase == :fragment
  end
end
