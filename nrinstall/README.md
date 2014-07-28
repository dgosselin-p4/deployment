#### Paradigm4's non-root installer for SciDB 14.7. ####

It is used to install SciDB Community or Enterprise Edition when you do not have root access to the SciDB hosts.

==================================================
##### Limitations #####

* It only supports CentOS 6 and RedHat 6, but not Ubuntu yet.
* Installing on multiple machines may not be possible for you, as it may require your IT department to perform some extra steps as root.
* If a banner or message is displayed on every shell invocation this script will erroneously report errors.
  Please email us the log and we will diagnose the problem and a provide a work around.

==================================================
##### Prerequisites #####

The following prerequisites must be met before you can successfuly run the non-root installer nrinstall:

* This installer must be run from the coordinator node.
* The coordinator node must have ssh connectivity to all the SciDB hosts (as listed in the configuration file).
* The coordinator node must have the following programs installed: ssh, bash, wget (or use pkg_downloader), and rpm2cpio.
* This same user account must be on all SciDB hosts, each account@host with the same home directory (that is absolute pathname not same disk).
* The same OS/version must be on all the SciDB hosts.

==================================================
##### Installation #####

1. Generate a SciDB configuration file. You may use https://github.com/Paradigm4/configurator to create the configuration file. When using the tool, make sure the value of 'SciDB install path' is a directory you have write access to, suffixed with '/opt/scidb/14.7'. For instance, if you have access to the directory /home/scidb, you may use /home/scidb/opt/scidb/14.7. 
2. Determine the CIDR of your network, in the form of W.X.Y.Z/N. For instance, if your IP address is 192.168.111.222, and your netmask is 255.255.255.0, your CIDR should be 192.168.111.0/24.
3. (Optional) If you have licensed the enterprise edition (consult http://paradigm4.com for more information), get your username and password ready.
4. cd nrinstall (Note: assume you were in the root directory of the deployment tool.)
5. (Optional) If your machine does not have wget installed, or it does not have internet access, use the "pkg_downloader" tool to download packages on another machine with wget and internet access, then copy over. See "./pkg_downloader -h" for details.
6. Install SciDB. See "./nrinstall -h" for details. By default it uses wget to download packages and then install. But it has an option to install from a local directory of already-downloaded packages. Note: to install the enterprise edition, you should provide the "-p USERNAME:PASSWORD" option here, unless you provided it to pkg_downloader.
7. (Optional) If you do not already have access to PostgreSQL on the coordinator machine, use setupPostgreSQL to create PostgreSQL. See "./setupPostgreSQL -h" for more details. The tool will prompt you to enter the CIDR address.
8. source ~/.bashrc
9. scidb.py init_syscat cluster   (Note: replace "cluster" with the cluster name you provided to the configurator, if you changed the default value.)
10. scidb.py initall cluster    (Note: this is to initialize the database.)
11. scidb.py startall cluster   (Note: this is to start the server.)
12. Do your work, e.g. to list SciDB instances: iquery list('instances')
13. scidb.py stopall cluster   (Note: this is to stop the server.)

