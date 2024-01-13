using CSV, DataFrames, Statistics

include("GenVarCalc.jl")

powergenome_input_path = "/Users/Kucuksayacigil/Desktop/WECC-data/extra_inputs/"
powergenome_output_path = "/Users/Kucuksayacigil/Desktop/PowerGenome_Output/2050/single_2050_A_single_scenario/Inputs/"
# powergenome_52week_path = "/Users/Kucuksayacigil/Dropbox/UCSD Postdoc/Data/52-week data/"

other_info = CSV.read(string(powergenome_input_path, "other_inputs.csv"), DataFrame)
network = CSV.read(string(powergenome_output_path, "Network.csv"), DataFrame)
genvar = CSV.read(string(powergenome_output_path, "Generators_variability.csv"), DataFrame)[:, 2:end]
generators = CSV.read(string(powergenome_output_path, "Generators_data.csv"), DataFrame)
fuels = CSV.read(string(powergenome_output_path, "Fuels_data.csv"), DataFrame) # Reading fuels data and create a data frame
duration_file = CSV.read(string(powergenome_input_path, "capacity_fom_storage_units.csv"), DataFrame)
solarpower_lim = CSV.read(string(powergenome_input_path, "solar_power_caplimit.csv"), DataFrame)
geothermal_lim = CSV.read(string(powergenome_input_path, "geothermal_caplimit.csv"), DataFrame)
npd_lim = CSV.read(string(powergenome_input_path, "nonpowered_caplimit.csv"), DataFrame)
demand = CSV.read(string(powergenome_output_path, "Load_data.csv"), DataFrame)
# genvar52 = CSV.read(string(powergenome_52week_path, "Generators_variability.csv"), DataFrame)[:, 2:end]
# demand52 = CSV.read(string(powergenome_52week_path, "Load_data.csv"), DataFrame)
pumped_lim = CSV.read(string(powergenome_input_path, "pumped_caplimit.csv"), DataFrame)
hydroencap = CSV.read(string(powergenome_input_path, "energycap_hydro.csv"), DataFrame)
hydroramp = CSV.read(string(powergenome_input_path, "hydro_ramp.csv"), DataFrame)
hydrominmax = CSV.read(string(powergenome_input_path, "hydro_minmax.csv"), DataFrame)
# distancesubs = CSV.read(string(powergenome_input_path, "distance_subs.csv"), DataFrame)
# old_voltages = CSV.read(string(powergenome_input_path, "voltages_lines.csv"), DataFrame)
# rightow_costs = CSV.read(string(powergenome_input_path, "row_costs_lines.csv"), DataFrame)
# newaccosts = CSV.read(string(powergenome_input_path, "costs_for_new_ac_lines.csv"), DataFrame)

# Region description and Transmission Path Name columns in Network.csv have spaces. So, I rename column names.
# I read the list of new transmission lines and append it to the existing list, according to selected transmission_scenario
# I also created Line_Fixed_Cost_per_MW_yr column in Network.csv.
# I updated transmission capacity between PNW and MT
# I also added voltage details and ROW costs to the list of existing transmission lines
# newnames = names(network)
# for (index, names) in enumerate(names(network))
#     if occursin("Region", names) == true && occursin("description", names) == true
#         newnames[index] = "Region_description"
#     # elseif occursin("Transmission", names) == true && occursin("Path", names) == true && occursin("Name", names) == true
#     #     newnames[index] = "Transmission_Path_Name"
#     else
#         nothing
#     end
# end
# rename!(network, newnames)

# Add voltage details to current transmission data set
# network.Count_TwoH_AC = old_voltages.Count_TwoH_AC
# network.Count_ThreeH_AC = old_voltages.Count_ThreeH_AC
# network.Count_FiveH_AC = old_voltages.Count_FiveH_AC
# network.Count_FiveH_DC = old_voltages.Count_FiveH_DC

# Add right of widhts costs to current transmission data set
# network.ROWCost_TwoH_AC_permile = rightow_costs.ROWCost_TwoH_AC_permile
# network.ROWCost_ThreeH_AC_permile = rightow_costs.ROWCost_ThreeH_AC_permile
# network.ROWCost_FiveH_AC_permile = rightow_costs.ROWCost_FiveH_AC_permile
# network.ROWCost_FiveH_DC_permile = rightow_costs.ROWCost_FiveH_DC_permile

# Add green field costs of new ac transmission lines
# network.Var_cost_per_mile_new_acline = newaccosts.Var_cost_per_mile_new_acline
# network.Var_cost_per_MW_new_acline = newaccosts.Var_cost_per_MW_new_acline
# network.Fixed_cost_new_acline = newaccosts.Fixed_cost_new_acline

# if transmission_scenario == "pessimistic"
#     addnetwork = addnetwork[addnetwork.Status .== "Very_likely", :]
# elseif transmission_scenario == "moderate"
#     addnetwork = addnetwork[(addnetwork.Status .== "Very_likely") .| (addnetwork.Status .== "Likely"), :]
# elseif transmission_scenario == "optimistic"
#     nothing
# end

# Update transmission line capacity between MT and PNW according to Colstrip upgrade project
# I found incremental capacity in Montana Renewables Development Action Plan
# You can find reference in your email

regdesc, netzones = [], []
for x in collect(1:length(unique(generators.region)))
    push!(regdesc, first(generators[generators.Zone .== x, :region]))
    push!(netzones, string("z", x))
end

reg_zone = DataFrame()
reg_zone.Region_description = regdesc
reg_zone.Network_zones = netzones

# reg_zone = select(network, ["Region_description", "Network_zones"])
# reg_zone = reg_zone[completecases(reg_zone), :]
mt_number = first(reg_zone[reg_zone.Region_description .== "MT", :Network_zones])
pnw_number = first(reg_zone[reg_zone.Region_description .== "PNW", :Network_zones])

mt_pnw_df = DataFrame()
mt_pnw_df.linenum = collect(1:length(network[:,mt_number]))
mt_pnw_df.mt = network[:,mt_number]
mt_pnw_df.pnw = network[:,pnw_number]
mtpnwnum = first(mt_pnw_df[((mt_pnw_df.mt .== 1) .& (mt_pnw_df.pnw .== -1)) .| ((mt_pnw_df.mt .== -1) .& (mt_pnw_df.pnw .== 1)), :linenum])
network[mtpnwnum, :Line_Max_Flow_MW] = network[mtpnwnum, :Line_Max_Flow_MW] + first(other_info[other_info.Parameter .== "colstrip", :Value])

network.Line_Reinforcement_Cost_per_MWyr = network.Line_Reinforcement_Cost_per_MWyr / first(other_info[other_info.Parameter .== "objscale", :Value])

# network.DistanceSubs = distancesubs.Distance_Between_Subs
CSV.write(string(powergenome_output_path, "Network.csv"), network)


# If number of weeks is 2, then remove one week from generator variability and replace it with average one
genvar = genvar .* 1.0 # Convert integer columns to float types
# region_names = collect(skipmissing(network.Region_description))
region_names = reg_zone.Region_description

# numweek = Int(first(demand.Rep_Periods))
hours_per_period = Int(first(demand.Timesteps_per_Rep_Period)) # Reading hours per period data
sample_weight = vcat(fill.(collect(skipmissing(demand.Sub_Weights)) / hours_per_period, hours_per_period)...)

# if numweek == 2
#     # Determine peak week and to-be-removed week in 2-week data set
#     load_names = Array{String, 1}(undef, length(region_names))
#     for regnum in 1:length(region_names)
#         load_names[regnum] = string("Load_MW_z", regnum)
#     end
#     load = select(demand, load_names)
#     peakweek = Int(ceil(findmax(sum.(eachrow(load)))[2] / hours_per_period))
#     if peakweek == 1 removedweek = 2 else removedweek = 1 end
#
#
#     numweek52 = Int(first(demand52.Subperiods))
#     hours_per_period_52 = Int(first(demand52.Hours_per_period))
#
#     # Find weekly average of capacity factor for 52 weeks
#     weekaver = DataFrame()
#     for (tstart, weeknum) in zip(1:hours_per_period_52:hours_per_period_52 * numweek52, 1:numweek52)
#         weekaver[!, string("W", weeknum)] = mean.(eachcol(genvar52[tstart:tstart+hours_per_period_52 - 1, :]))
#     end
#     insertcols!(weekaver, 1, "Resource" => names(genvar52))
#
#     # Filter this weekly average with just utilitypv and find average utilitypv capacity factor
#     technames = ["_utilitypv"]
#     allrow = Int64[]
#     for nnn in technames
#         for x in region_names
#             foundrow = findall(t -> occursin(string(x, nnn), t), weekaver.Resource)
#             removednum = Int64[]
#             for y in foundrow
#                 if x == "ID" && first(split(first(weekaver.Resource[y,:]), "_")) == "SD"
#                     push!(removednum, y)
#                 else
#                     nothing
#                 end
#             end
#             setdiff!(foundrow, removednum)
#             append!(allrow, foundrow)
#         end
#     end
#     utilityaver = mean.(eachrow(select(weekaver[allrow, :], Not(:Resource))))
#
#     # Determine when system-wide peak demand occurs and remove that week from the weekly average
#     load52 = select(demand52, load_names)
#     peakweek52 = Int(ceil(findmax(sum.(eachrow(load52)))[2] / hours_per_period_52))
#     remainingcol = String[]
#     push!(remainingcol, "Resource")
#     for x in 1:numweek52
#         push!(remainingcol, string("W", x))
#     end
#     filter!(x -> x != string("W", peakweek52), remainingcol)
#     select!(weekaver, remainingcol)
#
#     # Find weekly average capacity factor for utilitypv, except for the week which has peak demand and append overall average over 52 weeks as another column
#     utilitybrief = weekaver[allrow, :]
#     utilitybrief.Aver52 = utilityaver
#
#     # Find sum of absolute value and assign column names
#     finalresult = DataFrame()
#     finalresult.Diff = sum.(eachcol(abs.(select(utilitybrief, Not([:Resource, :Aver52])) .- utilitybrief.Aver52)))
#     finalresult.Weeks = names(select(utilitybrief, Not([:Resource, :Aver52])))
#
#     # Find minimum of these absolute values and determine weeks
#     week_close_average = parse(Int64, last(split(finalresult[findmin(finalresult.Diff)[2], :Weeks], "W")))
#
#     replacedtech = ["_onshore_wind", "_solar_photovoltaic", "_landbasedwind", "_utilitypv", "_offshorewind"]
#     replacedrow = Int64[]
#     for nnn in replacedtech
#         for x in region_names
#             foundrow = findall(t -> occursin(string(x, nnn), t), weekaver.Resource)
#             removednum = Int64[]
#             for y in foundrow
#                 if x == "ID" && first(split(first(weekaver.Resource[y,:]), "_")) == "SD"
#                     push!(removednum, y)
#                 else
#                     nothing
#                 end
#             end
#             setdiff!(foundrow, removednum)
#             append!(replacedrow, foundrow)
#         end
#     end
#     replaceddf = weekaver[replacedrow, :]
#
#     # Replace capacity factor
#     genvar[(removedweek - 1) * hours_per_period + 1:removedweek * hours_per_period, replaceddf.Resource] = genvar52[(week_close_average - 1) * hours_per_period_52 + 1:week_close_average * hours_per_period_52, replaceddf.Resource]
# else
#     nothing
# end

# Commercial pv and residential pv have variability of 1. So, I copied and pasted utility pv's variability into commercial and residential pv for each zone.
# I also did the same thing for new build hydropower
for regname in region_names
    # findall(t -> occursin("AZ_utility", t), names(genvar)) You can also use this
    referenceindex_1 = findfirst(t -> occursin(string(regname, "_utilitypv"), t), names(genvar))
    ftarget_1 = findfirst(t -> occursin(string(regname, "_commpv"), t), names(genvar))
    starget_1 = findfirst(t -> occursin(string(regname, "_respv"), t), names(genvar))

    referenceindex_2 = findfirst(t -> occursin(string(regname, "_small_hydroelectric"), t), names(genvar))
    ftarget_2 = findfirst(t -> occursin(string(regname, "_hydropower_npd4"), t), names(genvar))

    genvar[:, ftarget_1] = genvar[:, referenceindex_1]
    genvar[:, starget_1] = genvar[:, referenceindex_1]
    genvar[:, ftarget_2] = genvar[:, referenceindex_2]
end

for x in findall(t -> occursin("csp", t), names(genvar))
    genvar[:,x] = repeat(0.4:0.4, first(size(genvar)))
end

# I labeled new nuclear resources with 1 under New_Build column. PowerGenome has a problem in separating existing and new nuclear resources.
newnuclear = findall(t -> occursin(string("nuclear_"), t), generators.technology)
generators.New_Build[newnuclear] = repeat(1:1, length(newnuclear))

# I assigned MWh capacity values for existing storage and conventional hydro units. PowerGenome does not give this output
sbattery_old = generators[(generators.BATTERY .== 1) .& (generators.New_Build .== 0), :R_ID]
spumped_old = generators[(generators.PUMPED .== 1) .& (generators.New_Build .== -1), :R_ID]
stherstor = generators[(generators.THERMALSTOR .== 1) .& (generators.New_Build .== -1), :R_ID]

generators.Existing_Cap_MWh = repeat(0.0:0.0, first(size(generators)))
generators.Existing_Cap_MWh[sbattery_old] = generators.Existing_Cap_MW[sbattery_old] * first(duration_file[duration_file.Resource .== "Battery", :Average_durations_hours])
generators.Existing_Cap_MWh[spumped_old] = generators.Existing_Cap_MW[spumped_old] * first(duration_file[duration_file.Resource .== "Pumped_hydro", :Average_durations_hours])
generators.Existing_Cap_MWh[stherstor] = generators.Existing_Cap_MW[stherstor] * first(duration_file[duration_file.Resource .== "Thermal_storages", :Average_durations_hours])

for regnames in hydroencap.Regions
    row = first(generators[(generators.LHYDRO .== 1) .& (generators.New_Build .== 0) .& (generators.region .== regnames), :R_ID])
    generators.Existing_Cap_MWh[row] = first(hydroencap[hydroencap.Regions .== regnames, "MWh_cap"])
end

# I assigned fixed O&M per MW and per MWh costs for existing storage units (except solar thermal because I do not have data for it)
# generators.Fixed_OM_cost_per_MWyr[sbattery_old] = repeat(first(duration_file[duration_file.Resource .== "Battery", :FOM_Existing]):first(duration_file[duration_file.Resource .== "Battery", :FOM_Existing]), length(sbattery_old))
# generators.Fixed_OM_cost_per_MWyr[spumped_old] = repeat(first(duration_file[duration_file.Resource .== "Pumped_hydro", :FOM_Existing]):first(duration_file[duration_file.Resource .== "Pumped_hydro", :FOM_Existing]), length(spumped_old))
# generators.Fixed_OM_cost_per_MWhyr[sbattery_old] = repeat(first(duration_file[duration_file.Resource .== "Battery", :FOMh_Existing]):first(duration_file[duration_file.Resource .== "Battery", :FOMh_Existing]), length(sbattery_old))
# generators.Fixed_OM_cost_per_MWhyr[spumped_old] = repeat(first(duration_file[duration_file.Resource .== "Pumped_hydro", :FOMh_Existing]):first(duration_file[duration_file.Resource .== "Pumped_hydro", :FOMh_Existing]), length(spumped_old))

# I assigned investment cost per MW and per MWh for new build storage units (only for battery and pumped hydro)
sbattery_new = generators[(generators.BATTERY .== 1) .& (generators.New_Build .== 1), :R_ID]
spumped_new = generators[(generators.PUMPED .== 1) .& (generators.New_Build .== 1), :R_ID]

# generators.Inv_cost_per_MWyr[sbattery_new] = repeat(first(duration_file[duration_file.Resource .== "Battery", :INV_New]):first(duration_file[duration_file.Resource .== "Battery", :INV_New]), length(sbattery_new))
generators.Inv_Cost_per_MWyr[spumped_new] = repeat(first(duration_file[duration_file.Resource .== "Pumped_hydro", :INV_New]):first(duration_file[duration_file.Resource .== "Pumped_hydro", :INV_New]), length(spumped_new))
# generators.Inv_cost_per_MWhyr[sbattery_new] = repeat(first(duration_file[duration_file.Resource .== "Battery", :INVh_New]):first(duration_file[duration_file.Resource .== "Battery", :INVh_New]), length(sbattery_new))
generators.Inv_Cost_per_MWhyr[spumped_new] = repeat(first(duration_file[duration_file.Resource .== "Pumped_hydro", :INVh_New]):first(duration_file[duration_file.Resource .== "Pumped_hydro", :INVh_New]), length(spumped_new))

# I assigned fixed O&M per MW and per MWh costs for new build storage units (only for battery and pumped hydro)
generators.Fixed_OM_Cost_per_MWyr[sbattery_new] = repeat(first(duration_file[duration_file.Resource .== "Battery", :FOM_New]):first(duration_file[duration_file.Resource .== "Battery", :FOM_New]), length(sbattery_new))
# generators.Fixed_OM_cost_per_MWyr[spumped_new] = repeat(first(duration_file[duration_file.Resource .== "Pumped_hydro", :FOM_New]):first(duration_file[duration_file.Resource .== "Pumped_hydro", :FOM_New]), length(spumped_new))
generators.Fixed_OM_Cost_per_MWhyr[sbattery_new] = repeat(first(duration_file[duration_file.Resource .== "Battery", :FOMh_New]):first(duration_file[duration_file.Resource .== "Battery", :FOMh_New]), length(sbattery_new))
# generators.Fixed_OM_cost_per_MWhyr[spumped_new] = repeat(first(duration_file[duration_file.Resource .== "Pumped_hydro", :FOMh_New]):first(duration_file[duration_file.Resource .== "Pumped_hydro", :FOMh_New]), length(spumped_new))

# I changed Cap_size for new build pumped hydro to 0
generators.Cap_Size[spumped_new] = zeros(length(spumped_new))

# I assigned some values for Max_Cap_MW and num_units
# battery_caplimit = first(other_info[other_info.Parameter .== "battery_caplimit", :Value])
num_units = first(other_info[other_info.Parameter .== "num_units_for_UC", :Value]) * 1.0

# battery_rows = findall(t -> occursin(string("battery"), t), generators.Resource)
# generators.Max_Cap_MW[battery_rows] = repeat(battery_caplimit:battery_caplimit, length(battery_rows))

snewuc = generators[(generators.Commit .== 1) .& (generators.New_Build .== 1), :R_ID]
generators.num_units[snewuc] = repeat(num_units:num_units, length(snewuc))

# Create additional columns in generator data set for variable cost, co2 emissions, start cost, and co2 emissions per start
fuelnames = names(fuels)[2:end]
fuels = select(fuels, Not(:Time_Index))
fuels = DataFrame(Matrix(fuels[1:2, :])', :auto)

rename!(fuels, :x1 => :CO2_content_tons_per_MMBtu)
rename!(fuels, :x2 => :Cost_per_MMBtu)
insertcols!(fuels, 1, :Fuel => fuelnames)

generators.Var_Cost, generators.CO2_Rate, generators.Start_Cost, generators.CO2_Per_Start =
                                    zeros(first(size(generators))), zeros(first(size(generators))), zeros(first(size(generators))), zeros(first(size(generators)))
for g in 1:first(size(generators))
    generators.Var_Cost[g] = generators.Var_OM_Cost_per_MWh[g] + first(fuels[fuels.Fuel .== generators.Fuel[g], :Cost_per_MMBtu]) * generators.Heat_Rate_MMBTU_per_MWh[g]
    generators.CO2_Rate[g] = first(fuels[fuels.Fuel .== generators.Fuel[g], :CO2_content_tons_per_MMBtu]) * generators.Heat_Rate_MMBTU_per_MWh[g]
    generators.Start_Cost[g] = generators.Start_Cost_per_MW[g] + first(fuels[fuels.Fuel .== generators.Fuel[g], :Cost_per_MMBtu]) * generators.Start_Fuel_MMBTU_per_MW[g]
    generators.CO2_Per_Start[g] = first(fuels[fuels.Fuel .== generators.Fuel[g], :CO2_content_tons_per_MMBtu]) * generators.Start_Fuel_MMBTU_per_MW[g]
end

# Make min_power for existing storage units 0
sstor = generators[(generators.STOR .== 1) .& ((generators.New_Build .== 0) .| (generators.New_Build .== -1)), :R_ID]
generators.Min_Power[sstor] = zeros(length(sstor))

generators[(generators.region .== "NM") .& (generators.technology .== "natural_gas_steam_turbine"), :Min_Power] = generators[(generators.region .== "AZ") .& (generators.technology .== "natural_gas_fired_combined_cycle"), :Min_Power]
generators[(generators.region .== "UT") .& (generators.technology .== "natural_gas_fired_combined_cycle"), :Min_Power] = generators[(generators.region .== "AZ") .& (generators.technology .== "natural_gas_fired_combined_cycle"), :Min_Power]

# I made fixed O&M cost of pumped storage $15,900, which was given by Mongird et al 2019
# pumped_fom = first(other_info[other_info.Parameter .== "pumped_fom", :Value])
# pumped_rows = findall(t -> occursin(string("pumped_"), t), generators.Resource)
# generators.Fixed_OM_cost_per_MWyr[pumped_rows] = repeat(pumped_fom:pumped_fom, length(pumped_rows))

# I added numbers in Max_Cap_MW column for respv, commpv, and csp (for reference, look at leading studies worksheet)
# While preparing data, I used Lopez et al 2012. Rooftop solar given in this table is divided by 2 to assing numbers for respv and commpv
# For CA, I divided rooftop solar by 6 to assing numbers for respv and commpv for three regions in CA.
# For PNW, I found total of Oregon and Washington.
solar_list = ["respv", "commpv", "csp"]
for regnames in region_names
    for sname in solar_list
        first_df = generators[generators.region .== regnames, :]
        row = first(findall(t -> occursin(sname, t), first_df.technology))
        rid = first_df[row, :R_ID]
        generators.Max_Cap_MW[rid] = first(solarpower_lim[solarpower_lim.Regions .== regnames, sname])
    end
end

# I added numbers in Max_Cap_MW column for geothermal (for reference, look at leading studies worksheet)
# While preparing data, I used Western Flexibility Assessment
# For CA, I divided given number by 3.
for regnames in geothermal_lim.Regions
    first_df = generators[generators.region .== regnames, :]
    row = first(findall(t -> occursin("hydroflash", t), first_df.technology))
    rid = first_df[row, :R_ID]
    generators.Max_Cap_MW[rid] = first(geothermal_lim[geothermal_lim.Regions .== regnames, "geothermal"])
end

# I added numbers in Max_Cap_MW column for non-powered hydro units (reference is Hadjerioua et al 2012)
for regnames in npd_lim.Regions
    first_df = generators[generators.region .== regnames, :]
    row = first(findall(t -> occursin("hydropower_npd", t), first_df.technology))
    rid = first_df[row, :R_ID]
    generators.Max_Cap_MW[rid] = first(npd_lim[npd_lim.Regions .== regnames, "non_powered"])
end

# I added numbers in Max_Cap_MW column for pumped hydro units (reference is Western Flexibility Assessment)
for regnames in pumped_lim.Regions
    first_df = generators[generators.region .== regnames, :]
    row = first(findall(t -> occursin("newpumped", t), first_df.technology))
    rid = first_df[row, :R_ID]
    generators.Max_Cap_MW[rid] = first(pumped_lim[pumped_lim.Regions .== regnames, "pumped"])
end

# I assigned ramp rates for conventional hydro units
# for regnames in hydroramp.Regions
#     row = first(generators[(generators.LHYDRO .== 1) .& (generators.New_Build .== 0) .& (generators.region .== regnames), :R_ID])
#     generators.Ramp_Up_percentage[row] = first(hydroramp[hydroramp.Regions .== regnames, "RampUp"])
#     generators.Ramp_Dn_percentage[row] = first(hydroramp[hydroramp.Regions .== regnames, "RampDown"])
# end
existing_hydro = generators[(generators.LHYDRO .== 1) .& (generators.New_Build .== 0), :R_ID]
for row in existing_hydro
    generators.Ramp_Up_Percentage[row] = first(hydroramp[hydroramp.Regions .== generators.region[row], "RampUp"])
    generators.Ramp_Dn_Percentage[row] = first(hydroramp[hydroramp.Regions .== generators.region[row], "RampDown"])
end
newbuild_hydro = generators[(generators.LHYDRO .== 1) .& (generators.New_Build .== 1), :R_ID]
for row in newbuild_hydro
    generators.Ramp_Up_Percentage[row] = first(hydroramp[hydroramp.Regions .== generators.region[row], "RampUp"])
    generators.Ramp_Dn_Percentage[row] = first(hydroramp[hydroramp.Regions .== generators.region[row], "RampDown"])
end

# I created two columns for min and max power functional relationships for hydro units
generators.MinInter = repeat(0.0:0.0, first(size(generators)))
generators.MinCoef = repeat(0.0:0.0, first(size(generators)))
# generators.MinExpo = repeat(0.0:0.0, first(size(generators)))
generators.MaxInter = repeat(0.0:0.0, first(size(generators)))
generators.MaxCoef = repeat(0.0:0.0, first(size(generators)))
# generators.MaxExpo = repeat(0.0:0.0, first(size(generators)))
# generators.MinType = repeat(["none"], first(size(generators)))
# generators.MaxType = repeat(["none"], first(size(generators)))

# for regnames in hydrominmax.Regions
#     row = first(generators[(generators.LHYDRO .== 1) .& (generators.New_Build .== 0) .& (generators.region .== regnames), :R_ID])
#     generators.MinInter[row] = first(hydrominmax[hydrominmax.Regions .== regnames, "Min_Inter"])
#     generators.MinCoef[row] = first(hydrominmax[hydrominmax.Regions .== regnames, "Min_Coef"])
#     generators.MaxInter[row] = first(hydrominmax[hydrominmax.Regions .== regnames, "Max_Inter"])
#     generators.MaxCoef[row] = first(hydrominmax[hydrominmax.Regions .== regnames, "Max_Coef"])
# end
for row in existing_hydro
    generators.MinInter[row] = first(hydrominmax[hydrominmax.Regions .== generators.region[row], "Min_Inter"])
    generators.MinCoef[row] = first(hydrominmax[hydrominmax.Regions .== generators.region[row], "Min_Coef"])
    generators.MaxInter[row] = first(hydrominmax[hydrominmax.Regions .== generators.region[row], "Max_Inter"])
    generators.MaxCoef[row] = first(hydrominmax[hydrominmax.Regions .== generators.region[row], "Max_Coef"])
    # generators.MinCoef[row] = first(hydrominmax[hydrominmax.Regions .== generators.region[row], "MinCoef"])
    # generators.MinExpo[row] = first(hydrominmax[hydrominmax.Regions .== generators.region[row], "MinExpo"])
    # generators.MaxCoef[row] = first(hydrominmax[hydrominmax.Regions .== generators.region[row], "MaxCoef"])
    # generators.MaxExpo[row] = first(hydrominmax[hydrominmax.Regions .== generators.region[row], "MaxExpo"])
    # generators.MinType[row] = first(hydrominmax[hydrominmax.Regions .== generators.region[row], "MinType"])
    # generators.MaxType[row] = first(hydrominmax[hydrominmax.Regions .== generators.region[row], "MaxType"])
end
for row in newbuild_hydro
    generators.MinInter[row] = first(hydrominmax[hydrominmax.Regions .== generators.region[row], "Min_Inter"])
    generators.MinCoef[row] = first(hydrominmax[hydrominmax.Regions .== generators.region[row], "Min_Coef"])
    generators.MaxInter[row] = first(hydrominmax[hydrominmax.Regions .== generators.region[row], "Max_Inter"])
    generators.MaxCoef[row] = first(hydrominmax[hydrominmax.Regions .== generators.region[row], "Max_Coef"])
    # generators.MinCoef[row] = first(hydrominmax[hydrominmax.Regions .== generators.region[row], "MinCoef"])
    # generators.MinExpo[row] = first(hydrominmax[hydrominmax.Regions .== generators.region[row], "MinExpo"])
    # generators.MaxCoef[row] = first(hydrominmax[hydrominmax.Regions .== generators.region[row], "MaxCoef"])
    # generators.MaxExpo[row] = first(hydrominmax[hydrominmax.Regions .== generators.region[row], "MaxExpo"])
    # generators.MinType[row] = first(hydrominmax[hydrominmax.Regions .== generators.region[row], "MinType"])
    # generators.MaxType[row] = first(hydrominmax[hydrominmax.Regions .== generators.region[row], "MaxType"])
end

# I made investment cost for coal_ccs90highCF as equal to that of coal_ccs90avgcf
# generators[generators.Resource .== "coal_ccs90highcf_mid", :Inv_cost_per_MWyr] = generators[generators.Resource .== "coal_ccs90avgcf_mid", :Inv_cost_per_MWyr]

# I adjusted renewable clusters for offshore wind, land based wind, and utility pv
mincap = first(other_info[other_info.Parameter .== "min_capacity_for_clusters", :Value])
minvar_solar = first(other_info[other_info.Parameter .== "min_var_solar", :Value])
minvar_wind = first(other_info[other_info.Parameter .== "min_var_wind", :Value])
mintotcap_solar = first(other_info[other_info.Parameter .== "cap_for_solar", :Value])
mintotcap_wind = first(other_info[other_info.Parameter .== "cap_for_wind", :Value])
maxclus = first(other_info[other_info.Parameter .== "num_clusters_for_clusters", :Value])

offres, landres, utilres = GenVar()

rows_removed = Int64[]
for fileres in [offres, landres, utilres]

    if fileres == offres
        name = "offshorewind"
        minvar_ind = minvar_wind
        mintotcap_ind = mintotcap_wind
    elseif fileres == landres
        name = "landbasedwind"
        minvar_ind = minvar_wind
        mintotcap_ind = mintotcap_wind
    elseif fileres == utilres
        name = "utilitypv"
        minvar_ind = minvar_solar
        mintotcap_ind = mintotcap_solar
    else
        nothing
    end

    rowsin = findall(t -> occursin(name, t), generators.technology)
    generators_sub = generators[rowsin, :]
    fileres.MaxCap = generators.Max_Cap_MW[rowsin]
    fileres.Region = generators.region[rowsin]
    # filter!(row -> !(row.MaxCap <= mincap), fileres)
    first_removed = generators_sub[findall(generators_sub.Max_Cap_MW .<= mincap), :R_ID]
    append!(rows_removed, first_removed)

    for regnames in region_names
        first_df = fileres[fileres.Region .== regnames, :]
        sort!(first_df, :GenVar, rev = true)

        sumcap = 0
        cutoff = 0
        for (row_index, row) in enumerate(eachrow(first_df))

            if row.GenVar >= minvar_ind
                sumcap = sumcap + row.MaxCap
                cutoff = first(size(first_df))
            else
                cutoff = row_index
                break
            end

            if sumcap >= mintotcap_ind
                cutoff = row_index
                break
            else
                cutoff = first(size(first_df))
            end

            if row_index > maxclus
                cutoff = row_index
                break
            else
                cutoff = first(size(first_df))
            end
        end

        for row in cutoff+1:first(size(first_df))
            area = first_df[row, :Region]
            cluster = parse(Int64, last(split(first_df[row, :Zones], "_")))

            push!(rows_removed, first(generators_sub[(generators_sub.region .== area) .& (generators_sub.cluster .== cluster), :R_ID]))
        end
    end
end

sort!(rows_removed)
unique!(rows_removed)
delete!(generators, rows_removed)
select!(genvar, Not(rows_removed))

generators.R_ID = collect(1:first(size(generators)))

rows_removed_biomass = generators[(generators.technology .== "biomass") .& (generators.Existing_Cap_MW .< first(other_info[other_info.Parameter .== "biomass_threshold", :Value])), :R_ID]
delete!(generators, rows_removed_biomass)
select!(genvar, Not(rows_removed_biomass))

generators.R_ID = collect(1:first(size(generators)))

generators.Inv_Cost_per_MWyr = generators.Inv_Cost_per_MWyr / first(other_info[other_info.Parameter .== "objscale", :Value])
generators.Inv_Cost_per_MWhyr = generators.Inv_Cost_per_MWhyr / first(other_info[other_info.Parameter .== "objscale", :Value])
generators.Fixed_OM_Cost_per_MWyr = generators.Fixed_OM_Cost_per_MWyr / first(other_info[other_info.Parameter .== "objscale", :Value])
generators.Fixed_OM_Cost_per_MWhyr = generators.Fixed_OM_Cost_per_MWhyr / first(other_info[other_info.Parameter .== "objscale", :Value])
generators.Var_Cost = generators.Var_Cost / first(other_info[other_info.Parameter .== "objscale", :Value])
generators.Start_Cost = generators.Start_Cost / first(other_info[other_info.Parameter .== "objscale", :Value])

CSV.write(string(powergenome_output_path, "Generators_data.csv"), generators)

genvar .= ifelse.(genvar .<= 0.01, 0.0, genvar) # Changing all values in capacity factor less than 0.01 to 0.0

CSV.write(string(powergenome_output_path, "Generators_variability.csv"), genvar)

demand.Voll[1] = demand.Voll[1] / first(other_info[other_info.Parameter .== "objscale", :Value])
demand[1:2, Symbol("\$/MWh")] = demand[1:2, Symbol("\$/MWh")] / first(other_info[other_info.Parameter .== "objscale", :Value])

CSV.write(string(powergenome_output_path, "Load_data.csv"), demand)
