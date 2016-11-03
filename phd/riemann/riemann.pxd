from ..containers.containers cimport CarrayContainer
from ..reconstruction.reconstruction cimport ReconstructionBase


cdef class RiemannBase:

    cdef public ReconstructionBase reconstruction

    cdef public double cfl
    cdef public double gamma
    cdef public int boost
    cdef public int dim

    cdef _solve(self, CarrayContainer fluxes, CarrayContainer left_face, CarrayContainer right_face, CarrayContainer faces,
            double t, double dt, int iteration_count, int dim)

    cdef _deboost(self, CarrayContainer fluxes, CarrayContainer faces, int dim)

    cdef double _compute_time_step(self, CarrayContainer pc)

cdef class HLL(RiemannBase):

    cdef void get_waves(self, double d_l, double u_l, double p_l,
            double d_r, double u_r, double p_r,
            double gamma, double *sl, double *sc, double *sr)

cdef class HLLC(HLL):
    pass

cdef class Exact(RiemannBase):

    cdef p_guess(self, double d_l, double u_l, double p_l, double d_r, double u_r, double p_r, double gamma)
    cdef p_func(self, double d, double u, double p, double gamma, double p_old)
    cdef p_func_deriv(self, double d, double u, double p, double gamma, double p_old)
    cdef get_pstar(self, double d_l, double u_l, double p_l, double d_r, double u_r, double p_r, double gamma)
