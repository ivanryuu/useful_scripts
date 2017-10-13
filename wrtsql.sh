#!/bin/bash

array_all=("SEQUENCE" "TABLE" "INDEX" "CONSTRAINT" "FK_CONSTRAINT" "FUNCTION" "TRIGGER" "DATA");

directory=""
all=0
while getopts "ad:" opt; do
    case "$opt" in
    a)  all=1
        ;;
    d)  directory=$OPTARG
        ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

function write_sql() {
  array=("$@")
  for d in ${array[@]}; do
    for f in `ls -v $d/*.sql`; do
      cat $f >> script.sql;
    done;
  done;
}

if [ "$all" -eq "1" ]; then
  echo "DROP SCHEMA IF EXISTS $(basename $(pwd)) CASCADE;" > script.sql;
  find . -maxdepth 1 -type f -not -name 'script.sql' | xargs cat >> script.sql;
  write_sql "${array_all[@]}"
elif [[ -z "${directory// }" ]]; then
  echo "no directory was specified"
  exit 1
else
  echo "" > script.sql
  write_sql $(echo ${directory})
fi;
