#!/bin/bash

command -v psql >/dev/null 2>&1 || { echo >&2 "abort. psql required."; exit 1; }

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
dbhost="10.20.40.80"
dbname="telematics_test_telematics"
directory=""
files=""
all_schema=0
remove=0
while getopts "ard:f:" opt; do
    case "$opt" in
    a)  all_schema=1
        ;;
    d)  dbname=$OPTARG
        ;;
    f)  directory=$OPTARG
        ;;
    r) remove=1 ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

if [ "$all_schema" -eq "1" ]; then
  wrtsql.sh -a
  files="script.sql"
elif [[ -z "${directory// }" ]]; then
  echo "no files were specified"
  exit 1
else
  wrtsql.sh -d $directory
  files="script.sql"
fi;

psql -h $dbhost -d $dbname -U postgres -f $files -1

if [ "$remove" -eq "1" ]; then
  rm "$files"
fi
