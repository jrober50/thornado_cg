PROGRAM StandingAccretionShock

  USE KindModule, ONLY: &
    DP, Pi, TwoPi, Two
  USE UnitsModule, ONLY: &
    Meter, Second, SpeedOfLight, Millisecond
  USE ProgramHeaderModule, ONLY: &
    iX_B0, iX_B1, iX_E0, iX_E1
  USE ProgramInitializationModule, ONLY: &
    InitializeProgram, &
    FinalizeProgram
  USE ReferenceElementModuleX, ONLY: &
    InitializeReferenceElementX, &
    FinalizeReferenceElementX
  USE ReferenceElementModuleX_Lagrange, ONLY: &
    InitializeReferenceElementX_Lagrange, &
    FinalizeReferenceElementX_Lagrange
  USE PositivityLimiterModule, ONLY: &
    InitializePositivityLimiter, &
    FinalizePositivityLimiter
  USE GeometryFieldsModule, ONLY: &
    uGF
  USE GeometryComputationModule_Beta, ONLY: &
    ComputeGeometryX
  USE FluidFieldsModule, ONLY: &
    uCF, uPF, uAF
  USE InputOutputModuleHDF, ONLY: &
    WriteFieldsHDF
  USE InitializationModule_GR, ONLY: &
    InitializeFields_StandingAccretionShock
  USE TimeSteppingModule_SSPRK, ONLY: &
    InitializeFluid_SSPRK, &
    FinalizeFluid_SSPRK, &
    UpdateFluid_SSPRK
  USE SlopeLimiterModule_Euler_GR, ONLY: &
    InitializeSlopeLimiter, &
    FinalizeSlopeLimiter
  USE dgDiscretizationModule_Euler_GR, ONLY: &
    ComputeIncrement_Euler_GR_DG_Explicit
  USE EulerEquationsUtilitiesModule_Beta_GR, ONLY: &
    ComputeFromConserved
  USE EquationOfStateModule, ONLY: &
    InitializeEquationOfState, &
    FinalizeEquationOfState
  USE DataFileReaderModule, ONLY: &
    ReadData, ReadParameters

  IMPLICIT NONE

  REAL(DP), ALLOCATABLE :: FluidFieldData(:,:), FluidFieldParameters(:)
  REAL(DP), ALLOCATABLE :: r(:), rho(:), v(:), e(:)
  INTEGER               :: nLines, iCycle, iCycleD, iCycleW, K
  REAL(DP)              :: M_PNS, gamma, Ri, R_PNS, R_shock, Rf, Mdot
  REAL(DP)              :: t, dt, t_end, CFL, xL, xR, dt_write

  CALL ReadParameters &
         ( '../StandingAccretionShock_Parameters.dat', FluidFieldParameters )

  M_PNS   = FluidFieldParameters(1)
  Gamma   = FluidFieldParameters(2)
  Ri      = FluidFieldParameters(3)
  R_PNS   = FluidFieldParameters(4)
  R_shock = FluidFieldParameters(5)
  Rf      = FluidFieldParameters(6)
  Mdot    = FluidFieldParameters(7)

  CALL ReadData &
         ( '../StandingAccretionShock_Data.dat', nLines, FluidFieldData )

  r   = FluidFieldData(1,:)
  rho = FluidFieldData(2,:)
  v   = FluidFieldData(3,:)
  e   = FluidFieldData(4,:)

  xL = R_PNS
  xR = Two * R_shock
  K  = 512
  CALL InitializeProgram &
         ( ProgramName_Option &
             = 'StandingAccretionShock', &
           nX_Option &
             = [ K, 1, 1 ], &
           swX_Option &
             = [ 1, 0, 0 ], &
           bcX_Option &
             = [ 10, 3, 1 ], &
           xL_Option &
             = [ xL, 0.0_DP, 0.0_DP ], &
           xR_Option &
             = [ xR, Pi, 4.0_DP ], &
           nNodes_Option &
             = 1, &
           CoordinateSystem_Option &
             = 'SPHERICAL', &
           ActivateUnits_Option &
             = .TRUE., &
           BasicInitialization_Option &
             = .TRUE. )

  CALL InitializeEquationOfState &
         ( EquationOfState_Option = 'IDEAL', &
           Gamma_IDEAL_Option = Gamma )

  CFL      = 0.4d0
  t_end    = 1.0d2 * Millisecond
  dt       = CFL * ( xR - xL ) / ( SpeedOfLight * K )
  dt_write = 0.1d0 * Millisecond

  iCycleD = dt_write / dt
  iCycleW = dt_write / dt

  CALL InitializeReferenceElementX

  CALL InitializeReferenceElementX_Lagrange

  CALL ComputeGeometryX &
         ( iX_B0, iX_E0, iX_B1, iX_E1, uGF, Mass_Option = M_PNS )

!!$  WRITE(*,*) 'Min/Max SqrtGm:' , MINVAL( uGF(:,:,:,:,8) ) / R_shock**2, &
!!$                                 MAXVAL( uGF(:,:,:,:,8) ) / R_shock**2
!!$  WRITE(*,*) 'Min/Max Alpha: ' , MINVAL( uGF(:,:,:,:,9) ), &
!!$                                 MAXVAL( uGF(:,:,:,:,9) )
!!$  WRITE(*,*) 'Min/Max Psi:   ' , MINVAL( uGF(:,:,:,:,13) ), &
!!$                                 MAXVAL( uGF(:,:,:,:,13) )
!!$  

  CALL InitializeFields_StandingAccretionShock

  CALL WriteFieldsHDF &
         ( 0.0_DP, WriteGF_Option = .TRUE., WriteFF_Option = .TRUE. )

  CALL InitializeFluid_SSPRK( nStages = 3 )

  CALL InitializeSlopeLimiter &
         ( BetaTVD_Option = 1.5_DP, &
           UseSlopeLimiter_Option = .TRUE., &
           UseTroubledCellIndicator_Option = .TRUE. )

  CALL InitializePositivityLimiter &
         ( Min_1_Option = 1.0d-16 , Min_2_Option = 1.0d-16, &
           UsePositivityLimiter_Option = .TRUE. )

  iCycle = 0

  DO WHILE ( t < t_end )

    IF( t + dt < t_end )THEN
       t = t + dt
    ELSE
       dt = t_end - t
       t = t_end
    END IF

    iCycle = iCycle + 1

    IF( MOD( iCycle, iCycleD ) == 0 )THEN

      WRITE(*,'(A8,A8,I8.8,A2,A4,ES13.6E3,A3,A5,ES13.6E3,A2)') &
             '', 'Cycle = ', iCycle, '', 't = ',  t / Millisecond, 'ms ', &
               'dt = ', dt / Millisecond, 'ms'

    END IF

    CALL UpdateFluid_SSPRK &
           ( t, dt, uGF, uCF, ComputeIncrement_Euler_GR_DG_Explicit )

    ! --- Update primitive fluid variables, pressure, and sound speed ---
    CALL ComputeFromConserved( iX_B0, iX_E0, uGF, uCF, uPF, uAF )

!!$    WRITE(*,*) 'CALL ComputeGeometryX'
!!$    CALL ComputeGeometryX &
!!$           ( iX_B0, iX_E0, iX_B1, iX_E1, uGF, Mass_Option = M_PNS )
!!$
!!$    WRITE(*,*) 'Min/Max SqrtGm:' , MINVAL( uGF(:,:,:,:,8) ) / R_shock**2, &
!!$                                   MAXVAL( uGF(:,:,:,:,8) ) / R_shock**2
!!$    WRITE(*,*) 'Min/Max Alpha: ' , MINVAL( uGF(:,:,:,:,9) ), &
!!$                                   MAXVAL( uGF(:,:,:,:,9) )
!!$    WRITE(*,*) 'Min/Max Psi:   ' , MINVAL( uGF(:,:,:,:,13) ), &
!!$                                   MAXVAL( uGF(:,:,:,:,13) )
  
    IF( MOD( iCycle, iCycleW ) == 0 )THEN

      CALL WriteFieldsHDF &
             ( t, WriteGF_Option = .TRUE., WriteFF_Option = .TRUE. )

    END IF

  END DO

  CALL WriteFieldsHDF &
         ( t, WriteGF_Option = .TRUE., WriteFF_Option = .TRUE. )

  CALL FinalizePositivityLimiter

  CALL FinalizeSlopeLimiter

  CALL FinalizeFluid_SSPRK

  CALL FinalizeReferenceElementX_Lagrange

  CALL FinalizeReferenceElementX

  CALL FinalizeEquationOfState

  CALL FinalizeProgram

  DEALLOCATE( FluidFieldParameters, FluidFieldData )

END PROGRAM StandingAccretionShock
