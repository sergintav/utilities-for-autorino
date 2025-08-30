#!/usr/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error when substituting.

#working directory
export  work_dir="/data2/semih"

#activate myenv
source ${work_dir}/myenv/bin/activate

#set enviroment for autorino
export AUTORINO_DIR="$work_dir"
export AUTORINO_ENV="${AUTORINO_DIR}/configfiles/main/autorino_main_cfg.yml"


# List of sites
declare -a sites_direct=("ATAK00TUR" "KANT00TUR" "JYO400TUR")
 
declare -a sites_turkcell=("ARMU00TUR" "MAVI00TUR" "TERM00TUR" "HRTX00TUR" "DARC00TUR" "KINA00TUR" "KRBG00TUR" "EZNE00TUR" "RKYE00TUR" "EVRE00TUR" \ 
                           "KMAR00TUR")

declare -a sites_vodofone=("GELI00TUR")

declare -a sites_telekom=("KHAS00TUR" "TEPE00TUR" "EKOY00TUR" "KOCA00TUR" "SILT00TUR" "KLYT00TUR" "KCTX00TUR" "EDCK00TUR" "KERD00TUR" "CANM00TUR" \
                          "EVRE00TUR" "ENEZ00TUR" "ERIK00TUR" "MARE00TUR" "NKEM00TUR")

#create full list                          
declare -a sites_all=("${sites_direct[@]}" "${sites_turkcell[@]}" "${sites_vodofone[@]}" "${sites_telekom[@]}")                         
                  
                  
# Use GNU Parallel to upload the directory to each server simultaneously
# Pass the arguments directly after a triple colon (:::)
#log directory will be created in home directory. if you wish to change it, add path

#for cron usage in the shall
#parallel --results log  'autorino_cfgfile_run -c'"${work_dir}"'/configfiles/sites -sp download convert -si {}' ::: "${sites_all[@]}"


#for termineal usage, directly
parallel --eta --progress --results log  'autorino_cfgfile_run -c'"${work_dir}"'/configfiles/sites -sp download convert -si {}' ::: "${sites_all[@]}"
