cimport numpy as np

from .splitter cimport Splitter
from .gravity_pool cimport Node
from ..utils.carray cimport IntArray
from ..containers.containers cimport CarrayContainer

# ** later on this will become a generic class to hanlde
#    any type of calculation on the tree  **
cdef class Interaction:
    cdef int dim                    # spatial dimension of the problem
    cdef long current               # index of particle to compute on
    cdef long num_particles         # total number of particles

    cdef public dict fields         # fields to use in computation
    cdef public dict named_groups   # vector of fields for ease

    cdef IntArray tags              # reference to particle tags
    cdef Splitter splitter          # criteria to open node

    cdef void interact(self, Node* node)
    cdef void initialize_particles(self, CarrayContainer pc)
    cdef int process_particle(self)

cdef class GravityAcceleration(Interaction):
    cdef int calc_potential  # flag to include gravity potential

    # pointer to particle data
    cdef np.float64_t *m     # masses
    cdef np.float64_t *pot   # masses
    cdef np.float64_t *x[3]  # positions
    cdef np.float64_t *a[3]  # accelerations
