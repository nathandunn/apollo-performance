#!/bin/bash

#pip install ../python-apollo

NUMBER_USERS=2
NUMBER_ORGANISMS_PER_ORGANISM=1
ORGANISMS=("yeast" "fly")

SHOULD_LAUNCH_DOCKER=1
for arg in "$@"
do
    case $arg in
        --nodocker)
        SHOULD_LAUNCH_DOCKER=0
        shift
        ;;
        *)
        shift
        ;;
    esac
done

export GALAXY_SHARED_DIR=`pwd`/apollo_shared_dir
mkdir -p "$GALAXY_SHARED_DIR"
mkdir -p loaded-data

function init(){

  if ! [[ $SHOULD_LAUNCH_DOCKER -eq 0 ]]; then
    IS_RUNNING=$(docker ps  | grep quay.io/gmod/apollo:latest | wc -l)
    if [[ "$IS_RUNNING" -eq "0" ]]; then
      echo "is not running so starting"
      echo "docker run --memory=4g -d -p 8888:8080 -v `pwd`/apollo_shared_dir:/data/ quay.io/gmod/apollo:latest"
      docker run --memory=4g -d -p 8888:8080 -v `pwd`/apollo_shared_dir:/data/  quay.io/gmod/apollo:latest
    else
      echo "Apollo on docker is already running"
    fi
  fi

  for ((i=0;i<30;i++))
  do
      echo "Checking Apollo"
     APOLLO_UP=$(arrow users get_users 2> /dev/null | head -1 | grep '^\[$' -q; echo "$?")
     echo "Result of Apollo up $APOLLO_UP"
    if [[ $APOLLO_UP -eq 0 ]]; then
      echo "Apollo came up"
      break
    fi
  #   arrow users get_users
      echo "Not up yet"
      sleep 10
  done

  echo "Apollo is running ${APOLLO_UP}"

}

function add_users(){
  echo "adding users using arrow"
#  echo arrow users get_users | jq '. | length'
  FOUND_USERS=$(arrow users get_users | jq '. | length')
  echo "Number of users : ${FOUND_USERS}"
  if [ "$FOUND_USERS" -le "$NUMBER_USERS" ]
  then
    for user_number in $(seq 1 $NUMBER_USERS);
    do
      arrow users create_user user"${user_number}"@test.com user"${user_number}" lastname"${user_number}" demo --role user
    done
  fi
}

function download_organism_data(){
  for organism in "${ORGANISMS[@]}" ; do
    if [[ ! -d "loaded-data/${organism}" ]]
    then
      curl -o loaded-data/${organism}.tgz https://apollo-jbrowse-data.s3.amazonaws.com/${organism}.tgz
      tar xfz loaded-data/${organism}.tgz -C loaded-data
    fi
  done
}

function prepare_organism_data(){
  for organism in "${ORGANISMS[@]}" ; do
    if [[ ! -f "${GALAXY_SHARED_DIR}/${organism}" ]]
    then
      cp -r loaded-data/${organism} "${GALAXY_SHARED_DIR}/${organism}"
      touch "${GALAXY_SHARED_DIR}/${organism}/refSeqs.json"
    fi
  done
}

function add_organisms(){
  FOUND_ORGANISMS=$(arrow organisms get_organisms | jq '. | length')
  echo "Number of organisms : ${FOUND_ORGANISMS}"
  if [ "$FOUND_ORGANISMS" -le "$NUMBER_ORGANISMS_PER_ORGANISM" ];
  then
    for organism in "${ORGANISMS[@]}" ;
    do
      for org_count in $(seq 1 "${NUMBER_ORGANISMS_PER_ORGANISM}");
      do
        arrow organisms add_organism --genus "Foous${org_count}" --species "barus${organism}" "${organism}${org_count}" "/data/${organism}"
      done
    done
  fi
}



function load_gff3s() {
  FOUND_ORGANISMS_COUNT=$(arrow organisms get_organisms | jq '.[].directory' | uniq | wc -l )
  echo "Found organisms : ${FOUND_ORGANISMS} vs ${#ORGANISMS[@]} ${FOUND_ORGANISMS_COUNT}"
  COMMON_NAMES_STRING=$(arrow organisms get_organisms | jq '.[].commonName'  )

  for organism in "${ORGANISMS[@]}" ;
  do
    COMMON_NAMES=()
    while IFS= read -r line
    do
      echo "adding $line"
      COMMON_NAMES+=($line)
    done < <(arrow organisms get_organisms | jq '.[].commonName' | grep "$organism" )
    echo "Populated genomes [  ${COMMON_NAMES[@]} ] "
#    if [ "$FOUND_ORGANISMS" -eq ${#ORGANISMS[@]} ];
#    then
    echo "Adding genomes for ${organism}"
    for common_name in "${COMMON_NAMES[@]}" ;
    do
        time arrow annotations load_bulk_gff3  ${common_name} "loaded-data/${organism}/raw/${organism}.gff"
    done
#    fi
  done

}


time init
time add_users
time download_organism_data
time prepare_organism_data
time add_organisms
time load_gff3s




