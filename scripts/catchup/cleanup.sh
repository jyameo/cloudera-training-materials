#!/bin/bash

# -------------------------[ Documentation ]------------------------------
#
# (1) Check that the script is running on Elephant, if not exit.  
#    The cleanup script depends on named nodes and that it is homed on Elephant
#    
# (2) Echo's the hostname where the script is running
#
# (3) Kill all scm agents and servers on all nodes
#    killAllProcessesOnAllNodes = Kills all scm agents and server process on all nodes
#
# (4) Uninstall yum RPMS beginning with "cloudera*" on all nodes
#    uninstallRPMsOnAllNodes =  calls next and uninstalls all RPMS on all nodes
#        uninstallRPMsOnOneNode = Uninstalls yum RPMS named cloudera*
#   
# (5) Unmount the temporary file system used by cm_process on all nodes
#    unmountTmpfs = Unmounts cm_processes temporary file system on all nodes
#
# (6) Deletes a long list of common generated files on all nodes
#    deleteFilesOnAllNodes =  calls next and delets files on all nodes
#       deleteFilesOnOneNode =  deletes common files on one node
#   
# (7) Deletes the databases and users from MySQL on node Lion
#     deleteDBsAndUsers = Deletes the four MySQL database on Lion
# 
# (8) Echo's the hostname where the script is running, and exits
#
# [TAS-9.14.2016]

echo "Running script on " $(date)
if [ $HOSTNAME != "elephant" ]; then
    echo "This script should only be run on elephant. It appears you are running this on " $HOSTNAME
    echo "Exiting..."
    sleep 5
    exit 0
fi

killAllProcessesOnAllNodes() {
	echo
	echo "Killing all agent processes across all 5 machines in parallel. Give it some time."
	echo "Some 'unrecognized service' messages are to be expected."
	echo
	sudo service cloudera-scm-agent hard_stop_confirmed 2>&1 | sed -e 's/^/elephant output> /' &
	ssh training@lion -o StrictHostKeyChecking=no sudo service cloudera-scm-agent hard_stop_confirmed 2>&1 | sed -e 's/^/lion output> /' &
	ssh training@tiger -o StrictHostKeyChecking=no sudo service cloudera-scm-agent hard_stop_confirmed 2>&1 | sed -e 's/^/tiger output> /' &
	ssh training@horse -o StrictHostKeyChecking=no sudo service cloudera-scm-agent hard_stop_confirmed 2>&1 | sed -e 's/^/horse output> /' &
	ssh training@monkey -o StrictHostKeyChecking=no sudo service cloudera-scm-agent hard_stop_confirmed 2>&1 | sed -e 's/^/monkey output> /' &
	wait
	 
	echo
	echo "Killing CM server - try across all 5 machines in case it was installed on the wrong machine."
	echo "Some 'unrecognized service' messages are to be expected."
	echo
	sudo service cloudera-scm-server stop 2>&1 | sed -e 's/^/elephant output> /' &
	ssh training@lion -o StrictHostKeyChecking=no sudo service cloudera-scm-server stop 2>&1 | sed -e 's/^/lion output> /' &
	ssh training@tiger -o StrictHostKeyChecking=no sudo service cloudera-scm-server stop 2>&1 | sed -e 's/^/tiger output> /' &
	ssh training@horse -o StrictHostKeyChecking=no sudo service cloudera-scm-server stop 2>&1 | sed -e 's/^/horse output> /' &
	ssh training@monkey -o StrictHostKeyChecking=no sudo service cloudera-scm-server stop 2>&1 | sed -e 's/^/monkey output> /' &
	
	sudo service cloudera-scm-server-db stop 2>&1 | sed -e 's/^/elephant output> /' &
	ssh training@lion -o StrictHostKeyChecking=no sudo service cloudera-scm-server-db stop 2>&1 | sed -e 's/^/lion output> /' &
	ssh training@tiger -o StrictHostKeyChecking=no sudo service cloudera-scm-server-db stop 2>&1 | sed -e 's/^/tiger output> /' &
	ssh training@horse -o StrictHostKeyChecking=no sudo service cloudera-scm-server-db stop 2>&1 | sed -e 's/^/horse output> /' &
	ssh training@monkey -o StrictHostKeyChecking=no sudo service cloudera-scm-server-db stop 2>&1 | sed -e 's/^/monkey output> /' &
	wait
}
	
unmountTmpfs() {
    echo
	echo "Unmounting cm_processes on elephant"
    sudo umount cm_processes
    echo "Unmounting cm_processes on tiger"
    ssh training@tiger -o StrictHostKeyChecking=no sudo umount cm_processes
    echo "Unmounting cm_processes on horse"
    ssh training@horse -o StrictHostKeyChecking=no sudo umount cm_processes
    echo "Unmounting cm_processes on monkey"
    ssh training@monkey -o StrictHostKeyChecking=no sudo umount cm_processes
    echo "Unmounting cm_processes on lion"
    ssh training@lion -o StrictHostKeyChecking=no sudo umount cm_processes
    # if umount fails, sudo lsof | grep /var/run/cloudera will show what process is locking it up.
}

uninstallRPMsOnOneNode() {
  $1 sudo yum remove --assumeyes cloudera*
  $1 sudo yum clean all
}

uninstallRPMsOnAllNodes() {
  echo 
  echo ">>>Uninstalling all Hadoop and ecosystem RPMs on elephant."
  echo 
  uninstallRPMsOnOneNode "" 

  echo 
  echo ">>>Uninstalling all Hadoop and ecosystem RPMs on tiger."
  echo 
  uninstallRPMsOnOneNode "ssh training@tiger -o StrictHostKeyChecking=no"

  echo 
  echo ">>>Uninstalling all Hadoop and ecosystem RPMs on horse."
  echo 
  uninstallRPMsOnOneNode "ssh training@horse -o StrictHostKeyChecking=no"

  echo 
  echo ">>>Uninstalling all Hadoop and ecosystem RPMs on monkey."
  echo 
  uninstallRPMsOnOneNode "ssh training@monkey -o StrictHostKeyChecking=no"

  echo 
  echo ">>>Uninstalling all Hadoop and ecosystem RPMs on lion."
  echo 
  uninstallRPMsOnOneNode "ssh training@lion -o StrictHostKeyChecking=no"
}

deleteFilesOnOneNode() {
  $1 sudo rm -rf /disk1
  $1 sudo rm -rf /disk2
  $1 sudo rm -rf /dfs
  $1 sudo rm -rf /mapred
  $1 sudo rm -rf /etc/cloudera*
  $1 sudo rm -rf /etc/default/impala
  $1 sudo rm -rf /etc/flume-ng
  $1 sudo rm -rf /etc/hadoop
  $1 sudo rm -rf /etc/hbase*
  $1 sudo rm -rf /etc/hive*
  $1 sudo rm -rf /etc/hue
  $1 sudo rm -rf /etc/impala
  $1 sudo rm -rf /etc/llama
  $1 sudo rm -rf /etc/oozie
  $1 sudo rm -rf /etc/pig
  $1 sudo rm -rf /etc/solr
  $1 sudo rm -rf /etc/spark
  $1 sudo rm -rf /etc/sqoop*
  $1 sudo rm -rf /etc/zookeeper
  $1 sudo rm -rf /etc/alternatives/flume*
  $1 sudo rm -rf /etc/alternatives/hadoop*
  $1 sudo rm -rf /etc/alternatives/hbase*
  $1 sudo rm -rf /etc/alternatives/hive*
  $1 sudo rm -rf /etc/alternatives/hue*
  $1 sudo rm -rf /etc/alternatives/impala*
  $1 sudo rm -rf /etc/alternatives/llama*
  $1 sudo rm -rf /etc/alternatives/oozie*
  $1 sudo rm -rf /etc/alternatives/pig*
  $1 sudo rm -rf /etc/alternatives/solr*
  $1 sudo rm -rf /etc/alternatives/spark*
  $1 sudo rm -rf /etc/alternatives/sqoop*
  $1 sudo rm -rf /etc/alternatives/zookeeper*
  $1 sudo rm -rf /home/training/backup_config
  $1 sudo rm -rf /opt/cloudera/parcels/*
  $1 sudo rm -rf /opt/cloudera/parcel-cache/*
  $1 sudo rm -rf /tmp/*scm*
  $1 sudo rm -rf /tmp/.*scm*
  $1 sudo rm -rf /tmp/hadoop*
  $1 sudo rm -rf /var/cache/yum/cloudera*
  $1 sudo rm -rf /usr/lib/hadoop*
  $1 sudo rm -rf /usr/lib/hive*
  $1 sudo rm -rf /usr/lib/hue
  $1 sudo rm -rf /usr/lib/oozie
  $1 sudo rm -rf /usr/lib/parquet
  $1 sudo rm -rf /usr/lib/spark
  $1 sudo rm -rf /usr/lib/sqoop
  $1 sudo rm -rf /usr/share/cmf
  $1 sudo rm -rf /usr/share/hue
  $1 sudo rm -rf /var/lib/cloudera*
  $1 sudo rm -rf /var/lib/flume-ng
  $1 sudo rm -rf /var/lib/hadoop*
  $1 sudo rm -rf /var/lib/hdfs
  $1 sudo rm -rf /var/lib/hive*
  $1 sudo rm -rf /var/lib/hue
  $1 sudo rm -rf /var/lib/impala
  $1 sudo rm -rf /var/lib/oozie
  $1 sudo rm -rf /var/lib/sqoop*
  $1 sudo rm -rf /var/lib/spark
  $1 sudo rm -rf /var/lib/solr
  $1 sudo rm -rf /var/lib/zookeeper
  $1 sudo rm -rf /var/lib/alternatives/flume*
  $1 sudo rm -rf /var/lib/alternatives/hadoop*
  $1 sudo rm -rf /var/lib/alternatives/hbase*
  $1 sudo rm -rf /var/lib/alternatives/hive*
  $1 sudo rm -rf /var/lib/alternatives/hue*
  $1 sudo rm -rf /var/lib/alternatives/impala*
  $1 sudo rm -rf /var/lib/alternatives/llama*
  $1 sudo rm -rf /var/lib/alternatives/oozie*
  $1 sudo rm -rf /var/lib/alternatives/pig*
  $1 sudo rm -rf /var/lib/alternatives/solr*
  $1 sudo rm -rf /var/lib/alternatives/spark*
  $1 sudo rm -rf /var/lib/alternatives/sqoop*
  $1 sudo rm -rf /var/lib/alternatives/zookeeper*
  $1 sudo rm -rf /var/lock/subsys/cloudera*
  $1 sudo rm -rf /var/lock/subsys/flume-ng*
  $1 sudo rm -rf /var/lock/subsys/hadoop*
  $1 sudo rm -rf /var/lock/subsys/hbase*
  $1 sudo rm -rf /var/lock/subsys/hdfs*
  $1 sudo rm -rf /var/lock/subsys/hive*
  $1 sudo rm -rf /var/lock/subsys/hue*
  $1 sudo rm -rf /var/lock/subsys/impala*
  $1 sudo rm -rf /var/lock/subsys/llama*
  $1 sudo rm -rf /var/lock/subsys/oozie*
  $1 sudo rm -rf /var/lock/subsys/solr*
  $1 sudo rm -rf /var/lock/subsys/spark*
  $1 sudo rm -rf /var/lock/subsys/sqoop*
  $1 sudo rm -rf /var/lock/subsys/zookeeper*
  $1 sudo rm -rf /var/log/cloudera*
  $1 sudo rm -rf /var/log/flume-ng
  $1 sudo rm -rf /var/log/hadoop*
  $1 sudo rm -rf /var/log/hbase*
  $1 sudo rm -rf /var/log/hive*
  $1 sudo rm -rf /var/log/hue
  $1 sudo rm -rf /var/log/impala*
  $1 sudo rm -rf /var/log/llama
  $1 sudo rm -rf /var/log/oozie
  $1 sudo rm -rf /var/log/solr
  $1 sudo rm -rf /var/log/sqoop2
  $1 sudo rm -rf /var/log/spark
  $1 sudo rm -rf /var/log/zookeeper
  $1 sudo rm -rf /var/run/cloudera*
  $1 sudo rm -rf /var/run/flume-ng
  $1 sudo rm -rf /var/run/hadoop*
  $1 sudo rm -rf /var/run/hbase*
  $1 sudo rm -rf /var/run/hdfs*
  $1 sudo rm -rf /var/run/hive
  $1 sudo rm -rf /var/run/impala
  $1 sudo rm -rf /var/run/llama
  $1 sudo rm -rf /var/run/oozie
  $1 sudo rm -rf /var/run/solr
  $1 sudo rm -rf /var/run/spark
  $1 sudo rm -rf /var/run/sqoop2
  $1 sudo rm -rf /var/run/zookeeper
  $1 sudo rm -rf /yarn
}

deleteFilesOnAllNodes() {
  echo 
  echo "Deleting files on elephant."
  echo 
  deleteFilesOnOneNode "" 

  echo 
  echo "Deleting files on tiger."
  echo 
  deleteFilesOnOneNode "ssh training@tiger -o StrictHostKeyChecking=no"

  echo 
  echo "Deleting files on horse."
  echo 
  deleteFilesOnOneNode "ssh training@horse -o StrictHostKeyChecking=no"

  echo 
  echo "Deleting files on monkey."
  echo 
  deleteFilesOnOneNode "ssh training@monkey -o StrictHostKeyChecking=no"

  echo 
  echo "Deleting files on lion."
  echo 
  deleteFilesOnOneNode "ssh training@lion -o StrictHostKeyChecking=no"
}

deleteDBsAndUsers() {
  echo
  echo "Deleting the four databases and users from MySQL on lion."
  echo
  echo "This script will make a few attempts to delete the tables and users in the database."
  echo "Give it time and let it run without assistance, ignoring initial errors."
  echo "You should eventually see Query OK messages."
  echo ""

  #One of these three scripts will work depending on the current mysql root password
  ssh training@lion /home/training/training_materials/admin/scripts/catchup/setMysqlPwd.sh
  ssh training@lion /home/training/training_materials/admin/scripts/catchup/setMysqlPwd2.exp
  ssh training@lion /home/training/training_materials/admin/scripts/catchup/setMysqlPwd3.exp

  #Drop users and tables
  ssh training@lion /home/training/training_materials/admin/scripts/catchup/dropDBsAndUsers.exp 
  sleep 5
}

setOwnership() {
  ssh training@lion sudo chown training:training /opt/cloudera/parcel-repo/CDH-5.9.0-1.cdh5.9.0.p0.23
  ssh training@lion sudo chmod 644 /opt/cloudera/parcel-repo/CDH-5.9.0-1.cdh5.9.0.p0.23
}


MYHOST="`hostname`: "
echo
echo $MYHOST "Running " $0"."
echo

killAllProcessesOnAllNodes $1
uninstallRPMsOnAllNodes $1
unmountTmpfs $1
deleteFilesOnAllNodes $1
deleteDBsAndUsers $1
#setOwnership

echo
echo $MYHOST $0 "done."
echo