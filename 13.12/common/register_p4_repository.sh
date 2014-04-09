#!/bin/bash
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
function centos6()
{
echo "[p4]" > p4.repo
echo "name=Paradigm4 repository" >> p4.repo
echo "baseurl=http://${P4CREDS}@downloads.paradigm4.com/private/centos6.3/${release}/" >> p4.repo
echo "gpgkey=http://downloads.paradigm4.com/key" >> p4.repo
echo "gpgcheck=1" >> p4.repo
echo "enabled=0" >> p4.repo
cat p4.repo
REPO_FILE=/etc/yum.repos.d/p4.repo
mv p4.repo ${REPO_FILE}
yum clean all
}

function ubuntu1204()
{
wget -O- http://downloads.paradigm4.com/key | apt-key add -
echo "deb http://${P4CREDS}@downloads.paradigm4.com/private/ ubuntu12.04/${release}/" > p4.list
cat p4.list
REPO_FILE=/etc/apt/sources.list.d/p4.list
mv p4.list ${REPO_FILE}
apt-get update
}

OS=`./os_detect.sh`
release=${1}

# Get the credentials in the form of USERNAME:PASSWORD
P4CREDS=`cat p4_creds.txt | xargs`

if [ "${OS}" = "CentOS 6" ]; then
    centos6
fi

if [ "${OS}" = "RedHat 6" ]; then
    centos6
fi

if [ "${OS}" = "Ubuntu 12.04" ]; then
    ubuntu1204
fi
