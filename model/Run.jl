using JuMP, PyPlot, DataFrames, CSV, Gurobi, Missings, PyCall, Statistics # Importing required packages

# runname = first(split(last(split(@__FILE__, "/")), "."))
runname = ARGS[1]
actfilename = split(runname, "_")

# Scenario creation
global policy_scenario = "none"
global region_scenario = "none"

for spart in actfilename[1:4]

    global policy_scenario
    global region_scenario

    if spart[1] == 'p'
        policy_scenario = string(spart[2:end])
    elseif spart[1] == 'r'
        region_scenario = string(spart[2:end])
    else
        nothing
    end
end

mainloc = abspath(joinpath(@__DIR__))

# Solver parameters
solver_params = CSV.read(string(mainloc, "/solver_params.csv"), DataFrame)

include(string(mainloc, "/Paths.jl"))
include(string(mainloc, "/CreateBarLine.jl"))
include(string(mainloc, "/ExpansionModel.jl"))
include(string(mainloc, "/ProcessDispatch.jl"))
include(string(mainloc, "/ReadFiles.jl"))
include(string(mainloc, "/RecordCSV.jl"))
include(string(mainloc, "/RecordPlot.jl"))
include(string(mainloc, "/SetCreation.jl"))

ExpansionModel()

delete!(network, setNEWLINE)
select!(network, Not(:Line_Fixed_Cost_per_MW_yr))
CSV.write(string(inputpath, "Network.csv"), network)
