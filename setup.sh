#!/usr/bin/env zsh
[[ -d venv ]] || python3 -m venv venv
source venv/bin/activate
pip3 install -U pip -r requirements.txt

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

export ARROW_GLOBAL_CONFIG_PATH=`pwd`/test-data/arrow.yml
for ((i=0;i<30;i++))
do
   APOLLO_UP=$(arrow users get_users 2> /dev/null | head -1 | grep '^\[$' -q; echo "$?")
	if [[ $APOLLO_UP -eq 0 ]]; then
	  echo "Apollo came up"
		break
	fi
	  echo "Checking Apollo"
    sleep 10
done

echo "Apollo is running ${APOLLO_UP}"

python setup.py nosetests
killall java || true



