#!/bin/bash

###############################################################################
# To all DEV around the world :)					      #
# to build this kernel you need to be ROOT and to have bash as script loader  #
# do this:								      #
# cd /bin								      #
# rm -f sh								      #
# ln -s bash sh								      #
#									      #
# Now you can build my kernel.						      #
# using bash will make your life easy. so it's best that way.		      #
# Have fun and update me if something nice can be added to my source.	      #
#									      #
# Original scripts by halaszk & various sources throughout gitHub	      #
# Highly modified by UpInTheAir for SkyHigh kernels			      #
#									      #
###############################################################################


#################################### SETUP ####################################

. ./env_setup.sh ${1} || exit 1;

if [ ! -f ${KERNELDIR}/.config ]; then
	echo
	echo "${bldcya}***** Writing Config *****${txtrst}";
	echo

		cp ${KERNELDIR}/arch/arm64/configs/$KERNEL_CONFIG .config;
		make ARCH=arm64 $KERNEL_CONFIG;
fi;

. ${KERNELDIR}/.config


################################### CLEAN UP ###################################

echo
echo "${bldcya}***** Clean up first *****${txtrst}"
echo

	find . -type f -name "*~" -exec rm -f {} \;
	find . -type f -name "*orig" -exec rm -f {} \;
	find . -type f -name "*rej" -exec rm -f {} \;

	# cleanup previous Image files
	if [ -e ${KERNELDIR}/dt.img ]; then
		rm ${KERNELDIR}/dt.img;
	fi;
	if [ -e ${KERNELDIR}/arch/arm64/boot/Image ]; then
		rm ${KERNELDIR}/arch/arm64/boot/Image;
	fi;
	if [ -e ${KERNELDIR}/arch/arm64/boot/dt.img ]; then
		rm ${KERNELDIR}/arch/arm64/boot/dt.img;
	fi;

	# cleanup variant ramdisk files
	find . -type f -name "EMPTY_DIRECTORY" -exec rm -f {} \;

	if [ -e $EXTRACT/boot.img ]; then
		rm -rf $EXTRACT/boot.img
	fi;
	if [ -e $EXTRACT/Image ]; then
		rm -rf $EXTRACT/Image
	fi;
	if [ -e $EXTRACT/ramdisk.lzo ]; then
		rm -rf $EXTRACT/ramdisk.lzo
	fi;
	if [ -e $EXTRACT/ramdisk/lib/modules/ ]; then
		cd $EXTRACT || exit 1;
		find . -type f -name "*.ko" -exec rm -f {} \;
		cd ${KERNELDIR} || exit 1;
	fi;
	if [ -e $BK/system/lib/modules/ ]; then
		cd ${KERNELDIR}/$BK/system || exit 1;
		find . -type f -name "*.ko" -exec rm -f {} \;
	fi;

	cd ${KERNELDIR} || exit 1;

	# cleanup old output files
	rm -rf ${KERNELDIR}/output/$TARGET/*

	# cleanup old dtb files
	rm -rf ${KERNELDIR}/arch/arm64/boot/dts/*.dtb;

echo "Clean up finished"


################################ UNPACK BOOT.IMG ###############################

echo
echo "${bldcya}***** Unpack boot.img *****${txtrst}"
echo

	cd ${KERNELDIR}/$BK/tools || exit 1;

	./mkboot ${KERNELDIR}/$BK/$TARGET/boot.img $EXTRACT;


################################ COMPILE IMAGES ################################

echo
echo "${bldcya}***** Compiling kernel *****${txtrst}"
echo

	cd ${KERNELDIR} || exit 1;

	if [ $USER != "root" ]; then
		make CONFIG_DEBUG_SECTION_MISMATCH=y -j5 Image ARCH=arm64
	else
		make -j$(($NUMBEROFCPUS + 1)) Image ARCH=arm64;
	fi;

	if [ -e ${KERNELDIR}/arch/arm64/boot/Image ]; then
		echo
		echo "${bldcya}***** Final Touch for Kernel *****${txtrst}"
		echo

			stat ${KERNELDIR}/arch/arm64/boot/Image || exit 1;
			mv ./arch/arm64/boot/Image $EXTRACT
			echo
			echo "${grn}--- Creating custom dt.img ---${txtrst}"
			echo
			# stock generated tools
			./$BK/tools/dtbtool -o dt.img -s 2048 -p ./scripts/dtc/dtc ./arch/arm64/boot/dts/
	else
		echo "${bldred}Kernel STUCK in BUILD!${txtrst}"
		echo
		while true; do
			read -p "${grn}Do you want to run a Make command to check the error?  (y/n) > ${txtrst}" yn
			case $yn in
				[Yy]* ) make Image ARCH=arm64; echo ; exit;;
				[Nn]* ) echo; exit;;
				* ) echo "Please answer yes or no.";;
			esac
		done
	fi;

############################### PATCH GENERATION ###############################

echo
echo "${bldcya}***** Patch ramdisk *****${txtrst}"

	cd ${KERNELDIR} || exit 1;

	backup_file() { cp $1 $1~; }

	replace_string() {
		if [ -z "$(grep "$2" $1)" ]; then
			sed -i "s;${3};${4};" $1;
		fi;
	}

	insert_line() {
		if [ -z "$(grep "$2" $1)" ]; then
			case $3 in
				before) offset=0;;
				after) offset=1;;
			esac;
			line=$(($(grep -n "$4" $1 | cut -d: -f1) + offset));
			sed -i "${line}s;^;${5}\n;" $1;
		fi;
	}

	replace_line() {
		if [ ! -z "$(grep "$2" $1)" ]; then
			line=$(grep -n "$2" $1 | cut -d: -f1);
			sed -i "${line}s;.*;${3};" $1;
		fi;
	}

	remove_line() {
		if [ ! -z "$(grep "$2" $1)" ]; then
			line=$(grep -n "$2" $1 | cut -d: -f1);
			sed -i "${line}d" $1;
		fi;
	}

echo
read -p "${grn}Patch ramdisk with SkyHigh mods? (y/n) > ${txtrst}";

	if [ "$REPLY" == "y" -o "$REPLY" == "Y" ]; then
		sleep 1

		# backup
		backup_file $EXTRACT/ramdisk/default.prop;
		backup_file $EXTRACT/ramdisk/file_contexts;
		backup_file $EXTRACT/ramdisk/init.rc;
		backup_file $EXTRACT/ramdisk/init.rilcommon.rc;
		backup_file $EXTRACT/ramdisk/init.samsungexynos7420.rc;
		backup_file $EXTRACT/ramdisk/fstab.samsungexynos7420;
		backup_file $EXTRACT/ramdisk/fstab.samsungexynos7420.fwup;

		# default.prop
		if [ "$TARGET" == "G928F" ]; then
			if [ "$(grep "# SM-G9287C dual SIM support" $EXTRACT/ramdisk/default.prop)" != "" ]; then
				echo ""
			else
				insert_line $EXTRACT/ramdisk/default.prop "# SkyHigh KERNEL" after "rild.libpath=/system/lib64/libsec-ril.so" "\n# SM-G9287C dual SIM support";
			fi;
			if [ "$(grep "rild.libpath2=/system/lib64/libsec-ril-dsds.so" $EXTRACT/ramdisk/default.prop)" != "" ]; then
				echo ""
			else
				insert_line $EXTRACT/ramdisk/default.prop "# SkyHigh KERNEL" after "# SM-G9287C dual SIM support" "rild.libpath2=/system/lib64/libsec-ril-dsds.so\n";
			fi;
		fi;
		if [ "$(grep "persist.security.ams.enforcing=1" $EXTRACT/ramdisk/default.prop)" != "" ]; then
			replace_string $EXTRACT/ramdisk/default.prop "persist.security.ams.enforcing=0" "persist.security.ams.enforcing=1" "persist.security.ams.enforcing=0";
		else
			echo ""
		fi;
		if [ "$(grep "persist.security.ams.enforcing=3" $EXTRACT/ramdisk/default.prop)" != "" ]; then
			replace_string $EXTRACT/ramdisk/default.prop "persist.security.ams.enforcing=0" "persist.security.ams.enforcing=3" "persist.security.ams.enforcing=0";
		else
			echo ""
		fi;
		if [ "$(grep "ro.secure=1" $EXTRACT/ramdisk/default.prop)" != "" ]; then
			replace_string $EXTRACT/ramdisk/default.prop "ro.secure=0" "ro.secure=1" "ro.secure=0";
		else
			echo ""
		fi;
		if [ "$(grep "ro.debuggable=0" $EXTRACT/ramdisk/default.prop)" != "" ]; then
			replace_string $EXTRACT/ramdisk/default.prop "ro.debuggable=1" "ro.debuggable=0" "ro.debuggable=1";
		else
			echo ""
		fi;
		if [ "$(grep "ro.adb.secure=1" $EXTRACT/ramdisk/default.prop)" != "" ]; then
			replace_string $EXTRACT/ramdisk/default.prop "ro.adb.secure=0" "ro.adb.secure=1" "ro.adb.secure=0";
		else
			echo ""
		fi;
		if [ "$(grep "persist.sys.usb.config=mtp" $EXTRACT/ramdisk/default.prop)" != "" ]; then
			replace_string $EXTRACT/ramdisk/default.prop "persist.sys.usb.config=mtp,adb" "persist.sys.usb.config=mtp" "persist.sys.usb.config=mtp,adb";
		else
			echo ""
		fi;
		if [ "$(grep "# Keep WIFI settings on flash/reboot" $EXTRACT/ramdisk/default.prop)" != "" ]; then
			echo ""
		else
			insert_line $EXTRACT/ramdisk/default.prop "# SkyHigh KERNEL" after "debug.atrace.tags.enableflags=0" "\n# Keep WIFI settings on flash/reboot";
		fi;
		if [ "$(grep "ro.securestorage.support=false" $EXTRACT/ramdisk/default.prop)" != "" ]; then
			echo ""
		else
			insert_line $EXTRACT/ramdisk/default.prop "# SkyHigh KERNEL" after "# Keep WIFI settings on flash/reboot" "ro.securestorage.support=false";
		fi
		if [ "$(grep "# Screen mirroring / AllShare Cast fix" $EXTRACT/ramdisk/default.prop)" != "" ]; then
			echo ""
		else
			insert_line $EXTRACT/ramdisk/default.prop "# SkyHigh KERNEL" after "ro.securestorage.support=false" "\n# Screen mirroring / AllShare Cast fix";
		fi;
		if [ "$(grep "wlan.wfd.hdcp=disable" $EXTRACT/ramdisk/default.prop)" != "" ]; then
			echo ""
		else
			insert_line $EXTRACT/ramdisk/default.prop "# SkyHigh KERNEL" after "# Screen mirroring / AllShare Cast fix" "wlan.wfd.hdcp=disable\n";
		fi;

		# init.rc
		if [ "$(grep "import /init.sec_debug.rc" $EXTRACT/ramdisk/init.rc)" != "" ]; then
			remove_line $EXTRACT/ramdisk/init.rc "import /init.sec_debug.rc";
		else
			echo ""
		fi;
		if [ "$(grep "import /init.SkyHigh.rc" $EXTRACT/ramdisk/init.rc)" != "" ]; then
			echo ""
		else
			insert_line $EXTRACT/ramdisk/init.rc "# SkyHigh KERNEL" after "import /init.rilcommon.rc" "import /init.SkyHigh.rc";
		fi;
		if [ "$(grep "write /proc/sys/kernel/randomize_va_space" $EXTRACT/ramdisk/init.rc)" != "" ]; then
			replace_line $EXTRACT/ramdisk/init.rc "    write /proc/sys/kernel/randomize_va_space" "    write /proc/sys/kernel/randomize_va_space 0";
		else
			echo ""
		fi;
		if [ "$(grep "write /sys/block/mmcblk0/queue/scheduler noop" $EXTRACT/ramdisk/init.rc)" != "" ]; then
			remove_line $EXTRACT/ramdisk/init.rc "    write /sys/block/mmcblk0/queue/scheduler noop";
		else
			echo ""
		fi;
		if [ "$(grep "write /sys/block/sda/queue/scheduler noop" $EXTRACT/ramdisk/init.rc)" != "" ]; then
			remove_line $EXTRACT/ramdisk/init.rc "    write /sys/block/sda/queue/scheduler noop";
		else
			echo ""
		fi;
		if [ "$(grep "write /sys/block/mmcblk0/queue/scheduler cfq" $EXTRACT/ramdisk/init.rc)" != "" ]; then
			remove_line $EXTRACT/ramdisk/init.rc "    write /sys/block/mmcblk0/queue/scheduler cfq";
		else
			echo ""
		fi;
		if [ "$(grep "write /sys/block/sda/queue/scheduler cfq" $EXTRACT/ramdisk/init.rc)" != "" ]; then
			remove_line $EXTRACT/ramdisk/init.rc "    write /sys/block/sda/queue/scheduler cfq";
		else
			echo ""
		fi;
		if [ "$(grep "# Call Post-init script" $EXTRACT/ramdisk/init.rc)" != "" ]; then
			echo ""
		else
			INITPATCH=$(cat ./$BK/patch/init_patch)
			echo "$INITPATCH" >> $EXTRACT/ramdisk/init.rc
		fi;

		# file_contexts
		if [ "$(grep "/dev/erandom" $EXTRACT/ramdisk/file_contexts)" != "" ]; then
			echo ""
		else
			insert_line $EXTRACT/ramdisk/file_contexts "# SkyHigh KERNEL" after "u:object_r:uio_device:s0" "/dev/erandom		u:object_r:urandom_device:s0";
		fi;
		if [ "$(grep "/dev/frandom" $EXTRACT/ramdisk/file_contexts)" != "" ]; then
			echo ""
		else
			insert_line $EXTRACT/ramdisk/file_contexts "# SkyHigh KERNEL" before "/dev/urandom" "/dev/frandom		u:object_r:random_device:s0";
		fi;
		if [ "$(grep "/system/xbin(/.*)?" $EXTRACT/ramdisk/file_contexts)" != "" ]; then
			echo ""
		else
			insert_line $EXTRACT/ramdisk/file_contexts "# SkyHigh KERNEL" before "/system/xbin/su" "/system/xbin(/.*)?      u:object_r:system_file:s0";
		fi;

		# init.rilcommon.rc
		if [ "$TARGET" == "N920C" ] ||  [ "$TARGET" == "N9200" ] ||  [ "$TARGET" == "N9208" ] ||  [ "$TARGET" == "G928F" ]; then

			if [ "$(grep "import /init.rilcarrier.rc" $EXTRACT/ramdisk/init.rilcommon.rc)" != "" ]; then
				remove_line $EXTRACT/ramdisk/init.rilcommon.rc "import /init.rilcarrier.rc";
			else
				echo ""
			fi;
			if [ "$(grep "import /init.rilepdg.rc" $EXTRACT/ramdisk/init.rilcommon.rc)" != "" ]; then
				remove_line $EXTRACT/ramdisk/init.rilcommon.rc "import /init.rilepdg.rc";
			else
				echo ""
			fi;
		elif [ "$TARGET" == "N920P" ] ||  [ "$TARGET" == "G920P" ]; then
			if [ "$(grep "import /init.rilepdg.rc" $EXTRACT/ramdisk/init.rilcommon.rc)" != "" ]; then
				remove_line $EXTRACT/ramdisk/init.rilcommon.rc "import /init.rilepdg.rc";
			else
				echo ""
			fi;
		elif [ "$TARGET" == "N920T" ] ||  [ "$TARGET" == "G928T" ]; then
			echo ""
		fi;

		# init.samsungexynos7420.rc
		if [ "$(grep "import init.fac.rc" $EXTRACT/ramdisk/init.samsungexynos7420.rc)" != "" ]; then
			remove_line $EXTRACT/ramdisk/init.samsungexynos7420.rc "import init.fac.rc";
		else
			echo ""
		fi;
		if [ "$(grep "import init.exynos7420_fac.rc" $EXTRACT/ramdisk/init.samsungexynos7420.rc)" != "" ]; then
			remove_line $EXTRACT/ramdisk/init.samsungexynos7420.rc "import init.exynos7420_fac.rc";
		else
			echo ""
		fi;
		if [ "$(grep "import init.remove_recovery.rc" $EXTRACT/ramdisk/init.samsungexynos7420.rc)" != "" ]; then
			remove_line $EXTRACT/ramdisk/init.samsungexynos7420.rc "import init.remove_recovery.rc";
		else
			echo ""
		fi;
		if [ "$(grep "write /proc/sys/vm/dirty_bytes" $EXTRACT/ramdisk/init.samsungexynos7420.rc)" != "" ]; then
			remove_line $EXTRACT/ramdisk/init.samsungexynos7420.rc "    write /proc/sys/vm/dirty_bytes";
		else
			echo ""
		fi;
		if [ "$(grep "write /proc/sys/vm/dirty_background_bytes" $EXTRACT/ramdisk/init.samsungexynos7420.rc)" != "" ]; then
			remove_line $EXTRACT/ramdisk/init.samsungexynos7420.rc "    write /proc/sys/vm/dirty_background_bytes";
		else
			echo ""
		fi;

		# fstab.samsungexynos7420
		if [ "$(grep "/dev/block/platform/15570000.ufs/by-name/CACHE		/cache	f2fs" $EXTRACT/ramdisk/fstab.samsungexynos7420)" != "" ]; then
			echo ""
		else
			insert_line $EXTRACT/ramdisk/fstab.samsungexynos7420 "# SkyHigh KERNEL" before "/dev/block/platform/15570000.ufs/by-name/CACHE		/cache	ext4" "/dev/block/platform/15570000.ufs/by-name/CACHE		/cache	f2fs	nosuid,nodev,noatime,discard,flush_merge							wait,check,formattable";
		fi;
		if [ "$(grep "/dev/block/platform/15570000.ufs/by-name/USERDATA	/data	f2fs" $EXTRACT/ramdisk/fstab.samsungexynos7420)" != "" ]; then
			echo ""
		else
			insert_line $EXTRACT/ramdisk/fstab.samsungexynos7420 "# SkyHigh KERNEL" before "/dev/block/platform/15570000.ufs/by-name/USERDATA	/data	ext4" "/dev/block/platform/15570000.ufs/by-name/USERDATA	/data	f2fs	nosuid,nodev,noatime,discard,flush_merge							wait,check,formattable";
		fi;

		# fstab.samsungexynos7420.fwup
		if [ "$(grep "/dev/block/platform/15570000.ufs/by-name/CACHE		/cache	f2fs" $EXTRACT/ramdisk/fstab.samsungexynos7420.fwup)" != "" ]; then
			echo ""
		else
			insert_line $EXTRACT/ramdisk/fstab.samsungexynos7420.fwup "# SkyHigh KERNEL" before "/dev/block/platform/15570000.ufs/by-name/CACHE		/cache	ext4" "/dev/block/platform/15570000.ufs/by-name/CACHE		/cache	f2fs	nosuid,nodev,noatime,discard,flush_merge							wait,check,formattable";
		fi;

		# SkyHigh init
		rm -rf $EXTRACT/ramdisk/init.SkyHigh.rc
		cp -r ./$BK/patch/init.SkyHigh.rc $EXTRACT/ramdisk

		# Synapse UCI
		if [ -d "$EXTRACT/ramdisk/res" ]; then
			rm -rf $EXTRACT/ramdisk/res
		fi;
		cp -r ./$BK/res $EXTRACT/ramdisk/res
		if [ -f "$EXTRACT/ramdisk/sbin/adbd" ]; then
			# replace adbd with 5.1.1 version
			rm -rf $EXTRACT/ramdisk/sbin/adbd
		fi;
		cp -r ./$BK/sbin/* $EXTRACT/ramdisk/sbin

		echo "Patched ramdisk with SkyHigh";
	else
		sleep 1

		# backup
		backup_file $EXTRACT/ramdisk/default.prop;

		# default.prop
		if [ "$TARGET" == "G928F" ]; then
			if [ "$(grep "# SM-G9287C dual SIM support" $EXTRACT/ramdisk/default.prop)" != "" ]; then
				echo ""
			else
				insert_line $EXTRACT/ramdisk/default.prop "# SkyHigh KERNEL" after "rild.libpath=/system/lib64/libsec-ril.so" "\n# SM-G9287C dual SIM support";
			fi;
			if [ "$(grep "rild.libpath2=/system/lib64/libsec-ril-dsds.so" $EXTRACT/ramdisk/default.prop)" != "" ]; then
				echo ""
			else
				insert_line $EXTRACT/ramdisk/default.prop "# SkyHigh KERNEL" after "# SM-G9287C dual SIM support" "rild.libpath2=/system/lib64/libsec-ril-dsds.so\n";
			fi;
		fi;
		if [ "$(grep "# Keep WIFI settings on flash/reboot" $EXTRACT/ramdisk/default.prop)" != "" ]; then
			echo ""
		else
			insert_line $EXTRACT/ramdisk/default.prop "# SkyHigh KERNEL" after "debug.atrace.tags.enableflags=0" "\n# Keep WIFI settings on flash/reboot";
		fi;
		if [ "$(grep "ro.securestorage.support=false" $EXTRACT/ramdisk/default.prop)" != "" ]; then
			echo ""
		else
			insert_line $EXTRACT/ramdisk/default.prop "# SkyHigh KERNEL" after "# Keep WIFI settings on flash/reboot" "ro.securestorage.support=false";
		fi;
		if [ "$(grep "# Screen mirroring / AllShare Cast fix" $EXTRACT/ramdisk/default.prop)" != "" ]; then
			echo ""
		else
			insert_line $EXTRACT/ramdisk/default.prop "# SkyHigh KERNEL" after "ro.securestorage.support=false" "\n# Screen mirroring / AllShare Cast fix";
		fi;
		if [ "$(grep "wlan.wfd.hdcp=disable" $EXTRACT/ramdisk/default.prop)" != "" ]; then
			echo ""
		else
			insert_line $EXTRACT/ramdisk/default.prop "# SkyHigh KERNEL" after "# Screen mirroring / AllShare Cast fix" "wlan.wfd.hdcp=disable\n";
		fi;

		echo "Patched ramdisk with stock";
	fi;

echo
echo "${grn}***** Patch for cpusets *****${txtrst}"

	# setup for cpusets

	# backup
	backup_file $EXTRACT/ramdisk/init.rc;
	backup_file $EXTRACT/ramdisk/init.samsungexynos7420.rc;

	# init.rc
	if [ "$(grep "write /dev/cpuset/foreground/cpus" $EXTRACT/ramdisk/init.rc)" != "" ]; then
		replace_line $EXTRACT/ramdisk/init.rc "write /dev/cpuset/foreground/cpus" "    write /dev/cpuset/foreground/cpus 0-7";
	else
		echo ""
	fi;
	if [ "$(grep "write /dev/cpuset/foreground/boost/cpus" $EXTRACT/ramdisk/init.rc)" != "" ]; then
		replace_line $EXTRACT/ramdisk/init.rc "write /dev/cpuset/foreground/boost/cpus" "    write /dev/cpuset/foreground/boost/cpus 0-7";
	else
		echo ""
	fi;
	if [ "$(grep "write /dev/cpuset/background/cpus" $EXTRACT/ramdisk/init.rc)" != "" ]; then
		replace_line $EXTRACT/ramdisk/init.rc "write /dev/cpuset/background/cpus" "    write /dev/cpuset/background/cpus 0-7";
	else
		echo ""
	fi;
	if [ "$(grep "write /dev/cpuset/system-background/cpus" $EXTRACT/ramdisk/init.rc)" != "" ]; then
		replace_line $EXTRACT/ramdisk/init.rc "write /dev/cpuset/system-background/cpus" "    write /dev/cpuset/system-background/cpus 0-7";
	else
		echo ""
	fi;
	if [ "$(grep "chown system system /dev/cpuset/system-background" $EXTRACT/ramdisk/init.rc)" != "" ]; then
		echo ""
	else
		insert_line $EXTRACT/ramdisk/init.rc "# SkyHigh KERNEL" before "chown system system /dev/cpuset/tasks" "    chown system system /dev/cpuset/system-background";
	fi;
	if [ "$(grep "chown system system /dev/cpuset/system-background/tasks" $EXTRACT/ramdisk/init.rc)" != "" ]; then
		echo ""
	else
		insert_line $EXTRACT/ramdisk/init.rc "# SkyHigh KERNEL" after "chown system system /dev/cpuset/background/tasks" "    chown system system /dev/cpuset/system-background/tasks";
	fi;
	if [ "$(grep "# set system-background to 0775 so SurfaceFlinger can touch it" $EXTRACT/ramdisk/init.rc)" != "" ]; then
		echo ""
	else
		insert_line $EXTRACT/ramdisk/init.rc "# SkyHigh KERNEL" after "chown system system /dev/cpuset/system-background/tasks" "\n    # set system-background to 0775 so SurfaceFlinger can touch it";
	fi;
	if [ "$(grep "chmod 0775 /dev/cpuset/system-background" $EXTRACT/ramdisk/init.rc)" != "" ]; then
		echo ""
	else
		insert_line $EXTRACT/ramdisk/init.rc "# SkyHigh KERNEL" after "# set system-background to 0775 so SurfaceFlinger can touch it" "    chmod 0775 /dev/cpuset/system-background";
	fi;
	if [ "$(grep "chmod 0664 /dev/cpuset/system-background/tasks" $EXTRACT/ramdisk/init.rc)" != "" ]; then
		echo ""
	else
		insert_line $EXTRACT/ramdisk/init.rc "# SkyHigh KERNEL" after "chmod 0664 /dev/cpuset/background/tasks" "    chmod 0664 /dev/cpuset/system-background/tasks";
	fi;

	# init.samsungexynos7420.rc
	if [ "$(grep "start bootsh" $EXTRACT/ramdisk/init.samsungexynos7420.rc)" != "" ]; then
		echo ""
	else
		insert_line $EXTRACT/ramdisk/init.samsungexynos7420.rc "# SkyHigh KERNEL" after "setprop ro.mst.support 1" "\n    start bootsh";
	fi;
	if [ "$(grep "service bootsh /init.invisible_cpuset.sh" $EXTRACT/ramdisk/init.samsungexynos7420.rc)" != "" ]; then
		echo ""
	else
		insert_line $EXTRACT/ramdisk/init.samsungexynos7420.rc "# SkyHigh KERNEL" after "seclabel u:r:watchdogd:s0" "\nservice bootsh /init.invisible_cpuset.sh";
	fi;
	if [ "$(grep "user root #" $EXTRACT/ramdisk/init.samsungexynos7420.rc)" != "" ]; then
		echo ""
	else
		insert_line $EXTRACT/ramdisk/init.samsungexynos7420.rc "# SkyHigh KERNEL" after "service bootsh /init.invisible_cpuset.sh" "    user root #";
	fi;
	if [ "$(grep "oneshot #" $EXTRACT/ramdisk/init.samsungexynos7420.rc)" != "" ]; then
		echo ""
	else
		insert_line $EXTRACT/ramdisk/init.samsungexynos7420.rc "# SkyHigh KERNEL" after "user root #" "    oneshot #";
	fi;
	if [ "$(grep "disabled #" $EXTRACT/ramdisk/init.samsungexynos7420.rc)" != "" ]; then
		echo ""
	else
		insert_line $EXTRACT/ramdisk/init.samsungexynos7420.rc "# SkyHigh KERNEL" after "oneshot #" "    disabled #";
	fi;
	# init.invisible_cpuset.sh
	rm -rf $EXTRACT/ramdisk/init.invisible_cpuset.sh
	cp -r ./$BK/patch/init.invisible_cpuset.sh $EXTRACT/ramdisk

	echo "Patched ramdisk for cpusets";

echo
read -p "${grn}PRE-patch ramdisk for SuperSU? (y/n) > ${txtrst}";

	if [ "$REPLY" == "y" -o "$REPLY" == "Y" ]; then
		sleep 1

		# backup
		backup_file $EXTRACT/ramdisk/file_contexts;
		backup_file $EXTRACT/ramdisk/fstab.goldfish;
		backup_file $EXTRACT/ramdisk/init.rc;
		backup_file $EXTRACT/ramdisk/init.environ.rc;
		backup_file $EXTRACT/ramdisk/fstab.samsungexynos7420;
		backup_file $EXTRACT/ramdisk/fstab.samsungexynos7420.fwup;

		# file_contexts
		if [ "$(grep "# SuperSU" $EXTRACT/ramdisk/file_contexts)" != "" ]; then
			echo ""
		else
			CONTEXTS_PATCH=$(cat ./$BK/patch/file_contexts_su_patch)
			echo "$CONTEXTS_PATCH" >> $EXTRACT/ramdisk/file_contexts
		fi;

		# fstab.goldfish
		if [ "$(grep "ro,barrier=1" $EXTRACT/ramdisk/fstab.goldfish)" != "" ]; then
			replace_line $EXTRACT/ramdisk/fstab.goldfish "/dev/block/mtdblock0" "/dev/block/mtdblock0                                    /system             ext4      ro,noatime,barrier=1				   wait";
		else
			echo ""
		fi;

		# fstab.samsungexynos7420
		if [ "$(grep "wait,support_scfs,verify" $EXTRACT/ramdisk/fstab.samsungexynos7420)" != "" ]; then
			replace_line $EXTRACT/ramdisk/fstab.samsungexynos7420 "/dev/block/platform/15570000.ufs/by-name/SYSTEM" "/dev/block/platform/15570000.ufs/by-name/SYSTEM		/system	ext4	ro,noatime,errors=panic,noload									wait";
		else
			echo ""
		fi;

		# fstab.samsungexynos7420.fwup
		if [ "$(grep "wait,support_scfs,verify" $EXTRACT/ramdisk/fstab.samsungexynos7420.fwup)" != "" ]; then
			replace_line $EXTRACT/ramdisk/fstab.samsungexynos7420.fwup "/dev/block/platform/15570000.ufs/by-name/SYSTEM" "/dev/block/platform/15570000.ufs/by-name/SYSTEM		/system	ext4	ro,noatime,errors=panic,noload									wait";
		else
			echo ""
		fi;

		# init.environ.rc
		if [ "$(grep "export PATH /su/bin:/sbin:/vendor/bin:/system/sbin:/system/bin:/su/xbin:/system/xbin" $EXTRACT/ramdisk/init.environ.rc)" != "" ]; then
			echo ""
		else
			insert_line $EXTRACT/ramdisk/init.environ.rc "# SkyHigh KERNEL" before "export ANDROID_BOOTLOGO 1" "    export PATH /su/bin:/sbin:/vendor/bin:/system/sbin:/system/bin:/su/xbin:/system/xbin";
		fi;

		# init.rc
		if [ "$(grep "import init.supersu.rc" $EXTRACT/ramdisk/init.rc)" != "" ]; then
			echo ""
		else
			insert_line $EXTRACT/ramdisk/init.rc "# SkyHigh KERNEL" before "on early-init" "import init.supersu.rc\n";
		fi;
		if [ "$(grep "mkdir /su 0755 root root" $EXTRACT/ramdisk/init.rc)" != "" ]; then
			echo ""
		else
			insert_line $EXTRACT/ramdisk/init.rc "# SkyHigh KERNEL" before "mkdir /data 0771 system system" "     mkdir /su 0755 root root # create mount point for SuperSU";
		fi;
		if [ "$(grep "# SuperSU:PATCH:278" $EXTRACT/ramdisk/init.rc)" != "" ]; then
			echo ""
		else
			SUPATCH=$(cat ./$BK/patch/su_patch)
			echo "$SUPATCH" >> $EXTRACT/ramdisk/init.rc
		fi;
		if [ "$(grep "setprop selinux.reload_policy 1" $EXTRACT/ramdisk/init.rc)" != "" ]; then
			sed -i "/setprop selinux.reload_policy 1/d" $EXTRACT/ramdisk/init.rc;
		else
			echo ""
		fi;

		# create empty su folder
		if [ ! -d $EXTRACT/ramdisk/su ]; then
			mkdir -p $EXTRACT/ramdisk/su;
		fi;

		# launch_daemonsu.sh
		if [ -f "$EXTRACT/ramdisk/sbin/launch_daemonsu.sh" ]; then
			rm -rf $EXTRACT/ramdisk/sbin/launch_daemonsu.sh
		fi;
		cp -r ./$BK/patch/launch_daemonsu.sh $EXTRACT/ramdisk/sbin/

		# init.supersu.rc
		if [ -f "$EXTRACT/ramdisk/init.supersu.rc" ]; then
			rm -rf $EXTRACT/ramdisk/init.supersu.rc
		fi;
		cp -r ./$BK/patch/init.supersu.rc $EXTRACT/ramdisk/

		# sepolicy
		if [ -f "$EXTRACT/ramdisk/sepolicy" ]; then
			# replace with patched version
			rm -rf $EXTRACT/ramdisk/sepolicy
		fi;
		cp -r ./$BK/patch/sepolicy $EXTRACT/ramdisk/

		echo "ramdisk PRE-patched";
	else
		echo "ramdisk NOT PRE-patched";
	fi;

echo
read -p "${grn}Patch ramdisk for UX beta firmware? (y/n) > ${txtrst}";

	if [ "$REPLY" == "y" -o "$REPLY" == "Y" ]; then
		sleep 1

		# backup
		backup_file $EXTRACT/ramdisk/init.environ.rc;

		# init.environ.rc
		if [ "$(grep ":/system/framework/ssrm.jar" $EXTRACT/ramdisk/init.environ.rc)" != "" ]; then
			echo ""
		else
			replace_line $EXTRACT/ramdisk/init.environ.rc "export SYSTEMSERVERCLASSPATH /system/framework/services.jar:/system/framework/ethernet-service.jar:/system/framework/wifi-service.jar" "    export SYSTEMSERVERCLASSPATH /system/framework/services.jar:/system/framework/ethernet-service.jar:/system/framework/wifi-service.jar:/system/framework/ssrm.jar";
		fi;

		echo "ramdisk UX patched";
	else
		echo "ramdisk NOT UX patched";
	fi;

echo
read -p "${grn}Patch ramdisk for lazytime mount for EXT$ FS? (y/n) > ${txtrst}";

	if [ "$REPLY" == "y" -o "$REPLY" == "Y" ]; then
		sleep 1

		# backup
		backup_file $EXTRACT/ramdisk/init.samsungexynos7420.rc;


		# init.samsungexynos7420.rc
		if [ "$(grep "start lazy_mount" $EXTRACT/ramdisk/init.samsungexynos7420.rc)" != "" ]; then
			echo ""
		else
			insert_line $EXTRACT/ramdisk/init.samsungexynos7420.rc "# SkyHigh KERNEL" after "setprop ro.mst.support 1" "\n    start lazy_mount";
		fi;
		if [ "$(grep "wait /dev/block/mounted" $EXTRACT/ramdisk/init.samsungexynos7420.rc)" != "" ]; then
			echo ""
		else
			insert_line $EXTRACT/ramdisk/init.samsungexynos7420.rc "# SkyHigh KERNEL" after "start lazy_mount" "    wait /dev/block/mounted";
		fi;
		if [ "$(grep "service lazy_mount /init.lazytime_mount.sh" $EXTRACT/ramdisk/init.samsungexynos7420.rc)" != "" ]; then
			echo ""
		else
			insert_line $EXTRACT/ramdisk/init.samsungexynos7420.rc "# SkyHigh KERNEL" after "seclabel u:r:watchdogd:s0" "\nservice lazy_mount /init.lazytime_mount.sh";
		fi;
		if [ "$(grep "user root ##" $EXTRACT/ramdisk/init.samsungexynos7420.rc)" != "" ]; then
			echo ""
		else
			insert_line $EXTRACT/ramdisk/init.samsungexynos7420.rc "# SkyHigh KERNEL" after "service lazy_mount /init.lazytime_mount.sh" "    user root ##";
		fi;
		if [ "$(grep "oneshot ##" $EXTRACT/ramdisk/init.samsungexynos7420.rc)" != "" ]; then
			echo ""
		else
			insert_line $EXTRACT/ramdisk/init.samsungexynos7420.rc "# SkyHigh KERNEL" after "user root ##" "    oneshot ##";
		fi;
		if [ "$(grep "disabled ##" $EXTRACT/ramdisk/init.samsungexynos7420.rc)" != "" ]; then
			echo ""
		else
			insert_line $EXTRACT/ramdisk/init.samsungexynos7420.rc "# SkyHigh KERNEL" after "oneshot ##" "    disabled ##";
		fi;

		# init.lazytime_mount.sh
		rm -rf $EXTRACT/ramdisk/init.lazytime_mount.sh
		cp -r ./$BK/patch/init.lazytime_mount.sh $EXTRACT/ramdisk

		echo "lazytime mount patched";
	else
		echo "lazytime mount NOT patched";
	fi;

	# license agreement
	if [ -f "$EXTRACT/ramdisk/LICENSE.md" ]; then
		rm -rf $EXTRACT/ramdisk/LICENSE.md;
		cp -r ./$BK/patch/LICENSE.md $EXTRACT/ramdisk/;
	else
		cp -r ./$BK/patch/LICENSE.md $EXTRACT/ramdisk/;
	fi;

	# clean up patch temp files
	find . -type f -name "*~" -exec rm -f {} \;


############################## MODULES GENERATION ##############################

echo
echo "${bldcya}***** Make modules *****${txtrst}"
echo

	# make modules
	make -j$(($NUMBEROFCPUS + 1)) modules ARCH=arm64  || exit 1;

	# find modules
	for i in $(find "${KERNELDIR}" -name '*.ko'); do
		cp -av "$i" ./$BK/system/lib/modules/;
	done;

	if [ -f "./$BK/system/lib/modules/*" ]; then
		chmod 0755 ./$BK/system/lib/modules/*
		${CROSS_COMPILE}strip --strip-debug ./$BK/system/lib/modules/*.ko
		${CROSS_COMPILE}strip --strip-unneeded ./$BK/system/lib/modules/*
	fi;

echo
echo "Modules done"


############################## RAMDISK GENERATION ##############################

echo
echo "${bldcya}***** Make ramdisk *****${txtrst}"
echo

	# fix ramdisk permissions
	cd ${KERNELDIR}/$BK/patch || exit 1;
	cp ./ramdisk_fix_permissions.sh $EXTRACT/ramdisk/ramdisk_fix_permissions.sh
	cd $EXTRACT/ramdisk || exit 1;
	chmod 0777 ramdisk_fix_permissions.sh
	./ramdisk_fix_permissions.sh 2>/dev/null
	rm -f ramdisk_fix_permissions.sh
	echo "Permissions fixed"

	# make ramdisk
	cd ${KERNELDIR}/$BK/tools || exit 1;
	./mkbootfs $EXTRACT/ramdisk | lzop -9 > $EXTRACT/ramdisk.lzo

echo "Ramdisk done"


############################# BOOT.IMG GENERATION ##############################

echo
echo "${bldcya}***** Make boot.img *****${txtrst}"
echo

read -p "${grn}Use Stock dt.img? (y/n) > ${txtrst}";
	if [ "$REPLY" == "y" -o "$REPLY" == "Y" ]; then
		./mkbootimg --kernel $EXTRACT/Image --dt $EXTRACT/dt.img --board $board --ramdisk $EXTRACT/ramdisk.lzo --base 0x10000000 --kernel_offset 0x00008000 --ramdisk_offset 0x01000000 --tags_offset 0x00000100 --pagesize 2048 -o $EXTRACT/boot.img;
		echo "Build with stock dt.img";
	else
		./mkbootimg --kernel $EXTRACT/Image --dt ${KERNELDIR}/dt.img --board $board --ramdisk $EXTRACT/ramdisk.lzo --base 0x10000000 --kernel_offset 0x00008000 --ramdisk_offset 0x01000000 --tags_offset 0x00000100 --pagesize 2048 -o $EXTRACT/boot.img;
		echo "Build with custom dt.img";
	fi;

	echo -n "SEANDROIDENFORCE" >> $EXTRACT/boot.img

	# check boot.img less than partition size
	GENERATED_SIZE=$(stat -c %s $EXTRACT/boot.img)
	if [[ $GENERATED_SIZE -gt $PARTITION_SIZE ]]; then
		echo
		echo "${bldred}$TARGET${txtrst} ${red}boot.img size larger than partition size !!${txtrst}" 1>&2;
		cd ${KERNELDIR} || exit 1;

		echo
		read -p "${grn}Make clean source? (y/n) > ${txtrst}";
			if [ "$REPLY" == "y" -o "$REPLY" == "Y" ]; then
				make clean;
				make distclean;
				make mrproper;
				echo;
				echo "Source cleaned";
				echo;
				exit 1;
			else
				echo "Source not cleaned";
				echo;
				exit 1;
			fi;
	fi;


############################## ARCHIVE GENERATION ##############################

echo
echo "${bldcya}***** Make archives *****${txtrst}"
echo

	cd ${KERNELDIR}/$BK || exit 1;

	cp $EXTRACT/boot.img ${KERNELDIR}/output/$TARGET/
	cp -R ./aroma ${KERNELDIR}/output/$TARGET/
	cp -R ./busybox ${KERNELDIR}/output/$TARGET/
	cp -R ./defaults ${KERNELDIR}/output/$TARGET/
	cp -R ./META-INF ${KERNELDIR}/output/$TARGET/
	cp -R ./supersu ${KERNELDIR}/output/$TARGET/
	cp -R ./system ${KERNELDIR}/output/$TARGET/

	cd ${KERNELDIR}/output/$TARGET || exit 1;
	GETVER=$(grep 'SkyHigh_MM_*v' ${KERNELDIR}/.config | sed 's/.*".//g' | sed 's/-S.*//g')

	zip -r SM-$TARGET--kernel-${GETVER}-$(date +[%y-%m-%d]).zip .
	tar -H ustar -c boot.img > SM-$TARGET--kernel-${GETVER}-$(date +[%y-%m-%d]).tar
	md5sum -t SM-$TARGET--kernel-${GETVER}-$(date +[%y-%m-%d]).tar >> SM-$TARGET--kernel-${GETVER}-$(date +[%y-%m-%d]).tar
	mv SM-$TARGET--kernel-${GETVER}-$(date +[%y-%m-%d]).tar SM-$TARGET--kernel-${GETVER}-$(date +[%y-%m-%d]).tar.md5

echo
echo "${bldred}$TARGET${txtrst} ${red}build completed !!${txtrst}"


############################ OPTIONAL SOURCE CLEAN #############################

echo
echo "${bldcya}***** Clean source *****${txtrst}"
echo

	cd ${KERNELDIR} || exit 1;

read -p "${grn}Make clean source? (y/n) > ${txtrst}";
	if [ "$REPLY" == "y" -o "$REPLY" == "Y" ]; then
		make clean;
		make distclean;
		make mrproper;
		echo;
		echo "Source cleaned";
	else
		echo "Source not cleaned";
	fi;

echo
echo "${bldcya}***** Flashable zip found in /output/$TARGET directory *****${txtrst}"
echo
# build script ends
