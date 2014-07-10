This is Paradigm4's non-root installer.

It is used to install SciDB Community or Enterprise Edition when you do not have root access to the SciDB hosts.
It can provide PostgreSQL if needed and it provides the SciDB shim.

Presently the non-root installer (named nrinstall) only supports CentOS 6 and RedHat 6 and SciDB version 14.3.

The non-root installer is driven from your SciDB configuration file.
There is a "configurator" in the Paradigm4 GitHub (https://github.com/Paradigm4/configurator)
to create your own SciDB configuration file.

You run nrinstall on the coordinator node as a regular user.

To get started you downloaded the deployment project from Paradigm4 on GitHub.
You change directory to "nrinstall" and run "./nrinstall" for help.

Additionally if you do not have internet access from your cluster
there is a script "pkg_downloader" that can be run on a machine with internet access
to download all the packages needed by nrinstall.
Seek "pkg_downloader -h" for details.

==================================================
The order of events should be something like this:

    cd nrinstall
    ./nrinstall -h
    . ~/.bashrc
    ~/setupPostgreSQL (but ONLY if you need to run your own postgresql and ONLY the first time)
    scidb.py init_syscat [db] (notice scidb.py is now in your PATH)
    scidb.py initall [db]
    scidb.py startall [db]
    Do your work
    scidb.py stopall [db]

==================================================
Prerequisites

The following prerequisites must be met before you can successfuly run the non-root installer nrinstall:

* The coordinator node must have ssh connectivity to all the SciDB hosts (as listed in the configuration file).
* The coordinator node must have the following programs installed: ssh, bash, wget (or use pkg_downloader), and rpm2cpio.
* This same user account must be on all SciDB hosts, each account@host with the same home directory (that is absolute pathname not same disk).
* The same OS/version must be on all the SciDB hosts.

* You should have a SciDB configuration file to "drive" nrinstall. There is a "configurator" in the Paradigm4 GitHub (https://github.com/Paradigm4/configurator) to create your own SciDB configuration file.

* The setupPostgreSQL script will ask you for the CIDR of your cluster network. This is of the form IPaddress/routing_prefix (W.X.Y.Z/N).
