# svMultiPhysics Installation on Stampede (TACC)

This document provides complete, step-by-step instructions to build **svMultiPhysics (SVMP)** on the **Stampede (TACC)** cluster, either **with Trilinos support** or **without Trilinos**.  
All builds are performed using provided scripts and are intended to be reproducible by all users.

---

## ⚠️ Important Notes

- **Do NOT build on the login node**.
- Compilation **must** be done on an **interactive compute node**.
- Build scripts use **8 processors by default**.
- If you request a different number of cores, update the script accordingly.
- Trilinos+SVMP installation will take roughly 4.5 GB on disk. Stampede allows a limit of 14.0 GB on $HOME and 1.0 TB on $WORK.
- Users may choose to build the Trilinos-enabled SVMP on $WORK directory by following the below steps after "cd $WORK".
- Do not purge modules on Stampede as it loads the required default environment in which the following will work.

---

## 1. Request an Interactive Node

Before running any installation script, request an interactive node:

```bash
idev -N 1 -n 8 -p skx-dev -t 2:00:00
```

This will request:
* -N 1 -> 1 Node
* -n 8 -> 8 CPUs
* -p skx_dev -> Partition skx_dev
* -t 2:00:00 -> Time 2 hours

---

## 2. Create a Working Directory

It is recommended to run the build from a clean directory from your home folder

# Build with Trilinos

```bash
mkdir svmpWithTrilinos
cd svmpWithTrilinos
```

# Build without Trilinos 
```bash
mkdir svmpWithoutTrilinos
cd svmpWithoutTrilinos
```
---

## 3. Installation Scripts

Two installation scripts are provided.

1️⃣ install_trilinos_svmp_stampede.sh (With Trilinos)

This script:
* Loads required TACC modules
* Builds Trilinos from source
* Applies required Intel/MPI compatibility fixes automatically
* Builds svMultiPhysics with Trilinos enabled

Use this script if you need Trilinos-based solvers.

2️⃣ install_svmp_stampede.sh (Without Trilinos)
This script:
* Loads required modules
* Builds svMultiPhysics only
* Faster and simpler build (no Trilinos dependency)

Use this script if you do not need Trilinos.

---

## 4. Make the Script Executable

Run this once before execution:
```bash
chmod +x install_trilinos_svmp_stampede.sh
```
or
```bash
chmod +x install_svmp_stampede.sh
```
---

## 5. Run the Script
With Trilinos
```bash
./install_trilinos_svmp_stampede.sh
```
Without Trilinos
```bash
./install_svmp_stampede.sh
```
The build runs in parallel using 8 processors by default.
If you requested a different number of cores with idev, edit the script and update:

JOBS=8 

---

## 6. Automatic Fixes Applied (Trilinos Build Only)

The Trilinos installation script automatically applies two critical fixes to avoid known Stampede + Intel compiler issues:

1. MPI linking fix
  * Replaces legacy MPI variables with MPI::MPI_CXX

2. Intel compiler compatibility fix
   * Adds #include <cstring> to avoid memset compilation errors

These fixes are applied before building svMultiPhysics.

---

## 7. Expected Directory Structure

**With Trilinos**

svmpWithTrilinos/
└── svmp_trilinos_build/
    ├── Trilinos/
    ├── Trilinos-build/
    ├── trilinos-cpu/
    └── svMultiPhysics/

**Without Trilinos**

svmpWithoutTrilinos/
└── svMultiPhysics/

## 8. Sample Job Script

A sample job script is provided as well to load the modules and run the simulations using SVMP.
