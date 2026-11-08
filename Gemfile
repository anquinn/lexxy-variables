source "https://rubygems.org"

gemspec

group :development, :test do
  gem "rubocop-rails-omakase", require: false

  # Not a runtime dependency: the browser test suite serves the lexxy gem's
  # self-contained lexxy.js to exercise the importmap setup end-to-end.
  # 1.0 adds keyboard navigation to toolbar dropdowns.
  gem "lexxy", ">= 1.0"
end
