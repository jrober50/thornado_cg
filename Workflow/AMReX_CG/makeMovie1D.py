#!/usr/bin/env python3

import numpy as np
from sys import argv
import matplotlib.pyplot as plt
plt.style.use( 'publication.sty' )


import GlobalVariables_Settings as gvS
from GlobalVariables_Units   import SetSpaceTimeUnits

from Utilities_Files         import GetFileNumberArray
from Utilities_MakeDataArray import MakeDataArray
from Utilities_MovieMaker    import MakeMovie

#### ========== User Input ==========

# Specify name of problem
ProblemName = 'YahilCollapse_XCFC'

# Specify title of figure
gvS.FigTitle = ProblemName

# Specify directory containing amrex Plotfiles
PlotDirectory = '/Users/nickroberts/thornado/SandBox/AMReX/Applications/YahilCollapse_XCFC/Data_9Lvls_512/'

# Specify plot file base name
PlotBaseName = ProblemName + '.plt'

# Specify field to plot
Field = 'AF_P'

# Specify to plot in log-scale
UseLogScale_X  = True
UseLogScale_Y  = True
UseLogScale_2D = False

# Specify whether or not to use physical units
UsePhysicalUnits = False

# Specify coordinate system (currently supports 'cartesian' and 'spherical')
CoordinateSystem = 'cartesian'

# Only use every <plotEvery> plotfile
PlotEvery = 20

# First and last snapshots and number of snapshots to include in movie
SSi = 553 # -1 -> SSi = 0
SSf = 2248 # -1 -> plotfileArray.shape[0] - 1
nSS = -1 # -1 -> plotfileArray.shape[0]


# Max level of refinement to plot (-1 plots leaf elements)
gvS.MaxLevel = -1

# Include initial conditions in movie?
gvS.ShowIC = True

gvS.PlotMesh = False

# Write extra info to screen
gvS.Verbose = True

# Use custom limts for y-axis (1D) or colorbar (2D)
gvS.UseCustomLimits = False
gvS.vmin = 0.0
gvS.vmax = 2.0

gvS.MovieRunTime = 10.0 # seconds

gvS.ShowRefinement = True
gvS.RefinementLocations = [ 5.0e+4, 2.5E+4, 1.25E+4, 6.25E+3, 3.125E+3, \
                        1.5625E+3, 7.8125E+2, 3.90625E+2, 1.953125E+2 ]

#### ====== End of User Input =======

DataDirectory = '.{:s}_test'.format( ProblemName )

ID            = '{:s}_{:s}'.format( ProblemName, Field )
gvS.MovieName     = 'mov.{:s}.mp4'.format( ID )

# Append "/" to PlotDirectory, if not present
if not PlotDirectory[-1] == '/': PlotDirectory += '/'

#if type(Field) is not list: Field = [ Field ]
#if type(DataDirectory) is not list: DataDirectory = [ DataDirectory ]

SetSpaceTimeUnits(CoordinateSystem, UsePhysicalUnits)

        
FileNumberArray = GetFileNumberArray( PlotDirectory,      \
                                      PlotBaseName,       \
                                      SSi, SSf,           \
                                      PlotEvery           )

MakeDataArray( FileNumberArray, \
               PlotDirectory,   \
               PlotBaseName,    \
               Field,           \
               DataDirectory    )


MakeMovie( FileNumberArray, \
           PlotDirectory,   \
           [Field],           \
           [DataDirectory]    )
