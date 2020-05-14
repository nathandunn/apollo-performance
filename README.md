# apollo-performance
A set of scripts for loading Apollo databases and evaluating their perofrmance

To run this code:

```
python3 -m venv venv
source venv/bin/activate
pip3 install -U pip -r requirements.txt
ARROW_GLOBAL_CONFIG_PATH=`pwd`/test-data/arrow.yml
export ARROW_GLOBAL_CONFIG_PATH
```

Note that there are nubmers are the top of the `load_data.sh` script.  You will need to addjust:

- NUMBER_USERS
- NUMBER_ORGANISMS_PER_ORGANISM
- ORGANISMS 

If a JBrowse folder in loaded-data organism are not present, it is downloaded from https://apollo-jbrowse-data.s3.amazonaws.com/${organism_name}

e.g., 
https://apollo-jbrowse-data.s3.amazonaws.com/yeast.tgz


```
./load_data.sh 
```

