#!/bin/bash
set -eu

PROG_NAME=$(basename $0)
PROG_DIR=$(cd $(dirname $0) && pwd)
IMAGE_NAME=react_dev
CONTAINER_PREFIX=react_dev
BUILD_DIR=$PROG_DIR/build
APPLICATION_BASEDIR=$PROG_DIR/apps
LOG_LEVEL=1

# log: Print messages to stderr when $level is equal or greater than $LOG_LEVEL
# Args:
#   $1 (`level`): Logging level. Higher value indicates the message is more important.
function log () {
  local level=$1
  shift
  if [ $level -ge $LOG_LEVEL ]; then
    echo -e "$PROG_NAME: $@" 1>&2
  fi
}

# debug: Log message with level 0
function debug () {
  log 0 "[DEBUG]" "$@"
}

# info: Log message with level 1
function info () {
  log 1 "[INFO]" "$@"
}

# warn: Log message with level 2
function warn () {
  log 2 "[WARN]" "$@"
}

# error: Log message with level 3
function error () {
  log 3 "[ERROR]" "$@"
}

# error_exit: Show error message and exit this script with $error_code
# Args:
#   $1: message
#   $2: exit_code (default 1)
function error_exit () {
  set +u
  local message=$1
  local exit_code=$2
  set -u
  if [ ! -z "$message" ]; then
    error $message
  fi
  if [ -z "$exit_code" ]; then
    exit_code=1
  fi
  exit $exit_code
}

# container_exists: Check whether Docker container named $name
# Args:
#   $1 (name): container name
# Return: 0 (when the image already exists)
#         other (otherwise)
function container_exists () {
  local name=$1
  set +e
  local exists=1
  if [ "$(docker ps -af "name=$name" | wc -l)" -gt 1 ]; then
    exists=0
  fi
  set -e
  if [ "$exists" = 0 ]; then
    debug "Container $name already exists."
  else
    debug "Container $name does not exists."
  fi
  return $exists
}

# image_exists: Check whether Docker image named $IMAGE_NAME
# Return: 0 (when the image already exists)
#         other (otherwise)
function image_exists () {
  set +e
  docker images | grep "^$IMAGE_NAME " >/dev/null
  local exists=$?
  set -e
  if [ "$exists" = 0 ]; then
    debug "Image $IMAGE_NAME already exists."
  else
    debug "Image $IMAGE_NAME does not exists."
  fi
  return $exists
}

function get_container_name () {
  local application_name=$1
  echo ${CONTAINER_PREFIX}_$application_name
}

function get_application_dir () {
  local application_name=$1
  echo $APPLICATION_BASEDIR/$application_name
}

# build: Build Dockerfile in $BUILD_DIR as $IMAGE_NAME
function build () {
  if ! image_exists; then
    set +e
    __tmp=$(docker build -t $IMAGE_NAME $BUILD_DIR 2>&1)
    local success=$?
    local result=$__tmp
    unset __tmp
    set -e
    if [ "$success" = 0 ]; then
      info "Build completed:\n$result"
    else
      error_exit "Build failed:\n$result"
    fi
  else
    info "Docker image $IMAGE_NAME already exists."
  fi
}

# create: Create a new application
# Args:
#   $1 (application_name): Directory name to be created
function create () {
  debug "functioon create() starts"
  set +u
  local application_name=$1
  set -u
  if [ -z "$application_name" ]; then
    error_exit "create command need 1 argument (application name)"
  fi

  if [ ! -d "$APPLICATION_BASEDIR" ]; then
    mkdir -p "$APPLICATION_BASEDIR"
    debug "Applications directory created: $APPLICATION_BASEDIR"
  fi

  local application_dir=$(get_application_dir "$application_name")
  if [ -d "$application_dir" ]; then
    error_exit "Directory '$application_dir' already exists. Stop."
  fi

  if ! image_exists; then
    info "Image not found. Build Docker image before create your application ($application_name). Please wait..."
    build
  fi

  debug "Run create-react-app"
  docker run --rm -u $(id -u):$(id -g) -v $APPLICATION_BASEDIR:/opt/app $IMAGE_NAME \
    create-react-app "$application_name"
}

# install_modules: Install modules in the application directory
# Args:
#   $1 (application_name): Application to install modules
function install_modules () {
  debug "function install_modules() starts"
  set +u
  local application_name=$1
  set -u
  if [ -z " $application_name" ]; then
    error_exit "install_modules command needs 1 argumens (application name)"
  fi

  local application_dir=$(get_application_dir "$application_name")
  if [ ! -d "$application_dir" ]; then
    error_exit "Application directory does not exist. Stop."
  fi
  if [ ! -f "$application_dir/package.json" ]; then
    error_exit "package.json does not exist in the application directory. Stop."
  fi

  if ! image_exists; then
    info "Image not found. Build Docker image before create your application ($application_name). Please wait..."
    build
  fi

  debug "Run npm install"
  docker run --rm -u $(id -u):$(id -g) -v $application_dir:/opt/app $IMAGE_NAME \
    npm install
}

# run: Create Docker container and start application
# Args:
#   $1 (application_name): Application name
#   $2 (port): A port to open (default: 3000)
#   $@ (options): Options for `docker run` command
function run_app () {
  debug "function run() starts"
  set +eu
  local application_name=$1
  shift
  local port=$1
  shift
  local options="$@"
  set -eu

  if [ -z "$port" ]; then
    port=3000
  fi

  local port_option="-p $port:3000"
  if [ $port = 0 ]; then
    port_option=""
  fi

  local application_dir=$APPLICATION_BASEDIR/$application_name
  local container_name=$(get_container_name $application_name)

  if [ -z "$application_name" ]; then
    error_exit "create command need 1 argument (application name)"
  fi

  if ! image_exists; then
    info "Image not found. Build Docker image before create your application ($application_name). Please wait..."
    build
  fi

  if [ ! -d "$application_dir" ]; then
    create "$application_name"
  fi
  if [ ! -d "$application_dir/node_modules" ]; then
    install_modules "$application_name"
  fi

  if container_exists $container_name; then
    info "Remove existing cointainer '$container_name'"
    docker rm -f $container_name >/dev/null 2>&1
  fi

  debug "Run application"
  docker run --name $container_name -u $(id -u):$(id -g)\
    -v $application_dir:/opt/app $port_option $options $IMAGE_NAME npm start
}

function stop_app () {
  local application_name=$1
  local container_name=$(get_container_name $application_name)
  if container_exists $container_name; then
    info "Stoppng container $container_name..."
    docker stop $container_name
  else
    warn "Container $container_name does not exist."
  fi
}

function main () {
  # Call function by first argument (sub-command)
  set +u
  local sub_command=$1
  set -u +e
  shift
  set -e
  case "$sub_command" in
    'build')
      build "$@"
      ;;
    'create')
      create "$@"
      ;;
    'install|install_modules')
      install_modules "$@"
      ;;
    'run'|'start')
      run_app "$@"
      ;;
    'stop')
      stop_app "$@"
      ;;
    '')
      error_exit "No sub-command specified."
      ;;
    *)
      error_exit "No such sub-command: $sub_command"
      ;;
  esac
}

main "$@"

