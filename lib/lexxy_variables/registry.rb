module LexxyVariables
  # Maps a chip's content-type to the attachment type that resolves it.
  # Registering the same content-type again overrides the previous entry, so a
  # host can replace a built-in type (e.g. variables) or add new ones (snippets).
  # Nodes with no registered content-type (images, files, ...) match nothing and
  # are left untouched by the pipeline.
  class Registry
    def initialize
      @by_content_type = {}
    end

    def register(type)
      @by_content_type[type.content_type] = type
    end

    def match(node)
      @by_content_type[node["content-type"]]
    end

    def types
      @by_content_type.values
    end
  end
end
