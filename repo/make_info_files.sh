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
# This script will process a package distribution directory
# creating informational text file associated with each package.
#
# The purpose behind this is to create a distribution directory
# for non-root installs that can make "package queries"
# such as dependency checks.
#
# This avoids the non-root installer downloading all packages
# in a dependency chain. Later the installer can decide
# which packages to download and take apart.
#
################################################################
#
# Global values
#
################################################################
#
# Argument processing
#
function usage ()
{
    cat <<EOF

$0 [-h|--help] <package_directory>
  <package_directory>
  - where the packages are that will be used by the non-root installer
EOF
}
if [ $# -lt 1 ]; then
    echo
    echo "Not enough arguments"
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

package_directory="${1}"
if [ "${package_directory}" == "" ]; then
    echo
    echo "Please specify a <package_directory>."
    usage
    exit 1
fi
if [ ! -d "${package_directory}" ]; then
    echo
    echo "package_directory '${package_directory}' does not exist."
    echo "Please try again."
    exit 1
fi
################################################################
#
# What type of packages
#
PDDEB=0
if [ `find -L "${package_directory}" -maxdepth 1 -type f -iname \*.deb | wc -l` -ne 0 ]; then
    PDDEB=1
fi
PDRPM=0
if [ `find -L "${package_directory}" -maxdepth 1 -type f -iname \*.rpm | wc -l` -ne 0 ]; then
    PDRPM=1
fi
if [ ${PDDEB} -eq 0 -a ${PDRPM} -eq 0 ]; then
    echo
    echo "Neither .deb nor .rpm files found in ${package_directory}."
    echo "Please try again."
    exit 1
fi
if [ ${PDDEB} -ne 0 -a ${PDRPM} -ne 0 ]; then
    echo
    echo "Both .deb and .rpm files found in ${package_directory}."
    echo "I have no idea what to do."
    echo "Please try again."
    exit 1
fi
################################################################
#
# Functions
#
function get_package_name {
    if [ ${PDDEB} -eq 1 ]; then
	:
    else
	rpm --nosignature --query --queryformat "%{NAME}" --package "${1}"
    fi
}
function package_provides {
    if [ ${PDDEB} -eq 1 ]; then
	:
    else
	rpm --nosignature --query --provides --package "${1}"
    fi
}
function package_requires {
    if [ ${PDDEB} -eq 1 ]; then
	:
    else
	rpm --nosignature --query --requires --package "${1}"
    fi
}
################################################################
#
# Main
package_list=`mktemp "/tmp/${USER}_NR_PL_XXXX"`
temp_file=`mktemp "/tmp/${USER}_NR_TF_XXXX"`
pushd ${package_directory} > /dev/null
if [ ${PDDEB} -eq 1 ]; then
    find -L . -maxdepth 1 -type f -iname \*.deb ! -iname \*.src.deb | sed 's|^\./||' > $package_list
else
    find -L . -maxdepth 1 -type f -iname \*.rpm ! -iname \*.src.rpm  | sed 's|^\./||' > $package_list
fi
popd > /dev/null
while read file
do
    package_file="${package_directory}/${file}"
    package_name="$(get_package_name "${package_file}")"
    package_info="${package_directory}/${package_name}.info"
    echo "F:${file}" > "${package_info}"
    package_provides "${package_file}" | sed 's/^/P:/' >> "${package_info}"
    package_requires "${package_file}" | sed 's/^/R:/' >> "${package_info}"
    grep -v -E '^[PR]:rpmlib' "${package_info}" > "${temp_file}"
    grep -v -E '^[PR]:rtld'   "${temp_file}" >  "${package_info}"
    grep -v -E '^[PR]:pkgconfig\(' "${package_info}" > "${temp_file}"
    grep -v -E '^[PR]:config\(' "${temp_file}" > "${package_info}"
    grep -v -E '^[PR]:fileutils\(' "${package_info}" > "${temp_file}"
    grep -v -E '^[PR]:sh-utils\(' "${temp_file}" > "${package_info}"
    grep -v -E '^[PR]:mktemp\(' "${package_info}" > "${temp_file}"
    sed -e 's/([^)]*)//g' -e 's/\s*=.*//g' -e 's/\s*>=.*//g' -e 's/\s*>.*//g' -e 's/\s*<=.*//g' -e 's/\s*<.*//g' "${package_info}" > "${temp_file}"
    sort -u "${temp_file}" > "${package_info}"
done < $package_list
