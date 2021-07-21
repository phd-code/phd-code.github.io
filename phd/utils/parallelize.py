import phd
import numpy as np

def distribute_initial_particles(create_particles, **kwargs):
    if not phd._in_parallel:
        return create_particles(**kwargs)

    else:

        if "dim" not in kwargs:
            raise KeyError("Dim not specified")
        else:
            dim = kwargs["dim"]

        if "units" not in kwargs:
                raise KeyError("Units not specified")
        else:
            units = kwargs["units"]

        if phd._rank == 0:

            particles_root, units = create_particles(**kwargs)

            # how many particles to each process
            nsect, extra = divmod(particles_root.get_carray_size(), phd._size)
            lengths = extra*[nsect+1] + (phd._size-extra)*[nsect]
            send = np.array(lengths)

            # how many particles 
            disp = np.zeros(phd._size, dtype=np.int32)
            for i in range(1, phd._size):
                disp[i] = send[i-1] + disp[i-1]

        else:

            lengths = disp = send = None
            particles_root = {}
            pc, units = phd.HydroParticleCreator(dim=dim, unit_sys = units)
            for key in list(pc.carrays.keys()):
                particles_root[key] = None

        # tell each processor how many particles it will hold
        send = phd._comm.scatter(send, root=0)

        # allocate local particle container
        particles, units = phd.HydroParticleCreator(send, dim=dim, unit_sys = units)

        # import particles from root
        for field in list(particles.carrays.keys()):
            phd._comm.Scatterv([particles_root[field], (lengths, disp)], particles[field])
        del particles_root

        return particles, units
