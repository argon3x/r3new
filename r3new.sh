 #!/bin/bash

# colors
gr="\e[01;32m"
bl="\e[01;34m"
re="\e[01;31m"
ye="\e[01;33m"
end="\e[00m"

# context execution
okey="${bl}[${gr}+${bl}]${end}"
err="${bl}[${re}-${bl}]${end}"
war="${bl}[${ye}!${bl}]${end}"

# signal handlers
interrupt_signal(){
  # interrupt process with ctrl+c
  echo -e "\n${re} process terminated ${end}\n"
  exit 1
}

terminate_signal(){
  # process terminated by error
  local error=${1:-'unknown error'}

  echo -e "\n${re}[ERROR]${end}: ${error}\n"
  exit 1
}

trap interrupt_signal SIGINT
trap terminate_signal SIGTERM


help_menu(){
# show the help menu
cat << EOF
usage: ${0##*/} [-h] [-v] [-n] -d

description:
  renames files in the selected directory, by default using the file hash, 
  (first 17 chars of the hash)or using the -n paramenter for a specific name.

  it is recommended to use it to rename multimedia files.

options:
  -h      show this help menu.
  -v      show the script version.
  -d      select a directory.
  -n      use specific a name (by default used the hash).
EOF
exit 0
}

rename_file(){
  local origin=$1
  local destin=$2

  (mv -n $origin $destin 2>/dev/null)
  if [[ $? -eq 0 ]]; then
    echo -e "${gr}OK${end}"
  else
    echo -e "${ye}already renowned${end}"
  fi
}


rename_hash(){
  local fpath=$1
  local dpath=${1%/*}
  local ext=${1##*.}

  # gets the first 17 chars of the file's md5 hash
  hash_md5=$(md5sum $fpath | cut -c 1-10)
  
  # generate a new file name
  new_name="${dpath}/${hash_md5}.${ext,,}"

  # rename the file
  echo -e "${hash_md5}... \c"

  rename_file $fpath $new_name
}


rename_name(){
  local fpath=$1
  local dpath=${1%/*}
  local ext=${1##*.}
  local count=$(($2 + 1))
  local nname=$3

  # generate a new file name
  new_name=$(printf "${dpath}/${nname}_%02d.${ext,,}" "${count}")

  # rename the file
  echo -e "${new_name##*/}... \c"

  rename_file $fpath $new_name
}


rename_files(){
  local dpath=$1
  local nname=$2
  local count=0

  # remove the last char if it is a /
  [[ ${dpath: -1} == '/' ]] && local dpath=${dpath%?}

  # checks the integrity of the directory and its contents
  echo -e "${okey} checking the integrity of the directory... \c"

  if [[ -d $dpath && $(ls -1 ${dpath}/*.* 2>/dev/null | wc -l) -ne 0 ]]; then
    echo -e "${gr}OK${end}"
  else
    terminate_signal "the directory does not exist or is empty"
  fi

  # rename the files
  for file in $(ls -1 $dpath/*.*); do
    if [[ -f $file && $nname == 'default' ]]; then
      echo -e "${bl}[RENAMING]${end} $file ${gr}to${end} \c"

      rename_hash ${file} 
      count=$(($count + 1))

    elif [[ -f $file && $nname != 'default' ]]; then
      echo -e "${bl}[RENAMING]${end} $file ${gr}to${end} \c"

      rename_name ${file} ${count} ${nname}
      count=$(($count + 1))
    fi
  done

  echo -e "\n ${bl}[${gr}$count${bl}]${end} renamed files.\n"
}


if [[ $# -ne 0 ]]; then
  # Set arguments
  while getopts ':d:n:v,h' args 2>/dev/null; do
    case $args in
      \?) terminate_signal "the -$OPTARG paramenter not is valid";;
      :) terminate_signal "the -$OPTARG paramenter requires an argument";;
      h) help_menu;;
      v) echo -e "${0##*/} 4.0.0";;
      d) dpath=$OPTARG;;
      n) rename=${OPTARG};;
    esac
  done
  
  if [[ -n $dpath || -n $rename ]]; then
    rename_files $dpath ${rename:-'default'}
  fi

else
  help_menu
fi
