PROGRAM main

  ! --- AMReX Modules ---
  USE amrex_fort_module,                ONLY: &
    amrex_real
  USE amrex_parallel_module,            ONLY: &
    amrex_parallel_ioprocessor, &
    amrex_parallel_communicator

  ! --- Local Modules ---
  USE MF_TwoMoment_UtilitiesModule,     ONLY: & 
    MF_ComputeTimeStep
  USE MyAmrDataModule,                  ONLY: &
    MF_uCR, &
    MF_uPR
  USE InitializationModule,             ONLY: &
    InitializeProgram
  USE FinalizationModule,               ONLY: &
    FinalizeProgram
  USE MyAmrModule,                      ONLY: &
    nLevels,   &
    StepNo,    &
    t,         &
    dt,        &
    t_end,     &
    CFL,       &
    t_wrt,     &
    dt_wrt,    &
    t_chk,     &
    dt_chk,    &
    iCycleD,   &
    iCycleW,   &
    iCycleChk, &
    BA,        &
    GEOM
  USE MF_TimeSteppingModule_IMEX,      ONLY: &
    MF_UpdateField_IMEX

  ! --- thornado Modules ---
  USE InputOutput,           ONLY: &
    WriteFieldsAMReX_PlotFile, &
    WriteFieldsAMReX_Checkpoint, &
    ReadCheckpointFile

  IMPLICIT NONE

  CALL InitializeProgram

  print*, 'Yay'

  CALL WriteFieldsAMReX_Checkpoint & 
      ( StepNo, nLevels, dt, t, t_wrt, BA % P, &
        MF_uCR % P,  &
        MF_uPR % P  )
  
  DO WHILE( ALL( t .LT. t_end ) )
    
    StepNo = StepNo + 1
 
    CALL MF_ComputeTimeStep( dt )
    IF( ALL( t + dt .LE. t_end ) )THEN
      t = t + dt
    ELSE
      dt = t_end - [t]
      t  = [t_end]
    END IF

    WRITE(*,'(8x,A8,I8.8,A5,ES13.6E3,1x,A,A6,ES13.6E3,1x,A)') &
      'StepNo: ', StepNo(0), ' t = ', t , &
      ' dt = ', dt(0) 

    !this is where the issue is
    CALL MF_UpdateField_IMEX &
           ( t, dt, MF_uPR )

  END DO
  
  CALL WriteFieldsAMReX_Checkpoint & 
      ( StepNo, nLevels, dt, t, t_wrt, BA % P, &
        MF_uCR % P,  &
        MF_uPR % P  )

    CALL WriteFieldsAMReX_PlotFile &
           ( t(0), StepNo, &
             MF_uCR_Option = MF_uCR, &
             MF_uPR_Option = MF_uPR )


  CALL FinalizeProgram( GEOM )
  

END PROGRAM main