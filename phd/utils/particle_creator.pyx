from .particle_tags import ParticleTAGS
from ..containers.containers cimport CarrayContainer
from .units import Units

def HydroParticleCreator(num=0, dim=2, parallel=False, unit_sys='cgs', unit_dict=None):
    """Creates a ``CarrayContainer`` to hold hydro data related to the simulation.

    Parameters
    ----------
    num : int
        Size of ``CarrayContainer``

    dim : int
        Number of dimensions

    parallel : bool
        Toggles whether the simulation is being run in parallel or serial

    unit_sys : str
        Specifies one of the named ``unyt`` systems for use in the simulation initialization.

    unit_dict : dict
        Overwrites use of unit_sys. Allows user to specify a custom unit system by passing 
        length, time, and mass units in dictionary.

    Returns
    -------
    pc : CarrayContainer
        Object holding the hydro information pertaining to the  particles

    unit_obj : Units
        Object holding the unit information in use for the simulation.
        
    """
    cdef dict carray_named_groups = {}
    cdef str axis, dimension = 'xyz'[:dim]
    cdef CarrayContainer pc = CarrayContainer(num)

    # initialize unit interface
    if(unit_dict is not None):
        unit_obj = Units(unit_dict = unit_dict)
    else:
        unit_obj = Units(unit_system = unit_sys)

    # register primitive fields
    carray_named_groups['position'] = []
    carray_named_groups['velocity'] = []
    pc.register_carray(num, 'density', 'double')

    for axis in dimension:

        pc.register_carray(num, 'position-' + axis, 'double')
        pc.register_carray(num, 'velocity-' + axis, 'double')

        carray_named_groups['position'].append('position-' + axis)
        carray_named_groups['velocity'].append('velocity-' + axis)

    pc.register_carray(num, 'pressure', 'double')

    # register conservative fields
    carray_named_groups['momentum'] = []
    pc.register_carray(num, 'mass', 'double')

    for axis in dimension:

        pc.register_carray(num, 'momentum-' + axis, 'double')
        carray_named_groups['momentum'].append('momentum-' + axis)

    pc.register_carray(num, 'energy', 'double')

    # information for prallel runs
#    if parallel:
#
#        pc.register_carray(num, 'key', 'longlong')
#        pc.register_carray(num, 'process', 'long')

    # ghost labels 
    pc.register_carray(num, 'tag', 'int')
    pc.register_carray(num, 'type', 'int')

    # ** remove and place in boundary **
    pc.register_carray(num, 'ids', 'long')
    #pc.register_carray(num, 'map', 'long')

    carray_named_groups['primitive'] = ['density'] +\
            carray_named_groups['velocity'] +\
            ['pressure']
    carray_named_groups['conservative'] = ['mass'] +\
            carray_named_groups['momentum'] +\
            ['energy']

    # set initial particle tags to be real
    pc['tag'][:] = ParticleTAGS.Real
    pc['type'][:] = ParticleTAGS.Undefined
    pc.carray_named_groups = carray_named_groups

    return pc, unit_obj

#def MhdParticleCreator(num=0, dim=2, parallel=False):
#    pass
