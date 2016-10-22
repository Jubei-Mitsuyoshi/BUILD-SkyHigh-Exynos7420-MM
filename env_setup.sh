#!/bin/bash

# Colorize and add text parameters
export red=$(tput setaf 1)		#  red
export grn=$(tput setaf 2)		#  green
export blu=$(tput setaf 4)		#  blue
export cya=$(tput setaf 6)		#  cyan
export txtbld=$(tput bold)		#  Bold
export bldred=${txtbld}$(tput setaf 1)	#  red
export bldgrn=${txtbld}$(tput setaf 2)	#  green
export bldblu=${txtbld}$(tput setaf 4)	#  blue
export bldcya=${txtbld}$(tput setaf 6)	#  cyan
export txtrst=$(tput sgr0)		#  Reset


# check if ccache installed, if not install
if [ ! -e /usr/bin/ccache ]; then
	echo "You must install 'ccache' to continue";
	sudo apt-get install ccache
fi;

# check if xmllint installed, if not install
if [ ! -e /usr/bin/xmllint ]; then
	echo "You must install 'xmllint' to continue";
	sudo apt-get install libxml2-utils
fi;


echo
echo "${bldcya}***** Set up Environment before compile *****${txtrst}";

	# reset current local branch to gitHub repo
	function parse_git_branch() {
		git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e "s/* \(.*\)/\1/"
	}
	BRANCH=$(parse_git_branch);

	echo
	read -p "${grn}Reset current local branch to gitHub repo? (y/n) > ${txtrst}";
		if [ "$REPLY" == "y" -o "$REPLY" == "Y" ]; then
			git reset --hard origin/$BRANCH && git clean -fd;
			echo
			echo "Local branch reset to $BRANCH";
		else
			echo "Local branch not reset";
		fi;


	# make clean source
	echo
	read -p "${grn}Make clean source? (y/n) > ${txtrst}";
		if [ "$REPLY" == "y" -o "$REPLY" == "Y" ]; then
			make clean;
			make distclean;
			make mrproper;
			echo
			echo "Source cleaned";
		else
			echo "Source not cleaned";
		fi;


	# clear ccache
	echo
	read -p "${grn}Clear ccache but keeping the config file? (y/n) > ${txtrst}";
		if [ "$REPLY" == "y" -o "$REPLY" == "Y" ]; then
			ccache -C;
		else
			echo "ccache not cleared";
	fi;


	# start build for target variant
	TARGET=$1
	if [ "$TARGET" != "" ]; then
		echo
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
		exit 1
	fi;


	# location
	export KERNELDIR=$(readlink -f .);


	# set build variables
	BK=build_kernel;
	EXTRACT=${KERNELDIR}/$BK/$TARGET/extract;

	export PARTITION_SIZE=29360128;	# N920* G928*
	export KCONFIG_NOTIMESTAMP=true;
	export ARCH=arm64;
	export SUB_ARCH=arm64;


	# SM-N920 C/CD/G/I
	if [ "$TARGET" == "N920C" ] ; then
		export KERNEL_CONFIG="SkyHigh_N920C_defconfig";
		board="SYSMAGIC000KU";
	# SM-N920 P (Sprint)
	elif [ "$TARGET" == "N920P" ] ; then
		export KERNEL_CONFIG="SkyHigh_N920P_defconfig";
		board="SYSMAGIC000KU";
	# SM-N920 T/W8
	elif [ "$TARGET" == "N920T" ] ; then
		export KERNEL_CONFIG="SkyHigh_N920T_defconfig";
		board="SYSMAGIC000KU";
	# SM-N9200 HK
	elif [ "$TARGET" == "N9200" ] ; then
		export KERNEL_CONFIG="SkyHigh_N9200_HK_defconfig";
		board="FPRPNLCC000KU";
	# SM-N9208 SEA
	elif [ "$TARGET" == "N9208" ] ; then
		export KERNEL_CONFIG="SkyHigh_N9208_SEA_defconfig";
		board="SYSMAGIC000KU";
	# SM-G928 C/F/G/I/7C
	elif [ "$TARGET" == "G928F" ] ; then
		export KERNEL_CONFIG="SkyHigh_G928F_defconfig";
		board="SYSMAGIC000KU";
	# SM-G928 P (Sprint)
	elif [ "$TARGET" == "G928P" ] ; then
		export KERNEL_CONFIG="SkyHigh_G928P_defconfig";
		board="SYSMAGIC000KU";
	# SM-G928 T/W8
	elif [ "$TARGET" == "G928T" ] ; then
		export KERNEL_CONFIG="SkyHigh_G928T_defconfig";
		board="SYSMAGIC000KU";
	fi;


	# system compiler : Ubuntu/Linaro 5.4.0 20160609
	export CROSS_COMPILE=/usr/bin/aarch64-linux-gnu-


	# CPU Core
	export NUMBEROFCPUS=$(grep 'processor' /proc/cpuinfo | wc -l);
