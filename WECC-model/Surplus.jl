# datapath = "/Users/Kucuksayacigil/Dropbox/UCSD Postdoc/Code/courserepo/Project/wecc_2045_all_clean_expansion/reference_electrification_16_weeks/"

# select!(generators, Not([:capex, :capex_mwh, :heat_rate_mmbtu_mwh_iqr, :heat_rate_mmbtu_mwh_std]))
# show(generators, allrows = true, allcols = true)
# columns names of a data frame, names(dataframe). If you want to see each element print(names(dataframe))

# VOLL = demand.Voll[1]
# demand.Representative_Periods[1] = smallperiods

# hourtobeadded = floor((52*7*24 - sum(demand.Representative_Period_Weight[1:smallperiods])) / smallperiods)

# sample_weight = vcat(fill.(collect(skipmissing(demand.Representative_Period_Weight)) / hours_per_period, hours_per_period)...)

# lines = select(network, Not([:Transmission_Path_Name, :Distance_mile, :Investment_cost_MW]))

# setZONE = unique(generators.Zone)
# setOLDLINE = collect(1:10)  # Set of existing transmission lines
# setP = collect(1:demand.Representative_Periods[1])
# setW = collect(skipmissing(demand.Representative_Period_Weight))
# setVRE = generators[generators.VRE .== 1, :R_ID]
# setRPS = generators[generators.RPS .== 1, :R_ID]

# for g in setUCSTABLEGEN fix(vNUMUCSTABLE[g], generators.Num_Units[g], force = true) end

# @constraint(Expansion_Model, cCapUcOld[g in setUCOLDGEN], vCAPGEN[g] == generators.Cap_size[g] * (generators.Num_Units[g] - vNUMUCOLD[g]))

# @constraint(Expansion_Model, cMaxCap_NONUC[g in union(setEDNEWGEN, setSTORNEW)], vCAPGEN[g] <= generators.Num_Units[g] * generators.Cap_size[g])

# @constraint(Expansion_Model, cMaxCap_UC[g in setUCNEWGEN], vNUMUCNEW[g] <= generators.Num_Units[g])

# @constraint(Expansion_Model, cMaxNSE[z in setZONE, s in setSEGMENT, t in setTIME], vNSE[z,s,t] <= nse.NSE_Max[s] * load[t,z])

# @constraint(Expansion_Model, cSOC[g in setSTOR, t in setINTERIORS], vSOC[g,t] == vSOC[g,t-1] + generators.Charge_efficiency[g] * vCHARGE[g,t] - vGENDISPATCH[g,t] / generators.Discharge_efficiency[g])
# @constraint(Expansion_Model, cSOCWrap[g in setSTOR, t in setSTARTS], vSOC[g,t] == vSOC[g,t + hours_per_period - 1] + generators.Charge_efficiency[g] * vCHARGE[g,t] - vGENDISPATCH[g,t] / generators.Discharge_efficiency[g])

# @constraint(Expansion_Model, cCommitMax_Old[g in setUCOLDGEN, t in setTIME], vCOMMIT[g,t] <= generators.Num_Units[g] - vNUMUCOLD[g])

# @constraint(Expansion_Model, cStartCap_Old[g in setUCOLDGEN, t in setTIME], vSTARTUC[g,t] <= generators.Num_Units[g] - vNUMUCOLD[g])

# @constraint(Expansion_Model, cShutCap_Old[g in setUCOLDGEN, t in setTIME], vSHUTUC[g,t] <= generators.Num_Units[g] - vNUMUCOLD[g])

# @constraint(Expansion_Model, cRetireCap[g in setUCOLDGEN], vNUMUCOLD[g] <= generators.Num_Units[g])

# @constraint(Expansion_Model, cComShut_Old[g in setUCOLDGEN, t in setdiff(setTIME, 1:maximum(generators.Down_time[setUCOLDGEN]))],
#                                 generators.Num_Units[g] - vNUMUCOLD[g] - vCOMMIT[g,t] >= sum(vSHUTUC[g,tt] for tt in Array(t-generators.Down_time[g]:t)))

# Demand balance constraint
# @constraint(Expansion_Model, cDemandBalance[t in setTIME, z in setZONE],
#         sum(vGENDISPATCH[g,t] for g in generators[generators.Zone .== z, :R_ID]) +
#         sum(vNSE[z,s,t] for s in setSEGMENT) -
#         sum(vCHARGE[g,t] for g in intersect(generators[generators.Zone .== z, :R_ID], setSTOR)) -
#         load[t,z] -
#         sum(lines[l, Symbol(string("z",z))] * vFLOW[l,t] for l in setLINE) == 0
# )

# @expression(Expansion_Model, eNSECosts,
#     sum(sample_weight[t] * nse.NSE_Cost[s] * vNSE[z,s,t] for z in setZONE, s in setSEGMENT, t in setTIME)
# )

# subplot(211)
# b = bar(x,y,color="#0f87bf",align="center",alpha=0.4)
#
# subplot(212)
# b = barh(x,y,color="#0f87bf",align="center",alpha=0.4)
#
# PyPlot.suptitle("Bar Plot Examples")

# smallperiods = 1 # Number of initial weeks to sample from data set (Running 10 weeks is too long, we wanted to run optimization with
                 # just a few weeks to get the results and to detect anomalies in the code)


 # demand = demand[1:smallperiods*Int(first(demand.Hours_per_period)),:] # Get the slice of demand time series corresponding to smallperiods defined above
 # demand.Subperiods[1] = smallperiods # Update the number of periods you are using (ex: Change from 10 weeks to 1 week)

 # # Update Representative_Period_Index column in demand data set corresponding to smallperiods defined above
 # fpartindex = collect(1:smallperiods)
 # spartindex = missings(size(demand)[1] - smallperiods)
 # demand.Representative_Period_Index = vcat(fpartindex, spartindex)

 # Update Representative_Period_Weight column in demand data set corresponding to smallperiods defined above
 # If original demand data set has 10 weeks, then there are 10 weights. If you want to use only 2 weeks,
 # you have to distribute weights of 8 weeks to weight of 2 weeks so that total weight is 8760.
 # hourtobeadded = floor((52*7*24 - sum(demand.Sub_Weights[1:smallperiods])) / smallperiods)
 # newweight = demand.Sub_Weights[1:smallperiods] .+ hourtobeadded
 # if sum(newweight) == 52*7*24
 #     nothing
 # elseif sum(newweight) > 52*7*24
 #     print("Hoops, there is a problem")
 # else
 #     newweight[length(newweight)] = 52*7*24 - sum(newweight)
 # end
 # spartweight = missings(size(demand)[1] - smallperiods)
 # demand.Representative_Period_Weight = vcat(newweight, spartweight)

 # load = select(demand, :Load_MW_z1, :Load_MW_z2, :Load_MW_z3, :Load_MW_z4, :Load_MW_z5, :Load_MW_z6,
 #                       :Load_MW_z7, :Load_MW_z8, :Load_MW_z9, :Load_MW_z10, :Load_MW_z11, :Load_MW_z12)

 # genvar = genvar[1:smallperiods*Int(first(demand.Hours_per_period)),:] # Get the slice of generator variability data corresponding to smallperiods defined above

 # lines = select(network, Not([:Network_zones, :DistrZones, :CES])) # Get a clearer version of network data
 # lines.Line_Fixed_Cost_per_MW_yr = lines.Line_Reinforcement_Cost_per_MW_yr / 20 # Assign fixed cost

 # solargen, biopowergen, coalgen, geogen, windgen, naturalgen, hydrogen, nucleargen = Int64[], Int64[], Int64[], Int64[], Int64[], Int64[], Int64[], Int64[]
 # for row in 1:first(size(generators))
 #    if occursin("csp", generators.Resource[row]) == true || occursin("commpv", generators.Resource[row]) == true || occursin("respv", generators.Resource[row]) == true ||
 #       occursin("solar_pho", generators.Resource[row]) == true || occursin("solar_thermal_without", generators.Resource[row]) == true || occursin("utilitypv", generators.Resource[row]) == true
 #       push!(solargen, generators.R_ID[row])
 #    elseif occursin("biomass", generators.Resource[row]) == true || occursin("biopower", generators.Resource[row]) == true
 #       push!(biopowergen, generators.R_ID[row])
 #    elseif occursin("coal", generators.Resource[row]) == true
 #       push!(coalgen, generators.R_ID[row])
 #    elseif occursin("geothermal", generators.Resource[row]) == true
 #       push!(geogen, generators.R_ID[row])
 #    elseif occursin("wind", generators.Resource[row]) == true
 #       push!(windgen, generators.R_ID[row])
 #    elseif occursin("natural", generators.Resource[row]) == true
 #       push!(naturalgen, generators.R_ID[row])
 #    elseif occursin("conventional_hydroelectric", generators.Resource[row]) == true || occursin("small_hydroelectric", generators.Resource[row]) == true
 #       push!(hydrogen, generators.R_ID[row])
 #    elseif occursin("nuclear", generators.Resource[row]) == true
 #       push!(nucleargen, generators.R_ID[row])
 #    else
 #       nothing
 #    end
 # end

 # csp + commpv + respv + utilitypv = solar_california = 4493
 # battery = storage_california = 2982
 # biopower = biopower_california = 1326 + biopowerccs_california = 0
 # coal = coal_california = 490 + coalccs_california = 33
 # geothermal = geothermal_california = 1514
 # landbased + offshore = wind_california = 7675
 # naturalgas + naturalgas + naturalgas = gas_california = 41981 + gasccs_california = 0
 # hydropower = hydro_california = 9890
 # nuclear = nuclear_california = 2323

 # newgen = generators[generators.New_Build .== 1, :R_ID]
 # weccgen = generators[(generators.region .== "AZ") .| (generators.region .== "CO") .| (generators.region .== "ID") .| (generators.region .== "MT") .|
 #                      (generators.region .== "NM") .| (generators.region .== "NV") .| (generators.region .== "PNW") .| (generators.region .== "UT") .|
 #                      (generators.region .== "WY"), :R_ID]
 # calgen = generators[(generators.region .== "NorCal") .| (generators.region .== "SoCal") .| (generators.region .== "SD_IID"), :R_ID]
 #
 # weccnewgen = intersect(newgen, weccgen)
 # calnewgen = intersect(newgen, calgen)
 #
 # storgen = setSTOR
 # solargen =  generators[generators.SOLAR .== 1, :R_ID]
 # biopowergen = generators[generators.BIOPOWER .== 1, :R_ID]
 # coalgen = generators[generators.COAL .== 1, :R_ID]
 # geogen = generators[generators.GEOTHERMAL .== 1, :R_ID]
 # windgen = generators[generators.WIND .== 1, :R_ID]
 # naturalgen = generators[generators.NATURAL .== 1, :R_ID]
 # hydrogen = generators[generators.HYDRO .== 1, :R_ID]
 # nucleargen = generators[generators.NUCLEAR .== 1, :R_ID]
 #
 # resourcelist = [solargen, storgen, biopowergen, coalgen, geogen, windgen, naturalgen, hydrogen, nucleargen]
 # wecccaplist = [solar_restwecc, storage_restwecc, biopower_restwecc + biopowerccs_restwecc, coal_restwecc + coalccs_restwecc, geothermal_restwecc,
 #                wind_restwecc, gas_restwecc + gasccs_restwecc, hydro_restwecc, nuclear_restwecc]
 # californiacaplist = [solar_california, storage_california, biopower_california + biopowerccs_california, coal_california + coalccs_california, geothermal_california,
 #                      wind_california, gas_california + gasccs_california, hydro_california, nuclear_california]
 #
 # for (resname, capname) in zip(resourcelist, wecccaplist)
 #    newres = intersect(weccnewgen, resname)
 #    newnumunit = ceil(capname / sum(generators.Cap_size[newres]))
 #    generators.num_units[newres] = repeat([newnumunit], length(newres))
 # end
 #
 # for (resname, capname) in zip(resourcelist, californiacaplist)
 #    newres = intersect(calnewgen, resname)
 #    newnumunit = ceil(capname / sum(generators.Cap_size[newres]))
 #    generators.num_units[newres] = repeat([newnumunit], length(newres))
 # end

 # coal_california = 490
 # gas_california = 41981
 # geothermal_california = 1514
 # solar_california = 4493
 # wind_california = 7675
 # biopower_california = 1326
 # hydro_california = 9890
 # nuclear_california = 2323
 # coalccs_california = 33
 # gasccs_california = 0
 # biopowerccs_california = 0
 # storage_california = 2982
 #
 # coal_restwecc = 5174
 # gas_restwecc = 70217
 # geothermal_restwecc = 3792
 # solar_restwecc = 11999
 # wind_restwecc = 33653
 # biopower_restwecc = 1276
 # hydro_restwecc = 52807
 # nuclear_restwecc = 5409
 # coalccs_restwecc = 0
 # gasccs_restwecc = 0
 # biopowerccs_restwecc = 0
 # storage_restwecc = 1170

 # @constraint(Expansion_Model, cMinPower_HYDRO_1[g in setdiff(setLHYDRO, mintypeexpo), t in setTIME], vGENDISPATCH[g,t] >= (generators.MinCoef[g] * genvar[t,g]^generators.MinExpo[g]) * vCAPGEN[g])
 # @constraint(Expansion_Model, cMinPower_HYDRO_2[g in intersect(setLHYDRO, mintypeexpo), t in setTIME], vGENDISPATCH[g,t] >= (generators.MinCoef[g] * exp(genvar[t,g] * generators.MinExpo[g])) * vCAPGEN[g])
 # @constraint(Expansion_Model, cResDownDisp_2[g in setdiff(setLHYDRO, mintypeexpo), t in setTIME], vRESDOWN[g,t] <= vGENDISPATCH[g,t] - (generators.MinCoef[g] * genvar[t,g]^generators.MinExpo[g]) * vCAPGEN[g])
 # @constraint(Expansion_Model, cResDownDisp_3[g in intersect(setLHYDRO, mintypeexpo), t in setTIME], vRESDOWN[g,t] <= vGENDISPATCH[g,t] - (generators.MinCoef[g] * exp(genvar[t,g] * generators.MinExpo[g])) * vCAPGEN[g])
 # @constraint(Expansion_Model, cMaxPower_HYDRO_1[g in setdiff(setLHYDRO, maxtypeexpo), t in setTIME], vGENDISPATCH[g,t] <= (generators.MaxCoef[g] * genvar[t,g]^generators.MaxExpo[g]) * vCAPGEN[g])
 # @constraint(Expansion_Model, cMaxPower_HYDRO_2[g in intersect(setLHYDRO, maxtypeexpo), t in setTIME], vGENDISPATCH[g,t] <= (generators.MaxCoef[g] * exp(genvar[t,g] * generators.MaxExpo[g])) * vCAPGEN[g])
 # @constraint(Expansion_Model, cResUpDisp_2[g in setdiff(setLHYDRO, maxtypeexpo), t in setTIME], vRESUP[g,t] <= (generators.MaxCoef[g] * genvar[t,g]^generators.MaxExpo[g]) * vCAPGEN[g] - vGENDISPATCH[g,t])
 # @constraint(Expansion_Model, cResUpDisp_4[g in intersect(setLHYDRO, maxtypeexpo), t in setTIME], vRESUP[g,t] <= (generators.MaxCoef[g] * exp(genvar[t,g] * generators.MaxExpo[g])) * vCAPGEN[g] - vGENDISPATCH[g,t])

 # @constraint(Expansion_Model, cContNew_2[g in setUCNEWGEN], vUCBIN[g] => {vNUMUCNEW[g] >= 1})
 # @constraint(Expansion_Model, cContNew_3[g in setUCNEWGEN], !vUCBIN[g] => {vNUMUCNEW[g] == 0})
 # @constraint(Expansion_Model, cContOld_2[g in setUCOLDGEN], vUCBIN[g] => {generators.num_units[g] - vNUMUCOLD[g] >= 1})
 # @constraint(Expansion_Model, cContOld_3[g in setUCOLDGEN], !vUCBIN[g] => {generators.num_units[g] - vNUMUCOLD[g] == 0})

 # @objective(Expansion_Model, Min, eFixCostGen + eFixCostStor + eFixCostLine + eNewACCost + eNewDCCost +
 #                             eACtoACUpgradeCost + eACtoDCUpgradeCost_1 + eACtoDCUpgradeCost_2 + eVarCostGen + eNSECosts + eStartCostUC +
 #                             eNoncompliance_RPS + eNoncompliance_CES + eTransactionCost) # Define the objective function

 # @objective(Expansion_Model, Min, eFixCostGen + eFixCostStor + eFixCostLine + eNewACCost + eNewDCCost +
 #                                 eACtoACUpgradeCost + eACtoDCUpgradeCost_1 + eACtoDCUpgradeCost_2 + eVarCostGen + eNSECosts + eStartCostUC +
 #                                 eNoncompliance_RPS + eNoncompliance_CES) # Define the objective function
