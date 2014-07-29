#!/bin/bash
#
# BEGIN_COPYRIGHT
#
# This file is part of SciDB.
# Copyright (C) 2008-2013 SciDB, Inc.
#
# SciDB is free software: you can redistribute it and/or modify
# it under the terms of the AFFERO GNU General Public License as published by
# the Free Software Foundation.
#
# SciDB is distributed "AS-IS" AND WITHOUT ANY WARRANTY OF ANY KIND,
# INCLUDING ANY IMPLIED WARRANTY OF MERCHANTABILITY,
# NON-INFRINGEMENT, OR FITNESS FOR A PARTICULAR PURPOSE. See
# the AFFERO GNU General Public License for the complete license terms.
#
# You should have received a copy of the AFFERO GNU General Public License
# along with SciDB.  If not, see <http://www.gnu.org/licenses/agpl-3.0.html>
#
# END_COPYRIGHT
#
set -eu
################################################################
#
# Needs to be run as root
#
################################################################
#
# Argument processing
#
function usage ()
{
    cat <<EOF

mychroot_run.sh [-h|--help]
mychroot_run.sh [-l|-c "commandline"] <chroot_location> [copy_in]
  -l
    to log into the chroot as root with root's shell.
  -c "commandline"
    to run the "commandline" within the chroot as root and then exit.
    Quote the commandline so it is accepted as a single argument.
  <chroot_location>
  - the chroot directory created with the prepare_mychroot.sh script.
  [copy_in]
  - a list of files and directories to copy into the chroot.
    This is useful if your commandline calls a script that you need
    copied into the chroot.    
EOF
}
if [ $# -eq 0 ]; then
    usage
    exit 0
fi
if [ "${1}" == "-h" ]; then
    usage
    exit 0
fi
if [ "${1}" == "--help" ]; then
    usage
    exit 0
fi

lc="${1}"
commandline=""
if [ "${lc}" == "-l" ]; then
    shift
elif [ "${lc}" == "-c" ]; then
    shift
    if [ $# -eq 0 ]; then
	echo "Expected a commandline. Got nothing."
	usage
	exit 1
    fi
    commandline="${1}"
    shift
else
    echo
    echo "Expected either -l or -c. Got neither."
    usage
    exit 1
fi

root="${1}"
if [ "${root}" == "" ]; then
    echo
    echo "Please specify a chroot_location."
    usage
    exit 1
fi
if [ ! -d "${root}" ]; then
    echo
    echo "chroot_location '${root}' does not exist."
    echo "Please create it using the prepare_mychroot.sh script and try again."
    exit 1
fi
shift

FD="$*"
################################################################
#
# Functions
#
function copy_in {
    for fd in ${FD}
    do
	cp -r $fd ${root}
    done
}
################################################################
#
# If not root then call this script again with sudo
#
if id | grep -q 'uid=0' ; then
    :
else
    if [ "${lc}" == "-c" ]; then
	sudo $0 -c "${commandline}" "${root}" ${FD}
    else
	sudo $0 -l "${root}" ${FD}
    fi
    exit 0
fi
################################################################
#
copy_in
if [ "${lc}" == "-c" ]; then
    chroot ${root} ${commandline}
else
    chroot ${root}
fi
