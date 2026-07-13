source "https://rubygems.org"

gemspec

group :development, :test do
  gem "rubocop-rails-omakase", require: false

  # Not a runtime dependency: the browser test suite serves the lexxy gem's
  # self-contained lexxy.js to exercise the importmap setup end-to-end.
  # 0.9.24 ships the {{ prompt fix (basecamp/lexxy#1179).
  gem "lexxy", ">= 0.9.24"
end
