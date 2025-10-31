#!/bin/bash

# This script creates users on the local machine.
# The first argument will be treated as username and any further as a single comment.
# Password is automatically generated; Errors will be displayed, all STDOUT suppressed.
# Finally, all Data is displayed.

# Enforce superuser execution
if [[ "${UID}" -ne 0 ]]
then
 echo "Only the superuser may execute this script" >&2
 exit 1
fi

# Enforce minimum 1 parameter given (for username)
if [[ "${#}" -lt 1 ]]
then
 echo "Usage: ${0} USER_NAME [COMMENT...]" >&2
 exit 1
fi

USER_NAME="${1}"

shift

COMMENT="${@}"

useradd -c "${COMMENT}" -m ${USER_NAME} &> /dev/null

# Safeguard if useradd failed for any reason
if [[ "${?}" -ne 0 ]]
then
 echo 'Creation of user failed.' >&2
 exit 1
fi

PASSWORD=$(date +%s%N | sha256sum | head -c32)

echo ${PASSWORD} | passwd --stdin ${USER_NAME} &> /dev/null

# Safeguard if password setting failed for whatever reason
if [[ "${?}" -ne 0 ]]
then
 echo 'Setting password failed!' >&2
 exit 1
fi

passwd -e ${USER_NAME} &> /dev/null

echo
echo "New user created: ${USER_NAME}"
echo "Initial password: ${PASSWORD}"
echo "On host: ${HOSTNAME}"
echo
exit 0
