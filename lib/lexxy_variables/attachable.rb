module LexxyVariables
  # Makes a host's variable model an Action Text attachable, so its chips carry
  # a real sgid and render as chips. Action Text may not be loaded yet when this
  # file is, so it's included lazily. Chip comes after it, which keeps these
  # methods ahead of Action Text's defaults and behind the host model's own.
  module Attachable
    extend ActiveSupport::Concern

    included do
      include ActionText::Attachable
      include Chip
    end

    module Chip
      def attachable_content_type = LexxyVariables::VARIABLE_CONTENT_TYPE
      def to_attachable_partial_path = LexxyVariables::ChipAttachment::PARTIAL_PATH
      def attachable_plain_text_representation(_caption = nil) = name
    end
  end
end
