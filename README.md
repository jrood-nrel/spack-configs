# Spack configuration files and scripts for use on machines at NREL

These software installations are maintained by Jon Rood for the HPACF group at NREL and are tailored to the applications our group develops. They are open to anyone to use on our machines. The software installations are organized by date snapshots. The binaries, compilers, and utilties are not updated as often as the software modules, so dated symlinks might overlap multiple dates for those. However, each date snapshot of the modules should be able to stand on its own so that older snapshots can be purged safely over time.

- "base" is just a newer version of GCC to replace the system GCC 4.8.5 which is far too old to build many recent projects.
- "binaries" are generally the binary downloads of Paraview and Visit.
- "compilers" are the latest set of compilers built using the base GCC.
- "utilities" are the latest set of utility programs that don't rely on MPI and are built using the base GCC.
- "software" are the latest set of generally larger programs and dependencies that rely on MPI. Each date corresponds to a single MPI implementation so there is no confusion as to which MPI was used for the applications. These modules are built using a farily recent GCC, Clang, or Intel compiler provided from the "compilers" modules, using the highest optimization flags specific to the machine architecture.

Currently there is no perfect way to advertise deprecation or addition, and evolution of these modules. I have an MOTD you can cat in your login script to see updates. Generally the latest 4 sets of modules will likely be kept and new sets have been showing up around every 3 to 6 months.

To use these modules you can add the following to your `~/.bashrc` for example and choose the module set (date) you prefer, and the GCC or Intel compiled software modules:

```
#------------------------------------------

#MPICH 3.3.1
#MODULES=modules-2019-10-08
#COMPILER=gcc-7.4.0
#COMPILER=clang-7.0.1
#COMPILER=intel-18.0.4

#MPICH 3.3
#MODULES=modules-2019-05-23
#COMPILER=gcc-7.4.0
#COMPILER=intel-18.0.4

#MPICH 3.3
#MODULES=modules-2019-05-08
#COMPILER=gcc-7.4.0
#COMPILER=intel-18.0.4

#MPICH 3.3
#MODULES=modules-2019-01-10
#COMPILER=gcc-7.3.0
#COMPILER=intel-18.0.4

#OpenMPI 3.1.3
#MODULES=modules-2018-11-21
#COMPILER=gcc-7.3.0
#COMPILER=intel-18.0.4

#Recommended default according to where "modules" is currently symlinked
MODULES=modules
COMPILER=gcc-7.4.0
#COMPILER=clang-7.0.1
#COMPILER=intel-18.0.4

module purge
module unuse ${MODULEPATH}
module use /nopt/nrel/ecom/hpacf/binaries/${MODULES}
module use /nopt/nrel/ecom/hpacf/compilers/${MODULES}
module use /nopt/nrel/ecom/hpacf/utilities/${MODULES}
module use /nopt/nrel/ecom/hpacf/software/${MODULES}/${COMPILER}
module load gcc
module load git
module load python
module load mpich
#etc...

#------------------------------------------
```

If `module avail` does not show the modules on Eagle, try removing the LMOD cache with `rm -rf ~/.lmod.d/.cache`

Also included in this directory is a recommended Spack configurations you can use to build your own packages on the machines supported at NREL. Once you have `SPACK_ROOT` set you can run `/nopt/nrel/ecom/hpacf/spack-config/setup-spack.sh` which should copy the yaml files into your instance of Spack. Or you can copy the yaml files into your `~/.spack/` directory manually. `spack compilers` should then show you many available compilers. Source your Spack's `setup-env.sh` after you do the `module unuse ${MODULEPATH}` in your `.bashrc` so that your Spack instance will add its own module path to MODULEPATH. Remove `~/.spack/linux` if it exists and `spack compilers` doesn't show you the updated list of compilers. The `~/.spack` directory takes highest precendence in the Spack configuration.
