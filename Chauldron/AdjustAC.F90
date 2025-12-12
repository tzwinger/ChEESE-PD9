!------------------------------------------------------------------------------
!> Subroutine for computingadjusting the artificial compressibility from
!>  geometry . 
!> \ingroup Solvers
!------------------------------------------------------------------------------
SUBROUTINE AdjustAC( Model,Solver,dt,Transient )
!------------------------------------------------------------------------------
  USE DefUtils
  IMPLICIT NONE
!------------------------------------------------------------------------------
  TYPE(Solver_t) :: Solver   !< Linear & nonlinear equation solver options
  TYPE(Model_t) :: Model     !< All model information (mesh, materials, BCs, etc...)
  REAL(KIND=dp) :: dt        !< Timestep size for time dependent simulations
  LOGICAL :: Transient !< Steady state or transient simulation
!------------------------------------------------------------------------------
! Local variables
!------------------------------------------------------------------------------
 
  CHARACTER(*), PARAMETER :: Caller = 'AdjustAC'
  TYPE(Mesh_t), POINTER :: Mesh
  TYPE(Element_t), POINTER :: Element
  TYPE(Matrix_t), POINTER :: Matrix
  TYPE(Variable_t), POINTER :: ACVar, VolVar, GapVar, DepthVar, ContactVar
  TYPE(ValueList_t), POINTER :: Params
  TYPE(Nodes_t) :: ElementNodes
  TYPE(GaussIntegrationPoints_t) :: IntegStuff
  
  REAL(KIND=dp) ::  AveragedHeight, AveragedDepth, TotalArea, TotalVolume, LocalVol, TotalVol, TotalDepthVol, &
       ReferenceLength, D, K, SqrtElementMetric,s, U,V,W,Basis(Model % MaxElementNodes), miny, maxy, &
       globalminy, globalmaxy, globalArea, globalVol, globalDepthVol, &
       localArea, localVolume, localDepthVol, elementAverageGap,fact(2)


  INTEGER :: i,j,n,Active,detachedelements=0, globaldetachedelements=0, elements,  globalelements, ierr, NMAX
  REAL(KIND=dp), PARAMETER :: E=9.0e9, nu=0.45
  INTEGER, POINTER :: ACPerm(:), VolPerm(:), GapPerm(:), DepthPerm(:), ContactPerm(:), NodeIndexes(:)
  REAL(KIND=dp), POINTER :: AC(:), Vol(:), Gap(:), Depth(:), Contact(:)
  LOGICAL :: stat, ALlocationsDone=.FALSE., Found

  SAVE ElementNodes, AllocationsDone
  
  IF ( AllocationsDone ) THEN
    DEALLOCATE( ElementNodes % x,    &
         ElementNodes % y,    &
         ElementNodes % z)
  END IF
  NMAX = Model % MaxElementNodes
  ALLOCATE( ElementNodes % x( NMAX ),    &
       ElementNodes % y( NMAX ),    &
       ElementNodes % z( NMAX ))
  ALlocationsDone = .TRUE.
  
  Params => Solver % Values
  fact = 1.0_dp
  fact(1) = GetConstReal(Params, "AC multiplication factor 1", Found)
  IF (.NOT.Found) THEN
    CALL INFO(Caller, "AC multiplication factor 1 not found and set to unity", Level=1)
  END IF
  fact(2) = GetConstReal(Params, "AC multiplication factor 2", Found)
  IF (.NOT.Found) THEN
    CALL INFO(Caller, "AC multiplication factor 2 not found and set to unity", Level=1)
  END IF
  
  Mesh => Solver % Mesh
  
  globalArea = 0.0_dp
  globalVol = 0.0_dp
  globalDepthVol = 0.0_dp
  globaldetachedelements = 0
  globalelements = 0
  localArea = 0.0_dp
  localVolume = 0.0_dp
  localDepthVol = 0.0_dp
  detachedelements = 0
  elements = 0
  
  CALL INFO(Caller, "#############################",Level=1)
  CALL INFO(Caller, "Initialization", Level=1)
  CALL INFO(Caller, "#############################",Level=1)

  ! get pointers to variables
  ACVar => Solver % Variable
  IF (.NOT.ASSOCIATED(ACVar)) CALL FATAL(Caller,"Solver variable not associated")
  ACPerm => ACVar % Perm
  AC => ACVar % Values
  !PRINT *, "1-----------"
  VolVar => VariableGet(Mesh % Variables, 'Channel Volume', .TRUE., UnfoundFatal=.TRUE.)
  !IF (.NOT.ASSOCIATED(VolVar)) CALL FATAL(Caller,"Channel Volume not associated")
  !PRINT *, "2.0-----------"
  VolPerm => VolVar % Perm
  Vol => VolVar % Values
  !PRINT *, "2.1-----------"
  Vol(1) = 0.0_dp
  !PRINT *, "2.2-----------"   
  GapVar => VariableGet(Mesh % Variables, 'Gap Disp', .TRUE., UnfoundFatal=.TRUE.)
  GapPerm => GapVar % Perm
  Gap => GapVar % Values
  !PRINT *, "3-----------" 
  DepthVar => VariableGet(Mesh % Variables, 'Depth', .TRUE., UnfoundFatal=.TRUE.)
  DepthPerm => DepthVar % Perm
  Depth => DepthVar % Values
  !PRINT *, "4-----------"   
  !ContactVar => VariableGet(Mesh % Variables, 't contact active 3', .TRUE., UnfoundFatal=.TRUE.)
  !ContactPerm => ContactVar % Perm
  !Contact => ContactVar % Values
  !PRINT *, "5-----------"   
  CALL INFO(Caller, "All variables assigned",Level=3)
  
  ! hard-coded bounding box values for PD9
  miny=508000.0_dp
  maxy=492000.0_dp

  !PRINT *, "6-----------" 
  ! loop all elements
  Active = GetNOFActive()
  !PRINT *, "7-----------", Active
  
  AC = 0.0_dp

  !PRINT *, "8-----------"
  !IF (ParEnv % MyPe == 0) PRINT *,"9-------------"
  
  DO i=1,Active
    Element => GetActiveElement(i)
    LocalVol = 0.0_dp
    elements = elements + 1
 
    n = Element % TYPE % NumberOfNodes
    NodeIndexes => Element % NodeIndexes


    !PRINT *,"10-------------", i, Active, n 
    !ElementNodes % x(1:n) = Mesh % Nodes % x(NodeIndexes(1:n))
    !ElementNodes % y(1:n) = Mesh % Nodes % y(NodeIndexes(1:n))
    !DO j=1,n
    !  IF (ElementNodes % y(j) < miny) miny = ElementNodes % y(j)
    !  IF (ElementNodes % y(j) > maxy) maxy = ElementNodes % y(j)
    !END DO

    !PRINT *,"11-------------"
    
    ElementNodes % z(1:n) = Mesh % Nodes % z(NodeIndexes(1:n))

    IntegStuff = GaussPoints( Element )
    
    !elementAverageGap = SUM(Gap(GapPerm(NodeIndexes(1:n))))/(1.0_dp*n)
    !PRINT *, Gap(GapPerm(NodeIndexes(1:n)))
    !IF (ANY(Contact(ContactPerm(NodeIndexes(1:n))) > -0.5)) THEN
    !PRINT *,"12-------------"
    !IF (ANY(Gap(GapPerm(NodeIndexes(1:n))) > 0.001)) PRINT *, Gap(GapPerm(NodeIndexes(1:n)))
    !IF (elementAverageGap > 0.001_dp) THEN
    IF (ANY(Gap(GapPerm(NodeIndexes(1:n))) > 0.002)) THEN
      detachedelements = detachedelements + 1
      ElementNodes % x(1:n) = Mesh % Nodes % x(NodeIndexes(1:n))
      ElementNodes % y(1:n) = Mesh % Nodes % y(NodeIndexes(1:n))
      DO j=1,n
        IF (ElementNodes % y(j) < miny) miny = ElementNodes % y(j)
        IF (ElementNodes % y(j) > maxy) maxy = ElementNodes % y(j)
      END DO
      !PRINT *, Contact(ContactPerm(NodeIndexes(1:n)))
      DO j=1,IntegStuff % n

        U = IntegStuff % u(j)
        V = IntegStuff % v(j)
        W = IntegStuff % w(j)

        !------------------------------------------------------------------------------
        !        Basis function values at the integration point
        !------------------------------------------------------------------------------
        stat = ElementInfo( Element,ElementNodes,U,V,W,SqrtElementMetric, &
             Basis )

      
        !assume cartesian here
        s = SqrtElementMetric * IntegStuff % s(j)

        !Check here for grounded
        localDepthVol = localDepthVol + s * SUM(Depth(DepthPerm(NodeIndexes(1:n))) * Basis(1:n))
        localVol = localVol + s * SUM(Gap(GapPerm(NodeIndexes(1:n))) * Basis(1:n))
        localArea = localArea + s
      END DO
      AC(ACPerm(NodeIndexes(1:n))) = fact(1)
      !PRINT *, "hit"
    ELSE
      AC(ACPerm(NodeIndexes(1:n))) = fact(2)
      !PRINT *, "miss"
    END IF
  END DO

   !PRINT *,"13-------------" 
  ! Reduce information across MPI ranks (if there are)
  IF (ParEnv % PEs > 1) THEN
    CALL MPI_ALLREDUCE(localDepthVol, globalDepthVol, 1, MPI_DOUBLE_PRECISION, MPI_SUM, ELMER_COMM_WORLD, ierr)
    CALL MPI_ALLREDUCE(localVol, globalVol, 1, MPI_DOUBLE_PRECISION, MPI_SUM, ELMER_COMM_WORLD, ierr)
    CALL MPI_ALLREDUCE(localArea, globalArea, 1, MPI_DOUBLE_PRECISION, MPI_SUM, ELMER_COMM_WORLD, ierr)
    CALL MPI_ALLREDUCE(detachedelements, globaldetachedelements, 1, MPI_INTEGER, MPI_SUM, ELMER_COMM_WORLD, ierr)
    CALL MPI_ALLREDUCE(elements, globalelements, 1, MPI_INTEGER, MPI_SUM, ELMER_COMM_WORLD, ierr)
    CALL MPI_ALLREDUCE(miny, globalminy, 1, MPI_DOUBLE_PRECISION, MPI_MIN, ELMER_COMM_WORLD, ierr)
    CALL MPI_ALLREDUCE(maxy, globalmaxy, 1, MPI_DOUBLE_PRECISION, MPI_MAX, ELMER_COMM_WORLD, ierr)
  END IF

  !PRINT *,"14-------------"
  Vol(1) = globalVol
  
  AveragedHeight = globalVol/globalArea                                                                                                                     
  AveragedDepth =  MAX(globalDepthVol/globalArea, 500.0_dp)   

  !PRINT *,"15-------------"   
  
  ! do the maths and set value of primed (0,1) AC-field
  IF (globaldetachedelements == 0) THEN
    ReferenceLength = 1000.0
  ELSE
    ReferenceLength = MAX(globalmaxy - globalminy, 1000.0_dp)
  END IF
  D=E*AveragedDepth**3.0_dp/(12.0_dp*(1.0_dp-nu**2.0_dp))
  K=D*24.0_dp*(16.0_dp/5.0_dp)/(ReferenceLength**4.0_dp)
  AC=AC/K
  
  WRITE(Message,*) "det.el:", globaldetachedelements, "total elmts:", globalelements
  CALL INFO(Caller,Message, Level=3)
  WRITE(Message,*) "AC0=1/K=", 1.0/K,"H=", AveragedDepth, ", L=", ReferenceLength,"=",globalmaxy, "-", globalminy
  CALL INFO(Caller,Message, Level=3) 
END SUBROUTINE AdjustAC
