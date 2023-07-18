#!/usr/bin/env python3

import numpy as np






def GetFieldData( ds,                   \
                  Field,                \
                  CoordinateSystem,     \
                  X1, X2, X3,           \
                  dX1, dX2, dX3         ):
                  
        
    nX1 = X1.shape[0]
    nX2 = X2.shape[0]
    nX3 = X3.shape[0]
    
    print(nX1,nX2,nX3)
    
    Locations = [None]*nX1*nX2*nX3
    for k in range(nX3):
        for j in range(nX2):
            for i in range(nX1):
                Here = k*nX1*nX2    \
                     + j*nX1        \
                     + i
                Locations[Here] = np.array([X1[i],X2[j],X3[k]])
    
    print("after locs")
    if Field == 'MPIProcess':

        Data = np.copy( CoveringGrid['MPIProcess'].to_ndarray() )
        DataUnits = ''

    elif Field == 'PF_D':
        print("Before np.copy")
        Data = np.copy( ds.find_field_values_at_points(     \
                            ("boxlib",Field), Locations ) )
        DataUnits = 'g/cm^3'
        print("after np.copy")
    elif Field == 'PF_V1':

        Data = np.copy( CoveringGrid[Field].to_ndarray() )
        DataUnits = 'km/s'

    elif Field == 'PF_V2':

        Data = np.copy( CoveringGrid[Field].to_ndarray() )

        if   CoordinateSystem == 'cartesian'  : DataUnits = 'km/s'
        elif CoordinateSystem == 'cylindrical': DataUnits = 'km/s'
        elif CoordinateSystem == 'spherical'  : DataUnits = '1/s'

    elif Field == 'PF_V3':

        Data = np.copy( CoveringGrid[Field].to_ndarray() )

        if   CoordinateSystem == 'cartesian'  : DataUnits = 'km/s'
        elif CoordinateSystem == 'cylindrical': DataUnits = '1/s'
        elif CoordinateSystem == 'spherical'  : DataUnits = '1/s'

    elif Field == 'PF_E':

        Data = np.copy( CoveringGrid[Field].to_ndarray() )
        DataUnits = 'erg/cm^3'

    elif Field == 'PF_Ne':

        Data = np.copy( CoveringGrid[Field].to_ndarray() )
        DataUnits = '1/cm^3'

    elif Field == 'CF_D':

        Data = np.copy( CoveringGrid[Field].to_ndarray() )
        DataUnits = 'g/cm^3'

    elif Field == 'CF_S1':

        Data = np.copy( CoveringGrid[Field].to_ndarray() )
        DataUnits = 'g/cm^2/s'

    elif Field == 'CF_S2':

        Data = np.copy( CoveringGrid[Field].to_ndarray() )

        if   CoordinateSystem == 'cartesian'  : DataUnits = 'g/cm^2/s'
        elif CoordinateSystem == 'cylindrical': DataUnits = 'g/cm^2/s'
        elif CoordinateSystem == 'spherical'  : DataUnits = 'g/cm/s'

    elif Field == 'CF_S3':

        Data = np.copy( CoveringGrid[Field].to_ndarray() )

        if   CoordinateSystem == 'cartesian'  : DataUnits = 'g/cm^2/s'
        elif CoordinateSystem == 'cylindrical': DataUnits = 'g/cm/s'
        elif CoordinateSystem == 'spherical'  : DataUnits = 'g/cm/s'

    elif Field == 'CF_E':

        Data = np.copy( CoveringGrid[Field].to_ndarray() )
        DataUnits = 'erg/cm^3'

    elif Field == 'CF_Ne':

        Data = np.copy( CoveringGrid[Field].to_ndarray() )
        DataUnits = '1/cm^3'

    elif Field == 'AF_P':

        Data = np.copy( CoveringGrid[Field].to_ndarray() )
        DataUnits = 'erg/cm^3'

    elif Field == 'AF_Ye':

        Data = np.copy( CoveringGrid[Field].to_ndarray() )
        DataUnits = ''

    elif Field == 'AF_T':

        Data = np.copy( CoveringGrid[Field].to_ndarray() )
        DataUnits = 'K'

    elif Field == 'AF_S':

        Data = np.copy( CoveringGrid[Field].to_ndarray() )
        DataUnits = 'kb/baryon'

    elif Field == 'AF_Cs':

        Data = np.copy( CoveringGrid[Field].to_ndarray() )
        DataUnits = 'km/s'

    elif Field == 'GF_Gm_11':

        Data = np.copy( CoveringGrid[Field].to_ndarray() )
        DataUnits = ''

    elif Field == 'GF_Gm_22':

        Data = np.copy( CoveringGrid[Field].to_ndarray() )

        if   CoordinateSystem == 'cartesian'  : DataUnits = ''
        elif CoordinateSystem == 'cylindrical': DataUnits = ''
        elif CoordinateSystem == 'spherical'  : DataUnits = 'km^2'

    elif Field == 'GF_Gm_33':

        Data = np.copy( CoveringGrid[Field].to_ndarray() )

        if   CoordinateSystem == 'cartesian'  : DataUnits = ''
        elif CoordinateSystem == 'cylindrical': DataUnits = 'km^2'
        elif CoordinateSystem == 'spherical'  : DataUnits = 'km^2'

    elif Field == 'GF_K_11':

        Data = np.copy( CoveringGrid[Field].to_ndarray() )

        if   CoordinateSystem == 'cartesian'  : DataUnits = ''
        elif CoordinateSystem == 'cylindrical': DataUnits = ''
        elif CoordinateSystem == 'spherical'  : DataUnits = ''

    elif Field == 'GF_Psi':

        Data = np.copy( CoveringGrid[Field].to_ndarray() )
        DataUnits = ''

    elif Field == 'GF_Alpha':

        Data = np.copy( CoveringGrid[Field].to_ndarray() )
        DataUnits = ''

    elif Field == 'GF_Beta_1':

        Data = np.copy( CoveringGrid[Field].to_ndarray() )
        DataUnits = 'km/s'

    elif Field == 'DF_TCI':

        Data = np.copy( CoveringGrid[Field].to_ndarray() )
        DataUnits = ''

    # --- Derived Fields ---

    elif Field == 'alphaE':

        alpha = np.copy( CoveringGrid['GF_Alpha'].to_ndarray() )
        D     = np.copy( CoveringGrid['CF_D'].to_ndarray() )
        tau   = np.copy( CoveringGrid['CF_E'].to_ndarray() )

        Data = alpha * ( tau + D )
        DataUnits = 'erg/cm^3'

    elif Field == 'pr4':

        p = np.copy( CoveringGrid['AF_P'].to_ndarray() )

        Data = np.empty( (nX[0],nX[1],nX[2]), np.float64 )

        for iX1 in range( nX[0] ):
            for iX2 in range( nX[1] ):
                for iX3 in range( nX[2] ):
                    Data[iX1,iX2,iX3] = p[iX1,iX2,iX3] \
                                          * ( X1[iX1,iX2,iX3] * 1.0e5 )**4

        DataUnits = 'erg*cm'

    elif Field == 'RelativisticBernoulliConstant':

        c = 2.99792458e10

        rho   = np.copy( CoveringGrid['PF_D'    ].to_ndarray() )
        e     = np.copy( CoveringGrid['PF_E'    ].to_ndarray() )
        v1    = np.copy( CoveringGrid['PF_V1'   ].to_ndarray() ) * 1.0e5
        v2    = np.copy( CoveringGrid['PF_V2'   ].to_ndarray() )
        p     = np.copy( CoveringGrid['AF_P'    ].to_ndarray() )
        alpha = np.copy( CoveringGrid['GF_Alpha'].to_ndarray() )
        Gm11  = np.copy( CoveringGrid['GF_Gm11' ].to_ndarray() )
        Gm22  = np.copy( CoveringGrid['GF_Gm22' ].to_ndarray() ) * ( 1.0e5 )**2

        VSq = Gm11 * v1**2 + Gm22 * v2**2

        h = c**2 + ( e + p ) / rho
        W = 1.0 / np.sqrt( 1.0 - VSq / c**2 )

        B = alpha * h * W

        Data = B

        DataUnits = 'cm^2/s^2'

    elif Field == 'PolytropicConstant':

        PF_D  = np.copy( CoveringGrid['PF_D' ].to_ndarray() )
        AF_P  = np.copy( CoveringGrid['AF_P' ].to_ndarray() )
        AF_Gm = np.copy( CoveringGrid['AF_Gm'].to_ndarray() )

        Data  = AF_P / PF_D**AF_Gm

        DataUnits = 'erg/cm^3/(g/cm^3)^(Gamma_IDEAL)'

    elif Field == 'NonRelativisticSpecificEnthalpy':

        e   = np.copy( CoveringGrid['PF_E'].to_ndarray() )
        p   = np.copy( CoveringGrid['AF_P'].to_ndarray() )
        rho = np.copy( CoveringGrid['PF_D'].to_ndarray() )

        Data = ( e + p ) / rho

        DataUnits = 'cm^2/s^2'

    elif Field == 'RelativisticSpecificEnthalpy':

        c = 2.99792458e10

        e   = np.copy( CoveringGrid['PF_E'].to_ndarray() )
        p   = np.copy( CoveringGrid['AF_P'].to_ndarray() )
        rho = np.copy( CoveringGrid['PF_D'].to_ndarray() )

        Data = ( c**2 + ( e + p ) / rho ) / c**2

        DataUnits = ''

    elif Field == 'LorentzFactor':

        c = 2.99792458e5

        Gm11 = np.copy( CoveringGrid['GF_Gm_11'].to_ndarray() )
        Gm22 = np.copy( CoveringGrid['GF_Gm_22'].to_ndarray() )
        Gm33 = np.copy( CoveringGrid['GF_Gm_33'].to_ndarray() )

        V1 = np.copy( CoveringGrid['PF_V1'].to_ndarray() )
        V2 = np.copy( CoveringGrid['PF_V2'].to_ndarray() )
        V3 = np.copy( CoveringGrid['PF_V3'].to_ndarray() )

        VSq = Gm11 * V1**2 + Gm22 * V2**2 + Gm33 * V3**2

        Data = 1.0 / np.sqrt( 1.0 - VSq / c**2 )

        DataUnits = ''

    elif Field == 'TurbulentVelocity':

        Psi  = np.copy( CoveringGrid['GF_Psi'  ].to_ndarray() )
        Gm11 = np.copy( CoveringGrid['GF_Gm_11'].to_ndarray() )
        Gm22 = np.copy( CoveringGrid['GF_Gm_22'].to_ndarray() )
        Gm33 = np.copy( CoveringGrid['GF_Gm_33'].to_ndarray() )

        rho = np.copy( CoveringGrid['PF_D' ].to_ndarray() )
        V1  = np.copy( CoveringGrid['PF_V1'].to_ndarray() )
        V2  = np.copy( CoveringGrid['PF_V2'].to_ndarray() )
        V3  = np.copy( CoveringGrid['PF_V3'].to_ndarray() )

        # --- Compute angle-averaged and
        #     mass density weighted radial velocity ---

        AngleAveragedMass           = np.zeros( (nX[0]), np.float64 )
        AngleAveragedRadialVelocity = np.zeros( (nX[0]), np.float64 )

        Data = np.empty( nX, np.float64 )

        for iX1 in range( nX[0] ):

            for iX2 in range( nX[1] ):
                for iX3 in range( nX[2] ):

                    AngleAveragedMass[iX1] \
                      += rho[iX1,iX2,iX3] \
                           * Psi[iX1,iX2,iX3]**4 \
                           * np.sin( X2[iX1,iX2,iX3] ) \
                           * dX1[iX1,iX2,iX3] * dX2[iX1,iX2,iX3]

                    AngleAveragedRadialVelocity[iX1] \
                      += V1[iX1,iX2,iX3] * rho[iX1,iX2,iX3] \
                           * Psi[iX1,iX2,iX3]**4 \
                           * np.sin( X2[iX1,iX2,iX3] ) \
                           * dX1[iX1,iX2,iX3] * dX2[iX1,iX2,iX3]

            AngleAveragedRadialVelocity[iX1] /= AngleAveragedMass[iX1]

            for iX2 in range( nX[1] ):
                for iX3 in range( nX[2] ):

                    Data[iX1,iX2,iX3] \
                      = np.sqrt( \
                          Gm11[iX1,iX2,iX3] \
                            * ( V1[iX1,iX2,iX3] \
                                  - AngleAveragedRadialVelocity[iX1] )**2 \
                            + Gm22[iX1,iX2,iX3] * V2[iX1,iX2,iX3]**2 \
                            + Gm33[iX1,iX2,iX3] * V3[iX1,iX2,iX3]**2 )

        DataUnits = 'km/s'

    elif Field == 'TurbulentEnergyDensity':

        Psi  = np.copy( CoveringGrid['GF_Psi'  ].to_ndarray() )
        Gm11 = np.copy( CoveringGrid['GF_Gm_11'].to_ndarray() )
        Gm22 = np.copy( CoveringGrid['GF_Gm_22'].to_ndarray() )
        Gm33 = np.copy( CoveringGrid['GF_Gm_33'].to_ndarray() )

        rho = np.copy( CoveringGrid['PF_D' ].to_ndarray() )
        V1  = np.copy( CoveringGrid['PF_V1'].to_ndarray() )
        V2  = np.copy( CoveringGrid['PF_V2'].to_ndarray() )
        V3  = np.copy( CoveringGrid['PF_V3'].to_ndarray() )

        AngleAveragedMass           = np.zeros( (nX[0]), np.float64 )
        AngleAveragedRadialVelocity = np.zeros( (nX[0]), np.float64 )

        c = 2.99792458e5

        Data = np.empty( nX, np.float64 )

        for iX1 in range( nX[0] ):

            # --- Compute angle-averaged and
            #     mass density weighted radial velocity ---

            for iX2 in range( nX[1] ):
                for iX3 in range( nX[2] ):

                    AngleAveragedMass[iX1] \
                      += rho[iX1,iX2,iX3] \
                           * Psi[iX1,iX2,iX3]**4 \
                           * np.sin( X2[iX1,iX2,iX3] ) \
                           * dX1[iX1,iX2,iX3] * dX2[iX1,iX2,iX3]

                    AngleAveragedRadialVelocity[iX1] \
                      += V1[iX1,iX2,iX3] * rho[iX1,iX2,iX3] \
                           * Psi[iX1,iX2,iX3]**4 \
                           * np.sin( X2[iX1,iX2,iX3] ) \
                           * dX1[iX1,iX2,iX3] * dX2[iX1,iX2,iX3]

            AngleAveragedRadialVelocity[iX1] /= AngleAveragedMass[iX1]

            # --- Compute turbulent energy density ---

            for iX2 in range( nX[1] ):
                for iX3 in range( nX[2] ):

                    # --- BetaSq = v_i * v^i / c^2 ---

                    BetaSq = ( Gm11[iX1,iX2,iX3] \
                                 * ( V1[iX1,iX2,iX3] \
                                       - AngleAveragedRadialVelocity[iX1] )**2 \
                                 + Gm22[iX1,iX2,iX3] * V2[iX1,iX2,iX3]**2 \
                                 + Gm33[iX1,iX2,iX3] * V3[iX1,iX2,iX3]**2 ) \
                               / c**2

                    W = 1.0 / np.sqrt( 1.0 - BetaSq )

                    Data[iX1,iX2,iX3] \
                      = rho[iX1,iX2,iX3] * ( c * 1.0e5 )**2 \
                          * W**2 * BetaSq / ( W + 1.0 )

        DataUnits = 'erg/cm^3'

    elif Field == 'Vorticity':

        h1 = np.copy( CoveringGrid['GF_h_1'].to_ndarray() )
        h2 = np.copy( CoveringGrid['GF_h_2'].to_ndarray() )
        V1 = np.copy( CoveringGrid['PF_V1' ].to_ndarray() )
        V2 = np.copy( CoveringGrid['PF_V2' ].to_ndarray() )

        h1A = np.empty( (nX[0],nX[1]+2,nX[2]), np.float64 )
        h2A = np.empty( (nX[0],nX[1]+2,nX[2]), np.float64 )
        V1A = np.empty( (nX[0],nX[1]+2,nX[2]), np.float64 )
        V2A = np.empty( (nX[0],nX[1]+2,nX[2]), np.float64 )

        h1A[:,1:-1,:] = np.copy( h1 )
        h2A[:,1:-1,:] = np.copy( h2 )
        V1A[:,1:-1,:] = np.copy( V1 )
        V2A[:,1:-1,:] = np.copy( V2 )

        # --- Apply reflecting boundary conditions in theta ---

        for i in range( nX[0] ):
            for k in range( nX[2] ):

                h1A[i,0,k] = +h1A[i,1,k]
                h2A[i,0,k] = +h2A[i,1,k]
                V1A[i,0,k] = +V1A[i,1,k]
                V2A[i,0,k] = -V2A[i,1,k]

                h1A[i,-1,k] = +h1A[i,-2,k]
                h2A[i,-1,k] = +h2A[i,-2,k]
                V1A[i,-1,k] = +V1A[i,-2,k]
                V2A[i,-1,k] = -V2A[i,-2,k]

        # --- Compute vorticity in domain using
        #     central differences for derivatives (assume 2D) ---

        Data = np.zeros( (nX[0],nX[1],nX[2]), np.float64 )

        for i in range( 1, nX[0] - 1 ):
            for j in range( 1, nX[1] + 1 ):
                for k in range( nX[2] ):

                    Data[i,j-1,k] \
                      = 1.0 / ( h1A[i,j,k]      * h2A[i,j,k] ) \
                        * ( (   h2A[i+1,j,k]**2 * V2A[i+1,j,k] \
                              - h2A[i-1,j,k]**2 * V2A[i-1,j,k] ) \
                              / ( 2.0 * X1[i,j,k] ) \
                          - (   h1A[i,j+1,k]**2 * V1A[i,j+1,k] \
                              - h1A[i,j-1,k]**2 * V1A[i,j-1,k] ) \
                              / ( 2.0 * X2[i,j-1,k] ) )

        DataUnits = '1/s'

    else:

        print( '\nInvalid field: {:}'.format( Field ) )
        print( '\nValid choices:' )
        print( '--------------' )
        print( '  MPIProcess' )
        print( '  PF_D' )
        print( '  PF_V1' )
        print( '  PF_V2' )
        print( '  PF_V3' )
        print( '  PF_E' )
        print( '  PF_Ne' )
        print( '  CF_D' )
        print( '  CF_S1' )
        print( '  CF_S2' )
        print( '  CF_S3' )
        print( '  CF_E' )
        print( '  CF_Ne' )
        print( '  AF_P' )
        print( '  AF_Ye' )
        print( '  AF_T' )
        print( '  AF_S' )
        print( '  AF_Cs' )
        print( '  GF_Gm_11' )
        print( '  GF_Gm_22' )
        print( '  GF_Gm_33' )
        print( '  GF_K_11' )
        print( '  GF_Psi' )
        print( '  GF_Alpha' )
        print( '  GF_Beta_1' )
        print( '  DF_TCI' )
        print( '  alphaE' )
        print( '  pr4' )
        print( '  RelativisticBernoulliConstant' )
        print( '  PolytropicConstant' )
        print( '  NonRelativisticSpecificEnthalpy' )
        print( '  RelativisticSpecificEnthalpy' )
        print( '  LorentzFactor' )
        print( '  TurbulentVelocity' )
        print( '  TurbulentEnergyDensity' )
        print( '  Vorticity' )

        assert 0, 'Invalid choice of field'

    return Data, DataUnits
