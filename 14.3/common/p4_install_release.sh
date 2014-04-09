#!/bin/bash
########################################
# BEGIN_COPYRIGHT
#
# PARADIGM4 INC.
# This file is part of the Paradigm4 Enterprise SciDB distribution kit
# and may only be used with a valid Paradigm4 contract and in accord
# with the terms and conditions specified by that contract.
#
# Copyright © 2010 - 2014 Paradigm4 Inc.
# All Rights Reserved.
#
# END_COPYRIGHT
########################################

function centos6 ()
{
    yum install --enablerepo=scidb --enablerepo=scidb3rdparty --enablerepo=p4 -y scidb-${release}-p4
}

function ubuntu1204 ()
{
    apt-get update
    apt-get install -y scidb-${release}-p4
}

OS=`./os_detect.sh`
release="${1}"

if [ "${OS}" = "CentOS 6" ]; then
    centos6
fi

if [ "${OS}" = "RedHat 6" ]; then
    centos6
fi

if [ "${OS}" = "Ubuntu 12.04" ]; then
    ubuntu1204
fi
