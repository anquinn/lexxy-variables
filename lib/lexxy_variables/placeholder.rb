module LexxyVariables
  # The single definition of the placeholder token format. The pipeline writes
  # tokens with #token and the renderers find them with #pattern, so the format
  # only lives here.
  module Placeholder
    PREFIX = "@@lexxy-var-"

    def self.token(nonce, key)
      "#{PREFIX}#{nonce}:#{key}@@"
    end

    def self.pattern(nonce)
      /#{Regexp.escape(PREFIX)}#{Regexp.escape(nonce)}:([a-z][a-z0-9_.]*)@@/
    end
  end
end
