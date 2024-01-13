
function WriteResults(gencap, linecap, unitc, flowdec, unmetdec, stres)

    global pivot_new_energy
    global pivot_new_power
    global pivot_old_energy
    global pivot_old_power
    global pivot_stable_energy
    global pivot_stable_power

    global wdth = 0.2
    global fs = 18
    global dotperinch = 600

    for var in gencap
        if first(size(var)) != 0
            data = DataFrame()
            data.Index = first(axes(value.(var)))
            data.Zone = generators.zone[data.Index]
            data.Region = generators.region[data.Index] # [FK]
            data.Resource = generators.Resource[data.Index]
            data.OptValues = value.(var).data

            varname = first(split(name(var[first(data.Index)]), "["))

            if varname == "vCAPESTORNEW" || varname == "vRETESTOROLD" || varname == "vCAPESTORSTABLE"
                data.ExistingCap = generators.Existing_Cap_MWh[data.Index]
            else
                data.ExistingCap = generators.Existing_Cap_MW[data.Index]
            end

            if varname == "vNUMUCNEW" || varname == "vNUMUCOLD" || varname == "vNUMUCSTABLE"
                data.CapSize = generators.Cap_size[data.Index]
                if varname == "vNUMUCNEW"
                    data.NewCap = data.OptValues .* data.CapSize
                elseif varname == "vNUMUCOLD"
                    data.RetCap = data.OptValues .* data.CapSize
                else
                    nothing
                end
            end

            if varname == "vCAPESTORNEW" || varname == "vRETESTOROLD" || varname == "vCAPESTORSTABLE"
                pivot_optvalues = combine(groupby(data, [:Zone, :Region, :Resource]), :OptValues => sum => :OptEValues)
                pivot_existingcap = combine(groupby(data, [:Zone, :Region, :Resource]), :ExistingCap => sum => :ExistingECap)

                if varname == "vCAPESTORNEW"
                    pivot_new_energy = innerjoin(pivot_optvalues, pivot_existingcap, on = [:Zone, :Region, :Resource])
                elseif varname == "vRETESTOROLD"
                    pivot_old_energy = innerjoin(pivot_optvalues, pivot_existingcap, on = [:Zone, :Region, :Resource])
                elseif varname == "vCAPESTORSTABLE"
                    pivot_stable_energy = innerjoin(pivot_optvalues, pivot_existingcap, on = [:Zone, :Region, :Resource])
                else
                    nothing
                end
            elseif varname == "vCAPSTORNEW" || varname == "vRETSTOROLD" || varname == "vCAPSTORSTABLE"
                pivot_optvalues = combine(groupby(data, [:Zone, :Region, :Resource]), :OptValues => sum => :OptPValues)
                pivot_existingcap = combine(groupby(data, [:Zone, :Region, :Resource]), :ExistingCap => sum => :ExistingPCap)

                if varname == "vCAPSTORNEW"
                    pivot_new_power = innerjoin(pivot_optvalues, pivot_existingcap, on = [:Zone, :Region, :Resource])
                elseif varname == "vRETSTOROLD"
                    pivot_old_power = innerjoin(pivot_optvalues, pivot_existingcap, on = [:Zone, :Region, :Resource])
                elseif varname == "vCAPSTORSTABLE"
                    pivot_stable_power = innerjoin(pivot_optvalues, pivot_existingcap, on = [:Zone, :Region, :Resource])
                else
                    nothing
                end
            else
                pivot_optvalues = combine(groupby(data, [:Zone, :Region, :Resource]), :OptValues => sum => :OptValues)
                pivot_existingcap = combine(groupby(data, [:Zone, :Region, :Resource]), :ExistingCap => sum => :ExistingCap)

                if varname == "vNUMUCNEW" || varname == "vNUMUCOLD" || varname == "vNUMUCSTABLE"
                    pivot_capsize = combine(groupby(data, [:Zone, :Region, :Resource]), :CapSize => sum => :CapSize)

                    if varname == "vNUMUCNEW"
                        pivot_newcap = combine(groupby(data, [:Zone, :Region, :Resource]), :NewCap => sum => :NewCap)
                        pivotall = innerjoin(pivot_optvalues, pivot_existingcap, pivot_capsize, pivot_newcap, on = [:Zone, :Region, :Resource])
                    elseif varname == varname == "vNUMUCOLD"
                        pivot_retcap = combine(groupby(data, [:Zone, :Region, :Resource]), :RetCap => sum => :RetCap)
                        pivotall = innerjoin(pivot_optvalues, pivot_existingcap, pivot_capsize, pivot_retcap, on = [:Zone, :Region, :Resource])
                    else
                        pivotall = innerjoin(pivot_optvalues, pivot_existingcap, pivot_capsize, on = [:Zone, :Region, :Resource])
                    end
                else
                    pivotall = innerjoin(pivot_optvalues, pivot_existingcap, on = [:Zone, :Region, :Resource])
                end

                CSV.write(string(resultpath, varname, "_results.csv"), pivotall)
            end
        end
    end

    pivot_stor_allnew = innerjoin(pivot_new_power, pivot_new_energy, on = [:Zone, :Region, :Resource])
    CSV.write(string(resultpath, "storexpansion_results.csv"), pivot_stor_allnew)

    # if first(size(pivot_old_power)) != 0
    #     pivot_stor_allret = innerjoin(pivot_old_power, pivot_old_energy, on = [:Zone, :Region, :Resource])
    #     CSV.write(string(resultpath, "storretirement_results.csv"), pivot_stor_allret)
    # end

    if first(size(pivot_stable_power)) != 0
        pivot_stor_allstable = innerjoin(pivot_stable_power, pivot_stable_energy, on = [:Zone, :Region, :Resource])
        CSV.write(string(resultpath, "storstable_results.csv"), pivot_stor_allstable)
    end

    for var in linecap
        if first(size(var)) != 0
            data = DataFrame()
            data.Index = first(axes(value.(var)))
            data.Path = network.Transmission_Path_Name[data.Index]
            data.OptValues = value.(var).data

            varname = first(split(name(var[first(data.Index)]), "["))

            if varname == "vCAPUPGLINE"
                data.ExistingCap = network.Line_Max_Flow_MW[data.Index]
            end
            CSV.write(string(resultpath, varname, "_results.csv"), data)
        end
    end

    for var in unitc
        data = DataFrame(value.(var).data)
        insertcols!(data, 1, :Index => first(axes(value.(var))))
        insertcols!(data, 2, :Zone => generators.zone[first(axes(value.(var)))])
        insertcols!(data, 3, :Region => generators.region[first(axes(value.(var)))])
        insertcols!(data, 4, :Resource => generators.Resource[first(axes(value.(var)))])

        varname = first(split(name(var[first(first(axes(value.(var)))), 1]), "["))
        CSV.write(string(resultpath, varname, "_results.csv"), data)
    end

    flowdata = DataFrame(value.(flowdec).data)
    insertcols!(flowdata, 1, :Index => first(axes(value.(flowdec))))
    insertcols!(flowdata, 2, :Path => network.Transmission_Path_Name[flowdata.Index])
    CSV.write(string(resultpath, "vFLOW_results.csv"), flowdata)

    for row in 1:first(size(unmetdec))
        data = DataFrame(value.(unmetdec).data[row,:,:])
        insertcols!(data, 1, :Index => first(axes(value.(unmetdec)[row,:,:])))
        CSV.write(string(resultpath, string("vNSE", row), ".csv"), data)
    end

    for var in stres
        data = DataFrame(value.(var).data)
        insertcols!(data, 1, :Index => first(axes(value.(var))))
        insertcols!(data, 2, :Zone => generators.zone[first(axes(value.(var)))])
        insertcols!(data, 3, :Region => generators.region[first(axes(value.(var)))])
        insertcols!(data, 4, :Resource => generators.Resource[first(axes(value.(var)))])

        varname = first(split(name(var[first(first(axes(value.(var)))), 1]), "["))
        CSV.write(string(resultpath, varname, "_results.csv"), data)
    end

    # Since there is only one unit commitment resource which is not retirable, I do not create its plot
    # requiredplots = ["vCAPEDNEW_results.csv", "vRETEDOLD_results.csv", "storexpansion_results.csv", "storretirement_results.csv",
    #                  "storstable_results.csv", "vNUMUCNEW_results.csv", "vNUMUCOLD_results.csv", "vCAPEDSTABLE_results.csv"]
    requiredplots = ["vCAPEDNEW_results.csv", "storexpansion_results.csv",
                     "storstable_results.csv", "vNUMUCNEW_results.csv", "vNUMUCOLD_results.csv", "vCAPEDSTABLE_results.csv"]

    for filename in requiredplots
        resultdata = CSV.read(string(resultpath, filename), DataFrame)

        barnames = String[]

        ind = collect(1:first(size(resultdata)))
        # fig = figure("pyplot_barplot", figsize = (15, 8))
        fig = figure(figsize = (20, 12))

        if filename == "vCAPEDNEW_results.csv"
            for row in eachrow(resultdata)
               push!(barnames, string(row.Region, "_", first(split(row.Resource, "_"))))
            end
            bar(ind, resultdata.OptValues, width = wdth, color = "red")
            title("Capacity Expansion for ED Units", fontsize = fs)
        elseif filename == "vRETEDOLD_results.csv"
            for row in eachrow(resultdata)
               push!(barnames, string(row.Region, "_", row.Resource))
            end
            bar(ind, resultdata.OptValues, width = wdth, color = "red")
            bar(ind .+ wdth, resultdata.ExistingCap, width = wdth, color = "blue")
            title("Retirement for ED Units", fontsize = fs)
            legend(["Retirement", "Existing"], fontsize = fs, frameon = false)
        elseif filename == "storexpansion_results.csv"
            for row in eachrow(resultdata)
               push!(barnames, string(row.Region, "_", first(split(row.Resource, "_"))))
            end
            bar(ind, resultdata.OptPValues, width = wdth, color = "red")
            title("Capacity Expansion for STOR Units", fontsize = fs)
        elseif filename == "storretirement_results.csv"
            for row in eachrow(resultdata)
               push!(barnames, string(row.Region, "_", row.Resource))
            end
            bar(ind, resultdata.OptPValues, width = wdth, color = "red")
            bar(ind .+ wdth, resultdata.ExistingPCap, width = wdth, color = "blue")
            title("Retirement for STOR Units", fontsize = fs)
            legend(["Retirement", "Existing"], fontsize = fs, frameon = false)
        elseif filename == "storstable_results.csv"
            for row in eachrow(resultdata)
               push!(barnames, string(row.Region, "_", row.Resource))
            end
            # bar(ind, resultdata.OptPValues, width = wdth, color = "red")
            # bar(ind .+ wdth, resultdata.ExistingPCap, width = wdth, color = "blue")
            bar(ind, resultdata.ExistingPCap, width = wdth, color = "blue")
            title("Non-retired STOR Units", fontsize = fs)
            # legend(["Retirement", "Existing"], fontsize = fs, frameon = false)
            legend(["Existing"], fontsize = fs, frameon = false)
        elseif filename == "vNUMUCNEW_results.csv"
            for row in eachrow(resultdata)
               push!(barnames, string(row.Region, "_", split(row.Resource, "_")[1], "_", split(row.Resource, "_")[2]))
            end
            bar(ind, resultdata.NewCap, width = wdth, color = "red")
            title("Capacity Expansion for UC Units", fontsize = fs)
        elseif filename == "vNUMUCOLD_results.csv"
            for row in eachrow(resultdata)
               push!(barnames, string(row.Region, "_", row.Resource))
            end
            bar(ind, resultdata.RetCap, width = wdth, color = "red")
            bar(ind .+ wdth, resultdata.ExistingCap, width = wdth, color = "blue")
            title("Retirement for UC Units", fontsize = fs)
            legend(["Retirement", "Existing"], fontsize = fs, frameon = false)
        elseif filename == "vCAPEDSTABLE_results.csv"
            for row in eachrow(resultdata)
               push!(barnames, string(row.Region, "_", row.Resource))
            end
            # bar(ind, resultdata.OptValues, width = wdth, color = "red")
            # bar(ind .+ wdth, resultdata.ExistingCap, width = wdth, color = "blue")
            bar(ind, resultdata.ExistingCap, width = wdth, color = "blue")
            title("Non-retired ED Units", fontsize = fs)
            # legend(["Retirement", "Existing"], fontsize = fs, frameon = false)
            legend(["Existing"], fontsize = fs, frameon = false)
        else
            nothing
        end
        # grid("on")
        axis("tight")
        ylabel("MW", fontsize = fs)
        xlabel("Resources", fontsize = fs)
        ylim(bottom = 0)
        xticks(fontsize = 10, rotation = 90)
        yticks(fontsize = fs)
        xticks(ind .+ wdth / 2, barnames)
        fig.subplots_adjust(bottom = 0.40)
        fig.savefig(string(resultpath, first(split(filename, ".")), ".pdf"), dpi = dotperinch)
        close(fig)
    end

    disvar = last(unitc)
    solution = DataFrame(disvar.data)
    ax1 = disvar.axes[1]
    ax2 = disvar.axes[2]
    cols = names(solution)
    insertcols!(solution, 1, :R_ID => ax1)
    solution = stack(solution, Not(:R_ID), variable_name = :Hour, value_name = :Dispatch)

    numresults = []
    for i in 1:first(size(solution))
        push!(numresults, value.(solution[i,:Dispatch]))
    end

    solution.DispatchNum = numresults
    select!(solution, Not(:Dispatch))

    solution.Hour = foldl(replace, [cols[i] => ax2[i] for i in 1:length(ax2)], init = solution.Hour)
    solution.Hour = convert.(Int64, solution.Hour)

    sol_gen = innerjoin(solution, generators[!, [:R_ID, :Resource]], on = :R_ID)
    sol_gen = combine(groupby(sol_gen, [:Resource, :Hour]), :DispatchNum => sum)

    dis_long = unstack(sol_gen, :Resource, :DispatchNum_sum)

    CSV.write(string(resultpath, "dispatch_raw.csv"), dis_long)

    # sol_gen |> @vlplot(:area, width = 1200, height = 800, x = :Hour, y = :DispatchNum_sum, color = {:Resource, scale = {scheme = "category20b"}}) |> display

    # <editor-fold Aggregation of dispatch_raw>
    solar_list = ["csp", "commpv", "respv", "utilitypv", "solar"]
    wind_list = ["wind"]
    geo_list = ["geothermal"]
    hydro_list = ["conventional_hydroelectric", "small_hydroelectric"]
    coal_list = ["coal"]
    natural_list = ["natural"]
    nuclear_list = ["nuclear"]
    biomass_list = ["bio"]
    battery_list = ["batter"]
    hydropump_list = ["pumped"]
    other_list = ["other_peaker", "other_gases"]

    totallist = [solar_list, wind_list, geo_list, hydro_list, coal_list, natural_list, nuclear_list, biomass_list, battery_list, hydropump_list, other_list]

    aggregated_dispatch = DataFrame()
    for indlist in totallist
        total = zeros(first(size(dis_long)))
        for name in indlist
            index = findall(t -> occursin(string(name), t), names(dis_long))
            if length(index) == 1
                total = total + dis_long[:,first(index)]
            elseif length(index) > 1
                sumall = sum(eachcol(dis_long[:,index]))
                total = total + sumall
            else
                nothing
            end
        end
        if first(indlist) == "csp"
            aggregated_dispatch.Solar = total
        elseif first(indlist) == "wind"
            aggregated_dispatch.Wind = total
        elseif first(indlist) == "geothermal"
            aggregated_dispatch.Geothermal = total
        elseif first(indlist) == "conventional_hydroelectric"
            aggregated_dispatch.Hydro = total
        elseif first(indlist) == "coal"
            aggregated_dispatch.Coal = total
        elseif first(indlist) == "natural"
            aggregated_dispatch.Natural = total
        elseif first(indlist) == "nuclear"
            aggregated_dispatch.Nuclear = total
        elseif first(indlist) == "bio"
            aggregated_dispatch.Biomass = total
        elseif first(indlist) == "batter"
            aggregated_dispatch.Battery = total
        elseif first(indlist) == "pumped"
            aggregated_dispatch.Hydropumped = total
        elseif first(indlist) == "other_peaker"
            aggregated_dispatch.Other = total
        else
            nothing
        end
    end

    CSV.write(string(resultpath, "dispatch_agg.csv"), aggregated_dispatch)
    # </editor-fold>

    scriptdir = @__DIR__
    pushfirst!(PyVector(pyimport("sys")."path"), scriptdir)
    pyimportjulia = pyimport("DispatchPlot")
    pyimportjulia.PlotDispatch(resultpath)

    sumnse = zeros(size(unmetdec)[2], last(size(unmetdec)))
    for row in 1:first(size(unmetdec))
        sumnse = sumnse + value.(unmetdec).data[row,:,:]
    end

    fig = figure(figsize = (20, 12))
    for seg in 1:size(unmetdec)[2]
        plot(sumnse[seg,:])
    end
    title("Non-served energy amount over all regions", fontsize = fs)
    xlabel("Hours", fontsize = fs)
    ylabel("MW", fontsize = fs)
    xticks(fontsize = fs)
    yticks(fontsize = fs)
    legend(["Segment 1", "Segment 2"], frameon = false, fontsize = fs) # You can change this to an arbitrary number of segments
    fig.savefig(string(resultpath, "nonserved.pdf"), dpi = dotperinch)
    close(fig)
end
