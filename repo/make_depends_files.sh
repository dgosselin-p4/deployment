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
################################################################
#
# This script is given a package directory
# (with SciDB or P4 .deb/.rpm packages)
# and a package.
#
# The output is a list of SciDB and P4 packages
# that are required (recursively) by the given package.
# Also a script to run on the cluster to see that
# all required libraries are available.
#
# There are 3 lists:
# 1. Requires - what is still required (still remains to find)
# 2. Provides - what has been provided
# (and so doesn't need to be provided again)
# 3. Files - what package files have been processed
# and are expected to be loaded.
#
# The cycle starts with loading the Requires list with the
# package given as an argument.
# The Requires list is processed one item at a time.
# This means the package info is parsed and the 3 lists are updated.
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

$0 [-h|--help] <package_directory> <package>
  <package_directory>
  - where the packages are that will be used by the non-root installer
v    This should also include .info files created by make_nonroot_repo.sh
  <package>
  - the package you want to generate requirements about
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
if [ $# -lt 2 ]; then
    echo
    echo "Not enough arguments"
    usage
    exit 0
fi
package="${2}"
if [ "${package}" == "" ]; then
    echo
    echo "Please specify a <package>."
    usage
    exit 1
fi
if [ ! -f "${package_directory}/${package}.info" ]; then
    echo
    echo "<package> ${package} not found."
    exit 1
fi
################################################################
#
# Array functions
#
declare -a Requires=()
declare -i iRequires=0
declare -a Provides=()
declare -i iProvides=0
declare -a Files=()
declare -i iFiles=0
declare -a NotFound=()
declare -i iNotFound=0
#
# Helper variable (return value)
declare returnValue
#
# Requires Array Functions
function pushRequires () {
    local i
    for (( i=0; i<$iRequires; i++ ))
    do
	if [ "${Requires[$i]}" == "$1" ]; then
	    # duplicate
	    return 0
	fi
    done
    Requires[$iRequires]="$1"
    iRequires=$iRequires+1
}
function popRequires () {
    if [ $iRequires -ne 0 ]; then
	iRequires=$iRequires-1
	returnValue=${Requires[${iRequires}]}
	unset Requires[${iRequires}]
    fi
}
function findRequires () {
    local i
    for (( i=0; i<$iRequires; i++ ))
    do
	if [ "${Requires[$i]}" == "$1" ]; then
	    break
	fi
    done
    if [ $i -eq $iRequires ]; then
	return 1
    else
	return 0
    fi
}
function popFoundRequires () {
    local i
    for (( i=0; i<$iRequires; i++ ))
    do
	if [ "${Requires[$i]}" == "$1" ]; then
	    break
	fi
    done
    if [ $i -eq $iRequires ]; then
	# Not found
	return 1
    else
	# Shift array over the found item
	for (( i=$i ; i<$iRequires-1; i++))
	do
	    Requires[$i]="${Requires[$i+1]}"
	done
	iRequires=$iRequires-1
	unset Requires[${iRequires}]
    fi
}
#
# Provides Array Functions
function pushProvides () {
    local i
    for (( i=0; i<$iProvides; i++ ))
    do
	if [ "${Provides[$i]}" == "$1" ]; then
	    # duplicate
	    return 0
	fi
    done
    Provides[$iProvides]="$1"
    iProvides=$iProvides+1
}
function popProvides () {
    if [ $iProvides -ne 0 ]; then
	iProvides=$iProvides-1
	returnValue=${Provides[${iProvides}]}
	unset Provides[${iProvides}]
    fi
}
function findProvides () {
    local i
    for (( i=0; i<$iProvides; i++ ))
    do
	if [ "${Provides[$i]}" == "$1" ]; then
	    break
	fi
    done
    if [ $i -eq $iProvides ]; then
	return 1
    else
	return 0
    fi
}
function popFoundProvides () {
    local i
    for (( i=0; i<$iProvides; i++ ))
    do
	if [ "${Provides[$i]}" == "$1" ]; then
	    break
	fi
    done
    if [ $i -eq $iProvides ]; then
	# Not found
	return 1
    else
	# Shift array over the found item
	for (( i=$i ; i<$iProvides-1; i++))
	do
	    Provides[$i]="${Provides[$i+1]}"
	done
	iProvides=$iProvides-1
	unset Provides[${iProvides}]
    fi
}
#
# Files Array Functions
function pushFiles () {
    local i
    for (( i=0; i<$iFiles; i++ ))
    do
	if [ "${Files[$i]}" == "$1" ]; then
	    # duplicate
	    return 0
	fi
    done
    Files[$iFiles]="$1"
    iFiles=$iFiles+1
}
function popFiles () {
    if [ $iFiles -ne 0 ]; then
	iFiles=$iFiles-1
	returnValue=${Files[${iFiles}]}
	unset Files[${iFiles}]
    fi
}
function findFiles () {
    local i
    for (( i=0; i<$iFiles; i++ ))
    do
	if [ "${Files[$i]}" == "$1" ]; then
	    break
	fi
    done
    if [ $i -eq $iFiles ]; then
	return 1
    else
	return 0
    fi
}
function popFoundFiles () {
    local i
    for (( i=0; i<$iFiles; i++ ))
    do
	if [ "${Files[$i]}" == "$1" ]; then
	    break
	fi
    done
    if [ $i -eq $iFiles ]; then
	# Not found
	return 1
    else
	# Shift array over the found item
	for (( i=$i ; i<$iFiles-1; i++))
	do
	    Files[$i]="${Files[$i+1]}"
	done
	iFiles=$iFiles-1
	unset Files[${iFiles}]
    fi
}
#
# NotFound Array Functions
function pushNotFound () {
    local i
    for (( i=0; i<$iNotFound; i++ ))
    do
	if [ "${NotFound[$i]}" == "$1" ]; then
	    # duplicate
	    return 0
	fi
    done
    NotFound[$iNotFound]="$1"
    iNotFound=$iNotFound+1
}
function popNotFound () {
    if [ $iNotFound -ne 0 ]; then
	iNotFound=$iNotFound-1
	returnValue=${NotFound[${iNotFound}]}
	unset NotFound[${iNotFound}]
    fi
}
function findNotFound () {
    local i
    for (( i=0; i<$iNotFound; i++ ))
    do
	if [ "${NotFound[$i]}" == "$1" ]; then
	    break
	fi
    done
    if [ $i -eq $iNotFound ]; then
	return 1
    else
	return 0
    fi
}
function popFoundNotFound () {
    local i
    for (( i=0; i<$iNotFound; i++ ))
    do
	if [ "${NotFound[$i]}" == "$1" ]; then
	    break
	fi
    done
    if [ $i -eq $iNotFound ]; then
	# Not found
	return 1
    else
	# Shift array over the found item
	for (( i=$i ; i<$iNotFound-1; i++))
	do
	    NotFound[$i]="${NotFound[$i+1]}"
	done
	iNotFound=$iNotFound-1
	unset NotFound[${iNotFound}]
    fi
}
################################################################
#
# Function to parse a package info file
# and update the 3 Arrays.
#
function getPackage () {
    if findProvides $1 ; then
	return
    fi
    infoFile="`grep -l -E "^P:${1}\s*$" ${package_directory}/*.info | grep -F -v -- '-dbg.info'`"
    if [ "${infoFile}" != "" ]; then
	while read line
	do
	    if [ "${line#F:}" != "${line}" ]; then
		pushFiles "${line#F:}"
	    elif [ "${line#P:}" != "${line}" ]; then
		pushProvides "${line#P:}"
		popFoundRequires "${line#P:}"
	    elif [ "${line#R:}" != "${line}" ]; then
		pushRequires "${line#R:}"
	    fi
	done < "${infoFile}"
    fi
}
################################################################
#
# Main
#
# This is what was passed in as need to load this...
pushRequires "${package}"
#
# Loop satisfying Requires
#
while [ $iRequires -gt 0 ]
do
    popRequires
    if [ -f "${package_directory}/${returnValue}.info" ]; then
	getPackage "$returnValue"
    else
	foundIt="`grep -l -E "^P:${returnValue}\s*$" ${package_directory}/*.info | grep -F -v -- '-dbg.info'`"
	if [ "$foundIt" == "" ]; then
	    pushNotFound "$returnValue"
	else
	    getPackage "$returnValue"
	fi
    fi
done
#
# Write out what package files are needed to be loaded
#
rm -f "${package}.files"
for ((i=0; i<$iFiles; i++))
do
    echo "${Files[$i]}" >> "${package_directory}/${package}.files"
done
#
# Write out what wasn't found
#
rm -f "${package}.requires"
for ((i=0; i<$iNotFound; i++))
do
    echo "${NotFound[$i]}" >> "${package_directory}/${package}.requires"
done
