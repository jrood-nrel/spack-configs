# Copyright 2013-2021 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack import *
from spack.pkg.builtin.openfast import Openfast as bOpenfast

class Openfast(bOpenfast):
    version('develop', commit='3d170ccc23045c299aa803ba8c0c016012491629')
