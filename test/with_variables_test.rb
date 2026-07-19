require "test_helper"
require "active_support/all"
require "active_record"
require "action_controller"
require "action_view"
require "action_text"

# ActionText::Content includes helpers that live in the engine's app/ directory,
# which is only on the load path inside a full Rails app. Load them by hand.
actiontext_root = Gem.loaded_specs["actiontext"].full_gem_path
require File.join(actiontext_root, "app/helpers/action_text/content_helper")
require File.join(actiontext_root, "app/helpers/action_text/tag_helper")

# Covers the chainable API: Content#with_variables (injected via the
# :action_text_content load hook) returning a resolved Content that ActionText's
# own conversions read from, and the RichText delegation module.
class WithVariablesTest < ActiveSupport::TestCase
  VARIABLE_TYPE = "test/variable"

  FakeRichText = Struct.new(:body) do
    include LexxyVariables::RichTextWithVariables
  end

  setup do
    LexxyVariables.reset_config!
    LexxyVariables.configure do |c|
      c.register_attachment(
        content_type: VARIABLE_TYPE,
        resolve: ->(node, _context) { node["data-key"] }
      )
    end
  end

  teardown do
    LexxyVariables.reset_config!
  end

  def content(html)
    ActionText::Content.new(html, canonicalize: false)
  end

  def variable_chip(key)
    %(<action-text-attachment content-type="#{VARIABLE_TYPE}" data-key="#{key}"></action-text-attachment>)
  end

  test "Content gains with_variables via the load hook" do
    assert_includes ActionText::Content.included_modules, LexxyVariables::WithVariables
  end

  test "with_variables returns a resolved Content" do
    resolved = content("<p>Hi #{variable_chip('first_name')}!</p>").with_variables(first_name: "Ada")

    assert_instance_of ActionText::Content, resolved
    assert_equal "<p>Hi Ada!</p>", resolved.to_html
  end

  test "to_plain_text reads raw values" do
    resolved = content("<p>Hi #{variable_chip('first_name')}!</p>").with_variables(first_name: "Tom & Jerry")

    assert_equal "Hi Tom & Jerry!", resolved.to_plain_text
  end

  test "to_html reads escaped values" do
    resolved = content("<p>#{variable_chip('first_name')}</p>").with_variables(first_name: "Tom & Jerry")

    assert_equal "<p>Tom &amp; Jerry</p>", resolved.to_html
  end

  test "to_markdown reads resolved values" do
    skip "ActionText::Content#to_markdown not available in this Rails" unless
      ActionText::Content.method_defined?(:to_markdown)

    resolved = content("<h1>Hi #{variable_chip('first_name')}!</h1>").with_variables(first_name: "Ada")

    assert_equal "# Hi Ada!", resolved.to_markdown.strip
  end

  test "assigns hash and keyword args are merged" do
    resolved = content("<p>#{variable_chip('first_name')} #{variable_chip('last_name')}</p>")
      .with_variables(assigns: { first_name: "Ada" }, last_name: "Lovelace")

    assert_equal "<p>Ada Lovelace</p>", resolved.to_html
  end

  test "RichText delegates to its body" do
    rich_text = FakeRichText.new(content("<p>Hi #{variable_chip('first_name')}!</p>"))

    assert_equal "<p>Hi Ada!</p>", rich_text.with_variables(first_name: "Ada").to_html
  end

  test "RichText with nil body resolves to empty Content" do
    resolved = FakeRichText.new(nil).with_variables(first_name: "Ada")

    assert_instance_of ActionText::Content, resolved
    assert_equal "", resolved.to_html
  end

  # The display idiom, <%= @record.body.with_variables %>. ERB calls to_s, which
  # renders through Action Text with the layout and sanitizer, the same path as
  # <%= @record.body %>. Stand in for the Rails app with a controller that knows
  # Action Text's views and helpers, wired in the way the engine does at boot.
  test "to_s keeps author formatting, resolves chips inside it, and escapes values" do
    actiontext_root = Gem.loaded_specs["actiontext"].full_gem_path
    controller = Class.new(ActionController::Base) do
      helper ActionText::ContentHelper
      append_view_path File.join(actiontext_root, "app/views")
    end
    previous_renderer = ActionText::Content.renderer
    ActionText::Content.renderer = controller.renderer

    html = %(<p><strong>Bold #{variable_chip('first_name')}</strong> and <em>italic</em></p>)
    out = content(html).with_variables(first_name: "Tom & Jerry").to_s

    assert_includes out, "<strong>Bold Tom &amp; Jerry</strong>"
    assert_includes out, "<em>italic</em>"
    assert_includes out, %(<div class="trix-content">)
    assert_predicate out, :html_safe?
  ensure
    ActionText::Content.renderer = previous_renderer
  end
end
