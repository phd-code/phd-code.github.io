import numpy as np

def sod():

    # boundaries
    boundary_dic = {"left":0.0, "right":2.0, "bottom":0.0, "top":0.2}

    gamma = 1.4

    Lx = 2.       # domain size
    nx = 100      # number of points

    dx = Lx/nx
    x = (np.arange(nx+6, dtype=np.float64) - 3)*dx + 0.5*dx

    Ly = .2       # domain size
    ny = 10       # number of points

    dy = Ly/ny
    y = (np.arange(ny+6, dtype=np.float64) - 3)*dy + 0.5*dy

    X, Y = np.meshgrid(x,y); Y = np.flipud(Y)

    x = X.flatten(); y = Y.flatten()

    left   = boundary_dic["left"];   right = boundary_dic["right"]
    bottom = boundary_dic["bottom"]; top   = boundary_dic["top"]


    indices = (((left <= x) & (x <= right)) & ((bottom <= y) & (y <= top)))
    x_in = x[indices]; y_in = y[indices]

    data = np.zeros((4, x_in.size))
    left_cells = np.where(x_in <= 1.0)[0]
    data[0, left_cells] = 1.0                 # density
    data[1, left_cells] = -2.0                # velocity
    data[3, left_cells] = 0.5*data[0, left_cells]*data[1, left_cells]**2 + 0.4/(gamma-1.0)

    right_cells = np.where(1.0 < x_in)[0]
    data[0, right_cells] = 1.0                # density
    data[1, right_cells] = 2.0                # velocity
    data[3, right_cells] = 0.5*data[0, right_cells]*data[1, right_cells]**2 + 0.4/(gamma-1.0)

    x_particles = np.copy(x_in); y_particles = np.copy(y_in)
    particles_index = {}
    particles_index["real"] = np.arange(x_particles.size)

    x_particles = np.append(x_particles, x[~indices])
    y_particles = np.append(y_particles, y[~indices])
    particles_index["ghost"] = np.arange(particles_index["real"].size, x_particles.size)

    particles = np.array([x_particles, y_particles])

    return data, particles, particles_index

#-------------------------------------------------------------------------------
import PHD.simulation as simulation
import PHD.boundary as boundary
import PHD.reconstruction as reconstruction
import PHD.riemann as riemann

# parameters for the simulation
CFL = 0.2
gamma = 1.4
max_steps = 1000
max_time = 0.15
output_name = "Sod"

# create boundary and riemann objects
boundary_condition = boundary.reflect(0.,2.0,0.,.2)
#reconstruction = reconstruction.piecewise_constant()
reconstruction = reconstruction.piecewise_linear()
#riemann_solver = riemann.castro()
riemann_solver = riemann.pvrs()

# create initial state of the system
data, particles, particles_index = sod()

# setup the moving mesh simulation
#simulation = simulation.moving_mesh()
simulation = simulation.static_mesh()

# set runtime parameters for the simulation
simulation.set_parameter("CFL", CFL)
simulation.set_parameter("gamma", gamma)
simulation.set_parameter("max_steps", max_steps)
simulation.set_parameter("max_time", max_time)
simulation.set_parameter("output_name", output_name)

# set the boundary, riemann solver, and initial state of the simulation 
simulation.set_boundary_condition(boundary_condition)
simulation.set_reconstruction(reconstruction)
simulation.set_riemann_solver(riemann_solver)
simulation.set_initial_state(particles, data, particles_index)

# run the simulation
simulation.solve()
