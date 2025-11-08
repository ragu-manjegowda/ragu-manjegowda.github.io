#!/usr/bin/env bash
set -e # halt script on error

# Set Jekyll environment to production
export JEKYLL_ENV=production

# Build Site for production
# Suppress SASS deprecation warnings (they're from old theme SCSS, not critical)
bundle exec jekyll build --incremental 2>&1 | grep -v "DEPRECATION WARNING" | grep -v "More info" | grep -v "automated migrator" | grep -v "Use color" | grep -v "color\." | grep -v "^  " | grep -v "^    " | grep -v "│" | grep -v "WARNING: .* repetitive" | grep -v "Run in verbose mode" | grep -v "^$" || true

# Lint html - ignore localhost URLs (0.0.0.0:4000) and allow HTTP for internal links
bundle exec htmlproofer ./_site \
  --disable-external \
  --ignore-urls "/0\.0\.0\.0/" \
  --allow-hash-href

