#!/usr/bin/env bash
set -e # halt script on error

# Force Ruby to use Select-based event selector instead of liburing
# (liburing.so.2 may not be available in all environments)
# This will still show the warning but fallback to using select
# To test:
# IO_EVENT_SELECTOR=Select ruby -e "require 'io/event'; puts IO::Event::Selector.default.name"
export IO_EVENT_SELECTOR=Select

# Set Jekyll environment to production
export JEKYLL_ENV=production

build_site() {
  bundle exec jekyll build

  if [ ! -f ./_site/feed.xml ]; then
    echo "Expected ./_site/feed.xml to be generated"
    exit 1
  fi
}

run_site_tests() {
  ruby -I tests tests/site_regression_test.rb
}

run_theme_tests() {
  ruby -I tests tests/theme_contract_test.rb
}

run_http_check() {
  ruby <<'RUBY'
bad_links = []
Dir.glob('_site/**/*.html').each do |path|
  File.read(path).scan(/(?:href|src)="http:\/\/([^"]+)"/) do |match|
    url = match.first
    next if url.start_with?('localhost') || url.start_with?('0.0.0.0')

    bad_links << "#{path}: http://#{url}"
  end
end

if bad_links.any?
  warn "Insecure generated href/src URLs found:"
  bad_links.each { |entry| warn "  #{entry}" }
  exit 1
end
RUBY
}

run_htmlproofer() {
  bundle exec htmlproofer ./_site \
    --disable-external \
    --ignore-urls "/0\.0\.0\.0/" \
    --allow-hash-href
}

case "${1:-all}" in
  build)
    build_site
    ;;
  site-tests)
    run_site_tests
    ;;
  theme-tests)
    run_theme_tests
    ;;
  http-check)
    run_http_check
    ;;
  htmlproofer)
    run_htmlproofer
    ;;
  all)
    build_site
    run_site_tests
    run_theme_tests
    run_http_check
    run_htmlproofer
    ;;
  *)
    echo "Usage: $0 [all|build|site-tests|theme-tests|http-check|htmlproofer]" >&2
    exit 2
    ;;
esac
