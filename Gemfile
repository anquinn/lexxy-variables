source "https://rubygems.org"

gemspec

gem "rubocop-rails-omakase", require: false

group :development, :test do
  # Not a runtime dependency: the browser test suite serves the lexxy gem's
  # self-contained lexxy.js to exercise the importmap setup end-to-end.
  gem "lexxy", ">= 0.9.23"
end
