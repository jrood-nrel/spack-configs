from spack import *
from spack.pkg.builtin.nalu_wind import NaluWind as bNaluWind
from spack.pkg.builtin.kokkos import Kokkos
import os

class NaluWind(NaluWind, CudaPackage):
    depends_on('kokkos-nvcc-wrapper', when='+cuda')
    depends_on('trilinos+cuda+wrapper+cuda_rdc', when='+cuda')
    depends_on('nccmp')
    depends_on('hypre~int64')

    def setup_build_environment(self, env):
        if '+cuda' in self.spec:
            env.set('MPICXX_CXX', self.spec["kokkos-nvcc-wrapper"].kokkos_cxx)

    def cmake_args(self):
        options = super(NaluWind, self).cmake_args()

        if '+cuda' in self.spec:
            options.append(CMakePackage.define('ENABLE_CUDA', True))

        return options
