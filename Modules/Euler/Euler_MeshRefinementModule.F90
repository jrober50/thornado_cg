MODULE Euler_MeshRefinementModule

#if defined( THORNADO_USE_AMREX ) && defined( THORNADO_USE_MESHREFINEMENT )

  USE amrex_DGInterfaceModule, ONLY: &
    amrex_InitializeMeshRefinement_DG, &
    amrex_FinalizeMeshRefinement_DG

#endif

  USE KindModule, ONLY: &
    DP, &
    Zero, &
    One, &
    Half
  USE ProgramHeaderModule, ONLY: &
    nDimsX, &
    nNodesX, &
    nNodes, &
    nDOFX
  USE ReferenceElementModuleX_Lagrange, ONLY: &
     LX_X1_Dn, &
     LX_X1_Up, &
     LX_X2_Dn, &
     LX_X2_Up, &
     LX_X3_Dn, &
     LX_X3_Up
  USE ReferenceElementModuleX, ONLY: &
    NodesX1, &
    NodesX2, &
    NodesX3, &
    WeightsX1, &
    WeightsX2, &
    WeightsX3, &
    WeightsX_q, &
    nDOFX_X1, &
    nDOFX_X2, &
    nDOFX_X3, &
    NodeNumberTableX_X1, &
    NodeNumberTableX_X2, &
    NodeNumberTableX_X3, &
    NodesLX1, &
    NodesLX2, &
    NodesLX3
  USE PolynomialBasisModuleX_Lagrange, ONLY: &
    IndLX_Q, &
    L_X1, &
    L_X2, &
    L_X3
  USE GeometryFieldsModule, ONLY: &
    iGF_SqrtGm

  IMPLICIT NONE
  PRIVATE

  PUBLIC :: InitializeMeshRefinement_Euler
  PUBLIC :: FinalizeMeshRefinement_Euler
  PUBLIC :: Refine_Euler
  PUBLIC :: Coarsen_Euler

  REAL(DP), ALLOCATABLE, PUBLIC :: LX_X1_Refined(:,:,:)
  REAL(DP), ALLOCATABLE, PUBLIC :: LX_X2_Refined(:,:,:)
  REAL(DP), ALLOCATABLE, PUBLIC :: LX_X3_Refined(:,:,:)

  REAL(DP), ALLOCATABLE, PUBLIC :: LX_X1_Refined_C(:)
  REAL(DP), ALLOCATABLE, PUBLIC :: LX_X2_Refined_C(:)
  REAL(DP), ALLOCATABLE, PUBLIC :: LX_X3_Refined_C(:)

  REAL(DP), ALLOCATABLE, PUBLIC :: LX_X1_Up_1D(:)
  REAL(DP), ALLOCATABLE, PUBLIC :: LX_X1_Dn_1D(:)
  REAL(DP), ALLOCATABLE, PUBLIC :: LX_X2_Up_1D(:)
  REAL(DP), ALLOCATABLE, PUBLIC :: LX_X2_Dn_1D(:)
  REAL(DP), ALLOCATABLE, PUBLIC :: LX_X3_Up_1D(:)
  REAL(DP), ALLOCATABLE, PUBLIC :: LX_X3_Dn_1D(:)

  REAL(DP), ALLOCATABLE :: xiX1(:)
  REAL(DP), ALLOCATABLE :: xiX2(:)
  REAL(DP), ALLOCATABLE :: xiX3(:)
  
  REAL(DP), ALLOCATABLE :: Chi1(:,:)
  REAL(DP), ALLOCATABLE :: Chi2(:,:)
  REAL(DP), ALLOCATABLE :: Chi3(:,:)
    
  REAL(DP), ALLOCATABLE :: LX_X1(:,:)
  REAL(DP), ALLOCATABLE :: LX_X2(:,:)
  REAL(DP), ALLOCATABLE :: LX_X3(:,:)
  
  REAL(DP), ALLOCATABLE :: ProjectionMatrix  (:,:,:)
  REAL(DP), ALLOCATABLE :: ProjectionMatrix_c(:)
  REAL(DP), ALLOCATABLE :: ProjectionMatrix_T(:,:,:) ! --- Transpose ---

  REAL(DP), ALLOCATABLE :: ProjectionMatrixCGtoCoarse  (:,:,:)
  REAL(DP), ALLOCATABLE :: ProjectionMatrixCGtoCoarse_c(:)
  
  REAL(DP), ALLOCATABLE :: ProjectionMatrixCGtoFine  (:,:,:)
  REAL(DP), ALLOCATABLE :: ProjectionMatrixCGtoFine_c(:)

  INTEGER  :: nFine, nFineX(3)
  REAL(DP) :: VolumeRatio


CONTAINS


  SUBROUTINE InitializeMeshRefinement_Euler

    INTEGER :: iDim
    INTEGER :: iFine, iFineX1, iFineX2, iFineX3
    INTEGER :: i, j, k, m, iN1, iN2, iN3, kk, &
               iNX_X_Crse, iNX_X1_Crse, iNX_X2_Crse, iNX_X3_Crse, &
               iNX_X_Fine, iNX_X1_Fine, iNX_X2_Fine, iNX_X3_Fine

    nFineX      = 1
    VolumeRatio = One
    DO iDim = 1, nDimsX
      ! --- Refinement Factor of 2 Assumed ---
      nFineX(iDim) = 2
      VolumeRatio  = Half * VolumeRatio
    END DO
    nFine = PRODUCT( nFineX )

    ALLOCATE( LX_X1_Refined(nDOFX_X1,nFineX(2)*nFineX(3),nDOFX_X1) )
    ALLOCATE( LX_X2_Refined(nDOFX_X2,nFineX(1)*nFineX(3),nDOFX_X2) )
    ALLOCATE( LX_X3_Refined(nDOFX_X3,nFineX(1)*nFineX(2),nDOFX_X3) )

    ALLOCATE( LX_X1_Refined_C(nDOFX_X1*nFineX(2)*nFineX(3)*nDOFX_X1) )
    ALLOCATE( LX_X2_Refined_C(nDOFX_X2*nFineX(1)*nFineX(3)*nDOFX_X2) )
    ALLOCATE( LX_X3_Refined_C(nDOFX_X3*nFineX(1)*nFineX(2)*nDOFX_X3) )

    ALLOCATE( LX_X1_Up_1D(nNodesX(1)) )
    ALLOCATE( LX_X1_Dn_1D(nNodesX(1)) )
    ALLOCATE( LX_X2_Up_1D(nNodesX(2)) )
    ALLOCATE( LX_X2_Dn_1D(nNodesX(2)) )
    ALLOCATE( LX_X3_Up_1D(nNodesX(3)) )
    ALLOCATE( LX_X3_Dn_1D(nNodesX(3)) )

    ALLOCATE( xiX1(nNodesX(1)) )
    ALLOCATE( xiX2(nNodesX(2)) )
    ALLOCATE( xiX3(nNodesX(3)) )
    
    ALLOCATE( Chi1(nNodesX(1),nFineX(1)) )
    ALLOCATE( Chi2(nNodesX(2),nFineX(2)) )
    ALLOCATE( Chi3(nNodesX(3),nFineX(3)) )
    
    ALLOCATE( LX_X1(nNodesX(1),nNodesX(1)) )
    ALLOCATE( LX_X2(nNodesX(2),nNodesX(2)) )
    ALLOCATE( LX_X3(nNodesX(3),nNodesX(3)) )

    ALLOCATE( ProjectionMatrix  (nDOFX,nDOFX,nFine) )
    ALLOCATE( ProjectionMatrix_c(nDOFX*nDOFX*nFine) )
    ALLOCATE( ProjectionMatrix_T(nDOFX,nDOFX,nFine) )

    ALLOCATE( ProjectionMatrixCGtoCoarse  (nDOFX,nDOFX,nFine) )
    ALLOCATE( ProjectionMatrixCGtoCoarse_c(nDOFX*nDOFX*nFine) )

    ALLOCATE( ProjectionMatrixCGtoFine  (nDOFX,nDOFX,nFine) )
    ALLOCATE( ProjectionMatrixCGtoFine_c(nDOFX*nDOFX*nFine) )

    DO i = 1, nNodesX(1)

      LX_X1_Up_1D(i) = L_X1(i) % P( +Half )
      LX_X1_Dn_1D(i) = L_X1(i) % P( -Half )

    END DO

    DO i = 1, nNodesX(2)

      LX_X2_Up_1D(i) = L_X2(i) % P( +Half )
      LX_X2_Dn_1D(i) = L_X2(i) % P( -Half )

    END DO

    DO i = 1, nNodesX(3)

      LX_X3_Up_1D(i) = L_X3(i) % P( +Half )
      LX_X3_Dn_1D(i) = L_X3(i) % P( -Half )

    END DO

    kk = 0

    iFine = 0
    DO iFineX3 = 1, nFineX(3)
    DO iFineX2 = 1, nFineX(2)
    DO iFineX1 = 1, nFineX(1)

      iFine = iFine + 1

      IF( nFineX(1) .GT. 1 )THEN
        xiX1 = Half * ( NodesX1 + (-1)**iFineX1 * Half )
      ELSE
        xiX1 = Zero
      END IF

      IF( nFineX(2) .GT. 1 )THEN
        xiX2 = Half * ( NodesX2 + (-1)**iFineX2 * Half )
      ELSE
        xiX2 = Zero
      END IF

      IF( nFineX(3) .GT. 1 )THEN
        xiX3 = Half * ( NodesX3 + (-1)**iFineX3 * Half )
      ELSE
        xiX3 = Zero
      END IF

      ProjectionMatrix(:,:,iFine) = Zero
      DO k = 1, nDOFX
      DO i = 1, nDOFX

        DO iN3 = 1, nNodesX(3)
        DO iN2 = 1, nNodesX(2)
        DO iN1 = 1, nNodesX(1)

          ProjectionMatrix(i,k,iFine) &
            = ProjectionMatrix(i,k,iFine) &
                + WeightsX1(iN1) * WeightsX2(iN2) * WeightsX3(iN3) &
                  * L_X1(IndLX_Q(1,i)) % P( NodesX1(iN1) ) &
                  * L_X2(IndLX_Q(2,i)) % P( NodesX2(iN2) ) &
                  * L_X3(IndLX_Q(3,i)) % P( NodesX3(iN3) ) &
                  * L_X1(IndLX_Q(1,k)) % P( xiX1   (iN1) ) &
                  * L_X2(IndLX_Q(2,k)) % P( xiX2   (iN2) ) &
                  * L_X3(IndLX_Q(3,k)) % P( xiX3   (iN3) )

        END DO
        END DO
        END DO

        kk = kk + 1
        ProjectionMatrix_c(kk) = ProjectionMatrix(i,k,iFine)

      END DO
      END DO

      ProjectionMatrix_T(:,:,iFine) &
        = TRANSPOSE( ProjectionMatrix(:,:,iFine) )

    END DO
    END DO
    END DO

    kk = 0

    iFine = 0
    DO iFineX3 = 1, nFineX(3)
    DO iFineX2 = 1, nFineX(2)
    DO iFineX1 = 1, nFineX(1)

      iFine = iFine + 1

      IF( nFineX(1) .GT. 1 )THEN
        xiX1 = Half * ( NodesX1 + (-1)**iFineX1 * Half )
      ELSE
        xiX1 = Zero
      END IF

      IF( nFineX(2) .GT. 1 )THEN
        xiX2 = Half * ( NodesX2 + (-1)**iFineX2 * Half )
      ELSE
        xiX2 = Zero
      END IF

      IF( nFineX(3) .GT. 1 )THEN
        xiX3 = Half * ( NodesX3 + (-1)**iFineX3 * Half )
      ELSE
        xiX3 = Zero
      END IF

      ProjectionMatrixCGtoFine(:,:,iFine) = Zero
      DO k = 1, nDOFX
      DO i = 1, nDOFX

        ProjectionMatrixCGtoFine(i,k,iFine) &
          =   L_X1(IndLX_Q(1,i)) % P( xiX1(IndLX_Q(1,k)) ) &
            * L_X2(IndLX_Q(2,i)) % P( xiX2(IndLX_Q(2,k)) ) &
            * L_X3(IndLX_Q(3,i)) % P( xiX3(IndLX_Q(3,k)) )
            
        kk = kk + 1
        ProjectionMatrixCGtoFine_c(kk) = ProjectionMatrixCGtoFine(i,k,iFine)

      END DO
      END DO

    END DO
    END DO
    END DO



    Chi1 = One
    IF (nFineX(1) .NE. 1 ) THEN
        Chi1(:,1) = Zero
        DO iN1 = 1, nNodesX(1)
        IF ( NodesLX1(iN1) .LE. Zero ) THEN
            Chi1(iN1,1) = One
            Chi1(iN1,2) = Zero
        END IF
        END DO
    ENDIF
    
    Chi2 = One
    IF (nFineX(2) .NE. 1 ) THEN
        Chi2(:,1) = Zero
        DO iN2 = 1, nNodesX(2)
        IF ( NodesLX2(iN2) .LE. Zero ) THEN
            Chi2(iN2,1) = One
            Chi2(iN2,2) = Zero
        END IF
        END DO
    ENDIF
    
    Chi3 = One
    IF (nFineX(3) .NE. 1 ) THEN
        Chi3(:,1) = Zero
        DO iN3 = 1, nNodesX(3)
        IF ( NodesLX3(iN3) .LE. Zero ) THEN
            Chi3(iN3,1) = One
            Chi3(iN3,2) = Zero
        END IF
        END DO
    ENDIF
    
    IF ( nNodesX(1) == 1 ) THEN
        LX_X1 = One
    ELSE
        DO k = 1, nNodesX(1)
        DO m = 1, nNodesX(1)
            LX_X1(m,k) = Lagrange( NodesX1(m), k, NodesLX1(:) )
        END DO
        END DO
    END IF
    
    

    IF ( nNodesX(2) == 1 ) THEN
        LX_X2 = One
    ELSE
        DO iN1 = 1, nNodesX(2)
        DO iN2 = 1, nNodesX(2)
            LX_X2(iN2,iN1) = Lagrange( NodesX2(iN2), iN1, NodesLX2(:) )
        END DO
        END DO
    END IF
    
    
    IF ( nNodesX(3) == 1 ) THEN
        LX_X3 = One
    ELSE
        DO iN1 = 1, nNodesX(3)
        DO iN2 = 1, nNodesX(3)
            LX_X3(iN2,iN1) = Lagrange( NodesX3(iN2), iN1, NodesLX3(:) )
        END DO
        END DO
    END IF

    kk = 0

    iFine = 0
    DO iFineX3 = 1, nFineX(3)
    DO iFineX2 = 1, nFineX(2)
    DO iFineX1 = 1, nFineX(1)

      iFine = iFine + 1

      IF( nFineX(1) .GT. 1 )THEN
        xiX1 = NodesLX1 / Half - (-1)**iFineX1 * Half
      ELSE
        xiX1 = Zero
      END IF
!      PRINT*,"NodesLX1",NodesLX1
!      PRINT*,"NodesX1",NodesX1
!      PRINT*,"xiX1",xiX1

      IF( nFineX(2) .GT. 1 )THEN
        xiX2 = NodesLX2 / Half - (-1)**iFineX2 * Half
      ELSE
        xiX2 = Zero
      END IF

      IF( nFineX(3) .GT. 1 )THEN
        xiX3 = NodesLX3 / Half - (-1)**iFineX3 * Half
      ELSE
        xiX3 = Zero
      END IF

      ProjectionMatrixCGtoCoarse(:,:,iFine) = Zero
      DO m = 1, nDOFX ! Gauss Locations on Coarse Element
      DO i = 1, nDOFX   ! Gauss Locations on Fine Element
      
        DO k = 1, nDOFX ! Lobatto Locations on Coarse Element

          ProjectionMatrixCGtoCoarse(i,m,iFine) &
            = ProjectionMatrixCGtoCoarse(i,m,iFine) &
                +   Chi1(IndLX_Q(1,k),iFineX1) &
                  * Chi2(IndLX_Q(2,k),iFineX2) &
                  * Chi3(IndLX_Q(3,k),iFineX3) &
                  * L_X1( IndLX_Q(1,i) ) % P( xiX1(IndLX_Q(1,k)) ) &
                  * L_X2( IndLX_Q(2,i) ) % P( xiX2(IndLX_Q(2,k)) ) &
                  * L_X3( IndLX_Q(3,i) ) % P( xiX3(IndLX_Q(3,k)) ) &
                  * LX_X1(IndLX_Q(1,m),IndLX_Q(1,k)) &
                  * LX_X2(IndLX_Q(2,m),IndLX_Q(2,k)) &
                  * LX_X3(IndLX_Q(3,m),IndLX_Q(3,k))

        END DO
      
        kk = kk + 1
        ProjectionMatrixCGtoCoarse_c(kk) = ProjectionMatrixCGtoCoarse(i,m,iFine)
      END DO
      END DO

    END DO
    END DO
    END DO


    kk = 0
    DO iNX_X1_Crse = 1, nDOFX_X1

      iNX_X2_Crse = NodeNumberTableX_X1(1,iNX_X1_Crse)
      iNX_X3_Crse = NodeNumberTableX_X1(2,iNX_X1_Crse)

      iFine = 0

      DO iFineX3 = 1, nFineX(3)
      DO iFineX2 = 1, nFineX(2)

        IF( nFineX(2) .GT. 1 )THEN
          xiX2 = Half * ( NodesX2 + (-1)**iFineX2 * Half )
        ELSE
          xiX2 = Zero
        END IF

        IF( nFineX(3) .GT. 1 )THEN
          xiX3 = Half * ( NodesX3 + (-1)**iFineX3 * Half )
        ELSE
          xiX3 = Zero
        END IF

        iFine = iFine + 1

        DO iNX_X1_Fine = 1, nDOFX_X1

          iNX_X2_Fine = NodeNumberTableX_X1(1,iNX_X1_Fine)
          iNX_X3_Fine = NodeNumberTableX_X1(2,iNX_X1_Fine)

          LX_X1_Refined(iNX_X1_Crse,iFine,iNX_X1_Fine) = One
          IF( nDimsX .GT. 1 ) &
            LX_X1_Refined(iNX_X1_Crse,iFine,iNX_X1_Fine) &
              = LX_X1_Refined(iNX_X1_Crse,iFine,iNX_X1_Fine) &
                  * Lagrange( xiX2(iNX_X2_Fine), iNX_X2_Crse, NodesX2 )
          IF( nDimsX .GT. 2 ) &
            LX_X1_Refined(iNX_X1_Crse,iFine,iNX_X1_Fine) &
              = LX_X1_Refined(iNX_X1_Crse,iFine,iNX_X1_Fine) &
                  * Lagrange( xiX3(iNX_X3_Fine), iNX_X3_Crse, NodesX3 )

          kk = kk + 1
          LX_X1_Refined_C(kk) &
            = LX_X1_Refined(iNX_X1_Crse,iFine,iNX_X1_Fine)

        END DO ! iNX_X1_Fine

      END DO ! iFineX2
      END DO ! iFineX3

    END DO ! iNX_X1_Crse

    IF( nDimsX .GT. 1 )THEN

      kk = 0
      DO iNX_X2_Crse = 1, nDOFX_X2

        iNX_X1_Crse = NodeNumberTableX_X2(1,iNX_X2_Crse)
        iNX_X3_Crse = NodeNumberTableX_X2(2,iNX_X2_Crse)

        iFine = 0

        DO iFineX3 = 1, nFineX(3)
        DO iFineX1 = 1, nFineX(1)

          IF( nFineX(1) .GT. 1 )THEN
            xiX1 = Half * ( NodesX1 + (-1)**iFineX1 * Half )
          ELSE
            xiX1 = Zero
          END IF

          IF( nFineX(3) .GT. 1 )THEN
            xiX3 = Half * ( NodesX3 + (-1)**iFineX3 * Half )
          ELSE
            xiX3 = Zero
          END IF

          iFine = iFine + 1

          DO iNX_X2_Fine = 1, nDOFX_X2

            iNX_X1_Fine = NodeNumberTableX_X2(1,iNX_X2_Fine)
            iNX_X3_Fine = NodeNumberTableX_X2(2,iNX_X2_Fine)

            LX_X2_Refined(iNX_X2_Crse,iFine,iNX_X2_Fine) = One
            IF( nDimsX .GT. 1 ) &
              LX_X2_Refined(iNX_X2_Crse,iFine,iNX_X2_Fine) &
                = LX_X2_Refined(iNX_X2_Crse,iFine,iNX_X2_Fine) &
                    * Lagrange( xiX1(iNX_X1_Fine), iNX_X1_Crse, NodesX1 )
            IF( nDimsX .GT. 2 ) &
              LX_X2_Refined(iNX_X2_Crse,iFine,iNX_X2_Fine) &
                = LX_X2_Refined(iNX_X2_Crse,iFine,iNX_X2_Fine) &
                    * Lagrange( xiX3(iNX_X3_Fine), iNX_X3_Crse, NodesX3 )

            kk = kk + 1
            LX_X2_Refined_C(kk) &
              = LX_X2_Refined(iNX_X2_Crse,iFine,iNX_X2_Fine)

          END DO ! iNX_X2_Fine

        END DO ! iFineX1
        END DO ! iFineX3

      END DO ! iNX_X2_Crse

    END IF ! nDimsX .GT. 1

    IF( nDimsX .GT. 2)THEN

      kk = 0
      DO iNX_X3_Crse = 1, nDOFX_X3

        iNX_X1_Crse = NodeNumberTableX_X3(1,iNX_X3_Crse)
        iNX_X2_Crse = NodeNumberTableX_X3(2,iNX_X3_Crse)

        iFine = 0

        DO iFineX2 = 1, nFineX(2)
        DO iFineX1 = 1, nFineX(1)

          IF( nFineX(1) .GT. 1 )THEN
            xiX1 = Half * ( NodesX1 + (-1)**iFineX1 * Half )
          ELSE
            xiX1 = Zero
          END IF

          IF( nFineX(2) .GT. 1 )THEN
            xiX2 = Half * ( NodesX2 + (-1)**iFineX2 * Half )
          ELSE
            xiX2 = Zero
          END IF

          iFine = iFine + 1

          DO iNX_X3_Fine = 1, nDOFX_X3

            iNX_X1_Fine = NodeNumberTableX_X3(1,iNX_X3_Fine)
            iNX_X2_Fine = NodeNumberTableX_X3(2,iNX_X3_Fine)

            LX_X3_Refined(iNX_X3_Crse,iFine,iNX_X3_Fine) = One
            IF( nDimsX .GT. 1 ) &
              LX_X3_Refined(iNX_X3_Crse,iFine,iNX_X3_Fine) &
                = LX_X3_Refined(iNX_X3_Crse,iFine,iNX_X3_Fine) &
                    * Lagrange( xiX1(iNX_X1_Fine), iNX_X1_Crse, NodesX1 )
            IF( nDimsX .GT. 2 ) &
              LX_X3_Refined(iNX_X3_Crse,iFine,iNX_X3_Fine) &
                = LX_X3_Refined(iNX_X3_Crse,iFine,iNX_X3_Fine) &
                    * Lagrange( xiX2(iNX_X2_Fine), iNX_X2_Crse, NodesX2 )

            kk = kk + 1
            LX_X3_Refined_C(kk) &
              = LX_X3_Refined(iNX_X3_Crse,iFine,iNX_X3_Fine)

          END DO ! iNX_X3_Fine

        END DO ! iFineX1
        END DO ! iFineX2

      END DO ! iNX_X3_Crse

    END IF ! nDimsX .GT. 2

#if defined( THORNADO_USE_AMREX ) && defined( THORNADO_USE_MESHREFINEMENT )

!              ProjectionMatrix_c, ProjectionMatrixCGtoFine_c, ProjectionMatrixCGtoCoarse_c, &

    CALL amrex_InitializeMeshRefinement_DG &
           ( nNodesX, &
             ProjectionMatrix_c, ProjectionMatrixCGtoFine_c, ProjectionMatrixCGtoCoarse_c, &
             WeightsX1, WeightsX2, WeightsX3, &
             LX_X1_Refined_C, LX_X2_Refined_C, LX_X3_Refined_C, &
             LX_X1_Up_1D, LX_X1_Dn_1D, &
             LX_X2_Up_1D, LX_X2_Dn_1D, &
             LX_X3_Up_1D, LX_X3_Dn_1D, iGF_SqrtGm )

#endif
!  STOP "At End of InitializeMeshRefinement_Euler"
  END SUBROUTINE InitializeMeshRefinement_Euler


  SUBROUTINE FinalizeMeshRefinement_Euler

#if defined( THORNADO_USE_AMREX ) && defined( THORNADO_USE_MESHREFINEMENT )

    CALL amrex_FinalizeMeshRefinement_DG

#endif


    DEALLOCATE( ProjectionMatrixCGtoFine_c )
    DEALLOCATE( ProjectionMatrixCGtoFine )

    DEALLOCATE( ProjectionMatrixCGtoCoarse_c )
    DEALLOCATE( ProjectionMatrixCGtoCoarse )

    DEALLOCATE( ProjectionMatrix_T )
    DEALLOCATE( ProjectionMatrix_c )
    DEALLOCATE( ProjectionMatrix )
    
    DEALLOCATE( LX_X3 )
    DEALLOCATE( LX_X2 )
    DEALLOCATE( LX_X1 )
        
    DEALLOCATE( Chi1 )
    DEALLOCATE( Chi2 )
    DEALLOCATE( Chi3 )

    DEALLOCATE( xiX3 )
    DEALLOCATE( xiX2 )
    DEALLOCATE( xiX1 )

    DEALLOCATE( LX_X3_Dn_1D )
    DEALLOCATE( LX_X3_Up_1D )
    DEALLOCATE( LX_X2_Dn_1D )
    DEALLOCATE( LX_X2_Up_1D )
    DEALLOCATE( LX_X1_Dn_1D )
    DEALLOCATE( LX_X1_Up_1D )

    DEALLOCATE( LX_X3_Refined_C )
    DEALLOCATE( LX_X2_Refined_C )
    DEALLOCATE( LX_X1_Refined_C )

    DEALLOCATE( LX_X3_Refined )
    DEALLOCATE( LX_X2_Refined )
    DEALLOCATE( LX_X1_Refined )

  END SUBROUTINE FinalizeMeshRefinement_Euler


  SUBROUTINE Refine_Euler( nX, U_Crs, U_Fin )

    INTEGER,  INTENT(in)  :: nX(3)
    REAL(DP), INTENT(in)  :: U_Crs(1:nDOFX)
    REAL(DP), INTENT(out) :: U_Fin(1:nDOFX,1:nX(1),1:nX(2),1:nX(3))

    INTEGER :: iFine, iFineX1, iFineX2, iFineX3

    iFine = 0
    DO iFineX3 = 1, nFineX(3)
    DO iFineX2 = 1, nFineX(2)
    DO iFineX1 = 1, nFineX(1)

      iFine = iFine + 1

      U_Fin(:,iFineX1,iFineX2,iFineX3) &
        = MATMUL( ProjectionMatrix(:,:,iFine), U_Crs ) / WeightsX_q

    END DO
    END DO
    END DO

  END SUBROUTINE Refine_Euler


  SUBROUTINE Coarsen_Euler( nX, U_Crs, U_Fin )

    INTEGER,  INTENT(in)  :: nX(3)
    REAL(DP), INTENT(out) :: U_Crs(1:nDOFX)
    REAL(DP), INTENT(in)  :: U_Fin(1:nDOFX,1:nX(1),1:nX(2),1:nX(3))

    INTEGER  :: iFine, iFineX1, iFineX2, iFineX3
    REAL(DP) :: U_Crs_iFine(1:nDOFX)

    U_Crs = Zero

    iFine = 0
    DO iFineX3 = 1, nFineX(3)
    DO iFineX2 = 1, nFineX(2)
    DO iFineX1 = 1, nFineX(1)

      iFine = iFine + 1

      U_Crs_iFine = MATMUL( ProjectionMatrix_T(:,:,iFine), &
                            U_Fin(:,iFineX1,iFineX2,iFineX3) ) / WeightsX_q

      U_Crs = U_Crs + VolumeRatio * U_Crs_iFine

    END DO
    END DO
    END DO

  END SUBROUTINE Coarsen_Euler


  REAL(DP) FUNCTION Lagrange( x, i, xn ) RESULT( L )

    REAL(DP), INTENT(in) :: x
    INTEGER , INTENT(in) :: i
    REAL(DP), INTENT(in) :: xn(:)

    INTEGER :: j

    L = One
    DO j = 1, SIZE( xn )

      IF( j .NE. i ) L = L * ( x - xn(j) ) / ( xn(i) - xn(j) )

    END DO

    RETURN
  END FUNCTION Lagrange

END MODULE Euler_MeshRefinementModule
