#!/bin/bash
#----------------------------------------------------
# Sample Slurm job script
#   for TACC Stampede3 SKX nodes
#
#   *** MPI Job in SKX Queue ***
# 
# Last revised: 23 April 2024
#
# Notes:
#
#   -- Launch this script by executing
#      "sbatch skx.mpi.slurm" on Stampede3 login node.
#
#   -- Use ibrun to launch MPI codes on TACC systems.
#      Do not use mpirun or mpiexec.
#
#   -- Max recommended MPI ranks per SKX node: 48
#      (start small, increase gradually).
#
#   -- If you're running out of memory, try running
#      fewer tasks per node to give each task more memory.
#
#----------------------------------------------------

#SBATCH -J jobname         # Job name
#SBATCH -o junk.o%j        # Name of stdout output file
#SBATCH -e junk.e%j        # Name of stderr error file
#SBATCH -p skx             # Queue (partition) name
#SBATCH -N 1               # Total # of nodes 
#SBATCH -n 48              # Total # of mpi tasks
#SBATCH -t 06:00:00        # Run time (hh:mm:ss)

module load hypre/2.30.0-i64 hdf5/1.14.6 blis/1.1 boost/1.86.0 vtk/9.3.0

ibrun ~/svmpWithTrilinos/svmp_trilinos_build/svMultiPhysics/build/svMultiPhysics-build/bin/svmultiphysics solver.xml         # Use ibrun instead of mpirun or mpiexec

