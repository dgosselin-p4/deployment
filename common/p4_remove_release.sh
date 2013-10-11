#!/bin/bash
#
########################################
# BEGIN_COPYRIGHT
#
# PARADIGM4 INC.
# This file is part of the Paradigm4 Enterprise SciDB distribution kit
# and may only be used with a valid Paradigm4 contract and in accord
# with the terms and conditions specified by that contract.
#
# Copyright © 2010 - 2013 Paradigm4 Inc.
# All Rights Reserved.
#
# END_COPYRIGHT
########################################

function centos6 ()
{
    transaction=`yum history list scidb-${release}-p4 | awk '$1 ~ /[0-9]+/ {print $1}' | head -1`
    if [ "${transaction}" != "" ]; then
	yum history undo -y ${transaction}
    fi
}

function ubuntu1204 ()
{
    apt-get update
    apt-get purge -y scidb-${release}-p4
    apt-get autoremove --purge -y
}

OS=`./os_detect.sh`
release=${1}

if [ "${OS}" = "CentOS 6" ]; then
    centos6
fi

if [ "${OS}" = "RedHat 6" ]; then
    centos6
fi

if [ "${OS}" = "Ubuntu 12.04" ]; then
    ubuntu1204
fi
