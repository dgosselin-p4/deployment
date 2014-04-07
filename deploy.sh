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

set -eu

function print_usage()
{
cat <<EOF
USAGE
  deploy.sh usage - print this usage
  deploy.sh help  - print verbose help

Configuring remote access:
  deploy.sh access  <os_user> <os_user_passwd> <ssh_public_key> <host ...>

Preparing remote machines:
  deploy.sh prepare_postgresql  <postgresql_os_username>
                                <postgresql_os_password>
                                <network/mask>
                                <scidb-coordinator-host>

SciDB control on remote machines:
  deploy.sh scidb_install_release <ScidbVersion> <coordinator-host> [host ...]
  deploy.sh scidb_remove_release  <ScidbVersion> <coordinator-host> [host ...]
  deploy.sh scidb_prepare_wcf <scidb_os_user> <scidb_os_passwd>
                             <database>
                             <coordinator-host> [host ...]
EOF
echo
}

function print_usage_exit ()
{
print_usage
exit ${1}
}

function print_help ()
{
print_usage
echo
cat <<EOF
DESCRIPTION

  deploy.sh can be used to bootstrap a cluster of machines/hosts for running SciDB.
  It assumes that its user has the root privileges on all the hosts in the cluster.
  It also requires password-less ssh from the local host to the cluster as root (see access).

  WARNING: the 'expect' tool and the bash shell are required for running deploy.sh
  Ubuntu: apt-get install -y expect
  CentOS/RedHat: yum install -y expect

Commands:
  access               Provide password-less ssh access to each <host ...> for <scidb_os_user> with <ssh_public_key>.
                       do not supply <os_user_passwd> (first '') on the command line, which exposes it via ps(1)
                       and leaves a copy in your shell history file even after logout. The option is for backwards compatibility
                       only.
                       Giving '' for <ssh_public_key> uses ~/.ssh/id_rsa.pub key.

  prepare_postgresql   Install & configure PostgreSQL on <scidb-coordinator-host>.
                       <postgresql_os_username> - OS user for PostgreSQL (commonly used name is 'postgres')
                       <postgresql_os_password> - password for PostgreSQL user
                       <network/mask> - subnet identifier in the CIDR (W.X.Y.Z/N) notation

  scidb_install_release
                       Install SciDB release <ScidbVersion> on <coordinator-host> and <host ...>.
                       The first host is the cluster coordinator, and some packages are installed only on the coordinator.

  scidb_remove_release Remove SciDB release <ScidbVersion> from <coordinator-host> and <host ...>

  scidb_prepare_wcf    Prepare the cluster for running SciDB as <scidb_os_user>. <scidb_os_passwd> should be "" and be supplied on stdin.
                       Supplying passwords on the command line in clear text is a well-known security risk because they can be viewed by
                       other users of the system. The option is only for backwards compatibility.
                       The first host, <coordinator-host>, is the cluster coordinator, and some steps are performed only on that host.
                       The configuration file is assumed to be in the pwd named config.ini.
                       It will also setup a password-less ssh from <coordinator-host>
                       to *all* hosts using <scidb_os_user> and <scidb_os_passwd>
                       and update <scidb_os_user>'s default PATH & LD_LIBRARY_PATH in ~<scidb_os_user>/.bashrc
EOF
echo
}

# detect directory where we run and use that to find
bin_path=$(readlink -f $(dirname $0)/common)
echo "Script common path: ${bin_path}"

SCIDB_VERSION=${SCIDB_VERSION:=NOTSET}
if [ "$SCIDB_VERSION" != "NOTSET" ]; then
    # If SCIDB_VERSION is set use that as the version number
    SCIDB_VER=${SCIDB_VERSION}
else
    echo "Environment variable SCIDB_VERSION is not set."
    exit 1
fi
echo "SciDB version: ${SCIDB_VER}"

SCP="scp -r -q -o StrictHostKeyChecking=no"
SSH="ssh -o StrictHostKeyChecking=no"

# get password for username from stdin
# assign the value to variable password
# if no password given, exit
function get_password()
{
    local username="${1}"

    read -s -p "Enter ${username}'s password (only once):" password
    if [ "${password}" == "" ]; then
       echo "No password given"
       exit 1
    fi
}

# run command on remote host
# if password specified, it would used on password prompt
function remote_no_password ()
{
local username=${1}
local password="${2}"
local hostname=${3}
shift 3
expect <<EOF
log_user 1
set timeout -1
spawn $@
expect {
  "${username}@${hostname}'s password:" { send "${password}\r"; exp_continue }
  eof                                   { }
}
catch wait result
exit [lindex \$result 3]
EOF
if [ $? -ne 0 ]; then
echo "Remote command failed!"
exit 1
fi
}

# Run command on remote host (with some prepared scripts/files)
# 1) copy ./deployment/common to remote host to /tmp/${username}/deployment
# 2) (If) specified files would be copied to remote host to /tmp/${username}/deployment
# 3) execute ${4} command on remote host
# 4) remove /tmp/${username}/deployment from remote host
function remote ()
{
local username=${1}
local password="${2}"
local hostname=${3}
local files=${5-""}
remote_no_password "${username}" "${password}" "${hostname}" "${SSH} ${username}@${hostname}  \"rm -rf /tmp/${username}/deployment && mkdir -p /tmp/${username}\""
remote_no_password "${username}" "${password}" "${hostname}" "${SCP} ${bin_path} ${username}@${hostname}:/tmp/${username}/deployment"
if [ -n "${files}" ]; then
    remote_no_password "${username}" "${password}" "${hostname}" "${SCP} ${files} ${username}@${hostname}:/tmp/${username}/deployment"
fi;
remote_no_password "${username}" "${password}" "${hostname}" "${SSH} ${username}@${hostname} \"cd /tmp/${username}/deployment && ${4}\""
remote_no_password "${username}" "${password}" "${hostname}" "${SSH} ${username}@${hostname}  \"rm -rf /tmp/${username}/deployment\""
}

# Provide password-less access to remote host
function provide_password_less_ssh_access ()
{
    local username=${1}
    local password="${2}"
    local key=${3}
    local hostname=${4}
    echo "Provide access by ~/.ssh/id_rsa.pub to ${username}@${hostname}"
    remote "${username}" "${password}" "${hostname}" "./user_access.sh \\\"${username}\\\" \\\"${key}\\\""
}

# Register 3rdparty SciDB repository on remote host
function register_3rdparty_scidb_repository ()
{
    local hostname=${1}
    echo "Register SciDB 3rdparty repository on ${hostname}"
    remote root "" ${hostname} "./register_3rdparty_scidb_repository.sh"
}

# Register released SciDB repository on remote host
function register_scidb_repository ()
{
    local release=${1}
    local hostname=${2}
    echo "Register SciDB repository ${release} on ${hostname}"
    remote root "" ${hostname} "./register_scidb_repository.sh ${release}"
}

# Install & configure PostgreSQL
function install_and_configure_postgresql ()
{
    local username=${1}
    local password="${2}"
    local network=${3}
    local hostname=${4}
    remote root "" ${hostname} "./configure_postgresql.sh ${username} \\\"${password}\\\" ${network}"
}

# Remove SciDB Release from remote host
function scidb_remove_release()
{
    local release=${1}
    local hostname=${2}
    local with_coordinator=${3}

    remote root "" "${hostname}" "./scidb_remove_release.sh ${release} ${with_coordinator}"
}

# Install SciDB to remote host from a release on 
function scidb_install_release()
{
    local release=${1}
    local hostname=${2}
    local with_coordinator=${3}
    register_scidb_repository "${release}" "${hostname}"
    register_3rdparty_scidb_repository "${hostname}"
    remote root "" "${hostname}" "./scidb_install_release.sh ${release} ${with_coordinator}"
}

# Prepare machine for run SciDB (setup environment, copy in config file, etc)
function scidb_prepare_node ()
{
    local username="${1}"
    local password="${2}"
    local hostname=${3}
    remote root "" ${hostname} "su -l ${username} -c '/tmp/root/deployment/scidb_prepare.sh ${SCIDB_VER}'"
    remote root "" ${hostname} "cat config.ini > /opt/scidb/${SCIDB_VER}/etc/config.ini && chown ${username} /opt/scidb/${SCIDB_VER}/etc/config.ini" `readlink -f ./config.ini`
}

# Prepare SciDB cluster given a config file (wcf=With Configuration File)
function scidb_prepare_wcf ()
{
    local username="${1}"
    local password="${2}"
    local database=${3}
    local coordinator=${4}
    shift 4


    # deposit config.ini to coordinator
    local hostname
    for hostname in ${coordinator} $@; do
        # generate scidb environment for username
	scidb_prepare_node "${username}" "${password}" ${hostname} # not ideal to modify the environment
    done;
    remote root "" ${coordinator} "./scidb_prepare_coordinator.sh ${username} ${database} ${SCIDB_VER}" 
}

# Register released P4 repository on remote host
function register_p4_repository ()
{
    local release=${1}
    local hostname=${2}
    echo "Register P4 repository ${release} on ${hostname}"
    remote root "" ${hostname} "./register_p4_repository.sh ${release}"
}

# Install P4 to remote host from the repo
function p4_install_release()
{
    local release=${1}
    local hostname=${2}
    register_p4_repository "${release}" "${hostname}"
    remote root "" "${hostname}" "./p4_install_release.sh ${release}"
}

# Remove P4 Release from remote host
function p4_remove_release()
{
    local release=${1}
    local hostname=${2}
    remote root "" "${hostname}" "./p4_remove_release.sh ${release}"
}

if [ $# -lt 1 ]; then
    print_usage_exit 1
fi

echo "Executing: $@"
echo

case ${1} in
    help)
        if [ $# -gt 2 ]; then
            print_usage_exit 1
        fi
        print_help
        ;;
    usage)
        if [ $# -gt 2 ]; then
            print_usage_exit 1
        fi
        print_usage
        ;;
    access)
	if [ $# -lt 5 ]; then
	    print_usage_exit 1
	fi
	username="${2}"
	password="${3}"
	key="${4}"
	shift 4
	if [ "${key}" == "" ]; then
	    key="`cat ~/.ssh/id_rsa.pub`"
	fi
        if [ "${password}" == "" ]; then
           get_password "${username}"
        fi
	for hostname in $@; do 
	    provide_password_less_ssh_access "${username}" "${password}" "${key}" "${hostname}"
	done;
	;;
    prepare_postgresql)
	if [ $# -ne 5 ]; then
	    print_usage_exit 1
	fi
	username=${2}
	password="${3}"
	network=${4}
	hostname=${5}
	install_and_configure_postgresql ${username} "${password}" ${network} ${hostname}
	;;
    scidb_install_release)
	if [ $# -lt 3 ]; then
	    print_usage_exit 1
	fi
	releaseNum=${2}
	coordinator=${3}
	echo "Coordinator IP: ${coordinator}"
	shift 3
	scidb_install_release ${releaseNum} ${coordinator} 1
	for hostname in $@; do
	    scidb_install_release ${releaseNum} ${hostname} 0
	done;
	;;
    scidb_remove_release)
	if [ $# -lt 3 ]; then
	    print_usage_exit 1
	fi
	releaseNum=${2}
	coordinator=${3}
	echo "Coordinator IP: ${coordinator}"
	shift 3
	scidb_remove_release ${releaseNum} ${coordinator} 1
	for hostname in $@; do
	    scidb_remove_release ${releaseNum} ${hostname} 0
	done;
	;;
    scidb_prepare_wcf)
	if [ $# -lt 5 ]; then
	    print_usage_exit 1
	fi
        username=${2}
        password="${3}"
        database=${4}
        coordinator=${5}
        shift 5
	scidb_prepare_wcf ${username} "${password}" ${database} ${coordinator} $@
	;;
    p4_install_release)
	if [ $# -lt 3 ]; then
	    print_help
	fi
	release=${2}
	shift 2
	for hostname in $@; do
	    p4_install_release ${release} ${hostname}
	done;
	;;
    p4_remove_release)
	if [ $# -lt 3 ]; then
	    print_help
	fi
	release=${2}
	shift 2
	for hostname in $@; do
	    p4_remove_release ${release} ${hostname}
	done;
	;;
    *)
	print_usage_exit 1
	;;
esac
exit 0
