require "test_helper"

class SubstitutionRendererTest < Minitest::Test
  def setup
    @renderer = LexxyVariables::Renderers::Substitution.new
  end

  def render(html, nonce: "abc123", assigns: {})
    @renderer.render(html, nonce: nonce, assigns: assigns)
  end

  def test_substitutes_a_matching_token
    html = "Hello @@lexxy-var-abc123:company@@!"

    assert_equal "Hello Acme!", render(html, assigns: { "company" => "Acme" })
  end

  def test_escapes_the_value_so_html_is_inert
    html = "@@lexxy-var-abc123:company@@"

    assert_equal "&lt;script&gt;x&lt;/script&gt;",
      render(html, assigns: { "company" => "<script>x</script>" })
  end

  def test_missing_key_becomes_empty
    assert_equal "", render("@@lexxy-var-abc123:company@@", assigns: {})
  end

  def test_ignores_a_token_with_a_forged_nonce
    html = "@@lexxy-var-WRONG:company@@"

    # The author cannot fabricate a token: only this render's nonce is honored.
    assert_equal html, render(html, nonce: "abc123", assigns: { "company" => "Acme" })
  end

  def test_no_template_engine_means_authored_braces_are_literal
    html = "{{ evil }} and {% raw %}"

    assert_equal html, render(html)
  end
end
