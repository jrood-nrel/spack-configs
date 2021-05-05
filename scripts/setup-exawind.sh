#!/bin/bash

#Script for setting up Exawind environment in Spack

# Function for printing and executing commands
cmd() {
  echo "+ $@"
  eval "$@"
}

THIS_REPO_DIR=..

#Might want to do these first erase steps to start fresh
cmd "ls ${HOME}/spack && rm -rf ${HOME}/spack"
set -e
cmd "git clone https://github.com/spack/spack.git ${HOME}/spack && export SPACK_ROOT=${HOME}/spack"

#Can start here if spack is already cloned
set +e
cmd "ls ${HOME}/.spack && rm -rf ${HOME}/.spack"
set -e
if [ -z "${SPACK_ROOT}" ]; then
    echo "SPACK_ROOT must be set first"
    exit 1
fi
cmd "cp -R ${THIS_REPO_DIR}/custom ${SPACK_ROOT}/var/spack/repos/"
cmd "source ${SPACK_ROOT}/share/spack/setup-env.sh"
cmd "spack compilers"
cmd "spack env create exawind ${THIS_REPO_DIR}/envs/exawind/spack.yaml"
cmd "spack env activate exawind"
cmd "spack concretize -f"
cmd "spack install"

#Do this to setup spack develop
#cmd "mkdir -p ${HOME}/exawind/exawind-env && cd ${HOME}/exawind/exawind-env && spack develop nalu-wind@master"
#cmd "spack install" #To rebuild nalu-wind from local source
