#!/bin/bash

DIR=`dirname $0`
CONSUL_BACKUP="${DIR}/consul-kv-backup"

function test_variables () {

    echo 'Testing required variables'

    if [ -z "$CONSUL_HOST" ] || [ -z "$CONSUL_PORT" ] || [ -z "$ENVIROMENT" ] 
    then
        echo 'Is mandatory declare this variables: CONSUL_HOST CONSUL_PORT ENVIROMENT'
        exit 1
    fi

    if [ -z "$SECONDS_WAIT" ]
    then
        echo 'SECONDS_WAIT is set to default: 3600( 1 hour )'
        export SECONDS_WAIT=86400
    fi

    if [ -z "$GIT_URL" ]
    then
        echo 'Is mandatory declare git url in GIT_URL'
        exit 1
    fi

    if [ ! -z "$GIT_USER_NAME" ] && [ ! -z "$GIT_USER_EMAIL" ]
    then
        git config --global user.name "$GIT_USER_NAME"
        git config --global user.email "$GIT_USER_EMAIL"
    fi

    git config --global http.sslVerify "false"
        
    MESSAGE="[consul-kv-exporter] Automatically checking status changes enviroment: ${ENVIROMENT}"

    echo "################################################"
    echo "#  DIR:.................: ${DIR}"
    echo "#  CONSUL_HOST:.........: ${CONSUL_HOST}"
    echo "#  CONSUL_PORT:.........: ${CONSUL_PORT}"
    echo "#  ENVIROMENT:..........: ${ENVIROMENT}"
    echo "#  SECONDS_WAIT:........: ${SECONDS_WAIT}"
    echo "#  GIT_URL:.............: ${GIT_URL}"
    echo "#  GIT_USER_NAME:.......: ${GIT_USER_NAME}"
    echo "#  GIT_USER_EMAIL:......: ${GIT_USER_EMAIL}"
    echo "#  MESSAGE:.............: ${MESSAGE}"
    echo "################################################"

}

function export_consul_kv()  {

    echo "################################################"
    echo "# Start exporter..."
    echo "################################################"

    echo "Cloning..."
    git clone $GIT_URL
    export PROJECT=`echo $GIT_URL | sed -e 's/.*\///g' | cut -d'.' -f1`
    
    echo "Switch to dir: ${DIR}/${PROJECT}"
    cd "${DIR}/${PROJECT}"

    echo "Removing old file"
    rm -f "${ENVIROMENT}.json" 2> /dev/null

    echo "${CONSUL_BACKUP} --addr ${CONSUL_HOST} --port ${CONSUL_PORT}  backup > \"${ENVIROMENT}.json\""
    ${CONSUL_BACKUP} --addr ${CONSUL_HOST} --port ${CONSUL_PORT}  backup > "${ENVIROMENT}.json"
   
    cat ${ENVIROMENT}.json

    echo "git adding changes"
    git add .

    echo "git commit and push (if necessary)"
    git commit -m "${MESSAGE}" && git push

    echo "Removing project dir"
    cd ${DIR}
    rm -rf $PROJETO 2> /dev/null

}

cat << "EOF"

#####################################
### CONSUL KV EXPORTER
#####################################

EOF

test_variables

while :
do
	export_consul_kv
    echo "Waiting ${SECONDS_WAIT} seconds..."
	sleep $SECONDS_WAIT
done




