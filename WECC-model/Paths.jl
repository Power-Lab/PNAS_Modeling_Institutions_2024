
# inputpath = string("/Users/Kucuksayacigil/Desktop/PowerGenome_Output/", year_scenario, "/single_", year_scenario, "_A_single_scenario/Inputs/") # Input data location
# resultpath = "/Users/Kucuksayacigil/Desktop/Results/" # Location of result file
# extrainputpath = "/Users/Kucuksayacigil/Desktop/WECC-data/extra_inputs/"
# inputpath = string("/oasis/tscc/scratch/fkucuksayacigil/PowerGenome_Output/", year_scenario, "/single_", year_scenario, "_A_single_scenario/Inputs/")
# resultpath = "/oasis/tscc/scratch/fkucuksayacigil/WECC-model/Results/" # Location of result file
# extrainputpath = "/oasis/tscc/scratch/fkucuksayacigil/WECC-data/extra_inputs/"
# dispatchpath = string(resultpath, "Dispatch/") # Location of dispatch csv files
inputpath = abspath(joinpath(@__DIR__, "..", "PowerGenome_Output/", string(year_scenario), string("single_", year_scenario, "_A_single_scenario/"), "Inputs/"))
resultpath = abspath(joinpath(@__DIR__, string("Batch/Results_", runname, "/")))
extrainputpath = abspath(joinpath(@__DIR__, "..", "WECC-data/", "extra_inputs/"))
dispatchpath = abspath(joinpath(resultpath, "Dispatch/"))

##### Two-stage #####
if two_stage == true
    if region_scenario == "baseline"
        fixed_resultpath = abspath(string("/home/fkucuksayacigil/Results/Results_m2050_tbaseline_pregionalces_rregionalized_linear/"))
    elseif region_scenario == "regionalized"
        fixed_resultpath = abspath(string("/home/fkucuksayacigil/Results/Results_m2050_tbaseline_pregionalces_rbaseline_linear/"))
    end
end
#####################
