import numpy as np
from PHD.mesh import VoronoiMesh2D

def test_volume():
    """Test if particle volumes are created correctly.
    First create a grid of particles in a unit box. So
    the total volume  is 1.0. Then perturb the particles
    in a box of unit lenght 0.5. Create the tessellation
    and compare the sum of all the particle volumes and
    the total volume.
    """

    L = 1.      # box size
    n = 50      # number of points
    dx = L/n

    # add ghost 3 ghost particles to the sides for the tesselation
    # wont suffer from edge boundaries
    x = (np.arange(n+6, dtype=np.float64) - 3)*dx + 0.5*dx

    # generate the grid of particle positions
    X, Y = np.meshgrid(x,x); Y = np.flipud(Y)
    x = X.flatten(); y = Y.flatten()

    # find all particles inside the unit box 
    indices = (((0. <= x) & (x <= 1.)) & ((0. <= y) & (y <= 1.)))
    x_in = x[indices]; y_in = y[indices]

    # find particles in the interior box
    k = ((0.25 < x_in) & (x_in < 0.5)) & ((0.25 < y_in) & (y_in < 0.5))

    # randomly perturb their positions
    num_points = k.sum()
    x_in[k] += 0.2*dx*(2.0*np.random.random(num_points)-1.0)
    y_in[k] += 0.2*dx*(2.0*np.random.random(num_points)-1.0)

    # store real particles
    x_particles = np.copy(x_in); y_particles = np.copy(y_in)
    particles_index = {"real": np.arange(x_particles.size)}

    # store ghost particles
    x_particles = np.append(x_particles, x[~indices])
    y_particles = np.append(y_particles, y[~indices])

    # store indices of ghost particles
    particles_index["ghost"] = np.arange(particles_index["real"].size, x_particles.size)

    # particle list of real and ghost particles
    particles = np.array([x_particles, y_particles])

    # generate voronoi mesh 
    mesh = VoronoiMesh2D()
    neighbor_graph, neighbor_graph_sizes, face_graph, face_graph_sizes, voronoi_vertices = mesh.tessellate(particles)

    # calculate voronoi volumes of all real particles 
    cell_info = mesh.volume_center_mass(particles, neighbor_graph, neighbor_graph_sizes, face_graph,
            voronoi_vertices, particles_index)

    tot_vol = cell_info["volume"].sum()
    assert np.abs(1.0 - tot_vol) < 1.0E-10

def test_center_of_mass():
    """Test if particle volumes are created correctly.
    First create a grid of particles in a unit box. So
    the total volume  is 1.0. Then perturb the particles
    in a box of unit lenght 0.5. Create the tessellation
    and compare the sum of all the particle volumes and
    the total volume.
    """

    L = 1.      # box size
    n = 50      # number of points
    dx = L/n

    # add ghost 3 ghost particles to the sides for the tesselation
    # wont suffer from edge boundaries
    x = (np.arange(n+6, dtype=np.float64) - 3)*dx + 0.5*dx

    # generate the grid of particle positions
    X, Y = np.meshgrid(x,x); Y = np.flipud(Y)
    x = X.flatten(); y = Y.flatten()

    # find all particles inside the unit box 
    indices = (((0. <= x) & (x <= 1.)) & ((0. <= y) & (y <= 1.)))
    x_in = x[indices]; y_in = y[indices]

    # store real particles
    x_particles = np.copy(x_in); y_particles = np.copy(y_in)
    particles_index = {"real": np.arange(x_particles.size)}

    # store ghost particles
    x_particles = np.append(x_particles, x[~indices])
    y_particles = np.append(y_particles, y[~indices])

    # store indices of ghost particles
    particles_index["ghost"] = np.arange(particles_index["real"].size, x_particles.size)

    # particle list of real and ghost particles
    particles = np.array([x_particles, y_particles])

    # generate voronoi mesh 
    mesh = VoronoiMesh2D()
    neighbor_graph, neighbor_graph_sizes, face_graph, face_graph_sizes, voronoi_vertices = mesh.tessellate(particles)

    # calculate voronoi volumes of all real particles 
    cell_info = mesh.volume_center_mass(particles, neighbor_graph, neighbor_graph_sizes, face_graph,
            voronoi_vertices, particles_index)

    com = cell_info["center of mass"]

    # the center of mass of each particle should be their position
    real = particles_index["real"]
    diff = np.absolute(particles[0,real] - com[0,:]) < 1.0E-10
    diff = np.append(diff, np.absolute(particles[1,real] - com[1,:]) < 1.0E-10)

    assert np.all(diff)
