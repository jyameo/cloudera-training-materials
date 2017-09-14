#!/bin/bash

# ------------------------------[ Documentation ]----------------------------------------
#
# This script performs the installation of Cloudera Manager by replicating the commands
# exactly as if they had been typed by the student during the lab. It assumes that symbolic
# hostnames are already established and that there is IP addressability and passwordless SSH
# across the private interfaces of the nodes.
#
# The commands for CM installation are all run from the Lion server.
#
# (1) Reset the user's MySQL password to NULL, in case it has already been set to "training"
# (2) Call the mysql-setup.sql script (just as they do in the lab) to establish default databases for CDH and CM
# (3) Runs the ./01secureSQL.exp, which is an expect script that spoofs the user to the mysql secure script
#        The expect script calls 01secureSQL.sh which calls the mysql_secure_installation script
#        The expect script then responds to the expected questions so that the MySQL system is secured.
#        It responds exactly as a user would to the mysql_secure_installation
#
# (4) Check for existence of cloudera manager daemons and servers, and remove if present, then install
# (5) Cause CM Sever NOT to autostart on a reboot
# (6) Call the scm_prepare_database.sh script.  This has no required input, so it does not need an expect script.
#     This prepares the basic databases that will be needed by CM.
# (7) Start Cloudera Manager
#
# [TAS-9.14.2016]
#

if [ $HOSTNAME != "lion" ]; then
	echo "This script should only be run on lion. It appears you are running this on " $HOSTNAME
	echo "Exiting..."
	sleep 5
	exit 0
fi
echo "verified the hostname is lion. Continuing..."

MYHOST="`hostname`: "
echo
echo $MYHOST "Running " $0"."
echo
echo
echo "This scripts the steps in the Installing Cloudera Manager Server Hands-On Exercise."
echo "IMPORTANT: This script assumes the networking exercise was already completed."
echo "=================================================================================="

#This SCRIPTS_DIR variable is used extensively throughout this script
SCRIPTS_DIR=/home/training/training_materials/admin/scripts

echo 
echo ">>>Reset MySQL root user's password to empty in case it was already changed"
mysqladmin -u root -p'training' password ''
echo ">>>if error access denied was returned, ignore it"
echo 
#Before running this, there should be 5 databases. Afterwards there should be 8.

echo 
echo ">>>Creating (or dropping and creating) databases for CDH and CM"
echo
mysql -u root < $SCRIPTS_DIR/mysql-setup.sql

echo 
echo ">>>Securing MySQL"
echo
# the .exp calls a .sh which runs the mysql_secure_installation wizard
cd $SCRIPTS_DIR/catchup
./01secureSQL.exp
# add a sleep so that we are sure to see the "all done" message
sleep 10

echo
echo "*********************************************"
echo ">>>Installing CM Daemons and CM Server on lion" 
echo "*********************************************"

#check for cm daemons and install if not found
if [[ -n $(rpm -qa | grep cloudera-manager-daemons) ]]; then
	echo "cloudera-manager-daemons already installed. Uninstalling and reinstalling"
	sudo yum remove -y cloudera-manager-daemons
	sudo yum install -y cloudera-manager-daemons
else
    echo "cloudera-manager-daemons not found. Installing now."
	sudo yum install -y cloudera-manager-daemons
fi

#check for cm server and install if not found
if [[ -n $(rpm -qa | grep cloudera-manager-server) ]]; then
	echo "cloudera-manager-server already installed. Uninstalling and reinstalling."
	sudo yum remove -y cloudera-manager-server
	sudo yum install -y cloudera-manager-server
else
    echo "cloudera-manager-server not found. Installing now."
	sudo yum install -y cloudera-manager-server
fi 
echo
echo 
echo "*********************************************"
echo ">>>Setting CM server service to off"
echo "*********************************************"
sudo chkconfig cloudera-scm-server off
echo
echo "*********************************************"
echo ">>>Preparing the CM database"
echo "*********************************************"
echo
cd $SCRIPTS_DIR/catchup
./setCmserveruserPwd.exp
sudo /usr/share/cmf/schema/scm_prepare_database.sh mysql cmserver cmserveruser password
echo 
echo "done."
sleep 2
echo 
echo "*********************************************"
echo ">>>Starting CM server"
echo "*********************************************"
sudo service cloudera-scm-server start
sleep 5



