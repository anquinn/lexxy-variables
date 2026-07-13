require "test_helper"

# Unit-tests the view helper's argument handling in isolation. The pipeline is
# swapped for a fake that captures what it is called with, so these assert how
# render_lexxy_content forwards context, locale, and inline assigns without
# exercising the full ActionText render path (that lives in pipeline_test).
class HelperTest < Minitest::Test
  class FakePipeline
    attr_reader :calls

    def initialize(*)
      @calls = []
    end

    def call(rich_text, **kwargs)
      @calls << [ rich_text, kwargs ]
      "rendered"
    end
  end

  class View
    include LexxyVariables::Helper
  end

  def setup
    @fake = FakePipeline.new
    @original = LexxyVariables::Pipeline
    LexxyVariables.send(:remove_const, :Pipeline)
    fake = @fake
    LexxyVariables.const_set(:Pipeline, Class.new do
      define_method(:initialize) { |*| }
      define_method(:call) { |rich_text, **kwargs| fake.call(rich_text, **kwargs) }
    end)
  end

  def teardown
    LexxyVariables.send(:remove_const, :Pipeline)
    LexxyVariables.const_set(:Pipeline, @original)
  end

  def last_assigns
    @fake.calls.last.last[:assigns]
  end

  def test_keyword_args_become_inline_assigns
    View.new.render_lexxy_content(:body, first_name: "Ada")

    assert_equal({ first_name: "Ada" }, last_assigns)
  end

  def test_explicit_assigns_hash_is_passed_through
    View.new.render_lexxy_content(:body, assigns: { first_name: "Ada" })

    assert_equal({ first_name: "Ada" }, last_assigns)
  end

  def test_explicit_and_keyword_assigns_are_merged
    View.new.render_lexxy_content(:body, assigns: { first_name: "Ada" }, last_name: "Lovelace")

    assert_equal({ first_name: "Ada", last_name: "Lovelace" }, last_assigns)
  end

  def test_context_and_locale_are_not_swallowed_into_assigns
    View.new.render_lexxy_content(:body, context: :tenant, locale: :fr, plan: "pro")

    kwargs = @fake.calls.last.last
    assert_equal :tenant, kwargs[:context]
    assert_equal :fr, kwargs[:locale]
    assert_equal({ plan: "pro" }, kwargs[:assigns])
  end
end
