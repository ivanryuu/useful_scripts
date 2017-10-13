#!/bin/bash

_old=$1
_new=$2

ag -l "${_old}" | xargs sed -i "s/${_old}/${_new}/g"

files=$(find -name "*${_old}*")
file_array=($files)
for elem in "${file_array[@]}"; do
  new_name="${elem/${_old}/${_new}}"
  hg rename ${elem} ${new_name}
done
