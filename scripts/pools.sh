#!/bin/bash

#This script is designed to be used during the Fair Scheduler exercise.
#Check that the user supplied two parameters.
if [ $# != 2 ]
  then
    echo "Wrong number of arguments supplied."
	echo $"Usage: $0 {pool1|pool2|pool3|pool4} {start|stop}"
	exit 1
fi
if [ $HOSTNAME != "elephant" ]; then
	echo "This script should only be run on elephant. It appears you are running this on " $HOSTNAME
	echo "Exiting..."
	sleep 5
	exit 0
fi
runJob() {
$1 hadoop jar \
~/training_materials/admin/java/sleep.jar SleepJob \
-D mapreduce.job.name=$2 \
-D mapreduce.job.queuename=$3 \
-m 10 -r 10 -mt 20000 -rt 20000 > /dev/null 2>&1 &
}

killJobs() {
	#create array to hold found appIds
	declare -a runningJobsInPool 
	runningJobsInPool=($(sudo yarn application --list | grep $1 | awk '{print $1}'))
	#iterate through appIds and kill the jobs
	for i in "${runningJobsInPool[@]}"
	do
		sudo yarn application -kill $i
	done 
}

case "$1" in
	pool1)
		case "$2" in
			start)
				echo "Starting job in pool1."
				runJob "" "job1elephant" "pool1"
				;;
			stop)
				echo "Stopping jobs in pool1."
				killJobs "job1elephant"
				;;
			*)
				echo $"Usage: $0 {pool1|pool2|pool3|pool4} {start|stop}"
			exit 1
		esac
		;;
	pool2)
		case "$2" in
			start)
				echo "Starting job in pool2."
				runJob "ssh training@tiger" "job2tiger" "pool2"
				;;
			stop)
				echo "Stopping jobs in pool2."
				killJobs "job2tiger"
				;;
			*)
				echo $"Usage: $0 {pool1|pool2|pool3|pool4} {start|stop}"
			exit 1
		esac
		;;
	pool3)
		case "$2" in
			start)
				echo "Starting job in pool3."
				runJob "ssh training@horse" "job3horse" "pool3"
				;;
			stop)
				echo "Stopping jobs in pool3."
				killJobs "job3horse"
				;;
			*)
				echo $"Usage: $0 {pool1|pool2|pool3|pool4} {start|stop}"
			exit 1
		esac
		;;
	pool4)
		case "$2" in
			start)
				echo "Starting job in pool4."
				runJob "" "job4monkey" "pool4"
				;;
			stop)
				echo "Stopping jobs in pool4."
				killJobs "job4monkey"
				;;
			*)
				echo $"Usage: $0 {pool1|pool2|pool3|pool4} {start|stop}"
			exit 1
		esac
		;;
	*)
		echo $"Usage: $0 {pool1|pool2|pool3|pool4} {start|stop}"
esac
exit 1
