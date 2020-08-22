#!/usr/bin/env bash
set -e # halt script on error

# Delete old build
rm -rf ./_site

# Build site
RUBYOPT='-W0' bundle exec jekyll build

# Lint html output
bundle exec htmlproofer ./_site --disable-external

# Serve on localhost
RUBYOPT='-W0' bundle exec jekyll serve --future --drafts --incremental
