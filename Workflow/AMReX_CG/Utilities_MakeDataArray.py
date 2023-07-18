#!/usr/bin/env python3

import numpy as np
import os
from os.path import isdir, isfile
from multiprocessing import Process, cpu_count

import GlobalVariables_Settings as gvS
import GlobalVariables_Units    as gvU

from Utilities_Files import Overwrite, CheckForField, CleanField
from Utilities_GetData import GetData






def MakeDataArray(  FileNumberArray,                \
                    PlotDirectory,                  \
                    PlotBaseName,                   \
                    Field,                          \
                    DataDirectory,                  \
                    forceChoiceD     = False,       \
                    overwriteD       = True,        \
                    forceChoiceF     = False,       \
                    overwriteF       = True,        \
                    SaveTime         = True,       \
                    SaveX            = True,       \
                    SavedX           = True        ):
                     
    """
    Generate a directory with the following structure for each plotfile
    (the example uses plotfile PlotBaseName.08675309)

    .DataDirectory/
    .DataDirectory/PlotfileNumbers.dat
    .DataDirectory/08675309/Time.dat
    .DataDirectory/08675309/X1.dat
    .DataDirectory/08675309/X2.dat
    .DataDirectory/08675309/X3.dat
    .DataDirectory/08675309/CF_D.dat
    .DataDirectory/08675309/PF_V1.dat
    .DataDirectory/08675309/<Your favorite field>.dat
    """
              

    print( '\n  Running MakeDataFile' )
    
    print(   '  --------------------' )

    if DataDirectory[-1] != '/': DataDirectory += '/'
    if PlotDirectory[-1] != '/': PlotDirectory += '/'

    print( '\n  DataDirectory: {:}\n'.format( DataDirectory ) )
    print( '\n  PlotDirectory: {:}\n'.format( PlotDirectory ) )


    overwriteD = Overwrite( DataDirectory, ForceChoice = forceChoiceD, OW = overwriteD )



    nProc = 1 #max( 1, cpu_count() // 2 )


    if overwriteD:
    
        os.system( 'rm -rf {:}'.format( DataDirectory ) )
        os.system(  'mkdir {:}'.format( DataDirectory ) )
    
        printProcMem = False

        if printProcMem:
            import psutil
            process = psutil.Process( os.getpid() )
            print( 'mem: {:.3e} kB'.format \
                    ( process.memory_info().rss / 1024.0 ) )
                    
                    
        print( '  Generating {:} with {:} processes...\n'.format \
             ( DataDirectory, nProc ) )

        if nProc > 1:
            for i in range( nProc ):
                print("Not ready for multiple processes.")


        else:
    
            MakeDataDirectory(  FileNumberArray,    \
                                PlotDirectory,      \
                                PlotBaseName,       \
                                Field,              \
                                DataDirectory,      \
                                SaveTime,           \
                                SaveX,              \
                                SavedX              )
            

    else: # overwriteD == False


        PathDataDirectory, Flag = CheckForField(Field,          \
                                                DataDirectory,  \
                                                FileNumberArray     )
        
                          
        if Flag:
            owF = Overwrite( PathDataDirectory,         \
                             ForceChoice = forceChoiceF,\
                             OW = overwriteF            )
        else:
            owF = True



        if owF:
        
            CleanField( Field,          \
                        DataDirectory,  \
                        FileNumberArray     )
        
            print( '\nPlotDirectory: {:}\n'.format( PlotDirectory ) )
            if nProc > 1:
                for i in range( nProc ):
                    print("Not ready for multiple processes.")
        

            else:
        
                MakeDataDirectory(  FileNumberArray,    \
                                    PlotDirectory,      \
                                    PlotBaseName,       \
                                    Field,              \
                                    DataDirectory,      \
                                    SaveTime,           \
                                    SaveX,              \
                                    SavedX              )
                                    
        else:
            MakeDataDirectory(  FileNumberArray,    \
                                PlotDirectory,      \
                                PlotBaseName,       \
                                Field,              \
                                DataDirectory,      \
                                SaveTime,           \
                                SaveX,              \
                                SavedX              )
            

    return







def MakeDataDirectory(  FileNumberArray,                \
                        PlotDirectory,                  \
                        PlotBaseName,                   \
                        Field,                          \
                        DataDirectory,                  \
                        SaveTime         = True,        \
                        SaveX            = True,        \
                        SavedX           = True,        \
                        owF              = True         ):

    
    NumPltFiles = FileNumberArray.shape[0]
    
    
    for i in range(NumPltFiles):

        printProcMem = False
        if printProcMem:
            print( 'mem: {:.3e} kB'.format \
                    ( process.memory_info().rss / 1024.0 ) )

        PlotFileNumber = FileNumberArray[i]
        PathDataDirectory = DataDirectory + str(PlotFileNumber) + '/'
        PathPlotDirectory = PlotDirectory       \
                          + PlotBaseName    \
                          + '{:}'.format( str(PlotFileNumber).zfill(8) )
        
        
        
        if not isdir(PathDataDirectory):
        
            if gvS.Verbose:
                print( 'Generating data directory: {:} ({:}/{:})'.format \
                    ( PathDataDirectory, i+1, NumPltFiles ) )
                    
            CreateDirectory( PathDataDirectory, \
                             PathPlotDirectory, \
                             PlotFileNumber,    \
                             Field,             \
                             SaveTime,          \
                             SaveX,             \
                             SavedX             )
                             
        elif isdir(PathDataDirectory) and owF:
        
            PathFieldDirectory = PathDataDirectory         \
                               + '{:}.dat'.format( Field )

            os.system( 'rm -rf {:}'.format( PathFieldDirectory ) )
            if gvS.Verbose:
                print( 'Generating data directory: {:} ({:}/{:})'.format \
                    ( PathDataDirectory, i+1, NumPltFiles ) )
                    
            CreateDirectory( PathDataDirectory, \
                             PathPlotDirectory, \
                             PlotFileNumber,    \
                             Field,             \
                             SaveTime,          \
                             SaveX,             \
                             SavedX             )
        
#        else:
#            print("Directory, {:s}, already exists, skipping".format( PathDataDirectory ))






    return




def CreateDirectory( PathDataDirectory,             \
                     PathPlotDirectory,             \
                     PlotFileNumber,                \
                     Field,                         \
                     SaveTime         = True,       \
                     SaveX            = True,       \
                     SavedX           = True        ):

    if not isdir(PathDataDirectory):
        os.system( 'mkdir {:}'.format(PathDataDirectory) )

    DataFile = PathDataDirectory + '{:}.dat'.format( Field )

    if SaveTime:
        TimeFile = PathDataDirectory + '{:}.dat'.format( 'Time' )
    if SaveX:
        X1File   = PathDataDirectory + '{:}.dat'.format( 'X1' )
        X2File   = PathDataDirectory + '{:}.dat'.format( 'X2' )
        X3File   = PathDataDirectory + '{:}.dat'.format( 'X3' )
    if SavedX:
        dX1File  = PathDataDirectory + '{:}.dat'.format( 'dX1' )
        dX2File  = PathDataDirectory + '{:}.dat'.format( 'dX2' )
        dX3File  = PathDataDirectory + '{:}.dat'.format( 'dX3' )

    

    Data, DataUnits, \
      X1, X2, X3, dX1, dX2, dX3, xL, xH, nX, Time \
        = GetData( PathPlotDirectory,   \
                   Field,               \
                   SaveTime,            \
                   SaveX,               \
                   SavedX               )





    nDimsX = 1
    if( nX[1] > 1 ): nDimsX += 1
    if( nX[2] > 1 ): nDimsX += 1

    if   nDimsX == 1:
        LoopShape = [ Data.shape[0], 1, 1 ]
        DataShape = '{:d}' \
                    .format( Data.shape[0] )
        Data = np.copy( Data[:,0  ,0  ] )
        if SaveX:
            X1   = np.copy( X1  [:,0:1,0:1] )
            X2   = np.copy( X2  [:,0:1,0:1] )
            X3   = np.copy( X3  [:,0:1,0:1] )
        if SavedX:
            dX1  = np.copy( dX1 [:,0:1,0:1] )
            dX2  = np.copy( dX2 [:,0:1,0:1] )
            dX3  = np.copy( dX3 [:,0:1,0:1] )
    elif nDimsX == 2:
        LoopShape = [ Data.shape[0], Data.shape[1], 1 ]
        DataShape = '{:d} {:d}' \
                    .format( Data.shape[0], Data.shape[1] )
        Data = np.copy( Data[:,:,0  ] )
        if SaveX:
            X1   = np.copy( X1  [:,:,0:1] )
            X2   = np.copy( X2  [:,:,0:1] )
            X3   = np.copy( X3  [:,:,0:1] )
        if SavedX:
            dX1  = np.copy( dX1 [:,:,0:1] )
            dX2  = np.copy( dX2 [:,:,0:1] )
            dX3  = np.copy( dX3 [:,:,0:1] )
    else:
        exit( 'MakeDataFile not implemented for nDimsX > 2' )



    if not isfile( DataFile ):

        # Save multi-D array with np.savetxt. Taken from:
        # https://stackoverflow.com/questions/3685265/
        # how-to-write-a-multidimensional-array-to-a-text-file

        with open( DataFile, 'w' ) as FileOut:

            FileOut.write( '# {:}\n'              \
                           .format( DataFile  ) )
            FileOut.write( '# Array Shape: {:}\n' \
                           .format( DataShape ) )
            FileOut.write( '# Data Units: {:}\n'  \
                           .format( DataUnits ) )
            FileOut.write( '# Min. value: {:.16e}\n' \
                           .format( Data.min() ) )
            FileOut.write( '# Max. value: {:.16e}\n' \
                           .format( Data.max() ) )

            np.savetxt( FileOut, Data )

        # end with open( DataFile, 'w' ) as FileOut

    # end if not isfile( DataFile )

    if SaveTime:
        if not isfile( TimeFile ):

            with open( TimeFile, 'w' ) as FileOut:

                FileOut.write( '# {:}\n'              \
                               .format( TimeFile  ) )
                FileOut.write( '# Time Units: {:}\n'  \
                               .format( gvU.TimeUnits ) )
                FileOut.write( str( Time ) + '\n' )




    if SaveX:
        if not isfile( X1File ):

            with open( X1File, 'w' ) as FileOut:

                FileOut.write( '# {:}\n'.format( X1File  ) )
                FileOut.write( '# X1_C {:}\n'.format( gvU.X1Units ) )

                for iX1 in range( LoopShape[0] ):
                    for iX2 in range( LoopShape[1] ):
                        for iX3 in range( LoopShape[2] ):
                            FileOut.write \
                              ( str( X1 [iX1,iX2,iX3] ) + ' ' )
                        FileOut.write( '\n' )
                    FileOut.write( '\n' )
                FileOut.write( '\n' )


        if not isfile( X2File ):

            with open( X2File, 'w' ) as FileOut:

                FileOut.write( '# {:}\n'.format( X2File  ) )
                FileOut.write( '# X2_C {:}\n'.format( gvU.X2Units ) )

                for iX1 in range( LoopShape[0] ):
                    for iX2 in range( LoopShape[1] ):
                        for iX3 in range( LoopShape[2] ):
                            FileOut.write \
                              ( str( X2 [iX1,iX2,iX3] ) + ' ' )
                        FileOut.write( '\n' )
                    FileOut.write( '\n' )
                FileOut.write( '\n' )

        if not isfile( X3File ):

            with open( X3File, 'w' ) as FileOut:

                FileOut.write( '# {:}\n'.format( X3File  ) )
                FileOut.write( '# X3_C {:}\n'.format( gvU.X3Units ) )

                for iX1 in range( LoopShape[0] ):
                    for iX2 in range( LoopShape[1] ):
                        for iX3 in range( LoopShape[2] ):
                            FileOut.write \
                              ( str( X3 [iX1,iX2,iX3] ) + ' ' )
                        FileOut.write( '\n' )
                    FileOut.write( '\n' )
                FileOut.write( '\n' )



    if SavedX:
        if not isfile( dX1File ):

            with open( dX1File, 'w' ) as FileOut:

                FileOut.write( '# {:}\n'.format( dX1File  ) )
                FileOut.write( '# dX1 {:}\n'.format( gvU.X1Units ) )

                for iX1 in range( LoopShape[0] ):
                    for iX2 in range( LoopShape[1] ):
                        for iX3 in range( LoopShape[2] ):
                            FileOut.write \
                              ( str( dX1[iX1,iX2,iX3] ) + ' ' )
                        FileOut.write( '\n' )
                    FileOut.write( '\n' )
                FileOut.write( '\n' )


        if not isfile( dX2File ):

            with open( dX2File, 'w' ) as FileOut:

                FileOut.write( '# {:}\n'.format( dX2File  ) )
                FileOut.write( '# dX2 {:}\n'.format( gvU.X2Units ) )

                for iX1 in range( LoopShape[0] ):
                    for iX2 in range( LoopShape[1] ):
                        for iX3 in range( LoopShape[2] ):
                            FileOut.write \
                              ( str( dX2[iX1,iX2,iX3] ) + ' ' )
                        FileOut.write( '\n' )
                    FileOut.write( '\n' )
                FileOut.write( '\n' )


        if not isfile( dX3File ):

            with open( dX3File, 'w' ) as FileOut:

                FileOut.write( '# {:}\n'.format( dX3File  ) )
                FileOut.write( '# dX3 {:}\n'.format( gvU.X3Units ) )

                for iX1 in range( LoopShape[0] ):
                    for iX2 in range( LoopShape[1] ):
                        for iX3 in range( LoopShape[2] ):
                            FileOut.write \
                              ( str( dX3[iX1,iX2,iX3] ) + ' ' )
                        FileOut.write( '\n' )
                    FileOut.write( '\n' )
                FileOut.write( '\n' )
