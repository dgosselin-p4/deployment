This is Paradigm4's qualifier.

The qualify shell script along with supporting scripts will qualify your cluster.
It is driven from your SciDB configuration file.
There is a "configurator" in the Paradigm4 GitHub (https://github.com/Paradigm4/configurator)
to create your own SciDB configuration file.

If this script is run as root on the installer (a login shell such as "su -l root")
it will attempt to fix any issues with your cluster that could prevent SciDB from working.

./qualify [-u <username>] <config_file>
  -u <username>
                - non-root user that will run SciDB
                - defaults to user "scidb"
  <config_file> - The SciDB configuration file SciDB will be running with

================
DISCLAIMER

This tool is provided as is with no support.
Use at your own risk.
================
Read the SECURITY file to see what security issues this script will cause.
================
PREREQUISITES

Supported OSes are CentOS 6, RedHat 6, and Ubuntu 12.04.

The user account <username> (default is "scidb") must be present on all nodes with the same password and home directory.
You must know the password for "root" (if running as root) and for <username> on all nodes.