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
# Global variables
#
# detect directory where we run
here="$(dirname $0)"
#
SCP="scp -r -q -o StrictHostKeyChecking=no"
SSH="ssh -o StrictHostKeyChecking=no"
#
NAPTIME=3
#
################################################################
# Functions
function print_usage ()
{
    echo ""
    echo "${0} [-s|-p <credentials>] <ssh_key_file> <hostlist> <network> <configfile> <version>"
    echo "  -s         - if installing SciDB without P4"
    echo "  -p <credentials>"
    echo "             - if installing SciDB with P4"
    echo "               <credentials> is a file with one line of the credentials"
    echo "                (<username>:<password>) to access the P4 downloads."
    echo "  ssh_key_file"
    echo "             - the ssh public key file to use for root and scidb access to all hosts"
    echo "               Note: either use a keyring or make the key passphrase-less"
    echo "  hostlist   - a file listing the hosts in the cluster"
    echo "             - the first line is the coordinator"
    echo "  network    - is the network mask the cluster is on"
    echo "  configfile - SciDB configuration file"
    echo "  version    - version of SciDB you wish to install (ie. 13.12)"
}
################################################################
# Argument processing
#
installation=""
credentials=""
while [ $# -gt 0 ]; do
    case ${1} in
	-h|--help)
	    print_usage
	    exit 0
	    ;;
	-s|--scidb)
	    installation="s"
	    ;;
	-[pP]|--[pP]4)
	    if [ $# -lt 2 ]; then
		echo
		echo "ERROR: Option ${1} requires an argument."
		print_usage
		exit 1
	    fi
	    credentials="${2}"
	    installation="p"
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
if [ $# -ne 5 ];then
    echo
    echo "ERROR: Wrong number of arguments."
    print_usage
    exit 1
fi
# Must have chosen either -s or -p
if [ "${installation}" != "s" -a "${installation}" != "p" ];then
    echo
    echo "ERROR: Unknown installation type."
    echo "       You need to pick SciDB with or without P4."
    echo "       [-s|-p credentials]"
    print_usage
    exit 1
fi
# CREDENTIALS
if [ "${installation}" = "p" ];then
    if [ ! -f "${credentials}" ];then
	echo
	echo "ERROR: Credentials '${credentials}' is not readable."
	print_usage
	exit 1
    fi
fi
# SSH KEY
key="${1}"
if [ ! -f "$key" ];then
    echo
    echo "ERROR: Keyfile '$key' is not readable."
    print_usage
    exit 1
fi
function notKey () {
    echo
    echo "ERROR: Keyfile '$key' is not a public key file."
    print_usage
    exit 1
}
ssh-keygen -l -f "${key}" > /dev/null || notKey
key=`cat $key`
shift
# LIST OF HOSTS
hostlist="${1}"
if [ ! -f "$hostlist" ];then
    echo
    echo "ERROR: Hostlist '$hostlist' is not readable."
    print_usage
    exit 1
fi
shift
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
# VERSION
version="${1}"
if [[ ${version} =~ ^[0-9]{2}\.[0-9]{1,2}$ ]]; then
    VMajor=${version%.*}
    VMinor=${version#*.}
    if [ ${VMajor} -lt 13 ]; then
	echo
	echo "ERROR: This script does not support SciDB versions less than 13.11"
	exit 1
    fi
    if [ ${VMajor} -eq 13 ]; then
	if [ ${VMinor} -lt 11 ]; then
	    echo
	    echo "ERROR: This script does not support SciDB versions less than 13.11"
	    exit 1
	fi
    fi
else
    echo
    echo "ERROR: Not a valid version number."
    exit 1
fi
shift
################################################################
# Read configuration file to get the name of the database
# Find line of "[database]" and extract name within the brackets
#
database=""
database="`grep -E '^\[.*\]$' ${config_file} | sed -e 's/\[//' -e 's/\]//'`"
if [ "${database}" = "" ];then
    echo
    echo "ERROR: Invalid configuration file. Can not find database name."
    exit 1
fi
################################################################
# Main
#
echo
echo '***********************************************************************************************'
echo '* Enabling ssh access for root account from localhost to the cluster hosts with NO PASSPHRASE *'
echo '***********************************************************************************************'
echo
sleep ${NAPTIME}
SCIDB_VERSION=${version} ${here}/deploy.sh access root "" "${key}" `cat $hostlist`
echo
echo '***********************************************************************************************'
echo '* Testing ssh access for root account from localhost to the cluster hosts with NO PASSPHRASE *'
echo '***********************************************************************************************'
echo
for h in `cat $hostlist`
do
    if ! ssh -o PreferredAuthentications=publickey root@$h hostname ; then
	echo
	echo "Sorry, key authentication failed for root@$h."
	echo "Please correct the problem and try again."
	exit 1
    fi
done
echo
echo '************************************************************************************************'
echo '* Enabling ssh access for scidb account from localhost to the cluster hosts with NO PASSPHRASE *'
echo '************************************************************************************************'
echo
sleep ${NAPTIME}
SCIDB_VERSION=${version} ${here}/deploy.sh access scidb "" "${key}" `cat $hostlist`
echo
echo '***********************************************************************************************'
echo '* Testing ssh access for scidb account from localhost to the cluster hosts with NO PASSPHRASE *'
echo '***********************************************************************************************'
echo
for h in `cat $hostlist`
do
    if ! ssh -o PreferredAuthentications=publickey scidb@$h hostname ; then
	echo
	echo "Sorry, key authentication failed for scidb@$h."
	echo "Please correct the problem and try again."
	exit 1
    fi
done
echo
echo '**********************************************************'
echo '* Configure and start Postgresql on the coordinator host *'
echo '**********************************************************'
echo
sleep ${NAPTIME}
SCIDB_VERSION=${version} ${here}/deploy.sh prepare_postgresql scidb "" ${network} `head -1 $hostlist`
echo
echo '******************************************'
echo '* Installing SciDB to the cluster hosts. *'
echo '******************************************'
echo
sleep ${NAPTIME}
SCIDB_VERSION=${version} ${here}/deploy.sh scidb_install_release ${version} `cat $hostlist`
if [ "${installation}" = "p" ];then
    echo
    echo '***************************************'
    echo '* Installing P4 to the cluster hosts. *'
    echo '***************************************'
    echo
    sleep ${NAPTIME}
    if [ -f "${credentials}" ];then
	cp -f "${credentials}" "${here}/common/p4_creds.txt"
    else
	cp -f "${here}/p4_creds.txt" "${here}/common/p4_creds.txt"
    fi
    SCIDB_VERSION=${version} ${here}/deploy.sh p4_install_release ${version} `cat $hostlist`
    rm -f "${here}/common/p4_creds.txt"
fi
echo
echo '********************************************************************'
echo '* Configure SciDB to run under user scidb                          *'
echo '*   using mydb as the Postgres role/database_name/password,        *'
echo '*   using /home/scidb/mydb-DB as the root for SciDB storage,       *'
echo '*   using config file: ' "${config_file}" '.                       *'
echo '********************************************************************'
echo
sleep ${NAPTIME}
if [ "${config_file}" != "config.ini" ];then
    cp -f "${config_file}" config.ini
fi
SCIDB_VERSION=${version} ${here}/deploy.sh scidb_prepare_wcf scidb "" "${database}" `cat $hostlist`
if [ "${config_file}" != "config.ini" ];then
    rm -f config.ini
fi
