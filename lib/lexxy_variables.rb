require "active_support"
require "erb"
require "securerandom"
require "nokogiri"

require "lexxy_variables/version"
require "lexxy_variables/placeholder"
require "lexxy_variables/attachment_type"
require "lexxy_variables/registry"
require "lexxy_variables/renderers/substitution"
require "lexxy_variables/renderers/liquid"
require "lexxy_variables/configuration"
require "lexxy_variables/pipeline"
require "lexxy_variables/attachable"
require "lexxy_variables/helper"
require "lexxy_variables/engine" if defined?(Rails::Engine)

# Insert and safely resolve variable/attachment tokens in Lexxy rich text.
#
# The gem owns the mechanism: the editor extension, the nonce-safe render
# pipeline, the attachment-type registry, and the renderers. The host app owns
# the policy: what variables exist (catalog), what a key resolves to (assigns),
# and any extra attachment types (register_attachment, e.g. snippets).
module LexxyVariables
  # Default content-type carried by variable attachment chips. A host may
  # register additional types (snippets, etc.) via Configuration#register_attachment.
  VARIABLE_CONTENT_TYPE = "application/vnd.actiontext.variable"

  class << self
    def configure
      yield config
      config
    end

    def config
      @config ||= Configuration.new
    end

    # Primarily for tests / reloading.
    def reset_config!
      @config = Configuration.new
    end

    # Resolves an attachment node's sgid to its attachable, or nil if the sgid is
    # missing or stale. Handy for host-supplied :value / :fragment resolvers.
    def attachable_from(node)
      ActionText::Attachable.from_attachable_sgid(node["sgid"])
    rescue StandardError
      nil
    end

    # Reads the key that lexxy_variable_chip embeds as data-lexxy-key in the chip
    # content, or nil if absent. This is how a plain-hash catalog (which has no
    # sgid-backed attachable) maps a chip back to its catalog key at render.
    def chip_key(node)
      content = node["content"]
      return nil if content.nil? || content.empty?

      span = Nokogiri::HTML5.fragment(content).at_css("[data-lexxy-key]")
      key = span && span["data-lexxy-key"]
      key unless key.nil? || key.empty?
    rescue StandardError
      nil
    end

    # Catalog items can be plain hashes or any objects that respond to the same
    # fields. These accessors read the fields the prompt needs either way.
    def item_name(item)
      if item.is_a?(Hash)
        item[:name]
      else
        item.name
      end
    end

    def item_key(item)
      if item.is_a?(Hash)
        item[:key]
      else
        item.key
      end
    end

    def item_value(item)
      if item.is_a?(Hash)
        item[:value]
      else
        item.value
      end
    end

    def item_sgid(item)
      if item.is_a?(Hash)
        item[:attachable_sgid]
      else
        item.attachable_sgid
      end
    end

    def item_content_type(item)
      if item.is_a?(Hash)
        item[:content_type]
      elsif item.respond_to?(:attachable_content_type)
        item.attachable_content_type
      end
    end

    # True when a content-type is registered as a :fragment type (e.g. snippets),
    # so its chip should render in the block style.
    def block_content_type?(content_type)
      type = registered_type(content_type)
      type ? type.fragment? : false
    end

    # The badge label for an item's type, or nil if none is registered.
    def item_type_label(item)
      registered_type(item_content_type(item))&.label
    end

    private

    def registered_type(content_type)
      return nil if content_type.nil?

      config.registry.match("content-type" => content_type)
    end
  end
end
