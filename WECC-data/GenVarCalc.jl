
function GenVar()

    resnames = ["onshore_wind", "offshorewind", "landbasedwind", "solar_photovoltaic", "utilitypv", "conventional_hydroelectric", "small_hydroelectric"]
    returned_resource = []

    for rname in resnames

        relcols = findall(t -> occursin(rname, t), names(genvar))

        zones = String[]
        for str in names(genvar)[relcols]
            zone, cluster = first(split(str, "_")), last(split(str, "_"))
            push!(zones, string(zone, "_", cluster))
        end

        varsum = sum.(eachcol(genvar[:,relcols] .* sample_weight))
        weightedvar = DataFrame()
        weightedvar.Zones = zones
        weightedvar.GenVar = varsum / sum(sample_weight)

        CSV.write(string(powergenome_output_path, rname, ".csv"), weightedvar)
        if rname == "offshorewind" || rname == "landbasedwind" || rname == "utilitypv"
            push!(returned_resource, weightedvar)
        else
            nothing
        end
    end
    
    return returned_resource
end
