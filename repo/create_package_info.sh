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
################################################################
# Arg 1 is the version of SciDB
SCIDBver="${1}"
################################################################
# Global values
SCIDBpkg="scidb-${SCIDBver}-all-coord"
################################################################
#
# Needs to be run as root
#
# If not root then call this script again with sudo
#
if id | grep -q 'uid=0' ; then
    :
else
    sudo $0
fi
################################################################
# Need the following packages
echo
echo "Make sure yum-utils is installed..."
yum -y install yum-utils
echo
echo "Make sure wget is installed..."
yum -y install wget
################################################################
# First setup scidb repo
#
cat > /etc/yum.repos.d/scidb.repo <<EOF
[scidb]
name=SciDB repository
baseurl=http://downloads.paradigm4.com/centos6.3/$SCIDBver
gpgkey=http://downloads.paradigm4.com/key
gpgcheck=1
enabled=1
EOF
################################################################
# Use yumdownloader to output what URLs would be downloaded
# to resolve installing SCIDBpkg
#
# This file will be used in the non-root installer
# to download all the packages to unroll into the
# user's installation directory.
#
echo
echo "Running yumdownloader to get a list of packages needed by ${SCIDBpkg}..."
yumdownloader --urls --resolve ${SCIDBpkg} | grep -F 'http://' > ${SCIDBpkg}.urls
################################################################
# Download all those packages
#
echo
echo "Downloading packages..."
mkdir -p pkgdir
pushd pkgdir > /dev/null
while read pkg
do
    wget "$pkg"
done < ../${SCIDBpkg}.urls
popd > /dev/null
################################################################
# Create info file for each package
echo
echo "Creating info files for packages..."
./repo/make_info_files.sh pkgdir
# Create
echo
echo "Creating the requires file for ${SCIDBpkg}..."
./repo/make_depends_files.sh pkgdir ${SCIDBpkg}
cp pkgdir/${SCIDBpkg}.requires .
