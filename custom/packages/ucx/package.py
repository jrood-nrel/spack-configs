# Copyright 2013-2020 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack import *


class Ucx(AutotoolsPackage, CudaPackage):
    """a communication library implementing high-performance messaging for
    MPI/PGAS frameworks"""

    homepage = "http://www.openucx.org"
    url      = "https://github.com/openucx/ucx/releases/download/v1.3.1/ucx-1.3.1.tar.gz"

    maintainers = ['hppritcha']

    version('1.8.0', sha256='e400f7aa5354971c8f5ac6b881dc2846143851df868088c37d432c076445628d')
    version('1.7.0', sha256='6ab81ee187bfd554fe7e549da93a11bfac420df87d99ee61ffab7bb19bdd3371')
    version('1.6.1', sha256='1425648aa03f5fa40e4bc5c4a5a83fe0292e2fe44f6054352fbebbf6d8f342a1')
    version('1.6.0', sha256='360e885dd7f706a19b673035a3477397d100a02eb618371697c7f3ee4e143e2c')

    depends_on('numactl')
    depends_on('rdma-core')
    depends_on('gdrcopy@1.3')

    def configure_args(self):
        args = []

        args.append('--enable-optimizations')
        args.append('--disable-logging')
        args.append('--disable-debug')
        args.append('--disable-assertions')
        args.append('--disable-params-check')
        args.append('--with-avx')
        args.append('--with-march')
        args.append('--with-verbs=/usr')
        args.append('--with-rc')
        args.append('--with-ud')
        args.append('--with-dc')
        args.append('--with-cm')
        args.append('--with-mlx5-dv')
        args.append('--with-ib-hw-tm')
        args.append('--with-cuda={0}'.format(self.spec['cuda'].prefix))
        args.append('--with-gdrcopy={0}'.format(self.spec['gdrcopy'].prefix))

        return args
