#!/system/bin/sh
#
# Modified work Copyright (c) 2017 UpInTheAir. All rights reserved.
#
# Authors:	AndreiLux
#		apbaxel
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

cat << CTAG
{
    name:IO,
    elements:[
	{ SPane:{
		title:"I/O Schedulers",
		description:"Set the active I/O elevator algorithm. The I/O Scheduler decides how to prioritize and handle I/O requests. More info: <a href='http://timos.me/tm/wiki/ioscheduler'>Wiki</a>"
	}},
	{ SSpacer:{
		height:1
	}},
	{ SOptionList:{
		title:"Scheduler",
		description:" ",
		default:$(echo $(/res/synapse/actions/bracket-option /sys/block/sda/queue/scheduler)),
		action:"ioset scheduler",
		values:[
`
			for IOSCHED in \`cat /sys/block/sda/queue/scheduler | $BB sed -e 's/\]//;s/\[//'\`; do
				echo "\"$IOSCHED\",";
			done;
`
		],
		notify:[
			{
				on:APPLY,
				do:[ REFRESH, CANCEL ],
				to:"/sys/block/sda/queue/iosched"
			},
			{
				on:REFRESH,
				do:REFRESH,
				to:"/sys/block/sda/queue/iosched"
			}
		]
	}},
	{ SSpacer:{
		height:2
	}},
	{ SSeekBar:{
		title:"Read-Ahead",
		description:" ",
		max:4096,
		min:64,
		unit:" KB",
		step:64,
		default:$(cat /sys/block/sda/queue/read_ahead_kb),
		action:"ioset queue read_ahead_kb"
	}},
	{ SSpacer:{
		height:2
	}},
	{ SPane:{
		title:"General I/O Tunables",
		description:"Set the internal storage general tunables."
	}},
	{ SSpacer:{
		height:1
	}},
	{ SOptionList:{
		title:"Add Random",
		description:"Draw entropy from spinning (rotational) storage.\n",
		default:0,
		action:"ioset queue add_random",
		values:{
			0:"Disabled", 1:"Enabled"
		}
	}},
	{ SSpacer:{
		height:2
	}},
	{ SOptionList:{
		title:"IO Stats",
		description:"Maintain I/O statistics for this storage device. Disabling will break I/O monitoring apps but reduce CPU overhead.\n",
		default:0,
		action:"ioset queue iostats",
		values:{
			0:"Disabled", 1:"Enabled"
		}
	}},
	{ SSpacer:{
		height:2
	}},
	{ SOptionList:{
		title:"Rotational",
		description:"Treat device as rotational storage.\n",
		default:0,
		action:"ioset queue rotational",
		values:{
			0:"Disabled", 1:"Enabled"
		}
	}},
	{ SSpacer:{
		height:2
	}},
	{ SOptionList:{
		title:"No Merges",
		description:"Types of merges (prioritization) the scheduler queue for this storage device allows.\n",
		default:0,
		action:"ioset queue nomerges",
		values:{
			0:"All", 1:"Simple Only", 2:"None"
		}
	}},
	{ SSpacer:{
		height:2
	}},
	{ SOptionList:{
		title:"RQ Affinity",
		description:"Try to have scheduler requests complete on the CPU core they were made from.\n",
		default:2,
		action:"ioset queue rq_affinity",
		values:{
			0:"Disabled", 1:"Enabled", 2:"Aggressive"
		}
	}},
	{ SSpacer:{
		height:2
	}},
	{ SSeekBar:{
		title:"NR Requests",
		description:"Maximum number of read (or write) requests that can be queued to the scheduler in the block layer.\n",
		step:128,
		min:128,
		max:2048,
		default:$(cat /sys/block/sda/queue/nr_requests),
		action:"ioset queue nr_requests"
	}},
	{ SSpacer:{
		height:2
	}},
	{ SPane:{
		title:"I/O Scheduler Tunables"
	}},
	{ SSpacer:{
		height:1
	}},
	{ STreeDescriptor:{
		path:"/sys/block/sda/queue/iosched",
		generic: {
			directory: {},
			element: {
				SGeneric: { title:"@BASENAME" }
			}
		},
		exclude: [ "weights", "wr_max_time" ]
	}},
    ]
}
CTAG
