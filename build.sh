#!/bin/bash
#
# Modified work Copyright (c) 2017 UpInTheAir. All rights reserved.
#
# Authors:	UpInTheAir (MAJOR rework of all code)
#
# Contributors:	halaszk (initial base scripts)
#		arter97 (boot.img size check)
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


# COLORIZE & ADD TEXT PARAMETERS

	export red;                             # red
	red=$(tput setaf 1);
	export grn;                             # green
	grn=$(tput setaf 2);
	export cya;                             # cyan
	cya=$(tput setaf 6);
	export txtbld;                          # bold
	txtbld=$(tput bold);
	export bldred;                          # bold red
	bldred=${txtbld}$(tput setaf 1);
	export bldcya;                          # bold cyan
	bldcya=${txtbld}$(tput setaf 6);
	export txtrst;                          # reset
	txtrst=$(tput sgr0);


# LICENSE

	echo;
	echo "${bldred}Copyright (c) 2017 UpInTheAir${txtrst}";


# DISTRO

	echo;
	echo "Linux Mint https://linuxmint.com";


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


# TARGET VARIANT

	TARGET=$1;

	# SM-N920 C/CD/G/I
	if [ "$TARGET" == "N920C" ] ; then
		export KERNEL_CONFIG="SkyHigh_N920C_defconfig";
		export BOARD="SYSMAGIC000KU";
	# SM-N9208 SEA
	elif [ "$TARGET" == "N9208" ] ; then
		export KERNEL_CONFIG="SkyHigh_N9208_SEA_defconfig";
		export BOARD="SYSMAGIC000KU";
	fi;


# LOCATION

	export KERNELDIR;
	KERNELDIR=$(readlink -f .);


# SET BUILD VARIABLES

	export BK;
	BK=build_kernel;

	export EXTRACT;
	EXTRACT="${KERNELDIR}"/$BK/$TARGET/extract;

	export BOOT="${KERNELDIR}"/$BK/$TARGET/boot.img;

	export DATE;
	DATE=$(date +[%F]);

	export AROMA_CONFIG="${KERNELDIR}"/$BK/META-INF/com/google/android/aroma-config;

	# N920*
	export PARTITION_SIZE=29360128;

	# omitt timestamp line in generated .config
	export KCONFIG_NOTIMESTAMP=true;

	export ARCH=arm64;

	export SUB_ARCH=arm64;


# CPU CORE

	export NUMBEROFCPUS;
	NUMBEROFCPUS=$(grep -c 'processor' /proc/cpuinfo);


# RESET CURRENT LOCAL BRANCH TO GIT REPO

	function parse_git_branch() {
		git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e "s/* \(.*\)/\1/";
	}

	BRANCH=$(parse_git_branch);

	while true; do

		echo;
		read -rp "${cya}Reset current local branch to gitHub repo? (y/n) > ${txtrst}" yn;

		case $yn in

			y|Y )
				git reset --hard origin/"$BRANCH" && git clean -fd;
				echo "Local branch reset to ${bldred}$BRANCH${txtrst}";
				break;
				;;

			n|N )
				echo "Local branch not reset";
				break;
				;;

			* )
				echo "Please answer yes or no";
				;;

		esac;
	done;


# MAKE CLEAN SOURCE

	while true; do

		echo;
		read -rp "${cya}Make clean source? (y/n) > ${txtrst}" yn;

		case $yn in

			y|Y )
				make clean && make distclean && make mrproper;
				echo "Source cleaned";
				break;
				;;

			n|N )
				echo "Source not cleaned";
				break;
				;;

			* )
				echo "Please answer yes or no";
				;;

		esac;
	done;


# CLEAR CCACHE

	while true; do

		echo;
		read -rp "${cya}Clear ccache but keeping the config file? (y/n) > ${txtrst}" yn;

		case $yn in

			y|Y )
				ccache -C;
				break;
				;;

			n|N )
				echo "ccache not cleared";
				break;
				;;

			* )
				echo "Please answer yes or no";
				;;

		esac;
	done;


# RAMDISK ALGORITHM

	# select algorithm or change compression level to ensure boot.img 'GENERATED_SIZE' < 'PARTITION_SIZE'
	# algorithm must be supported & enabled in defconfig
	while true; do

		echo;
		read -rp "${cya}Select ramdisk de/compression algorithm:
			[1] GZIP (SuperSU & Magisk support)
			[2] LZO
			[3] LZ4
			[4] XZ
			> ${txtrst}" algorithm;

		case $algorithm in

			1 )
				export COMP="gzip -9";
				export EXT="gz";
				sed -i '/# CONFIG_RD_GZIP is not set/c\CONFIG_RD_GZIP=y' "${KERNELDIR}"/arch/arm64/configs/"$KERNEL_CONFIG";
				echo "GZIP selected";
				break;
				;;

			2 )
				export COMP="lzop -9";
				export EXT="lzo";
				sed -i '/# CONFIG_RD_LZO is not set/c\CONFIG_RD_LZO=y' "${KERNELDIR}"/arch/arm64/configs/"$KERNEL_CONFIG";
				echo "LZO selected";
				break;
				;;

			3 )
				export COMP="lz4c -l -hc";
				export EXT="lz4";
				sed -i '/# CONFIG_RD_LZ4 is not set/c\CONFIG_RD_LZ4=y' "${KERNELDIR}"/arch/arm64/configs/"$KERNEL_CONFIG";
				echo "LZ4 selected";
				break;
				;;

			4 )
				export COMP="xz -1 -Ccrc32";
				export EXT="xz";
				sed -i '/# CONFIG_RD_XZ is not set/c\CONFIG_RD_XZ=y' "${KERNELDIR}"/arch/arm64/configs/"$KERNEL_CONFIG";
				echo "XZ selected";
				break;
				;;

			* )
				echo "Please select algorithm";
				;;

		esac;
	done;


# DT.IMG

	while true; do

		echo;
		read -rp "${cya}Select dt.img:
			[1] Stock
			[2] Custom
			> ${txtrst}" dt;

		case $dt in

			1 )
				DT="$EXTRACT";
				echo "Stock dt.img selected";
				break;
				;;

			2 )
				export DT="${KERNELDIR}";
				echo "Custom dt.img selected";
				break;
				;;

			* )
				echo "Please select dt.img";
				;;

		esac;
	done;


# TOOLCHAIN

	while true; do

		echo;
		read -rp "${cya}Select toolchain:
			[1] Linaro-Android	6.3.1
			[2] Linaro		6.3.1
			[3] Flash		6.3.1
			> ${txtrst}" tc;

		case $tc in

			1 )
				# Linaro-Android 6.3.1 http://snapshots.linaro.org/android/android-gcc-toolchain/latest
				export CROSS_COMPILE=~/Toolchains/aarch64-linux-android-6.3/bin/aarch64-linux-android-;
				echo "Linaro-Android 6.3.1 selected";

				while true; do

					echo;
					read -rp "${grn}Enable graphite optimizations? (y/n) > ${txtrst}" yn;

					case $yn in

						y|Y )
							sed -i '/# CONFIG_CC_GRAPHITE_OPTIMIZATION is not set/c\CONFIG_CC_GRAPHITE_OPTIMIZATION=y' "${KERNELDIR}"/arch/arm64/configs/"$KERNEL_CONFIG";
							echo "Graphite enabled in config";
							break;
							;;

						n|N )
							sed -i '/CONFIG_CC_GRAPHITE_OPTIMIZATION=y/c\# CONFIG_CC_GRAPHITE_OPTIMIZATION is not set' "${KERNELDIR}"/arch/arm64/configs/"$KERNEL_CONFIG";
							echo "Graphite disabled in config";
							break;
							;;

						* )
							echo "Please answer yes or no";
							;;

					esac;
				done;

				break;
				;;

			2 )
				# Linaro 6.3.1 https://releases.linaro.org/components/toolchain/binaries/latest/aarch64-linux-gnu
				export CROSS_COMPILE=~/Toolchains/gcc-linaro-6.3.1-2017.02-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-;
				sed -i '/CONFIG_CC_GRAPHITE_OPTIMIZATION=y/c\# CONFIG_CC_GRAPHITE_OPTIMIZATION is not set' "${KERNELDIR}"/arch/arm64/configs/"$KERNEL_CONFIG";
				echo "Linaro 6.3.1 selected";
				echo "Graphite disabled in config";
				break;
				;;

			3 )
				# Flash 6.3.1 https://gitlab.com/Flash-ROM/aarch64-linux-android-6.x
				export CROSS_COMPILE=~/Toolchains/aarch64-linux-android-6.x/bin/aarch64-linux-android-;
				echo "Flash 6.3.1 selected";

				while true; do

					echo;
					read -rp "${grn}Enable graphite optimizations? (y/n) > ${txtrst}" yn;

					case $yn in

						y|Y )
							sed -i '/# CONFIG_CC_GRAPHITE_OPTIMIZATION is not set/c\CONFIG_CC_GRAPHITE_OPTIMIZATION=y' "${KERNELDIR}"/arch/arm64/configs/"$KERNEL_CONFIG";
							echo "Graphite enabled in config";
							break;
							;;

						n|N )
							sed -i '/CONFIG_CC_GRAPHITE_OPTIMIZATION=y/c\# CONFIG_CC_GRAPHITE_OPTIMIZATION is not set' "${KERNELDIR}"/arch/arm64/configs/"$KERNEL_CONFIG";
							echo "Graphite disabled in config";
							break;
							;;

						* )
							echo "Please answer yes or no";
							;;

					esac;
				done;

				break;
				;;

			* )
				echo "Please select toolchain";
				;;

		esac;
	done;


# START LOG

	# remove existing build.log
	if [ ! -e /build.log ]; then
		rm -rf ./build.log;
	fi;

	(


# START BUILD

	export DATE_START;
	DATE_START=$(date +"%s");

	if [ "$TARGET" != "" ]; then
		echo;
		echo "${cya}Starting your build for${txtrst} ${bldred}$TARGET${txtrst}";
		sleep 2;
	else
		echo;
		echo "You need to define your device target!";
		echo "example: build_kernel.sh N920C";
		echo "example: build_kernel.sh N9208";
		echo;
		exit 1;
	fi;


# APPEND BUILD DATE TO CONFIG

	# kernel config
	sed -i "s/\[[^][]*\]/$DATE/g" "${KERNELDIR}"/arch/arm64/configs/"$KERNEL_CONFIG";

	# Aroma config
	sed -i "s/\[[^][]*\]/$DATE/g" "$AROMA_CONFIG";


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
	rm -rf "$EXTRACT";
	rm -rf "${KERNELDIR}"/output/"$TARGET"/*;

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

		if [ "$dt" == "2" ]; then
			echo;
			echo "${cya}--- Creating custom dt.img ---${txtrst}";
			echo;
			# stock generated tools
			./$BK/tools/dtbtool -o dt.img -s 2048 -p ./scripts/dtc/dtc ./arch/arm64/boot/dts/;
		fi;
	else
		echo "${bldred}Kernel STUCK in BUILD!${txtrst}";

		while true; do

			echo;
			read -rp "${cya}Do you want to run a 'make' command to check the error?  (y/n) > ${txtrst}" yn;

			case $yn in

				y|Y )
					make Image ARCH=arm64;
					exit 1;
					;;

				n|N )
					echo;
					exit 1;
					;;

				* )
					echo "Please answer yes or no";
					;;

			esac;
		done;
	fi;


# RAMDISK PATCH

	echo;
	echo "${bldcya}***** Patch ramdisk *****${txtrst}";

	cd "${KERNELDIR}"/"$BK"/patch || exit 1;

	# 'Modified work Copyright (c) 2017 UpInTheAir' header
	echo -e '0r copyright_header.patch\nw' | ed "$EXTRACT"/ramdisk/default.prop 2> /dev/null;
	echo -e '0r copyright_header.patch\nw' | ed "$EXTRACT"/ramdisk/file_contexts 2> /dev/null;
	echo -e '0r copyright_header.patch\nw' | ed "$EXTRACT"/ramdisk/fstab.samsungexynos7420 2> /dev/null;
	echo -e '0r copyright_header.patch\nw' | ed "$EXTRACT"/ramdisk/fstab.samsungexynos7420.fwup 2> /dev/null;
	echo -e '0r copyright_header.patch\nw' | ed "$EXTRACT"/ramdisk/init.environ.rc 2> /dev/null;
	echo -e '0r copyright_header.patch\nw' | ed "$EXTRACT"/ramdisk/init.rc 2> /dev/null;
	echo -e '0r copyright_header.patch\nw' | ed "$EXTRACT"/ramdisk/init.rilcommon.rc 2> /dev/null;
	echo -e '0r copyright_header.patch\nw' | ed "$EXTRACT"/ramdisk/init.samsungexynos7420.rc 2> /dev/null;

	cd "${KERNELDIR}" || exit 1;

	# default.prop
	sed -i '/persist.security.ams.enforcing/c\persist.security.ams.enforcing=0' "$EXTRACT"/ramdisk/default.prop;
	sed -i '/ro.secure=1/c\ro.secure=0' "$EXTRACT"/ramdisk/default.prop;
	sed -i '/ro.debuggable=0/c\ro.debuggable=1' "$EXTRACT"/ramdisk/default.prop;
	sed -i '/ro.adb.secure=1/c\ro.adb.secure=0' "$EXTRACT"/ramdisk/default.prop;
	sed -i '/persist.sys.usb.config=mtp/c\persist.sys.usb.config=mtp,adb' "$EXTRACT"/ramdisk/default.prop;

	sed -i '/debug.atrace.tags.enableflags=0/a\\n# SELinux \& KNOX related' "$EXTRACT"/ramdisk/default.prop;
	sed -i '/# SELinux \& KNOX related/a\persist.cne.feature=0' "$EXTRACT"/ramdisk/default.prop;
	sed -i '/persist.cne.feature=0/a\androidboot.selinux=0' "$EXTRACT"/ramdisk/default.prop;
	sed -i '/androidboot.selinux=0/a\ro.securestorage.knox=false' "$EXTRACT"/ramdisk/default.prop;
	sed -i '/ro.securestorage.knox=false/a\ro.security.mdpp.ux=Disabled' "$EXTRACT"/ramdisk/default.prop;
	sed -i '/ro.security.mdpp.ux=Disabled/a\ro.config.tima=0' "$EXTRACT"/ramdisk/default.prop;
	sed -i '/ro.config.tima=0/a\ro.config.dmverity=false' "$EXTRACT"/ramdisk/default.prop;
	sed -i '/ro.config.dmverity=false/a\ro.config.rkp=false' "$EXTRACT"/ramdisk/default.prop;
	sed -i '/ro.config.rkp=false/a\ro.config.kap_default_on=false' "$EXTRACT"/ramdisk/default.prop;
	sed -i '/ro.config.kap_default_on=false/a\ro.config.kap=false' "$EXTRACT"/ramdisk/default.prop;
	sed -i '/ro.config.kap=false/a\\n# Keep WIFI settings on flash\/reboot' "$EXTRACT"/ramdisk/default.prop;
	sed -i '/# Keep WIFI settings on flash\/reboot/a\ro.securestorage.support=false' "$EXTRACT"/ramdisk/default.prop;
	sed -i '/ro.securestorage.support=false/a\\n# Screen Mirroring \& AllShare Cast fix' "$EXTRACT"/ramdisk/default.prop;
	sed -i '/# Screen Mirroring \& AllShare Cast fix/a\wlan.wfd.hdcp=disable\n' "$EXTRACT"/ramdisk/default.prop;

	# file_contexts
	sed -i '/\/dev\/uio[0-9]*/a\\/dev\/erandom		u:object_r:urandom_device:s0' "$EXTRACT"/ramdisk/file_contexts;
	sed -i '/\/dev\/erandom/a\\/dev\/frandom		u:object_r:random_device:s0' "$EXTRACT"/ramdisk/file_contexts;
	sed -i '/\/system\/xbin\/su/i\\/system/xbin(/.*)?      u:object_r:system_file:s0' "$EXTRACT"/ramdisk/file_contexts;

	# init.rc
	sed -i '/import \/init.sec_debug.rc/d' "$EXTRACT"/ramdisk/init.rc;
	sed -i '/import \/init.rilcommon.rc/a\import \/init.SkyHigh.rc' "$EXTRACT"/ramdisk/init.rc;
	sed -i '/write \/proc\/sys\/kernel\/randomize_va_space/c\    \write \/proc\/sys\/kernel\/randomize_va_space 0' "$EXTRACT"/ramdisk/init.rc;
	sed -i '/write \/sys\/block\/mmcblk0\/queue\/scheduler noop/d' "$EXTRACT"/ramdisk/init.rc;
	sed -i '/write \/sys\/block\/sda\/queue\/scheduler noop/d' "$EXTRACT"/ramdisk/init.rc;
	sed -i '/write \/sys\/block\/mmcblk0\/queue\/scheduler cfq/d' "$EXTRACT"/ramdisk/init.rc;
	sed -i '/write \/sys\/block\/sda\/queue\/scheduler cfq/d' "$EXTRACT"/ramdisk/init.rc;

	# init.rilcommon.rc
	if [ "$TARGET" == "N920C" ] || [ "$TARGET" == "N9208" ]; then
		sed -i '/import \/init.rilcarrier.rc/d' "$EXTRACT"/ramdisk/init.rilcommon.rc;
		sed -i '/import \/init.rilepdg.rc/d' "$EXTRACT"/ramdisk/init.rilcommon.rc;
	fi;

	# init.samsungexynos7420.rc
	sed -i '/import init.fac.rc/d' "$EXTRACT"/ramdisk/init.samsungexynos7420.rc;
	sed -i '/import init.exynos7420_fac.rc/d' "$EXTRACT"/ramdisk/init.samsungexynos7420.rc;
	sed -i '/import init.remove_recovery.rc/d' "$EXTRACT"/ramdisk/init.samsungexynos7420.rc;
	sed -i '/write \/proc\/sys\/vm\/dirty_bytes/d' "$EXTRACT"/ramdisk/init.samsungexynos7420.rc;
	sed -i '/write \/proc\/sys\/vm\/dirty_background_bytes/d' "$EXTRACT"/ramdisk/init.samsungexynos7420.rc;

	# CPUSets
	sed -i '/write \/dev\/cpuset\/foreground\/cpus/c\    \write \/dev\/cpuset\/foreground\/cpus 0-7' "$EXTRACT"/ramdisk/init.rc;
	sed -i '/write \/dev\/cpuset\/foreground\/boost\/cpus/c\    \write \/dev\/cpuset\/foreground\/boost\/cpus 0-7' "$EXTRACT"/ramdisk/init.rc;
	sed -i '/write \/dev\/cpuset\/background\/cpus/c\    \write \/dev\/cpuset\/background\/cpus 0-7' "$EXTRACT"/ramdisk/init.rc;
	sed -i '/write \/dev\/cpuset\/system-background\/cpus/c\    \write \/dev\/cpuset\/system-background\/cpus 0-7' "$EXTRACT"/ramdisk/init.rc;
	sed -i '/chown system system \/dev\/cpuset\/tasks/i\    chown system system \/dev\/cpuset\/system-background' "$EXTRACT"/ramdisk/init.rc;
	sed -i '/chown system system \/dev\/cpuset\/tasks/a\    chown system system \/dev\/cpuset\/system-background\/tasks' "$EXTRACT"/ramdisk/init.rc;
	sed -i '/chown system system \/dev\/cpuset\/system-background\/tasks/a\\n    \# Set system-background to 0775 so SurfaceFlinger can touch it' "$EXTRACT"/ramdisk/init.rc;
	sed -i '/# Set system-background to 0775 so SurfaceFlinger can touch it/a\    chmod 0775 \/dev\/cpuset\/system-background' "$EXTRACT"/ramdisk/init.rc;
	sed -i '/chmod 0664 \/dev\/cpuset\/background\/tasks/a\    chmod 0775 \/dev\/cpuset\/system-background\/tasks' "$EXTRACT"/ramdisk/init.rc;

	sed -i '/setprop ro.mst.support 1/a\\n    \start bootsh' "$EXTRACT"/ramdisk/init.samsungexynos7420.rc;
	sed -i '/seclabel u:r:watchdogd:s0/a\\n\service bootsh \/init.invisible_cpuset.sh' "$EXTRACT"/ramdisk/init.samsungexynos7420.rc;
	sed -i '/service bootsh \/init.invisible_cpuset.sh/a\    user root #' "$EXTRACT"/ramdisk/init.samsungexynos7420.rc;
	sed -i '/user root #/a\    oneshot #' "$EXTRACT"/ramdisk/init.samsungexynos7420.rc;
	sed -i '/oneshot #/a\    disabled #' "$EXTRACT"/ramdisk/init.samsungexynos7420.rc;

	cp -r ./"$BK"/patch/init.invisible_cpuset.sh "$EXTRACT"/ramdisk;

	# lazytime mount for EXT4 FS
	sed -i '/setprop ro.mst.support 1/a\\n    \start lazy_mount' "$EXTRACT"/ramdisk/init.samsungexynos7420.rc;
	sed -i '/start lazy_mount/a\    wait \/dev\/block\/mounted' "$EXTRACT"/ramdisk/init.samsungexynos7420.rc;
	sed -i '/seclabel u:r:watchdogd:s0/a\\n\service lazy_mount \/init.lazytime_mount.sh' "$EXTRACT"/ramdisk/init.samsungexynos7420.rc;
	sed -i '/service lazy_mount \/init.lazytime_mount.sh/a\    user root ##' "$EXTRACT"/ramdisk/init.samsungexynos7420.rc;
	sed -i '/user root ##/a\    oneshot ##' "$EXTRACT"/ramdisk/init.samsungexynos7420.rc;
	sed -i '/user root ##/a\    disabled ##' "$EXTRACT"/ramdisk/init.samsungexynos7420.rc;

	cp -r ./"$BK"/patch/init.lazytime_mount.sh "$EXTRACT"/ramdisk;

	# UX ROM boot support
	sed -i '/wifi-service.jar/s/$/:\/system\/framework\/ssrm.jar/' "$EXTRACT"/ramdisk/init.environ.rc;

	# SkyHigh init
	cp -r ./"$BK"/patch/init.SkyHigh.rc "$EXTRACT"/ramdisk;

	# Synapse UCI & replace adbd with 5.1.1 version (adb debugging)
	cp -r ./"$BK"/res "$EXTRACT"/ramdisk/res;
	rm -rf "$EXTRACT"/ramdisk/sbin/adbd;
	cp -r ./"$BK"/sbin/* "$EXTRACT"/ramdisk/sbin;
	INITPATCH=$(cat ./"$BK"/patch/init_patch);
	echo "$INITPATCH" >> "$EXTRACT"/ramdisk/init.rc;

	# fstab* : disable dm-verity boot prevention for non-rooted device
	sed -i 's/,verify//g' "$EXTRACT"/ramdisk/fstab.*;
	sed -i 's/,support_scfs//g' "$EXTRACT"/ramdisk/fstab.*;

	# fstab* : mount system rw to permit SafetyNet to pass (does not boot with Magisk)
#	sed -i '/system/ s/ro,/rw,/' "$EXTRACT"/ramdisk/fstab.*;
#	sed -i '/system/ s/ro/rw/' "$EXTRACT"/ramdisk/fstab.ranchu;

#	cd "$EXTRACT"/ramdisk || exit 1;

	# sys.usb.state & sys.usb.config : rename to permit SafetyNet to pass with USB debugging enabled. ROM developers do the same in services.jar.
#	find ./ -type f -exec sed -i 's/sys.usb.config/sys.usb.config.SkyHigh/g' {} \;
#	find ./ -type f -exec sed -i 's/sys.usb.state/sys.usb.state.SkyHigh/g' {} \;

#	cd "${KERNELDIR}" || exit 1;

	# SuperSU (GZIP support only)
	if [ "$COMP" != "gzip -9" ] && [ "$EXT" != "gz" ]; then

		cd "${KERNELDIR}"/"$BK"/patch || exit 1;

		# 'Modified work Copyright (c) 2017 UpInTheAir' header
		echo -e '0r copyright_header.patch\nw' | ed "$EXTRACT"/ramdisk/fstab.goldfish 2> /dev/null;

		cd "${KERNELDIR}" || exit 1;

		# fstab* :
		#	disable dm-verity boot prevention) by previous patch as default
		#	noatime mount: by default on all partitions (patched source fs/namespace.c)

		CONTEXTS_PATCH=$(cat ./"$BK"/patch/file_contexts_su_patch);
		echo "$CONTEXTS_PATCH" >> "$EXTRACT"/ramdisk/file_contexts;

		sed -i '/on init/a\    export PATH \/su\/bin:\/sbin:\/vendor\/bin:\/system\/sbin:\/system\/bin:\/su\/xbin:\/system\/xbin' "$EXTRACT"/ramdisk/init.environ.rc;
		sed -i '/on early-init/i\import init.supersu.rc\n' "$EXTRACT"/ramdisk/init.rc;
		sed -i '/mkdir \/data 0771 system system/i\     mkdir \/su 0755 root root # create mount point for SuperSU' "$EXTRACT"/ramdisk/init.rc;

		SUPATCH=$(cat ./"$BK"/patch/su_patch);
		echo "$SUPATCH" >> "$EXTRACT"/ramdisk/init.rc;
		sed -i "/setprop selinux.reload_policy 1/d" "$EXTRACT"/ramdisk/init.rc;

		mkdir -p "$EXTRACT"/ramdisk/su;

		cp -r ./"$BK"/patch/launch_daemonsu.sh "$EXTRACT"/ramdisk/sbin/;

		cp -r ./"$BK"/patch/init.supersu.rc "$EXTRACT"/ramdisk/;

		# sepolicy (patched version)
		rm -rf "$EXTRACT"/ramdisk/sepolicy;
		cp -r ./"$BK"/patch/sepolicy "$EXTRACT"/ramdisk/;
	fi;

	# license agreement
	cp -r ./"$BK"/patch/LICENSE.md "$EXTRACT"/ramdisk/;

	cd "${KERNELDIR}"/"$BK"/patch || exit 1;

	# fix ramdisk permissions
	cp ./ramdisk_fix_permissions.sh "$EXTRACT"/ramdisk/ramdisk_fix_permissions.sh;

	cd "$EXTRACT"/ramdisk || exit 1;

	chmod 0777 ramdisk_fix_permissions.sh;
	./ramdisk_fix_permissions.sh 2>/dev/null;
	rm -f ramdisk_fix_permissions.sh;

	echo "Patched ramdisk with SkyHigh";


# MODULES GENERATION

	echo;
	echo "${bldcya}***** Make modules *****${txtrst}";

	cd "${KERNELDIR}" || exit 1;

	# make modules
	make -j$((NUMBEROFCPUS + 1)) modules ARCH=arm64  || exit 1;

	# find modules
	find "${KERNELDIR}" -name '*.ko' -exec cp -v {} ./"$BK"/system/lib/modules \;

	if [ -f "./$BK/system/lib/modules/*" ]; then
		chmod 0755 ./"$BK"/system/lib/modules/*
		${CROSS_COMPILE}strip --strip-debug ./"$BK"/system/lib/modules/*.ko
		${CROSS_COMPILE}strip --strip-unneeded ./"$BK"/system/lib/modules/*
	fi;

	echo "Modules done"


# RAMDISK GENERATION

	echo;
	echo "${bldcya}***** Make ramdisk *****${txtrst}";

	cd "${KERNELDIR}"/"$BK"/tools || exit 1;

	./mkbootfs "$EXTRACT"/ramdisk | $COMP > "$EXTRACT"/ramdisk."$EXT";

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

	# check boot.img < partition size
	GENERATED_SIZE=$(stat -c %s "$EXTRACT"/boot.img);

	if [[ $GENERATED_SIZE -gt $PARTITION_SIZE ]]; then
		echo;
		echo "${bldred}$TARGET${txtrst} ${red}boot.img size > partition size !!${txtrst}" 1>&2;
		echo "Please change your de/compression algorithm or compression level !!";

		cd "${KERNELDIR}" || exit 1;

		while true; do

			echo;
			read -rp "${cya}Make clean source? (y/n) > ${txtrst}" yn;

			case $yn in

				y|Y )
					make clean && make distclean && make mrproper;
					echo "Source cleaned";
					exit 1;
					;;

				n|N )
					echo "Source not cleaned";
					exit 1;
					;;

				* )
					echo "Please answer yes or no";
					;;

			esac;
		done;
	fi;

	echo "boot.img done";


# ARCHIVE GENERATION

	echo;
	echo "${bldcya}***** Make archives *****${txtrst}";

	cd "${KERNELDIR}"/"$BK" || exit 1;

	cp "$EXTRACT"/boot.img "${KERNELDIR}"/output/"$TARGET"/;
	cp -R ./aroma "${KERNELDIR}"/output/"$TARGET"/;
	cp -R ./busybox "${KERNELDIR}"/output/"$TARGET"/;
	cp -R ./defaults "${KERNELDIR}"/output/"$TARGET"/;
	cp -R ./META-INF "${KERNELDIR}"/output/"$TARGET"/;
	cp -R ./root "${KERNELDIR}"/output/"$TARGET"/;
	cp -R ./su "${KERNELDIR}"/output/"$TARGET"/;
	cp -R ./system "${KERNELDIR}"/output/"$TARGET"/;

	cd "${KERNELDIR}"/output/"$TARGET" || exit 1;

	GETVER=$(grep 'SkyHigh_MM--*' "${KERNELDIR}"/.config | sed 's/.*".//g' | sed 's/"//g');

	zip -r SM-"$TARGET"-kernel--"${GETVER}".zip .;
	tar -H ustar -c boot.img > SM-"$TARGET"-kernel--"${GETVER}".tar;
	md5sum -t SM-"$TARGET"-kernel--"${GETVER}".tar >> SM-"$TARGET"-kernel--"${GETVER}".tar;
	mv SM-"$TARGET"-kernel--"${GETVER}".tar SM-"$TARGET"-kernel--"${GETVER}".tar.md5;

	echo;
	echo "${bldred}$TARGET build completed !!${txtrst}";
	echo;
	echo "${bldcya}***** Flashable zip found in: ${bldred}/output/$TARGET${txtrst} ${bldcya}directory *****${txtrst}";


# END BUILD

	DATE_END=$(date +"%s");
	DIFF=$((DATE_END - DATE_START));

	echo;
	echo "${cya}Build time:${txtrst} $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds.";


# OPTIONAL SOURCE CLEAN

	echo;
	echo "${bldcya}***** Clean source *****${txtrst}";

	cd "${KERNELDIR}" || exit 1;

	while true; do

		echo;
		read -rp "${cya}Make clean source? (y/n) > ${txtrst}" yn;

		case $yn in

			y|Y )
				make clean && make distclean && make mrproper;
				echo "Source cleaned";
				break;
				;;

			n|N )
				echo "Source not cleaned";
				break;
				;;

			* )
				echo "Please answer yes or no";
				;;

		esac;
	done;

	echo;


# END LOG

	) 2>&1 | tee -a ./build.log;
