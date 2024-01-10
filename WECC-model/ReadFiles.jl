
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

# fuels = CSV.read(string(inputpath, "Fuels_data.csv"), DataFrame) # Reading fuels data and create a data frame

# intercept_minreserve = first(other_info[other_info.Parameter .== "intercept_minreserve", :Value])
# coeff_minreserve = first(other_info[other_info.Parameter .== "coeff_minreserve", :Value])
initfinalstate = first(other_info[other_info.Parameter .== "initfinalstate", :Value])
minreservoirlevel = first(other_info[other_info.Parameter .== "reservoirminlevel", :Value])
DC_to_AC = first(other_info[other_info.Parameter .== "dc_to_ac", :Value])
new_AC_voltage = first(other_info[other_info.Parameter .== "new_AC_voltage", :Value])
if new_AC_voltage == 500
    snew_AC_voltage = "FiveH_AC"
elseif new_AC_voltage == 345
    snew_AC_voltage = "ThreeH_AC"
elseif new_AC_voltage == 230
    snew_AC_voltage = "TwoH_AC"
else
    nothing
end
sub_distance_AC = first(other_info[other_info.Parameter .== "sub_distance_AC", :Value])
num_conv_DC = first(other_info[other_info.Parameter .== "num_conv_DC", :Value])

# numnewline = first(size(CSV.read(string(extrainputpath, "new_transmission_lines.csv"), DataFrame))) # Reading additional transmission lines
# numnewline = first(size(network[network.NewOld .== "new", :]))

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

# planningres.AdjFImport = zeros(first(size(planningres)))
# planningres.AdjFExport = zeros(first(size(planningres)))
timepeakdemand = findmax(sum.(eachrow(load)))[2]
subgenvar = DataFrame()
push!(subgenvar, genvar[timepeakdemand,:])
hydrocol = union(findall(t -> occursin(string("conventional_hydroelectric"), t), names(subgenvar)),
                 findall(t -> occursin(string("hydropower"), t), names(subgenvar)))
subgenvar[1, hydrocol] = repeat(1.0:1.0, length(hydrocol))
#
# for bal in unique(planningres.Aggregated)
#     zones = planningres[planningres.Aggregated .== bal, :Zones]
#     imp = first(planningres[planningres.Aggregated .== bal, :FImport])
#     expo = first(planningres[planningres.Aggregated .== bal, :FExport])
#     numzones = length(zones)
#
#     maxs = Float64[]
#     for zone in zones
#         push!(maxs, maximum(load[:,zone]))
#     end
#     prop = maxs ./ sum(maxs)
#
#     adjimp = imp * prop
#     adjexp = expo * prop
#
#     planningres.AdjFImport[zones] = adjimp
#     planningres.AdjFExport[zones] = adjexp
# end

# Create total transmission limits for each zone
# totaltrans = DataFrame()
# totaltrans.Zones = collect(1:length(region_names))
# totlimit = Float64[]
# for num in 1:length(region_names)
#     lim = sum(network[(network[:,string("z",num)]) .== 1, :Line_Max_Flow_MW]) + sum(network[(network[:,string("z",num)]) .== -1, :Line_Max_Flow_MW])
#     push!(totlimit, lim)
# end
# totaltrans.TotalLimit = totlimit

# Find contingency requirement (Configuration 2 in Jenkins and Sepulveda)
# contingency = DataFrame()
# contingency.Zones = collect(1:length(region_names))
#
# contnum = Float64[]
# for num in 1:length(region_names)
#     # translim = maximum([maximum(network[(network[:,string("z",num)]) .== 1, :Line_Max_Flow_MW]), maximum(network[(network[:,string("z",num)]) .== -1, :Line_Max_Flow_MW])])
#     genlim = maximum(generators[generators.zone .== num, :Cap_size])
#     # push!(contnum, maximum([translim, genlim]))
#     push!(contnum, genlim)
# end
# contingency.TotalLimit = contnum
# contingency = maximum([maximum(generators.Cap_size), maximum(network.Line_Max_Flow_MW)])

# Read operating reserve fractions
operatingres = CSV.read(string(extrainputpath, "operating_reserve.csv"), DataFrame)
# load_fraction = first(operatingres[operatingres.Contribution .== "Load", :Fraction])
# renew_fraction = first(operatingres[operatingres.Contribution .== "Renewable", :Fraction])
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

# Read line and substation costs for new AC and DC lines
# Read ROW costs for different voltages levels
# Read transformer and converter costs for upgrading old AC lines
# Read assumed capacity information for voltage levels
# Read voltage details for existing lines
linesub_cost_new_ACDC = CSV.read(string(extrainputpath, "linesubconv_cost_new_ACDC_line.csv"), DataFrame)
row_costs = CSV.read(string(extrainputpath, "row_costs_lines_permile.csv"), DataFrame)
select!(row_costs, Not([:Network_Lines, :transmission_path_name]))
tranconv_costs_upgrade = CSV.read(string(extrainputpath, "transformer_converter_cost_upgrade.csv"), DataFrame)
select!(tranconv_costs_upgrade, Not(:fromto_perMW))
voltage_cap = CSV.read(string(extrainputpath, "voltages_capacity.csv"), DataFrame) # 4000 MW of 500 kV DV is based on https://www.energy.gov/sites/default/files/2016/10/f33/2.%20HVDC%20Panel%20-%20Michael%20Skelly%2C%20Clean%20Line%20Energy.pdf
voltage_count = CSV.read(string(extrainputpath, "voltages_lines.csv"), DataFrame)
select!(voltage_count, Not([:Network_Lines, :transmission_path_name]))

# Reading hurdle rates
hurdlerates = CSV.read(string(extrainputpath, "hurdle_rates.csv"), DataFrame)

# Reading additional import and export for expandedEIM scenario
addimpexp = first(other_info[other_info.Parameter .== "impexp_inc", :Value])

# Reading regional planning reserve margin
region_margin = first(planningres[planningres.Regions .== "NorCal", :Margin])

# Reading cleanest RPS and CES shares
clean_RPS = first(other_info[other_info.Parameter .== "clean_rps", :Value])
clean_CES = first(other_info[other_info.Parameter .== "clean_ces", :Value])

# Determine big M for REC
# bigMREC = maximum(network.Line_Max_Flow_MW) * length(sample_weight) * 52
# bigMREC = maximum(network.Line_Max_Flow_MW) * sum(sample_weight)

# Reading in-state RPS and CES fractions
instate_rps = first(other_info[other_info.Parameter .== "instate_rps", :Value])
instate_ces = first(other_info[other_info.Parameter .== "instate_ces", :Value])
# penalty_rps_ces = first(other_info[other_info.Parameter .== "penalty_rps_ces", :Value])

# Adding recoded linear costs for new lines and upgraded lines
fipart_new = first(linesub_cost_new_ACDC[linesub_cost_new_ACDC.Voltages .== snew_AC_voltage, :Sub_fixed_cost]) ./
                            (first(voltage_cap[voltage_cap.Voltages .== snew_AC_voltage, :Capacity]) * network.distance_mile)

separt_new = (
                first(linesub_cost_new_ACDC[linesub_cost_new_ACDC.Voltages .== snew_AC_voltage, :Line_cost_per_mile]) +
                first(linesub_cost_new_ACDC[linesub_cost_new_ACDC.Voltages .== snew_AC_voltage, :Sub_fixed_cost]) / sub_distance_AC .+
                row_costs[:,snew_AC_voltage]
             ) /
                first(voltage_cap[voltage_cap.Voltages .== snew_AC_voltage, :Capacity])
# append!(separt_new, zeros(length(fipart_new) - length(separt_new)))

thpart_new = first(linesub_cost_new_ACDC[linesub_cost_new_ACDC.Voltages .== snew_AC_voltage, :Sub_cost_per_MW]) ./ network.distance_mile

fopart_new = first(linesub_cost_new_ACDC[linesub_cost_new_ACDC.Voltages .== snew_AC_voltage, :Sub_cost_per_MW]) / sub_distance_AC

network.RecodedNewLinear = (fipart_new + separt_new + thpart_new .+ fopart_new) .* network.distance_mile

fipart_upg = (row_costs[:,snew_AC_voltage] - row_costs[:,:TwoH_AC]) ./ first(voltage_cap[voltage_cap.Voltages .== snew_AC_voltage, :Capacity])
# append!(fipart_upg, zeros(length(thpart_new) - length(fipart_upg)))

network.RecodedUpgLinear = (fipart_upg + thpart_new .+ fopart_new) .* network.distance_mile

twofive_cap = (
first(voltage_cap[voltage_cap.Voltages .== snew_AC_voltage, :Capacity]) -
first(voltage_cap[voltage_cap.Voltages .== "TwoH_AC", :Capacity])
) .* voltage_count.TwoH_AC
# append!(twofive_cap, zeros(length(thpart_new) - length(twofive_cap)))

network.TwoFive_Cap = twofive_cap

reinforcement_to_fixed = first(other_info[other_info.Parameter .== "reinforcement_to_fixed", :Value])
if transcost_sens == "linear"
    network.Line_Fixed_Cost_per_MW_yr = network.Line_Reinforcement_Cost_per_MWyr / reinforcement_to_fixed # Assign fixed cost
else
    network.Line_Fixed_Cost_per_MW_yr = network.RecodedNewLinear / reinforcement_to_fixed # Assign fixed cost
end

##### Two-stage #####
if two_stage == true
    gencap_fixed = CSV.read(string(fixed_resultpath, "allcap.csv"), DataFrame)
    storenergycapnew_fixed = CSV.read(string(fixed_resultpath, "vCAPESTORNEW_results.csv"), DataFrame)
    storenergycapold_fixed = CSV.read(string(fixed_resultpath, "vRETESTOROLD_results.csv"), DataFrame)
    linecap_fixed = CSV.read(string(fixed_resultpath, "vCAPLINE_results.csv"), DataFrame)
end
#####################
