#!/bin/bash

#Script for copying the recommended configuration for Spack onto your system

if [ -z "${SPACK_ROOT}" ]; then
    echo "SPACK_ROOT must be set first"
    exit 1
fi

set -e

OS=$(uname -s)

#Use kind of ridiculous logic to find the machine name
if [ ${OS} == 'Darwin' ]; then
  OSX=$(sw_vers -productVersion)
  case "${OSX}" in
    10.12*)
      MACHINE=mac
    ;;
    10.13*)
      MACHINE=mac
    ;;
    10.14*)
      MACHINE=mac
    ;;
    10.15*)
      MACHINE=mac
    ;;
  esac
elif [ ${OS} == 'Linux' ]; then
  case "${NREL_CLUSTER}" in
    eagle)
      MACHINE=eagle
    ;;
  esac
  case "${NREL_CLUSTER}" in
    ellis)
      MACHINE=ellis
    ;;
  esac
  MYHOSTNAME=$(hostname -s)
  case "${MYHOSTNAME}" in
    rhodes)
      MACHINE=rhodes
    ;;
  esac
fi

# Copy machine-specific configuration for Spack if we recognize the machine
if [ "${MACHINE}" == 'eagle' ] || \
   [ "${MACHINE}" == 'ellis' ] || \
   [ "${MACHINE}" == 'rhodes' ] || \
   [ "${MACHINE}" == 'mac' ]; then

  printf "Machine is detected as ${MACHINE}.\n"

  #Extra stuff for eagle
  if [ ${MACHINE} == 'eagle' ] || [ ${MACHINE} == 'rhodes' ] || [ ${MACHINE} == 'ellis' ]; then
    OS=linux
  elif [ "${MACHINE}" == 'mac' ]; then
    OS=darwin
  fi

  THIS_REPO_DIR=..

  #All machines do this
  (set -x; mkdir -p ${SPACK_ROOT}/etc/spack/${OS})
  (set -x; cp ${THIS_REPO_DIR}/configs/base/*.yaml ${SPACK_ROOT}/etc/spack/)
  (set -x; cp ${THIS_REPO_DIR}/configs/${MACHINE}/packages.yaml ${SPACK_ROOT}/etc/spack/${OS}/)
  (set -x; cp ${THIS_REPO_DIR}/configs/${MACHINE}/config.yaml ${SPACK_ROOT}/etc/spack/${OS}/)
  (set -x; cp -R ${THIS_REPO_DIR}/custom ${SPACK_ROOT}/var/spack/repos/)

  if [ "${MACHINE}" != 'mac' ]; then
    (set -x; cp ${THIS_REPO_DIR}/configs/${MACHINE}/software/compilers.yaml ${SPACK_ROOT}/etc/spack/)
    (set -x; cp ${THIS_REPO_DIR}/configs/${MACHINE}/software/modules.yaml ${SPACK_ROOT}/etc/spack/)
    (set -x; cp ${THIS_REPO_DIR}/configs/${MACHINE}/user/upstreams.yaml ${SPACK_ROOT}/etc/spack/)
  fi

else
  printf "\nMachine name not found.\n"
fi

