---
priority: 0.6
title: Heart Rate Measurement Device
excerpt: using IR sensors.
categories: projects
background-image: heartRate.jpg
tags:
  - C
  - Atmel
  - Electronic Circuits
---

# Background
---

This is my first ever hobby project.

Device built using IR sensors to measure the heart rate in human body. It also has three digit display. 
Heart rate is measured by reading LED pulses reflected back from human finger and processing the signal through filters.

### Block diagram:

<img src="/images/blockDiagram.png" width="450">

### Technical explanation:

I used [LDO](https://en.wikipedia.org/wiki/Low-dropout_regulator) to step down battery voltage from 9V to 5V (As all parts operates at 5V), 
rest is self explanatory from block diagram.
I used [Express PCB](https://www.expresspcb.com/), An open source CAD tool to design schematic and layout.

### To know more:

All other work products like Abstract, BOM, PCB, Firmware etc.., can be found in my [GitHub repository](https://github.com/ragu-manjegowda/heart-rate-measurement-device).