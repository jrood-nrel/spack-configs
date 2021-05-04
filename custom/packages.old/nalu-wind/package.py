from spack import *
from spack.pkg.builtin.nalu_wind import NaluWind as bNaluWind
from spack.pkg.builtin.kokkos import Kokkos
import os

class NaluWind(bNaluWind, CudaPackage):
    depends_on('kokkos-nvcc-wrapper', when='+cuda')
    depends_on('trilinos+cuda', when='+cuda')
    depends_on('hypre+cuda~int64', when='+cuda')
    depends_on('nccmp')

    for val in CudaPackage.cuda_arch_values:
        arch_string='cuda_arch={arch}'.format(arch=val)
        depends_on('trilinos+wrapper+cuda_rdc {arch}'.format(arch=arch_string), when=arch_string)

    def setup_build_environment(self, env):
        if '+cuda' in self.spec:
            env.set('MPICXX_CXX', self.spec["kokkos-nvcc-wrapper"].kokkos_cxx)

    def cmake_args(self):
        options = super(NaluWind, self).cmake_args()

        if '+cuda' in self.spec:
            options.append(CMakePackage.define('ENABLE_CUDA', True))

        return options
