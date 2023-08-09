MODULE TaggingModule

  USE ISO_C_BINDING

  ! --- thornado Modules ---

  USE ProgramHeaderModule, ONLY: &
    nDOFX
  USE MeshModule, ONLY: &
    MeshX
  USE FluidFieldsModule, ONLY: &
    iCF_D
  USE UnitsModule, ONLY: &
    Kilometer, Gram, Centimeter

  ! --- Local Modules ---

  USE MF_KindModule, ONLY: &
    DP

  IMPLICIT NONE
  PRIVATE

  PUBLIC :: TagElements, TagElements_Yahil1D

CONTAINS


  SUBROUTINE TagElements &
    ( iLevel, iX_B0, iX_E0, iLo, iHi, uCF, TagCriteria, &
      SetTag, ClearTag, TagLo, TagHi, Tag )

    INTEGER,  INTENT(in) :: iLevel, iX_B0(3), iX_E0(3), iLo(4), iHi(4), &
                            TagLo(4), TagHi(4)
    REAL(DP), INTENT(in) :: uCF(iLo(1):iHi(1),iLo(2):iHi(2), &
                                iLo(3):iHi(3),iLo(4):iHi(4))
    REAL(DP), INTENT(in) :: TagCriteria
    CHARACTER(KIND=c_char), INTENT(in)    :: SetTag, ClearTag
    CHARACTER(KIND=c_char), INTENT(inout) :: Tag(TagLo(1):TagHi(1), &
                                                 TagLo(2):TagHi(2), &
                                                 TagLo(3):TagHi(3), &
                                                 TagLo(4):TagHi(4))

    INTEGER :: iX1, iX2, iX3

    REAL(DP) :: TagCriteria_this

    TagCriteria_this = TagCriteria

    DO iX3 = iX_B0(3), iX_E0(3)
    DO iX2 = iX_B0(2), iX_E0(2)
    DO iX1 = iX_B0(1), iX_E0(1)

      IF( MeshX(1) % Center(iX1) / Kilometer .LT. TagCriteria_this )THEN

        Tag(iX1,iX2,iX3,1) = SetTag

      ELSE

        Tag(iX1,iX2,iX3,1) = ClearTag

      END IF

    END DO
    END DO
    END DO

  END SUBROUTINE TagElements








  SUBROUTINE TagElements_Yahil1D &
    ( iLevel, iX_B0, iX_E0, iLo, iHi, uCF, TagCriteria, &
      SetTag, ClearTag, TagLo, TagHi, Tag )

    INTEGER,  INTENT(in) :: iLevel, iX_B0(3), iX_E0(3), iLo(4), iHi(4), &
                            TagLo(4), TagHi(4)
    REAL(DP), INTENT(in) :: uCF(iLo(1):iHi(1),iLo(2):iHi(2), &
                                iLo(3):iHi(3),iLo(4):iHi(4))
    REAL(DP), INTENT(in) :: TagCriteria
    CHARACTER(KIND=c_char), INTENT(in)    :: SetTag, ClearTag
    CHARACTER(KIND=c_char), INTENT(inout) :: Tag(TagLo(1):TagHi(1), &
                                                 TagLo(2):TagHi(2), &
                                                 TagLo(3):TagHi(3), &
                                                 TagLo(4):TagHi(4))

    INTEGER :: iX1, iX2, iX3

    REAL(DP) :: TagCriteria_this

    TagCriteria_this = TagCriteria

    DO iX3 = iX_B0(3), iX_E0(3)
    DO iX2 = iX_B0(2), iX_E0(2)
    DO iX1 = iX_B0(1), iX_E0(1)
    
!      PRINT*,uCF(iX1,iX2,iX3,iCF_D)/(Gram/Centimeter**3), TagCriteria_this
      IF( uCF(iX1,iX2,iX3,iCF_D)/(Gram/Centimeter**3) .GT. TagCriteria_this  ) THEN

        Tag(iX1,iX2,iX3,1) = SetTag

      ELSE

        Tag(iX1,iX2,iX3,1) = ClearTag

      END IF

    END DO
    END DO
    END DO

  END SUBROUTINE TagElements_Yahil1D

END MODULE TaggingModule
