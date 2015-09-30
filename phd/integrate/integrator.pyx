from utils.particle_tags import ParticleTAGS

from riemann.riemann cimport RiemannBase
from containers.containers cimport CarrayContainer
from utils.carray cimport DoubleArray, IntArray, LongLongArray
from libc.math cimport sqrt, fabs, fmin

import numpy as np
cimport numpy as np

cdef int Real = ParticleTAGS.Real
cdef int Boundary = ParticleTAGS.Boundary

cdef class IntegrateBase:
    def __init__(self, RiemannBase riemann):
        """Constructor for the Integrator"""
        self.riemann = riemann

        # properties inherited from the function
        self.mesh = riemann.mesh
        self.particles = riemann.mesh.particles

        # create flux data array
        flux_vars = {
                "mass": "double",
                "momentum-x": "double",
                "momentum-y": "double",
                "energy": "double",
                }
        self.flux = CarrayContainer(var_dict=flux_vars)

        # create left/right face state array 
        state_vars = {
                "density": "double",
                "velocity-x": "double",
                "velocity-y": "double",
                "pressure": "double",
                }
        self.left_state  = CarrayContainer(var_dict=state_vars)
        self.right_state = CarrayContainer(var_dict=state_vars)

    def compute_time_step(self):
        return self._compute_time_step()

    def integrate(self, double dt, double t, int iteration_count):
        self._integrate(dt, t, iteration_count)


    cdef double _compute_time_step(self):
        msg = "IntegrateBase::compute_time_step called!"
        raise NotImplementedError(msg)

    cdef _integrate(self, double dt, double t, int iteration_count):
        msg = "IntegrateBase::_integrate called!"
        raise NotImplementedError(msg)


cdef class MovingMesh(IntegrateBase):
    def __init__(self, RiemannBase riemann, int regularize, double eta = 0.25):
        """Constructor for the Integrator"""

        IntegrateBase.__init__(riemann)

        self.regularize = regularize
        self.eta = eta


    cdef _integrate(self, double dt, double t, int iteration_count):
        """Main step routine"""

        # particle flag information
        cdef IntArray tags = self.particles.get_carray("tag")

        # face information
        cdef LongLongArray pair_i = self.mesh.faces.get_carray("pair-i")
        cdef LongLongArray pair_j = self.mesh.faces.get_carray("pair-j")
        cdef DoubleArray area = self.mesh.faces.get_carray("area")

        # particle position and velocity
        cdef DoubleArray  x = self.particles.get_carray("position-x")
        cdef DoubleArray  y = self.particles.get_carray("position-y")
        cdef DoubleArray wx = self.particles.get_carray("w-x")
        cdef DoubleArray wy = self.particles.get_carray("w-y")

        # particle values
        cdef DoubleArray m  = self.particles.get_carray("mass")
        cdef DoubleArray mu = self.particles.get_carray("momentum-x")
        cdef DoubleArray mv = self.particles.get_carray("momentum-y")
        cdef DoubleArray E  = self.particles.get_carray("energy")

        # flux values
        cdef DoubleArray f_m  = self.flux.get_carray("mass")
        cdef DoubleArray f_mu = self.flux.get_carray("momentum-x")
        cdef DoubleArray f_mv = self.flux.get_carray("momentum-y")
        cdef DoubleArray f_E  = self.flux.get_carray("energy")

        cdef int i, j, k
        cdef double a

        cdef long num_faces = self.mesh.faces.get_number_of_items()
        cdef long npart = self.particles.get_number_of_particles()


        # compute particle and face velocities
        self.compute_face_velocities()

        # resize face/states arrays
        self.left_state.resize(num_faces)
        self.right_state.resize(num_faces)
        self.flux.resize(num_faces)

        # reconstruct left\right states at each face
        self.riemann.interpolation.compute(self.particles, self.mesh.faces, self.left_state, self.right_state,
                t, dt, iteration_count)

        # extrapolate state to face, apply frame transformations, solve riemann solver, and transform back
        self.riemann.solve(self.flux, self.left_state, self.right_state, self.mesh.faces,
                t, dt, iteration_count)

        # update conserved quantities
        for k in range(num_faces):

            # update only real particles in the domain
            i = pair_i.data[k]
            j = pair_j.data[k]
            a = area.data[k]

            # flux entering cell defined by particle i
            if tags.data[j] == Real:
                m.data[i]  -= dt*a*f_m.data[k]
                mu.data[i] -= dt*a*f_mu.data[k]
                mv.data[i] -= dt*a*f_mv.data[k]
                E.data[i]  -= dt*a*f_E.data[k]

            # flux leaving cell defined by particle j
            if tags.data[j] == Real:
                m.data[j]  += dt*a*f_m.data[k]
                mu.data[j] += dt*a*f_mu.data[k]
                mv.data[j] += dt*a*f_mv.data[k]
                E.data[j]  += dt*a*f_E.data[k]

        # move particles
        for i in range(npart):
            if tags.data[i] == Real:
                x.data[i] += dt*wx.data[i]
                y.data[i] += dt*wy.data[i]

    cdef double _compute_time_step(self):

        cdef IntArray tags = self.particles.get_carray("tag")

        cdef DoubleArray r = self.particles.get_carray("density")
        cdef DoubleArray p = self.particles.get_carray("pressure")
        cdef DoubleArray u = self.particles.get_carray("velocity-x")
        cdef DoubleArray v = self.particles.get_carray("velocity-y")

        cdef DoubleArray vol = self.particles.get_carray("volume")

        cdef double gamma = self.gamma
        cdef double c, R, dt, dt_x, dt_y
        cdef long i, npart = self.particles.get_number_of_particles()

        c = sqrt(gamma*p.data[0]/r.data[0])
        R = sqrt(vol.data[0]/np.pi)
        dt = R/(fabs(u.data[0]) + c)

        for i in range(npart):
            if tags.data[i] == Real:

                c = sqrt(gamma*p.data[i]/r.data[i])

                # calculate approx radius of each voronoi cell
                R = sqrt(vol.data[i]/np.pi)

                dt_x = R/(fabs(u.data[i]) + c)
                dt_y = R/(fabs(v.data[i]) + c)

                dt = fmin(dt_x, fmin(dt_y, dt))

        return dt

    cdef _compute_face_velocities(self):
        self._assign_particle_velocities()
        self._assign_face_velocities()

    cdef _assign_particle_velocities(self):
        """
        Assigns particle velocities. Particle velocities are
        equal to local fluid velocity plus a regularization
        term. The algorithm is taken from Springel (2009).
        """
        # particle flag information
        cdef IntArray type = self.particles.get_carray("type")
        cdef IntArray tags = self.particles.get_carray("tag")

        # particle position and velocity
        cdef DoubleArray x = self.particles.get_carray("position-x")
        cdef DoubleArray y = self.particles.get_carray("position-y")
        cdef DoubleArray wx = self.particles.get_carray("w-x")
        cdef DoubleArray wy = self.particles.get_carray("w-y")

        # center of mass of particle cell
        cdef DoubleArray cx = self.particles.get_carray("com-x")
        cdef DoubleArray cy = self.particles.get_carray("com-y")

        # particle values
        cdef DoubleArray r = self.particles.get_carray("density")
        cdef DoubleArray p = self.particles.get_carray("pressure")
        cdef DoubleArray u = self.particles.get_carray("velocity-x")
        cdef DoubleArray v = self.particles.get_carray("velocity-y")

        # local variables
        cdef double _x, _y, _cx, _cy, _wx, _wy, cs, d, R
        cdef double eta = self.eta

        cdef long i, npart = self.particles.get_number_of_particles()

        for i in range(npart):
            if tags.data[i] == Real or type.data[i] == Boundary:

                _wx = _wy = 0.0

                if self.regularize == 1:

                    # sound speed 
                    cs = sqrt(self.gamma*p.data[i]/r.data[i])

                    # particle positions and center of mass of real particles
                    _x = x.data[i]
                    _y = y.data[i]

                    _cx = cx.data[i]
                    _cy = cy.data[i]

                    # distance form cell com to particle position
                    d = sqrt( (_cx - _x)**2 + (_cy - _y)**2 )

                    # approximate length of cell
                    R = sqrt(v.data[i]/np.pi)

                    # regularize - eq. 63
                    if ((0.9 <= d/(eta*R)) and (d/(eta*R) < 1.1)):
                        _wx += cs*(_cx - _x)*(d - 0.9*eta*R)/(d*0.2*eta*R)
                        _wy += cs*(_cy - _y)*(d - 0.9*eta*R)/(d*0.2*eta*R)

                    elif (1.1 <= d/(eta*R)):
                        _wx += cs*(_cx - _x)/d
                        _wy += cs*(_cy - _y)/d

                # add velocity of the particle
                wx.data[i] = _wx + u.data[i]
                wy.data[i] = _wy + v.data[i]


    cdef _assign_face_velocities(self):
        """
        Assigns velocities to the center of mass of the face
        defined by neighboring particles. The face velocity
        is the average of particle velocities that define
        the face plus a residual motion. The algorithm is
        taken from Springel (2009).
        """
        # particle flag information
        cdef IntArray tags = self.particles.get_carray("tags")
        cdef IntArray type = self.particles.get_carray("type")

        # particle position
        cdef DoubleArray x = self.particles.get_carray("position-x")
        cdef DoubleArray y = self.particles.get_carray("position-y")

        # particle velocity
        cdef DoubleArray wx = self.particles.get_carray("w-x")
        cdef DoubleArray wy = self.particles.get_carray("w-y")

        # face information
        cdef DoubleArray fu  = self.mesh.faces.get_carray("velocity-x")
        cdef DoubleArray fv  = self.mesh.faces.get_carray("velocity-y")
        cdef DoubleArray fcx = self.mesh.faces.get_carray("com-x")
        cdef DoubleArray fcy = self.mesh.faces.get_carray("com-y")

        # neighbor arrays
        cdef np.int32_t[:] neighbors = self.mesh["neighbors"]
        cdef np.int32_t[:] num_neighbors = self.mesh["number of neighbors"]

        # local variables
        cdef double _xi, _yi, _xj, _yj
        cdef double _wxi, _wyi, _wxj, _wyj
        cdef double factor

        # k is the face index and ind is the neighbor index
        cdef int k, ind
        cdef int n

        cdef long npart = self.particles.get_number_of_particles()

        k = ind = 0
        for i in range(npart):
            if tags.data[i] == Real or type.data[i] == Boundary:

                # particle position
                _xi = x.data[i]
                _yi = y.data[i]

                # particle velocity
                _wxi = wx.data[i]
                _wyi = wy.data[i]

                # assign velocities to faces of particle i
                # by looping over all it's neighbors
                for n in range(num_neighbors[i]):

                    # index of neighbor
                    j = neighbors[ind]

                    # no duplicate faces
                    if i < j:

                        # position of neighbor
                        _xj = x.data[j]
                        _yj = y.data[j]

                        # velocity of neighbor
                        _wxj = wx.data[j]
                        _wyj = wy.data[j]

                        # correct face velocity due to residual motion - eq. 32
                        factor  = (_wxi - _wxj)*(fcx.data[k] - 0.5*(_xi + _xj)) +\
                                  (_wyi - _wyj)*(fcy.data[k] - 0.5*(_yi + _yj))
                        factor /= (_xj - _xi)*(_xj - _xi) + (_yj - _yi)*(_yj - _yi)

                        # the face velocity mean of particle velocities and residual term - eq. 33
                        fu.data[k] = 0.5*(_wxi + _wxj) + factor*(_xj - _xi)
                        fv.data[k] = 0.5*(_wxi + _wxj) + factor*(_yj - _yi)

                        # update counter
                        k   += 1
                        ind += 1

                    else:

                        # face accounted for, go to next neighbor and face
                        ind += 1