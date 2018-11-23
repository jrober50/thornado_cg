PROGRAM main

  ! --- AMReX Modules ---

  USE amrex_base_module
  USE amrex_fort_module, only: amrex_spacedim

  ! --- thornado Modules ---

  USE KindModule,                       ONLY: &
    DP
  USE ProgramHeaderModule,              ONLY: &
    InitializeProgramHeader,                  &
    DescribeProgramHeaderX
  USE PolynomialBasisModuleX_Lagrange,  ONLY: &
    InitializePolynomialBasisX_Lagrange
  USE PolynomialBasisModuleX_Legendre,  ONLY: &
    InitializePolynomialBasis_Legendre
  USE ReferenceElementModuleX,          ONLY: &
    InitializeReferenceElementX
  USE ReferenceElementModuleX_Lagrange, ONLY: &
    InitializeReferenceElementX_Lagrange

  IMPLICIT NONE

  CHARACTER(LEN=:), ALLOCATABLE :: ProgramName
  INTEGER :: iDim
  INTEGER :: nNodes
  INTEGER :: nStages
  INTEGER :: nX(3) = 1, swX(3) = 0
  INTEGER, PARAMETER :: nComp = 10
  INTEGER, PARAMETER :: nGhost = 2
  INTEGER, ALLOCATABLE  :: n_cell(:)
  INTEGER, ALLOCATABLE  :: max_grid_size(:)
  REAL(amrex_real)      :: t_end
  REAL(amrex_real)      :: dt_wrt
  TYPE(amrex_parmparse) :: PP
  TYPE(amrex_box)       :: BX
  TYPE(amrex_boxarray)  :: BA
  TYPE(amrex_geometry)  :: GEOM
  TYPE(amrex_distromap) :: DM
  TYPE(amrex_multifab)  :: U

  ! --- Initialize AMReX ---

  CALL amrex_init( )

  ! --- Parse Parameter File ---

  CALL amrex_parmparse_build( PP )

  CALL PP % get( "t_end",   t_end )
  CALL PP % get( "dt_wrt",  dt_wrt )
  CALL PP % get( "nNodes",  nNodes )
  CALL PP % get( "nStages", nStages )
  CALL PP % get( "ProgramName", ProgramName )

  CALL amrex_parmparse_destroy( PP )

  PRINT*, "t_end   = ", t_end
  PRINT*, "dt_wrt  = ", dt_wrt
  PRINT*, "nNodes  = ", nNodes
  PRINT*, "nStages = ", nStages
  PRINT*, "nDimsX  = ", amrex_spacedim
  PRINT*, "Name    = ", ProgramName, LEN( ProgramName )

  CALL amrex_parmparse_build( PP, "amr" )

  CALL PP % getarr( "n_cell", n_cell )
  CALL PP % getarr( "max_grid_size", max_grid_size )

  CALL amrex_parmparse_destroy( PP )

  PRINT*, "n_cell = ", n_cell
  PRINT*, "max_grid_size = ", max_grid_size

  DO iDim = 1, amrex_spacedim
    nX (iDim) = n_cell(iDim)
    swX(iDim) = nGhost
  END DO

  CALL InitializeProgramHeader &
         ( nNodes_Option = nNodes, nX_Option = nX, swX_Option = swX )

  CALL DescribeProgramHeaderX
print*,"Calling InitializePolynomialBasisX_Lagrange"
  CALL InitializePolynomialBasisX_Lagrange
print*,"Calling InitializePolynomialBasisX_Legendre"
  CALL InitializePolynomialBasis_Legendre
print*,"Calling InitializeReferenceElementX"
  CALL InitializeReferenceElementX
print*,"Calling InitializeReferenceElementX_Lagrange"
  CALL InitializeReferenceElementX_Lagrange

  BX = amrex_box( [ 0, 0, 0 ], [ n_cell(1)-1, n_cell(2)-1, n_cell(3)-1 ] )

  PRINT*, "BX % Lo = ", BX % Lo
  PRINT*, "BX % Hi = ", BX % Hi
  PRINT*, "BX % nodal = ", BX % nodal

  CALL amrex_print( BX )

  CALL amrex_boxarray_build( BA, BX )

  CALL BA % maxSize( max_grid_size )

  CALL amrex_geometry_build( GEOM, BX )

  PRINT*, "GEOM % dx = ", GEOM % dx

  CALL amrex_distromap_build( DM, BA )

  CALL amrex_multifab_build( U, BA, DM, nComp, nGhost )

  ! --- Finalize AMReX ---

  CALL amrex_finalize( )

END PROGRAM main
