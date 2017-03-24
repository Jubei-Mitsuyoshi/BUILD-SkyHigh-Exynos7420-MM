#!/system/bin/sh
#
# FSTrim script
#
# Copyright (c) 2017 UpInTheAir. All rights reserved.
#
# Authors:	UpInTheAir
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

mount -o remount,rw \/system;

FSTRIM=$(cat /res/synapse/SkyHigh/cron/fstrim);

if [ "$FSTRIM" == 1 ]; then

	# wait till CPU is idle.
	while [ ! "$($BB cat /proc/loadavg | cut -c1-4)" -lt "3.50" ]; do
		echo "Waiting For CPU to cool down";
		sleep 30;
	done;

	# EXT4 partitions only
	if grep -q 'system ext4' /proc/mounts ; then
		if [ -e /su/xbin/fstrim ]; then
			/su/xbin/fstrim -v /system
		elif [ -e /system/xbin/fstrim ]; then
			/system/xbin/fstrim -v /system
		elif [ -e /system/bin/fstrim ]; then
			/system/bin/fstrim -v /system
		fi;
	else
		exit 0;
	fi;
	if grep -q 'data ext4' /proc/mounts ; then
		if [ -e /su/xbin/fstrim ]; then
			/su/xbin/fstrim -v /data
		elif [ -e /system/xbin/fstrim ]; then
			/system/xbin/fstrim -v /data
		elif [ -e /system/bin/fstrim ]; then
			/system/bin/fstrim -v /data
		fi;
	else
		exit 0;
	fi;
	if grep -q 'cache ext4' /proc/mounts ; then
		if [ -e /su/xbin/fstrim ]; then
			/su/xbin/fstrim -v /cache
		elif [ -e /system/xbin/fstrim ]; then
			/system/xbin/fstrim -v /cache
		elif [ -e /system/bin/fstrim ]; then
			/system/bin/fstrim -v /cache
		fi;
	else
		exit 0;
	fi;

	$BB sync

	date +%R-%F > /data/crontab/cron-fstrim;
	echo " EXT4 File System trimmed" >> /data/crontab/cron-fstrim;

elif [ "$FSTRIM" == 0 ]; then

	date +%R-%F > /data/crontab/cron-fstrim;
	echo " EXT4 File System Trim is disabled" >> /data/crontab/cron-fstrim;
fi;
