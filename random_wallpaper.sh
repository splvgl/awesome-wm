#!/bin/bash
find $HOME/.wallpapers -type f -name '*.jpg' -o -name '*.png' | shuf -n 1 | xargs feh --bg-scale
