#!/bin/bash
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
schema_name=${PWD##*/}

# Initialize our own variables:
name=""
col=""
col_type="bigint"
cols=""
fk_table=""
fk_schema=""
fk_col=""
partition=""
_type=""
_subtype=""

sql_type="$1"
shift 1;

TEMP=`getopt -o n:p: --long name:,col:,col-type:,cols:,fk-table:,fk-schema:,fk-col:,type:,partition: -n 'sqlgen.sh' -- "$@"`
eval set -- "$TEMP"

while true ; do
  case "$1" in
    -n|--name)
      case "$2" in
        "") exit 1 ;;
        *) name=$2 ; shift 2 ;;
      esac ;;
    --col) col=$2 ; shift 2 ;;
    --col-type) col_type=$2 ; shift 2 ;;
    --cols) cols=$2 ; shift 2 ;;
    --fk-table) fk_table=$2 ; shift 2 ;;
    --fk-schema) fk_schema=$2 ; shift 2 ;;
    --fk-col) fk_col=$2 ; shift 2 ;;
    -p|--partition) partition=$2 ; shift 2 ;;
    --type) _type=$2 ; shift 2 ;;
    --subtype) _subtype=$2 ; shift 2 ;;
    --) shift ; break ;;
    *) echo "Internal error" ; exit 1;;
  esac
done

function string_is_set() {
  string=$1
  msg=$2
  if [[ -z "${string// }" ]]; then
    echo "$msg"
    exit 1
  fi;
}

string_is_set "$name" "-n or --name must be used"

function replace() {
  old=$1
  new=$2
  dest=$3
  sed -i -e "s/$old/$new/g" ${dest}
}

function copy_and_replace() {
  template=$1
  dest=${2}.sql
  cp $parent_path/templates/${template}_template.sql ${dest}
  replace "<schema_name>" ${schema_name} ${dest}
  replace "<table_name>" ${name} ${dest}
  echo "Generated: ${dest}"
}

function copy_and_replace_partition() {
  time=$1
  dest=TRIGGER/${name}_before_insert
  copy_and_replace trigger_partition ${dest}
  replace "<col>" ${col} ${dest}
  replace "<time>" ${time} ${dest}
}

function generate_sequence() {
  copy_and_replace sequence_id SEQUENCE/${name}_id_seq
}

function generate_pk() {
  copy_and_replace table_pk CONSTRAINT/${name}_pkey
}

function generate_fk() {
  if [[ -z "${col// }" ]]; then
    col=${fk_table}_id
  fi;

  if [[ -z "${fk_schema// }" ]]; then
    fk_schema=${schema_name}
  fi;

  if [[ -z "${fk_col// }" ]]; then
    fk_col=${fk_table}_id
  fi;

  dest=FK_CONSTRAINT/${name}_${fk_table}_fkey
  copy_and_replace table_fk ${dest}
  replace "<col>" ${col} ${dest}
  replace "<fk_schema>" ${fk_schema} ${dest}
  replace "<fk_table>" ${fk_table} ${dest}
  replace "<fk_col>" ${fk_col} ${dest}
}

function generate_index() {
  dest=INDEX/${name}_${col}_idx
  copy_and_replace table_index ${dest}
  replace "<col>" ${col} ${dest}
}

function generate_table() {
  copy_and_replace table TABLE/${name}
  copy_and_replace table_permissions TABLE/${name}_permissions
}

function generate_trigger_partition() {
  if [[ -z "${col// }" ]]; then
    col="create_time"
  fi;

  case "$partition" in
    d*) copy_and_replace_partition "day" ;;
    w*) copy_and_replace_partition "week" ;;
    m*) copy_and_replace_partition "month" ;;
  esac
}

function generate_trigger_update() {
  if [ ! -f FUNCTION/tf_update_update_time.sql ]; then
    copy_and_replace tf_update_time TRIGGER/tf_update_update_time
  fi
  copy_and_replace trigger_update TRIGGER/update_update_time_${name}
}

function generate_trigger() {
  string_is_set "$_type" "--type must be used"

  case "$_type" in
    p*) generate_trigger_partition ;;
    r*) copy_and_replace trigger_replicate TRIGGER/replicate_${name} ;;
    u*) generate_trigger_update ;;
  esac
}

function generate_schema() {
  copy_and_replace schema ${schema_name}
  mkdir -p CONSTRAINT FK_CONSTRAINT FUNCTION INDEX SEQUENCE TABLE TRIGGER DATA
}

generate_function_get() {
  pluralLookupName="s"
  if [[ -z "${col// }" ]]; then
    col="${name}_id"
    pluralLookupName=""
  fi;
  short_name=`echo ${name} | sed -e "s/${schema_name}_//g"`
  short_col=`echo ${col} | sed -e "s/${schema_name}_//g"`

  IFS=' ' read -ra array <<< ${cols}
  cols=""
  for elem in "${array[@]}"; do
    cols+="\n\t\tt.${elem},"
  done

  function_name=get_${short_name}${pluralLookupName}_by_${short_col}
  dest=FUNCTION/${function_name}

  copy_and_replace function_get ${dest}
  replace "<col>" "${col}" ${dest}
  replace "<col_type>" "${col_type}" ${dest}
  replace "<cols>" "${cols}" ${dest}
  replace "<function_name>" "${function_name}" ${dest}

  dest=FUNCTION/${function_name}_permissions
  copy_and_replace function_get_permissions ${dest}
  replace "<function_name>" "${function_name}" ${dest}
  replace "<col_type>" "${col_type}" ${dest}
}

generate_function_add() {
  IFS=',' read -ra array <<< ${cols}
  params=""
  param_types=""
  param_names=""
  table_names=""
  for elem in "${array[@]}"; do
    split=($elem)
    params+="\n\t_${split[0]} ${split[1]},"
    param_types+="${split[1]}, "
    param_names+="_${split[0]}, "
    table_names+="${split[0]}, "
  done

  params=${params::-1}
  param_types=${param_types::-2}
  param_names=${param_names::-2}
  table_names=${table_names::-2}

  function_name="add_${name}"
  dest=FUNCTION/${function_name}
  copy_and_replace function_add ${dest}
  replace "<params>" "${params}" ${dest}
  replace "<param_types>" "${param_types}" ${dest}
  replace "<param_names>" "${param_names}" ${dest}
  replace "<table_names>" "${table_names}" ${dest}

  dest=FUNCTION/${function_name}_permissions
  copy_and_replace function_add_permissions ${dest}
  replace "<function_name>" ${function_name} ${dest}
  replace "<param_types>" "${param_types}" ${dest}
}

generate_function_update() {
  IFS=',' read -ra array <<< ${cols}
  params=""
  param_types=""
  set_statements=""
  for elem in "${array[@]}"; do
    split=($elem)
    params+="\n\t_${split[0]} ${split[1]},"
    param_types+="${split[1]}, "
    set_statements+="\n\t\t${split[0]} = _${split[0]},"
  done

  params=${params::-1}
  param_types=${param_types::-2}
  set_statements=${set_statements::-1}

  function_name="update_${name}"
  dest=FUNCTION/${function_name}
  copy_and_replace function_update ${dest}
  replace "<params>" "${params}" ${dest}
  replace "<param_types>" "${param_types}" ${dest}
  replace "<set_statements>" "${set_statements}" ${dest}

  dest=FUNCTION/${function_name}_permissions
  copy_and_replace function_update_permissions ${dest}
  replace "<function_name>" ${function_name} ${dest}
  replace "<param_types>" "${param_types}" ${dest}
}

generate_function() {
  case "$_type" in
    a*) generate_function_add ;;
    g*) generate_function_get ;;
    u*) generate_function_update ;;
  esac
}

case "$sql_type" in
  ta*)
    generate_table
    generate_sequence
    generate_pk
    _type="replicate"
    generate_trigger
    ;;
  se*) generate_sequence ;;
  sc*) generate_schema ;;
  pk) generate_pk ;;
  fk) generate_fk ;;
  i*) generate_index ;;
  tr*) generate_trigger ;;
  f*) generate_function ;;
esac
