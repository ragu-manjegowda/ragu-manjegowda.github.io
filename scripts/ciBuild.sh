#!/usr/bin/env bash
set -e # halt script on error

# Set Jekyll environment to production
export JEKYLL_ENV=production

# Build Site for production
bundle exec jekyll build --incremental

# Lint html
bundle exec htmlproofer ./_site --disable-external

