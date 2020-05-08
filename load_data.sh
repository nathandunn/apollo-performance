#!/bin/bash


NUMBER_USERS=200
NUMBER_ORGANISMS_PER_ORGANISM=20
ORGANISMS=("bee")


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

if ! [[ $SHOULD_LAUNCH_DOCKER -eq 0 ]]; then
  IS_RUNNING=$(docker ps  | grep quay.io/gmod/apollo:latest | wc -l)
  if [[ "$IS_RUNNING" -eq "0" ]]; then
    echo "is not running so starting"
    docker run --memory=4g -d -p 8888:8080 -v `pwd`/apollo_shared_dir/:`pwd`/apollo_shared_dir/ -e "WEBAPOLLO_DEBUG=true" quay.io/gmod/apollo:latest
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

function add_users(){
  echo "adding users using arrow"
#  echo arrow users get_users | jq '. | length'
  FOUND_USERS=$(arrow users get_users | jq '. | length')
  rm -f users.txst
  echo "Number of users : ${FOUND_USERS}"
  if [ "$FOUND_USERS" -le "$NUMBER_USERS" ]
  then
    for user_number in $(seq 1 $NUMBER_USERS);
    do
      arrow users create_user user"${user_number}"@test.com user"${user_number}" lastname"${user_number}" demo --role user
    done
  fi
}


function prepare_organism_data(){
  for organism in "${ORGANISMS[@]}" ; do
    cp -r load-data/${organism}/data/ "${GALAXY_SHARED_DIR}/${organism}"
  done
}

function add_organisms(){
  for organism in "${ORGANISMS[@]}" ;
  do
    for org_count in $(seq 1 "${NUMBER_ORGANISMS_PER_ORGANISM}");
    do
      arrow organisms add_organism --genus "Foo${org_count}" --species "barus${organism}" "${organism}${org_count}" "$GALAXY_SHARED_DIR/${organism}"
    done
  done
}

#function load_gff3s(){
#
#}



time add_users
#time prepare_organism_data
#time add_organisms
#time load_gff3s




