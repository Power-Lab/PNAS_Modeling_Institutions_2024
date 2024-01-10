# WECC-model
This repository involves renewable capacity expansion model for western states

The first ile is GetInput.jl.
  It gets input data path and results folder path.
  User need to create a folder for results and give its path.
  It gets some user inputs.
  It also gets capacity bounds for new build resources.
  
The second file is ReadFiles.jl.
  It reads the data files for generators, fuels, demand, network, and generator variability.
  
The third file is SetCreation.jl.
  This constructs several sets, ready to be used by the optimization model.
  
The fourth file is CapBound.jl.
  Based on the capacity bounds read in the first step above, this file updates generator data set.
  It assigns appropriate numbers for num_units column in the generator data set.
  num_units multiplied with Cap_size are the capacity bounds given above.
  
The fifth file is ExpansionModel.jl
  This is the optimization model.
  
The last file is WriteResults.jl.
  It writes optimal values of decisions variables into csv files and creates relevant plots.
  
Run.jl is the main file.
  User can directly run this file to get the optimization results.
  User should give the correct folder paths of input data and result.
  
Surplus.jl is the collection of old codes.

Most of this code is commented, but I will continue writing documentation for the rest.

This code is in progress...
