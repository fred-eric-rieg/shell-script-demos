#!/bin/bash

# This script executes a single command on every remote system specified in either
# a default file or a user-given file [-f FILE].
# With the [-v] verbose option, the server name is displayed before executing the command.
# With the [-n] DRY RUN option, the user only gets verbose feedback but nothing is executed.
# With the [-s] SUDO option, the user can execute the command as superuser.

# If the script is used wrong (e.g. non-existing option) the user get's man-style feedback on how
# to use the script.

# This script shall not be executed as root. This will exit the script. Instead, use [-s] option.


VERBOSE=0
DRY=0
SUDO=0
SERVER_LIST='/vagrant/servers'
COMMAND=""

usage_info() {
cat <<EOF
Do not run this script as root. Use -s option instead.
Usage: $0 [-f FILE] [-nsv] COMMAND
Executes COMMAND as a single command on every server.
	-f FILE 	provide path to a custom file containing servernames
	-v 		verbose mode: displays server name before executing COMMAND
	-s 		execute COMMAND with sudo privileges on remote server
	-n 		dry run: display COMMAND and exit
EOF
}

# Logic for verbose output
verbose_output() {
if [[ VERBOSE -eq 1 ]]
then
 echo ssh ${1} hostname
fi
}

# Logic for sudo command execution
sudo_run() {
if [[ SUDO -eq 1 ]]
then
 ssh ${1} sudo ${2}
fi
}

check_exit_code() {
if [[ $(echo $?) -ne 0 ]]
then
 echo "Problem with ssh connection." >&2
 exit 1
fi
}

# The dry run logic gives verbose infos to the servers that would be connected to and exits with 0.
dry_run() {
for server in $(cat ${SERVER_LIST})
do
 echo "DRY RUN: $server"
done
exit 0
}

# The real run that executes the command via ssh
real_run() {
for server in $(cat ${SERVER_LIST})
do
 if [[ $VERBOSE -eq 1 ]]
 then
  echo "Running $command on $server"
 fi

 if [[ $SUDO -eq 1 ]]
 then
  ssh -o ConnectTimeout=2 $server sudo $COMMAND
  check_exit_code
 else
  ssh -o ConnectTimeout=2 $server $COMMAND
  check_exit_code
 fi
done
}

# Check if a non-root user executes this script.
if [[ "${UID}" -eq 0 ]]
then
 echo "NO superuser may execute this script, only normal users" >&2
 exit 1
fi


# Check all options set by user
while getopts nsvf: OPTIONS
do
 case $OPTIONS in
  f)
   SERVER_LIST="${OPTARG}"
   ;;
  v)
   VERBOSE=1
   ;;
  s)
   SUDO=1
   ;;
  n)
   DRY=1
   ;;
  ?)
   usage_info
   exit 1
   ;;
 esac
done

# Remove all Options
shift $((OPTIND - 1))


# Check, if COMMAND was provided
if [[ $# -eq 0 ]]
then
 echo "No command passed as argument!" >&2
 usage_info
 exit 1
else
 COMMAND=$@
 echo "Command given: $@"
fi

# Check, if SERVER_LIST exists
if [[ ! -e "${SERVER_LIST}" ]]
then
 echo "Server-List-File does not exist!" >&2
 exit 1
else
 echo "Found server list in : ${SERVER_LIST}"
fi

# Do the run!
if [[ ${DRY} -eq 1 ]]
then
 dry_run
else
 real_run
fi


# Exit with exit code of 0 (success) when reaching the end of the script.
exit 0
