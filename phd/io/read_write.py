import h5py
import numpy as np
import unyt as u
from ..utils.logger import phdLogger
from ..utils.particle_tags import ParticleTAGS
from ..containers.containers import CarrayContainer
from ..utils.units import Units

class ReaderWriterBase(object):
    def write(self, base_name, output_directory, integrator):
        """Write simulation to disk.

        This base class is the api for writing and reading
        of data. Note the user is free to write any type of
        output. For example, this can be used to create
        runtime plots or diagnostics.

        Parameters
        ----------
        base_name : str
            File name for output data.

        output_directory : str
            Directory where to store the data.

        integrator : IntegrateBase
            Advances the fluid equations by one step.
        """
        msg = "ReaderWriterBase::write called!"
        raise NotImplementedError(msg)

    def read(self, file_name):
        """Read data and return particles.

        For formats where the data is being stored, a read
        function must be defined. This function reads the
        data outputted by `write` and returns a CarrayContainer
        of particles to be used by the simulation.

        Parameters
        ----------
        file_name : str
            File name to be read in.

        Returns
        -------
        particles : CarrayContainer
            Complete container of particles for a simulation.

        """
        msg = "ReaderWriterBase::read called!"
        raise NotImplementedError(msg)

class Hdf5(ReaderWriterBase):
    def write(self, base_name, output_directory, integrator):
        """Write simulation data to hdf5 file.
        
        Parameters
        ----------
        base_name : str
            Base file name for simulation output

        output_directory : str

        integrator : IntegrateBase
            Advances the fluid equations by one step

        """
        file_name = base_name + ".hdf5"
        output_path = output_directory + "/" + file_name
        phdLogger.info("hdf5 format: Writting %s" % file_name)

        with h5py.File(output_path, "w") as f:

            # store current time
            f.attrs["dt"] = integrator.dt
            f.attrs["time"] = integrator.time
            f.attrs["iteration"] = integrator.iteration

            # extract unit information from passed unit object
            output_len_unit = str(integrator.units.get_output_bases()['length'])
            output_time_unit = str(integrator.units.get_output_bases()['time'])
            output_mass_unit = str(integrator.units.get_output_bases()['mass'])
            f.attrs["length_unit"] = output_len_unit
            f.attrs["mass_unit"] = output_mass_unit
            f.attrs["time_unit"] = output_time_unit

            # store particle data
            particle_grp = f.create_group("particles")

            # common information 
            particle_grp.attrs["Real"] = ParticleTAGS.Real
            particle_grp.attrs["Ghost"] = ParticleTAGS.Ghost
            particle_grp.attrs["number_particles"] = integrator.particles.get_carray_size()

            # store particle data for each field
            for prop_name in list(integrator.particles.carrays.keys()):
                data_grp = particle_grp.create_group(prop_name)
                data_grp.attrs["dtype"] = integrator.particles.carray_dtypes[prop_name]
               
                if(integrator.units.get_bases() == integrator.units.get_output_bases()):
                    # if the simulation and output unit systems are the same
                    data_grp.create_dataset("data", data=integrator.particles[prop_name])
                else:
                    # assign sim data proper units, convert to output units and strip of units for file writing
                    prop_name_str = prop_name
                    prop_name_blacklist = ["tag", "type", "ids", "map", "radius",
                                           "old_radius", "volume", "dcom-x", 
                                           "dcom-y", "dcom-z", "w-x", "w-y", "w-z"]
                    if("position" in prop_name):
                        prop_name_str = "length"
                    elif("velocity" in prop_name):
                        prop_name_str = "velocity"
                    elif("momentum" in prop_name):
                        prop_name_str = "momentum"
                    elif(prop_name in prop_name_blacklist):
                        data_grp.create_dataset("data", data=integrator.particles[prop_name])
                        continue

                    sim_data_unitful = integrator.particles[prop_name]*integrator.units.get_bases()[prop_name_str]
                    output_data_unitful = sim_data_unitful.in_base(integrator.units.get_output_bases())

                    data_grp.create_dataset("data", data=output_data_unitful.v)

            f.close()

    def read(self, file_name):
        """Read hdf5 file of particles.
        
        Parameters
        ----------
        file_name : str
            File to be parsed.

        Returns
        -------
        particles : CarrayContainer
            Object holding the information relating to the particles in the simulation

        units : Units
            Object holding the metadata related to units used in simulation output (uses
            functionality of unyt Python package).
        """
        phdLogger.info("hdf5 format: Reading filename %s" % file_name)

        with h5py.File(file_name, "r") as f:

            output_len_unit = f.attrs["length_unit"]
            output_time_unit = f.attrs["time_unit"]
            output_mass_unit = f.attrs["mass_unit"]
            units = Units(unit_dict = {"length": output_len_unit, 
                                          "time": output_time_unit, 
                                          "mass": output_mass_unit})

            particle_grp = f["particles"]
            num_particles = particle_grp.attrs["number_particles"]
            particles = CarrayContainer(num_particles)

            # populate arrays with data
            for field_key in list(particle_grp.keys()):
                #field = field_key.encode('utf8')
                field = str(field_key)
                field_grp = particle_grp[field]
                particles.register_carray(num_particles, field, field_grp.attrs["dtype"])
                particles[field][:] = field_grp["data"][:]

        return particles, units
