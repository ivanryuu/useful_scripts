#!/bin/bash

command -v hg >/dev/null 2>&1 || { echo >&2 "abort. hg required."; exit 1; }
command -v python >/dev/null 2>&1 || { echo >&2 "abort. python required."; exit 1; }
command -v pgsanity >/dev/null 2>&1 || { echo >&2 "abort. pgsanity required."; exit 1; }
command -v ecpg >/dev/null 2>&1 || { echo >&2 "abort. ecpg required."; exit 1; }

SCHEMA_DIR="schema"
GAT_DIR="GatewayUpdateScripts"
TEL_DIR="TelematicsUpdateScripts"
TEL_SCHEMAS=("action_request\|device_doctor\|health_event\|phonebook\|sds\|vehicle")
DIR_ORDER=("SEQUENCE" "TABLE" "INDEX" "CONSTRAINT" "FK_CONSTRAINT" "DATA" "TRIGGER" "FUNCTION")

CURR_BRANCH=$(hg branch)
if [ ! $? -eq 0 ]; then
	exit 1
elif [ $CURR_BRANCH = "default" ]; then
	echo "abort. not in a branch."
	exit 1
elif [ ! -d $SCHEMA ]; then
	echo "abort. schema directory not found."
	exit 1
fi

# todo: remove changes added in merge
HAS_MERGE=$(hg log -r "branch(`hg branch`) and merge()" | grep 'default')
if [ "$HAS_MERGE" ]; then
	echo "abort. branch was merged to default."
	exit 1
fi

PARENT=$(hg log -r "parents(min(branch($CURR_BRANCH)))" | grep 'changeset' | awk '{print $2}')
REV=${PARENT#*:}

FILES=$(hg diff -r $REV --stat | grep 'schema/.*sql.*+' | awk '{print $1}')
ERROR_FLAG=false
for f in $FILES; do
	if ! pgsanity $f; then
		echo '-->' $f
		ERROR_FLAG=true
	fi
done;

create_script() {
	HEADER="SELECT support.script_ok_to_run(:release_script, :hgchangeset, :force);"
	FOOTER="SELECT support.script_run(:release_script, :release_user, :hgchangeset, :hgbranch, :hguser, :hgsummary, :bugid);"
	if [ $2 ]; then
		SCRIPT_NAME=$1/$(date -d "today" +"%Y%m%d")_$CURR_BRANCH.sql
		printf "$HEADER\n$2\n$FOOTER\n" > "$SCRIPT_NAME"
		echo "created $SCRIPT_NAME"
	fi
}

if [ $ERROR_FLAG = false ]; then
	GAT_SCRIPT=""
	TEL_SCRIPT=""

	for d in ${DIR_ORDER[@]}; do
		TEL_HAS_FILES=false
		GAT_HAS_FILES=false
		for f in `printf -- '%s' "$FILES" | grep "/$d"`; do
			if grep -q $TEL_SCHEMAS $f; then
				TEL_SCRIPT="$TEL_SCRIPT\n\i/root/release/Devel/$f"
				TEL_HAS_FILES=true
			else
				GAT_SCRIPT="$GAT_SCRIPT\n\i/root/release/Devel/$f"
				GAT_HAS_FILES=true
			fi
		done;

		if [ $TEL_HAS_FILES = true ]; then
			TEL_SCRIPT="$TEL_SCRIPT\n"
		fi
		if [ $GAT_HAS_FILES = true ]; then
			GAT_SCRIPT="$GAT_SCRIPT\n"
		fi

	done;
	create_script $TEL_DIR $TEL_SCRIPT
	create_script $GAT_DIR $GAT_SCRIPT
fi
