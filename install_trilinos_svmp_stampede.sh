#!/usr/bin/env bash
set -euo pipefail

# =========================
# svMultiPhysics build script (Stampede/TACC style)
# To build svMultiPhysics with Trilinos
# First this will install Trilinos and then SVMP
# =========================

module load hypre/2.30.0-i64 hdf5/1.14.6 blis/1.1 boost/1.86.0 vtk/9.3.0

# ----------------------------
# Run the script from the folder you want everything to fall under
# ----------------------------
# Put everything under a single workspace folder


WORKDIR="$PWD/svmp_trilinos_build"
TRILINOS_SRC="$WORKDIR/Trilinos"
TRILINOS_BLD="$WORKDIR/Trilinos-build"
TRILINOS_INSTALL="$WORKDIR/trilinos-cpu"

SVMP_SRC="$WORKDIR/svMultiPhysics"
SVMP_BLD="$SVMP_SRC/build"

# Parallel build
JOBS=8

mkdir -p "$WORKDIR"

# ----------------------------
# Trilinos: clone + build + install
# ----------------------------

echo "==> Cloning Trilinos..."
git clone https://github.com/trilinos/Trilinos.git "$TRILINOS_SRC"

mkdir -p "$TRILINOS_BLD"
cd "$TRILINOS_BLD"

echo "==> Configuring Trilinos..."
cmake \
  -DCMAKE_INSTALL_PREFIX="$TRILINOS_INSTALL" \
  -DTPL_ENABLE_MPI=ON \
  -DTPL_ENABLE_Boost=ON \
  -DBoost_LIBRARY_DIRS=/home1/apps/intel24/boost/1.86.0/lib \
  -DBoost_INCLUDE_DIRS=/home1/apps/intel24/boost/1.86.0/include \
  -DTPL_ENABLE_BLAS=ON \
  -DTPL_BLAS_LIBRARIES=/home1/apps/intel24/blis/1.1/lib/libblis.a \
  -DTPL_BLAS_INCLUDE_DIRS=/home1/apps/intel24/blis/1.1/include \
  -DTPL_ENABLE_HDF5=ON \
  -DHDF5_LIBRARY_DIRS=/home1/apps/intel24/hdf5/1.14.6/lib \
  -DHDF5_INCLUDE_DIRS=/home1/apps/intel24/hdf5/1.14.6/include \
  -DTPL_ENABLE_HYPRE=ON \
  -DHYPRE_LIBRARY_DIRS=/opt/apps/intel24/impi21/hypre/2.30.0/i64/lib \
  -DHYPRE_INCLUDE_DIRS=/opt/apps/intel24/impi21/hypre/2.30.0/i64/include \
  -DTPL_ENABLE_LAPACK=ON \
  -DTPL_LAPACK_LIBRARIES=/home1/apps/intel24/blis/1.1/lib/libblis.a \
  -DTPL_LAPACK_INCLUDE_DIRS=/home1/apps/intel24/blis/1.1/include \
  -DCMAKE_C_COMPILER=/opt/intel/oneapi/mpi/2021.11/bin/mpicc \
  -DCMAKE_CXX_COMPILER=/opt/intel/oneapi/mpi/2021.11/bin/mpicxx \
  -DCMAKE_Fortran_COMPILER=/opt/intel/oneapi/mpi/2021.11/bin/mpif90 \
  -DTPL_ENABLE_gtest=OFF \
  -DTrilinos_ENABLE_MueLu=ON \
  -DTrilinos_ENABLE_ROL=ON \
  -DTrilinos_ENABLE_Sacado=ON \
  -DTrilinos_ENABLE_Teuchos=ON \
  -DTrilinos_ENABLE_Zoltan=ON \
  -DTrilinos_ENABLE_Tpetra=ON \
  -DTrilinos_ENABLE_Belos=ON \
  -DTrilinos_ENABLE_Ifpack2=ON \
  -DTrilinos_ENABLE_Amesos2=ON \
  -DTrilinos_ENABLE_Zoltan2=ON \
  -DTrilinos_ENABLE_Kokkos=ON \
  -DKokkos_ENABLE_SERIAL=ON \
  -DTrilinos_ENABLE_KokkosKernels=ON \
  -DTrilinos_ENABLE_Xpetra=ON \
  -DXpetra_ENABLE_Kokkos_compat=ON \
  -DTrilinos_ENABLE_EXPLICIT_INSTANTIATION=ON \
  -DTpetra_INST_SERIAL=ON \
  -DTpetra_INST_DOUBLE=ON \
  -DTpetra_INST_INT_INT=ON \
  -DMueLu_ENABLE_EXPLICIT_INSTANTIATION=ON \
  "$TRILINOS_SRC"

echo "==> Building + Installing Trilinos..."
make -j${JOBS}
make install

# ----------------------------
# svMultiPhysics: clone
# ----------------------------

cd "$WORKDIR"
echo "==> Cloning svMultiPhysics..."
git clone https://github.com/SimVascular/svMultiPhysics.git

# ----------------------------
# Apply documented fixes BEFORE building svMultiPhysics
# ----------------------------

echo "==> Applying svMultiPhysics patches..."

# (Fix 1) MPI linking change in Code/Source/liner_solver/CMakeLists.txt

LS_CMAKE="$SVMP_SRC/Code/Source/liner_solver/CMakeLists.txt"

if grep -q 'target_link_libraries(${lib} ${MPI_LIBRARY} ${MPI_Fortran_LIBRARIES})' "$LS_CMAKE"; then
  sed -i 's|target_link_libraries(${lib} ${MPI_LIBRARY} ${MPI_Fortran_LIBRARIES})|target_link_libraries(${lib} MPI::MPI_CXX ${MPI_Fortran_LIBRARIES})|g' "$LS_CMAKE"
  echo "  - Patched MPI target_link_libraries in liner_solver/CMakeLists.txt"
else
  echo "  - MPI link line not found (maybe already patched)."
fi

# (Fix 2) Add #include <cstring> in Code/Source/solver/Vector.h (only if missing)
VEC_H="$SVMP_SRC/Code/Source/solver/Vector.h"

if ! grep -q '^#include <cstring>' "$VEC_H"; then
  # Insert after the first #include line (portable sed)
  sed -i '0,/^#include/{/^#include/a #include <cstring>/}' "$VEC_H" 2>/dev/null || {
    # Fallback if sed doesn't support -i the same way: write to temp file
    awk '
      BEGIN{added=0}
      /^#include/ && added==0 {print; print "#include <cstring>"; added=1; next}
      {print}
    ' "$VEC_H" > "${VEC_H}.tmp" && mv "${VEC_H}.tmp" "$VEC_H"
  }
  echo "  - Added #include <cstring> to solver/Vector.h"
else
  echo "  - #include <cstring> already present in solver/Vector.h"
fi

# ----------------------------
# Build svMultiPhysics with Trilinos enabled
# ----------------------------

export CMAKE_PREFIX_PATH="$TRILINOS_INSTALL:$CMAKE_PREFIX_PATH"
export Trilinos_DIR="$TRILINOS_INSTALL/lib64/cmake/Trilinos"

mkdir -p "$SVMP_BLD"
cd "$SVMP_BLD"

echo "==> Configuring svMultiPhysics (SV_USE_TRILINOS=ON)..."
cmake .. \
  -DSV_USE_TRILINOS:BOOL=ON \
  -DTrilinos_DIR="$TRILINOS_INSTALL" \
  -DCMAKE_C_COMPILER=mpiicc \
  -DCMAKE_CXX_COMPILER=mpiicpc

echo "==> Building svMultiPhysics..."
make -j${JOBS}

echo "==> DONE"
echo "Trilinos install: $TRILINOS_INSTALL"
echo "svMultiPhysics build: $SVMP_BLD"
