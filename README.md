# RPi-Timelapse

Set of scripts to get your location and what time sunset is where you are to then set a cron job that runs X minutes before sunset.

A photo will be taken at whatever interval you choose, then the photos will be turned into a timelapse video

## sunset-cron.sh

Requires `curl` and `jq` Sets your location based off your IP address, pulls the sunset time for your area, and adds a cron job for <user_defined> minutes prior

Usage:
```
user@host:~$ ./sunset-cron.sh [minutes before sunset]
```

## setsunset.sh 

Requires `curl` and `jq`. This script requires the user to specify their own LAT and LON in the config. Useful if your IP geo location data is frequently wrong. For example, VPN users

Usage:
```
user@host:~$ ./setsunset.sh [minutes before sunset]
```

## sunset-timelapse.sh

Requires `ffmpeg` and `libcamera-apps`. Script will make a timelapse video based off photos taken by the camera device. You can specifiy a time interval for when photos will be taken (in seconds) and a duration for how long to run (in minutes). Once the pictures are taken, ffmpeg will stitch them into a video for your enjoyment

Usage:
```
user@host:~$ ./sunset-timelapse.sh [interval] [duration]
```

## RPi Zero 2 W Configuration Changes

**coming soon**

This is a work in progress as of 11/4/25. Use at your own risk.

