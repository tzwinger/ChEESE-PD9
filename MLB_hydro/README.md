# Test-case 9.1 Artificial jökulhlaup in Arctic glacier

## Files in repository:
* [`mlb_geometry.sif`](mlb_geometry.sif) Elmer solver input file (SIF) initialization of geometry for initial film-pressure based on ice-overburden pressure
* [`mlb_ve_fsi_p.sif`](mlb_ve_fsi_p.sif) Elmer SIF for transient run of jökulhlaup for first 15 minutes physical time with overpressure active
* [`mlb_ve_fsi_p_ctd.sif`](mlb_ve_fsi_p_ctd.sif) Elmer SIF for restarted transient run of jökulhlaup for following 10 minutes with overpressure off
* [`mlb_hydro.lua`](mlb_hydro.lua) LUA definition file needed by SIF's
* [`outline62_lc25`](outline62_lc25) mesh subdirectory also containing the geometry information as 2D restart file

## Components
- [**gmsh**](https://gmsh.info/):
    Open source meshing tool, with which the footprint mesh has been created. This step is skipped in this workflow, as we provide the serial footprint mesh of the glacier
- [**Elmer mesh partitioner ```ElmerGrid```**](https://github.com/ElmerCSC/elmerfem/tree/devel/elmergrid):
  Serial pre-processer to convert meshes and - in our case - to create mesh partitions for distributed memory runs (MPI)
- [**Elmer/Ice**](https://github.com/ElmerCSC/elmerfem):
  High performance multi-physics, open-source Finite Element package included in Elmer
- [**ParaView**](https://www.paraview.org/):
  HPC enabled rendering software, installed on and ran via LUMI openOnDemand [remote desktop](https://lumi.csc.fi/public)


## Quick Workflow
1. **Mesh Partitioning**

     ```ElmerGrid 2 2 outline62_lc25 -partdual -metiskway N```

     where  ```N``` is the number of partitions (=MPI ranks) to run on

2. **Initialization run**

    ```mpirun -np N ElmerSolver mlb_geometry.sif```
    
    read-in of initial geometry into footprint mesh

3. **Simulation part 1**

     ```mpirun -np N ElmerSolver mlb_ve_fsi_p.sif```
     
4. **Simulation part 2 - restart test**

     ```mpirun -np N ElmerSolver mlb_ve_fsi_p_ctd.sif```

5. **Visualization**  
   launch ParaView on LUMI openOnDemand remote desktop (has built-in ParaView launchers) and load the parallel VTK-unstructured file series (```*.pvtu```)
