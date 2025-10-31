#!/bin/bash

# Disables/expires/locks accounts by default
# Options
# -d delete user
# -r remove home directory
# -c creates archive of home directory and stores in /archives -> create dir if needed
# invalid options will trigger usage info and exit 1
# List of usernames as arguments (min 1 username or usage info display)
# Refuse to delete accounts with ID less than 1000
# Info if not able to disable, delete or archive
# Display what has been done with usernames provided

DELETE_USERS=0
DELETE_HOMES=0
ARCHIVE_HOMES=0

info_out() {
 echo "${@}" >&2
}

# Prints info how to use this script to the terminal
usage_info() {
 cat <<EOF
Usage: $0 [-d] [-r] [-c] USERNAME...
	-d	delete given user
	-r	remove home directory of given users
	-c	create archive of home directories and store in /archives
EOF
}

check_uid() {
 ID=$(id -u $@)
 if [[ $ID -lt 1001 ]]
 then
  info_out "Refusing to delete User ${@} with UID 1000 or lower." >&2
  info_out "Nothing was done." >&2
  exit 1
 fi
}

delete_users() {
 local USERS="${@}"
 for user in $USERS; do
  check_uid $user
  userdel $user
 done
}

# Sudo check
if [[ "${UID}" -ne 0 ]]
then
 info_out 'Sudo privileges required.'
 exit 1
fi

# Using getopts to extract user-provided options
while getopts dra OPTIONS
do
 case $OPTIONS in
  d)
   echo "Requesting to delete all users given."
   DELETE_USERS=1
   ;;
  r)
   echo "Requesting delete all home directories of users given."
   DELETE_HOMES=1
   ;;
  a)
   echo "Requesting to archive all home directories of users given."
   ARCHIVE_HOMES=1
   ;;
  *)
   info_out "Option not known: -{$OPTARG}"
   usage_info
   exit 1
   ;;
 esac
done

# Delete all options after the while-loop's check
shift $((OPTIND - 1))

# Check, if usernames were given as arguments
if [[ $# -eq 0 ]]
then
 echo "No usernames passed as argument!" >&2
 usage_info
 exit 1
fi

# Execute commands according to options
for user in "$@"; do
 check_uid $user
 HOME_DIR=$(getent passwd "$user" | cut -d: -f6)

 # Archive Option
 if [[ "$ARCHIVE_HOMES" -eq 1 ]]; then
  mkdir /archives 2>/dev/null
  TIMESTAMP=$(date +%s)
  tar -czf "/archives/${user}_${TIMESTAMP}.tar.gz" "${HOME_DIR}" &> /dev/null
  if [[ $? -ne 0 ]]; then
   info_out "Failed archiving ${user}'s home directory in ${HOME_DIR}" >&2
   exit 1
  else
   echo "Archived $user home directory in /archives/${user}_${TIMESTAMP}.tar.gz"
  fi
 fi

 # Delete Option
 if [[ "$DELETE_USERS" -eq 1 ]]; then
  userdel "$user"
  if [[ $? -ne 0 ]]; then
   info_out "Failed to delete $user" >&2
   exit 1
  else
   echo "User $user deleted."
  fi
 fi

 # Delete home option
 if [[ "$DELETE_HOMES" -eq 1 ]]; then
  rm -rf "${HOME_DIR}"
  if [[ $? -ne 0 ]]; then
   info_out "Failed deleting home directory of $user" >&2
   exit 1
  else
   echo "Home directory of $user deleted."
  fi
 fi

 # If no options are set, default behaviour is triggered
 if [[ "$ARCHIVE_HOMES" -eq 0 && "$DELETE_USERS" -eq 0 && "$DELETE_HOMES" -eq 0 ]]; then
  chage -E 0 "$user" && echo "User $user deactivated"
  if [[ $? -ne 0 ]]; then
   info_out "Failed to deactivate account of $user."
   exit 1
  fi
 fi
done

echo "Success!"
exit 0
