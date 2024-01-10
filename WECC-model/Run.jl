
using JuMP, PyPlot, DataFrames, CSV, Gurobi, Missings, PyCall, Statistics, TimerOutputs # Importing required packages

##### Two-stage #####
two_stage = false
#####################

# runname = first(split(last(split(@__FILE__, "/")), "."))
runname = ARGS[1]
actfilename = split(runname, "_")

# Scenario creation
global year_scenario = 0
global transmission_scenario = "none"
global policy_scenario = "none"
global region_scenario = "none"

for spart in actfilename[1:4]

    global year_scenario
    global transmission_scenario
    global policy_scenario
    global region_scenario

    if spart[1] == 'm'
        year_scenario = parse(Int64, spart[2:end])
    elseif spart[1] == 't'
        transmission_scenario = string(spart[2:end])
    elseif spart[1] == 'p'
        policy_scenario = string(spart[2:end])
    elseif spart[1] == 'r'
        region_scenario = string(spart[2:end])
    else
        nothing
    end
end

transcost_sens = actfilename[5]

# year_scenario = 2050 # 2030 or 2050
# transmission_scenario = "baseline" # or baseline or expanded
# policy_scenario = "state" # or state or regionalrps or regionalces
# region_scenario = "baseline" # or baseline or expandedEIM or regionalized

# Path information
# mainloc = "/Users/Kucuksayacigil/Desktop/WECC-model/"
# mainloc = "/oasis/tscc/scratch/fkucuksayacigil/WECC-model/"
# mainloc = abspath(joinpath(@__DIR__, ".."))
mainloc = abspath(joinpath(@__DIR__))

# Solver parameters
solver_params = CSV.read(string(mainloc, "/solver_params.csv"), DataFrame)

const to = TimerOutput()

@timeit to "define_paths" include(string(mainloc, "/Paths.jl"))
@timeit to "define_figcreation" include(string(mainloc, "/CreateBarLine.jl"))
@timeit to "define_optimization" include(string(mainloc, "/ExpansionModel.jl"))
@timeit to "define_fixmodel" include(string(mainloc, "/FixModel.jl"))
@timeit to "define_stackcreation" include(string(mainloc, "/ProcessDispatch.jl"))
@timeit to "define_inputs" include(string(mainloc, "/ReadFiles.jl"))
@timeit to "define_reporting" include(string(mainloc, "/RecordCSV.jl"))
@timeit to "define_plotting" include(string(mainloc, "/RecordPlot.jl"))
@timeit to "define_sets" include(string(mainloc, "/SetCreation.jl"))
# include("WriteResults.jl") # Import user-defined function to write results. See WriteResults.jl file for this function

@timeit to "build_model_solve_model_report_results" ExpansionModel()

delete!(network, setNEWLINE)
select!(network, Not(:Line_Fixed_Cost_per_MW_yr))
CSV.write(string(inputpath, "Network.csv"), network)

show(to)
