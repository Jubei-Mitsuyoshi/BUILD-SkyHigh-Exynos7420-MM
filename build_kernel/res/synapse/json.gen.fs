#!/system/bin/sh
#
# Modified work Copyright (c) 2017 UpInTheAir. All rights reserved.
#
# Authors:	UpInTheAir
#
# Contributors:	halaszk (initial FS mount controls & display)
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

cat << CTAG
{
    name:FS,
    elements:[
	{ SPane:{
		title:"Partition Mount Status"
	}},
	{ SSpacer:{
		height:1
	}},
	{ SLiveLabel:{
		title:"System",
		refresh:10000000,
		action:"
			if grep -q 'system f2fs' /proc/mounts ; then
				echo F2FS;
			else
				echo EXT4;
			fi;"
	}},
	{ SSpacer:{
		height:1
	}},
	{ SLiveLabel:{
		title:"Data",
		refresh:10000000,
		action:"
			if grep -q 'data f2fs' /proc/mounts ; then
				echo F2FS;
			else
				echo EXT4;
			fi;"
	}},
	{ SSpacer:{
		height:1
	}},
	{ SLiveLabel:{
		title:"Cache",
		refresh:10000000,
		action:"
			if grep -q 'cache f2fs' /proc/mounts ; then
				echo F2FS;
			else
				echo EXT4;
			fi;"
	}},
	{ SSpacer:{
		height:2
	}},
	{ SPane:{
		title:"File System Mount Control"
	}},
	{ SSpacer:{
		height:1
	}},
	{ SButton:{
		label:"Remount RootFS as Read-Write",
		action:"$BB mount -t rootfs -o remount,rw rootfs;
		echo Remounted RootFS as Read-Write!;"
	}},
	{ SSpacer:{
		height:1
	}},
	{ SButton:{
		label:"Remount RootFS as Read-Only",
		action:"$BB mount -t rootfs -o remount,ro rootfs;
		echo Remounted RootFS as Read-Only!;"
	}},
	{ SSpacer:{
		height:1
	}},
	{ SButton:{
		label:"Remount System as Read-Write",
		action:"mount -o remount,rw \/system;
		echo Remounted \/system as Read-Write!;"
	}},
	{ SSpacer:{
		height:1
	}},
	{ SButton:{
		label:"Remount System as Read-Only",
		action:"mount -o remount,ro \/system;
		echo Remounted \/system as Read-Only!;"
	}},
	{ SSpacer:{
		height:2
	}},
	{ SPane:{
		title:"Scrolling Cache Control",
		description:"Disable to increase in-app scrolling speed and responsiveness. Default is (2). If you experience problems, set to (1). REBOOT REQUIRED !!"
	}},
	{ SSpacer:{
		height:1
	}},
	{ SOptionList:{
		title:"Scrolling Cache",
		description:"0- force to enable regardless of app setting.\n1- enable unless app specifies.\n2- disable unless app specifies.\n3- force to disable regardless of app setting.\n",
		default:$(echo "$(/res/synapse/actions/devtools scr_cache)"),
		action:"devtools scr_cache",
		values:[0, 1, 2, 3,]
	}},
	{ SSpacer:{
		height:2
	}},
	{ SPane:{
		title:"Optimize Databases",
		description:"Use this button to SQlite (defrag/reindex) all databases found in /data & /sdcard, this increases database read/write performance. Frequent inserts, updates, and deletes can cause the database file to become fragmented - where data for a single table or index is scattered around the database file. Running VACUUM ensures that each table and index is largely stored contiguously within the database file. In some cases, VACUUM may also reduce the number of partially filled pages in the database, reducing the size of the database file further."
	}},
	{ SSpacer:{
		height:1
	}},
	{ SDescription:{
		description:"NOTE: This process can take from 1-2 minutes and device may be UNRESPONSIVE during this time, PLEASE WAIT for the process to finish ! An error just means that some databases weren't succesful. Log output to /sdcard/SkyHigh/Logs/SQLite.txt."
	}},
	{ SSpacer:{
		height:1
	}},
	{ SButton:{
		label:"Defrag Databases",
		action:"devtools optimizedb"
	}},
	{ SSpacer:{
		height:2
	}},
	{ SPane:{
		title:"File System Trim"
	}},
	{ SSpacer:{
		height:1
	}},
	{ SLiveLabel:{
		title:"Last Auto FSTrim",
		refresh:10000,
		action:"
			if [ -f /data/system/last-fstrim ] ; then
				echo $(date -r /data/system/last-fstrim);
			else
				echo No Info Available;
			fi;"
	}},
	{ SSpacer:{
		height:1
	}},
	{ SDescription:{
		description:"Android 4.4.2+ introduced a feature that auto trims EXT4 partitions during suspend and only when certain condtions are met. As Android file systems are prone to lag over time and prevalent as your internal storage is used up, manually trimming may help retain consistant IO throughput with user control."
	}},
	{ SSpacer:{
		height:1
	}},
	{ SDescription:{
		description:"If you wish to manually trim /system, /data and /cache EXT4 partitions, then press the button below."
	}},
	{ SSpacer:{
		height:1
	}},
	{ SDescription:{
		description:"NOTE: This process can take from 1-2 minutes and device may be UNRESPONSIVE during this time, PLEASE WAIT for the process to finish."
	}},
	{ SSpacer:{
		height:1
	}},
	{ SButton:{
		label:"Manual FSTrim",
		action:"devtools fstrim"
	}},
	{ SSpacer:{
		height:2
	}},
	`if grep -q 'cache ext4' /proc/mounts && grep -q 'data ext4' /proc/mounts ; then
		echo '{ SPane:{
			title:"Wipe Options"
		}},
		{ SSpacer:{
			height:1
		}},
		{ SButton:{
			label:"Wipe Cache Reboot",
			action:"devtools wipe_cache_reboot"
		}},
		{ SSpacer:{
			height:1
		}},
		{ SButton:{
			label:"Wipe Dalvik-Cache Reboot",
			action:"devtools wipe_dalvik_reboot"
		}},
		{ SSpacer:{
			height:1
		}},
		{ SButton:{
			label:"Wipe Cache & Dalvik-Cache Reboot",
			action:"devtools wipe_cache-dalvik_reboot"
		}},
		{ SSpacer:{
			height:2
		}},'
	fi;`
	{ SPane:{
		title:"Wipe Junk Folders"
	}},
	{ SSpacer:{
		height:1
	}},
	{ SDescription:{
		description:"Remove: clipboard-cache, tombstones, anr logs, dropbox logs & lost+found."
	}},
	{ SSpacer:{
		height:1
	}},
	{ SButton:{
		label:"Clean up Junk",
		action:"devtools clean_up"
	}},
	{ SSpacer:{
		height:1
	}},
	{ SDescription:{
		description:"Remove useless scripts that interfere with kernel settings."
	}},
	{ SSpacer:{
		height:1
	}},
	{ SButton:{
		label:"Clean init.d",
		action:"devtools clean_initd"
	}},
	{ SSpacer:{
		height:2
	}},
    ]
}
CTAG
