# Copyright 2013-2021 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack import *
from spack.pkg.builtin.trilinos import Trilinos as bTrilinos

class Trilinos(bTrilinos):
    generator = 'Ninja'
    depends_on('ninja', type='build')
    patch('stk_boost_stacktrace.patch', when='@develop')
