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

# Build Site for production
bundle exec jekyll build --incremental

# Lint html - ignore localhost URLs (0.0.0.0:4000) and allow HTTP for internal links
bundle exec htmlproofer ./_site \
  --disable-external \
  --ignore-urls "/0\.0\.0\.0/" \
  --allow-hash-href

