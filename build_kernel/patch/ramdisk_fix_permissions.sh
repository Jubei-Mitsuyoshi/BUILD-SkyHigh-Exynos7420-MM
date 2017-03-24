#!/bin/bash
#
# Modified work Copyright (c) 2017 UpInTheAir. All rights reserved.
#
# Authors:
#
# Contributors:	UpInTheAir
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

chmod 644 file_contexts
chmod 644 se*
chmod 644 *.rc
chmod 750 init*
chmod 640 fstab*
chmod 644 default.prop
chmod 771 data
chmod 755 dev
chmod 755 lib/modules/*
chmod 755 proc
chmod 755 res
chmod 755 res/*
chmod 755 sbin
chmod 755 sbin/*
cd sbin
chmod 755 su
chmod 664 su/*
chmod 644 *.sh
chmod 644 uci
cd ../
chmod 755 init
chmod 755 sys
chmod 755 system
