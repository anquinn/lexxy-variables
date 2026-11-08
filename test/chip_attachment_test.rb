require "test_helper"
require "test_helpers/action_text"

class ChipAttachmentTest < ActiveSupport::TestCase
  SNIPPET_TYPE = "application/vnd.actiontext.snippet"
  VIEW_PATHS = [
    File.expand_path("../app/views", __dir__),
    File.join(Gem.loaded_specs["actiontext"].full_gem_path, "app/views")
  ]

  class Variable
    include ActiveModel::Model
    include LexxyVariables::Attachable

    attr_accessor :key, :name
  end

  setup do
    LexxyVariables.reset_config!
    LexxyVariables.configure do |c|
      c.register_attachment(content_type: SNIPPET_TYPE, renders_as: :html, resolve: ->(*) { })
    end
  end

  teardown do
    LexxyVariables.reset_config!
  end

  test "a saved chip with no record renders back as the chip" do
    attachment = ActionText::Attachment.from_node(chip_node("first_name", "First name"))

    assert_equal view.lexxy_variable_chip("First name", key: "first_name"), render(attachment)
  end

  test "a saved chip of a block type renders back as a block chip" do
    attachment = ActionText::Attachment.from_node(chip_node("signature", "Signature", content_type: SNIPPET_TYPE))

    assert_equal view.lexxy_variable_chip("Signature", key: "signature", block: true), render(attachment)
  end

  test "a saved chip with no record reads as its name in plain text" do
    content = ActionText::Content.new("<p>Hi #{chip_node("first_name", "First name").to_html}</p>")

    assert_equal "Hi First name", content.to_plain_text
  end

  test "attachments the gem doesn't own are left missing" do
    node = attachment_node(%(<action-text-attachment sgid="" content-type="image/png"></action-text-attachment>))

    assert_kind_of ActionText::Attachables::MissingAttachable, ActionText::Attachable.from_node(node)
  end

  test "a model including LexxyVariables::Attachable is a variable chip" do
    variable = Variable.new(key: "plan", name: "Plan")
    attachment = ActionText::Attachment.new(chip_node("plan", "Plan"), variable)

    assert_equal LexxyVariables::VARIABLE_CONTENT_TYPE, variable.attachable_content_type
    assert_equal view.lexxy_variable_chip("Plan", key: "plan"), render(attachment)
    assert_equal "Plan", variable.attachable_plain_text_representation
  end

  test "a catalog object without attachable_sgid has no sgid" do
    item = Struct.new(:key, :name).new("plan", "Plan")

    assert_nil LexxyVariables.item_sgid(item)
  end

  private
    def chip_node(key, name, content_type: LexxyVariables::VARIABLE_CONTENT_TYPE)
      chip = view.lexxy_variable_chip(name, key: key, block: content_type == SNIPPET_TYPE)
      attachment_node(%(<action-text-attachment sgid="" content-type="#{content_type}" content="#{CGI.escapeHTML(chip)}"></action-text-attachment>))
    end

    def attachment_node(html)
      Nokogiri::HTML5.fragment(html).at_css("action-text-attachment")
    end

    def render(attachment)
      view.render_action_text_attachment(attachment).strip
    end

    def view
      @view ||= ActionView::Base.with_empty_template_cache.with_view_paths(VIEW_PATHS).tap do |view|
        view.extend(ActionText::ContentHelper, LexxyVariables::Helper)
        view.lookup_context.prefixes = [ "messages" ]
      end
    end
end
