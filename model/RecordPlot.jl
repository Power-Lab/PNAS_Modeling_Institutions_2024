
function RecordPlot(varforbar, unmetdec, poweramount, chargeamount)

   for filename in varforbar[1:4]

      optresult = CSV.read(string(resultpath, filename), DataFrame)
      filter!(row -> (row.OptValues > 0),  optresult)
      ind = collect(1:first(size(optresult)))

      barnames = String[]
      for row in eachrow(optresult)
         if filename == "vNUMUCNEW_results.csv" || filename == "vNUMUCOLD_results.csv"
            push!(barnames, string(row.Region, "_", first(split(row.Resource, "_")), split(row.Resource, "_")[2]))
         else
            push!(barnames, string(row.Region, "_", first(split(row.Resource, "_"))))
         end
      end

      if filename == "vNUMUCNEW_results.csv" || filename == "vNUMUCOLD_results.csv"
         ylabb = "Number of units"
      else
         ylabb = "MW"
      end

      if filename == "vCAPEDNEW_results.csv"
         tit = "Capacity Expansion for ED Units"
      elseif filename == "vRETEDOLD_results.csv"
         tit = "Retirement for ED Units"
      elseif filename == "vNUMUCNEW_results.csv"
         tit = "Capacity Expansion for UC Units"
      elseif filename == "vNUMUCOLD_results.csv"
         tit = "Retirement for UC Units"
      else
         nothing
      end

      CreateBarLine(isbarplot = true,
                    fname = filename,
                    barnumbers = ind,
                    plotvalues_one = optresult.OptValues,
                    plotvalues_two = nothing,
                    barnam = barnames,
                    ylab = ylabb,
                    xlab = "Resources",
                    tlab = tit,
                    leglab = nothing,
                    rpath = resultpath)

      if filename == "vNUMUCNEW_results.csv"
         CreateBarLine(isbarplot = true,
                       fname = "newucmw.csv",
                       barnumbers = ind,
                       plotvalues_one = optresult.MW,
                       plotvalues_two = nothing,
                       barnam = barnames,
                       ylab = "MW",
                       xlab = "Resources",
                       tlab = tit,
                       leglab = nothing,
                       rpath = resultpath)
      elseif filename == "vNUMUCOLD_results.csv"
         CreateBarLine(isbarplot = true,
                       fname = "olducmw.csv",
                       barnumbers = ind,
                       plotvalues_one = optresult.MW,
                       plotvalues_two = nothing,
                       barnam = barnames,
                       ylab = "MW",
                       xlab = "Resources",
                       tlab = tit,
                       leglab = nothing,
                       rpath = resultpath)
      else
         nothing
      end
   end


   stor_exp_mw = CSV.read(string(resultpath, varforbar[5]), DataFrame)
   rename!(stor_exp_mw, :OptValues => :Power)
   stor_exp_mwh = CSV.read(string(resultpath, varforbar[6]), DataFrame)
   rename!(stor_exp_mwh, :OptValues => :Energy)
   stor_allnew = innerjoin(stor_exp_mw, stor_exp_mwh, on = [:Zone, :Region, :Resource], makeunique = true)
   filter!(row -> (row.Power > 0),  stor_allnew)
   ind_stor_new = collect(1:first(size(stor_allnew)))

   barnames = String[]
   for row in eachrow(stor_allnew)
      push!(barnames, string(row.Region, "_", first(split(row.Resource, "_"))))
   end

   CreateBarLine(isbarplot = true,
                 fname = "storage_expansion.csv",
                 barnumbers = ind_stor_new,
                 plotvalues_one = stor_allnew.Power,
                 plotvalues_two = stor_allnew.Energy,
                 barnam = barnames,
                 ylab = "MW or MWh",
                 xlab = "Resources",
                 tlab = "Capacity Expansion for STOR Units",
                 leglab = ["Power", "Energy"],
                 rpath = resultpath)


   stor_ret_mw = CSV.read(string(resultpath, varforbar[7]), DataFrame)
   rename!(stor_ret_mw, :OptValues => :Power)
   stor_ret_mwh = CSV.read(string(resultpath, varforbar[8]), DataFrame)
   rename!(stor_ret_mwh, :OptValues => :Energy)
   stor_allret = innerjoin(stor_ret_mw, stor_ret_mwh, on = [:Zone, :Region, :Resource], makeunique = true)
   filter!(row -> (row.Power > 0),  stor_allret)
   ind_stor_ret = collect(1:first(size(stor_allret)))

   barnames = String[]
   for row in eachrow(stor_allret)
      push!(barnames, string(row.Region, "_", first(split(row.Resource, "_"))))
   end

   CreateBarLine(isbarplot = true,
                 fname = "storage_retirement.csv",
                 barnumbers = ind_stor_ret,
                 plotvalues_one = stor_allret.Power,
                 plotvalues_two = stor_allret.Energy,
                 barnam = barnames,
                 ylab = "MW or MWh",
                 xlab = "Resource",
                 tlab = "Retirement for STOR Units",
                 leglab = ["Power", "Energy"],
                 rpath = resultpath)


   sumnse = zeros(size(unmetdec)[2], last(size(unmetdec)))
   for row in 1:first(size(unmetdec))
      sumnse = sumnse + value.(unmetdec).data[row,:,:]
   end

   for seg in 1:size(unmetdec)[2]
      CreateBarLine(isbarplot = false,
                    fname = string("nonserved", seg, ".csv"),
                    barnumbers = nothing,
                    plotvalues_one = sumnse[seg,:],
                    plotvalues_two = nothing,
                    barnam = nothing,
                    ylab = "MW",
                    xlab = "Hours",
                    tlab = string("Non-served energy amount over all regions in segment ", seg),
                    leglab = nothing,
                    rpath = resultpath)
   end

   allcap_aggregate = CSV.read(string(resultpath, varforbar[9]), DataFrame)

   for rname in region_names
      CreateBarLine(isbarplot = true,
                   fname = string(rname, "_finalcap.csv"),
                   barnumbers = collect(1:first(size(allcap_aggregate))),
                   plotvalues_one = allcap_aggregate[!, rname],
                   plotvalues_two = nothing,
                   barnam = allcap_aggregate.Types,
                   ylab = "MW",
                   xlab = "Resources",
                   tlab = "Final Capacity",
                   leglab = nothing,
                   rpath = resultpath)
   end

   ProcessDispatch(poweramount, chargeamount)

end
