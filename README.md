This repository contains the data and code to reproduce the engineering-economic optimization (EEO) modeling results from the study **"Simulating institutional heterogeneity in sustainability science"**. Optimization code is written using [JuMP](https://jump.dev/JuMP.jl/dev/) for [Julia](https://julialang.org/) and data processing and figures are generated using [Python](https://www.python.org/).

# File organization

## data

It contains two data folders to run EEO model.

1. `powergenome` is the main input data which provides major data resources such as load and generators in western USA.
2. `extra` contains additional data. It also includes `data_settings.yml`, which is a setting file to run PowerGenome package in order to get input data provided in `powergenome`. `PostProcessing.jl` is the Julia code which we use to edit/adjust the raw data provided by `PowerGenome` run.

## figs

It contains `figs.ipynb` notebook to generate Figure 3 in the main text and Figure S.2.1 in the supplementary file. It reads data from `powergenome` and `extra` folders, as well as model results from different folders. Running this notebook does not require any virtual environment. `base` environment can be used to successfully generate the figures. Users should install `odfpy` package to read results of ABM model.

## model

It includes Julia code to run EEO model and replicate the corresponding results in the paper. `batch` contains two `.sh` files, which are bash files to submit jobs in TORQUE clusters. Inside `batch`, `m2050_tbaseline_pregionalces_rbaseline_linear.sh` is used to replicate results with heterogeneity. `m2050_tbaseline_pregionalces_rregionalized_linear.sh` is used to replicate reference results (e.g., without institution or barriers).

## results

`eeo` folder contains EEO modeling results with and without heterogeneity (e.g., reference). `abm` and `iam` contain their modeling results in appropriate formats, solely to generate figures in the paper.

# Reproducing EEO results

There exist two ways of reproducing the results. One is to run the model in a TORQUE environment, and the other is to run on a local machine.

## To run the model in TORQUE

1. Make sure that Julia and Gurobi are installed.
2. Put folders `data` and `model` in the same directory.

To replicate heterogeneity results,

3. Uncomment `Line 116` in `ExpansionModel.jl`
4. Submit `m2050_tbaseline_pregionalces_rbaseline_linear.sh` in `model/batch`.

To replicate reference results,

3. Comment `Line 116` in `ExpansionModel.jl`
4. Submit `m2050_tbaseline_pregionalces_rregionalized_linear.sh` in `model/batch`.

## To run the model in local machines

1. Make sure that Julia and Gurobi are installed.
2. Put folders `data` and `model` in the same directory.

To replicate heterogeneity results,

3. Uncomment `Line 116` in `ExpansionModel.jl`
4. Change `runname` variable in `Line 4` of `Run.jl` to `m2050_tbaseline_pregionalces_rbaseline_linear`
5. Create an empty folder in `model/batch` with name `Results_m2050_tbaseline_pregionalces_rbaseline_linear`
6. Create an empty folder in `model/batch/Results_m2050_tbaseline_pregionalces_rbaseline_linear` with name `Dispatch`.
7. Run `Run.jl` file.

To replicate reference results,

3. Comment `Line 116` in `ExpansionModel.jl`
4. Change `runname` variable in `Line 4` of `Run.jl` to `m2050_tbaseline_pregionalces_rregionalized_linear`
5. Create an empty folder in `model/batch` with name `Results_m2050_tbaseline_pregionalces_rregionalized_linear`
6. Create an empty folder in `model/batch/Results_m2050_tbaseline_pregionalces_rregionalized_linear` with name `Dispatch`.
7. Run `Run.jl` file.
