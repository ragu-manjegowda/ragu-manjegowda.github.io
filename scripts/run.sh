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
        # Use official Jekyll Docker image
        # Rename lock file temporarily so Docker's Bundler creates its own
        # This avoids Bundler version conflicts (host 2.7.2 vs Docker 2.3.25)
        echo "Running Jekyll in Docker..."

        # Function to restore lock file on exit or interrupt
        restore_lock() {
            if [ -f Gemfile.lock.host ]; then
                rm -f Gemfile.lock
                mv Gemfile.lock.host Gemfile.lock
                echo "Restored Gemfile.lock"
            fi
        }
        trap restore_lock EXIT INT TERM

        # Temporarily rename host's lock file
        if [ -f Gemfile.lock ]; then
            mv Gemfile.lock Gemfile.lock.host
        fi

        # Run Docker, which will create its own lock file
        docker run --rm \
            -p 4000:4000 \
            -v "$PWD:/srv/jekyll" \
            -e IO_EVENT_SELECTOR=Select \
            jekyll/jekyll:latest \
            sh -c "cd /srv/jekyll && bundle install && jekyll serve --host 0.0.0.0 --watch --incremental"

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

    # Install dependencies only if gems are not installed
    if ! bundle check &> /dev/null; then
        echo "Installing gems via bundle install..."
        bundle install
    else
        echo -e "${GREEN}✓ Gems already installed${NC}"
    fi

    # Build site
    bundle exec jekyll build

    # Lint html output
    bundle exec htmlproofer ./_site --disable-external

    # Serve on localhost with Select-based event selector
    # (liburing.so.2 may not be available in all environments)
    export IO_EVENT_SELECTOR=Select
    bundle exec jekyll serve --incremental --host "0.0.0.0"

    exit 0
fi

echo -e "${RED}Build failed. Please follow README.md for setup instructions${NC}"
exit 1
