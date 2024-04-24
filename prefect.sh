#!/bin/bash
set -e
set +x

VOLUMES_FOLDER=./volumes
INITIALIZED_MARKER=./volumes/.initialized
LOCAL_ENV_FILE=.env


DOCKER_COMPOSE=docker-compose

# ------------------------------------


function wait_until_postgres_ready() {
    local iterations=0
    local max_iterations=40
    while [ ${iterations} -le ${max_iterations} ]; do
        set +e
        ${DOCKER_COMPOSE} exec postgres bash -c 'pg_isready | grep "accepting connections"' > /dev/null 2>&1
        local ready=$?
        set -e
        if [ ${ready} -eq 0 ]; then
            break
        else
            echo "waiting for postgres to be ready"
            sleep 5
        fi
        (( iterations = iterations + 1 ))
    done
    if [ "${iterations}" -gt ${max_iterations} ]; then
        echo "error starting postgres"
        exit 1
    fi
}


function start_postgres() {
    ${DOCKER_COMPOSE} up -d --force-recreate --no-deps postgres
    wait_until_postgres_ready
    sleep 1
}


function init_environment() {
    # init db
    docker-compose exec postgres /bin/bash -c "
PGPASSWORD=${POSTGRES_PASSWORD} psql --host postgres --username ${POSTGRES_USER} <<-EOSQL
    CREATE DATABASE ${PREFECT_DATABASE};
    GRANT ALL PRIVILEGES ON DATABASE ${PREFECT_DATABASE} TO ${POSTGRES_USER};
EOSQL"
    # start server
    ${DOCKER_COMPOSE} up -d --force-recreate --no-deps --remove-orphans prefect-server
    sleep 5
    docker-compose exec prefect-server /bin/bash -c "
        prefect --no-prompt work-pool create ${PREFECT_WORKER_POOL} --type process;
    "
    # start worker and deploy sample flow
    ${DOCKER_COMPOSE} up -d --force-recreate --no-deps --remove-orphans prefect-worker
    sleep 5
    docker-compose exec prefect-worker /bin/bash -c "
        cd ${PREFECT_FLOWS_PATH};
        prefect --no-prompt deploy --all;
    "
}


function initialize() {
    echo "Environment needs to be initialized...."
    reset
    start_postgres
    init_environment
    touch ${INITIALIZED_MARKER}
    sleep 1
}


function ensure_config() {
    if [ ! -f "./flows/prefect.yaml" ]; then
        eval "echo \"$(cat ./flows/prefect.template.yaml)\"" > ./flows/prefect.yaml
    fi
}


function start() {
    ensure_config
    if [ ! -d ${VOLUMES_FOLDER} ] || [ ! -f ${INITIALIZED_MARKER} ]; then
        ensure_images
        initialize # initialize starts all services
    else
        start_postgres
        ${DOCKER_COMPOSE} up -d --force-recreate prefect-server
        sleep 2
        ${DOCKER_COMPOSE} up -d --force-recreate prefect-worker
        sleep 1
    fi
    status
}


function status() {
    echo ''
    ${DOCKER_COMPOSE} ps
    echo ''
}


function stop() {
    echo ''
    ${DOCKER_COMPOSE} down
    echo ''
}


function reset() {
    echo 'deleting ALL prefect data'
    rm -rf volumes
    echo 'done!'
}


function prepare_environment() {
    if [ -f "${LOCAL_ENV_FILE}" ]; then
        for line in `cat ${LOCAL_ENV_FILE} | grep -v ^#`
        do
            eval "export $line"
        done
    fi
}


function build_prefect_image() {
    local extra_flags=$1
    docker build ${extra_flags} \
        -f ./build/Dockerfile \
        -t ${PREFECT_IMAGE} \
        --build-arg PREFECT_BASE_IMAGE=${PREFECT_BASE_IMAGE} .
}


function ensure_images() {
    local postgres_image_hash=$(docker images -q ${POSTGRES_IMAGE} 2> /dev/null)
    if [ -z "${postgres_image_hash}" ]; then
        ${DOCKER_COMPOSE} pull postgres
    fi
    local prefect_image_hash=$(docker images -q ${PREFECT_IMAGE} 2> /dev/null)
    if [ -z "${prefect_image_hash}" ]; then
        build_prefect_image
    fi
}


# ------------------------------------


ROOT_FOLDER=$(dirname $0)
pushd ${ROOT_FOLDER} > /dev/null 2>&1

prepare_environment

case "$1" in
    "restart")
        stop
        start
        ;;
    "start")
        start
        ;;
    "status")
        status
        ;;
    "stop")
        stop
        ;;
    "reset")
        stop
        reset
        ;;
    "build")
        build_prefect_image "--no-cache"
        ;;
    *)
        echo "Unknown option <$1>. Valid options: [ start, stop, restart, status, reset, build ]"
        exit 1
        ;;
esac

popd > /dev/null 2>&1
