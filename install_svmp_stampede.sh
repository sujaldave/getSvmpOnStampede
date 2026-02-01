#!/usr/bin/env bash
set -euo pipefail

# =========================
# svMultiPhysics build script (Stampede/TACC style)
# =========================

# How many compile threads to use
# Change if you are using an interactive node
JOBS=8

echo "==> Loading additional necessary modules..."
module load vtk/9.3.0

echo "==> Cloning repo"
git clone https://github.com/SimVascular/svMultiPhysics.git

cd svMultiPhysics && mkdir build && cd build

cmake ..

make -j"${JOBS}" 
