cimport numpy as np

from ..containers.containers cimport CarrayContainer

cdef class EquationStateBase:
    cdef public double gamma

    cpdef conservative_from_primitive(self, CarrayContainer particles)
    cpdef primitive_from_conservative(self, CarrayContainer particles)
    cpdef np.float64_t sound_speed(self, np.float64_t density, np.float64_t pressure)
    cpdef np.float64_t get_gamma(self)

cdef class IdealGas(EquationStateBase):
    pass
