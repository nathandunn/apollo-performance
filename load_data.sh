#!/usr/bin/env zsh


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
  arrow users get_users

for user_number in {1..200}
do
  arrow users create_user user${user_number}@test.com user${user_number} lastname${user_number} demo --role user
done
}

time addusers

killall java || true



