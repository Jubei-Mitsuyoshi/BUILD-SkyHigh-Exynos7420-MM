#!/bin/bash
#
# Copyright (C) 2017 UpInTheAir


# COLORIZE & ADD TEXT PARAMETERS

	export red;                             # red
	red=$(tput setaf 1);
	export grn;                             # green
	grn=$(tput setaf 2);
	export blu;                             # blue
	blu=$(tput setaf 4);
	export cya;                             # cyan
	cya=$(tput setaf 6);
	export txtbld;                          # bold
	txtbld=$(tput bold);
	export bldred;                          # bold red
	bldred=${txtbld}$(tput setaf 1);
	export bldgrn;                          # bold green
	bldgrn=${txtbld}$(tput setaf 2);
	export bldblu;                          # bold blue
	bldblu=${txtbld}$(tput setaf 4);
	export bldcya;                          # bold cyan
	bldcya=${txtbld}$(tput setaf 6);
	export txtrst;                          # reset
	txtrst=$(tput sgr0);


# LOCATION

	export KERNELDIR;
	KERNELDIR=$(readlink -f .);


# SET BUILD VARIABLES

	export BK=build_kernel;

	export EXTRACT="${KERNELDIR}"/$BK/$TARGET/extract;

	export BOOT="${KERNELDIR}"/$BK/$TARGET/boot.img;

	export DATE;
	DATE=$(date +[%F]);

	export AROMA_CONFIG="${KERNELDIR}"/$BK/META-INF/com/google/android/aroma-config;

	# N920* G928*
	export PARTITION_SIZE=29360128;

	# omitt timestamp line in generated .config
	export KCONFIG_NOTIMESTAMP=true;

	export ARCH=arm64;

	export SUB_ARCH=arm64;


# CHECK 'CCACHE' IS INSTALLED

	if [ ! -e /usr/bin/ccache ]; then
		echo "You must install 'ccache' to continue";
		sudo apt-get install ccache;
	fi;


# CHECK 'XMLLINT' IS INSTALLED

	if [ ! -e /usr/bin/xmllint ]; then
		echo "You must install 'xmllint' to continue";
		sudo apt-get install libxml2-utils;
	fi;


# CHECK 'PARALLEL' IS INSTALLED

	if [ ! -e /usr/bin/parallel ]; then
		echo "You must install 'parallel' to continue";
		sudo apt-get install parallel;
	fi;


# RESET CURRENT LOCAL BRANCH TO GIT REPO

	function parse_git_branch() {
		git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e "s/* \(.*\)/\1/"
	}
	BRANCH=$(parse_git_branch);

	echo;
	read -p "${grn}Reset current local branch to gitHub repo? (y/n) > ${txtrst}";

		if [ "$REPLY" == "y" ] || [ "$REPLY" == "Y" ]; then
			git reset --hard origin/"$BRANCH" && git clean -fd;
			echo;
			echo "Local branch reset to $BRANCH";
		else
			echo "Local branch not reset";
		fi;


# MAKE CLEAN SOURCE

	echo;
	read -p "${grn}Make clean source? (y/n) > ${txtrst}";

		if [ "$REPLY" == "y" ] || [ "$REPLY" == "Y" ]; then
			make clean;
			make distclean;
			make mrproper;
			echo;
			echo "Source cleaned";
		else
			echo "Source not cleaned";
		fi;


# CLEAR CCACHE

	echo;
	read -p "${grn}Clear ccache but keeping the config file? (y/n) > ${txtrst}";

		if [ "$REPLY" == "y" ] || [ "$REPLY" == "Y" ]; then
			ccache -C;
		else
			echo "ccache not cleared";
		fi;


# RAMDISK ALGORITHM

	echo;
	read -p "${grn}Use lzo de/compression algorithm (y/n) > ${txtrst}";

		if [ "$REPLY" == "y" ] || [ "$REPLY" == "Y" ]; then
			export COMP="lzop -9";
			export EXT="lzo";
			echo "LZO selected";
		else
			export COMP="gzip -9";
			export EXT="gz";
			echo "GZIP selected";
		fi;


# DT.IMG

	echo;
	read -p "${grn}Use Stock dt.img? (y/n) > ${txtrst}";

		if [ "$REPLY" == "y" ] || [ "$REPLY" == "Y" ]; then
			DT="$EXTRACT";
			echo "Stock dt.img";
		else
			DT="${KERNELDIR}";
			echo "Custom dt.img";
		fi;


# TARGET VARIANT

	TARGET=$1;

	if [ "$TARGET" != "" ]; then
		echo;
		echo "Starting your build for ${red}$TARGET${txtrst}";
		sleep 2;
	else
		echo
		echo "You need to define your device target!";
		echo "example: build_kernel.sh N920C";
		echo "example: build_kernel.sh N920P";
		echo "example: build_kernel.sh N920T";
		echo "example: build_kernel.sh N9200";
		echo "example: build_kernel.sh N9208";
		echo "example: build_kernel.sh G928F";
		echo "example: build_kernel.sh G928P";
		echo "example: build_kernel.sh G928T";
		exit 1;
	fi;

	# SM-N920 C/CD/G/I
	if [ "$TARGET" == "N920C" ] ; then
		export KERNEL_CONFIG="SkyHigh_N920C_defconfig";
		export BOARD="SYSMAGIC000KU";
	# SM-N920 P (Sprint)
	elif [ "$TARGET" == "N920P" ] ; then
		export KERNEL_CONFIG="SkyHigh_N920P_defconfig";
		export BOARD="SYSMAGIC000KU";
	# SM-N920 T/W8
	elif [ "$TARGET" == "N920T" ] ; then
		export KERNEL_CONFIG="SkyHigh_N920T_defconfig";
		export BOARD="SYSMAGIC000KU";
	# SM-N9200 HK
	elif [ "$TARGET" == "N9200" ] ; then
		export KERNEL_CONFIG="SkyHigh_N9200_HK_defconfig";
		export BOARD="FPRPNLCC000KU";
	# SM-N9208 SEA
	elif [ "$TARGET" == "N9208" ] ; then
		export KERNEL_CONFIG="SkyHigh_N9208_SEA_defconfig";
		export BOARD="SYSMAGIC000KU";
	# SM-G928 C/F/G/I/7C
	elif [ "$TARGET" == "G928F" ] ; then
		export KERNEL_CONFIG="SkyHigh_G928F_defconfig";
		export BOARD="SYSMAGIC000KU";
	# SM-G928 P (Sprint)
	elif [ "$TARGET" == "G928P" ] ; then
		export KERNEL_CONFIG="SkyHigh_G928P_defconfig";
		export BOARD="SYSMAGIC000KU";
	# SM-G928 T/W8
	elif [ "$TARGET" == "G928T" ] ; then
		export KERNEL_CONFIG="SkyHigh_G928T_defconfig";
		export BOARD="SYSMAGIC000KU";
	fi;


# START BUILD

	export DATE_START;
	DATE_START=$(date +"%s");


# APPEND BUILD DATE TO CONFIG

	# kernel config
	sed -i "s/\[[^][]*\]/$DATE/g" "${KERNELDIR}"/arch/arm64/configs/"$KERNEL_CONFIG";

	# Aroma config
	sed -i "s/\[[^][]*\]/$DATE/g" "$AROMA_CONFIG";


# TOOLCHAIN

	# GCC 6.3.1 20170122 https://gitlab.com/Flash-ROM/aarch64-linux-android-6.x
	export CROSS_COMPILE=~/Toolchains/aarch64-linux-android-6.x/bin/aarch64-linux-android-;


# CPU CORE

	export NUMBEROFCPUS;
	NUMBEROFCPUS=$(grep -c 'processor' /proc/cpuinfo);


# MAKE CONFIG

	if [ ! -f "${KERNELDIR}"/.config ]; then
		echo;
		echo "${bldcya}***** Writing Config *****${txtrst}";

		cp "${KERNELDIR}"/arch/arm64/configs/"$KERNEL_CONFIG" .config;
		make ARCH=arm64 "$KERNEL_CONFIG";
	fi;


# CLEAN UP

	echo;
	echo "${bldcya}***** Clean up first *****${txtrst}";

	# cleanup
	find . -type f \( -iname \*.bkp \
		       -o -iname \*EMPTY_DIRECTORY \
		       -o -iname \*Image \
		       -o -iname \*dt.img \
		       -o -iname \*.old \
		       -o -iname \*.org \
		       -o -iname \*.orig \
		       -o -iname \*~ \
		       -o -iname \*.rej \) \
		       | parallel --no-notice rm -fv {};

	# cleanup old working & output directories
	rm -rf "$EXTRACT"
	rm -rf "${KERNELDIR}"/output/"$TARGET"/*

	echo "Clean up done";


# UNPACK BOOT.IMG

	echo;
	echo "${bldcya}***** Unpack boot.img *****${txtrst}";

	cd "${KERNELDIR}"/$BK/tools || exit 1;

	./mkboot "${KERNELDIR}"/$BK/"$TARGET"/boot.img "$EXTRACT";


# COMPILE IMAGES

	echo;
	echo "${bldcya}***** Compiling kernel *****${txtrst}";

	cd "${KERNELDIR}" || exit 1;

	if [ "$USER" != "root" ]; then
		make CONFIG_DEBUG_SECTION_MISMATCH=y -j$((NUMBEROFCPUS + 1)) Image ARCH=arm64;
	else
		make -j$((NUMBEROFCPUS + 1)) Image ARCH=arm64;
	fi;

	if [ -e "${KERNELDIR}"/arch/arm64/boot/Image ]; then
		echo;
		echo "${bldcya}***** Final Touch for Kernel *****${txtrst}";
		echo;

		stat "${KERNELDIR}"/arch/arm64/boot/Image || exit 1;
		mv ./arch/arm64/boot/Image "$EXTRACT";
		echo;
		echo "${grn}--- Creating custom dt.img ---${txtrst}";
		echo;
		# stock generated tools
		./$BK/tools/dtbtool -o dt.img -s 2048 -p ./scripts/dtc/dtc ./arch/arm64/boot/dts/;
	else
		echo "${bldred}Kernel STUCK in BUILD!${txtrst}";
		echo;
		while true; do
			read -p "${grn}Do you want to run a Make command to check the error?  (y/n) > ${txtrst}" yn;
			case $yn in
				[Yy]* ) make Image ARCH=arm64; echo ; exit;;
				[Nn]* ) echo; exit;;
				* ) echo "Please answer yes or no.";;
			esac
		done;
	fi;


# RAMDISK PATCH

	echo;
	echo "${bldcya}***** Patch ramdisk *****${txtrst}";

	cd "${KERNELDIR}" || exit 1;

	backup_file() { cp "$1" "$1~"; }

	replace_string() {
		if [ -z "$(grep "$2" "$1")" ]; then
			sed -i "s;${3};${4};" "$1";
		fi;
	}

	insert_line() {
		if [ -z "$(grep "$2" "$1")" ]; then
			case $3 in
				before) offset=0;;
				after) offset=1;;
			esac;
			line=$(($(grep -n "$4" "$1" | cut -d: -f1) + offset));
			sed -i "${line}s;^;${5}\n;" "$1";
		fi;
	}

	replace_line() {
		if [ ! -z "$(grep "$2" "$1")" ]; then
			line=$(grep -n "$2" "$1" | cut -d: -f1);
			sed -i "${line}s;.*;${3};" "$1";
		fi;
	}

	remove_line() {
		if [ ! -z "$(grep "$2" "$1")" ]; then
			line=$(grep -n "$2" "$1" | cut -d: -f1);
			sed -i "${line}d" "$1";
		fi;
	}

	# backup
	backup_file "$EXTRACT"/ramdisk/default.prop;
	backup_file "$EXTRACT"/ramdisk/file_contexts;
	backup_file "$EXTRACT"/ramdisk/fstab.goldfish;
	backup_file "$EXTRACT"/ramdisk/fstab.samsungexynos7420;
	backup_file "$EXTRACT"/ramdisk/fstab.samsungexynos7420.fwup;
	backup_file "$EXTRACT"/ramdisk/init.environ.rc;
	backup_file "$EXTRACT"/ramdisk/init.rc;
	backup_file "$EXTRACT"/ramdisk/init.rilcommon.rc;
	backup_file "$EXTRACT"/ramdisk/init.samsungexynos7420.rc;

	# default.prop
	if [ "$TARGET" == "G928F" ]; then
		insert_line "$EXTRACT"/ramdisk/default.prop "# SkyHigh KERNEL" after "rild.libpath=/system/lib64/libsec-ril.so" "\n# SM-G9287C dual SIM support";
		insert_line "$EXTRACT"/ramdisk/default.prop "# SkyHigh KERNEL" after "# SM-G9287C dual SIM support" "rild.libpath2=/system/lib64/libsec-ril-dsds.so\n";
	fi;
	if [ "$(grep "persist.security.ams.enforcing=1" "$EXTRACT"/ramdisk/default.prop)" != "" ]; then
		replace_string "$EXTRACT"/ramdisk/default.prop "persist.security.ams.enforcing=0" "persist.security.ams.enforcing=1" "persist.security.ams.enforcing=0";
	elif [ "$(grep "persist.security.ams.enforcing=3" "$EXTRACT"/ramdisk/default.prop)" != "" ]; then
		replace_string "$EXTRACT"/ramdisk/default.prop "persist.security.ams.enforcing=0" "persist.security.ams.enforcing=3" "persist.security.ams.enforcing=0";
	fi;
	replace_string "$EXTRACT"/ramdisk/default.prop "ro.secure=0" "ro.secure=1" "ro.secure=0";
	replace_string "$EXTRACT"/ramdisk/default.prop "ro.debuggable=1" "ro.debuggable=0" "ro.debuggable=1";
	replace_string "$EXTRACT"/ramdisk/default.prop "ro.adb.secure=0" "ro.adb.secure=1" "ro.adb.secure=0";
	replace_string "$EXTRACT"/ramdisk/default.prop "persist.sys.usb.config=mtp,adb" "persist.sys.usb.config=mtp" "persist.sys.usb.config=mtp,adb";
	insert_line "$EXTRACT"/ramdisk/default.prop "# SkyHigh KERNEL" after "debug.atrace.tags.enableflags=0" "\n# Keep WIFI settings on flash/reboot";
	insert_line "$EXTRACT"/ramdisk/default.prop "# SkyHigh KERNEL" after "# Keep WIFI settings on flash/reboot" "ro.securestorage.support=false";
	insert_line "$EXTRACT"/ramdisk/default.prop "# SkyHigh KERNEL" after "ro.securestorage.support=false" "\n# Screen mirroring / AllShare Cast fix";
	insert_line "$EXTRACT"/ramdisk/default.prop "# SkyHigh KERNEL" after "# Screen mirroring / AllShare Cast fix" "wlan.wfd.hdcp=disable\n";

	# file_contexts
	insert_line "$EXTRACT"/ramdisk/file_contexts "# SkyHigh KERNEL" after "u:object_r:uio_device:s0" "/dev/erandom		u:object_r:urandom_device:s0";
	insert_line "$EXTRACT"/ramdisk/file_contexts "# SkyHigh KERNEL" before "/dev/urandom" "/dev/frandom		u:object_r:random_device:s0";
	insert_line "$EXTRACT"/ramdisk/file_contexts "# SkyHigh KERNEL" before "/system/xbin/su" "/system/xbin(/.*)?      u:object_r:system_file:s0";

	# init.rc
	remove_line "$EXTRACT"/ramdisk/init.rc "import /init.sec_debug.rc";
	insert_line "$EXTRACT"/ramdisk/init.rc "# SkyHigh KERNEL" after "import /init.rilcommon.rc" "import /init.SkyHigh.rc";
	replace_line "$EXTRACT"/ramdisk/init.rc "    write /proc/sys/kernel/randomize_va_space" "    write /proc/sys/kernel/randomize_va_space 0";
	remove_line "$EXTRACT"/ramdisk/init.rc "    write /sys/block/mmcblk0/queue/scheduler noop";
	remove_line "$EXTRACT"/ramdisk/init.rc "    write /sys/block/sda/queue/scheduler noop";
	remove_line "$EXTRACT"/ramdisk/init.rc "    write /sys/block/mmcblk0/queue/scheduler cfq";
	remove_line "$EXTRACT"/ramdisk/init.rc "    write /sys/block/sda/queue/scheduler cfq";

	# init.rilcommon.rc
	if [ "$TARGET" == "N920C" ] ||  [ "$TARGET" == "N9200" ] ||  [ "$TARGET" == "N9208" ] ||  [ "$TARGET" == "G928F" ]; then
		remove_line "$EXTRACT"/ramdisk/init.rilcommon.rc "import /init.rilcarrier.rc";
		remove_line "$EXTRACT"/ramdisk/init.rilcommon.rc "import /init.rilepdg.rc";
	elif [ "$TARGET" == "N920P" ] ||  [ "$TARGET" == "G920P" ]; then
		remove_line "$EXTRACT"/ramdisk/init.rilcommon.rc "import /init.rilepdg.rc";
	fi;

	# init.samsungexynos7420.rc
	remove_line "$EXTRACT"/ramdisk/init.samsungexynos7420.rc "import init.fac.rc";
	remove_line "$EXTRACT"/ramdisk/init.samsungexynos7420.rc "import init.exynos7420_fac.rc";
	remove_line "$EXTRACT"/ramdisk/init.samsungexynos7420.rc "import init.remove_recovery.rc";
	remove_line "$EXTRACT"/ramdisk/init.samsungexynos7420.rc "    write /proc/sys/vm/dirty_bytes";
	remove_line "$EXTRACT"/ramdisk/init.samsungexynos7420.rc "    write /proc/sys/vm/dirty_background_bytes";

	# CPUSets
	replace_line "$EXTRACT"/ramdisk/init.rc "write /dev/cpuset/foreground/cpus" "    write /dev/cpuset/foreground/cpus 0-7";
	replace_line "$EXTRACT"/ramdisk/init.rc "write /dev/cpuset/foreground/boost/cpus" "    write /dev/cpuset/foreground/boost/cpus 0-7";
	replace_line "$EXTRACT"/ramdisk/init.rc "write /dev/cpuset/background/cpus" "    write /dev/cpuset/background/cpus 0-7";
	replace_line "$EXTRACT"/ramdisk/init.rc "write /dev/cpuset/system-background/cpus" "    write /dev/cpuset/system-background/cpus 0-7";
	insert_line "$EXTRACT"/ramdisk/init.rc "# SkyHigh KERNEL" before "chown system system /dev/cpuset/tasks" "    chown system system /dev/cpuset/system-background";
	insert_line "$EXTRACT"/ramdisk/init.rc "# SkyHigh KERNEL" after "chown system system /dev/cpuset/background/tasks" "    chown system system /dev/cpuset/system-background/tasks";
	insert_line "$EXTRACT"/ramdisk/init.rc "# SkyHigh KERNEL" after "chown system system /dev/cpuset/system-background/tasks" "\n    # set system-background to 0775 so SurfaceFlinger can touch it";
	insert_line "$EXTRACT"/ramdisk/init.rc "# SkyHigh KERNEL" after "# set system-background to 0775 so SurfaceFlinger can touch it" "    chmod 0775 /dev/cpuset/system-background";
	insert_line "$EXTRACT"/ramdisk/init.rc "# SkyHigh KERNEL" after "chmod 0664 /dev/cpuset/background/tasks" "    chmod 0664 /dev/cpuset/system-background/tasks";

	insert_line "$EXTRACT"/ramdisk/init.samsungexynos7420.rc "# SkyHigh KERNEL" after "setprop ro.mst.support 1" "\n    start bootsh";
	insert_line "$EXTRACT"/ramdisk/init.samsungexynos7420.rc "# SkyHigh KERNEL" after "seclabel u:r:watchdogd:s0" "\nservice bootsh /init.invisible_cpuset.sh";
	insert_line "$EXTRACT"/ramdisk/init.samsungexynos7420.rc "# SkyHigh KERNEL" after "service bootsh /init.invisible_cpuset.sh" "    user root #";
	insert_line "$EXTRACT"/ramdisk/init.samsungexynos7420.rc "# SkyHigh KERNEL" after "user root #" "    oneshot #";
	insert_line "$EXTRACT"/ramdisk/init.samsungexynos7420.rc "# SkyHigh KERNEL" after "oneshot #" "    disabled #";

	cp -r ./"$BK"/patch/init.invisible_cpuset.sh "$EXTRACT"/ramdisk;

	# lazytime mount for EXT4 FS
	insert_line "$EXTRACT"/ramdisk/init.samsungexynos7420.rc "# SkyHigh KERNEL" after "setprop ro.mst.support 1" "\n    start lazy_mount";
	insert_line "$EXTRACT"/ramdisk/init.samsungexynos7420.rc "# SkyHigh KERNEL" after "start lazy_mount" "    wait /dev/block/mounted";
	insert_line "$EXTRACT"/ramdisk/init.samsungexynos7420.rc "# SkyHigh KERNEL" after "seclabel u:r:watchdogd:s0" "\nservice lazy_mount /init.lazytime_mount.sh";
	insert_line "$EXTRACT"/ramdisk/init.samsungexynos7420.rc "# SkyHigh KERNEL" after "service lazy_mount /init.lazytime_mount.sh" "    user root ##";
	insert_line "$EXTRACT"/ramdisk/init.samsungexynos7420.rc "# SkyHigh KERNEL" after "user root ##" "    oneshot ##";
	insert_line "$EXTRACT"/ramdisk/init.samsungexynos7420.rc "# SkyHigh KERNEL" after "oneshot ##" "    disabled ##";

	cp -r ./"$BK"/patch/init.lazytime_mount.sh "$EXTRACT"/ramdisk;

	# UX ROM boot support
	replace_line "$EXTRACT"/ramdisk/init.environ.rc "export SYSTEMSERVERCLASSPATH /system/framework/services.jar:/system/framework/ethernet-service.jar:/system/framework/wifi-service.jar" "    export SYSTEMSERVERCLASSPATH /system/framework/services.jar:/system/framework/ethernet-service.jar:/system/framework/wifi-service.jar:/system/framework/ssrm.jar";

	# SkyHigh init
	cp -r ./"$BK"/patch/init.SkyHigh.rc "$EXTRACT"/ramdisk;

	# Synapse UCI & replace adbd with 5.1.1 version (adb debugging)
	cp -r ./"$BK"/res "$EXTRACT"/ramdisk/res;
	rm -rf "$EXTRACT"/ramdisk/sbin/adbd;
	cp -r ./"$BK"/sbin/* "$EXTRACT"/ramdisk/sbin;
	INITPATCH=$(cat ./"$BK"/patch/init_patch);
	echo "$INITPATCH" >> "$EXTRACT"/ramdisk/init.rc;

	# SuperSU
	CONTEXTS_PATCH=$(cat ./"$BK"/patch/file_contexts_su_patch);
	echo "$CONTEXTS_PATCH" >> "$EXTRACT"/ramdisk/file_contexts;

	replace_line "$EXTRACT"/ramdisk/fstab.goldfish "/dev/block/mtdblock0" "/dev/block/mtdblock0                                    /system             ext4      ro,noatime,barrier=1				   wait";

	replace_line "$EXTRACT"/ramdisk/fstab.samsungexynos7420 "/dev/block/platform/15570000.ufs/by-name/SYSTEM" "/dev/block/platform/15570000.ufs/by-name/SYSTEM		/system	ext4	ro,noatime,errors=panic,noload									wait";

	replace_line "$EXTRACT"/ramdisk/fstab.samsungexynos7420.fwup "/dev/block/platform/15570000.ufs/by-name/SYSTEM" "/dev/block/platform/15570000.ufs/by-name/SYSTEM		/system	ext4	ro,noatime,errors=panic,noload									wait";

	insert_line "$EXTRACT"/ramdisk/init.environ.rc "# SkyHigh KERNEL" before "export ANDROID_BOOTLOGO 1" "    export PATH /su/bin:/sbin:/vendor/bin:/system/sbin:/system/bin:/su/xbin:/system/xbin";

	insert_line "$EXTRACT"/ramdisk/init.rc "# SkyHigh KERNEL" before "on early-init" "import init.supersu.rc\n";
	insert_line "$EXTRACT"/ramdisk/init.rc "# SkyHigh KERNEL" before "mkdir /data 0771 system system" "     mkdir /su 0755 root root # create mount point for SuperSU";

	SUPATCH=$(cat ./"$BK"/patch/su_patch);
	echo "$SUPATCH" >> "$EXTRACT"/ramdisk/init.rc;
	sed -i "/setprop selinux.reload_policy 1/d" "$EXTRACT"/ramdisk/init.rc;

	mkdir -p "$EXTRACT"/ramdisk/su;

	cp -r ./"$BK"/patch/launch_daemonsu.sh "$EXTRACT"/ramdisk/sbin/;

	cp -r ./"$BK"/patch/init.supersu.rc "$EXTRACT"/ramdisk/;

	# replace with patched version
	rm -rf "$EXTRACT"/ramdisk/sepolicy;
	cp -r ./$BK/patch/sepolicy "$EXTRACT"/ramdisk/;

	# license agreement
	cp -r ./"$BK"/patch/LICENSE.md "$EXTRACT"/ramdisk/;

	# fix ramdisk permissions
	cd "${KERNELDIR}"/"$BK"/patch || exit 1;
	cp ./ramdisk_fix_permissions.sh "$EXTRACT"/ramdisk/ramdisk_fix_permissions.sh;
	cd "$EXTRACT"/ramdisk || exit 1;
	chmod 0777 ramdisk_fix_permissions.sh;
	./ramdisk_fix_permissions.sh 2>/dev/null;
	rm -f ramdisk_fix_permissions.sh;

	# clean up patch temp files
	find . -type f -name "*~" -exec rm -f {} \;

	echo "Patched ramdisk with SkyHigh";


# MODULES GENERATION

	echo;
	echo "${bldcya}***** Make modules *****${txtrst}";

	cd "${KERNELDIR}" || exit 1;

	# make modules
	make -j$((NUMBEROFCPUS + 1)) modules ARCH=arm64  || exit 1;

	# find modules
	for i in $(find "${KERNELDIR}" -name '*.ko'); do
		cp -av "$i" ./$BK/system/lib/modules/;
	done;

	if [ -f "./$BK/system/lib/modules/*" ]; then
		chmod 0755 ./$BK/system/lib/modules/*
		${CROSS_COMPILE}strip --strip-debug ./$BK/system/lib/modules/*.ko
		${CROSS_COMPILE}strip --strip-unneeded ./$BK/system/lib/modules/*
	fi;

	echo "Modules done"


# RAMDISK GENERATION

	echo;
	echo "${bldcya}***** Make ramdisk *****${txtrst}";

	cd "${KERNELDIR}"/"$BK"/tools || exit 1;
	./mkbootfs "$EXTRACT"/ramdisk | $COMP > "$EXTRACT"/ramdisk.$EXT;

	echo "Ramdisk done";


# BOOT.IMG GENERATION

	echo;
	echo "${bldcya}***** Make boot.img *****${txtrst}";

	./mkbootimg \
		--kernel "$EXTRACT"/Image \
		--dt "$DT"/dt.img \
		--board "$BOARD" \
		--ramdisk "$EXTRACT"/ramdisk."$EXT" \
		--base 0x10000000 \
		--kernel_offset 0x00008000 \
		--ramdisk_offset 0x01000000 \
		--tags_offset 0x00000100 \
		--pagesize 2048 -o "$EXTRACT"/boot.img

	echo -n "SEANDROIDENFORCE" >> "$EXTRACT"/boot.img;

	# check boot.img less than partition size
	GENERATED_SIZE=$(stat -c %s "$EXTRACT"/boot.img);
	if [[ $GENERATED_SIZE -gt $PARTITION_SIZE ]]; then
		echo;
		echo "${bldred}$TARGET${txtrst} ${red}boot.img size larger than partition size !!${txtrst}" 1>&2;
		echo "Please change your de/compression algorithm !!";
		cd "${KERNELDIR}" || exit 1;

		echo;
		read -p "${grn}Make clean source? (y/n) > ${txtrst}";
			if [ "$REPLY" == "y" ] || [ "$REPLY" == "Y" ]; then
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

	echo "boot.img done";


# ARCHIVE GENERATION

	echo;
	echo "${bldcya}***** Make archives *****${txtrst}";

	cd "${KERNELDIR}"/"$BK" || exit 1;

	cp "$EXTRACT"/boot.img "${KERNELDIR}"/output/"$TARGET"/;
	cp -R ./aroma "${KERNELDIR}"/output/"$TARGET"/;
	cp -R ./busybox "${KERNELDIR}"/output/"$TARGET"/;
	cp -R ./defaults "${KERNELDIR}"/output/"$TARGET"/
	cp -R ./META-INF "${KERNELDIR}"/output/"$TARGET"/;
	cp -R ./supersu "${KERNELDIR}"/output/"$TARGET"/;
	cp -R ./system "${KERNELDIR}"/output/"$TARGET"/;

	cd "${KERNELDIR}"/output/"$TARGET" || exit 1;
	GETVER=$(grep 'SkyHigh_MM--*' "${KERNELDIR}"/.config | sed 's/.*".//g' | sed 's/"//g');

	zip -r SM-"$TARGET"-kernel--"${GETVER}".zip .;
	tar -H ustar -c boot.img > SM-"$TARGET"-kernel--"${GETVER}".tar;
	md5sum -t SM-"$TARGET"-kernel--"${GETVER}".tar >> SM-"$TARGET"-kernel--"${GETVER}".tar;
	mv SM-"$TARGET"-kernel--"${GETVER}".tar SM-"$TARGET"-kernel--"${GETVER}".tar.md5;

	echo;
	echo "${bldred}$TARGET${txtrst} ${red}build completed !!${txtrst}";
	echo;
	echo "${bldcya}***** Flashable zip found in /output/$TARGET directory *****${txtrst}";


# END BUILD

	DATE_END=$(date +"%s");
	DIFF=$((DATE_END - DATE_START));

	echo;
	echo "Build time: $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds.";


# OPTIONAL SOURCE CLEAN

	echo;
	echo "${bldcya}***** Clean source *****${txtrst}";

	cd "${KERNELDIR}" || exit 1;

	read -p "${grn}Make clean source? (y/n) > ${txtrst}";

		if [ "$REPLY" == "y" ] || [ "$REPLY" == "Y" ]; then
			make clean;
			make distclean;
			make mrproper;
			echo;
			echo "Source cleaned";
		else
			echo "Source not cleaned";
		fi;

	echo;
