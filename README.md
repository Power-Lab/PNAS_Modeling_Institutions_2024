# File organization

## data

It contains two data folders to run EEO model.

1. `powergenome` is the main input data which provides major data resources such as load and generators in western USA.
2. `extra` contains additional data. It also includes `data_settings.yml`, which is a setting file to run PowerGenome package in order to get input data provided in `powergenome`.

## figs

It contains a `figs.ipynb` notebook to generate Figure 3 in the main text and Figure S.2.1 in the supplementary file. It reads data from `powergenome` and `extra` folders, as well as model results from different folders. Running this notebook does not require any virtual environment. `base` environment can be used to successfully generate the figures. Users should install `odfpy` package to read results of ABM model.
