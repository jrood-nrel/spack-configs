#!/bin/bash -l

# Script for installation of HPACF group related compilers, utilities, and software on Eagle and Rhodes.
# The idea of this script requires running each TYPE stage and manually intervening after stage to set
# up for the next stage by editing the yaml files used in the next stage.

#SBATCH -J build-modules
#SBATCH -o %x.o%j
#SBATCH -t 04:00:00
#SBATCH -N 1
#SBATCH -p short
#SBATCH -A hpcapps

#TYPE=base
#TYPE=compilers
#TYPE=utilities
TYPE=software

DATE=2022-10

set -e

# Function for printing and executing commands
cmd() {
  echo "+ $@";
  eval "$@";
}

printf "============================================================\n"
printf "$(date)\n"
printf "============================================================\n"
printf "Job is running on ${HOSTNAME}\n"
printf "============================================================\n"

# Find machine we're on
case "${NREL_CLUSTER}" in
  eagle)
    MACHINE=eagle
  ;;
esac
MYHOSTNAME=$(hostname -s)
case "${MYHOSTNAME}" in
  rhodes)
    MACHINE=rhodes
  ;;
esac
case "${NREL_CLUSTER}" in
  ellis)
    MACHINE=ellis
  ;;
esac

if [ "${MACHINE}" == 'eagle' ]; then
  BASE_DIR=/nopt/nrel/ecom/hpacf
elif [ "${MACHINE}" == 'rhodes' ]; then
  BASE_DIR=/opt
elif [ "${MACHINE}" == 'ellis' ]; then
  BASE_DIR=/projects/hpacf/apps
else
  printf "\nMachine name not recognized.\n"
  exit 1
fi

INSTALL_DIR=${BASE_DIR}/${TYPE}/${DATE}

if [ "${TYPE}" == 'base' ]; then
  GCC_COMPILER_VERSION=4.8.5
  if [ "${MACHINE}" == 'eagle' ]; then
    CPU_OPT=haswell
    HOST_OS=centos7
  elif [ "${MACHINE}" == 'rhodes' ]; then
    CPU_OPT=haswell
    HOST_OS=centos7
  elif [ "${MACHINE}" == 'ellis' ]; then
    CPU_OPT=zen
    HOST_OS=rocky8
    GCC_COMPILER_VERSION=8.5.0
  fi
elif [ "${TYPE}" == 'compilers' ] || [ "${TYPE}" == 'utilities' ] || [ "${TYPE}" == 'software' ]; then
  GCC_COMPILER_VERSION=8.5.0
  if [ "${MACHINE}" == 'eagle' ]; then
    HOST_OS=centos7
    CPU_OPT=skylake_avx512
  elif [ "${MACHINE}" == 'rhodes' ]; then
    HOST_OS=centos7
    CPU_OPT=broadwell
  elif [ "${MACHINE}" == 'ellis' ]; then
    CPU_OPT=zen
    HOST_OS=rocky8
  fi
fi

GCC_COMPILER_MODULE=gcc/${GCC_COMPILER_VERSION}
INTEL_COMPILER_VERSION=20.0.4
INTEL_COMPILER_MODULE=intel-parallel-studio/cluster.2020.4
CLANG_COMPILER_VERSION=15.0.2
CLANG_COMPILER_MODULE=llvm/${CLANG_COMPILER_VERSION}

THIS_REPO_DIR=$(pwd)/..

# Set spack location
export SPACK_ROOT=${INSTALL_DIR}/spack
export SPACK_DISABLE_LOCAL_CONFIG=true
export SPACK_USER_CACHE_PATH=${SPACK_ROOT}/var/spack/user_cache
export SPACK_USER_CONFIG_PATH=${SPACK_ROOT}/var/spack/user_config

if [ ! -d "${INSTALL_DIR}" ]; then
  printf "============================================================\n"
  printf "Install directory doesn't exist.\n"
  printf "Creating everything from scratch...\n"
  printf "============================================================\n"

  printf "Creating top level install directory...\n"
  cmd "mkdir -p ${INSTALL_DIR}"

  printf "\nCloning Spack repo...\n"
  cmd "git clone https://github.com/spack/spack.git ${SPACK_ROOT}"
  cmd "cd ${SPACK_ROOT} && git checkout 560a9eec920e1fba3d334c6506d193aa8d9cb098 && cd -"

  printf "\nConfiguring Spack...\n"
  cmd "cd ${THIS_REPO_DIR}/scripts && ./setup-spack.sh"
  cmd "cp ${THIS_REPO_DIR}/configs/${MACHINE}/${TYPE}/compilers.yaml ${SPACK_ROOT}/etc/spack/"
  cmd "cp ${THIS_REPO_DIR}/configs/${MACHINE}/${TYPE}/modules.yaml ${SPACK_ROOT}/etc/spack/"
  cmd "cp ${THIS_REPO_DIR}/configs/${MACHINE}/${TYPE}/upstreams.yaml ${SPACK_ROOT}/etc/spack/ || true"
  if [ "${TYPE}" == 'compilers' ] || [ "${TYPE}" == 'base' ]; then
    cmd "rm -f ${SPACK_ROOT}/etc/spack/upstreams.yaml || true"
  fi
  cmd "mkdir -p ${SPACK_ROOT}/etc/spack/licenses/intel"
  if [ "${MACHINE}" != 'ellis' ]; then
    cmd "cp ${HOME}/save/license.lic ${SPACK_ROOT}/etc/spack/licenses/intel/"
  fi
  cmd "source ${SPACK_ROOT}/share/spack/setup-env.sh"
  cmd "spack env create ${TYPE}"
  cmd "cp ${THIS_REPO_DIR}/configs/${MACHINE}/${TYPE}/spack.yaml ${SPACK_ROOT}/var/spack/environments/${TYPE}/spack.yaml"

  printf "============================================================\n"
  printf "Done setting up install directory.\n"
  printf "============================================================\n"
else
  printf "\nLoading Spack...\n"
  cmd "source ${SPACK_ROOT}/share/spack/setup-env.sh"
fi

#printf "\nLoading modules...\n"
cmd "module purge"
cmd "module unuse ${MODULEPATH}"
if [ "${TYPE}" != 'software' ]; then
  cmd "module use ${BASE_DIR}/compilers/modules"
  cmd "module use ${BASE_DIR}/utilities/modules"
elif [ "${TYPE}" == 'software' ]; then
  cmd "module use ${BASE_DIR}/compilers/modules-${DATE}"
  cmd "module use ${BASE_DIR}/utilities/modules-${DATE}"
fi
cmd "module load binutils"
#cmd "module load bison bzip2 binutils curl git python texinfo unzip wget"
## Can't always load flex or texlive or some things fail
#if [ "${TYPE}" == 'utilities' ]; then
#  cmd "module load flex texlive"
#elif [ "${TYPE}" == 'software' ]; then
#  cmd "module load gcc"
#fi

cmd "source ${SPACK_ROOT}/share/spack/setup-env.sh"
cmd "spack compilers"
cmd "spack arch"

if [ "${MACHINE}" == 'eagle' ]; then
  printf "\nMaking and setting TMPDIR to disk...\n"
  cmd "mkdir -p /scratch/${USER}/.tmp"
  cmd "export TMPDIR=/scratch/${USER}/.tmp"
fi

printf "\nInstalling ${TYPE}...\n"

cmd "spack env activate ${TYPE}"
#cmd "spack concretize -f --fresh"
#for i in {1..8}; do
  #cmd "spack install --deprecated --fresh" #&
#done
#wait
cmd "spack module tcl refresh -y"

printf "\nDone installing ${TYPE} at $(date).\n"

printf "\nCreating dated modules symlink...\n"
#if [ "${TYPE}" != 'software' ]; then
#cmd "cd ${INSTALL_DIR}/.. && ln -sf ${DATE}/spack/share/spack/modules/linux-${HOST_OS}-${CPU_OPT}/gcc-${GCC_COMPILER_VERSION} modules-${DATE} && cd -"
#cmd "cd ${INSTALL_DIR}/.. && ln -sf ${DATE}/spack/share/spack/modules/linux-${HOST_OS}-${CPU_OPT}/gcc-${GCC_COMPILER_VERSION} modules && cd -"
cmd "cd ${INSTALL_DIR}/.. && ln -sf ${DATE}/spack/share/spack/modules/linux-${HOST_OS}-zen2 modules-${DATE} && cd -"
cmd "cd ${INSTALL_DIR}/.. && ln -sf ${DATE}/spack/share/spack/modules/linux-${HOST_OS}-zen2 modules && cd -"
#fi

#printf "\nSetting permissions...\n"
#if [ "${MACHINE}" == 'eagle' ]; then
#  # Need to create a blank .version for name/version splitting for lmod
#  cd ${INSTALL_DIR}/${DATE}/share/spack/modules/linux-${HOST_OS}-${CPU_OPT}/gcc-${GCC_COMPILER_VERSION} && find . -mindepth 1 -maxdepth 1 -type d -print0 | xargs -0 -I % touch %/.version
#  if [ "${TYPE}" == 'software' ]; then
#    cd ${INSTALL_DIR}/${DATE}/share/spack/modules/linux-${HOST_OS}-${CPU_OPT}/intel-${INTEL_COMPILER_VERSION} && find . -mindepth 1 -maxdepth 1 -type d -print0 | xargs -0 -I % touch %/.version
#    cd ${INSTALL_DIR}/${DATE}/share/spack/modules/linux-${HOST_OS}-${CPU_OPT}/clang-${CLANG_COMPILER_VERSION} && find . -mindepth 1 -maxdepth 1 -type d -print0 | xargs -0 -I % touch %/.version
#  fi
#  cmd "nice -n 19 ionice -c 3 chmod -R a+rX,go-w ${INSTALL_DIR}"
#  cmd "nice -n 19 ionice -c 3 chgrp -R n-ecom ${INSTALL_DIR}"
#elif [ "${MACHINE}" == 'rhodes' ]; then
#  cmd "nice -n 19 ionice -c 3 chgrp windsim /opt"
#  cmd "nice -n 19 ionice -c 3 chgrp windsim /opt/${TYPE}"
#  cmd "nice -n 19 ionice -c 3 chgrp -R windsim ${INSTALL_DIR}"
#  cmd "nice -n 19 ionice -c 3 chmod a+rX,go-w /opt"
#  cmd "nice -n 19 ionice -c 3 chmod a+rX,go-w /opt/${TYPE}"
#  cmd "nice -n 19 ionice -c 3 chmod -R a+rX,go-w ${INSTALL_DIR}"
#fi

printf "\n$(date)\n"
printf "\nDone!\n"

# Some other info:
# Edit software/compilers.yaml to point to all compilers this script installed in the compilers build phase
# Run makelocalrc for all PGI compilers (I think this sets a GCC to use as a frontend)
# I did something like:
# makelocalrc -gcc /nopt/nrel/ecom/hpacf/compilers/2019-05-08/spack/opt/spack/linux-centos7-x86_64/gcc-4.8.5/gcc-7.4.0-srw2azby5tn7wozbchryvj5ak3zlfz3r/bin/gcc -gpp /nopt/nrel/ecom/hpacf/compilers/2019-05-08/spack/opt/spack/linux-centos7-x86_64/gcc-4.8.5/gcc-7.4.0-srw2azby5tn7wozbchryvj5ak3zlfz3r/bin/g++ -g77 /nopt/nrel/ecom/hpacf/compilers/2019-05-08/spack/opt/spack/linux-centos7-x86_64/gcc-4.8.5/gcc-7.4.0-srw2azby5tn7wozbchryvj5ak3zlfz3r/bin/gfortran -x
# Add set PREOPTIONS=-D__GCC_ATOMIC_TEST_AND_SET_TRUEVAL=1; to localrc

# Other final manual customizations:
# - Rename necessary module files and set defaults
