#!/usr/bin/env bash
set -e # halt script on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default mode
MODE="docker"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --docker|-d)
      MODE="docker"
      shift
      ;;
    --local|-l)
      MODE="local"
      shift
      ;;
    --help|-h)
      echo "Usage: $0 [--docker|-d] [--local|-l] [--help|-h]"
      echo ""
      echo "Options:"
      echo "  --docker, -d    Use Docker to build and serve (default)"
      echo "  --local, -l     Use local Ruby/Jekyll installation"
      echo "  --help, -h      Show this help message"
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Verify we're in the right directory
if [ ! -f ./compose.rb ]; then
    echo -e "${RED}Make sure you are in repo's root directory!${NC}"
    exit 1
fi

# Delete old build
rm -rf ./_site

echo -e "${GREEN}Build mode: ${YELLOW}$MODE${NC}"

if [ "$MODE" = "docker" ]; then
    echo "Building with Docker..."

    # Check if docker is installed
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker could not be found!${NC}"
        echo -e "${YELLOW}Falling back to local build...${NC}"
        MODE="local"
    elif ! docker stats --no-stream &> /dev/null; then
        echo -e "${RED}Docker daemon is not running, please start docker service${NC}"
        echo -e "${YELLOW}Falling back to local build...${NC}"
        MODE="local"
    else
        # Use fixed Docker command with Gemfile.docker for Alpine compatibility
        docker run --rm -p 4000:4000 -v "$PWD:/srv/jekyll" -e BUNDLE_GEMFILE=Gemfile.docker jekyll/jekyll jekyll serve --watch --incremental --host "0.0.0.0"
        exit 0
    fi
fi

if [ "$MODE" = "local" ]; then
    echo "Building with local Ruby/Jekyll..."

    # Check if bundler is installed locally
    if ! command -v bundler &> /dev/null; then
        echo -e "${RED}Bundler could not be found${NC}"
        echo -e "${YELLOW}Please install Ruby and Bundler first${NC}"
        exit 1
    fi

    # Build site
    bundle exec jekyll build

    # Lint html output
    bundle exec htmlproofer ./_site --disable-external

    # Serve on localhost
    bundle exec jekyll serve --incremental --host "0.0.0.0"

    exit 0
fi

echo -e "${RED}Build failed. Please follow README.md for setup instructions${NC}"
exit 1
