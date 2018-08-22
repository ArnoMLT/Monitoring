#!/bin/bash
# get_instances.sh
# version 1.00
# date 20/11/2017


# Usage info
show_help() {
cat << EOF
Usage: ${0##*/} -u  -p  -o 

This program show instance associated with the requested host.

    -u User Centreon.
    -p Password Centreon
    -o name host
    -h help
EOF
exit 2
}

while getopts 'u:p:ho:' OPTION
do
  case $OPTION in
    u)
       USER_CENTREON="$OPTARG"
       ;;
    p)
       PWD_CENTREON="$OPTARG"
       ;;
    o) NAME_HOST="$OPTARG"
       ;;
    ?|h) show_help
       ;;
   esac
done
shift $(($OPTIND - 1))

# Check for missing parameters
if [ -z "${USER_CENTREON}" ] || [ -z "${PWD_CENTREON}" ] || [ -z "${NAME_HOST}" ]; then
    echo "Missing parameters!"
    show_help
fi

TAIL=/usr/bin/tail
CLAPI=/usr/share/centreon/bin/centreon

# read instance
function read_instance ()
{
  shopt -s nocasematch
  $CLAPI -u $USER_CENTREON -p $PWD_CENTREON -o INSTANCE -a SHOW | $TAIL -n+2 |
  #lecture param
  while read line
  do
    NAME_INSTANCE=`echo $line | cut -d ";" -f2 `
	ID_INSTANCE=`echo $line | cut -d ";" -f1 `
    read_gethost "$NAME_INSTANCE" "$ID_INSTANCE"
  done
}

# read getshost
function read_gethost ()
{
  $CLAPI -u $USER_CENTREON -p $PWD_CENTREON -o INSTANCE -a GETHOSTS -v "$1" | $TAIL -n+2 |
  #lecture param
  while read line
  do
    NAME=`echo $line | cut -d";" -f2 `
	if [[ "$NAME_HOST" = "$NAME" ]]; then
	  echo $2
      exit 1
    fi
  done
}

read_instance