inputpath = abspath(joinpath(@__DIR__, "..", "data/powergenome/"))
resultpath = abspath(joinpath(@__DIR__, string("batch/Results_", runname, "/")))
extrainputpath = abspath(joinpath(@__DIR__, "..", "data/extra/extra_inputs/"))
dispatchpath = abspath(joinpath(resultpath, "Dispatch/"))
