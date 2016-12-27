#!/sbin/sh

# Some elements & ideas from g.lewarne
# by UpInTheAir for SkyHigh kernels

# DETECT
if [ "$1" = "DETECT" ]; then
	if [ "$(grep "N920C" /proc/cmdline)" != "" ] || [ "$(grep "N920CD" /proc/cmdline)" != "" ] || [ "$(grep "N920G" /proc/cmdline)" != "" ] || [ "$(grep "N920I" /proc/cmdline)" != "" ] || [ "$(grep "N920P" /proc/cmdline)" != "" ] || [ "$(grep "N920T" /proc/cmdline)" != "" ] || [ "$(grep "N920W8" /proc/cmdline)" != "" ] || [ "$(grep "N9200" /proc/cmdline)" != "" ] || [ "$(grep "N9208" /proc/cmdline)" != "" ] || [ "$(grep "G928C" /proc/cmdline)" != "" ] || [ "$(grep "G928F" /proc/cmdline)" != "" ] || [ "$(grep "G928G" /proc/cmdline)" != "" ] || [ "$(grep "G928I" /proc/cmdline)" != "" ] || [ "$(grep "G9287C" /proc/cmdline)" != "" ] || [ "$(grep "G928P" /proc/cmdline)" != "" ] || [ "$(grep "G928T" /proc/cmdline)" != "" ] || [ "$(grep "G928W8" /proc/cmdline)" != "" ]; then
		echo "device.type=compatible" >> /system/device.prop
	else
		echo "device.type=incompatible" >> /system/device.prop
	fi;
fi;

# SELINUX
if [ "$1" = "PERMISSIVE" ]; then
	echo "selinux_permissive" >> /system/SkyHigh.prop
elif [ "$1" = "ENFORCING" ]; then
	echo "selinux_enforcing" >> /system/SkyHigh.prop
fi;

# BIND
if [ "$1" = "BIND" ]; then
	if [ -f /data/.supersu ]; then
		rm -rf /data/.supersu;
		echo BINDSYSTEMXBIN=true >> /data/.supersu;
	elif [ ! -f /data/.supersu ]; then
		echo BINDSYSTEMXBIN=true >> /data/.supersu;
	fi;
fi;

# INVISIBLE CPUSETS
if [ "$1" = "INVISIBLE" ]; then
	if [ -f /data/.SkyHigh/invisible_cpuset ]; then
		rm -rf /data/.SkyHigh/invisible_cpuset;
	fi;
	echo 1 >> /data/.SkyHigh/invisible_cpuset;
fi;

# VNSWAP
if [ "$1" = "VNSWAP" ]; then
	echo "vnswap_enabled" >> /system/SkyHigh.prop
fi;

# LAZYTIME MOUNT
if [ "$1" = "LAZYTIME" ]; then
	if [ -f /data/.SkyHigh/lazytime_mount ]; then
		rm -rf /data/.SkyHigh/lazytime_mount;
	fi;
	echo 1 >> /data/.SkyHigh/lazytime_mount;
fi;

# BUILD.PROP
if [ "$1" = "BUILD_PROP" ]; then
	# backup original build.prop
	if [ ! -f /system/build.prop.orig ]; then
		cp /system/build.prop /system/build.prop.orig
	fi;

	# check multi-user
	if [ "$(grep "fw.max_users" /system/build.prop)" != "" ]; then
		max_users="fw.max_users=30";
	fi;
	if [ "$(grep "fw.show_multiuserui" /system/build.prop)" != "" ]; then
		show_multiuserui="fw.show_multiuserui=1";
	fi;
	if [ "$(grep "fw.show_hidden_users" /system/build.prop)" != "" ]; then
		show_hidden_users="fw.show_hidden_users=1";
	fi;
	if [ "$(grep "fw.power_user_switcher" /system/build.prop)" != "" ]; then
		power_user_switcher="fw.power_user_switcher=1";
	fi;

	# check Viper4Android
	if [ "$(grep "lpa.decode" /system/build.prop)" != "" ]; then
		decode="lpa.decode=false";
	fi;
	if [ "$(grep "lpa.releaselock" /system/build.prop)" != "" ]; then
		releaselock="lpa.releaselock=false";
	fi;
	if [ "$(grep "lpa.use-stagefright" /system/build.prop)" != "" ]; then
		stagefright="lpa.use-stagefright=false";
	fi;
	if [ "$(grep "tunnel.decode" /system/build.prop)" != "" ]; then
		tunnel="tunnel.decode=false";
	fi;

	# remove placebo & bullshit 'tweaks'
	sed -i '/ro.expect.recovery_id/q' /system/build.prop;

	# stock kernel
	echo "#" >> /system/build.prop
	echo "# Keep WIFI settings on flash/reboot" >> /system/build.prop
	echo "ro.securestorage.support=false" >> /system/build.prop
	echo "# Screen mirroring / AllShare Cast fix" >> /system/build.prop
	echo "wlan.wfd.hdcp=disable" >> /system/build.prop
	echo "#" >> /system/build.prop

	# multi-user
	if [ "$max_users" == "fw.max_users=30" ]; then
		echo "fw.max_users=30" >> /system/build.prop
	fi;
	if [ "$show_multiuserui" == "fw.show_multiuserui=1" ]; then
		echo "fw.show_multiuserui=1" >> /system/build.prop
	fi;
	if [ "$show_hidden_users" == "fw.show_hidden_users=1" ]; then
		echo "fw.show_hidden_users=1" >> /system/build.prop
	fi;
	if [ "$power_user_switcher" == "fw.power_user_switcher=1" ]; then
		echo "fw.power_user_switcher=1" >> /system/build.prop
	fi;

	# Viper4Android
	if [ "$decode" == "lpa.decode=false" ]; then
		echo "lpa.decode=false" >> /system/build.prop
	fi;
	if [ "$releaselock" == "lpa.releaselock=false" ]; then
		echo "lpa.releaselock=false" >> /system/build.prop
	fi;
	if [ "$stagefright" == "lpa.use-stagefright=false" ]; then
		echo "lpa.use-stagefright=false" >> /system/build.prop
	fi;
	if [ "$tunnel" == "tunnel.decode=false" ]; then
		echo "tunnel.decode=false" >> /system/build.prop
	fi;

	chmod 644 /system/build.prop;
fi;

# CPU GOVERNOR
if [ "$1" = "INTERACTIVE" ]; then
	echo "cpugov_interactive" >> /system/SkyHigh.prop
elif [ "$1" = "KTOONSERVATIVE" ]; then
	echo "cpugov_ktoonservative" >> /system/SkyHigh.prop
elif [ "$1" = "PERFORMANCE" ]; then
	echo "cpugov_performance" >> /system/SkyHigh.prop
elif [ "$1" = "ONDEMAND" ]; then
	echo "cpugov_ondemand" >> /system/SkyHigh.prop
elif [ "$1" = "CONSERVATIVE" ]; then
	echo "cpugov_conservative" >> /system/SkyHigh.prop
elif [ "$1" = "CONSERVATIVEX" ]; then
	echo "cpugov_conservativex" >> /system/SkyHigh.prop
elif [ "$1" = "CHILL" ]; then
	echo "cpugov_chill" >> /system/SkyHigh.prop
fi;

# IO SCHEDULER
if [ "$1" = "ROW" ]; then
	echo "sched_row" >> /system/SkyHigh.prop
elif [ "$1" = "CFQ" ]; then
	echo "sched_cfq" >> /system/SkyHigh.prop
elif [ "$1" = "FIOPS" ]; then
	echo "sched_fiops" >> /system/SkyHigh.prop
elif [ "$1" = "NOOP" ]; then
	echo "sched_noop" >> /system/SkyHigh.prop
elif [ "$1" = "BFQ" ]; then
	echo "sched_bfq" >> /system/SkyHigh.prop
elif [ "$1" = "SIOPLUS" ]; then
	echo "sched_sioplus" >> /system/SkyHigh.prop
elif [ "$1" = "DEADLINE" ]; then
	echo "sched_deadline" >> /system/SkyHigh.prop
fi;

# CORTEX
if [ "$1" = "CORTEX_ENABLED" ]; then
	echo "cortex_enabled" >> /system/SkyHigh.prop
fi;

# CRONTAB
if [ "$1" = "CRONTAB_ENABLED" ]; then
	echo "crontab_enabled" >> /system/SkyHigh.prop
fi;
