#!/usr/bin/env python3

import numpy as np
import gc
from charade import detect

import GlobalVariables_Settings as gvS
import GlobalVariables_Units    as gvU

from Utilities_Checks import CoordSystemCheck
from Utilities_GetField import GetFieldData

def GetData( FilePath,              \
             Field,                 \
             X1, X2, X3,            \
             dX1, dX2, dX3,         \
             SaveTime   = True      ):

    import yt
    import numpy as np

    CoordSystemCheck()

    # https://yt-project.org/doc/faq/index.html#how-can-i-change-yt-s-log-level
    yt.funcs.mylog.setLevel(40) # Suppress yt warnings

    ds = yt.load( '{:}'.format( FilePath ) )

    Time = ds.current_time.to_ndarray()


    # --- Get Data ---
    Data, DataUnits = GetFieldData( ds,                     \
                                    Field,                  \
                                    gvS.CoordinateSystem,   \
                                    X1, X2, X3,             \
                                    dX1, dX2, dX3           )

    print("After GetFieldData")

    if not gvS.UsePhysicalUnits: DataUnits = '[]'
    else:                    DataUnits = '[' + DataUnits + ']'



    #---- Clean Up ----
    del ds
    gc.collect()
    
    
    
    #---- Return ----
    if SaveTime :

        return Data, DataUnits, Time

    else:

        return Data, DataUnits
