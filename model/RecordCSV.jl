
# function RecordCSV(gencap, linecap, unitc, flowdec, unmetdec, stres, allcap, conting, newlv, pickchange, powerchange)
function RecordCSV(gencap, linecap, unitc, flowdec, unmetdec, stres, allcap, newlv, pickchange, powerchange)

    for var in gencap
        if first(size(var)) != 0
            data = DataFrame()
            data.Index = first(axes(value.(var)))
            data.Zone = generators.Zone[data.Index]
            data.Region = generators.region[data.Index]
            data.Resource = generators.technology[data.Index]
            data.OptValues = value.(var).data

            varname = first(split(name(var[first(data.Index)]), "["))

            if varname == "vNUMUCNEW" || varname == "vNUMUCOLD"
                data.MW = generators.Cap_Size[data.Index] .* data.OptValues
            else
                nothing
            end

            CSV.write(string(resultpath, varname, "_results.csv"), data)
        end
    end

    for var in linecap
        if first(size(var)) != 0
            data = DataFrame()
            data.Index = first(axes(value.(var)))
            data.Path = network.transmission_path_name[data.Index]
            data.OptValues = value.(var).data

            varname = first(split(name(var[first(data.Index)]), "["))

            CSV.write(string(resultpath, varname, "_results.csv"), data)
        end
    end

    for var in unitc
        data = DataFrame(value.(var).data, :auto)
        insertcols!(data, 1, :Index => first(axes(value.(var))))
        insertcols!(data, 2, :Zone => generators.Zone[first(axes(value.(var)))])
        insertcols!(data, 3, :Region => generators.region[first(axes(value.(var)))])
        insertcols!(data, 4, :Resource => generators.technology[first(axes(value.(var)))])

        varname = first(split(name(var[first(first(axes(value.(var)))), 1]), "["))
        CSV.write(string(resultpath, varname, "_results.csv"), data)
    end

    flowdata = DataFrame(value.(flowdec).data, :auto)
    insertcols!(flowdata, 1, :Index => first(axes(value.(flowdec))))
    insertcols!(flowdata, 2, :Path => network.transmission_path_name[flowdata.Index])
    CSV.write(string(resultpath, "vFLOW_results.csv"), flowdata)

    for row in 1:first(size(unmetdec))
        data = DataFrame(value.(unmetdec).data[row,:,:], :auto)
        insertcols!(data, 1, :Index => first(axes(value.(unmetdec)[row,:,:])))
        CSV.write(string(resultpath, string("vNSE", row), ".csv"), data)
    end

    for var in stres
        data = DataFrame(value.(var).data, :auto)
        insertcols!(data, 1, :Index => first(axes(value.(var))))
        insertcols!(data, 2, :Zone => generators.Zone[first(axes(value.(var)))])
        insertcols!(data, 3, :Region => generators.region[first(axes(value.(var)))])
        insertcols!(data, 4, :Resource => generators.technology[first(axes(value.(var)))])

        varname = first(split(name(var[first(first(axes(value.(var)))), 1]), "["))
        CSV.write(string(resultpath, varname, "_results.csv"), data)
    end

    allcap_data = DataFrame()
    allcap_data.R_ID = first(axes(value.(allcap)))
    allcap_data.Zone = generators.Zone[allcap_data.R_ID]
    allcap_data.Region = generators.region[allcap_data.R_ID]
    allcap_data.Resource = generators.technology[allcap_data.R_ID]
    allcap_data.NOS = generators.New_Build[allcap_data.R_ID]
    allcap_data.OptValues = value.(allcap).data
    CSV.write(string(resultpath, "allcap.csv"), allcap_data)

    # allcap_res = CSV.read(string(resultpath, varforbar[12]), DataFrame)
    # rename!(allcap_res, :Index => :R_ID)
    # colnames = [:R_ID, :STOR, :SOLAR, :BIOPOWER, :COAL, :GEOTHERMAL, :WIND, :NATURAL, :HYDRO, :NUCLEAR, :OTHER] # Create common column names
    colnames = [:R_ID, :STOR, :SOLAR, :BIOPOWER, :NONCCS_COAL, :CCS_COAL, :GEOTHERMAL, :WIND, :NONCCS_GAS, :CCS_GAS, :HYDRO, :NUCLEAR, :OTHER] # Create common column names
    allcap_res = innerjoin(allcap_data, generators[!, colnames], on = :R_ID) # Add Resource, region and label information from generators.csv (merge on R_ID)

    allcap_aggregate = DataFrame()
    for rname in region_names
        temp = []
        for agn in colnames[2:end]
            push!(temp, sum(allcap_res[(allcap_res.Region .== rname) .& (allcap_res[!, agn] .== 1), :OptValues]))
        end
        allcap_aggregate[!,rname] = temp
    end
    insertcols!(allcap_aggregate, 1, :Types => colnames[2:end])
    CSV.write(string(resultpath, "allcap_aggregate.csv"), allcap_aggregate)

    # contingency = DataFrame()
    # if length(value.(conting).data) > 1
    #     contingency.Index = first(axes(value.(conting)))
    #     contingency.OptValues = value.(conting).data
    # elseif length(value.(conting).data) == 1
    #     contingency.OptValues = [value.(conting).data]
    # else
    #     nothing
    # end
    # if region_scenario == "baseline"
    #     contingency.Index = first(axes(value.(conting)))
    #     contingency.OptValues = value.(conting).data
    # elseif region_scenario == "expandedEIM" || region_scenario == "regionalized"
    #     contingency.OptValues = [value.(conting)]
    # else
    #     nothing
    # end
    # CSV.write(string(resultpath, "contingency.csv"), contingency)

    newlineinv = DataFrame()
    for (index, var) in enumerate(newlv)

        if index == 1
            newlineinv.Index = first(axes(value.(var)))
            newlineinv.Path = network.transmission_path_name[newlineinv.Index]
        else
            nothing
        end

        varname = first(split(name(var[first(newlineinv.Index)]), "["))
        if varname == "vCAPNEWAC"
            newlineinv.vCAPNEWAC = value.(var).data
        elseif varname == "vNUMNEWAC"
            newlineinv.vNUMNEWAC = value.(var).data
        elseif varname == "vCAPNEWDC"
            newlineinv.vCAPNEWDC = value.(var).data
        elseif varname == "vNUMNEWDC"
            newlineinv.vNUMNEWDC = value.(var).data
        else
            nothing
        end
    end
    CSV.write(string(resultpath, "newline_investment_results.csv"), newlineinv)

    # pickres = findall(==(1), value.(pickchange).data)
    # pickres = findall(>=(1), value.(pickchange).data)
    pickres = findall(>(0), value.(pickchange).data)
    if first(size(pickres)) > 0
        pickresults = DataFrame(Line = pickres[1][1], FromVol = pickres[1][2], ToVol = pickres[1][3], OptVal = [value.(pickchange).data[pickres[1]]])
        for row in 2:first(size(pickres))
            push!(pickresults, [pickres[row][1] pickres[row][2] pickres[row][3] [value.(pickchange).data[pickres[row]]]])
        end
        pickresults.Path = network.transmission_path_name[pickresults.Line]
        CSV.write(string(resultpath, "vNUMUPDATE_results.csv"), pickresults)
    else
        nothing
    end

    powerres = findall(>(0.0001), value.(powerchange).data)
    if first(size(powerres)) > 0
        powerresults = DataFrame(Line = powerres[1][1], FromVol = powerres[1][2], ToVol = powerres[1][3], OptVal = [value.(powerchange).data[powerres[1]]])
        for row in 2:first(size(powerres))
            push!(powerresults, [powerres[row][1] powerres[row][2] powerres[row][3] [value.(powerchange).data[powerres[row]]]])
        end
        powerresults.Path = network.transmission_path_name[powerresults.Line]
        CSV.write(string(resultpath, "vCAPUPDATE_results.csv"), powerresults)
    else
        nothing
    end

    # Calculate CO2 emission amount
    dispatch_result = CSV.read(string(resultpath, "vGENDISPATCH_results.csv"), DataFrame)
    start_result = CSV.read(string(resultpath, "vSTARTUC_results.csv"), DataFrame)

    sort!(dispatch_result, :Index)
    sorted_dispatch = copy(dispatch_result)
    dispatch_renew = dispatch_result[generators[generators.RENEW .== 1, :R_ID],:]

    co2_start = generators.CO2_Per_Start[start_result.Index]
    capsize = generators.Cap_Size[start_result.Index]

    select!(dispatch_result, Not([:Index,:Zone,:Region,:Resource]))
    select!(start_result, Not([:Index,:Zone,:Region,:Resource]))
    select!(dispatch_renew, Not([:Index,:Zone,:Region,:Resource]))

    co2_amount = sum((sum.(eachcol(generators.CO2_Rate .* dispatch_result)) + sum.(eachcol(co2_start .* (capsize .* start_result)))) .* sample_weight)
    renew_share = sum(sum.(eachcol(dispatch_renew)) .* sample_weight) / sum(sum.(eachcol(dispatch_result)) .* sample_weight)

    environment = DataFrame()
    environment.CO2 = [co2_amount]
    environment.Renew_Share = [renew_share]
    CSV.write(string(resultpath, "environment.csv"), environment)

    select!(sorted_dispatch, Not([:Index, :Zone, :Region, :Resource]))
    sort!(allcap_res, [:R_ID])

    final_curtailment = DataFrame()
    for agn in [:SOLAR, :WIND]
        currate = []
        for rname in region_names
            finalcap = allcap_res[(allcap_res.Region .== rname) .& (allcap_res[!, agn] .== 1) .& (allcap_res.OptValues .> 0), [:R_ID, :OptValues]]
            if first(size(finalcap)) != 0
                potentials = finalcap.OptValues' .* genvar[:, finalcap.R_ID]
                subdis = Matrix(sorted_dispatch[finalcap.R_ID, :])'
                weighted_cur = ((potentials .- subdis) ./ potentials) .* sample_weight
                for col in eachcol(weighted_cur) replace!(col, NaN => 0) end
                push!(currate, mean(sum.(eachcol(weighted_cur)) / sum(sample_weight)))
            else
                push!(currate, missing)
            end
        end
        final_curtailment[!, agn] = currate
    end
    insertcols!(final_curtailment, 1, :Region => region_names)
    CSV.write(string(resultpath, "final_curtailment.csv"), final_curtailment)
end
