
generators = CSV.read(string(inputpath, "Generators_data.csv"), DataFrame) # Reading generator data and create a data frame

demand = CSV.read(string(inputpath, "Load_data.csv"), DataFrame) # Reading demand data and create a data frame

# Reading non-served energy data and create a data frame
nse = DataFrame(Segment = collect(skipmissing(demand.Demand_segment)),
                NSE_Cost = collect(skipmissing(demand.Cost_of_demand_curtailment_perMW)) * first(demand.Voll),
                NSE_Max = collect(skipmissing(demand.Max_demand_curtailment)))
hours_per_period = Int(first(demand.Timesteps_per_Rep_Period)) # Reading hours per period data

# Create an array which is a collection of weights for each individual hour
numweek = Int(first(demand.Rep_Periods)) # Number of weeks in the modeling horizon
sample_weight = vcat(fill.(collect(skipmissing(demand.Sub_Weights)) / hours_per_period, hours_per_period)...)

# Get other info from PowerGenome repository
other_info = CSV.read(string(extrainputpath, "other_inputs.csv"), DataFrame)
network = CSV.read(string(inputpath, "Network.csv"), DataFrame) # Reading network data and create a data frame
filter!(row -> !(row.Line_Min_Flow_MW == 0), network)

addnetwork = CSV.read(string(extrainputpath, "new_transmission_lines.csv"), DataFrame) # Reading additional transmission lines
select!(addnetwork, Not(:Project))

regdesc, netzones = [], []
for x in collect(1:length(unique(generators.region)))
    push!(regdesc, first(generators[generators.Zone .== x, :region]))
    push!(netzones, string("z", x))
end

reg_zone = DataFrame()
reg_zone.Region_description = regdesc
reg_zone.Network_zones = netzones

# region_names = collect(skipmissing(network.Region_description))
region_names = reg_zone.Region_description

# <editor-fold Select transmission lines according to scenario>
# I added a label to indicate whether a transmission line is old or new
network.NewOld = fill("old", length(network.Network_Lines))

# if transmission_scenario == "baseline" && year_scenario == 2030
#     addnetwork = addnetwork[(addnetwork.Status .== "Very_likely") .| (addnetwork.Status .== "Likely"), :]
# end
select!(addnetwork, Not(:Status))
addnetwork.Network_Lines = collect(range(last(network.Network_Lines) + 1, length = length(addnetwork.Network_Lines)))

for x in setdiff(names(network), names(addnetwork))
    index = first(findall(t -> occursin(x, t), names(network)))
    if typeof(last(network[:,index])) == Missing
        insertcols!(addnetwork, index, x => missings(first(size(addnetwork))))
    elseif typeof(last(network[:,index])) == Int64
        insertcols!(addnetwork, index, x => zeros(first(size(addnetwork))))
    elseif typeof(last(network[:,index])) == Float64
        insertcols!(addnetwork, index, x => zeros(first(size(addnetwork))))
    end
end
# addnetwork.Network_Lines = addnetwork.Network_Lines .+ length(network.Network_Lines)
# if transmission_scenario != "baseline" append!(network, addnetwork) else nothing end
append!(network, addnetwork)
CSV.write(string(inputpath, "Network.csv"), network)
# </editor-fold>

# Get a clearer version of demand data frame and use it in the optimization
load_names = Array{String, 1}(undef, length(region_names))
for regnum in 1:length(region_names)
    load_names[regnum] = string("Load_MW_z", regnum)
end
load = select(demand, load_names)

genvar = CSV.read(string(inputpath, "Generators_variability.csv"), DataFrame) # Reading generator variability data and create a data frame

hydromin = DataFrame()
hydromax = DataFrame()
for (number, col) in enumerate(names(genvar))
    if occursin("conventional_hydroelectric", col) == true || occursin("hydropower", col) == true
        hydromin[!, col] = generators[number, :MinInter] .+ genvar[!, col] .* generators[number, :MinCoef]
        hydromax[!, col] = generators[number, :MaxInter] .+ genvar[!, col] .* generators[number, :MaxCoef]
    else
        hydromin[!, col] = zeros(first(size(genvar)))
        hydromax[!, col] = zeros(first(size(genvar)))
    end
end
hydromin .= ifelse.(hydromin .<= 0.01, 0.0, hydromin)
hydromax .= ifelse.(hydromax .<= 0.01, 0.0, hydromax)

initfinalstate = first(other_info[other_info.Parameter .== "initfinalstate", :Value])
minreservoirlevel = first(other_info[other_info.Parameter .== "reservoirminlevel", :Value])

# Get planning reserve requirements and adjust fixed import and export in proportion to peak demands
planningres = CSV.read(string(extrainputpath, "planning_reserve.csv"), DataFrame)
planningres.FImport = planningres.FImport / 1.0
planningres.FExport = planningres.FExport / 1.0
for row in eachrow(planningres)
    row.FImport = row.FImport * (1 + row.Growth)^(year_scenario - row.Data_year)
end
for row in eachrow(planningres)
    row.FExport = row.FExport * (1 + row.Growth)^(year_scenario - row.Data_year)
end

timepeakdemand = findmax(sum.(eachrow(load)))[2]
subgenvar = DataFrame()
push!(subgenvar, genvar[timepeakdemand,:])
hydrocol = union(findall(t -> occursin(string("conventional_hydroelectric"), t), names(subgenvar)),
                 findall(t -> occursin(string("hydropower"), t), names(subgenvar)))
subgenvar[1, hydrocol] = repeat(1.0:1.0, length(hydrocol))

# Read operating reserve fractions
operatingres = CSV.read(string(extrainputpath, "operating_reserve.csv"), DataFrame)
regional_load = first(operatingres.Load)
regional_renew = first(operatingres.Renewable)

# Read RPS targets
rpstargets = CSV.read(string(extrainputpath, "rps_targets.csv"), DataFrame)
rpsgoal = []
for row in eachrow(rpstargets)
    zone_target = 0
    if ismissing(row.RPS_Year_1) == false
        if row.RPS_Year_1 <= year_scenario
            zone_target = row.RPS_1
        else
            nothing
        end
    else
        zone_target = 0
    end
    if ismissing(row.RPS_Year_2) == false
        if row.RPS_Year_2 <= year_scenario
            zone_target = row.RPS_2
        else
            nothing
        end
    else
        nothing
    end
    push!(rpsgoal, zone_target)
end

cesgoal = []
for row in eachrow(rpstargets)
    zone_target = 0
    if ismissing(row.CES_Year_1) == false
        if row.CES_Year_1 <= year_scenario
            zone_target = row.CES_1
        else
            nothing
        end
    else
        zone_target = 0
    end
    if ismissing(row.CES_Year_2) == false
        if row.CES_Year_2 <= year_scenario
            zone_target = row.CES_2
        else
            nothing
        end
    else
        nothing
    end
    push!(cesgoal, zone_target)
end

# Read net import amount from Canada and Mexico
netimport = CSV.read(string(extrainputpath, "netimport.csv"), DataFrame)
for row in eachrow(netimport)
    row.Import = row.Import * (1 + row.Growth)^(year_scenario - row.Data_year)
end

voltage_cap = CSV.read(string(extrainputpath, "voltages_capacity.csv"), DataFrame)
voltage_count = CSV.read(string(extrainputpath, "voltages_lines.csv"), DataFrame)
select!(voltage_count, Not([:Network_Lines, :transmission_path_name]))

# Reading hurdle rates
hurdlerates = CSV.read(string(extrainputpath, "hurdle_rates.csv"), DataFrame)

# Reading regional planning reserve margin
region_margin = first(planningres[planningres.Regions .== "NorCal", :Margin])

# Reading cleanest RPS and CES shares
clean_RPS = first(other_info[other_info.Parameter .== "clean_rps", :Value])
clean_CES = first(other_info[other_info.Parameter .== "clean_ces", :Value])

# Reading in-state RPS and CES fractions
instate_rps = first(other_info[other_info.Parameter .== "instate_rps", :Value])
instate_ces = first(other_info[other_info.Parameter .== "instate_ces", :Value])

reinforcement_to_fixed = first(other_info[other_info.Parameter .== "reinforcement_to_fixed", :Value])
network.Line_Fixed_Cost_per_MW_yr = network.Line_Reinforcement_Cost_per_MWyr / reinforcement_to_fixed # Assign fixed cost
