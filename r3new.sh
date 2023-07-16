#!/bin/bash

### By: Argon3x
### Supported: Debian Based Systems and Termux
### Version: 3.0

# Colors
green="\e[01;32m"; blue="\e[01;34m"; red="\e[01;31m"
purple="\e[01;35m"; yellow="\e[01;33m"; end="\e[00m"

# Context Symbols
okey="${blue}[${green}+${blue}]${end}"
warning="${blue}[${red}!${blue}]${end}"
error="${blue}[${red}-${blue}]${end}"
pass="${blue}[${purple}*${blue}]${end}"

# signals handler
interrupt_handler(){
  echo -e "\n${warning} ${blue}------- ${red}Process Canceled ${blue}-------${end} ${warning}\n"
  tput cnorm
  exit 1
}
error_handler(){
  type_error="${1}"

  echo -e "${blue}Script Error${end}:{\n\t${type_error}\n}${end}"
  tput cnorm
  exit 1
}

# Call the signals
trap interrupt_handler SIGINT
trap error_handler SIGTERM


# Help munu
help_menu(){
  clear
  echo -e "${blue}Use Mode${end}\n"
  echo -e "${purple} -d, directory\t${end}Select a directory specific that contain pictures."
  echo -e "${purple} -r, rename\t${end}Rename the pictures already renamed, no overwrite the name"
  echo -e "${end}\t\tor Add a new name to rename the pictures."
  echo -e "${purple} -h, help\t${end}Show the help menu."
  echo -e "\n\t${green}./${0##*/}${end} -d [directory] <directory path> -n [new-name] <new name>\n"
  exit 0
}


# Continue the Renaming
continue_renaming (){
  local directory=$1
  local rename=$2
  local counter=$3
  local extensions=('jpg' 'jpeg' 'png')

  for e in ${extensions[@]}; do
    for i in $(command ls ${directory}/*.${e} 2>/dev/null); do
      local extract=$(basename ${i} ${e} | awk -F '_' '{print $1}')
      if [[ ${extract} != ${rename} ]]; then
        local rename_image=$(printf "${rename}_%02d.${e}" "${counter}")
        command mv "${i}" "${directory}/${rename_image}"
        let counter=counter+1
      fi
    done
  done

  if [[ $? -eq 0 ]]; then
    echo -e "\n${okey} ${green}Completed...!!!${end}\n"
  else
    error_handler "${red}Occurred An Error, While Renaming Images${end}"
  fi
}


# Rename Images
rename_images(){
  sleep 0.3
  local directory=$1
  local rename=$2
  local extensions=('jpg' 'jpeg' 'png')
  local counter=1
  
  for e in ${extensions[@]}; do
    for i in $(command ls ${directory}/*.${e}); do
      local rename_image=$(printf "${rename}_%02d.${e}" "${counter}")
      command mv "${i}" "${directory}/${rename_image}"
      sleep 0.2
      let counter=counter+1
    done
  done
  
  if [[ $? -eq 0 ]]; then
    echo -e "\n${okey} ${green}Completed...!!!${end}\n"
  else
    error_handler "${red}Occurred An Error, While Renaming Images${end}"
  fi
}


# Check if it continues with the renaming or renames again
checking_images(){
  sleep 1
  local path_directory=$1
  local rename=$2
  local extensions=('jpg' 'jpeg' 'png')
  local counter=0

  if [[ ${path_directory: -1} == '/' ]]; then local path_directory=${path_directory%?}; fi


  # check if there is at least one image with the name to continue the renaming.
  for e in ${extensions[@]}; do 
    for i in $(command ls ${path_directory}/*.${e}); do 
      extract=$(basename ${i} ${e} | awk -F '_' '{print $1}')
      if [[ ${extract} == ${rename} ]]; then
        let counter=counter+1
      fi
    done
  done

  # Check if there is more than one image with the name.
  if [[ ${counter} -ne 0 ]]; then
    echo -e "${pass} ${yellow}Continuing with the renaming of ${blue}(${green}${rename}${blue})${end}"
    continue_renaming $path_directory $rename $counter
  else
    echo -e "${pass} ${yellow}Renaming images to ${green}${rename}${end}......."
    rename_images $path_directory $rename
  fi
}

if [[ $# -ge 1 && $# -le 4 ]]; then
  while getopts ":d:r:h" args; do
    case $args in
      d) path_directory=$OPTARG ;;
      r) rename=$OPTARG ;;
      h | help) help_menu ;;
      :) error_handler "${purple}-$OPTARG ${red}Required An Argument ${purple}-h/--help${end}";;
      \?) error_handler "${red}The ${purple}-$OPTARG ${red}Argument Not Is Valid, use ${purple}-h ${red}for more help.${end}";;
    esac
  done
  
  clear && tput civis
  # Checking if the directory exists
  echo -e "${pass} ${yellow}Checking directory${end}....... \c"; sleep 1
  if [[ -d ${path_directory} ]]; then
    echo -e "${green}OK${end}"

    # Call the function.
    checking_images ${path_directory} ${rename}
  else
    echo -e "${red}FAILED${end}\n"
    error_handler "${error} ${red}Occurred An Error, The ${purple}${path_directory} ${red}Directory Not Exists${end}"
  fi

  tput cnorm
else
  help_menu
fi
