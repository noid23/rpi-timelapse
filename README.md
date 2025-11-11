# RPi-Timelapse

Set of scripts to get your location and what time sunset is where you are to then set a cron job that runs X minutes before sunset.

A photo will be taken at whatever interval you choose, then the photos will be turned into a timelapse video

## setsunset.sh / sunset-cron.sh

Both require `curl` and `jq`. `sunset-cron.sh` sets your location based off your IP address, pulls the sunset time for your area, and adds a cron job for <user_defined> minutes prior. `setsunset.sh` requires the user to specify their own LAT and LON in the config. Useful if your IP geo location data is frequently wrong. For example, VPN users

Usage:
```
user@host:~$ ./setsunset.sh [minutes before sunset]
user@host:~$ ./sunset-cron.sh [minutes before sunset]
```

## sunset-timelapse.sh

Requires `ffmpeg` and `libcamera-apps`. Script will make a timelapse video based off photos taken by the camera device. You can specifiy a time interval for when photos will be taken (in seconds) and a duration for how long to run (in minutes). Once the pictures are taken, ffmpeg will stitch them into a video for your enjoyment

Usage:
```
user@host:~$ ./sunset-timelapse.sh [interval] [duration]
```

## RPi Equipment and Setup

This was built with the following:
* The Pi: [Raspberry Pi Zero 2 W](https://www.raspberrypi.com/products/raspberry-pi-zero-2-w/)
* The Camera: [Raspberry Pi Camera Module 3](https://www.raspberrypi.com/products/camera-module-3/)
* The Case: [PiShop's Pi Zero Case](https://www.pishop.us/product/camera-case-for-raspberry-pi-zero-updated-for-v3/)

I am going to assume this isn't your first rodeo with the Raspberry Pi. Grab the [Raspberry Pi Imager](https://www.raspberrypi.com/software/) for your OS of choice. I went with the basic RPi OS **LITE** (64 bit). Install it, configure it, live it, laugh it, and love it. 

The RPi folks will tell you that the camera "just works" out of the box. As of this writting, using lite version of Debian Trixie, the camera does not work unless you make some changes. Once you get your OS up and running go ahead and install your prerequisite packages like `jq`, `ffmpeg`, and `libcamera-apps`. then you need to edit your config
```
user@host:~$ sudo nano /boot/firmware/config.txt

Change camera_auto_detect=1 to camera_auto_detect=0

[All]
dtoverlay=imx708
```
Now reboot

After a reboot you can test the camera by issuing a `rpicam-still -o test.jpg` to snap a photo. The IMX708 driver is necessary for the camera to work and not loaded unless you tell the system to do so. Now you should be ready to move on to the next step

## How to Use

This is a two part script. 

First, edit either `setsunset.sh` or `sunset-cron.sh` to point it to the location of `sunset-timelapse.sh`. Don't forget to add the required parameters the script needs to work. You have to provide an interval (in seconds) for how often photos will be taken and a duration (in minutes) for how long you want the script to run for. This is useful for tuning your timelapse event (in my case, it's recording the sunset)

Example for setsunset.sh:
```
# === CONFIGURATION ===
CRON_COMMAND="/home/noid/sunset-timelapse.sh 60 40"  # Command or script to run X min before sunset
```

Next, pick either `setsunset.sh` or `sunset-cron.sh` to set the launch time for the timelapse script. Put the script wherever you want it to live and then, using your editor of choice, edit your crontab with `crontab -e`. Insert the script into your crontab with whatever time you want it to execute every day. I have mine run at 0200. Save your crontab. You can verify that it's there with a `crontab -l`.

Example:
```
# m h  dom mon dow   command
0 2 * * * /home/noid/setsunset.sh 30
```
In this case the cron job will kick off 30 minutes before sunset. The script will then take a picture every 60 seconds for the next 40 minutes.

Once the script finishes up you will find your timelapse movie in `$HOME/sunset-timelapse`

## To-Do
* Add command line flag to clean up images after video generation
* ~~Add logging capabilities~~

## Notes
**NOTE :** I encountered a limitation with encoding videos on the RPi Zero 2 W. The following command does not work if you don't have enough memory
```
ffmpeg -y -pattern_type glob -i "$WORK_DIR/*.jpg" -c:v libx264 -r 30 -pix_fmt yuv420p "$OUTPUT_VIDEO"
```
To get around this limitation I went with the following, which does work, but comes with some caveats. Going lossless will work on the Pi Zero 2 W, but will generate very large videos. To put it in context a 40 minute run taking pictures twice a minute resulted in a 70mb video file. 
```
ffmpeg -y -pattern_type glob -i "$WORK_DIR/*.jpg" -c:v libx264 -crf 0 "$OUTPUT_VIDEO"
```
If you are using this script on a Pi 4 or 5, the original ffmpeg string will probably work just fine. I left it commented out in my script for you. Alternately if you are a ffmpeg guru and know of a better way to do this, open an issue. I'd love to know

**NOTE on Camera Cable:** When you attach the cable from the Pi to the camera take care to ensure you install it in the correct direction. Make sure that the contacts on the cable face the contacts on the hardware. You can install it "upside down" and, obviously, it won't work. Ask me how I know 😜

This is a work in progress as of 11/10/25. Use at your own risk.