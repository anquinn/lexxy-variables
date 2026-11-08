module LexxyVariables
  # Stands in for a chip whose sgid finds no record, like those from a
  # plain-hash catalog, so Action Text renders it as a chip instead of a
  # missing attachment. That's what lets saved chips survive re-editing.
  class ChipAttachment
    PARTIAL_PATH = "lexxy_variables/chip"

    attr_reader :key, :name, :attachable_content_type

    # Action Text's sanitizer strips data-lexxy-key before plain text and
    # rendering, so the chip's class is enough to find it and the key is optional.
    def self.from_node(node)
      if LexxyVariables.config.registry.match(node)
        if chip = Nokogiri::HTML5.fragment(node["content"].to_s).at_css("[data-lexxy-key], .lexxy-variable")
          new(key: chip["data-lexxy-key"].presence, name: chip.text, content_type: node["content-type"])
        end
      end
    end

    def initialize(key:, name:, content_type:)
      @key = key
      @name = name
      @attachable_content_type = content_type
    end

    def to_attachable_partial_path = PARTIAL_PATH
    def attachable_plain_text_representation(_caption = nil) = name

    module Lookup
      def from_node(node)
        attachable = super

        if attachable.is_a?(ActionText::Attachables::MissingAttachable)
          ChipAttachment.from_node(node) || attachable
        else
          attachable
        end
      end
    end
  end
end

ActiveSupport.on_load(:action_text_content) do
  ActionText::Attachable.singleton_class.prepend(LexxyVariables::ChipAttachment::Lookup)
end
