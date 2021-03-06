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
# This script will modify opt/scidb/<version>/bin/scidb.py
# to work in the user's local install tree.
#
sed -i \
-e 's/\"\/opt\/scidb/scidb_root+\"\/opt\/scidb/g' \
-e 's/:\/opt\/scidb/:\"+scidb_root+\"\/opt\/scidb/g' \
-e '/Defaults/ i\
scidb_root = os.environ.get("SCIDB_ROOT", "")' \
opt/scidb/${1}/bin/scidb.py
