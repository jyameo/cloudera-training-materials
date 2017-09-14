#!/bin/bash
echo "Running "$0 "on "$(date)
echo
if [ $HOSTNAME != "elephant" ]; then
	echo "This script should only be run on elephant. It appears you are running this on " $HOSTNAME
	echo "Exiting..."
	sleep 5
	exit 0
fi
echo "Verified hostname is "$HOSTNAME". Continuing..."

getStartState() {
  validResponse=0
  while [ $validResponse -eq 0 ] 
  do 
    echo ""
    echo "This script assumes you have completed the Configuring Networking setup activity."
    echo ""
    echo "Please enter the number of the exercise that you want to do after this script runs."
    echo "This script will reset your cluster to the start state for that exercise."
    echo ""
    echo " 1 Installing Cloudera Manager Server"
    echo " 2 (Installing CM Agents and) Creating a Hadoop Cluster"
    echo " 3 Working With HDFS" 
    echo " 4 Running YARN Applications" 
    echo " 5 Explore Hadoop Configurations and Daemon Logs" 
    echo " 6 Using Flume to Put Data into HDFS" 
    echo " 7 Importing Data With Sqoop"
    echo " 8 Querying HDFS With Hive and Cloudera Impala"
    echo " 9 Using Hue to Control Hadoop User Access"
    echo "10 Configuring HDFS High Availability"
    echo "11 Using the Fair Scheduler"
    echo "12 Breaking The Cluster"
    echo "13 Verifying The Cluster’s Self-Healing Features"
    echo "14 Taking HDFS Snapshots"
    echo "15 Configuring Email Alerts"
    echo "16 Troubleshooting Challenge: Heap O' Trouble"
    echo "17 (Complete all exercises)"
    read exercise
    if [[ $exercise -ge 1 && $exercise -le 17 ]]; then
      validResponse=1
    else 
      echo ""
      echo "Invalid response. Please re-enter a valid exercise number." 
      echo ""
    fi
  done  
} 

getConfirmation(){
  validResponse=""
  ###OUTER WHILE
  while [ "$validResponse" == "" ] 
  do 
    echo ""
    echo "You are about to catchup your cluster so that you can perform Exercise "$exercise" manually."
    echo "Do you want to proceed? (y/n)"
    read answer

	#YES PROCEED
    if [[ $answer == "Y" || $answer == "y" ]]; then
      		######ONLY OPTION START#########
      		onlyOption=""
      		while [[ "$onlyOption" == "" ]]
      		do	
      			prevEx="$(($exercise - 1))"
      			echo
      			echo "OPTIONS AVAILABLE:"
      			echo " --- To have this script ONLY automate the previous exercise (Exercise "$prevEx"), enter '1'."
      			echo 
      			echo " --- To completely rebuild your cluster, including a full uninstall/reinstall/catchup, enter 'ALL'."
      			echo
      			read secondAnswer
      			#ONLY LAST EXERCISE
      			if [[ $secondAnswer == "1" ]]; then   				
      				oneOnly=""
      				while [ "$oneOnly" == "" ]
      				do
      					echo "Ok, we will only run the scripts that automate exercise "$prevEx". OK to proceed? (y/n)"
      					read newAnswer
      					if [[ $newAnswer == "Y" || $newAnswer == "y" ]]; then
      						#exits the inner
      						oneOnly="yes"
      						onlyOption="responded"
      						validResponse="yes"
      					elif [[ $newAnswer == "N" || $newAnswer == "n" ]]; then
      						oneOnly="no"
      					else
      						echo "Invalid response."
      					fi
      				done
      			#FULL WIPE	
      			elif [[ $secondAnswer == "ALL" || $secondAnswer == "all" ]]; then
      				goAhead=""
      				while [ "$goAhead" == "" ]
      				do
						echo 
						echo "Ok, we will completely uninstall and then reinstall your cluster, then "
						echo "catch you up so you can manually complete Exercise" $exercise "afterwards."
						echo "OK to proceed? (y/n)"
						echo
						read newAnswer
						if [[ $newAnswer == "Y" || $newAnswer == "y" ]]; then
							#exits the inner
							oneOnly="no"
							onlyOption="responded"
							goAhead="yes"
						elif [[ $newAnswer == "N" || $newAnswer == "n" ]]; then
							exit
						else
							echo "Invalid response."
							exit
						fi
					done
      				validResponse="yes"
      			else
      			  echo ""
				  echo "Invalid response." 
				  echo ""
      			fi	
      		done	
			######ONLY OPTION START#########
	###NO, DON'T PROCEED
	elif [[ $answer == "N" || $answer == "n" ]]; then
		exit	
    else 
      echo ""
      echo "Invalid response." 
      echo ""
    fi
  done  
  #confirming the options chosen by the user
  echo "exercise chosen: " $exercise
  echo "oneOnly value: " $oneOnly
  echo "validResponse value: " $validResponse
  ####END OUTER WHILE
}

cleanup(){
    if [[ $exercise -eq 1 ]]; then
    	echo ""
   		echo "Stopping all Hadoop processes, removing Hadoop software, removing files, and resetting other changes to your system."
   	    echo ""
   		$CATCHUP_DIR"cleanup.sh"
   	elif [[ $exercise -ge 2 ]] && [[ "$oneOnly" == "no" ]]; then
    	echo ""
   		echo "Stopping all Hadoop processes, removing Hadoop software, removing files, and resetting other changes to your system."
   	    echo ""
   		$CATCHUP_DIR"cleanup.sh"
   	else
   		echo "Skipping cleanup step."
   	fi
   	echo $(date)
}

doExercise1(){
  if [[ $exercise -gt 1 ]] && [[ "$oneOnly" == "no" ]]; then
    echo "Ensuring Skytap does not auto-suspend while this script runs"
	curl -G http://gw/skytap?reset_autosuspend=1 &> /dev/null
	echo ""
    echo "Simulating Exercise 1."
    echo "Installs CM Server and prepares MySQL."
    ssh training@lion -o StrictHostKeyChecking=no ~/training_materials/admin/scripts/catchup/installCMServer.sh
  elif [[ $exercise -eq 2 ]] && [[ "$oneOnly" == "yes" ]]; then
    echo ""
    echo "Simulating Exercise 1."
    echo "Installs CM Server and prepares MySQL."
    ssh training@lion -o StrictHostKeyChecking=no ~/training_materials/admin/scripts/catchup/installCMServer.sh
  else
  	echo "Skipping Exercise 1 catchup."
  fi
  echo $(date)
}

doExercise2(){
  if [[ $exercise -gt 2 ]] && [[ "$oneOnly" == "no" ]]; then
    #if they choose 3 up to 17 and want to redo everything... then this step is called after CM server is installed and installs CM agents
	echo "Ensuring Skytap does not auto-suspend while this script runs"
	curl -G http://gw/skytap?reset_autosuspend=1 &> /dev/null
    echo ""
    echo "Simulating Exercise 2."
    echo "Installs CM Agents and chooses the Trial Edition of CM Server. Then creates basic cluster with HDFS and YARN."		
    $CATCHUP_DIR"installAgents.sh"
    cd $CATCHUP_DIR
    #./catchup.sh cmDeployment catchup/deployment1.json backup1.json
    ./catchup.sh cmDeployment deployment1.json backup1.json

  elif [[ $exercise -eq 3 ]] && [[ "$oneOnly" == "yes" ]]; then
    #if they choose 3 and only want to do the previous exercise, do the same thing
    echo ""
    echo "Simulating Exercise 2."
    echo "Installs CM Agents and chooses the Trial Edition of CM Server. Then creates basic cluster with HDFS and YARN."

    $CATCHUP_DIR"installAgents.sh"
    cd $CATCHUP_DIR
    ./catchup.sh cmDeployment deployment1.json backup1.json
  else
  	echo "Skipping Exercise 2 catchup."
  fi 
  echo $(date)
}

doExercise3(){
  if [[ $exercise -gt 3 ]] && [[ "$oneOnly" == "no" ]]; then  
		echo "Ensuring Skytap does not auto-suspend while this script runs"
		curl -G http://gw/skytap?reset_autosuspend=1 &> /dev/null
		echo ""
		echo "Simulating Exercise 3."
		echo "Creates /user/training dir and uploads weblog to hdfs."
		echo ""
		cd $CATCHUP_DIR
		./catchup.sh exercise-hdfs
  elif [[ $exercise -eq 4 ]] && [[ "$oneOnly" == "yes" ]]; then  
		echo ""
		echo "Simulating Exercise 3."
		echo "Creates /user/training dir and uploads weblog to hdfs."
		echo ""
		cd $CATCHUP_DIR
		./catchup.sh exercise-hdfs
  else
  	echo "Skipping Exercise 3 catchup."
  fi
  echo $(date)
}

doExercise4(){
  if [[ $exercise -gt 4 ]] && [[ "$oneOnly" == "no" ]]; then
		echo "Ensuring Skytap does not auto-suspend while this script runs"
		curl -G http://gw/skytap?reset_autosuspend=1 &> /dev/null
		echo ""
		echo "Simulating Exercise 4."
		echo "Starting spark and running an MR job and a Spark app."
		echo ""
		cd $CATCHUP_DIR
		./catchup.sh spark
  elif [[ $exercise -eq 5 ]] && [[ "$oneOnly" == "yes" ]]; then
		echo ""
		echo "Simulating Exercise 4."
		echo "Starting spark and running some MR jobs and Spark apps."
		echo ""
		cd $CATCHUP_DIR
		./catchup.sh spark
  else
  	echo "Skipping Exercise 4 catchup."
  fi
  echo $(date)
}

doExercise5(){
  if [[ $exercise -gt 5 ]] && [[ "$oneOnly" == "no" ]]; then
		echo "Ensuring Skytap does not auto-suspend while this script runs"
		curl -G http://gw/skytap?reset_autosuspend=1 &> /dev/null
		echo ""
		echo "Nothing done specifically in exercise 5 to the cluster."
		echo ""
  elif [[ $exercise -eq 6 ]] && [[ "$oneOnly" == "yes" ]]; then
		echo ""
		echo "Nothing done specifically in exercise 5 to the cluster."
		echo ""
  else
  	echo "Skipping Exercise 5 catchup."
  fi
  echo $(date)
}

doExercise6(){
  if [[ $exercise -gt 6 ]] && [[ "$oneOnly" == "no" ]]; then
		echo "Ensuring Skytap does not auto-suspend while this script runs"
		curl -G http://gw/skytap?reset_autosuspend=1 &> /dev/null
		echo ""
		echo "Simulating Exercise 6 (Flume exercise)."
		echo ""
		cd $CATCHUP_DIR
		./catchup.sh flume
  elif [[ $exercise -eq 7 ]] && [[ "$oneOnly" == "yes" ]]; then
		echo ""
		echo "Simulating Exercise 6 (Flume exercise)."
		echo ""
		cd $CATCHUP_DIR
		./catchup.sh flume
  else
  	echo "Skipping Exercise 6 catchup."
  fi
  echo $(date)
}

doExercise7(){
  if [[ $exercise -gt 7 ]] && [[ "$oneOnly" == "no" ]]; then
		echo "Ensuring Skytap does not auto-suspend while this script runs"
		curl -G http://gw/skytap?reset_autosuspend=1 &> /dev/null
		echo ""
		echo "Simulating Exercise 7 (Sqoop exercise)."
		echo ""
		cd $CATCHUP_DIR
		./catchup.sh sqoop
  elif [[ $exercise -eq 8 ]] && [[ "$oneOnly" == "yes" ]]; then
		echo ""
		echo "Simulating Exercise 7 (Sqoop exercise)."
		echo ""
		cd $CATCHUP_DIR
		./catchup.sh sqoop
  else
  	echo "Skipping Exercise 7 catchup."
  fi
  echo $(date)
}

doExercise8(){
  if [[ $exercise -gt 8 ]] && [[ "$oneOnly" == "no" ]]; then
		echo "Ensuring Skytap does not auto-suspend while this script runs"
		curl -G http://gw/skytap?reset_autosuspend=1 &> /dev/null	
		echo ""
		echo "Simulating Exercise 8."
		echo ""
		cd $CATCHUP_DIR
		./catchup.sh hive-impala
  elif [[ $exercise -eq 9 ]] && [[ "$oneOnly" == "yes" ]]; then
		echo ""
		echo "Simulating Exercise 8."
		echo ""
		cd $CATCHUP_DIR
		./catchup.sh hive-impala
  else
  	echo "Skipping Exercise 8 catchup."
  fi
  echo $(date)
}

doExercise9(){
  if [[ $exercise -gt 9 ]] && [[ "$oneOnly" == "no" ]]; then
		echo "Ensuring Skytap does not auto-suspend while this script runs"
		curl -G http://gw/skytap?reset_autosuspend=1 &> /dev/null	
		echo ""
		echo "Simulating Exercise 9."
		echo ""
		cd $CATCHUP_DIR
		./catchup.sh hue
  elif [[ $exercise -eq 10 ]] && [[ "$oneOnly" == "yes" ]]; then
		echo ""
		echo "Simulating Exercise 9."
		echo ""
		cd $CATCHUP_DIR
		./catchup.sh hue
  else
  	echo "Skipping Exercise 9 catchup."
  fi
  echo $(date)
}

doExercise10(){
  if [[ $exercise -gt 10 ]] && [[ "$oneOnly" == "no" ]]; then
		echo "Ensuring Skytap does not auto-suspend while this script runs"
		curl -G http://gw/skytap?reset_autosuspend=1 &> /dev/null	
		echo ""
		echo "Simulating Exercise 10."
		echo ""
		cd $CATCHUP_DIR
		./catchup.sh hdfs-ha
  elif [[ $exercise -eq 11 ]] && [[ "$oneOnly" == "yes" ]]; then
		echo ""
		echo "Simulating Exercise 10."
		echo ""
		cd $CATCHUP_DIR
		./catchup.sh hdfs-ha
  else
  	echo "Skipping Exercise 10 catchup."
  fi
  echo $(date)
}

doExercise11(){
  if [[ $exercise -gt 11 ]] && [[ "$oneOnly" == "no" ]]; then
		echo "Ensuring Skytap does not auto-suspend while this script runs"
		curl -G http://gw/skytap?reset_autosuspend=1 &> /dev/null		
		echo ""
		echo "Simulating Exercise 11."
		echo ""
		cd $CATCHUP_DIR
		./catchup.sh scheduler
  elif [[ $exercise -eq 12 ]] && [[ "$oneOnly" == "yes" ]]; then
		echo ""
		echo "Simulating Exercise 11."
		echo ""
		cd $CATCHUP_DIR
		./catchup.sh scheduler
  else
  	echo "Skipping Exercise 11 catchup."
  fi
  echo $(date)
}

doExercise12(){
  if [[ $exercise -gt 12 ]] && [[ "$oneOnly" == "no" ]]; then
   	echo "Ensuring Skytap does not auto-suspend while this script runs"
	curl -G http://gw/skytap?reset_autosuspend=1 &> /dev/null		
    echo ""
    echo "In exercise 12 the only change is stopping the DataNode on elephant"
    echo "which is then restarted in exercise 13. When you do not specify you want"
    echo "to manually complete Exercise 13 specifically, then the DN on elephant will be left running."
  elif [[ $exercise -eq 13 ]] && [[ "$oneOnly" == "yes" ]]; then
    echo ""
    echo "Stopping the DataNode on elephant."
    echo ""
    cd $CATCHUP_DIR
	./catchup.sh breaking
	echo ""
	echo "Note: You will want to wait 10 minutes before starting the 'self healing'"
	echo "exercise, just as is necessary if you did the exercise 12 steps manually."
  else
  	echo "Skipping Exercise 12 catchup."
  fi
  echo $(date)
}

doExercise13(){
  if [[ $exercise -gt 13 ]] && [[ "$oneOnly" == "no" ]]; then
		echo "Ensuring Skytap does not auto-suspend while this script runs"
		curl -G http://gw/skytap?reset_autosuspend=1 &> /dev/null	
		echo ""
    	echo "In exercise 13 the only change is starting the DataNode on elephant"
    	echo "that was stopped in exercise 12. Since you did not specify that you want"
    	echo "to manually complete Exercise 13 specifically, the DN on elephant was not"
    	echo "stopped and does not need restarting. Nothing to do here."
		echo ""
  elif [[ $exercise -eq 14 ]] && [[ "$oneOnly" == "yes" ]]; then
		echo ""
		echo "Simulating Exercise 13."
		echo ""
		cd $CATCHUP_DIR
		./catchup.sh healing
  else
  	echo "Skipping Exercise 13 catchup."
  fi
  echo $(date)
}

doExercise14(){
  if [[ $exercise -gt 14 ]] && [[ "$oneOnly" == "no" ]]; then
		echo "Ensuring Skytap does not auto-suspend while this script runs"
		curl -G http://gw/skytap?reset_autosuspend=1 &> /dev/null
		echo ""
		echo "Simulating Exercise 14."
		echo ""
		cd $CATCHUP_DIR
		./catchup.sh snapshot
  elif [[ $exercise -eq 15 ]] && [[ "$oneOnly" == "yes" ]]; then
		echo ""
		echo "Simulating Exercise 14."
		echo ""
		cd $CATCHUP_DIR
		./catchup.sh snapshot
  else
  	echo "Skipping Exercise 14 catchup."
  fi
  echo $(date)
}

doExercise15(){
  if [[ $exercise -gt 15 ]] && [[ "$oneOnly" == "no" ]]; then
		echo "Ensuring Skytap does not auto-suspend while this script runs"
		curl -G http://gw/skytap?reset_autosuspend=1 &> /dev/null
		echo ""
		echo "Simulating Exercise 15."
		echo ""
		cd $CATCHUP_DIR
		./catchup.sh email
  elif [[ $exercise -eq 16 ]] && [[ "$oneOnly" == "yes" ]]; then
		echo ""
		echo "Simulating Exercise 15."
		echo ""
		cd $CATCHUP_DIR
		./catchup.sh email
  else
  	echo "Skipping Exercise 15 catchup."
  fi
  echo $(date)
}

doExercise16(){
  if [[ $exercise -gt 16 ]]; then
		echo "Ensuring Skytap does not auto-suspend while this script runs"
		curl -G http://gw/skytap?reset_autosuspend=1 &> /dev/null
		echo ""
		echo "Simulating Exercise 16."
		echo ""
		cd $CATCHUP_DIR
		./catchup.sh heap
   elif [[ $exercise -eq 17 ]] && [[ "$oneOnly" == "yes" ]]; then
		echo ""
		echo "Simulating Exercise 16."
		echo ""
		cd $CATCHUP_DIR
		./catchup.sh heap
  else
  	echo "Skipping Exercise 16 catchup."
  fi
  echo $(date)
}

MYHOST="`hostname`: "
CATCHUP_DIR="/home/training/training_materials/admin/scripts/catchup/"
# Avoid "sudo: cannot get working directory" errors by
# changing to a directory owned by the training user
cd ~
getStartState
getConfirmation
cleanup
doExercise1
doExercise2
doExercise3
doExercise4
doExercise5
doExercise6
doExercise7
doExercise8
doExercise9
doExercise10
doExercise11
doExercise12
doExercise13
doExercise14
doExercise15
doExercise16
echo 
echo $MYHOST $0 "done." 
echo $(date)
