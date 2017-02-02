#!/system/bin/sh

BB=/system/xbin/busybox;

# Mount root as RW to apply tweaks and settings
if [ "$($BB mount | grep rootfs | cut -c 26-27 | grep -c ro)" -eq "1" ]; then
	$BB mount -o remount,rw /;
fi;
if [ "$($BB mount | grep system | grep -c ro)" -eq "1" ]; then
	$BB mount -o remount,rw /system;
fi;


# Variant detection for supported devices
if [ "$(grep "N920C" /proc/cmdline)" != "" ] || [ "$(grep "N920CD" /proc/cmdline)" != "" ] || [ "$(grep "N920G" /proc/cmdline)" != "" ] || [ "$(grep "N920I" /proc/cmdline)" != "" ] || [ "$(grep "N920T" /proc/cmdline)" != "" ] || [ "$(grep "N920W8" /proc/cmdline)" != "" ] || [ "$(grep "N9208" /proc/cmdline)" != "" ]; then


	# Set SELinux permissive by default (parse defaults from prop)
	if [ "$(grep "selinux_permissive" /system/SkyHigh.prop)" != "" ]; then
		setenforce 0
	elif [ "$(grep "selinux_enforcing" /system/SkyHigh.prop)" != "" ]; then
		setenforce 1
	fi;


	# Make directory for Cron Task & cpuset
	if [ ! -d /data/.SkyHigh ]; then
		$BB mkdir -p /data/.SkyHigh
		$BB chmod -R 0777 /.SkyHigh/
	fi;


	# Setup for cpuset
	if [ -d /dev/cpuset ]; then
		echo "0-7" > /dev/cpuset/foreground/cpus;
		echo "4-7" > /dev/cpuset/foreground/boost/cpus;
		echo "0" > /dev/cpuset/background/cpus;
		echo "0-3" > /dev/cpuset/system-background/cpus;
		# Move invisible apps to A53
		if [ -d /dev/cpuset/invisible ]; then
			echo "0-3" > /dev/cpuset/invisible/cpus;
		fi;
	fi;


	# vnswap (parse defaults from prop)
	SWAP=/dev/block/vnswap0;
	SWAPSIZE=2684354560; # Android 6.0.1 == 2560 MB
	if [ "$(grep "vnswap_enabled" /system/SkyHigh.prop)" != "" ]; then
		if [ "$(grep "vnswap0" /proc/swaps)" == "" ]; then
			echo "$SWAPSIZE" > /sys/block/vnswap0/disksize;
			$BB mkswap $SWAP > /dev/null 2>&1
			$BB swapon $SWAP > /dev/null 2>&1
			$BB sync;
			echo "190" > /proc/sys/vm/swappiness;
		fi;
	else
		echo "0" > /sys/block/vnswap0/disksize;
		$BB sync;
		echo "0" > /proc/sys/vm/swappiness;
	fi;


	# Backup EFS
	if [ ! -d /data/media/0/SkyHigh/Synapse/EFS ]; then
		$BB mkdir -p /data/media/0/SkyHigh/Synapse/EFS;
	fi;
	if [ ! -e /data/media/0/SkyHigh/Synapse/EFS/efs_backup.img ]; then
		$BB dd if=dev/block/platform/15570000.ufs/by-name/EFS of=/data/media/0/SkyHigh/Synapse/EFS/efs_backup.img 2> /dev/null;
	fi;


	# Reset CortexBrain WiFi auto screen ON-OFF intervals
	if [ -e /data/.wifi_scron.log ]; then
		rm /data/.wifi_scron.log;
	fi;
	if [ -e /data/.wifi_scroff.log ]; then
		rm /data/.wifi_scroff.log;
	fi;


	# Set correct r/w permissions for LMK parameters
	$BB chmod 666 /sys/module/lowmemorykiller/parameters/cost;
	$BB chmod 666 /sys/module/lowmemorykiller/parameters/adj;
	$BB chmod 666 /sys/module/lowmemorykiller/parameters/minfree;


	# Disable rotational storage for all blocks
	# We need faster I/O so do not try to force moving to other CPU cores (dorimanx)
	for i in /sys/block/*/queue; do
		echo "0" > "$i"/rotational;
		echo "2" > "$i"/rq_affinity;
	done;


	# Allow untrusted apps to read from debugfs (mitigate SELinux denials)
	if [ -e /su/lib/libsupol.so ]; then
	/system/xbin/supolicy --live \
		"allow untrusted_app debugfs file { open read getattr }" \
		"allow untrusted_app sysfs_lowmemorykiller file { open read getattr }" \
		"allow untrusted_app sysfs_devices_system_iosched file { open read getattr }" \
		"allow untrusted_app persist_file dir { open read getattr }" \
		"allow debuggerd gpu_device chr_file { open read getattr }" \
		"allow netd netd capability fsetid" \
		"allow netd { hostapd dnsmasq } process fork" \
		"allow { system_app shell } dalvikcache_data_file file write" \
		"allow { zygote mediaserver bootanim appdomain }  theme_data_file dir { search r_file_perms r_dir_perms }" \
		"allow { zygote mediaserver bootanim appdomain }  theme_data_file file { r_file_perms r_dir_perms }" \
		"allow system_server { rootfs resourcecache_data_file } dir { open read write getattr add_name setattr create remove_name rmdir unlink link }" \
		"allow system_server resourcecache_data_file file { open read write getattr add_name setattr create remove_name unlink link }" \
		"allow system_server dex2oat_exec file rx_file_perms" \
		"allow mediaserver mediaserver_tmpfs file execute" \
		"allow drmserver theme_data_file file r_file_perms" \
		"allow zygote system_file file write" \
		"allow atfwd property_socket sock_file write" \
		"allow untrusted_app sysfs_display file { open read write getattr add_name setattr remove_name }" \
		"allow debuggerd app_data_file dir search" \
		"allow sensors diag_device chr_file { read write open ioctl }" \
		"allow sensors sensors capability net_raw" \
		"allow init kernel security setenforce" \
		"allow netmgrd netmgrd netlink_xfrm_socket nlmsg_write" \
		"allow netmgrd netmgrd socket { read write open ioctl }"
	fi;


	if [ "$($BB mount | grep rootfs | cut -c 26-27 | grep -c ro)" -eq "1" ]; then
		$BB mount -o remount,rw /;
	fi;


	# Fix for earphone / handsfree no in-call audio
	if [ -d "/sys/class/misc/arizona_control" ]; then
		echo "1" >/sys/class/misc/arizona_control/switch_eq_hp
	fi;


	# CPU governor (parse defaults from prop)
	if [ "$(grep "cpugov_interactive" /system/SkyHigh.prop)" != "" ]; then
		echo "interactive" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor;
		echo "interactive" > /sys/devices/system/cpu/cpu4/cpufreq/scaling_governor;
	elif [ "$(grep "cpugov_ktoonservative" /system/SkyHigh.prop)" != "" ]; then
		echo "ktoonservative" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor;
		echo "ktoonservative" > /sys/devices/system/cpu/cpu4/cpufreq/scaling_governor;
	elif [ "$(grep "cpugov_performance" /system/SkyHigh.prop)" != "" ]; then
		echo "performance" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor;
		echo "performance" > /sys/devices/system/cpu/cpu4/cpufreq/scaling_governor;
	elif [ "$(grep "cpugov_ondemand" /system/SkyHigh.prop)" != "" ]; then
		echo "ondemand" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor;
		echo "ondemand" > /sys/devices/system/cpu/cpu4/cpufreq/scaling_governor;
	elif [ "$(grep "cpugov_conservative" /system/SkyHigh.prop)" != "" ]; then
		echo "conservative" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor;
		echo "conservative" > /sys/devices/system/cpu/cpu4/cpufreq/scaling_governor;
	elif [ "$(grep "cpugov_conservativex" /system/SkyHigh.prop)" != "" ]; then
		echo "conservativex" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor;
		echo "conservativex" > /sys/devices/system/cpu/cpu4/cpufreq/scaling_governor;
	elif [ "$(grep "cpugov_chill" /system/SkyHigh.prop)" != "" ]; then
		echo "chill" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor;
		echo "chill" > /sys/devices/system/cpu/cpu4/cpufreq/scaling_governor;
	fi;


	# IO scheduler (parse defaults from prop)
	if [ "$(grep "sched_row" /system/SkyHigh.prop)" != "" ]; then
		for i in /sys/block/sd*/queue/scheduler; do
			$BB echo "row" > "$i" 2> /dev/null;
		done;
	elif [ "$(grep "sched_cfq" /system/SkyHigh.prop)" != "" ]; then
		for i in /sys/block/sd*/queue/scheduler; do
			$BB echo "cfq" > "$i" 2> /dev/null;
		done;
	elif [ "$(grep "sched_fiops" /system/SkyHigh.prop)" != "" ]; then
		for i in /sys/block/sd*/queue/scheduler; do
			$BB echo "fiops" > "$i" 2> /dev/null;
		done;
	elif [ "$(grep "sched_noop" /system/SkyHigh.prop)" != "" ]; then
		for i in /sys/block/sd*/queue/scheduler; do
			$BB echo "noop" > "$i" 2> /dev/null;
		done;
	elif [ "$(grep "sched_bfq" /system/SkyHigh.prop)" != "" ]; then
		for i in /sys/block/sd*/queue/scheduler; do
			$BB echo "bfq" > "$i" 2> /dev/null;
		done;
	elif [ "$(grep "sched_sioplus" /system/SkyHigh.prop)" != "" ]; then
		for i in /sys/block/sd*/queue/scheduler; do
			$BB echo "sioplus" > "$i" 2> /dev/null;
		done;
	elif [ "$(grep "sched_deadline" /system/SkyHigh.prop)" != "" ]; then
		for i in /sys/block/sd*/queue/scheduler; do
			$BB echo "deadline" > "$i" 2> /dev/null;
		done;
	elif [ "$(grep "sched_zen" /system/SkyHigh.prop)" != "" ]; then
		for i in /sys/block/sd*/queue/scheduler; do
			$BB echo "zen" > "$i" 2> /dev/null;
		done;
	elif [ "$(grep "sched_maple" /system/SkyHigh.prop)" != "" ]; then
		for i in /sys/block/sd*/queue/scheduler; do
			$BB echo "maple" > "$i" 2> /dev/null;
		done;
	fi;


	# CortexBrain (parse defaults from prop)
	if [ "$(grep "cortex_enabled" /system/SkyHigh.prop)" != "" ]; then
		echo "1" > /res/synapse/SkyHigh/cortexbrain_background_process;
	else
		echo "0" > /res/synapse/SkyHigh/cortexbrain_background_process;
	fi;


	# Crontab (parse defaults from prop)
	if [ "$(grep "crontab_enabled" /system/SkyHigh.prop)" != "" ]; then
		echo "1" > /res/synapse/SkyHigh/cron/master;
	else
		echo "0" > /res/synapse/SkyHigh/cron/master;
	fi;


	# Make SkyHigh directory & correct ownership/permissions
	if [ ! -d /data/media/0/SkyHigh ]; then
		$BB mkdir -p /data/media/0/SkyHigh
	fi;
	$BB chown -R media_rw:media_rw /data/media/0/SkyHigh;
	$BB chmod -R 755 /data/media/0/SkyHigh;


	# Synapse
	$BB chmod -R 755 /res/*
	$BB ln -fs /res/synapse/uci /sbin/uci
	/sbin/uci


	if [ "$($BB mount | grep rootfs | cut -c 26-27 | grep -c ro)" -eq "1" ]; then
		$BB mount -o remount,rw /;
	fi;
	if [ "$($BB mount | grep system | grep -c ro)" -eq "1" ]; then
		$BB mount -o remount,rw /system;
	fi;


	# Init.d
	if [ ! -d /system/etc/init.d ]; then
		mkdir -p /system/etc/init.d/;
		chown -R root.root /system/etc/init.d;
		chmod 777 /system/etc/init.d/;
		chmod 777 /system/etc/init.d/*;
	fi;
	$BB run-parts /system/etc/init.d


	# Arizona earphone sound default (parametric equalizer preset values by AndreiLux)
	if [ -d "/sys/class/misc/arizona_control" ]; then
		sleep 20;
		echo "0x0FF3 0x041E 0x0034 0x1FC8 0xF035 0x040D 0x00D2 0x1F6B 0xF084 0x0409 0x020B 0x1EB8 0xF104 0x0409 0x0406 0x0E08 0x0782 0x2ED8" > /sys/class/misc/arizona_control/eq_A_freqs
		echo "0x0C47 0x03F5 0x0EE4 0x1D04 0xF1F7 0x040B 0x07C8 0x187D 0xF3B9 0x040A 0x0EBE 0x0C9E 0xF6C3 0x040A 0x1AC7 0xFBB6 0x0400 0x2ED8" > /sys/class/misc/arizona_control/eq_B_freqs
	fi;


	# Run Cortexbrain script
	# Cortex parent should be ROOT/INIT and not Synapse
	cortexbrain_background_process=$(cat /res/synapse/SkyHigh/cortexbrain_background_process);
	if [ "$cortexbrain_background_process" == "1" ]; then
		sleep 30
		$BB nohup $BB sh /sbin/cortexbrain-tune.sh > /dev/null 2>&1 &
	fi;


	# Start CROND by tree root, so it's will not be terminated.
	cron_master=$(cat /res/synapse/SkyHigh/cron/master);
	if [ "$cron_master" == "1" ]; then
		$BB nohup $BB sh /res/crontab_service/service.sh 2> /dev/null;
	fi;


	# Kernel custom test
	if [ -e /data/.SkyHigh_test.log ]; then
		rm /data/.SkyHigh_test.log
	fi;
	echo  Kernel script is working !!! >> /data/.SkyHigh_test.log
	echo "excecuted on $(date +"%d-%m-%Y %r" )" >> /data/.SkyHigh_test.log


fi;


$BB mount -o remount,rw /data
