import unyt as u
import phd

class Units:
    """
    Defines the unit system in use for the computations. 
    This depends on unyt's units package, but includes conversion
    support for Astropy's Unit package as well.
    """
    global sys_dict
    sys_dict = {'cgs': u.unit_systems.cgs_unit_system,
                'mks': u.unit_systems.mks_unit_system,
                'imperial': u.unit_systems.imperial_unit_system,
                'galactic': u.unit_systems.galactic_unit_system,
                'solar': u.unit_systems.solar_unit_system,
                'planck': u.unit_systems.planck_unit_system}

    def __init__(self, unit_system = 'cgs', unit_dict = None):
        """
        Constructor for the Unit class.

        Parameters
        ----------
        unit_system : str
            Specifies the unit system, supports available unyt unit systems 
            (cgs, mks, imperial, galactic, solar, planck).

        unit_dict : dict
            Dictionary of unyt ``Unit`` objects or strings (values) with associated 
            dimensions (keys). Must include length, time, mass units. For example, 
            u_dict = {'length': unyt.cm, 'time': unyt.s, 'mass': unyt.g}. This overwrites
            use of the ``unit_system`` parameter.
        """
        if(unit_dict is not None):
            self.unyt_sys = u.UnitSystem('user', unit_dict['length'], 
                                         unit_dict['mass'], unit_dict['time'])
        else:
            self.unyt_sys = sys_dict[unit_system]

        self.output_sys = self.unyt_sys # default unless changed by set_output_system

    def get_bases(self):
        """ Returns the base units for the simulation """
        return self.unyt_sys

    def set_bases(self, unit_dict):
        """ Sets the base units (time, length, mass) for the simulation 

        Parameters
        ----------
        unit_dict : dict
            Dictionary of unyt ``Unit`` objects (values) with associated 
            dimensions (keys). Must include length, time, mass units. For example, 
            u_dict = {'length': unyt.cm, 'time': unyt.s, 'mass': unyt.g}.
        """
        self.unyt_sys = u.UnitSystem('user', unit_dict['length'], 
                                     unit_dict['mass'], unit_dict['time'])

    def set_output_system(self, unit_system):
        """ Sets the units for simulation output. 

        Parameters
        ----------
        unit_system : str
            Name of the unit system to be used. Accepted names are those included with unyt 
            (cgs, mks, imperial, galactic, solar, planck) and 'user' (only works if ``set_bases`` 
            method has been used or custom ``unit_dict`` has been provided).
        """
        if(unit_system == 'user'):
            self.output_sys = self.unyt_sys
        else:
            self.output_sys = sys_dict[unit_system]

    def get_output_bases(self):
        """ Returns the base units for the output """
        return self.output_sys