#!/system/bin/sh
#
# Modified work Copyright (c) 2017 UpInTheAir. All rights reserved.
#
# Authors:	dorimanx
#		Dairinin
#		UpInTheAir (modifiy for Synpase UCI & TZ)
#
# This software and associated documentation files (the "Software")
# is proprietary of UpInTheAir. No part of this Software, either
# material or conceptual may be copied or distributed, transmitted,
# transcribed, stored in a retrieval system or translated into any
# human or computer language in any form by any means, electronic,
# mechanical, manual or otherwise, or disclosed to third parties
# without the express written permission of UpInTheAir.
#
# Alternatively, this program is free software in case of open
# source project:
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this Software, to redistribute the Software
# and/or modify it under the terms of the GNU General Public
# License as published by the Free Software Foundation; either
# version 3 of the License, or (at your option) any later version,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

if [ -e /su/xbin/busybox ]; then
	BB=/su/xbin/busybox;
elif [ -e /system/xbin/busybox ]; then
	BB=/system/xbin/busybox;
elif [ -e /system/bin/busybox ]; then
	BB=/system/bin/busybox;
fi;

if [ "$($BB mount | grep rootfs | cut -c 26-27 | grep -c ro)" -eq "1" ]; then
	$BB mount -o remount,rw /;
fi;

if [ ! -e /data/crontab/ ]; then
	$BB mkdir /data/crontab/;
fi;


# Copy Cron files after reset
if [ ! -e /data/crontab/cron-scripts/ ]; then
	$BB cp -a /res/crontab/ /data/;
fi;

if [ -e /su/xbin/busybox ]; then
	$BB cp -a /res/crontab_service/su/cron-root /data/crontab/root;
elif [ -e /system/xbin/busybox ]; then
	$BB cp -a /res/crontab_service/system_xbin/cron-root /data/crontab/root;
elif [ -e /system/bin/busybox ]; then
	$BB cp -a /res/crontab_service/system_bin/cron-root /data/crontab/root;
fi;

chown 0:0 /data/crontab/root;
chmod 777 /data/crontab/root;
if [ ! -d /var/spool/cron/crontabs ]; then
	mkdir -p /var/spool/cron/crontabs/;
fi;
$BB cp -a /data/crontab/root /var/spool/cron/crontabs/;

chown 0:0 /var/spool/cron/crontabs/*;
chmod 777 /var/spool/cron/crontabs/*;


# Check device local timezone & set for cron tasks
timezone=$(date +%z);

if [ "$timezone" == "+1400" ]; then
	TZ=UCT-14
elif [ "$timezone" == "+1300" ]; then
	TZ=UCT-13
elif [ "$timezone" == "+1245" ]; then
	TZ=CIST-12:45CIDT
elif [ "$timezone" == "+1200" ]; then
	TZ=NZST-12NZDT
elif [ "$timezone" == "+1100" ]; then
	TZ=UCT-11
elif [ "$timezone" == "+1030" ]; then
	TZ=LHT-10:30LHDT
elif [ "$timezone" == "+1000" ]; then
	TZ=UCT-10
elif [ "$timezone" == "+0930" ]; then
	TZ=UCT-9:30
elif [ "$timezone" == "+0900" ]; then
	TZ=UCT-9
elif [ "$timezone" == "+0830" ]; then
	TZ=KST
elif [ "$timezone" == "+0800" ]; then
	TZ=UCT-8
elif [ "$timezone" == "+0700" ]; then
	TZ=UCT-7
elif [ "$timezone" == "+0630" ]; then
	TZ=UCT-6:30
elif [ "$timezone" == "+0600" ]; then
	TZ=UCT-6
elif [ "$timezone" == "+0545" ]; then
	TZ=UCT-5:45
elif [ "$timezone" == "+0530" ]; then
	TZ=UCT-5:30
elif [ "$timezone" == "+0500" ]; then
	TZ=UCT-5
elif [ "$timezone" == "+0430" ]; then
	TZ=UCT-4:30
elif [ "$timezone" == "+0400" ]; then
	TZ=UCT-4
elif [ "$timezone" == "+0330" ]; then
	TZ=UCT-3:30
elif [ "$timezone" == "+0300" ]; then
	TZ=UCT-3
elif [ "$timezone" == "+0200" ]; then
	TZ=UCT-2
elif [ "$timezone" == "+0100" ]; then
	TZ=UCT-1
elif [ "$timezone" == "+0000" ]; then
	TZ=UCT
elif [ "$timezone" == "-0100" ]; then
	TZ=UCT1
elif [ "$timezone" == "-0200" ]; then
	TZ=UCT2
elif [ "$timezone" == "-0300" ]; then
	TZ=UCT3
elif [ "$timezone" == "-0330" ]; then
	TZ=NST3:30NDT
elif [ "$timezone" == "-0400" ]; then
	TZ=UCT4
elif [ "$timezone" == "-0430" ]; then
	TZ=UCT4:30
elif [ "$timezone" == "-0500" ]; then
	TZ=UCT5
elif [ "$timezone" == "-0600" ]; then
	TZ=UCT6
elif [ "$timezone" == "-0700" ]; then
	TZ=UCT7
elif [ "$timezone" == "-0800" ]; then
	TZ=UCT8
elif [ "$timezone" == "-0900" ]; then
	TZ=UCT9
elif [ "$timezone" == "-0930" ]; then
	TZ=UCT9:30
elif [ "$timezone" == "-1000" ]; then
	TZ=UCT10
elif [ "$timezone" == "-1100" ]; then
	TZ=UCT11
elif [ "$timezone" == "-1200" ]; then
	TZ=UCT12
else
	TZ=UCT
fi;

export TZ


#Set Permissions to scripts
chown 0:0 /data/crontab/cron-scripts/*;
chmod 777 /data/crontab/cron-scripts/*;


# use /var/spool/cron/crontabs/ call the crontab file "root"
if [ -e /su/xbin/crond ]; then
	$BB nohup /su/xbin/crond -c /var/spool/cron/crontabs/ > /data/.SkyHigh/cron.txt &
elif [ -e /system/xbin/crond ]; then
	$BB nohup /system/xbin/crond -c /var/spool/cron/crontabs/ > /data/.SkyHigh/cron.txt &
elif [ -e /system/bin/crond ]; then
	$BB nohup /system/bin/crond -c /var/spool/cron/crontabs/ > /data/.SkyHigh/cron.txt &
fi;
sleep 1;
PIDOFCRON=$(pidof crond);
echo "-900" > /proc/"$PIDOFCRON"/oom_score_adj;
