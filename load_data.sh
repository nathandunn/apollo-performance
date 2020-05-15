#!/bin/bash

#pip install ../python-apollo

NUMBER_USERS=2
NUMBER_ORGANISMS_PER_ORGANISM=1
BATCH_SIZE=10
#APOLLO_DATA_DIRECTORY="/data/"
APOLLO_DATA_DIRECTORY="/Users/nathandunn/repositories/apollo-performance/loaded-data/"

#ORGANISMS=("yeast" "fly" "fish" "worm"  "human")
ORGANISMS=("yeast") # broken types
#ORGANISMS=("worm") # works, but will need ot re-adjust he types
#ORGANISMS=("fly") # works , very slow
#ORGANISMS=("fish")
#ORGANISMS=("human")


#alias kill_docker_process="docker ps | tail -1 | cut -c1-15  | xargs docker kill "
#alias login_docker_process="docker exec -it `docker ps | tail -1 | cut -c1-15` /bin/bash  "


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

ARROW_GLOBAL_CONFIG_PATH=`pwd`/test-data/arrow.yml
GALAXY_SHARED_DIR=`pwd`/apollo_shared_dir
export ARROW_GLOBAL_CONFIG_PATH GALAXY_SHARED_DIR
mkdir -p "$GALAXY_SHARED_DIR"
mkdir -p loaded-data

function init(){

  if ! [[ $SHOULD_LAUNCH_DOCKER -eq 0 ]]; then
    IS_RUNNING=$(docker ps  | grep quay.io/gmod/apollo:latest | wc -l)
    if [[ "$IS_RUNNING" -eq "0" ]]; then
      echo "is not running so starting"
      echo "docker run --memory=4g -d -p 8888:8080 -v `pwd`/apollo_shared_dir:$APOLLO_DATA_DIRECTORY quay.io/gmod/apollo:latest"
      docker run --memory=4g -d -p 8888:8080 -v `pwd`/apollo_shared_dir:$APOLLO_DATA_DIRECTORY  quay.io/gmod/apollo:latest
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
        arrow organisms add_organism --genus "Foous${org_count}" --species "barus${organism}" "${organism}${org_count}" "$APOLLO_DATA_DIRECTORY${organism}"
      done
    done
  fi
}



function load_gff3s() {
  FOUND_ORGANISMS_COUNT=$(arrow organisms get_organisms | jq '.[].directory' | uniq | wc -l )
  echo "Found organisms : ${FOUND_ORGANISMS} vs ${#ORGANISMS[@]} ${FOUND_ORGANISMS_COUNT}"
  COMMON_NAMES_STRING=$(arrow organisms get_organisms | jq '.[].commonName'  )
  echo "Common names string ${COMMON_NAMES_STRING}"

  for organism in "${ORGANISMS[@]}" ;
  do
    echo "Add gff3 for ${organism}"
    COMMON_NAMES=()
    while IFS= read -r line
    do
      echo "adding $line"
      COMMON_NAMES+=($line)
    done < <(arrow organisms get_organisms | jq '.[].commonName' | grep "$organism" )
    echo "Common names ${COMMON_NAMES}"
    echo "Populated genomes [  ${COMMON_NAMES[@]} ] "
#    if [ "$FOUND_ORGANISMS" -eq ${#ORGANISMS[@]} ];
#    then
    echo "Adding genomes for ${organism}"
    for common_name in "${COMMON_NAMES[@]}" ;
    do
        time arrow annotations load_gff3  $(eval echo $common_name) --timing --batch_size=${BATCH_SIZE} "loaded-data/${organism}/raw/${organism}.gff"
    done
#    fi
  done

}

function kill_docker_process(){
 docker ps | tail -1 | cut -c1-15  | xargs docker kill
}

time init
time add_users
time download_organism_data
time prepare_organism_data
time add_organisms
time load_gff3s
#time finish_process




