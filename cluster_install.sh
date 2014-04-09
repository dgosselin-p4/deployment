#!/bin/bash
#
# BEGIN_COPYRIGHT
#
# This file is part of SciDB.
# Copyright (C) 2008-2014 SciDB, Inc.
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
set -u
################################################################
# Global variables
#
NAPTIME=3
################################################################
# Processed values:
MYDIR=`dirname ${0}`
################################################################
# Functions
function print_usage ()
{
    echo ""
    echo "${0} [-s|-p <credentials>] <network> <configfile>"
    echo "  -s         - install SciDB"
    echo "  -p <credentials>"
    echo "             - install P4"
    echo "               <credentials> is a file with one line of the credentials"
    echo "                (<username>:<password>) to access the P4 downloads."
    echo "  -s -p <credentials>"
    echo "             - install both SciDB and P4"
    echo "  network    - is the network mask the cluster is on"
    echo "  configfile - SciDB configuration file"
}
################################################################
# Argument processing
#
installSciDB=0
installP4=0
credentials=""
while [ $# -gt 0 ]; do
    case ${1} in
	-h|--help)
	    print_usage
	    exit 0
	    ;;
	-s|--scidb)
	    installSciDB=1
	    ;;
	-[pP]|--[pP]4)
	    if [ $# -lt 2 ]; then
		echo
		echo "ERROR: Option ${1} requires an argument."
		print_usage
		exit 1
	    fi
	    credentials="${2}"
	    installP4=1
	    shift
	    ;;
	-*)
	    echo
	    echo "ERROR: Invalid option ${1}."
	    print_usage
	    exit 1
	    ;;
	*)
	    break
	    ;;
    esac
    shift
done
if [ $# -ne 2 ];then
    echo
    echo "ERROR: Wrong number of arguments."
    print_usage
    exit 1
fi
# CREDENTIALS
if [ ${installP4} -eq 1 ];then
    if [ ! -f "${credentials}" ];then
	echo
	echo "ERROR: Credentials '${credentials}' is not readable."
	print_usage
	exit 1
    fi
fi
# NETWORK
network="${1}"
# should be of the form d.d.d.d/d
if [ "`echo ${network} | sed 's|^[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\/[0-9]\{1,2\}$||'`" != "" ];then
    echo
    echo "ERROR: Invalid network format '${network}'."
    echo "       Should be of the form W.X.Y.Z/N."
    print_usage
    exit 1
fi
shift
# CONFIG FILE
config_file="${1}"
if [ ! -f "${config_file}" ];then
    echo
    echo "ERROR: Configuration file '${config_file}' is not readable."
    print_usage
    exit 1
fi
shift
################################################################
# Read in the config.ini file
#   read_config_file is source so that it sets variables in the environment
WORKING_DIR=${MYDIR}
. qualify/read_config_file

################################################################
# CHECK ARGUMENTS
# Must have chosen either -s or -p or both
if [ ${installSciDB} -eq 0 -a ${installP4} -eq 0 ];then
    echo
    echo "ERROR: Unknown installation type."
    echo "       You need to pick one:"
    echo "         install SciDB (-s)"
    echo "         install P4 (-p)"
    echo "         install SciDB and P4 (-s -p)"
    print_usage
    exit 1
fi
if [ ${installSciDB} -eq 0 -a ${installP4} -eq 1 ];then
    #
    # Check if they have SciDB installed
    #
    ssh -n -o StrictHostKeyChecking=no -o BatchMode=yes root@${coordinator} ls -d /opt/scidb/${version}/etc > /dev/null 2>&1
    if [ $? -ne 0 ]; then
	echo
	echo "You have elected to install P4 without installing SciDB."
	echo "BUT there is no SciDB installation."
	echo
	echo -n "Would you like me to also install SciDB ? [y|n] "
	read -e yes_no
	echo
	if [[ ${yes_no} =~ ^[yY] ]]; then
	    installSciDB=1
	else
	    echo "There is no point in install P4 without SciDB."
	    echo "Exiting."
	    exit 1
	fi
    fi
fi
################################################################
# RUN QUALIFY
#
cd qualify
./qualify ../${config_file}
cd ../
################
# HERE WE GO
if [ ${installSciDB} -eq 1 ]; then
    echo
    echo '**********************************************************'
    echo '* Configure and start Postgresql on the coordinator host *'
    echo '**********************************************************'
    echo
    SCIDB_VERSION=${version} ${MYDIR}/deploy.sh prepare_postgresql scidb "" ${network} ${coordinator}
    echo
    echo '******************************************'
    echo '* Installing SciDB to the cluster hosts. *'
    echo '******************************************'
    echo
    sleep ${NAPTIME}
    SCIDB_VERSION=${version} ${MYDIR}/deploy.sh scidb_install_release ${version} `cat $host_file`
fi
if [ ${installP4} -eq 1 ];then
    echo
    echo '***************************************'
    echo '* Installing P4 to the cluster hosts. *'
    echo '***************************************'
    echo
    sleep ${NAPTIME}
    if [ -f "${credentials}" ];then
	cp -f "${credentials}" "${MYDIR}/common/p4_creds.txt"
    else
	cp -f "${MYDIR}/p4_creds.txt" "${MYDIR}/common/p4_creds.txt"
    fi
    SCIDB_VERSION=${version} ${MYDIR}/deploy.sh p4_install_release ${version} `cat $host_file`
    rm -f "${MYDIR}/common/p4_creds.txt"
fi
if [ ${installSciDB} -eq 1 ]; then
    echo
    echo '********************************************************************'
    echo '* Configure SciDB to run under user scidb                          *'
    echo '********************************************************************'
    echo
    sleep ${NAPTIME}
    if [ "${config_file}" != "config.ini" ];then
	cp -f "${config_file}" config.ini
    fi
    SCIDB_VERSION=${version} ${MYDIR}/deploy.sh scidb_prepare_wcf scidb "" "${cluster_name}" `cat $host_file`
    if [ "${config_file}" != "config.ini" ];then
	rm -f config.ini
    fi
fi
