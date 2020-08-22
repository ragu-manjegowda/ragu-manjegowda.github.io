[![Build Status](https://travis-ci.org/ragu-manjegowda/ragu-manjegowda.github.io.svg?branch=master)](https://travis-ci.org/ragu-manjegowda/ragu-manjegowda.github.io)
[![Website ragu-manjegowda.github.io](https://img.shields.io/website-up-down-green-red/http/ragu-manjegowda.github.io.svg)](https://ragu-manjegowda.github.io/)
[![powered by Jekyll](https://img.shields.io/badge/powered_by-Jekyll-green.svg)](https://jekyllrb.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)

# ragu-manjegowda.github.io

Ragu's personal web site, using the design of http://html5up.net/spectral 
by [@ajlkn](http://twitter.com/ajlkn) and Jekyll theme by 
[@arkadianriver](https://arkadianriver.github.io/arkadianriver.com/).

## Build Instructions

## 1. Local

   - a. Docker based

        From the repo's root directory run,

        ```
        $ docker run --rm -it -p 4000:4000 -v "$PWD:/srv/jekyll" jekyll/jekyll jekyll serve --watch --incremental --host "0.0.0.0"
        ```
        Open a browser and navigate to http://0.0.0.0:4000

   - b. Native

        Install ruby and bundler on your local machine then,

        From the repo's root directory run,

        ```
        $ bundle exec jekyll serve --incremental
        ```
        Open a browser and navigate to http://localhost:4000 (or the port number that jekyll 
        indicates to open)

   - c. Script

        From the repo's root directory run,

        ```
        $ ./scripts/run.sh
        ```


## 2. Remote

I have enabled [Travis CI hook](https://travis-ci.org/github/ragu-manjegowda/ragu-manjegowda.github.io/builds/) that triggers everytime commit is pushed. 
Build status and error messages can be seen by following CI status in commit history.


## Credits

* I would like to thank my beloved wife [@Sinduja Raghavendra](https://github.com/sinduja-raghavendra) 
for teaching web development and helping me fixing bugs 
in the original theme to make the website [responsive](https://en.wikipedia.org/wiki/Responsive_web_design).

* Obviously I should thank [@Gary Faircloth](https://github.com/arkadianriver) 
for this wonderful theme.


#### ***You can find readme from Gary's **arkadianriver** repo [here](https://github.com/arkadianriver/arkadianriver.com)***
