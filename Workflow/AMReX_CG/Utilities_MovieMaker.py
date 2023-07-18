#!/usr/bin/env python3

import numpy as np
from sys import argv
from matplotlib import animation
from functools import partial
import matplotlib.pyplot as plt
plt.style.use( 'publication.sty' )

import GlobalVariables_Settings as gvS
import GlobalVariables_Units    as gvU


def MakeMovie( FileNumberArray,     \
                PlotDirectory,      \
                Fields,             \
                DataDirectories     ):

    global line
    global time_text
    global IC
    global mesh
    global Data0
    global X1_C0
    global dX10
    global Field
    global DataDirectory
    global nSS
    
    Field = Fields[0]
    
    DataDirectory = DataDirectories[0]
    if DataDirectory[-1] != '/': DataDirectory += '/'

    Data0, DataUnits, X1_C0, dX10, Time = fetchData(0,FileNumberArray)

    nSS = FileNumberArray.shape[0]

    if not gvS.UseCustomLimits:
        gvS.vmin = +np.inf
        gvS.vmax = -np.inf
        for j in range( nSS ):
            DataFile \
              = DataDirectory + str(FileNumberArray[j]) + '/{:}.dat'.format( Field )
            DataShape, DataUnits, MinVal, MaxVal = ReadHeader( DataFile )
            gvS.vmin = min( gvS.vmin, MinVal )
            gvS.vmax = max( gvS.vmax, MaxVal )

    nX = np.shape(X1_C0)

    xL = X1_C0[0 ] - 0.5 * dX10[0 ]
    xH = X1_C0[-1] + 0.5 * dX10[-1]

    fig = plt.figure()
    ax  = fig.add_subplot( 111 )
    ax.set_title( r'$\texttt{{{:}}}$'.format( gvS.FigTitle ) + ' - CG Interpolation', fontsize = 15 )

    time_text = ax.text( 0.1, 0.9, '', transform = ax.transAxes, fontsize = 13 )

    ax.set_xlabel \
      ( r'$x^{{1}}\ \left[\mathrm{{{:}}}\right]$'.format( gvU.X1Units ), fontsize = 15 )
    ax.set_ylabel( Field  + ' ' + r'$\left[\mathrm{{{:}}}\right]$' \
                                  .format( DataUnits[2:-2] ) )

    ax.set_xlim( xL, xH )
    ax.set_ylim( gvS.vmin, gvS.vmax )

    if gvS.UseLogScale_Y: ax.set_yscale( 'log' )
    if gvS.UseLogScale_X:
        xL = max( xL, xL + 0.25 * dX10[0] )
        ax.set_xlim( xL, xH )
        ax.set_xscale( 'log' )

    if gvS.PlotMesh: mesh, = ax.plot( [],[], 'b-', label = 'mesh boundaries'    )
    if gvS.ShowIC: IC,     = ax.plot( [],[], 'r-', label = r'$u\left(0\right)$' )
    line,              = ax.plot( [],[], 'k-', label = r'$u\left(t\right)$' )
    if gvS.ShowRefinement:
        bottom, top = plt.ylim()
        ax.plot( (gvS.RefinementLocations[:], gvS.RefinementLocations[:]), \
                 (top, bottom),     \
                 scaley = False,    \
                 color  = 'red',    \
                 zorder = 0,        \
                 alpha  = 0.4       )




    ax.set_ylim( gvS.vmin, gvS.vmax )
    ax.legend( prop = {'size':12} )
    ax.grid(which='both')
    anim = animation.FuncAnimation( fig,                                                  \
                                    partial(UpdateFrame, FileNumberArray=FileNumberArray), \
                                    init_func = InitializeFrame, \
                                    frames = nSS, \
                                    blit = True )

    fps = max( 1, nSS / gvS.MovieRunTime )
    


    print( '\n  Making movie' )
    print( '  ------------' )
    anim.save( gvS.MovieName, fps = fps, dpi = 300 )

    import os
    os.system( 'rm -rf __pycache__ ' )



    return




def fetchData(t, FileNumberArray ):

    FileDirectory = DataDirectory + str(FileNumberArray[t]) + '/'

    TimeFile = FileDirectory + '{:}.dat'.format( 'Time' )
    X1File   = FileDirectory + '{:}.dat'.format( 'X1' )
    dX1File  = FileDirectory + '{:}.dat'.format( 'dX1' )
    DataFile = FileDirectory + '{:}.dat'.format( Field )

    DataShape, DataUnits, MinVal, MaxVal = ReadHeader( DataFile )

    Time = np.loadtxt( TimeFile )
    X1_C = np.loadtxt( X1File   )
    dX1  = np.loadtxt( dX1File  )
    Data = np.loadtxt( DataFile )

    return Data, DataUnits, X1_C, dX1, Time








def InitializeFrame():

    line.set_data([],[])
    time_text.set_text('')
    if gvS.ShowIC:   IC  .set_data([],[])
    if gvS.PlotMesh: mesh.set_data([],[])

    if gvS.ShowIC and gvS.PlotMesh: ret = ( line, time_text, IC, mesh )
    elif gvS.ShowIC:                ret = ( line, time_text, IC )
    elif gvS.PlotMesh:              ret = ( line, time_text, mesh )
    else:                           ret = ( line, time_text )

    return ret






def UpdateFrame( t, FileNumberArray ):

    print('    {:}/{:}'.format( t+1, nSS ) )
    Data, DataUnits, X1_C, dX1, Time = fetchData(t, FileNumberArray )

    time_text.set_text( r'$t={:.3e}\ \left[\mathrm{{{:}}}\right]$' \
                        .format( Time, gvU.TimeUnits ) )

    line             .set_data( X1_C , Data .flatten() )
    if gvS.ShowIC:   IC  .set_data( X1_C0, Data0.flatten() )
    if gvS.PlotMesh: mesh.set_data( X1_C - 0.5 * dX1, \
                                0.5 * ( vmin + vmax ) \
                                  * np.ones( dX1.shape[0] ) )

    if gvS.ShowIC and gvS.PlotMesh: ret = ( line, time_text, IC, mesh )
    elif gvS.ShowIC:                ret = ( line, time_text, IC )
    elif gvS.PlotMesh:              ret = ( line, time_text, mesh )
    else:                           ret = ( line, time_text )

    return ret



def ReadHeader( DataFile ):

    f = open( DataFile )

    dum = f.readline()

    s = f.readline(); ind = s.find( ':' )+1
    DataShape = np.array( list( map( np.int64, s[ind:].split() ) ), np.int64 )

    s = f.readline(); ind = s.find( ':' )+1
    DataUnits = s[ind:]

    s = f.readline(); ind = s.find( ':' )+1
    MinVal = np.float64( s[ind:] )

    s = f.readline(); ind = s.find( ':' )+1
    MaxVal = np.float64( s[ind:] )

    f.close()

    return DataShape, DataUnits, MinVal, MaxVal
