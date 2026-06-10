#!/usr/bin/env bash
set -e # halt script on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default mode
MODE="local"
LOCAL_URL="http://localhost:4000"
DOCKER_IMAGE="ruby:3.3.4"

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
      echo "Usage: $0 [--local|-l] [--docker|-d] [--help|-h]"
      echo ""
      echo "Options:"
      echo "  --local, -l     Use local Ruby/Jekyll installation (default)"
      echo "  --docker, -d    Use Docker to build and serve"
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
        # Use the Ruby version listed by GitHub Pages. Run as the host user so
        # Docker and local builds can share generated artifacts.
        echo "Running Jekyll in Docker..."
        echo -e "${GREEN}Open ${YELLOW}${LOCAL_URL}${NC}${GREEN} in your browser.${NC}"

        DOCKER_BUNDLE_CACHE="$PWD/.bundle/docker"
        mkdir -p "$DOCKER_BUNDLE_CACHE"

        DOCKER_NETWORK_ARGS=()
        DOCKER_PORT_ARGS=(-p 4000:4000)
        DOCKER_USER_ARGS=(--user "$(id -u):$(id -g)")
        if [ "$(uname -s)" = "Linux" ]; then
            # Docker bridge DNS can fail on some Linux setups even when host
            # networking works; use the host stack for local development.
            DOCKER_NETWORK_ARGS=(--network host)
            DOCKER_PORT_ARGS=()
        fi

        docker run --rm \
            "${DOCKER_NETWORK_ARGS[@]}" \
            "${DOCKER_PORT_ARGS[@]}" \
            "${DOCKER_USER_ARGS[@]}" \
            -v "$PWD:/srv/jekyll" \
            -v "$DOCKER_BUNDLE_CACHE:/usr/local/bundle" \
            -e HOME=/tmp \
            -e BUNDLE_APP_CONFIG=/tmp/bundle-config \
            -e IO_EVENT_SELECTOR=Select \
            "$DOCKER_IMAGE" \
            sh -c "mkdir -p /tmp/jekyll-bundle && cp /srv/jekyll/Gemfile /tmp/jekyll-bundle/Gemfile && cd /srv/jekyll && BUNDLE_GEMFILE=/tmp/jekyll-bundle/Gemfile sh -c 'bundle check || bundle install' && BUNDLE_GEMFILE=/tmp/jekyll-bundle/Gemfile bundle exec jekyll serve --host 0.0.0.0 --watch --incremental"

        exit 0
    fi
fi

if [ "$MODE" = "local" ]; then
    echo "Running Jekyll locally..."

    # Check if bundler is installed locally
    if ! command -v bundler &> /dev/null; then
        echo -e "${RED}Bundler could not be found${NC}"
        echo -e "${YELLOW}Please install Ruby and Bundler first${NC}"
        exit 1
    fi

    # Install dependencies only if gems are not installed
    if ! bundle check &> /dev/null; then
        echo "Installing gems via bundle install..."
        bundle install
    else
        echo -e "${GREEN}✓ Gems already installed${NC}"
    fi

    # Serve on localhost with Select-based event selector
    # (liburing.so.2 may not be available in all environments)
    export IO_EVENT_SELECTOR=Select
    echo -e "${GREEN}Open ${YELLOW}${LOCAL_URL}${NC}${GREEN} in your browser.${NC}"
    bundle exec jekyll serve --incremental --host "localhost"

    exit 0
fi

echo -e "${RED}Build failed. Please follow README.md for setup instructions${NC}"
exit 1
