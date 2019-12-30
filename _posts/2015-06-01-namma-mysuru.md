---
priority: 0.6
title: Namma Mysuru
excerpt: Android Application with backend server
categories: projects
background-image: nammaMysuru.png
tags:
  - Android
  - Python
  - HTTP
  - JSON
  - SQL
---

# Background
---
 
Being a movie freak, I used to struggle to find out about movies and their show times in [Mysuru](https://en.wikipedia.org/wiki/Mysore) 
theaters. So I thought of building an Android App that can show those details along with the directions to the famous 
sightseeing destinations and Restaurants around the city.

This was one of the most challenging, time consuming and interesting projects of mine. Throughout the project I always thought about 
integrating as many features as possible. 

## Project can broken down into several modules,
---

### 1. Web-Crawler:
      
A web-crawler written in Python using beautiful soup. Python scripts crawls the movie data available on google and fetches
related information from YouTube (trailer) and Wikipedia (Movie information) and loads it to sqlite database.

Please feel to take a look at my [web-crawler project website](https://ragu-manjegowda.github.io/web-crawler)

### 2. Http Server:
      
A http server running on my Digital Ocean droplet (VM), serves the https requests made by my app with the appropriate data it 
got after reading database previously populated in stage 1. The data is rturned in JSON format so that android application can 
parse and render it accordingly.

### 3. Android App:

{% include post_youtube.html id="c4VF_m8zvo4" %}

Android application that renders the data generated in step 1 and 2. Please feel free to checkout out my app on 
[Google Play](https://play.google.com/store/apps/details?id=com.project.raghavendra.nammamysore&hl=en)