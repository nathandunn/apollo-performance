#!/bin/bash


NUMBER_USERS=200
NUMBER_ORGANISMS_PER_ORGANISM=20
ORGANISMS=("yeast")


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
mkdir -p load-data

if ! [[ $SHOULD_LAUNCH_DOCKER -eq 0 ]]; then
  IS_RUNNING=$(docker ps  | grep quay.io/gmod/apollo:latest | wc -l)
  if [[ "$IS_RUNNING" -eq "0" ]]; then
    echo "is not running so starting"
    docker run --memory=4g -d -p 8888:8080 -v apollo_shared_dir/:/data/ -e "WEBAPOLLO_DEBUG=true" quay.io/gmod/apollo:latest
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
    if [[ ! -d "load-data/${organism}" ]]
    then
      curl -o load-data/${organism}.tgz https://apollo-jbrowse-data.s3.amazonaws.com/${organism}.tgz
      tar xfz load-data/${organism}.tgz -C load-data
    fi
  done
}

function prepare_organism_data(){
  for organism in "${ORGANISMS[@]}" ; do
    if [[ ! -f "${GALAXY_SHARED_DIR}/${organism}" ]]
    then
      cp -r load-data/${organism} "${GALAXY_SHARED_DIR}/${organism}"
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


AGR_ORGANISMS=("RGD" "HUMAN" "WB" "MGI" "ZFIN" "MGI" "FB")
# data URL is here: curl https://fms.alliancegenome.org/api/datafile/by/GFF/ |  jq '.[] | .s3Path' | grep 3.0.0
# data URL is here: curl https://fms.alliancegenome.org/api/datafile/by/VCF/ |  jq '.[] | .s3Path' | grep 3.0.0 # though we don't use that

function get_agr_gff3() {
  for organism in "${AGR_ORGANISMS[@]}" ; do
    echo "curl -o ${organism}.gff http://download.alliancegenome.org/3.0.0/GFF/${organism}/GFF_${organism}_0.gff"
    curl -o ${organism}.gff http://download.alliancegenome.org/3.0.0/GFF/${organism}/GFF_${organism}_0.gff
  done

}



#time add_users
#time download_organism_data
#time prepare_organism_data
#time add_organisms
#time load_gff3s
time get_agr_gff3




