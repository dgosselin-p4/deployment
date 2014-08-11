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

1. Click 'download' (on the right) or directly download from https://github.com/Paradigm4/deployment/archive/14.7.zip
2. Generate a SciDB configuration file. You may use https://github.com/Paradigm4/configurator to create the configuration file.
3. Determine the CIDR of your network, in the form of W.X.Y.Z/N. For instance, if your IP address is 192.168.111.222, and your netmask is 255.255.255.0, your CIDR should be 192.168.111.0/24.
4. (Optional) If you have licensed the enterprise edition (consult http://paradigm4.com for more information), get your username and password ready.
5. Unzip the download of deployment to the coordinator node. Also put the generated configuration file on the coordinator.
6. sudo su    (Note: cluster_install must be run as root on the coordinator node.)
7. cd cluster_install
8. Install SciDB. See "./cluster_install -h" for details.
9. exit       (Note: from root. Assume now you are the 'scidb' user, or whichever username you provided to cluster_install through the '-u' option.)
10. source ~/.bashrc
11. scidb.py startall cluster   (Note: this is to start the server.)
12. Do your work, e.g. to list SciDB instances: iquery list('instances')
13. scidb.py stopall cluster   (Note: this is to stop the server.)

Note: If you wish to use a previous installed version of SciDB, you must edit the SCIDB_VER variable in your .bashrc file and then source it.

==================================================
#### The deployment project itself features 2 tools for installing SciDB. ####

<dl>
<dt>[Recommended] cluster_install</dt>
<dd>The standard way of installing SciDB to a cluster.</dd>
<dt>[Not recommended] nrinstall</dt>
<dd>Alternative way of installing SciDB, if you do not have root privilege on your machine.</dd>
<dl>
#### Installation ####

To download this project for a particular release:

1. Change 'branch:master' to 'tag:release'
  * where release is the SciDB release number, such as 14.7
2. Click 'download' or directly download from https://github.com/Paradigm4/deployment/archive/14.7.zip
3. Change to the directory of the tool your are interested in and look at the README file
