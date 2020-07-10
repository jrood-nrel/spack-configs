#!/bin/bash -l

# Script for installation of HPACF group related compilers, utilities, and software on Eagle and Rhodes.
# The idea of this script requires running each TYPE stage and manually intervening after stage to set
# up for the next stage by editing the yaml files used in the next stage.

#TYPE=base
TYPE=compilers
#TYPE=utilities
#TYPE=software

DATE=2020-07

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

if [ "${MACHINE}" == 'eagle' ]; then
  BASE_DIR=/nopt/nrel/ecom/hpacf
elif [ "${MACHINE}" == 'rhodes' ]; then
  BASE_DIR=/opt
else
  printf "\nMachine name not recognized.\n"
  exit 1
fi

INSTALL_DIR=${BASE_DIR}/${TYPE}/${DATE}

if [ "${TYPE}" == 'base' ]; then
  GCC_COMPILER_VERSION=4.8.5
  CPU_OPT=haswell
elif [ "${TYPE}" == 'compilers' ] || [ "${TYPE}" == 'utilities' ] || [ "${TYPE}" == 'software' ]; then
  GCC_COMPILER_VERSION=9.3.0
  CPU_OPT=broadwell
fi
GCC_COMPILER_MODULE=gcc/${GCC_COMPILER_VERSION}
INTEL_COMPILER_VERSION=19.0.5
INTEL_COMPILER_MODULE=intel-parallel-studio/cluster.2019.5
CLANG_COMPILER_VERSION=10.0.0
CLANG_COMPILER_MODULE=llvm/${CLANG_COMPILER_VERSION}

THIS_REPO_DIR=$(pwd)/..

# Set spack location
export SPACK_ROOT=${INSTALL_DIR}/spack

if [ ! -d "${INSTALL_DIR}" ]; then
  printf "============================================================\n"
  printf "Install directory doesn't exist.\n"
  printf "Creating everything from scratch...\n"
  printf "============================================================\n"

  printf "Creating top level install directory...\n"
  cmd "mkdir -p ${INSTALL_DIR}"

  printf "\nCloning Spack repo...\n"
  cmd "git clone https://github.com/spack/spack.git ${SPACK_ROOT}"

  printf "\nConfiguring Spack...\n"
  cmd "cd ${THIS_REPO_DIR}/scripts && ./setup-spack.sh"
  cmd "cp ${THIS_REPO_DIR}/configs/${MACHINE}/${TYPE}/compilers.yaml ${SPACK_ROOT}/etc/spack/"
  cmd "cp ${THIS_REPO_DIR}/configs/${MACHINE}/${TYPE}/modules.yaml ${SPACK_ROOT}/etc/spack/"
  if [ "${TYPE}" == 'utilities' ]; then
    cmd "cp ${THIS_REPO_DIR}/configs/${MACHINE}/${TYPE}/upstreams.yaml ${SPACK_ROOT}/etc/spack/"
  fi
  cmd "mkdir -p ${SPACK_ROOT}/etc/spack/licenses/intel"
  cmd "cp ${HOME}/save/license.lic ${SPACK_ROOT}/etc/spack/licenses/intel/"
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

printf "\nLoading modules...\n"
cmd "module purge"
cmd "module unuse ${MODULEPATH}"
cmd "module use ${BASE_DIR}/utilities/modules"
for MODULE in unzip patch bzip2 cmake git texinfo bison wget bc python; do
  cmd "module load ${MODULE}"
done
if [ "${TYPE}" == 'compilers' ] || [ "${TYPE}" == 'utilities' ]; then
  cmd "module use ${BASE_DIR}/base/modules-${DATE}"
  cmd "module load ${GCC_COMPILER_MODULE}"
elif [ "${TYPE}" == 'software' ]; then
  cmd "module use ${BASE_DIR}/compilers/modules-${DATE}"
  cmd "module load ${GCC_COMPILER_MODULE}"
  cmd "module load ${INTEL_COMPILER_MODULE}"
  cmd "module load ${CLANG_COMPILER_MODULE}"
fi

cmd "source ${SPACK_ROOT}/share/spack/setup-env.sh"

if [ "${MACHINE}" == 'eagle' ]; then
  printf "\nMaking and setting TMPDIR to disk...\n"
  cmd "mkdir -p /scratch/${USER}/.tmp"
  cmd "export TMPDIR=/scratch/${USER}/.tmp"
fi

printf "\nInstalling ${TYPE}...\n"

cmd "spack env activate ${TYPE}"
cmd "spack install"

printf "\nDone installing ${TYPE} at $(date).\n"

printf "\nSetting permissions...\n"
if [ "${MACHINE}" == 'eagle' ]; then
  cmd "chmod -R a+rX,go-w ${INSTALL_DIR}"
  cmd "chgrp -R n-ecom ${INSTALL_DIR}"
elif [ "${MACHINE}" == 'rhodes' ]; then
  if [ "${TYPE}" != 'software' ]; then
    cmd "cd /opt/${TYPE}"
    cmd "ln -s ${DATE}/spack/share/spack/modules/linux-centos7-${CPU_OPT}/gcc-${GCC_COMPILER_VERSION} modules-${DATE}"
    cmd "cd -"
  fi
  cmd "chgrp windsim /opt"
  cmd "chgrp windsim /opt/${TYPE}"
  cmd "chgrp -R windsim ${INSTALL_DIR}"
  cmd "chmod a+rX,go-w /opt"
  cmd "chmod a+rX,go-w /opt/${TYPE}"
  cmd "chmod -R a+rX,go-w ${INSTALL_DIR}"
fi

printf "\n$(date)\n"
printf "\nDone!\n"

# Last step for compilers
# Edit compilers.yaml.software to point to all compilers this script installed
# Edit intel-parallel-studio modules to set INTEL_LICENSE_FILE correctly
# Edit pgi modules to set PGROUPD_LICENSE_FILE correctly
# It's possible the PGI compiler needs a libnuma.so.1.0.0 copied into its lib directory and symlinked to libnuma.so and libnuma.so.1
# Copy libnuma.so.1.0.0 into PGI lib directory and symlink to libnuma.so and libnuma.so.1
# Run makelocalrc for all PGI compilers (I think this sets a GCC to use as a frontend)
# I did something like:
# makelocalrc -gcc /nopt/nrel/ecom/hpacf/compilers/2019-05-08/spack/opt/spack/linux-centos7-x86_64/gcc-4.8.5/gcc-7.4.0-srw2azby5tn7wozbchryvj5ak3zlfz3r/bin/gcc -gpp /nopt/nrel/ecom/hpacf/compilers/2019-05-08/spack/opt/spack/linux-centos7-x86_64/gcc-4.8.5/gcc-7.4.0-srw2azby5tn7wozbchryvj5ak3zlfz3r/bin/g++ -g77 /nopt/nrel/ecom/hpacf/compilers/2019-05-08/spack/opt/spack/linux-centos7-x86_64/gcc-4.8.5/gcc-7.4.0-srw2azby5tn7wozbchryvj5ak3zlfz3r/bin/gfortran -x
# Add set PREOPTIONS=-D__GCC_ATOMIC_TEST_AND_SET_TRUEVAL=1; to localrc

# Other final manual customizations:
# - Rename necessary module files and set defaults
