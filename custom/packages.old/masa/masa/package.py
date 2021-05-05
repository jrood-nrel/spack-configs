# Copyright 2013-2020 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack import *
from spack.pkg.builtin.masa import Masa as bMasa


class Masa(bMasa):
    patch('stdcpp11.patch', sha256='ce612115e2493b1884a01e8ba660b49dd60cb7b1aefeb7c21d1fdab1f925f60b')
