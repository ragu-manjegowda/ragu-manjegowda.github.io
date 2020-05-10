#!/usr/bin/env bash
set -e # halt script on error

# Build Site
bundle exec jekyll build --incremental

# Lint html
bundle exec htmlproofer ./_site --disable-external

