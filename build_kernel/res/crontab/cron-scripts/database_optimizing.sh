#!/system/bin/sh
#
# Optimize Databases script
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

# SQLite3 binary location
if [ -f /su/xbin/sqlite3 ]; then
	SQL3=/su/xbin/sqlite3;
elif [ -f /system/xbin/sqlite3 ]; then
	SQL3=/system/xbin/sqlite3;
elif [ -f /system/bin/sqlite3 ]; then
	SQL3=/system/bin/sqlite3;
fi;

SQLITE=$(cat /res/synapse/SkyHigh/cron/sqlite);

if [ "$SQLITE" == 1 ]; then

	# wait till CPU is idle.
	while [ ! "$($BB cat /proc/loadavg | cut -c1-4)" -lt "3.50" ]; do
		echo "Waiting For CPU to cool down";
		sleep 30;
	done;

	for i in $(find /data -iname "*.db"); do
		$SQL3 "$i" 'VACUUM;' 2> /dev/null;
		$SQL3 "$i" 'REINDEX;' 2> /dev/null;
	done;

	for i in $(find /data/media/0 -iname "*.db"); do
		$SQL3 "$i" 'VACUUM;' 2> /dev/null;
		$SQL3 "$i" 'REINDEX;' 2> /dev/null;
	done;
	$BB sync;

	date +%R-%F > /data/crontab/cron-db-optimizing;
	echo " DB Optimized" >> /data/crontab/cron-db-optimizing;

elif [ "$SQLITE" == 0 ]; then

	date +%R-%F > /data/crontab/cron-db-optimizing;
	echo " DB Optimization is disabled" >> /data/crontab/cron-db-optimizing;
fi;
