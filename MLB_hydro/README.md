# Test-case 9.1 Artificial jökulhlaup in Arctic glacier

Files in repository:
* [`mlb_geometry.sif`](mlb_geometry.sif) Elmer solver input file (SIF) initialization of geometry for initial film-pressure based on ice-overburden pressure
* [`mlb_ve_fsi_p.sif`](mlb_ve_fsi_p.sif) Elmer SIF for transient run of jökulhlaup for first 15 minutes physical time with overpressure active
* [`mlb_ve_fsi_p_ctd.sif`](mlb_ve_fsi_p_ctd.sif) Elmer SIF for restarted transient run of jökulhlaup for following 10 minutes with overpressure off
* [`mlb_hydro.lua`](mlb_hydro.lua) LUA definition file needed by SIF's
* [`outline62_lc25`](outline62_lc25) mesh subdirectory also containing the geometry information as 2D restart file
