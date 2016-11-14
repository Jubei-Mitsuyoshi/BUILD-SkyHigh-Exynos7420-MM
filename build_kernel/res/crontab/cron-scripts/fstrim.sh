#!/system/bin/sh

# FSTrim script
# by UpInTheAir for SkyHigh kernels & Synapse

BB=/system/xbin/busybox;
FSTRIM=$(cat /res/synapse/SkyHigh/cron/fstrim);

if [ "$($BB mount | grep rootfs | cut -c 26-27 | grep -c ro)" -eq "1" ]; then
	$BB mount -o remount,rw /;
fi;
if [ "$($BB mount | grep system | grep -c ro)" -eq "1" ]; then
	$BB mount -o remount,rw /system;
fi;

if [ "$FSTRIM" == 1 ]; then

	# wait till CPU is idle.
	while [ ! "$($BB cat /proc/loadavg | cut -c1-4)" -lt "3.50" ]; do
		echo "Waiting For CPU to cool down";
		sleep 30;
	done;

	# EXT4 partitions only
	if grep -q 'system ext4' /proc/mounts ; then
		/system/xbin/fstrim -v /system
	else
		exit 0;
	fi;
	if grep -q 'data ext4' /proc/mounts ; then
		/system/xbin/fstrim -v /data
	else
		exit 0;
	fi;
	if grep -q 'cache ext4' /proc/mounts ; then
		/system/xbin/fstrim -v /cache
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
