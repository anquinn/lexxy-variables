module LexxyVariables
  # Convenience for hosts whose variable objects are not already Action Text
  # attachables. Include it and set `attachable_content_type` so chips carry a
  # real sgid and the pipeline can match them. Models that already include
  # ActionText::Attachable do not need this.
  module Attachable
    extend ActiveSupport::Concern

    included do
      include ActionText::Attachable
    end

    def attachable_content_type
      LexxyVariables::VARIABLE_CONTENT_TYPE
    end
  end
end
