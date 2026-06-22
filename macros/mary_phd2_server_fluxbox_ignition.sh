#!/bin/bash

sudo pkill -9 x11vnc
sudo pkill -9 Xvfb
sudo pkill -9 fluxbox
sudo pkill -9 phd2

Xvfb :99 -screen 0 1280x1024x24 &
export DISPLAY=:99
fluxbox &
/usr/bin/phd2 &
x11vnc -display :99 -bg -usepw -rfbport 5901 -listen 0.0.0.0 -xkb -forever

