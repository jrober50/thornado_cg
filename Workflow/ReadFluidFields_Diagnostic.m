function...
  [ Time, X1, X2, X3, Shock, Theta_1, Theta_2, Theta_3 ]...
    = ReadFluidFields_Diagnostic( AppName, FileNumber, Directory )

  if( exist( 'Directory', 'var' ) )
    DirName = Directory;
  else
    DirName = './Output';
  end

  FileName = [ DirName '/' AppName '_FluidFields_' sprintf( '%06d', FileNumber ) '.h5' ];

  Time = h5read( FileName, '/Time' );
  X1   = h5read( FileName, '/Spatial Grid/X1' );
  X2   = h5read( FileName, '/Spatial Grid/X2' );
  X3   = h5read( FileName, '/Spatial Grid/X3' );

  Shock   = h5read( FileName, '/Fluid Fields/Diagnostic/Shock' );
  Theta_1 = h5read( FileName, '/Fluid Fields/Diagnostic/Theta 1' );
  Theta_2 = h5read( FileName, '/Fluid Fields/Diagnostic/Theta 2' );
  Theta_3 = h5read( FileName, '/Fluid Fields/Diagnostic/Theta 3' );

end