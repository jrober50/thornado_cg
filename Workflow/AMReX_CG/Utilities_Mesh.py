#!/usr/bin/env python3

import numpy as np
import yt
import math



def CreateLocations(File,               \
                    MaxLevel = -1,      \
                    TypeIn = "Leaf"     ):


    CheckMeshType(TypeIn)

    if TypeIn.lower() == "leaf":
        X1, X2, X3, dX1, dX2, dX3, xL, xH           \
            = CreateLeafLocations(  File            )
    
    elif TypeIn.lower() == "uniform":
        X1, X2, X3, dX1, dX2, dX3, xL, xH           \
            = CreateUniformLocations(   File,       \
                                        MaxLevel    )
    
    


    return X1, X2, X3, dX1, dX2, dX3, xL, xH
    
 
 
def CreateLeafLocations( File ):


    print("In CreateLeafLocations")

    yt.funcs.mylog.setLevel(40) # Suppress yt warnings
    ds = yt.load( '{:}'.format( File ) )

    Time = ds.current_time.to_ndarray()
    nX   = ds.domain_dimensions
    xL   = ds.domain_left_edge
    xH   = ds.domain_right_edge

    nDimsX = 1
    if nX[1] > 1: nDimsX += 1
    if nX[2] > 1: nDimsX += 1


    slc = yt.SlicePlot(ds, "theta",("boxlib","PF_D"))

    slc.save('test')
    exit()

    return X1, X2, X3, dX1, dX2, dX3, xL, xH
    
    
    
    
    
    
    
    
    
    
    
    
    
def CreateUniformLocations( File,               \
                            MaxLevel            ):
                            
                        
    yt.funcs.mylog.setLevel(40) # Suppress yt warnings
    ds = yt.load( '{:}'.format( File ) )

    if MaxLevel == -1: MaxLevel = ds.index.max_level
    Time = ds.current_time.to_ndarray()
    nX   = ds.domain_dimensions
    xL   = ds.domain_left_edge
    xH   = ds.domain_right_edge

    nDimsX = 1
    if nX[1] > 1: nDimsX += 1
    if nX[2] > 1: nDimsX += 1

    if nDimsX == 1:
        dim_array = [nX[0] * 2**MaxLevel, nX[1], nX[2]]
    elif nDimsX == 2:
        dim_array = [nX[0] * 2**MaxLevel, nX[1] * 2**MaxLevel, nX[2]]
    else:
        dim_array = nX * 2**MaxLevel

    CoveringGrid \
          = ds.covering_grid \
              ( level           = MaxLevel, \
                left_edge       = xL, \
                dims            = dim_array, \
                num_ghost_zones = 0 )


    

    X1 = np.copy( CoveringGrid['X1_C'].to_ndarray() )
    X1 = np.copy( X1[:,0,0] )
    dX1 = np.copy( CoveringGrid['dX1'].to_ndarray() )
    dX1 = np.copy( dX1[:,0,0])

    if nDimsX > 1:
        X2 = np.copy( CoveringGrid['X2_C'].to_ndarray() )
        dX2 = np.copy( CoveringGrid['dX2'].to_ndarray() )
        X2 = np.copy( X2[0,:,0] )
        dX2 = np.copy( dX2[0,:,0] )
    else:
        X2  = np.array( [math.pi/2.0] )
        dX2 = np.array( [math.pi] )
        
    if nDimsX > 2:
        X3 = np.copy( CoveringGrid['X3_C'].to_ndarray() )
        dX3 = np.copy( CoveringGrid['dX3'].to_ndarray() )
        X3 = np.copy( X3[0,0,:] )
        dX3 = np.copy( dX3[0,0,:] )
    else:
        X3  = np.array( [math.pi] )
        dX3 = np.array( [2.0*math.pi] )



    del ds, CoveringGrid
    
    return X1, X2, X3, dX1, dX2, dX3, xL, xH






def CheckMeshType( TypeIn ):

    Types = set(Type.lower() for Type in ("Leaf","Uniform"))
    
    msg =  "\n\n Invalid mesh type: {:}. \n".format( TypeIn )
    msg += "\n Acceptable types: \n"
    msg += "-------------------\n"
    msg += "Leaf \n"
    msg += "Uniform \n"
    assert( TypeIn.lower() in Types ), msg
    
    
    return
