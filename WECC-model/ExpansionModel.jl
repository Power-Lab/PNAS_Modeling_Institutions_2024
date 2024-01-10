
function ExpansionModel()

    @timeit to "build_model" begin
        # Initiate optimization model with desired MIP gap, the number of threads to be used, and time limit
        # Expansion_Model =  Model(optimizer_with_attributes(Gurobi.Optimizer, "MIPGap" => 0.01, "Threads" => 16, "TimeLimit" => 32400))
        # Expansion_Model =  Model(optimizer_with_attributes(Gurobi.Optimizer, "MIPGap" => 0.01, "TimeLimit" => 108000, "Method" => 2))
        Expansion_Model =  Model(optimizer_with_attributes(Gurobi.Optimizer))
        # Expansion_Model =  Model(optimizer_with_attributes(CPLEX.Optimizer, "CPX_PARAM_EPGAP" => 0.01, "CPX_PARAM_TILIM" => 18000, "CPX_PARAM_STARTALG" => 4))

        for paramrow in eachrow(solver_params)
            if paramrow.Type == "Integer"
                set_optimizer_attribute(Expansion_Model, paramrow.Parameter, Int(paramrow.Value))
            else
                set_optimizer_attribute(Expansion_Model, paramrow.Parameter, paramrow.Value)
            end
        end

        # VARIABLES
        # Capacity variables
        @variable(Expansion_Model, vCAPEDNEW[setEDNEWGEN]             >= 0) # Capacity decision of new build economic dispatch generators
        @variable(Expansion_Model, vRETEDOLD[setEDOLDGEN]             >= 0) # Retirement decision of existing economic dispatch generators
        @variable(Expansion_Model, vCAPEDSTABLE[setEDSTABLEGEN]       >= 0) # Capacity decision of existing economic dispatch generators (this is actually constant)

        # @variable(Expansion_Model, vCAPHYDRONEW[setLHYDRONEW]         >= 0) # Capacity decision of new build hydro units
        # @variable(Expansion_Model, vRETHYDROOLD[setLHYDROOLD]         >= 0) # Retirement decision of existing hydro units
        # @variable(Expansion_Model, vCAPHYDROSTABLE[setLHYDROSTABLE]   >= 0) # Capacity decision of existing hydro units (this is actually constant)

        # @variable(Expansion_Model, vCAPSTORNEW[setSTORNEW]            >= 0) # Capacity decision of new build storages
        # @variable(Expansion_Model, vRETSTOROLD[setSTOROLD]            >= 0) # Retirement decision of existing storages
        # @variable(Expansion_Model, vCAPSTORSTABLE[setSTORSTABLE]      >= 0) # Capacity decision of existing storages (this is actually constant))
        @variable(Expansion_Model, vCAPSTORNEW[union(setSTORNEW,setLHYDRONEW)]            >= 0) # Capacity decision of new build storages
        @variable(Expansion_Model, vRETSTOROLD[union(setSTOROLD,setLHYDROOLD)]            >= 0) # Retirement decision of existing storages
        @variable(Expansion_Model, vCAPSTORSTABLE[union(setSTORSTABLE,setLHYDROSTABLE)]   >= 0) # Capacity decision of existing storages (this is actually constant))
        # @variable(Expansion_Model, vCAPESTORNEW[setSTORNEW]           >= 0) # Energy capacity of new build storages
        # @variable(Expansion_Model, vRETESTOROLD[setSTOROLD]           >= 0) # Retired energy capacity of existing storage units
        # @variable(Expansion_Model, vCAPESTORSTABLE[setSTORSTABLE]     >= 0) # Energy capacity of existing storage units unavailable to retirement (this is actually constant)
        @variable(Expansion_Model, vCAPESTORNEW[union(setSTORNEW,setLHYDRONEW)]           >= 0) # Energy capacity of new build storages
        @variable(Expansion_Model, vRETESTOROLD[union(setSTOROLD,setLHYDROOLD)]           >= 0) # Retired energy capacity of existing storage units
        @variable(Expansion_Model, vCAPESTORSTABLE[union(setSTORSTABLE,setLHYDROSTABLE)]  >= 0) # Energy capacity of existing storage units unavailable to retirement (this is actually constant)

        # @variable(Expansion_Model, vNUMUCNEW[setUCNEWGEN],             Int) # Number of new unit commitment generators to be build
        # @variable(Expansion_Model, vNUMUCOLD[setUCOLDGEN],             Int) # Number of existing unit commitment generators to be retired
        # @variable(Expansion_Model, vNUMUCSTABLE[setUCSTABLEGEN],       Int) # Number of existing unit commitment generators with a constant capacity
        @variable(Expansion_Model, vNUMUCNEW[setUCNEWGEN]             >= 0) # Number of new unit commitment generators to be build
        @variable(Expansion_Model, vNUMUCOLD[setUCOLDGEN]             >= 0) # Number of existing unit commitment generators to be retired
        @variable(Expansion_Model, vNUMUCSTABLE[setUCSTABLEGEN]       >= 0) # Number of existing unit commitment generators with a constant capacity
        @variable(Expansion_Model, vCAPGEN[setGEN]                    >= 0) # Auxiliary variable for capacities of all generators
        # @variable(Expansion_Model, vCAPEGEN[setSTOR]                  >= 0) # Auxiliary variable for energy capacities of all storage units
        @variable(Expansion_Model, vCAPEGEN[union(setSTOR,setLHYDRO)] >= 0) # Auxiliary variable for energy capacities of all storage and reservoir units
        @variable(Expansion_Model, vCAPNEWLINE[setNEWLINE]            >= 0) # Capacity of newly build right of ways
        if transcost_sens == "linear" || transcost_sens == "recodednewlinear"
            @variable(Expansion_Model, vCAPUPGLINE[setOLDLINE]            >= 0) # Upgraded capacity of existing transmission lines
        elseif transcost_sens == "recodedupglinear"
            @variable(Expansion_Model, vCAPUPGLINE[setOLDLINE]            >= 0) # Upgraded capacity of existing transmission lines
	    @variable(Expansion_Model, vCAPUPGLINR[setOLDLINE]            >= 0) # Upgraded capacity of existing transmission lines
        end
        @variable(Expansion_Model, vCAPLINE[setLINE]                  >= 0) # Auxiliary variable for capacity of existing and new transmission lines

        # Unit commitment variables
        # @variable(Expansion_Model, vCOMMIT[setUC, setTIME],  Int) # Number of committed unit commitment generators
        # @variable(Expansion_Model, vSTARTUC[setUC, setTIME], Int) # Start variable for unit commitment generators
        # @variable(Expansion_Model, vSHUTUC[setUC, setTIME],  Int) # Shut variable for unit commitment generators
        @variable(Expansion_Model, vCOMMIT[setUC, setTIME]  >= 0) # Number of committed unit commitment generators
        @variable(Expansion_Model, vSTARTUC[setUC, setTIME] >= 0) # Start variable for unit commitment generators
        @variable(Expansion_Model, vSHUTUC[setUC, setTIME]  >= 0) # Shut variable for unit commitment generators

        # Operational variables
        @variable(Expansion_Model, vGENDISPATCH[setGEN, setTIME]             >= 0) # Dispatch amount from all generators for each time period
        @variable(Expansion_Model, vCHARGE[setSTOR, setTIME]                 >= 0) # Amount of power used for charging of batteries for each time period
        # @variable(Expansion_Model, vSOC[setSTOR, setTIME]             >= 0) # Battery charge/discharge equation for all storages for each time period
        @variable(Expansion_Model, vSOC[union(setSTOR,setLHYDRO), setTIME]   >= 0) # Battery charge/discharge equation for all storages for each time period
        @variable(Expansion_Model, vNSE[setZONE, setSEGMENT, setTIME]        >= 0) # Amount of non-served demand
        @variable(Expansion_Model, vFLOW[setLINE, setTIME]) # Power flow amount on each line for each time period

        # Reserve variables
        @variable(Expansion_Model, vRESUP[union(setUC, setNONUCDISP), setTIME]               >= 0) # Allocated reserve up capacity for all unit commitment constraints for each time period
        @variable(Expansion_Model, vRESDOWN[union(setUC, setNONUCDISP, setNONDISP), setTIME] >= 0) # Allocated reserve down capacity for all unit commitment constraints for each time period
        @variable(Expansion_Model, vCHARGERESUP[setSTOR, setTIME]                            >= 0)
        @variable(Expansion_Model, vDISCHARGERESUP[setSTOR, setTIME]                         >= 0)
        @variable(Expansion_Model, vCHARGERESDOWN[setSTOR, setTIME]                          >= 0)
        @variable(Expansion_Model, vDISCHARGERESDOWN[setSTOR, setTIME]                       >= 0)

        # @variable(Expansion_Model, vUCBIN[union(setUCNEWGEN, setUCOLDGEN)], Bin)

        # @variable(Expansion_Model, vNUMUPDATE[setOLDLINE, setCHANGEOPT, setCHANGEOPT], Bin)
        @variable(Expansion_Model, vNUMUPDATE[setOLDLINE, setCHANGEOPT, setCHANGEOPT], Int)
        @variable(Expansion_Model, vCAPUPDATE[setOLDLINE, setCHANGEOPT, setCHANGEOPT] >= 0)
        # @variable(Expansion_Model, vNUMNEWAC[setOLDLINE], Bin)
        @variable(Expansion_Model, vNUMNEWAC[setOLDLINE], Int)
        @variable(Expansion_Model, vCAPNEWAC[setOLDLINE] >= 0)
        # @variable(Expansion_Model, vNUMNEWDC[setOLDLINE], Bin)
        @variable(Expansion_Model, vNUMNEWDC[setOLDLINE], Int)
        @variable(Expansion_Model, vCAPNEWDC[setOLDLINE] >= 0)

        # CONSTRAINTS
        # Non-negativity constraints
        @constraint(Expansion_Model, nn1[g in setUCNEWGEN], vNUMUCNEW[g]          >= 0)
        @constraint(Expansion_Model, nn2[g in setUCOLDGEN], vNUMUCOLD[g]          >= 0)
        @constraint(Expansion_Model, nn3[g in setUCSTABLEGEN], vNUMUCSTABLE[g]    >= 0)
        @constraint(Expansion_Model, nn4[g in setUC, t in setTIME], vCOMMIT[g,t]  >= 0)
        @constraint(Expansion_Model, nn5[g in setUC, t in setTIME], vSTARTUC[g,t] >= 0)
        @constraint(Expansion_Model, nn6[g in setUC, t in setTIME], vSHUTUC[g,t]  >= 0)

        # Fixing capacity of existing units which are not subject to retirement
        for g in setdiff(setEDSTABLEGEN,setSHYDRO) fix(vCAPEDSTABLE[g], generators.Existing_Cap_MW[g], force = true) end
        # for g in setSHYDRO fix(vCAPEDSTABLE[g], generators.unmodified_existing_cap_mw[g], force = true) end
        for g in setLHYDROSTABLE fix(vCAPSTORSTABLE[g], generators.Existing_Cap_MW[g], force = true) end
        for g in setLHYDROSTABLE fix(vCAPESTORSTABLE[g], generators.Existing_Cap_MWh[g], force = true) end
        for g in setSTORSTABLE fix(vCAPSTORSTABLE[g], generators.Existing_Cap_MW[g], force = true) end
        for g in setSTORSTABLE fix(vCAPESTORSTABLE[g], generators.Existing_Cap_MWh[g], force = true) end
        for g in setUCSTABLEGEN fix(vNUMUCSTABLE[g], generators.num_units[g], force = true) end
        for l in setNEWLINE fix(vCAPNEWLINE[l], network.Line_Max_Flow_MW[l], force = true) end

		##### Two-stage #####
		if two_stage == true
			for g in setGEN fix(vCAPGEN[g], first(gencap_fixed[gencap_fixed.R_ID .== g, :OptValues]), force = true) end
			for g in union(setSTORNEW,setLHYDRONEW) fix(vCAPESTORNEW[g], first(storenergycapnew_fixed[storenergycapnew_fixed.Index .== g, :OptValues]), force = true) end
			for g in union(setSTOROLD,setLHYDROOLD) fix(vRETESTOROLD[g], first(storenergycapold_fixed[storenergycapold_fixed.Index .== g, :OptValues]), force = true) end
			for l in setLINE fix(vCAPLINE[l], first(linecap_fixed[linecap_fixed.Index .== l, :OptValues]), force = true) end
		end
		#####################

        # Create auxiliary variables for generation capacities
        @constraint(Expansion_Model, cCapEdNew[g in setEDNEWGEN], vCAPGEN[g] == vCAPEDNEW[g])
        @constraint(Expansion_Model, cCapEdOld_1[g in setdiff(setEDOLDGEN,setSHYDRO)], vCAPGEN[g] == generators.Existing_Cap_MW[g] - vRETEDOLD[g])
        @constraint(Expansion_Model, cCapEdOld_2[g in setSHYDRO], vCAPGEN[g] == generators.unmodified_existing_cap_mw[g] - vRETEDOLD[g])
        @constraint(Expansion_Model, cCapEdStable[g in setEDSTABLEGEN], vCAPGEN[g] == vCAPEDSTABLE[g])
        # @constraint(Expansion_Model, cCapHydroNew[g in setLHYDRONEW], vCAPGEN[g] == vCAPHYDRONEW[g])
        # @constraint(Expansion_Model, cCapHydroOld[g in setLHYDROOLD], vCAPGEN[g] == generators.Existing_Cap_MW[g] - vRETHYDROOLD[g])
        # @constraint(Expansion_Model, cCapHydroStable[g in setLHYDROSTABLE], vCAPGEN[g] == vCAPHYDROSTABLE[g])
        @constraint(Expansion_Model, cCapStorNew[g in union(setSTORNEW,setLHYDRONEW)], vCAPGEN[g] == vCAPSTORNEW[g])
        @constraint(Expansion_Model, cCapStorOld[g in union(setSTOROLD,setLHYDROOLD)], vCAPGEN[g] == generators.Existing_Cap_MW[g] - vRETSTOROLD[g])
        @constraint(Expansion_Model, cCapStorStable[g in union(setSTORSTABLE,setLHYDROSTABLE)], vCAPGEN[g] == vCAPSTORSTABLE[g])
        @constraint(Expansion_Model, cCapUcNew[g in setUCNEWGEN], vCAPGEN[g] == generators.Cap_Size[g] * vNUMUCNEW[g])
        @constraint(Expansion_Model, cCapUcOld[g in setUCOLDGEN], vCAPGEN[g] == generators.Cap_Size[g] * (generators.num_units[g] - vNUMUCOLD[g]))
        @constraint(Expansion_Model, cCapUcStable[g in setUCSTABLEGEN], vCAPGEN[g] == generators.Cap_Size[g] * vNUMUCSTABLE[g])

        # Create auxiliary variables for storage units energy capacities
        # @constraint(Expansion_Model, cECapStorNew[g in setSTORNEW], vCAPEGEN[g] == vCAPESTORNEW[g])
        # @constraint(Expansion_Model, cECapStorOld[g in setSTOROLD], vCAPEGEN[g] == generators.Existing_Cap_MWh[g] - vRETESTOROLD[g])
        # @constraint(Expansion_Model, cECapStorStable[g in setSTORSTABLE], vCAPEGEN[g] == vCAPESTORSTABLE[g])
        @constraint(Expansion_Model, cECapStorNew[g in union(setSTORNEW,setLHYDRONEW)], vCAPEGEN[g] == vCAPESTORNEW[g])
        @constraint(Expansion_Model, cECapStorOld[g in union(setSTOROLD,setLHYDROOLD)], vCAPEGEN[g] == generators.Existing_Cap_MWh[g] - vRETESTOROLD[g])
        @constraint(Expansion_Model, cECapStorStable[g in union(setSTORSTABLE,setLHYDROSTABLE)], vCAPEGEN[g] == vCAPESTORSTABLE[g])

        # Constraining retired units and capacities (these are redundant constraints)
        @constraint(Expansion_Model, cMaxRetEd_1[g in setdiff(setEDOLDGEN,setSHYDRO)], vRETEDOLD[g] <= generators.Existing_Cap_MW[g])
        @constraint(Expansion_Model, cMaxRetEd_2[g in setSHYDRO], vRETEDOLD[g] <= generators.unmodified_existing_cap_mw[g])
        # @constraint(Expansion_Model, cMaxRetHydro[g in setLHYDROOLD], vRETHYDROOLD[g] <= generators.Existing_Cap_MW[g])
        # @constraint(Expansion_Model, cMaxRetEHydro[g in setLHYDROOLD], vRETESTOROLD[g] <= generators.Existing_Cap_MWh[g])
        @constraint(Expansion_Model, cMaxRetStor[g in union(setSTOROLD,setLHYDROOLD)], vRETSTOROLD[g] <= generators.Existing_Cap_MW[g])
        @constraint(Expansion_Model, cMaxRetEStor[g in union(setSTOROLD,setLHYDROOLD)], vRETESTOROLD[g] <= generators.Existing_Cap_MWh[g])
        @constraint(Expansion_Model, cMaxRetUc[g in setUCOLDGEN], vNUMUCOLD[g] <= generators.num_units[g])

        # Link retired power capacity to retired energy capacity (otherwise, one is positive, the other is zero)
        @constraint(Expansion_Model, cLinkEtoP_1[g in setBATTERYOLD], vRETESTOROLD[g] == vRETSTOROLD[g] * first(generators.Existing_Cap_MWh[g] ./ generators.Existing_Cap_MW[g]))
        @constraint(Expansion_Model, cLinkEtoP_2[g in setPUMPEDOLD], vRETESTOROLD[g] == vRETSTOROLD[g] * first(generators.Existing_Cap_MWh[g] ./ generators.Existing_Cap_MW[g]))
        @constraint(Expansion_Model, cLinkEtoP_3[g in setFLYOLD], vRETESTOROLD[g] == vRETSTOROLD[g] * first(generators.Existing_Cap_MWh[g] ./ generators.Existing_Cap_MW[g]))
        @constraint(Expansion_Model, cLinkEtoP_4[g in setTHERMALSTOROLD], vRETESTOROLD[g] == vRETSTOROLD[g] * first(generators.Existing_Cap_MWh[g] ./ generators.Existing_Cap_MW[g]))
        @constraint(Expansion_Model, cLinkEtoP_5[g in setLHYDROOLD], vRETESTOROLD[g] == vRETSTOROLD[g] * first(generators.Existing_Cap_MWh[g] ./ generators.Existing_Cap_MW[g]))

        # Maximum capacity that can be installed
        # @constraint(Expansion_Model, cMaxCap_NONUC[g in union(setEDNEWGEN, setSTORNEW)], vCAPGEN[g] <= generators.Max_Cap_MW[g])
        # @constraint(Expansion_Model, cMaxCap_NONUC[g in union(setEDNEWGEN, setSTORNEW, setLHYDRONEW)], vCAPGEN[g] <= generators.Max_Cap_MW[g])
        @constraint(Expansion_Model, cMaxCap_NONUC[g in union(setEDNEWGEN, setLHYDRONEW)], vCAPGEN[g] <= generators.Max_Cap_MW[g])
        # @constraint(Expansion_Model, cMaxCap_UC[g in setUCNEWGEN], vNUMUCNEW[g] <= generators.num_units[g])

        # Create auxiliary variables for transmission line capacities and model upgrading of existing lines
        @constraint(Expansion_Model, cCapLineNew[l in setNEWLINE], vCAPLINE[l] == vCAPNEWLINE[l])
        if transcost_sens == "linear" || transcost_sens == "recodednewlinear"
            @constraint(Expansion_Model, cCapLineOld[l in setOLDLINE], vCAPLINE[l] == network.Line_Max_Flow_MW[l] + vCAPUPGLINE[l])
            # @constraint(Expansion_Model, cCapLineOld2[l in setOLDLINE], vCAPUPGLINE[l] <= network.Line_Max_Reinforcement_MW[l])
        elseif transcost_sens == "recodedupglinear"
            @constraint(Expansion_Model, cCapLineOld[l in setOLDLINE], vCAPLINE[l] == network.Line_Max_Flow_MW[l] + vCAPUPGLINE[l] + vCAPUPGLINR[l])
            @constraint(Expansion_Model, cTwoFiveCap[l in setOLDLINE], vCAPUPGLINR[l] <= network.TwoFive_Cap[l])
        else
            @constraint(Expansion_Model, cBinaryLimit_1[l in setOLDLINE, u in setCHANGEOPT], sum(vNUMUPDATE[l,u,v] for v in 1:u) == 0)
            # @constraint(Expansion_Model, cBinaryLimit_2[l in setOLDLINE, u in setCHANGEOPT, v in setCHANGEOPT], vNUMUPDATE[l,u,v] <= voltage_count[l,u])
            # @constraint(Expansion_Model, cBinaryLimit_3[l in setOLDLINE, u in setCHANGEOPT], sum(vNUMUPDATE[l,u,v] for v in setCHANGEOPT) <= 1)
            @constraint(Expansion_Model, cBinaryLimit_3[l in setOLDLINE, u in setCHANGEOPT], sum(vNUMUPDATE[l,u,v] for v in setCHANGEOPT) <= voltage_count[l,u])

            @constraint(Expansion_Model, cPowerLimit_1[l in setOLDLINE, u in setCHANGEOPT_AC, v in setCHANGEOPT_AC],
                                                    vCAPUPDATE[l,u,v] == (voltage_cap[v,:Capacity] - voltage_cap[u,:Capacity]) * vNUMUPDATE[l,u,v])
            @constraint(Expansion_Model, cPowerLimit_2[l in setOLDLINE, u in setCHANGEOPT_AC, v in setCHANGEOPT_DC],
                                                    vCAPUPDATE[l,u,v] == voltage_cap[u,:Capacity] * DC_to_AC * vNUMUPDATE[l,u,v])
            @constraint(Expansion_Model, cPowerLimit_3[l in setOLDLINE, u in setCHANGEOPT], sum(vCAPUPDATE[l,u,v] for v in 1:u) == 0)

            @constraint(Expansion_Model, cNewACLimit[l in setOLDLINE], vCAPNEWAC[l] <= first(voltage_cap[voltage_cap.Voltages .== snew_AC_voltage, :Capacity]) * vNUMNEWAC[l])
            @constraint(Expansion_Model, cNewDCLimit[l in setOLDLINE], vCAPNEWDC[l] <= first(voltage_cap[voltage_cap.Voltages .== "FiveH_DC", :Capacity]) * vNUMNEWDC[l])

            # @constraint(Expansion_Model, cCapLineOld[l in setOLDLINE], vCAPLINE[l] == network.Line_Max_Flow_MW[l] + vCAPNEWAC[l] + vCAPNEWDC[l] +
            #                                                                 sum(voltage_count[l,u] * vCAPUPDATE[l,u,v] for u in setCHANGEOPT, v in setCHANGEOPT))
            @constraint(Expansion_Model, cCapLineOld[l in setOLDLINE], vCAPLINE[l] == network.Line_Max_Flow_MW[l] + vCAPNEWAC[l] + vCAPNEWDC[l] +
                                                                            sum(vCAPUPDATE[l,u,v] for u in setCHANGEOPT, v in setCHANGEOPT))
        end

        # Generation dispatch <= capacity_factor * installed capacity
        @constraint(Expansion_Model, cMaxPower_NONUC[g in setGENSTOR, t in setTIME], vGENDISPATCH[g,t] <= genvar[t,g] * vCAPGEN[g])
        # @constraint(Expansion_Model, cMaxPower_HYDRO_1[g in setLHYDRO, t in setTIME], vGENDISPATCH[g,t] <= (generators.MaxInter[g] + generators.MaxCoef[g] * genvar[t,g]) * vCAPGEN[g])
        @constraint(Expansion_Model, cMaxPower_HYDRO_1[g in setLHYDRO, t in setTIME], vGENDISPATCH[g,t] <= hydromax[t,g] * vCAPGEN[g])
        @constraint(Expansion_Model, cMaxPower_HYDRO_2[g in setLHYDRO, t in setTIME], vGENDISPATCH[g,t] <= vCAPGEN[g])
        @constraint(Expansion_Model, cMaxPower_UC[g in setUC, t in setTIME], vGENDISPATCH[g,t] <= genvar[t,g] * generators.Cap_Size[g] * vCOMMIT[g,t])

        # Generation dispatch >= minimum level of dispatch
        @constraint(Expansion_Model, cMinPower_NONUC[g in setGENSTOR, t in setTIME], vGENDISPATCH[g,t] >= generators.Min_Power[g] * vCAPGEN[g])
        # @constraint(Expansion_Model, cMinPower_HYDRO[g in setLHYDRO, t in setTIME], vGENDISPATCH[g,t] >= (generators.MinInter[g] + generators.MinCoef[g] * genvar[t,g]) * vCAPGEN[g])
        @constraint(Expansion_Model, cMinPower_HYDRO[g in setLHYDRO, t in setTIME], vGENDISPATCH[g,t] >= hydromin[t,g] * vCAPGEN[g])
        @constraint(Expansion_Model, cMinPower_UC[g in setUC, t in setTIME], vGENDISPATCH[g,t] >= generators.Min_Power[g] * generators.Cap_Size[g] * vCOMMIT[g,t])

        # Generation dispatch at time t+1 minus generation dispatch at time t <= ramp up level
        # @constraint(Expansion_Model, cRampUp_NONUC[g in setGENSTOR, t in setINTERIORS], vGENDISPATCH[g,t] - vGENDISPATCH[g,t-1] <= generators.Ramp_Up_percentage[g] * vCAPGEN[g])
        # @constraint(Expansion_Model, cRampUpWrap_NONUC[g in setGENSTOR, t in setSTARTS], vGENDISPATCH[g,t] - vGENDISPATCH[g,t + hours_per_period - 1] <= generators.Ramp_Up_percentage[g] * vCAPGEN[g])
        @constraint(Expansion_Model, cRampUp_NONUC[g in union(setGENSTOR,setLHYDRO), t in setINTERIORS], vGENDISPATCH[g,t] - vGENDISPATCH[g,t-1] <= generators.Ramp_Up_Percentage[g] * vCAPGEN[g])
        @constraint(Expansion_Model, cRampUpWrap_NONUC[g in union(setGENSTOR,setLHYDRO), t in setSTARTS], vGENDISPATCH[g,t] - vGENDISPATCH[g,t + hours_per_period - 1] <= generators.Ramp_Up_Percentage[g] * vCAPGEN[g])
        @constraint(Expansion_Model, cRampUp_UC[g in setUC, t in setINTERIORS], vGENDISPATCH[g,t] - vGENDISPATCH[g,t-1] <=
                                        (vCOMMIT[g,t] - vCOMMIT[g,t-1]) * generators.Min_Power[g] * generators.Cap_Size[g] + vCOMMIT[g,t] * generators.Ramp_Up_Percentage[g] * generators.Cap_Size[g])
        @constraint(Expansion_Model, cRampUpWrap_UC[g in setUC, t in setSTARTS], vGENDISPATCH[g,t] - vGENDISPATCH[g,t + hours_per_period - 1] <=
                                        (vCOMMIT[g,t] - vCOMMIT[g,t + hours_per_period - 1]) * generators.Min_Power[g] * generators.Cap_Size[g] + vCOMMIT[g,t] * generators.Ramp_Up_Percentage[g] * generators.Cap_Size[g])

        # Generation dispatch at time t minus generation dispatch at time t+1 <= ramp down level
        # @constraint(Expansion_Model, cRampDown_NONUC[g in setGENSTOR, t in setINTERIORS], vGENDISPATCH[g,t-1] - vGENDISPATCH[g,t] <= generators.Ramp_Dn_percentage[g] * vCAPGEN[g])
        # @constraint(Expansion_Model, cRampDownWrap_NONUC[g in setGENSTOR, t in setSTARTS], vGENDISPATCH[g,t + hours_per_period - 1] - vGENDISPATCH[g,t] <= generators.Ramp_Dn_percentage[g] * vCAPGEN[g])
        @constraint(Expansion_Model, cRampDown_NONUC[g in union(setGENSTOR,setLHYDRO), t in setINTERIORS], vGENDISPATCH[g,t-1] - vGENDISPATCH[g,t] <= generators.Ramp_Dn_Percentage[g] * vCAPGEN[g])
        @constraint(Expansion_Model, cRampDownWrap_NONUC[g in union(setGENSTOR,setLHYDRO), t in setSTARTS], vGENDISPATCH[g,t + hours_per_period - 1] - vGENDISPATCH[g,t] <= generators.Ramp_Dn_Percentage[g] * vCAPGEN[g])
        @constraint(Expansion_Model, cRampDown_UC[g in setUC, t in setINTERIORS], vGENDISPATCH[g,t-1] - vGENDISPATCH[g,t] <=
                                        (vCOMMIT[g,t-1] - vCOMMIT[g,t]) * generators.Min_Power[g] * generators.Cap_Size[g] + vCOMMIT[g,t] * generators.Ramp_Dn_Percentage[g] * generators.Cap_Size[g])
        @constraint(Expansion_Model, cRampDownWrap_UC[g in setUC, t in setSTARTS], vGENDISPATCH[g,t + hours_per_period - 1] - vGENDISPATCH[g,t] <=
                                        (vCOMMIT[g,t + hours_per_period - 1] - vCOMMIT[g,t]) * generators.Min_Power[g] * generators.Cap_Size[g] + vCOMMIT[g,t] * generators.Ramp_Dn_Percentage[g] * generators.Cap_Size[g])

        # Non-served demand <= maximum allowed non-served demand and sum of vNSE <= load
        @constraint(Expansion_Model, cMaxNSE_1[z in setZONE, s in setSEGMENT, t in setTIME], vNSE[z,s,t] <= nse.NSE_Max[s] * load[t,z])
        @constraint(Expansion_Model, cMaxNSE_2[z in setZONE, t in setTIME], sum(vNSE[z,s,t] for s in setSEGMENT) <= load[t,z])

        # Battery level <= energy capacity of batteries
        # @constraint(Expansion_Model, cMaxSOC[g in setSTOR, t in setTIME], vSOC[g,t] <= vCAPEGEN[g])
        @constraint(Expansion_Model, cMaxSOC[g in union(setSTOR,setLHYDRO), t in setTIME], vSOC[g,t] <= vCAPEGEN[g])

        # SOC(t) = SOC(t-1) + charge efficiency * amount of power used to charge - generation dispatch / discharge efficiency
        @constraint(Expansion_Model, cSOC[g in setSTOR, t in setINTERIORS], vSOC[g,t] == vSOC[g,t-1] + generators.Eff_Up[g] * vCHARGE[g,t] - vGENDISPATCH[g,t] / generators.Eff_Down[g])
        @constraint(Expansion_Model, cSOCWrap[g in setSTOR, t in setSTARTS], vSOC[g,t] == vSOC[g,t + hours_per_period - 1] + generators.Eff_Up[g] * vCHARGE[g,t] - vGENDISPATCH[g,t] / generators.Eff_Down[g])
        @constraint(Expansion_Model, cSOC_Hydro[g in setLHYDRO, t in setINTERIORS], vSOC[g,t] == vSOC[g,t-1] + generators.Eff_Up[g] * genvar[t,g] * vCAPGEN[g] - vGENDISPATCH[g,t] / generators.Eff_Down[g])
        @constraint(Expansion_Model, cSOCWrap_Hydro[g in setLHYDRO, t in setSTARTS], vSOC[g,t] == vSOC[g,t + hours_per_period - 1] + generators.Eff_Up[g] * genvar[t,g] * vCAPGEN[g] - vGENDISPATCH[g,t] / generators.Eff_Down[g])
        # @constraint(Expansion_Model, cSOCStart[g in setSTOR, t = first(setTIME)], vSOC[g,t] == initfinalstate * vCAPEGEN[g])
        # @constraint(Expansion_Model, cSOCFinal[g in setSTOR, t = last(setTIME)], vSOC[g,t] == initfinalstate * vCAPEGEN[g])
        @constraint(Expansion_Model, cSOCStart[g in union(setSTOR,setLHYDRO), t = first(setTIME)], vSOC[g,t] == initfinalstate * vCAPEGEN[g])
        @constraint(Expansion_Model, cSOCFinal[g in union(setSTOR,setLHYDRO), t = last(setTIME)], vSOC[g,t] == initfinalstate * vCAPEGEN[g])
        @constraint(Expansion_Model, cSOCMinHydro[g in setLHYDRO, t in setTIME], vSOC[g,t] >= minreservoirlevel * vCAPEGEN[g])

        # Minimum and maximum energy to power ratio for new build storage units
        # @constraint(Expansion_Model, vMinEtoP[g in setSTORNEW], vCAPESTORNEW[g] >= vCAPSTORNEW[g] * generators.Min_Duration[g])
        # @constraint(Expansion_Model, vMaxEtoP[g in setSTORNEW], vCAPESTORNEW[g] <= vCAPSTORNEW[g] * generators.Max_Duration[g])
        @constraint(Expansion_Model, vMinEtoP[g in union(setSTORNEW,setLHYDRONEW)], vCAPESTORNEW[g] >= vCAPSTORNEW[g] * generators.Min_Duration[g])
        @constraint(Expansion_Model, vMaxEtoP[g in union(setSTORNEW,setLHYDRONEW)], vCAPESTORNEW[g] <= vCAPSTORNEW[g] * generators.Max_Duration[g])

        # Number of committed units <= Number of units built or number of committed units <= final number of units after retirement
        @constraint(Expansion_Model, cCommitMax_New[g in setUCNEWGEN, t in setTIME], vCOMMIT[g,t] <= vNUMUCNEW[g])
        @constraint(Expansion_Model, cCommitMax_Old[g in setUCOLDGEN, t in setTIME], vCOMMIT[g,t] <= generators.num_units[g] - vNUMUCOLD[g])
        @constraint(Expansion_Model, cCommitMax_Stable[g in setUCSTABLEGEN, t in setTIME], vCOMMIT[g,t] <= vNUMUCSTABLE[g])

        # Number of units to be started <= number of installed unit for unit commitment generators
        @constraint(Expansion_Model, cStartCap_New[g in setUCNEWGEN, t in setTIME], vSTARTUC[g,t] <= vNUMUCNEW[g])
        @constraint(Expansion_Model, cStartCap_Old[g in setUCOLDGEN, t in setTIME], vSTARTUC[g,t] <= generators.num_units[g] - vNUMUCOLD[g])
        @constraint(Expansion_Model, cStartCap_Stable[g in setUCSTABLEGEN, t in setTIME], vSTARTUC[g,t] <= vNUMUCSTABLE[g])

        # Number of units to be shut <= number of installed unit for unit commitment generators
        @constraint(Expansion_Model, cShutCap_New[g in setUCNEWGEN, t in setTIME], vSHUTUC[g,t] <= vNUMUCNEW[g])
        @constraint(Expansion_Model, cShutCap_Old[g in setUCOLDGEN, t in setTIME], vSHUTUC[g,t] <= generators.num_units[g] - vNUMUCOLD[g])
        @constraint(Expansion_Model, cShutCap_Stable[g in setUCSTABLEGEN, t in setTIME], vSHUTUC[g,t] <= vNUMUCSTABLE[g])

        # Relation between commit variable and start/shut variables
        @constraint(Expansion_Model, cComStaShu[g in setUC, t in setdiff(setTIME,1)], vCOMMIT[g,t] - vCOMMIT[g,t-1] == vSTARTUC[g,t] - vSHUTUC[g,t])

        # Unit commitment generators have to be up and running for at least a pre-defined duration, once they are started
        @constraint(Expansion_Model, cComSta[g in setUC, t in setdiff(setTIME, 1:maximum(generators.Up_Time[setUC]))],
                                        vCOMMIT[g,t] >= sum(vSTARTUC[g,tt] for tt in round.(Int, Array(t-generators.Up_Time[g]:t))))

        # Unit commitment generators have to be down for at least a pre-defined duration, once they are shutdown
        @constraint(Expansion_Model, cComShut_New[g in setUCNEWGEN, t in setdiff(setTIME, 1:maximum(generators.Down_Time[setUCNEWGEN]))],
                                        vNUMUCNEW[g] - vCOMMIT[g,t] >= sum(vSHUTUC[g,tt] for tt in round.(Int, Array(t-generators.Down_Time[g]:t))))
        @constraint(Expansion_Model, cComShut_Old[g in setUCOLDGEN, t in setdiff(setTIME, 1:maximum(generators.Down_Time[setUCOLDGEN]))],
                                        generators.num_units[g] - vNUMUCOLD[g] - vCOMMIT[g,t] >= sum(vSHUTUC[g,tt] for tt in round.(Int, Array(t-generators.Down_Time[g]:t))))
        if length(setUCSTABLEGEN) > 0
            @constraint(Expansion_Model, cComShut_Stable[g in setUCSTABLEGEN, t in setdiff(setTIME, 1:maximum(generators.Down_Time[setUCSTABLEGEN]))],
                                            vNUMUCSTABLE[g] - vCOMMIT[g,t] >= sum(vSHUTUC[g,tt] for tt in round.(Int, Array(t-generators.Down_Time[g]:t))))
        else
            nothing
        end

        # Maximum investment amount for old and new transmission lines
        # @constraint(Expansion_Model, cMaxInvOldLine[l in setOLDLINE], vCAPUPGLINE[l] <= network.Line_Max_Reinforcement_MW[l])
        # @constraint(Expansion_Model, cMaxInvNewLine[l in setNEWLINE], vCAPNEWLINE[l] <= network.Line_Max_Flow_MW[l])

        # Power flow on transmission lines should be within capacities
        @constraint(Expansion_Model, cMaxFlow[l in setLINE, t in setTIME], vFLOW[l,t] <= vCAPLINE[l])
        @constraint(Expansion_Model, cMinFlow[l in setLINE, t in setTIME], vFLOW[l,t] >= -vCAPLINE[l])

        # Demand-balance constraint
        # @constraint(Expansion_Model, cDemandBalance[t in setTIME, z in setZONE],
        #         sum(vGENDISPATCH[g,t] for g in generators[generators.zone .== z, :R_ID]) +
        #         sum(vNSE[z,s,t] for s in setSEGMENT) -
        #         sum(vCHARGE[g,t] for g in intersect(generators[generators.zone .== z, :R_ID], setSTOR)) -
        #         load[t,z] -
        #         sum(network[l, Symbol(string("z",z))] * vFLOW[l,t] for l in setLINE) == 0
        # )
        @constraint(Expansion_Model, cDemandBalance[t in setTIME, z in setZONE],
                sum(vGENDISPATCH[g,t] for g in generators[generators.Zone .== z, :R_ID]) +
                netimport.Import[z] +
                sum(vNSE[z,s,t] for s in setSEGMENT) -
                sum(vCHARGE[g,t] for g in intersect(generators[generators.Zone .== z, :R_ID], setSTOR)) -
                load[t,z] -
                sum(network[l, Symbol(string("z",z))] * vFLOW[l,t] for l in setLINE) == 0
        )

        # For UC units, reserve up contribution should be less than committed capacity
        @constraint(Expansion_Model, cResUpLessCommit[g in setUC, t in setTIME], vRESUP[g,t] <= generators.Cap_Size[g] * vCOMMIT[g,t])

        # For UC units, reserve down contribution should be less than committed capacity
        @constraint(Expansion_Model, cResDownLessCommit[g in setUC, t in setTIME], vRESDOWN[g,t] <= generators.Cap_Size[g] * vCOMMIT[g,t])

        # For NonUC and Dispatchable units, reserve up contribution should be less than capacity * capacity factor
        # @constraint(Expansion_Model, cResUpLessCap[g in setNONUCDISP, t in setTIME], vRESUP[g,t] <= vCAPGEN[g] * genvar[t,g])
        @constraint(Expansion_Model, cResUpLessCap[g in setdiff(setNONUCDISP, setLHYDRO), t in setTIME], vRESUP[g,t] <= vCAPGEN[g] * genvar[t,g])
        @constraint(Expansion_Model, cResUpLessCap_Hydro[g in setLHYDRO, t in setTIME], vRESUP[g,t] <= vCAPGEN[g] * generators.Ramp_Up_Percentage[g])

        # For NonUC and Dispatchable units, reserve down contribution should be less than capacity * capacity factor
        # @constraint(Expansion_Model, cResDownLessCap[g in union(setNONUCDISP, setNONDISP), t in setTIME], vRESDOWN[g,t] <= vCAPGEN[g] * genvar[t,g])
        @constraint(Expansion_Model, cResDownLessCap[g in setdiff(setNONUCDISP, setLHYDRO), t in setTIME], vRESDOWN[g,t] <= vCAPGEN[g] * genvar[t,g])
        @constraint(Expansion_Model, cResDownLessCap_Hydro[g in setLHYDRO, t in setTIME], vRESDOWN[g,t] <= vCAPGEN[g] * generators.Ramp_Dn_Percentage[g])

        # For storage units, reserves provided while charging and discharging is total reserve up
        @constraint(Expansion_Model, cCombResUp[g in setSTOR, t in setTIME], vRESUP[g,t] == vCHARGERESUP[g,t] + vDISCHARGERESUP[g,t])

        # For storage units, reserves provided while charging and discharging is total reserve down
        @constraint(Expansion_Model, cCombResDown[g in setSTOR, t in setTIME], vRESDOWN[g,t] == vCHARGERESDOWN[g,t] + vDISCHARGERESDOWN[g,t])

        # Amount of capacity allocated for reserve up <= number of committed units - dispatch amount
        @constraint(Expansion_Model, cResUpCom[g in setUC, t in setTIME], vRESUP[g,t] <= generators.Cap_Size[g] * vCOMMIT[g,t] - vGENDISPATCH[g,t])

        # Amount of capacity allocated for reserve down <= dispatch amount - number of committed units
        @constraint(Expansion_Model, cResDownCom[g in setUC, t in setTIME], vRESDOWN[g,t] <= vGENDISPATCH[g,t] - generators.Min_Power[g] * generators.Cap_Size[g] * vCOMMIT[g,t])

        # For dispatchable renewable resources, provided reserve up should be less than capacity - dispatch
        # @constraint(Expansion_Model, cResUpDisp[g in setdiff(setNONUCDISP, setSTOR), t in setTIME], vRESUP[g,t] <= genvar[t,g] * vCAPGEN[g] - vGENDISPATCH[g,t])
        @constraint(Expansion_Model, cResUpDisp_1[g in setdiff(setNONUCDISP, union(setSTOR, setLHYDRO)), t in setTIME], vRESUP[g,t] <= genvar[t,g] * vCAPGEN[g] - vGENDISPATCH[g,t])
        # @constraint(Expansion_Model, cResUpDisp_2[g in setLHYDRO, t in setTIME], vRESUP[g,t] <= (generators.MaxInter[g] + generators.MaxCoef[g] * genvar[t,g]) * vCAPGEN[g] - vGENDISPATCH[g,t])
        @constraint(Expansion_Model, cResUpDisp_2[g in setLHYDRO, t in setTIME], vRESUP[g,t] <= hydromax[t,g] * vCAPGEN[g] - vGENDISPATCH[g,t])
        @constraint(Expansion_Model, cResUpDisp_3[g in setLHYDRO, t in setTIME], vRESUP[g,t] <= vSOC[g,t] - minreservoirlevel * vCAPEGEN[g] - vGENDISPATCH[g,t])

        # For dispatchable renewable resources, provided reserve down should be less than dispatch
        # @constraint(Expansion_Model, cResDownDisp[g in setdiff(setNONUCDISP, setSTOR), t in setTIME], vRESDOWN[g,t] <= vGENDISPATCH[g,t])
        # @constraint(Expansion_Model, cResDownDisp[g in union(setdiff(setNONUCDISP, setSTOR), setNONDISP), t in setTIME], vRESDOWN[g,t] <= vGENDISPATCH[g,t])
        # @constraint(Expansion_Model, cResDownDisp[g in setdiff(setNONUCDISP, union(setSTOR, setHYDRO)), t in setTIME], vRESDOWN[g,t] <= vGENDISPATCH[g,t])
        @constraint(Expansion_Model, cResDownDisp_1[g in union(setdiff(setNONUCDISP, union(setSTOR, setLHYDRO)), setNONDISP), t in setTIME], vRESDOWN[g,t] <= vGENDISPATCH[g,t])
        # @constraint(Expansion_Model, cResDownDisp_2[g in setLHYDRO, t in setTIME], vRESDOWN[g,t] <= vGENDISPATCH[g,t] - (generators.MinInter[g] + generators.MinCoef[g] * genvar[t,g]) * vCAPGEN[g])
        @constraint(Expansion_Model, cResDownDisp_2[g in setLHYDRO, t in setTIME], vRESDOWN[g,t] <= vGENDISPATCH[g,t] - hydromin[t,g] * vCAPGEN[g])

        # For small-hydro, reserve down is limited by ramp rate and minimum power
        @constraint(Expansion_Model, cResDownSmall_1[g in setSHYDRO, t in setTIME], vRESDOWN[g,t] <= vCAPGEN[g] * generators.Ramp_Dn_Percentage[g])
        @constraint(Expansion_Model, cResDownSmall_2[g in setSHYDRO, t in setTIME], vRESDOWN[g,t] <= vGENDISPATCH[g,t] - generators.Min_Power[g] * vCAPGEN[g])

        # Constraint for limiting charging capacity with reserves (previously, I had charge <= capacity)
        @constraint(Expansion_Model, cNewMaxCharge_1[g in setSTOR, t in setTIME], vCHARGE[g,t] + vCHARGERESDOWN[g,t] <= vCAPGEN[g] / generators.Eff_Up[g])
        @constraint(Expansion_Model, cNewMaxCharge_2[g in setSTOR, t in setdiff(setTIME,1)], vCHARGE[g,t] + vCHARGERESDOWN[g,t] <= (vCAPEGEN[g] - vSOC[g,t-1]) / generators.Eff_Up[g])
        @constraint(Expansion_Model, cNewMaxCharge_3[g in setSTOR, t in setTIME], vCHARGE[g,t] - vCHARGERESUP[g,t] >= 0)

        # Special dispatch constraints for storage devices
        @constraint(Expansion_Model, cNewStorDis_1[g in setSTOR, t in setTIME], vGENDISPATCH[g,t] + vDISCHARGERESUP[g,t] <= vCAPGEN[g] * generators.Eff_Down[g])
        @constraint(Expansion_Model, cNewStorDis_2[g in setSTOR, t in setdiff(setTIME,1)], vGENDISPATCH[g,t] + vDISCHARGERESUP[g,t] <= vSOC[g,t-1] * generators.Eff_Down[g])
        @constraint(Expansion_Model, cNewStorDis_3[g in setSTOR, t in setTIME], vGENDISPATCH[g,t] - vDISCHARGERESDOWN[g,t] >= 0)

        # Non-mutually exclusive charge and discharge for storage units
        @constraint(Expansion_Model, cCharDischarge[g in setSTOR, t in setTIME], (vGENDISPATCH[g,t] + vDISCHARGERESUP[g,t]) / generators.Eff_Down[g] + (vCHARGE[g,t] + vCHARGERESDOWN[g,t]) * generators.Eff_Up[g] <= vCAPGEN[g])

        @constraint(Expansion_Model, cStorTotUp[g in setSTOR, t in setTIME], vRESUP[g,t] <= vCAPGEN[g] * generators.Eff_Down[g])

        # Amount of capacity allocated for reserve up <= ramp up level
        @constraint(Expansion_Model, cResUpRamp[g in setUC, t in setTIME], vRESUP[g,t] <= vCOMMIT[g,t] * generators.Ramp_Up_Percentage[g] * generators.Cap_Size[g])

        # Amount of capacity allocated for reserve down <= ramp down level
        @constraint(Expansion_Model, cResDownRamp[g in setUC, t in setTIME], vRESDOWN[g,t] <= vCOMMIT[g,t] * generators.Ramp_Dn_Percentage[g] * generators.Cap_Size[g])

        # Expressions for objective function
        # Fixed and investment costs for generators
        @expression(Expansion_Model, eFixCostGen,
            sum(generators.Fixed_OM_Cost_per_MWyr[g] * vCAPGEN[g] for g in setdiff(setGEN,union(setSTOR,setLHYDRO))) +
            sum(generators.Inv_Cost_per_MWyr[g] * vCAPGEN[g] for g in union(setEDNEWGEN,setUCNEWGEN))
        )
        # Fixed and investment costs for storage units
        @expression(Expansion_Model, eFixCostStor,
			sum(generators.Fixed_OM_Cost_per_MWyr[g] * vCAPGEN[g] for g in union(setSTOR,setLHYDRO)) +
			sum(generators.Inv_Cost_per_MWyr[g] * vCAPGEN[g] for g in union(setSTORNEW,setLHYDRONEW)) +
            sum(generators.Fixed_OM_Cost_per_MWhyr[g] * vCAPEGEN[g] for g in union(setSTOR,setLHYDRO)) +
            sum(generators.Inv_Cost_per_MWhyr[g] * vCAPESTORNEW[g] for g in union(setSTORNEW,setLHYDRONEW))
        )
        if transcost_sens == "linear"
            @expression(Expansion_Model, eFixCostLine,
                sum(network.Line_Fixed_Cost_per_MW_yr[l] * vCAPLINE[l] + network.Line_Reinforcement_Cost_per_MWyr[l] * vCAPUPGLINE[l] for l in setOLDLINE) +
                # sum(network.Line_Fixed_Cost_per_MW_yr[l] * vCAPLINE[l] for l in setOLDLINE) +
                sum(network.Line_Fixed_Cost_per_MW_yr[l] * vCAPLINE[l] + network.Line_Reinforcement_Cost_per_MWyr[l] * vCAPNEWLINE[l] for l in setNEWLINE)
            )
        elseif transcost_sens == "recodednewlinear"
            @expression(Expansion_Model, eFixCostLine,
                sum(network.Line_Fixed_Cost_per_MW_yr[l] * vCAPLINE[l] + network.RecodedNewLinear[l] * vCAPUPGLINE[l] for l in setOLDLINE) +
                # sum(network.Line_Fixed_Cost_per_MW_yr[l] * vCAPLINE[l] + network.Line_Reinforcement_Cost_per_MWyr[l] * vCAPNEWLINE[l] for l in setNEWLINE)
				sum(network.Line_Fixed_Cost_per_MW_yr[l] * vCAPLINE[l] + network.RecodedNewLinear[l] * vCAPNEWLINE[l] for l in setNEWLINE)
            )
        elseif transcost_sens == "recodedupglinear"
            @expression(Expansion_Model, eFixCostLine,
                sum(network.Line_Fixed_Cost_per_MW_yr[l] * vCAPLINE[l] + network.RecodedNewLinear[l] * vCAPUPGLINE[l] + network.RecodedUpgLinear[l] * vCAPUPGLINR[l] for l in setOLDLINE) +
                # sum(network.Line_Fixed_Cost_per_MW_yr[l] * vCAPLINE[l] + network.Line_Reinforcement_Cost_per_MWyr[l] * vCAPNEWLINE[l] for l in setNEWLINE)
				sum(network.Line_Fixed_Cost_per_MW_yr[l] * vCAPLINE[l] + network.RecodedNewLinear[l] * vCAPNEWLINE[l] for l in setNEWLINE)
            )
        else
            @expression(Expansion_Model, eFixCostLine,
                # sum(network.Line_Fixed_Cost_per_MW_yr[l] * vCAPLINE[l] + network.Line_Reinforcement_Cost_per_MWyr[l] * vCAPUPGLINE[l] for l in setOLDLINE) +
                sum(network.Line_Fixed_Cost_per_MW_yr[l] * vCAPLINE[l] for l in setOLDLINE) +
                # sum(network.Line_Fixed_Cost_per_MW_yr[l] * vCAPLINE[l] + network.Line_Reinforcement_Cost_per_MWyr[l] * vCAPNEWLINE[l] for l in setNEWLINE)
                sum(network.Line_Fixed_Cost_per_MW_yr[l] * vCAPLINE[l] + network.RecodedNewLinear[l] * vCAPNEWLINE[l] for l in setNEWLINE)
            )
        end

        # Investment cost for new AC lines
        @expression(Expansion_Model, eNewACCost,
            sum(
                (
                first(linesub_cost_new_ACDC[linesub_cost_new_ACDC.Voltages .== snew_AC_voltage, :Sub_fixed_cost]) * (network.distance_mile[l] / sub_distance_AC - 1 + 2) +
                first(linesub_cost_new_ACDC[linesub_cost_new_ACDC.Voltages .== snew_AC_voltage, :Line_cost_per_mile]) * network.distance_mile[l] +
                row_costs[l,snew_AC_voltage] * network.distance_mile[l]
                ) * vNUMNEWAC[l] +
                (first(linesub_cost_new_ACDC[linesub_cost_new_ACDC.Voltages .== snew_AC_voltage, :Sub_cost_per_MW]) * (network.distance_mile[l] / sub_distance_AC - 1 + 2)) * vCAPNEWAC[l]
                for l in setOLDLINE
            )
        )
        # Investment cost for new DC lines
        @expression(Expansion_Model, eNewDCCost,
            sum(
                (
                first(linesub_cost_new_ACDC[linesub_cost_new_ACDC.Voltages .== snew_AC_voltage, :Sub_fixed_cost]) * num_conv_DC +
                first(linesub_cost_new_ACDC[linesub_cost_new_ACDC.Voltages .== "FiveH_DC", :Line_cost_per_mile]) * network.distance_mile[l] +
                row_costs[l,:FiveH_DC] * network.distance_mile[l]
                ) * vNUMNEWDC[l] +
                (first(linesub_cost_new_ACDC[linesub_cost_new_ACDC.Voltages .== "FiveH_DC", :Sub_cost_per_MW]) * num_conv_DC) * vCAPNEWDC[l] +
                (first(linesub_cost_new_ACDC[linesub_cost_new_ACDC.Voltages .== snew_AC_voltage, :Sub_cost_per_MW]) * num_conv_DC) * vCAPNEWDC[l]
                for l in setOLDLINE
            )
        )
        # Investment cost for AC to AC upgrade
        @expression(Expansion_Model, eACtoACUpgradeCost,
            # sum(voltage_count[l,u] * (row_costs[l,v] - row_costs[l,u]) * network.distance_mile[l] * vNUMUPDATE[l,u,v] for l in setOLDLINE, u in setCHANGEOPT_AC, v in setCHANGEOPT_AC) +
            # sum(voltage_count[l,u] * tranconv_costs_upgrade[u,v] * vCAPUPDATE[l,u,v] * (network.distance_mile[l] / sub_distance_AC - 1 + 2) for l in setOLDLINE, u in setCHANGEOPT_AC, v in setCHANGEOPT_AC)
            sum((row_costs[l,v] - row_costs[l,u]) * network.distance_mile[l] * vNUMUPDATE[l,u,v] for l in setOLDLINE, u in setCHANGEOPT_AC, v in setCHANGEOPT_AC) +
            # sum(tranconv_costs_upgrade[u,v] * vCAPUPDATE[l,u,v] * (network.distance_mile[l] / sub_distance_AC - 1 + 2) for l in setOLDLINE, u in setCHANGEOPT_AC, v in setCHANGEOPT_AC)
            sum(tranconv_costs_upgrade[u,v] * voltage_cap[v,:Capacity] * vNUMUPDATE[l,u,v] * (network.distance_mile[l] / sub_distance_AC - 1 + 2) for l in setOLDLINE, u in setCHANGEOPT_AC, v in setCHANGEOPT_AC)
        )
        # Investment cost for AC to DC upgrade (1)
        @expression(Expansion_Model, eACtoDCUpgradeCost_1,
            # sum(voltage_count[l,u] * (row_costs[l,v] - row_costs[l,u]) * network.distance_mile[l] * vNUMUPDATE[l,u,v] for l in setOLDLINE, u in setCHANGEOPT_ACROWLESSDC, v in setCHANGEOPT_DC) +
            # sum(voltage_count[l,u] * tranconv_costs_upgrade[u,v] * vCAPUPDATE[l,u,v] * num_conv_DC for l in setOLDLINE, u in setCHANGEOPT_ACROWLESSDC, v in setCHANGEOPT_DC)
            sum((row_costs[l,v] - row_costs[l,u]) * network.distance_mile[l] * vNUMUPDATE[l,u,v] for l in setOLDLINE, u in setCHANGEOPT_ACROWLESSDC, v in setCHANGEOPT_DC) +
            # sum((tranconv_costs_upgrade[u,v] + first(linesub_cost_new_ACDC[linesub_cost_new_ACDC.Voltages .== snew_AC_voltage, :Sub_cost_per_MW])) * vCAPUPDATE[l,u,v] * num_conv_DC for l in setOLDLINE, u in setCHANGEOPT_ACROWLESSDC, v in setCHANGEOPT_DC)
            sum((tranconv_costs_upgrade[u,v] + first(linesub_cost_new_ACDC[linesub_cost_new_ACDC.Voltages .== snew_AC_voltage, :Sub_cost_per_MW])) * voltage_cap[u,:Capacity] * (DC_to_AC + 1) * vNUMUPDATE[l,u,v] * num_conv_DC for l in setOLDLINE, u in setCHANGEOPT_ACROWLESSDC, v in setCHANGEOPT_DC)
        )
        # Investment cost for AC to DC upgrade (2)
        @expression(Expansion_Model, eACtoDCUpgradeCost_2,
            # sum(voltage_count[l,u] * tranconv_costs_upgrade[u,v] * vCAPUPDATE[l,u,v] * num_conv_DC for l in setOLDLINE, u in setdiff(setCHANGEOPT_AC,setCHANGEOPT_ACROWLESSDC), v in setCHANGEOPT_DC)
            # sum(tranconv_costs_upgrade[u,v] * vCAPUPDATE[l,u,v] * num_conv_DC for l in setOLDLINE, u in setdiff(setCHANGEOPT_AC,setCHANGEOPT_ACROWLESSDC), v in setCHANGEOPT_DC)
            sum(tranconv_costs_upgrade[u,v] * voltage_cap[u,:Capacity] * (DC_to_AC + 1) * vNUMUPDATE[l,u,v] * num_conv_DC for l in setOLDLINE, u in setdiff(setCHANGEOPT_AC,setCHANGEOPT_ACROWLESSDC), v in setCHANGEOPT_DC)
        )
        # Variable costs for generation dispatches
        @expression(Expansion_Model, eVarCostGen,
            sum(sample_weight[t] * generators.Var_Cost[g] * vGENDISPATCH[g,t] for g in setGEN, t in setTIME)
        )
        # Cost of non-served demand
        @expression(Expansion_Model, eNSECosts,
            sum(sample_weight[t] * nse.NSE_Cost[s] * vNSE[z,s,t] for z in setZONE, s in setSEGMENT, t in setTIME)
        )
        # Start up cost for unit commitment generators
        @expression(Expansion_Model, eStartCostUC,
            sum(generators.Start_Cost[g] * generators.Cap_Size[g] * vSTARTUC[g,t] for g in setUC, t in setTIME)
        )

        if policy_scenario == "state"

            # @variable(Expansion_Model, vFLOWTOTPOS[setLINE] >= 0)
            # @variable(Expansion_Model, vFLOWTOTNEG[setLINE] >= 0)
            # @variable(Expansion_Model, vFLOWTOTSIGN[setLINE], Bin)
            # @variable(Expansion_Model, vRECFLOWTOT[setLINE])
            # @variable(Expansion_Model, vNONCOMP_RPS[setZONE] >= 0)
            # @variable(Expansion_Model, vNONCOMP_CES[setZONE] >= 0)
            # @variable(Expansion_Model, vGENRPS               >= 0)
            # @variable(Expansion_Model, vSOS[setLINE, 1:2] >= 0) # 1: positive, 2: negative

            # Determine REC for policy constraint
            # @constraint(Expansion_Model, cFlowPosNeg[l in setLINE], sum(vFLOW[l,t] * sample_weight[t] for t in setTIME) == vFLOWTOTPOS[l] - vFLOWTOTNEG[l])
            # @constraint(Expansion_Model, cFlowPosNeg[l in setLINE], sum(vFLOW[l,t] * sample_weight[t] for t in setTIME) == vSOS[l,1] - vSOS[l,2])
            # @constraint(Expansion_Model, cRec1[l in setLINE], -vFLOWTOTNEG[l] <= vRECFLOWTOT[l])
            # @constraint(Expansion_Model, cRec2[l in setLINE], vRECFLOWTOT[l] <= vFLOWTOTPOS[l])
            # @constraint(Expansion_Model, cRec1[l in setLINE], -vSOS[l,2] <= vRECFLOWTOT[l])
            # @constraint(Expansion_Model, cRec2[l in setLINE], vRECFLOWTOT[l] <= vSOS[l,1])
            # @constraint(Expansion_Model, cBigMPos[l in setLINE], vFLOWTOTPOS[l] <= bigMREC * vFLOWTOTSIGN[l])
            # @constraint(Expansion_Model, cBigMNeg[l in setLINE], vFLOWTOTNEG[l] <= bigMREC * (1 - vFLOWTOTSIGN[l]))
            # for linenum in setLINE
            #     @constraint(Expansion_Model, vSOS[linenum, :] in SOS1())
            # end

            # @constraint(Expansion_Model, cRPS[z in setZONE],
            #     sum(vGENDISPATCH[g,t] * sample_weight[t] for g in intersect(generators[generators.zone .== z, :R_ID], setRENEW), t in setTIME) -
            #     sum(network[l, Symbol(string("z",z))] * vRECFLOWTOT[l] for l in setLINE) >=
            #     rpsgoal[z] * sum(vGENDISPATCH[g,t] * sample_weight[t] for g in generators[generators.zone .== z, :R_ID], t in setTIME)
            # )
            # @constraint(Expansion_Model, cCES[z in setZONE],
            #     sum(vGENDISPATCH[g,t] * sample_weight[t] for g in intersect(generators[generators.zone .== z, :R_ID], union(setRENEW, setCES)), t in setTIME) -
            #     sum(network[l, Symbol(string("z",z))] * vRECFLOWTOT[l] for l in setLINE) >=
            #     cesgoal[z] * sum(vGENDISPATCH[g,t] * sample_weight[t] for g in generators[generators.zone .== z, :R_ID], t in setTIME)
            # )
            # @constraint(Expansion_Model, cRPS_1[z in setZONE],
            #     sum(vGENDISPATCH[g,t] * sample_weight[t] for g in intersect(generators[generators.zone .== z, :R_ID], setRENEW), t in setTIME) +
            #     vNONCOMP_RPS[z] >=
            #     instate_rps * rpsgoal[z] * sum(vGENDISPATCH[g,t] * sample_weight[t] for g in generators[generators.zone .== z, :R_ID], t in setTIME)
            # )
            # @constraint(Expansion_Model, cRPS_1[z in setZONE],
            #     sum(vGENDISPATCH[g,t] * sample_weight[t] for g in intersect(generators[generators.zone .== z, :R_ID], setRENEW), t in setTIME) >=
            #     rpsgoal[z] * sum(vGENDISPATCH[g,t] * sample_weight[t] for g in generators[generators.zone .== z, :R_ID], t in setTIME)
            # )
            # The following was the single working constraint
            @constraint(Expansion_Model, cRPS_1[z in setZONE],
                sum(vGENDISPATCH[g,t] * sample_weight[t] for g in intersect(generators[generators.Zone .== z, :R_ID], setRENEW), t in setTIME) >=
                instate_rps * rpsgoal[z] * sum(vGENDISPATCH[g,t] * sample_weight[t] for g in intersect(setdiff(setGEN,setSTOR), generators[generators.Zone .== z, :R_ID]), t in setTIME)
            )
            @constraint(Expansion_Model, cRPS_2,
                sum(sum(vGENDISPATCH[g,t] * sample_weight[t] for g in intersect(generators[generators.Zone .== z, :R_ID], setRENEW), t in setTIME) for z in setZONE) >=
                sum(rpsgoal[z] * sum(vGENDISPATCH[g,t] * sample_weight[t] for g in intersect(setdiff(setGEN,setSTOR), generators[generators.Zone .== z, :R_ID]), t in setTIME) for z in setZONE)
            )

            # @constraint(Expansion_Model, cRPS_2,
            #     vGENRPS +
            #     # sum(sum(vGENDISPATCH[g,t] * sample_weight[t] for g in intersect(generators[generators.zone .== z, :R_ID], setRENEW), t in setTIME) for z in setZONE) +
            #     sum(vNONCOMP_RPS[z] for z in setZONE) >=
            #     sum(sum(rpsgoal[z] * sum(vGENDISPATCH[g,t] * sample_weight[t] for g in generators[generators.zone .== z, :R_ID], t in setTIME)) for z in setZONE)
            # )

            # @constraint(Expansion_Model, cRPS_3,
            #     vGENRPS <= sum(sum(vGENDISPATCH[g,t] * sample_weight[t] for g in intersect(generators[generators.zone .== z, :R_ID], setRENEW), t in setTIME) for z in setZONE)
            # )

            # @constraint(Expansion_Model, cCES_1[z in setZONE],
            #     sum(vGENDISPATCH[g,t] * sample_weight[t] for g in intersect(generators[generators.zone .== z, :R_ID], union(setRENEW, setCES)), t in setTIME) +
            #     vNONCOMP_CES[z] >=
            #     instate_ces * cesgoal[z] * sum(vGENDISPATCH[g,t] * sample_weight[t] for g in generators[generators.zone .== z, :R_ID], t in setTIME)
            # )
            # @constraint(Expansion_Model, cCES_1[z in setZONE],
            #     sum(vGENDISPATCH[g,t] * sample_weight[t] for g in intersect(generators[generators.zone .== z, :R_ID], union(setRENEW, setCES)), t in setTIME) >=
            #     cesgoal[z] * sum(vGENDISPATCH[g,t] * sample_weight[t] for g in generators[generators.zone .== z, :R_ID], t in setTIME)
            # )
            # The following was the single working constraint
            @constraint(Expansion_Model, cCES_1[z in setZONE],
                sum(vGENDISPATCH[g,t] * sample_weight[t] for g in intersect(generators[generators.Zone .== z, :R_ID], union(setRENEW, setCES)), t in setTIME) >=
                instate_ces * cesgoal[z] * sum(vGENDISPATCH[g,t] * sample_weight[t] for g in intersect(setdiff(setGEN,setSTOR), generators[generators.Zone .== z, :R_ID]), t in setTIME)
            )
            @constraint(Expansion_Model, cCES_2,
                sum(sum(vGENDISPATCH[g,t] * sample_weight[t] for g in intersect(generators[generators.Zone .== z, :R_ID], union(setRENEW, setCES)), t in setTIME) for z in setZONE) >=
                sum(cesgoal[z] * sum(vGENDISPATCH[g,t] * sample_weight[t] for g in intersect(setdiff(setGEN,setSTOR), generators[generators.Zone .== z, :R_ID]), t in setTIME) for z in setZONE)
            )
            # @constraint(Expansion_Model, cCES_2,
            #     sum(sum(vGENDISPATCH[g,t] * sample_weight[t] for g in intersect(generators[generators.zone .== z, :R_ID], union(setRENEW, setCES)), t in setTIME) for z in setZONE) -
            #     vGENRPS +
            #     sum(vNONCOMP_CES[z] for z in setZONE) >=
            #     sum(sum(cesgoal[z] * sum(vGENDISPATCH[g,t] * sample_weight[t] for g in generators[generators.zone .== z, :R_ID], t in setTIME)) for z in setZONE)
            # )

            # @expression(Expansion_Model, eNoncompliance_RPS,
            #     penalty_rps_ces * sum(vNONCOMP_RPS[z] for z in setZONE)
            # )
            # @expression(Expansion_Model, eNoncompliance_CES,
            #     penalty_rps_ces * sum(vNONCOMP_CES[z] for z in setZONE)
            # )

        elseif policy_scenario == "regionalrps"
            @constraint(Expansion_Model, cRPS_Region,
                sum(vGENDISPATCH[g,t] * sample_weight[t] for g in setRENEW, t in setTIME) >=
                clean_RPS * sum(vGENDISPATCH[g,t] * sample_weight[t] for g in setdiff(setGEN,setSTOR), t in setTIME)
            )
        elseif policy_scenario == "regionalces"
            @constraint(Expansion_Model, cCES_Region,
                sum(vGENDISPATCH[g,t] * sample_weight[t] for g in union(setRENEW, setCES), t in setTIME) >=
                clean_CES * sum(vGENDISPATCH[g,t] * sample_weight[t] for g in setdiff(setGEN,setSTOR), t in setTIME)
            )
        else
            nothing
        end

        if region_scenario == "baseline"

            # @variable(Expansion_Model, vCONT[setZONE] >= 0)
            @variable(Expansion_Model, vMINHURDLE[setLINE, setTIME] >= 0) # Transmission cost on each line for each time period

            # @constraint(Expansion_Model, cContStable[z in setZONE, g in intersect(setUCSTABLEGEN, generators[generators.Zone .== z, :R_ID])], vCONT[z] >= generators.Cap_Size[g])
            #
            # @constraint(Expansion_Model, cContNew_1[z in setZONE, g in intersect(setUCNEWGEN, generators[generators.Zone .== z, :R_ID])], vCONT[z] >= generators.Cap_Size[g] * vUCBIN[g])
            # @constraint(Expansion_Model, cContNew_2[g in setUCNEWGEN], vNUMUCNEW[g] <= vUCBIN[g] * bigMucnew)
            #
            # @constraint(Expansion_Model, cContOld_1[z in setZONE, g in intersect(setUCOLDGEN, generators[generators.Zone .== z, :R_ID])], vCONT[z] >= generators.Cap_Size[g] * vUCBIN[g])
            # @constraint(Expansion_Model, cContOld_2[g in setUCOLDGEN], generators.num_units[g] - vNUMUCOLD[g] <= vUCBIN[g] * bigMucold)

            # Amount of capacity allocated for reserve up should be bigger than a level
            # @constraint(Expansion_Model, cTotResUp[z in setZONE, t in setTIME],
            #     sum(vRESUP[g,t] for g in intersect(union(setUC, setNONUCDISP), generators[generators.zone .== z, :R_ID])) >=
            #     first(operatingres[operatingres.Zones .== z, :Load]) * load[t,z] +
            #     first(operatingres[operatingres.Zones .== z, :Renewable]) * sum(vGENDISPATCH[g,t] for g in intersect(setNONDISPRENEW, generators[generators.zone .== z, :R_ID])) +
            #     vCONT[z])
            # I removed the following
            @constraint(Expansion_Model, cTotResUp[z in setZONE, t in setTIME],
                sum(vRESUP[g,t] for g in intersect(union(setUC, setNONUCDISP), generators[generators.Zone .== z, :R_ID])) >=
                first(operatingres[operatingres.Zones .== z, :Load]) * load[t,z] +
                first(operatingres[operatingres.Zones .== z, :Renewable]) * sum(vGENDISPATCH[g,t] for g in intersect(setdiff(setNONDISPRENEW,setSHYDRO), generators[generators.Zone .== z, :R_ID])) +
                contn1[z])
            # I removed the above
            # @constraint(Expansion_Model, cTotResUp[z in setZONE, t in setTIME],
            #     sum(vRESUP[g,t] for g in intersect(union(setUC, setNONUCDISP), generators[generators.zone .== z, :R_ID])) >=
            #     first(operatingres[operatingres.Zones .== z, :Load]) * load[t,z] +
            #     first(operatingres[operatingres.Zones .== z, :Renewable]) * sum(vGENDISPATCH[g,t] for g in intersect(setdiff(setNONDISPRENEW,setSHYDRO), generators[generators.zone .== z, :R_ID])) +
            #     largestunit[z])

            # Amount of capacity allocated for reserve down should be bigger than a level
            # @constraint(Expansion_Model, cTotResDown[z in setZONE, t in setTIME],
            #     sum(vRESDOWN[g,t] for g in intersect(union(setUC, setNONUCDISP, setNONDISP), generators[generators.zone .== z, :R_ID])) >=
            #     first(operatingres[operatingres.Zones .== z, :Load]) * load[t,z] +
            #     first(operatingres[operatingres.Zones .== z, :Renewable]) * sum(vGENDISPATCH[g,t] for g in intersect(setNONDISPRENEW, generators[generators.zone .== z, :R_ID])))
            @constraint(Expansion_Model, cTotResDown[z in setZONE, t in setTIME],
                sum(vRESDOWN[g,t] for g in intersect(union(setUC, setNONUCDISP, setNONDISP), generators[generators.Zone .== z, :R_ID])) >=
                first(operatingres[operatingres.Zones .== z, :Load]) * load[t,z] +
                first(operatingres[operatingres.Zones .== z, :Renewable]) * sum(vGENDISPATCH[g,t] for g in intersect(setdiff(setNONDISPRENEW,setSHYDRO), generators[generators.Zone .== z, :R_ID])))

            # Obtain transmission costs
            @constraint(Expansion_Model, cHurdleRate[l in setdiff(setLINE, hurdle0_lines), z in setZONE, t in setTIME],
                                                    vMINHURDLE[l,t] >= vFLOW[l,t] * network[l, Symbol(string("z",z))] * first(hurdlerates[hurdlerates.Zones .== z, :Rate_From]))

            # Planning reserve requirement for each zone
            # @constraint(Expansion_Model, cPlanRes[z in setZONE],
            #     sum(vCAPGEN[g] * genvar[timepeakdemand,g] for g in generators[generators.zone .== z, :R_ID]) +
            #     first(planningres[planningres.Zones .== z, :FImport]) -
            #     first(planningres[planningres.Zones .== z, :FExport])
            #     >= maximum(load[:,z]) * (1 + first(planningres[planningres.Zones .== z, :Margin]))
            # )
            @constraint(Expansion_Model, cPlanRes[z in setZONE],
                sum(vCAPGEN[g] * subgenvar[1,g] for g in generators[generators.Zone .== z, :R_ID]) +
                first(planningres[planningres.Zones .== z, :FImport]) -
                first(planningres[planningres.Zones .== z, :FExport])
                >= maximum(load[:,z]) * (1 + first(planningres[planningres.Zones .== z, :Margin]))
            )

            # Transmission costs (hurdle costs)
            @expression(Expansion_Model, eTransactionCost,
                sum(vMINHURDLE[l,t] for l in setLINE, t in setTIME)
            )

            if transcost_sens == "linear" || transcost_sens == "recodednewlinear" || transcost_sens == "recodedupglinear"
                @objective(Expansion_Model, Min, eFixCostGen + eFixCostStor + eFixCostLine + eVarCostGen + eNSECosts + eStartCostUC +
                                            eTransactionCost) # Define the objective function
            else
                @objective(Expansion_Model, Min, eFixCostGen + eFixCostStor + eFixCostLine + eNewACCost + eNewDCCost +
                                            eACtoACUpgradeCost + eACtoDCUpgradeCost_1 + eACtoDCUpgradeCost_2 + eVarCostGen + eNSECosts + eStartCostUC +
                                            eTransactionCost) # Define the objective function
            end

        elseif region_scenario == "expandedEIM" || region_scenario == "regionalized"

            # @variable(Expansion_Model, vCONTREG >= 0)

            # @constraint(Expansion_Model, cContReg[z in setZONE], vCONTREG >= vCONT[z])

            # @constraint(Expansion_Model, cContStable[z in setZONE, g in intersect(setUCSTABLEGEN, generators[generators.zone .== z, :R_ID])], vCONT[z] >= generators.Cap_size[g])
            #
            # @constraint(Expansion_Model, cContNew_1[z in setZONE, g in intersect(setUCNEWGEN, generators[generators.zone .== z, :R_ID])], vCONT[z] >= generators.Cap_size[g] * vUCBIN[g])
            # @constraint(Expansion_Model, cContNew_2[g in setUCNEWGEN], vNUMUCNEW[g] <= vUCBIN[g] * bigMucnew)
            #
            # @constraint(Expansion_Model, cContOld_1[z in setZONE, g in intersect(setUCOLDGEN, generators[generators.zone .== z, :R_ID])], vCONT[z] >= generators.Cap_size[g] * vUCBIN[g])
            # @constraint(Expansion_Model, cContOld_2[g in setUCOLDGEN], generators.num_units[g] - vNUMUCOLD[g] <= vUCBIN[g] * bigMucold)

            # @constraint(Expansion_Model, cContStable[g in setUCSTABLEGEN], vCONTREG >= generators.Cap_Size[g])
            #
            # @constraint(Expansion_Model, cContNew_1[g in setUCNEWGEN], vCONTREG >= generators.Cap_Size[g] * vUCBIN[g])
            # @constraint(Expansion_Model, cContNew_2[g in setUCNEWGEN], vNUMUCNEW[g] <= vUCBIN[g] * bigMucnew)
            #
            # @constraint(Expansion_Model, cContOld_1[g in setUCOLDGEN], vCONTREG >= generators.Cap_Size[g] * vUCBIN[g])
            # @constraint(Expansion_Model, cContOld_2[g in setUCOLDGEN], generators.num_units[g] - vNUMUCOLD[g] <= vUCBIN[g] * bigMucold)

            @constraint(Expansion_Model, cTotResUp_Region[t in setTIME],
                sum(vRESUP[g,t] for g in union(setUC, setNONUCDISP)) >=
                regional_load * sum(load[t,z] for z in setZONE) +
                regional_renew * sum(vGENDISPATCH[g,t] for g in setdiff(setNONDISPRENEW,setSHYDRO)) +
                contn1_regional)

            @constraint(Expansion_Model, cTotResDown_Region[t in setTIME],
                sum(vRESDOWN[g,t] for g in union(setUC, setNONUCDISP, setNONDISP)) >=
                regional_load * sum(load[t,z] for z in setZONE) +
                regional_renew * sum(vGENDISPATCH[g,t] for g in setdiff(setNONDISPRENEW,setSHYDRO)))

            if region_scenario == "expandedEIM"
                # @constraint(Expansion_Model, cPlanRes_EIM[z in setZONE],
                #     sum(vCAPGEN[g] * genvar[timepeakdemand,g] for g in generators[generators.zone .== z, :R_ID]) +
                #     addimpexp * first(planningres[planningres.Zones .== z, :FImport]) -
                #     addimpexp * first(planningres[planningres.Zones .== z, :FExport])
                #     >= maximum(load[:,z]) * (1 + first(planningres[planningres.Zones .== z, :Margin]))
                # )
                @constraint(Expansion_Model, cPlanRes_EIM[z in setZONE],
                    sum(vCAPGEN[g] * subgenvar[1,g] for g in generators[generators.Zone .== z, :R_ID]) +
                    addimpexp * first(planningres[planningres.Zones .== z, :FImport]) -
                    addimpexp * first(planningres[planningres.Zones .== z, :FExport])
                    >= maximum(load[:,z]) * (1 + first(planningres[planningres.Zones .== z, :Margin]))
                )
            elseif region_scenario == "regionalized"
                # @constraint(Expansion_Model, cPlanRes_Region,
                #     sum(vCAPGEN[g] * genvar[timepeakdemand,g] for g in setGEN)
                #     >= maximum(maximum(eachcol(load))) * (1 + region_margin)
                # )
                @constraint(Expansion_Model, cPlanRes_Region,
                    sum(vCAPGEN[g] * subgenvar[1,g] for g in setGEN)
                    >= maximum(maximum(eachcol(load))) * (1 + region_margin)
                )
            else
                nothing
            end

            if transcost_sens == "linear" || transcost_sens == "recodednewlinear" || transcost_sens == "recodedupglinear"
                @objective(Expansion_Model, Min, eFixCostGen + eFixCostStor + eFixCostLine + eVarCostGen + eNSECosts + eStartCostUC) # Define the objective function
            else
                @objective(Expansion_Model, Min, eFixCostGen + eFixCostStor + eFixCostLine + eNewACCost + eNewDCCost +
                                                eACtoACUpgradeCost + eACtoDCUpgradeCost_1 + eACtoDCUpgradeCost_2 + eVarCostGen + eNSECosts + eStartCostUC) # Define the objective function
            end

        else
            nothing
        end


    end

    @timeit to "solve_model" begin optimize!(Expansion_Model) end

    @timeit to "report_results" begin
        if termination_status(Expansion_Model) == MOI.OPTIMAL || termination_status(Expansion_Model) == MOI.TIME_LIMIT # If model is solved to optimality or time limit is reached

            # Call WriteResults function from WriteResults.jl file
            # gencapdec = [vCAPEDNEW, vRETEDOLD, vCAPEDSTABLE, vCAPSTORNEW, vRETSTOROLD, vCAPSTORSTABLE, vCAPESTORNEW, vRETESTOROLD, vCAPESTORSTABLE, vNUMUCNEW, vNUMUCOLD, vNUMUCSTABLE, vUCBIN]
            gencapdec = [vCAPEDNEW, vRETEDOLD, vCAPEDSTABLE, vCAPSTORNEW, vRETSTOROLD, vCAPSTORSTABLE, vCAPESTORNEW, vRETESTOROLD, vCAPESTORSTABLE, vNUMUCNEW, vNUMUCOLD, vNUMUCSTABLE]
            # gencapdec = [vCAPEDNEW, vRETEDOLD, vCAPEDSTABLE, vCAPHYDRONEW, vRETHYDROOLD, vCAPHYDROSTABLE,
            #              vCAPSTORNEW, vRETSTOROLD, vCAPSTORSTABLE, vCAPESTORNEW, vRETESTOROLD, vCAPESTORSTABLE,
            #              vNUMUCNEW, vNUMUCOLD, vNUMUCSTABLE, vUCBIN]
            # linecapdec = [vCAPNEWLINE, vCAPUPGLINE]
            if transcost_sens != "recodedupglinear"
                linecapdec = [vCAPNEWLINE, vCAPLINE]
            else
                linecapdec = [vCAPNEWLINE, vCAPLINE, vCAPUPGLINR]
            end
            othergenopr = [vCOMMIT, vSTARTUC, vSHUTUC, vCHARGE, vSOC, vRESUP, vRESDOWN, vGENDISPATCH]
            storres = [vCHARGERESUP, vDISCHARGERESUP, vCHARGERESDOWN, vDISCHARGERESDOWN]
            newlinevar = [vCAPNEWAC, vNUMNEWAC, vCAPNEWDC, vNUMNEWDC]
            # WriteResults(gencapdec, linecapdec, othergenopr, vFLOW, vNSE, storres)
            if region_scenario == "baseline"
                # @timeit to "write_to_CSV" begin RecordCSV(gencapdec, linecapdec, othergenopr, vFLOW, vNSE, storres, vCAPGEN, vCONT, newlinevar, vNUMUPDATE, vCAPUPDATE) end
                @timeit to "write_to_CSV" begin RecordCSV(gencapdec, linecapdec, othergenopr, vFLOW, vNSE, storres, vCAPGEN, newlinevar, vNUMUPDATE, vCAPUPDATE) end
            else
                # @timeit to "write_to_CSV" begin RecordCSV(gencapdec, linecapdec, othergenopr, vFLOW, vNSE, storres, vCAPGEN, vCONTREG, newlinevar, vNUMUPDATE, vCAPUPDATE) end
                @timeit to "write_to_CSV" begin RecordCSV(gencapdec, linecapdec, othergenopr, vFLOW, vNSE, storres, vCAPGEN, newlinevar, vNUMUPDATE, vCAPUPDATE) end
            end

            costs = DataFrame()
            if region_scenario == "baseline"
                cost_names = ["eFixCostGen", "eFixCostStor", "eFixCostLine", "eNewACCost", "eNewDCCost", "eACtoACUpgradeCost", "eACtoDCUpgradeCost_1",
                              "eACtoDCUpgradeCost_2", "eVarCostGen", "eNSECosts", "eStartCostUC", "eTransactionCost"]
                cost_values = [value.(eFixCostGen), value.(eFixCostStor), value.(eFixCostLine), value.(eNewACCost), value.(eNewDCCost), value.(eACtoACUpgradeCost),
                               value.(eACtoDCUpgradeCost_1), value.(eACtoDCUpgradeCost_2), value.(eVarCostGen), value.(eNSECosts), value.(eStartCostUC), value.(eTransactionCost)]
                costs.Component = cost_names
                costs.Values = cost_values
            else
                cost_names = ["eFixCostGen", "eFixCostStor", "eFixCostLine", "eNewACCost", "eNewDCCost", "eACtoACUpgradeCost", "eACtoDCUpgradeCost_1",
                              "eACtoDCUpgradeCost_2", "eVarCostGen", "eNSECosts", "eStartCostUC"]
                cost_values = [value.(eFixCostGen), value.(eFixCostStor), value.(eFixCostLine), value.(eNewACCost), value.(eNewDCCost), value.(eACtoACUpgradeCost),
                               value.(eACtoDCUpgradeCost_1), value.(eACtoDCUpgradeCost_2), value.(eVarCostGen), value.(eNSECosts), value.(eStartCostUC)]
                costs.Component = cost_names
                costs.Values = cost_values
            end
            CSV.write(string(resultpath, "cost_components.csv"), costs)

            var_for_bar = ["vCAPEDNEW_results.csv", "vRETEDOLD_results.csv", "vNUMUCNEW_results.csv", "vNUMUCOLD_results.csv",
                           "vCAPSTORNEW_results.csv", "vCAPESTORNEW_results.csv", "vRETSTOROLD_results.csv", "vRETESTOROLD_results.csv",
                           "newline_investment_results.csv", "vNUMUPDATE_results.csv", "vCAPUPDATE_results.csv", "allcap_aggregate.csv"]
            RecordPlot(var_for_bar, vNSE, vGENDISPATCH, vCHARGE)
            # hurdle_result = DataFrame(value.(vMINHURDLE).data, :auto)
            # insertcols!(hurdle_result, 1, :Index => first(axes(value.(vMINHURDLE))))
            # insertcols!(hurdle_result, 2, :Path => network.Transmission_Path_Name[hurdle_result.Index])
            # CSV.write(string(resultpath, "vMINHURDLE_results.csv"), hurdle_result)

        elseif termination_status(Expansion_Model) == MOI.INFEASIBLE || termination_status(Expansion_Model) == MOI.INFEASIBLE_OR_UNBOUNDED nothing # If the solution is infeasible
        else # If the solution is neither optimal nor infeasible, be warned
            println("#########################")
            println("Solution status is other than optimal, time limit, infeasible, and unbounded")
            println("#########################")
        end
    end

    # FixModel!(Expansion_Model)
    # optimize!(Expansion_Model)
    #
    # mydata = DataFrame()
    # mydata.MarginalVals = dual.(cPlanRes).data
    # CSV.write("/Users/Kucuksayacigil/Desktop/marginal_planning_reserve.csv", mydata)
end
