require "test_helper"
require "liquid"

class LiquidRendererTest < Minitest::Test
  class CompanyDrop < Liquid::Drop
    def name = "Acme &amp; Co"
  end

  def setup
    @renderer = LexxyVariables::Renderers::Liquid.new
  end

  def render(html, nonce: "abc123", assigns: {})
    @renderer.render(html, nonce: nonce, assigns: assigns)
  end

  def test_resolves_a_matching_token
    html = "Hello @@lexxy-var-abc123:company@@!"

    assert_equal "Hello Acme!", render(html, assigns: { "company" => "Acme" })
  end

  def test_resolves_dotted_keys_through_drops
    html = "@@lexxy-var-abc123:company.name@@"

    assert_equal "Acme &amp; Co", render(html, assigns: { "company" => CompanyDrop.new })
  end

  def test_neutralizes_author_typed_liquid
    html = "{{ 7 | plus: 1 }} and {% assign x = 1 %}"
    out = render(html)

    # Author braces are entity-escaped before parsing, so nothing executes.
    refute_includes out, "8"
    assert_includes out, "&#123;&#123;"
  end

  def test_ignores_a_token_with_a_forged_nonce
    html = "@@lexxy-var-WRONG:company@@"

    assert_equal html, render(html, nonce: "abc123", assigns: { "company" => "Acme" })
  end
end
