#!/bin/sh

REPOSITORY=${GITHUB_REPOSITORY}
USERNAME=${USERNAME:-$GITHUB_ACTOR}
REPONAME=$(echo "${REPOSITORY}" | cut -d'/' -f2)

_error() {
  echo -e "$1"
  exit 1
}

_error_check() {
  RESULT=$?

  if [ ${RESULT} != 0 ]; then
    _error ${RESULT}
  fi
}

_docker_tag() {
  if [ -z "${TAG_NAME}" ]; then
    if [ -f ./target/TAG_NAME ]; then
      TAG_NAME=$(cat ./target/TAG_NAME | xargs)
    elif [ -f ./target/VERSION ]; then
      TAG_NAME=$(cat ./target/VERSION | xargs)
    elif [ -f ./VERSION ]; then
      TAG_NAME=$(cat ./VERSION | xargs)
    fi
    if [ -z "${TAG_NAME}" ]; then
      TAG_NAME="latest"
    fi
  fi
  if [ ! -z "${TAG_POST}" ]; then
    TAG_NAME="${TAG_NAME}-${TAG_POST}"
  fi
}

_docker_build() {
  echo "docker build ${DOCKER_BUILD_ARGS} -t ${IMAGE_URI}:${TAG_NAME} ${BUILD_PATH} -f ${DOCKERFILE}"
  docker build ${DOCKER_BUILD_ARGS} -t ${IMAGE_URI}:${TAG_NAME} ${BUILD_PATH} -f ${DOCKERFILE}

  _error_check
}


_docker_push() {
  if [ "${DOCKERPUSH}" == "true" ]; then
     echo "docker push ${IMAGE_URI}:${TAG_NAME}"
     docker push ${IMAGE_URI}:${TAG_NAME}

     _error_check

     if [ "${LATEST}" == "true" ]; then
       echo "docker tag ${IMAGE_URI}:latest"
       docker tag ${IMAGE_URI}:${TAG_NAME} ${IMAGE_URI}:latest

       echo "docker push ${IMAGE_URI}:latest"
       docker push ${IMAGE_URI}:latest
     fi
  fi
}

_docker_pre() {
  if [ -z "${USERNAME}" ]; then
    _error "USERNAME is not set."
  fi

  if [ -z "${PASSWORD}" ]; then
    _error "PASSWORD is not set."
  fi

  if [ -z "${BUILD_PATH}" ]; then
    BUILD_PATH="."
  fi

  if [ -z "${DOCKERFILE}" ]; then
    DOCKERFILE="Dockerfile"
  fi

  if [ -z "${IMAGE_URI}" ]; then
    if [ -z "${REGISTRY}" ]; then
      REGISTRY="docker.pkg.github.com"
    fi

    if [ "${REGISTRY}" == "docker.pkg.github.com" ]; then
      IMAGE_URI="${REGISTRY}/${REPOSITORY}/${IMAGE_NAME:-${REPONAME}}"
    else
      IMAGE_URI="${REGISTRY}/${IMAGE_NAME:-${REPOSITORY}}"
    fi
  fi

  _docker_tag
}

_docker_login() {
  echo "docker login ${REGISTRY} -u ${USERNAME}"
  echo ${PASSWORD} | docker login ${REGISTRY} -u ${USERNAME} --password-stdin

}

_docker_logout() {
  docker logout
}

_docker() {
  _docker_pre
  _docker_login
  _error_check
  _docker_build
  _docker_push
  _docker_logout
}

_docker

echo ::set-output name=TAG_NAME::${TAG_NAME}
