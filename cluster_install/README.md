This is Paradigm4's cluster installer.

This shell script along with supporting scripts installs and sets up a SciDB cluster from the coordinator node.
It is driven from your SciDB configuration file.
There is a "configurator" in the Paradigm4 GitHub (https://github.com/Paradigm4/configurator)
to create your own SciDB configuration file.

The cluster_install script must be run as root (a login shell such as "su -l root").

Before installing, this script will qualify your cluster.
This includes setting up password-less ssh keys and turning off firewalls.
See the ../qualify directory for more details.

./cluster_install [-s|-p <credentials>] [-u <username>] <network> <config_file>
  -s         - install SciDB
  -p <credentials>
             - install P4
               <credentials> is a file with one line of the credentials (<username>:<password>) to access the P4 downloads.
  -s -p <credentials>
             - install both SciDB and P4
  -u <username>
             - non-root user that will run SciDB
             - defaults to user "scidb"
  <network>
             - is the network mask the cluster is on
  	       Note: in the format of W.X.Y.Z/D
  <config_file>
             - SciDB configuration file

================
DISCLAIMER

This tool is provided as is with no support.
Use at your own risk.

================
PREREQUISITES

Supported OSes are CentOS 6, RedHat 6, and Ubuntu 12.04.

This script must be run as root.

The user account <username> (default is "scidb") must be present on all nodes with the same password and home directory.
You must know the password for "root" and <username> on all nodes.

SSH must be installed and running on all nodes.
Particularly for SELinux, passphraseless ssh keys must be allowed.

================
SETUP

This script will modify the .bashrc file on all nodes.
If you have already logged in on the coordinator, you will need to source the .bashrc file to setup environment variables for this new installation.
Next time you login you will get these settings as a result of logging in.

================
SECURITY

These are the known security issues that cluster_install (and indirectly qualify) creates.

* Passwordless ssh as user "root" is setup between the coordinator and all the nodes in the cluster.

* Passwordless ssh as user <username> (default is "scidb") is setup between the coordinator host and all the nodes in the cluster.

* ssh is run with StrictHostKeyChecking=no.

* All firewalls on all nodes are disabled permanently.

* User <username>'s (default is "scidb") .bashrc file is modified.

If any of the above is unacceptable do not use cluster_install
