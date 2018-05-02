PROGRAM RiemannProblem

  USE KindModule, ONLY: &
    DP, Pi, TwoPi
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
  USE GeometryComputationModule, ONLY: &
    ComputeGeometryX
  USE FluidFieldsModule, ONLY: &
    uCF, uPF, uAF
  USE InputOutputModuleHDF, ONLY: &
    WriteFieldsHDF
  USE InitializationModule_GR, ONLY: &
    InitializeFields_RiemannProblem
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
  USE RiemannProblemInitializer, ONLY: &
    RiemannProblemChoice


  IMPLICIT NONE

  INTEGER  :: iCycle, iCycleD, iCycleW, K,  bcX(3)
  REAL(DP) :: t, dt, t_end, xL, xR, x_D, CFL, Gamma, c = 1.0_DP
  REAL(DP) :: D_L, V_L(3), P_L, D_R, V_R(3), P_R

  REAL(DP)             :: LT
  CHARACTER( len = 4 ) :: arg
  INTEGER              :: argv(2), nNodes, i
  LOGICAL              :: ConvergenceRate = .FALSE.

  CALL RiemannProblemChoice &
         ( D_L, V_L, P_L, D_R, V_R, P_R, &
             xL, xR, x_D, K, t, t_end, CFL, Gamma, bcX, iRP = 12 )

  IF ( ConvergenceRate ) THEN
    DO i = 1 , IARGC()
      CALL GETARG( i , arg )
      READ( arg , * ) argv(i)
    END DO
    nNodes = argv(1)
    K      = argv(2)
  ELSE
     nNodes = 1
     K      = 1024
  END IF
  
  IF      ( nNodes == 1 ) THEN
    LT = 0.001_DP
  ELSE IF ( nNodes == 2 ) THEN ! Experimentally found to be the best
    LT = 0.1_DP
  ELSE IF ( nNodes == 3 ) THEN
    LT = 0.1_DP
  ELSE
    LT = 1.0_DP
  END IF

  CALL InitializeProgram &
         ( ProgramName_Option &
             = 'RiemannProblem', &
           nX_Option &
             = [ K, 1, 1 ], &
           swX_Option &
             = [ 1, 0, 0 ], &
           bcX_Option &
             = bcX, &
           xL_Option &
             = [ xL, 0.0d0, 0.0d0 ], &
           xR_Option &
             = [ xR, Pi, TwoPi ], &
           nNodes_Option &
             = nNodes, &
           CoordinateSystem_Option &
             = 'SPHERICAL', &
           EquationOfState_Option &
             = 'IDEAL', &
           FluidRiemannSolver_Option & ! --- Dummy ---
             = 'HLLC', &
           Gamma_IDEAL_Option &
             = Gamma, &
           Opacity_Option &
             = 'IDEAL', &
           nStages_SSP_RK_Option & ! --- Dummy ---
             = 3 )

  dt      = CFL * ( xR - xL ) / ( c * K )
  iCycleD = 100
  iCycleW = 100

  CALL InitializeReferenceElementX

  CALL InitializeReferenceElementX_Lagrange

  CALL ComputeGeometryX &
         ( iX_B0, iX_E0, iX_B1, iX_E1, uGF )

  CALL InitializeFields_RiemannProblem &
         ( D_L = D_L, V_L = V_L, P_L = P_L, &
           D_R = D_R, V_R = V_R, P_R = P_R, &
           X_D_Option = x_D )

  CALL WriteFieldsHDF &
         ( t, WriteGF_Option = .TRUE., WriteFF_Option = .TRUE. )

  CALL InitializeFluid_SSPRK( nStages = 3 )

  CALL InitializeSlopeLimiter &
         ( BetaTVD_Option = 1.7_DP, BetaTVB_Option = 0.0_DP, &
           LimiterThreshold_Option = LT, &
           UseSlopeLimiter_Option = .TRUE. , &
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
      t  = t_end
    END IF

    iCycle = iCycle + 1

    IF( MOD( iCycle, iCycleD ) == 0 )THEN

      WRITE(*,'(A8,A8,I8.8,A2,A4,ES12.6E2,A1,A5,ES12.6E2)') &
          '', 'Cycle = ', iCycle, '', 't = ',  t, '', 'dt = ', dt

    END IF

    CALL UpdateFluid_SSPRK &
         ( t, dt, uGF, uCF, ComputeIncrement_Euler_GR_DG_Explicit )

    ! --- Update primitive fluid variables, pressure, and sound speed
    CALL ComputeFromConserved( iX_B0, iX_E0, uGF, uCF, uPF, uAF )

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

  CALL FinalizeReferenceElementX

  CALL FinalizeReferenceElementX_Lagrange

  CALL FinalizeProgram

END PROGRAM RiemannProblem
