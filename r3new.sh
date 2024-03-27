#!/bin/bash
version='5.0.0'

# colors
grn="\e[01;32m"
rd="\e[01;31m"
blu="\e[01;34m"
pur="\e[01;35m"
yew="\e[01;33m"
end="\e[00m"

# used with the signal to cancel the script process
signal_ctrl_c(){
  echo -e "${rd}Process canceled${end}"
  tput cnorm
  exit 1
}
trap signal_ctrl_c SIGINT

# process the execution errors
error_state(){
  local code=$1
  local msg=$2
  
  if [[ $code -ne 0 ]]; then
    echo -e "[${rd}ERROR${end}] $msg"
    tput cnorm
    exit 1
  fi
}

help_menu(){
cat << EOF
usage: ${0##*/} [-h] [-v] [-p] [-t] -d

description:
  rename the files in a specified directory. you can use the parameter -p to specify
  a prefix to renamed all the files. if the parameter is not specified, the hash (MD5)
  of the file itself will be used as the prefix (7 chars).

  it's recommended to use it only on multimedia files.

options:
  -h      help menu.
  -v      script version.
  -d      directory path with files.
  -p      prefix that will identify the renamed files.
  -t      add the file type prefix img, vid, aud using (true/false)
          by default, its set to true.
EOF
}

# rename the files already with the contructed  file paths
rename_file(){
  local origin=$1
  local destin=$2

  mv $origin $destin 2>/dev/null 
  # check that the renaming was executed correctly
  if [[ $? -eq 0 ]]; then
    echo -e "${grn}[${blu}Renamed${grn}]${yew} $origin ${grn}to${pur} $destin${end}"
    counter=$[$counter+1]
  fi
}

# process the file string, building the source and destination paths. it also constructs the new
# name depending on whather it has the prefix or not.
process_file(){
  local dir_path=$1
  local name=$2
  local extension=$3
  local prefix=$4
  local i=$5
  local type=$6

  # construct the source file path
  local file_origin="${dir_path}/${name}.${extension}"

  if [[ $prefix == 'hash' ]]; then
    # this code block processes the data to contruct the new file name - starting from the file's hash
    # get the file hash (7 chars) 
    local file_hash=$(md5sum ${file_origin} | cut -c 1-7)

    # contruct the file origin
    local file_destin="${dir_path}/${type}${file_hash}.${extension,,}"

    rename_file ${file_origin} ${file_destin}
  else
    # this code block contruct the new file name, starting from the prefix configured from the parameter
    # contruct the file origin
    local file_destin=$(printf "${dir_path}/${type}${prefix}-%02d.${extension,,}" "${i}")
    
    rename_file ${file_origin} ${file_destin}
  fi
}

# process the data
main(){
  local dir_path=$1
  local prefix=$2
  local bool=$3
  local i=1

  # list of extensions that will generate a prefix indicating the file type (vid,img,aud)
  local img=(jpg jpeg png gif tiff)
  local vid=(mp4 mkv mob wmv avi webm)
  local aud=(mp3 wav wma)

  # check if the directory exists
  if ! [[ -d $dir_path && $(ls $dir_path | wc -l) -ne 0 ]]; then
    error_state 1 "the directory does not exist or is empty"
  fi

  # if the last character is /, remove it.
  [[ ${dir_path: -1} == '/' ]] && local dir_path=${dir_path%?}

  # check the value of the arguemnt -t
  if [[ ${bool} == 'true' ]]; then
    local prefix_img='IMG-'
    local prefix_vid='VID-'
    local prefix_aud='AUD-'
  fi

  # iterate through all the files in the directory
  for file in $(ls -1 $dir_path 2>/dev/null); do
    # the function receives the files path, name, extension and file type
    local name=${file%.*}
    local extension="${file##*.}"
    local patron_ext="\\b${extension}\\b"

    # check the file type based on its extension
    if [[ ${img[*]} =~ $patron_ext ]]; then
       process_file $dir_path $name $extension $prefix $i $prefix_img
    elif [[ ${vid[*]} =~ $patron_ext ]]; then
       process_file $dir_path $name $extension $prefix $i $prefix_vid
    elif [[ ${aud[*]} =~ $patron_ext ]]; then
       process_file $dir_path $name $extension $prefix $i $prefix_aud
    else
       process_file $dir_path $name $extension $prefix $i ''
    fi
    i=$[$i + 1]
  done
}

# set up the necessary arguments
while getopts ':h,v,t:d:p:' args 2>/dev/null; do
  case $args in
      \?) error_state 1 "invalid parameter, use -h"
         ;;
      :) error_state 1 "the parameter requieres an argument"
         ;;
      h) help_menu && break
         ;;
      v) echo -e "${0##*/} ${version}" && break
         ;;
      d) dir_path=$OPTARG
         ;;
      p) prefix=$OPTARG
         ;;
      t) bool=$OPTARG
         ;;
  esac
done

# if the variable dir_path is not empty, continue with the process, otherwise, termine
if [[ -n $dir_path ]]; then
  declare -i counter=0
  tput civis
  main ${dir_path} ${prefix:-hash} ${bool:-true}

  # show the summary of renamed files
  if [[ $counter -ne 0 ]]; then
    echo -e "\n ${grn}[${pur}${counter}${grn}]${end} file(s) renamed\n"
  else
    echo -e "\n ${blu}[!]${end} ${rd}No files were renamed${end}\n"
  fi
  tput cnorm
fi
