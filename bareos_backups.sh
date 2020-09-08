#!/bin/bash
list_jobs() {
  job_name=$1
  echo "list jobs jobstatus=T job=${job_name} days=4" |bconsole |grep '|'|awk -F '|' 'NR>1 {print $3 $5}' |sed 's/ $\|^ //g; s/  \| /|/g'|sort -r
}

restore() {
  restore_client=$1
  backup=$2
  job_name=$(echo ${backup} |awk -F '|' '{print $1}')
  datetime=$(echo ${backup} |awk -F '|' '{print $2" "$3}')

  echo $2  
  echo ${job_name}
  echo ${datetime}
  #Get target job id for restore
  jobid=$(echo "list jobs job=${job_name} days=6 " | bconsole |grep -E "${datetime}"|awk -F '|' '{print $2}'|sed 's/^[ \t]*//;s/[ \t]*$//')
  echo $jobid
  #Run restore
  restore_job=$(echo "restore client=${restore_client} replace=always jobid=$jobid all done yes" |bconsole)
  echo $restore_job
  restore_job_id=$(echo $restore_job|grep -o "Job queued\. JobId=.*"|grep -Eo '[0-9]{1,}')
  echo $restore_job_id
  echo "list jobid=${restore_job_id}" | bconsole
  
  wait=30
  try=40
  while [ $try -gt 0 ]
    do
      sleep ${wait}
      restore_job_status=$(echo "list jobid=${restore_job_id}"|bconsole |grep ${restore_client} |awk -F '|' '{print $10}'|sed 's/^[ \t]*//;s/[ \t]*$//')
      case $restore_job_status in
        T)
          echo -e "\e[32mRestore job is finished successfull [jobstatus $restore_job_status]\e[0m"
          exit 0 
          ;;
        E)
          echo -e "\e[31m\e[1mRestore job failed. Check bareos logs for more information. JobID=${restore_job_id} client=${restore_client} [jobstatus ${restore_job_status}]\e[0m"
          exit 1
          ;;
        W)
          echo -e "\e[33mRestore job is finished with warnings. Check bareos logs fore more information. JobID=${restore_job_id} client=${restore_client} [jobstatus $restore_job_status]\e[0m"
          exit 1 
          ;;
        C) 
          echo "Restore job is created... ($try attempts left) [jobstatus ${restore_job_status}]"
          ;;
        *) 
          echo "Restore job is running... ($try attempts left) [jobstatus ${restore_job_status}]"
          ;;
      esac
      try=$((try - 1))
    done 
}

help() {
echo "============================="
echo "This script has 2 options:"
echo "--list       List available backups in last 4 days"
echo "             Usage example: ./bareos_backup.sh --list <BareosBackupJobName>"
echo ""
echo "--restore    Restore backup to server. (Default restore dir is /tmp/bareos-restores). "
echo "             Usage example: ./bareos_backup.sh --restore <RestoreClientServer> <BackupName>"
echo "============================="
echo "FYI: <BackupName> is one of result in '--list' option"
}

case $1 in 
  --list) 
     list_jobs $2
     ;;
  --restore)
    restore $2 $3 
    ;;
  --help)
    help
    ;;
  *)
    help
    ;;
esac
