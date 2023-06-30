#!/bin/bash

    docker compose -f docker-compose-locust.yml up -d --build --force-recreate master
    docker compose -f docker-compose-locust.yml up --scale worker=${LOCUST_SCALE}

    # Check files ./locust/prd_locustfile.py and stg_locustfile.py with the message response because it's hardcoded

    if [ "${ENVIRONMENT_NAME}" = "stg"]; then
        export LOCUST_AVERAGE_RESPONSE=4000
        export LOCUST_PERCENTILE_RESPONSE=4000
    elif [ "${ENVIRONMENT_NAME}" = "prd" ]; then
        export LOCUST_AVERAGE_RESPONSE=3000
        export LOCUST_PERCENTILE_RESPONSE=3000
    fi

    echo "Env: ${ENVIRONMENT_NAME}"
    
    export LOCUST_ERROR_RESULT1="Test failed due to failure ratio > 1%"
    export LOCUST_ERROR_RESULT2="Test failed due to average response time ratio > ${LOCUST_AVERAGE_RESPONSE} ms"
    export LOCUST_ERROR_RESULT3="Test failed due to 95th percentile response time > ${LOCUST_PERCENTILE_RESPONSE} ms"

    echo "INFO: ${LOCUST_ERROR_RESULT1}"
    echo "INFO: ${LOCUST_ERROR_RESULT2}"
    echo "INFO: ${LOCUST_ERROR_RESULT3}"


    LOCUST_LOG_RESULT=$(docker logs wp-locust-${ENVIRONMENT_NAME}-master 2>&1 )

    LOCUSTRESULT1=$(echo "${LOCUST_LOG_RESULT}" | grep -oh "${LOCUST_ERROR_RESULT1}" )
    LOCUSTRESULT2=$(echo "${LOCUST_LOG_RESULT}" | grep -oh "${LOCUST_ERROR_RESULT2}" )
    LOCUSTRESULT3=$(echo "${LOCUST_LOG_RESULT}" | grep -oh "${LOCUST_ERROR_RESULT3}" )

    echo "INFO: {LOCUSTRESULT1}"
    echo "INFO: {LOCUSTRESULT2}"
    echo "INFO: {LOCUSTRESULT3}"

    if [ "${LOCUSTRESULT1}" = "${LOCUST_ERROR_RESULT1}" ]; then
        echo "${LOCUST_ERROR_RESULT1}"
        echo "Display log:"
        echo "${LOCUST_LOG_RESULT}"
        exit 1
    elif [ "${LOCUSTRESULT2}" = "${LOCUST_ERROR_RESULT2}" ]; then
        echo "${LOCUST_ERROR_RESULT2}"
        echo "Display log:"
        echo "${LOCUST_LOG_RESULT}"
        exit 1
    elif [ "${LOCUSTRESULT3}" = "${LOCUST_ERROR_RESULT3}" ]; then
        echo "${LOCUST_ERROR_RESULT3}"
        echo "Display log:"
        echo "${LOCUST_LOG_RESULT}"
        exit 1
    else
        echo "Load Test OK"
        echo "Display log:"
        echo "${LOCUST_LOG_RESULT}"
    fi