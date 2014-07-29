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
# Global values
################################################################
#
# Argument processing
#
function usage ()
{
    cat <<EOF

prepare_mychroot.sh [-h|--help] <chroot_location> <OSversion>
  <chroot_location>
  - where to create the root directory
  <OSversion>
  - version of the OS you want in the chroot
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
    echo "Please create the directory and try again."
    exit 1
fi
shift

if [ $# -eq 0 ]; then
    echo
    echo "Please specify an OS version."
    usage
    exit 0
fi
OSver="${1}"
if [[ ${OSver} =~ ^[0-9][0-9]{0,1}\.[0-9][0-9]{0,1}$ ]]; then
    :
else
    echo
    echo "Please specify a valid OS version XX.YY."
    usage
    exit 0
fi
################################################################
#
# Functions
#
function centos_rpm {
    arch=`uname -m`
    if [ "${arch}" != "x86_64" ];then
	echo
	echo "Sorry only supporting x86_64 architecture not '${arch}'."
	exit 0
    fi
    case ${OSver} in
	6.0)
	    CENTOS_DOWNLOAD="http://vault.centos.org/6.0/os/x86_64/Packages/centos-release-6-0.el6.centos.5.x86_64.rpm"
	    CENTOS_RPM="centos-release-6-0.el6.centos.5.x86_64.rpm"
	    ;;
	6.1)
	    CENTOS_DOWNLOAD="http://vault.centos.org/6.1/os/x86_64/Packages/centos-release-6-1.el6.centos.6.x86_64.rpm"
	    CENTOS_RPM="centos-release-6-1.el6.centos.6.x86_64.rpm"
	    ;;
	6.2)
	    CENTOS_DOWNLOAD="http://vault.centos.org/6.2/os/x86_64/Packages/centos-release-6-2.el6.centos.7.x86_64.rpm"
	    CENTOS_RPM="centos-release-6-2.el6.centos.7.x86_64.rpm"
	    ;;
	6.3)
	    CENTOS_DOWNLOAD="http://vault.centos.org/6.3/os/x86_64/Packages/centos-release-6-3.el6.centos.9.x86_64.rpm"
	    CENTOS_RPM="centos-release-6-3.el6.centos.9.x86_64.rpm"
	    ;;
	6.4)
	    CENTOS_DOWNLOAD="http://vault.centos.org/6.4/os/x86_64/Packages/centos-release-6-4.el6.centos.10.x86_64.rpm"
	    CENTOS_RPM="centos-release-6-4.el6.centos.10.x86_64.rpm"
	    ;;
	6.5)
	    CENTOS_DOWNLOAD="http://mirror.centos.org/centos/6/os/x86_64/Packages/centos-release-6-5.el6.centos.11.1.x86_64.rpm"
	    CENTOS_RPM="centos-release-6-5.el6.centos.11.1.x86_64.rpm"
	    ;;
    esac
}
function centos {
    pushd ${root}
    if [ ! -f "${CENTOS_RPM}" ]; then
	wget "${CENTOS_DOWNLOAD}"
    fi
    if [ ! -d "var/lib/rpm" ]; then
	mkdir -p "var/lib/rpm"
    fi
    rpm -i --root=${root} --nodeps "${CENTOS_RPM}" || true
    yum --installroot=${root} install -y rpm-build yum
    popd
    #
    # Provide nslookup within chroot
    cp -p /etc/resolv.conf ${root}/etc/resolv.conf
}

function ubuntu ()
{
    echo ubuntu
}
################################################################
#
# If not root then call this script again with sudo
#

if id | grep -q 'uid=0' ; then
    :
else
    sudo $0 "${root}" "${OSver}"
    exit 0
fi
################################################################
#
# Call function appropriate to the OS
#
case `awk 'NR == 1 {print $1}' /etc/issue` in
    "CentOS")
	centos_rpm
	centos
	;;
    "Red")
	redhat
	;;
    "Ubuntu")
	ubuntu
	;;
    *)
	echo "Not a supported OS"
	exit 1
	;;
esac
