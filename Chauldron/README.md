# Test-case 9.2  Water transfer from a filled cauldron in synthetic setup resembling SC9.1

Files in repository:
* [`Adjust_AC.F90`](Adjust_AC.F90) Elmer solver code for computing the adaptive artificial comprossibility field; compile with `elmerf90 Adjust_AC.F90 -o Adjust_AC.so`
* [`trans_fpv_darcy_chnl_ac.sif`](trans_fpv_darcy_chnl_ac.sif) Elmer solver input file (SIF) for transient run of cauldron water transfer experiment
* [`pd9.lua`](pd9.lua) LUA definition file needed by SIF
* [`block2d.geo`](block2d.geo) gmsh definition file of footprint geometry; run with `gmsh -2 block2d.geo` 
* [`block2d`](block2d) mesh subdirectory containing foootprint mesh; create with `ElmerGrid 14 2  block2d.msh -autoclean` from output of above `gmsh`-command
