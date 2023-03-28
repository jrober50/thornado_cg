MODULE MF_TwoMoment_PositivityLimiterModule

  ! --- AMReX Modules ---

  USE amrex_box_module, ONLY: &
    amrex_box
  USE amrex_geometry_module, ONLY: &
    amrex_geometry
  USE amrex_multifab_module, ONLY: &
    amrex_multifab, &
    amrex_mfiter, &
    amrex_mfiter_build, &
    amrex_mfiter_destroy
  USE amrex_parallel_module, ONLY: &
    amrex_parallel_ioprocessor

  ! --- thornado Modules ---

  USE ProgramHeaderModule, ONLY: &
    swX, &
    swE, &
    nDOFX, &
    nDOFE, &
    nDOFZ, &
    iE_B0, &
    iE_E0, &
    iE_B1, &
    iE_E1
  USE GeometryFieldsModule, ONLY: &
    nGF
  USE GeometryFieldsModuleE, ONLY: &
    nGE, &
    uGE
  USE RadiationFieldsModule, ONLY: &
    nCR
  USE FluidFieldsModule, ONLY: &
    nCF
  USE TwoMoment_PositivityLimiterModule, ONLY: &
    InitializePositivityLimiter_TwoMoment, &
    FinalizePositivityLimiter_TwoMoment, &
    ApplyPositivityLimiter_TwoMoment

  ! --- Local Modules ---

  USE MF_KindModule, ONLY: &
    DP
  USE MF_UtilitiesModule, ONLY: &
    amrex2thornado_X, &
    amrex2thornado_Z, &
    thornado2amrex_Z, &
    AllocateArray_X, &
    DeallocateArray_X, &
    AllocateArray_Z, &
    DeallocateArray_Z
  USE InputParsingModule, ONLY: &
    UsePositivityLimiter_TwoMoment, &
    Min_1_TwoMoment, &
    Min_2_TwoMoment, &
    nLevels, &
    nSpecies, &
    UseTiling, &
    nE

  IMPLICIT NONE
  PRIVATE

  PUBLIC :: InitializePositivityLimiter_TwoMoment_MF
  PUBLIC :: FinalizePositivityLimiter_TwoMoment_MF
  PUBLIC :: ApplyPositivityLimiter_TwoMoment_MF

CONTAINS


  SUBROUTINE InitializePositivityLimiter_TwoMoment_MF

    CALL InitializePositivityLimiter_TwoMoment &
           ( Min_1_Option = Min_1_TwoMoment, &
             Min_2_Option = Min_2_TwoMoment, &
             UsePositivityLimiter_Option &
               = UsePositivityLimiter_TwoMoment, &
             Verbose_Option = amrex_parallel_ioprocessor() )

  END SUBROUTINE InitializePositivityLimiter_TwoMoment_MF


  SUBROUTINE FinalizePositivityLimiter_TwoMoment_MF

    CALL FinalizePositivityLimiter_TwoMoment

  END SUBROUTINE FinalizePositivityLimiter_TwoMoment_MF


  SUBROUTINE ApplyPositivityLimiter_TwoMoment_MF &
    ( GEOM, MF_uGF, MF_uCF, MF_uCR, Verbose_Option )

    TYPE(amrex_geometry), INTENT(in)    :: GEOM   (0:nLevels-1)
    TYPE(amrex_multifab), INTENT(in)    :: MF_uGF (0:nLevels-1)
    TYPE(amrex_multifab), INTENT(in)    :: MF_uCF (0:nLevels-1)
    TYPE(amrex_multifab), INTENT(inout) :: MF_uCR (0:nLevels-1)
    LOGICAL             , INTENT(in), OPTIONAL :: Verbose_Option

    TYPE(amrex_mfiter) :: MFI
    TYPE(amrex_box)    :: BX

    REAL(DP), CONTIGUOUS, POINTER :: uGF (:,:,:,:)
    REAL(DP), CONTIGUOUS, POINTER :: uCF (:,:,:,:)
    REAL(DP), CONTIGUOUS, POINTER :: uCR (:,:,:,:)

    REAL(DP), ALLOCATABLE :: G (:,:,:,:,:)
    REAL(DP), ALLOCATABLE :: C (:,:,:,:,:)
    REAL(DP), ALLOCATABLE :: U (:,:,:,:,:,:,:)

    INTEGER :: iLevel
    INTEGER :: iX_B0(3), iX_E0(3), iX_B1(3), iX_E1(3), iLo_MF(4)
    INTEGER :: iZ_B0(4), iZ_E0(4), iZ_B1(4), iZ_E1(4)

    LOGICAL :: Verbose

    Verbose = .FALSE.
    IF( PRESENT( Verbose_Option ) ) &
      Verbose = Verbose_Option

    DO iLevel = 0, nLevels-1

      ! --- Apply boundary conditions to interior domains ---

      CALL MF_uCR(iLevel) % Fill_Boundary( GEOM(iLevel) )

      CALL MF_uCF(iLevel) % Fill_Boundary( GEOM(iLevel) )

      CALL MF_uGF(iLevel) % Fill_Boundary( GEOM(iLevel) )

      CALL amrex_mfiter_build( MFI, MF_uGF(iLevel), tiling = UseTiling )

      DO WHILE( MFI % next() )

        uGF  => MF_uGF (iLevel) % DataPtr( MFI )
        uCF  => MF_uCF (iLevel) % DataPtr( MFI )
        uCR  => MF_uCR (iLevel) % DataPtr( MFI )

        iLo_MF = LBOUND( uGF )

        BX = MFI % tilebox()

        iX_B0 = BX % lo
        iX_E0 = BX % hi
        iX_B1 = BX % lo - swX
        iX_E1 = BX % hi + swX

        iZ_B0(1) = iE_B0
        iZ_B1(1) = iE_B1
        iZ_E0(1) = iE_E0
        iZ_E1(1) = iE_E1

        iZ_B0(2:4) = iX_B0
        iZ_B1(2:4) = iX_B1
        iZ_E0(2:4) = iX_E0
        iZ_E1(2:4) = iX_E1

        CALL AllocateArray_X &
               ( [ 1    , iX_B1(1), iX_B1(2), iX_B1(3), 1   ], &
                 [ nDOFX, iX_E1(1), iX_E1(2), iX_E1(3), nGF ], &
                 G )

        CALL AllocateArray_X &
               ( [ 1    , iX_B1(1), iX_B1(2), iX_B1(3), 1   ], &
                 [ nDOFX, iX_E1(1), iX_E1(2), iX_E1(3), nCF ], &
                 C )

        CALL AllocateArray_Z &
               ( [ 1       , &
                   iZ_B1(1), &
                   iZ_B1(2), &
                   iZ_B1(3), &
                   iZ_B1(4), &
                   1       , &
                   1        ], &
                 [ nDOFZ   , &
                   iZ_E1(1), &
                   iZ_E1(2), &
                   iZ_E1(3), &
                   iZ_E1(4), &
                   nCR     , &
                   nSpecies ], &
                 U )

        CALL amrex2thornado_X( nGF, iX_B1, iX_E1, iLo_MF, iX_B0, iX_E0, uGF, G )

        CALL amrex2thornado_X( nCF, iX_B1, iX_E1, iLo_MF, iX_B0, iX_E0, uCF, C )

        CALL amrex2thornado_Z &
               ( nCR, nSpecies, nE, iE_B0, iE_E0, &
                 iZ_B1, iZ_E1, iLo_MF, iZ_B0, iZ_E0, uCR, U )

        CALL ApplyPositivityLimiter_TwoMoment &
               ( iZ_B0, iZ_E0, iZ_B1, iZ_E1, uGE, G, C, U, &
                 Verbose_Option = Verbose )

        CALL thornado2amrex_Z &
               ( nCR, nSpecies, nE, iE_B0, iE_E0, &
                 iZ_B1, iZ_E1, iLo_MF, iZ_B0, iZ_E0, uCR, U )

        CALL DeallocateArray_Z &
               ( [ 1       , &
                   iZ_B1(1), &
                   iZ_B1(2), &
                   iZ_B1(3), &
                   iZ_B1(4), &
                   1       , &
                   1        ], &
                 [ nDOFZ   , &
                   iZ_E1(1), &
                   iZ_E1(2), &
                   iZ_E1(3), &
                   iZ_E1(4), &
                   nCR     , &
                   nSpecies ], &
                 U )

        CALL DeallocateArray_X &
               ( [ 1    , iX_B1(1), iX_B1(2), iX_B1(3), 1   ], &
                 [ nDOFX, iX_E1(1), iX_E1(2), iX_E1(3), nCF ], &
                 C )

        CALL DeallocateArray_X &
               ( [ 1    , iX_B1(1), iX_B1(2), iX_B1(3), 1   ], &
                 [ nDOFX, iX_E1(1), iX_E1(2), iX_E1(3), nGF ], &
                 G )

      END DO ! DO WHILE( MFI % next() )

      CALL amrex_mfiter_destroy( MFI )

    END DO ! iLevel = 0, nLevels-1

  END SUBROUTINE ApplyPositivityLimiter_TwoMoment_MF


END MODULE MF_TwoMoment_PositivityLimiterModule
