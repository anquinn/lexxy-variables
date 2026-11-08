require "active_support/all"
require "active_record"
require "action_controller"
require "action_view"
require "global_id"
require "action_text"

# ActionText::Content includes helpers that live in the engine's app/ directory,
# which is only on the load path inside a full Rails app. Load them by hand.
actiontext_root = Gem.loaded_specs["actiontext"].full_gem_path
require File.join(actiontext_root, "app/helpers/action_text/content_helper")
require File.join(actiontext_root, "app/helpers/action_text/tag_helper")

# Loading Content runs the :action_text_content hooks, as a host app's first
# rich text does, so the gem's hooks are in place whatever order tests run in.
ActionText::Content

SignedGlobalID.verifier ||= ActiveSupport::MessageVerifier.new("lexxy-variables-test")
