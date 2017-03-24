#!/system/bin/sh
#
# Drop Cache script
#
# Modified work Copyright (c) 2017 UpInTheAir. All rights reserved.
#
# Authors:	dorimanx
#		UpInTheAir
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

DROP_CACHE=$(cat /res/synapse/SkyHigh/cron/drop_cache);

if [ "$DROP_CACHE" == 1 ]; then

	while read -r TYPE MEM KB; do
		export KB
		if [ "$TYPE" = "MemTotal:" ]; then
			TOTAL=$((MEM / 1024));
		elif [ "$TYPE" = "MemFree:" ]; then
			FREE=$((MEM / 1024));
		elif [ "$TYPE" = "Cached:" ]; then
			CACHED=$((MEM / 1024));
		fi;
	done < /proc/meminfo;

  	FREE=$(($FREE + $CACHED));
	MEM_USED_CALC=$(($FREE*100/$TOTAL));

	# do clean cache only if cache uses 50% of free memory.
	if [ "$MEM_USED_CALC" -gt "50" ]; then

		# wait till CPU is idle.
		while [ ! "$($BB cat /proc/loadavg | cut -c1-4)" -lt "3.50" ]; do
			echo "Waiting For CPU to cool down";
			sleep 30;
		done;

		$BB sync;
		sysctl -w vm.drop_caches=3;
		$BB sync;

		date +%R-%F > /data/crontab/cron-clear-ram-cache;
		echo " Cache above 50%! Cleaned RAM Cache" >> /data/crontab/cron-clear-ram-cache;

	elif [ "$MEM_USED_CALC" -lt "50" ]; then

		date +%R-%F > /data/crontab/cron-clear-ram-cache;
		echo " Cache below 50%! Cleaning RAM Cache aborted" >> /data/crontab/cron-clear-ram-cache;
	fi;

elif [ "$DROP_CACHE" == 0 ]; then

	date +%R-%F > /data/crontab/cron-clear-ram-cache;
	echo " Clean RAM Cache is disabled" >> /data/crontab/cron-clear-ram-cache;
fi;
