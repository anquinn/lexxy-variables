require "test_helper"

class RegistryTest < Minitest::Test
  def setup
    @registry = LexxyVariables::Registry.new
  end

  def type(content_type, phase: :value)
    LexxyVariables::AttachmentType.new(content_type: content_type, phase: phase, resolve: ->(*) { })
  end

  def test_matches_by_content_type
    t = type("application/vnd.actiontext.variable")
    @registry.register(t)

    assert_equal t, @registry.match("content-type" => "application/vnd.actiontext.variable")
  end

  def test_unregistered_content_type_matches_nothing
    @registry.register(type("application/vnd.actiontext.variable"))

    assert_nil @registry.match("content-type" => "image/png")
    assert_nil @registry.match("content-type" => nil)
  end

  def test_re_registering_same_content_type_overrides
    first = type("x", phase: :value)
    second = type("x", phase: :fragment)
    @registry.register(first)
    @registry.register(second)

    assert_equal second, @registry.match("content-type" => "x")
    assert_equal 1, @registry.types.size
  end
end
