#!/bin/bash
if [ $HOSTNAME != "elephant" ]; then
	echo "This script should only be run on elephant. It appears you are running this on " $HOSTNAME
	echo "Exiting..."
	sleep 5
	exit 0
fi
echo "verified the hostname is elephant. Continuing..."

#This SCRIPTS_DIR variable is used extensively throughout this script
SCRIPTS_DIR=/home/training/training_materials/admin/scripts

# Install CM agents to elephant tiger horse monkey lion
echo
echo "Installing CM Agent to all 5 machines in parallel."
echo
sudo yum install -y cloudera-manager-agent 2>&1 | sed -e 's/^/elephant output> /' &
ssh training@lion -o StrictHostKeyChecking=no sudo yum install -y cloudera-manager-agent 2>&1 | sed -e 's/^/lion output> /' &
ssh training@tiger -o StrictHostKeyChecking=no sudo yum install -y cloudera-manager-agent 2>&1 | sed -e 's/^/tiger output> /' &
ssh training@horse -o StrictHostKeyChecking=no sudo yum install -y cloudera-manager-agent 2>&1 | sed -e 's/^/horse output> /' &
ssh training@monkey -o StrictHostKeyChecking=no sudo yum install -y cloudera-manager-agent 2>&1 | sed -e 's/^/monkey output> /' &
wait

echo
echo "Configuring all 5 agents to find the CM server" 
echo
sudo sed -i 's,server_host=localhost,server_host=lion,' /etc/cloudera-scm-agent/config.ini
ssh training@lion -o StrictHostKeyChecking=no sudo sed -i 's,server_host=localhost,server_host=lion,' /etc/cloudera-scm-agent/config.ini
ssh training@tiger -o StrictHostKeyChecking=no sudo sed -i 's,server_host=localhost,server_host=lion,' /etc/cloudera-scm-agent/config.ini
ssh training@horse -o StrictHostKeyChecking=no sudo sed -i 's,server_host=localhost,server_host=lion,' /etc/cloudera-scm-agent/config.ini
ssh training@monkey -o StrictHostKeyChecking=no sudo sed -i 's,server_host=localhost,server_host=lion,' /etc/cloudera-scm-agent/config.ini

echo "Starting CM Agent on all 5 machines in parallel." 
sudo service cloudera-scm-agent start 2>&1 | sed -e 's/^/elephant output> /' &
ssh training@lion -o StrictHostKeyChecking=no sudo service cloudera-scm-agent start 2>&1 | sed -e 's/^/lion output> /' &
ssh training@tiger -o StrictHostKeyChecking=no sudo service cloudera-scm-agent start 2>&1 | sed -e 's/^/tiger output> /' &
ssh training@horse -o StrictHostKeyChecking=no sudo service cloudera-scm-agent start 2>&1 | sed -e 's/^/horse output> /' &
ssh training@monkey -o StrictHostKeyChecking=no sudo service cloudera-scm-agent start 2>&1 | sed -e 's/^/monkey output> /' &
wait

echo 
echo "Verify CM Server is started." 
echo
cmApiTest=""
while [[ $cmApiTest != "false" ]]
	do
	cmApiTest=$(ssh training@lion -o StrictHostKeyChecking=no curl -X GET -H "Content-Type:application/json" -u admin:admin 'http://lion:7180/api/v9/cm/version'|grep snapshot|cut -d " " -f5-|sed 's/[",]//g')
	sleep 10
done
echo 
echo "***************************"
echo ">>>Specifying we want the 60-day trial version of Cloudera Manager."
echo "***************************"
echo "Asking to start the trial..."
ssh training@lion -o StrictHostKeyChecking=no curl -X POST -H "Content-Type:application/json" -u admin:admin 'http://lion:7180/api/v9/cm/trial/begin'
sleep 10
echo "Asking to display the license..."
echo $(ssh training@lion -o StrictHostKeyChecking=no curl -X GET -v -H "Content-Type:application/json" -u admin:admin 'http://lion:7180/api/v9/cm/license')
sleep 5
echo "***************************"
echo "Restarting CM server"
echo $(date)
echo "***************************"
ssh training@lion -o StrictHostKeyChecking=no sudo service cloudera-scm-server restart

#don't move on until API is accessible.
echo 
echo "Waiting for CM Server to start. You may see curl errors until it does fully start. The couldn't connect to host messages are expected." 
echo
cmApiTest=""
while [[ $cmApiTest != "false" ]]
	do
	cmApiTest=$(ssh training@lion -o StrictHostKeyChecking=no curl -X GET -H "Content-Type:application/json" -u admin:admin 'http://lion:7180/api/v9/cm/version'|grep snapshot|cut -d " " -f5-|sed 's/[",]//g')
	sleep 10
done

echo "printing out the host ids and hostnames of the hosts that now have CM agent installed."
ssh training@lion -o StrictHostKeyChecking=no curl -X GET -H "Content-Type:application/json" -u admin:admin 'http://lion:7180/api/v9/hosts'|grep 'hostId\|hostname'

echo
echo "***************************"
echo "Done Installing CM Agents."
echo $(date)
echo "***************************"
