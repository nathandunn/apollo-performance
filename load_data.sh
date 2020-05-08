#!/usr/bin/env zsh


NUMBER_USERS=200
NUMBER_ORGS=200

ARROW_GLOBAL_CONFIG_PATH=`pwd`/test-data/arrow.yml
export ARROW_GLOBAL_CONFIG_PATH

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

if ! [[ $SHOULD_LAUNCH_DOCKER -eq 0 ]]; then
  docker run --memory=4g -d -p 8888:8080  quay.io/gmod/apollo:latest
#    docker run --memory=4g -d -p 8888:8080 -v `pwd`/apollo_shared_dir/:`pwd`/apollo_shared_dir/ -e "WEBAPOLLO_DEBUG=true" quay.io/gmod/apollo:latest
#docker run -p 8888:8080 gmod/apollo:latest
#docker run --memory=4g -d -p 8888:8080 -v `pwd`/apollo_shared_dir/:`pwd`/apollo_shared_dir/ -e "WEBAPOLLO_DEBUG=true" quay.io/gmod/apollo:latest
fi

for ((i=0;i<30;i++))
do
	  echo "Checking Apollo"
   APOLLO_UP=$(arrow users get_users 2> /dev/null | head -1 | grep '^\[$' -q; echo "$?")
	if [[ $APOLLO_UP -eq 0 ]]; then
	  echo "Apollo came up"
		break
	fi
    echo "Not up yet"
    sleep 10
done

echo "Apollo is running ${APOLLO_UP}"

python setup.py nosetests

function addusers(){
  echo "adding users using arrow"
#  echo arrow users get_users | jq '. | length'
  arrow users get_users | jq '. | length' 2>&1 > users.txt
  VALUE=`cat users.txt`
  rm -f users.txst
  echo "Number of users : ${VALUE}"
  if [ "$VALUE" -le "$NUMBER_USERS" ]
  then
    for user_number in {1..$NUMBER_USERS}
    do
      arrow users create_user user${user_number}@test.com user${user_number} lastname${user_number} demo --role user
    done
  fi

}

time addusers

killall java || true



