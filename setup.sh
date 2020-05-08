#!/usr/bin/env zsh
[[ -d venv ]] || python3 -m venv venv
source venv/bin/activate
pip3 install -U pip -r requirements.txt
ARROW_GLOBAL_CONFIG_PATH=`pwd`/test-data/arrow.yml
export ARROW_GLOBAL_CONFIG_PATH
