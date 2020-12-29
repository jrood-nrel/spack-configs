from spack import *
from spack.pkg.builtin.nalu_wind import NaluWind as bNaluWind
from spack.pkg.builtin.kokkos import Kokkos
import os
from shutil import copyfile

class NaluWind(bNaluWind, CudaPackage):
    depends_on('kokkos-nvcc-wrapper', when='+cuda')
    depends_on('trilinos+cuda', when='+cuda')

    for val in CudaPackage.cuda_arch_values:
        arch_string='cuda_arch={arch}'.format(arch=val)
        depends_on('trilinos+wrapper+cuda_rdc {arch}'.format(arch=arch_string), when=arch_string)

    def setup_build_environment(self, env):
        if '+cuda' in self.spec:
            if '+mpi' in self.spec:
                env.set('MPICXX_CXX', self.spec["kokkos-nvcc-wrapper"].kokkos_cxx)
            else:
                env.set('CXX', self.spec["kokkos-nvcc-wrapper"].kokkos_cxx)
        else:
            env.set(
                "KOKKOS_ARCH_" +
                Kokkos.spack_micro_arch_map[self.spec.target.name].upper(), True)

    def cmake_args(self):
        options = super(NaluWind, self).cmake_args()

        if  '+cuda' in self.spec:
            options.append(CMakePackage.define('ENABLE_CUDA', True))

        return options
