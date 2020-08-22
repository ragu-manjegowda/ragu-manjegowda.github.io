#!/usr/bin/env bash
set -e # halt script on error

# Delete old build
rm -rf ./_site

RED='\033[0;31m'
NC='\033[0m' # No Color

if [ ! -f ./compose.rb ];
then
    echo -e "${RED}Make sure you are in repo's root directory!${NC}"
    exit
fi

echo "Trying to build with docker..."

# If docker is installed
if ! command -v docker &> /dev/null
then
    echo -e "${RED}docker could not be found!${NC}\n\n"
else
    if ! docker stats --no-stream &> /dev/null
    then
        echo -e "${RED}docker deamon is not running, please start docker service${NC}\n\n"
    else
        docker run --rm -it -p 4000:4000 -v "$PWD:/srv/jekyll" jekyll/jekyll jekyll serve --watch --incremental --host "0.0.0.0"
        exit
    fi
fi

echo "Trying to build using tools installed natively..."

# If bundle is installed locally
if ! command -v bundler &> /dev/null
then
    echo -e "${RED}bundler could not be found${NC}\n\n"
else
    # Build site
    bundle exec jekyll build

    # Lint html output
    bundle exec htmlproofer ./_site --disable-external

    # Serve on localhost
    bundle exec jekyll serve --incremental

    exit
fi

echo -e "${RED}Please follow README.md for instructions${NC}"
