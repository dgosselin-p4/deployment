#### Paradigm4's cluster installer for SciDB 14.7. ####

It is used to install SciDB Community or Enterprise Edition on a cluster.

==================================================
##### Prerequisites #####

The following prerequisites must be met before you can successfuly run the installer cluster_install:

* This installer must be run as root from the coordinator node.
* The coordinator node must have ssh connectivity to all the SciDB hosts (as listed in the configuration file).
* This same user account must be on all SciDB hosts, each account@host with the same home directory (that is absolute pathname not same disk).
* The same OS/version must be on all the SciDB hosts.

==================================================
##### Installation #####

1. Generate a SciDB configuration file. You may use https://github.com/Paradigm4/configurator to create the configuration file.
2. Determine the CIDR of your network, in the form of W.X.Y.Z/N. For instance, if your IP address is 192.168.111.222, and your netmask is 255.255.255.0, your CIDR should be 192.168.111.0/24.
3. (Optional) If you have licensed the enterprise edition (consult http://paradigm4.com for more information), get your username and password ready.
4. sudo su    (Note: cluster_install must be run as root.)
5. cd cluster_install    (Note: assume you were in the root directory of this deployment tool.)
6. Install SciDB. See "./cluster_install -h" for details.
7. exit    (Note: assume now you are the 'scidb' user, or whichever username you provided to cluster_install through the '-u' option.)
8. source ~/.bashrc
9. scidb.py initall cluster    (Note: this is to initialize the database.)
10. scidb.py startall cluster   (Note: this is to start the server.)
11. Do your work, e.g. to list SciDB instances: iquery list('instances')
12. scidb.py stopall cluster   (Note: this is to stop the server.)
