setEDNEWGEN = generators[(generators.STOR .== 0) .& (generators.Commit .== 0) .& (generators.LHYDRO .== 0) .& (generators.New_Build .== 1), :R_ID] # Set of economic dispatch generators to be build
setEDOLDGEN = generators[(generators.STOR .== 0) .& (generators.Commit .== 0) .& (generators.LHYDRO .== 0) .& (generators.New_Build .== 0), :R_ID] # Set of economic dispatch generators available for retirement
setEDSTABLEGEN = generators[(generators.STOR .== 0) .& (generators.Commit .== 0) .& (generators.LHYDRO .== 0) .& (generators.New_Build .== -1), :R_ID] # Set of economic dispatch generators with constant capacity

setLHYDRONEW = generators[(generators.STOR .== 0) .& (generators.Commit .== 0) .& (generators.LHYDRO .== 1) .& (generators.New_Build .== 1), :R_ID] # Set of economic dispatch generators to be build
setLHYDROOLD = generators[(generators.STOR .== 0) .& (generators.Commit .== 0) .& (generators.LHYDRO .== 1) .& (generators.New_Build .== 0), :R_ID] # Set of economic dispatch generators available for retirement
setLHYDROSTABLE = generators[(generators.STOR .== 0) .& (generators.Commit .== 0) .& (generators.LHYDRO .== 1) .& (generators.New_Build .== -1), :R_ID] # Set of economic dispatch generators with constant capacity

setSHYDRONEW = generators[(generators.STOR .== 0) .& (generators.Commit .== 0) .& (generators.SHYDRO .== 1) .& (generators.New_Build .== 1), :R_ID] # Set of economic dispatch generators to be build
setSHYDROOLD = generators[(generators.STOR .== 0) .& (generators.Commit .== 0) .& (generators.SHYDRO .== 1) .& (generators.New_Build .== 0), :R_ID] # Set of economic dispatch generators available for retirement
setSHYDROSTABLE = generators[(generators.STOR .== 0) .& (generators.Commit .== 0) .& (generators.SHYDRO .== 1) .& (generators.New_Build .== -1), :R_ID] # Set of economic dispatch generators with constant capacity

setUCNEWGEN = generators[(generators.STOR .== 0) .& (generators.Commit .== 1) .& (generators.New_Build .== 1), :R_ID] # Set of unit commitment generators to be build
setUCOLDGEN = generators[(generators.STOR .== 0) .& (generators.Commit .== 1) .& (generators.New_Build .== 0), :R_ID] # Set of unit commitment generators available for retirement
setUCSTABLEGEN = generators[(generators.STOR .== 0) .& (generators.Commit .== 1) .& (generators.New_Build .== -1), :R_ID] # Set of unit commitment generators with constant capacity

setSTORNEW = generators[(generators.STOR .>= 1) .& (generators.Commit .== 0) .& (generators.New_Build .== 1), :R_ID] # Set of storages to be build
setSTOROLD = generators[(generators.STOR .>= 1) .& (generators.Commit .== 0) .& (generators.New_Build .== 0), :R_ID] # Set of storages available for retirement
setSTORSTABLE = generators[(generators.STOR .>= 1) .& (generators.Commit .== 0) .& (generators.New_Build .== -1), :R_ID] # Set of storages with constant capacity

setBATTERYOLD = generators[(generators.BATTERY .== 1) .& (generators.New_Build .== 0), :R_ID]
setPUMPEDOLD = generators[(generators.PUMPED .== 1) .& (generators.New_Build .== 0), :R_ID]
setFLYOLD = generators[(generators.FLYWHEEL .== 1) .& (generators.New_Build .== 0), :R_ID]
setTHERMALSTOROLD = generators[(generators.THERMALSTOR .== 1) .& (generators.New_Build .== 0), :R_ID]

# setGEN = union(setEDNEWGEN, setEDOLDGEN, setEDSTABLEGEN, setUCNEWGEN, setUCOLDGEN, setUCSTABLEGEN, setSTORNEW, setSTOROLD, setSTORSTABLE) # Set of all generators
setGEN = union(setEDNEWGEN, setEDOLDGEN, setEDSTABLEGEN, setLHYDRONEW, setLHYDROOLD, setLHYDROSTABLE,
               setUCNEWGEN, setUCOLDGEN, setUCSTABLEGEN, setSTORNEW, setSTOROLD, setSTORSTABLE) # Set of all generators
setSTOR = union(setSTORNEW, setSTOROLD, setSTORSTABLE) # Set of all storages
setLHYDRO = union(setLHYDRONEW, setLHYDROOLD, setLHYDROSTABLE)
setSHYDRO = union(setSHYDRONEW, setSHYDROOLD, setSHYDROSTABLE)
# setGENSTOR = setdiff(setGEN, union(setUCNEWGEN, setUCOLDGEN, setUCSTABLEGEN)) # Set of economic dispatch units and storages
setGENSTOR = setdiff(setGEN, union(setUCNEWGEN, setUCOLDGEN, setUCSTABLEGEN, setLHYDRO)) # Set of economic dispatch units and storages
setUC = union(setUCNEWGEN, setUCOLDGEN, setUCSTABLEGEN) # Set of all unit commitment generators

setTIME = demand.Time_Index # Set of time periods/hours
temp_segment = collect(skipmissing(demand.Demand_segment)) # Set of demand segment

setSEGMENT = []
for i in 1:first(size(temp_segment))
    push!(setSEGMENT, Int(temp_segment[i]))
end

setZONE = unique(generators.Zone) # Set of zones
setLINE = collect(1:first(size(network))) # Set of all transmission lines (existing plus new right of ways)
setOLDLINE = network[network.NewOld .== "old", :Network_Lines]
setNEWLINE = network[network.NewOld .== "new", :Network_Lines]

# Determine the set of lines for which hurdle is 0
subnetwork = select(network, reg_zone.Network_zones)
insertcols!(subnetwork, 1, :Network_Lines => network.Network_Lines)

hurdle0_regions = ["NorCal", "SD_IID", "SoCal"]
hurdle0_zones = []

for x in hurdle0_regions
    # push!(hurdle0_zones, first(region_zone[region_zone.Region_description .== x, :Network_zones]))
    push!(hurdle0_zones, first(reg_zone[reg_zone.Region_description .== x, :Network_zones]))
end

hurdle0_lines = []
for z in collect(1:length(hurdle0_zones))
    for y in collect(z+1:length(hurdle0_zones))
        append!(hurdle0_lines, subnetwork[((subnetwork[!, hurdle0_zones[z]] .== 1) .& (subnetwork[!, hurdle0_zones[y]] .== -1)) .|
               ((subnetwork[!, hurdle0_zones[z]] .== -1) .& (subnetwork[!, hurdle0_zones[y]] .== 1)), :Network_Lines])
    end
end

setSTARTS = 1:hours_per_period:maximum(setTIME) # Set of time periods indicating a period starts
setINTERIORS = setdiff(setTIME, setSTARTS) # Set of time periods within a period

setRENEW = generators[generators.RENEW .== 1, :R_ID]
setCES = generators[generators.CES .== 1, :R_ID]
setNONDISP = generators[generators.NONDISP .== 1, :R_ID]
setNONDISPRENEW =  intersect(setRENEW, setNONDISP)
setNONUCDISP = generators[(generators.Commit .== 0) .& (generators.NONDISP .== 0), :R_ID]

contn1 = []
for z in setZONE
    olduc_region = intersect(union(setUCOLDGEN, setUCSTABLEGEN), generators[generators.Zone .== z, :R_ID])
    maxuc = maximum(generators[olduc_region, :Cap_Size])

    oldlines = network[network.NewOld .== "old", :]
    oldlines_region = oldlines[(oldlines[!, string("z", z)] .== 1) .| (oldlines[!, string("z", z)] .== -1), :Network_Lines]
    maxvoltage = "blank"
    maxline = 0
    for x in ["TwoH_AC", "ThreeH_AC", "FiveH_AC"]
        voltage_count_region = voltage_count[oldlines_region, :]
        if sum(voltage_count_region[!, x]) >= 1
            maxvoltage = x
        end
        maxline = first(voltage_cap[voltage_cap.Voltages .== maxvoltage, :Capacity])
    end

    possibleuc = first(findall(t -> occursin("naturalgas_cc", t), generators.technology))
    maxnewuc = generators[possibleuc, :Cap_Size]

    push!(contn1, maximum([maxuc, maxline, maxnewuc]))
end

maxuc_regional = maximum(generators[union(setUCOLDGEN, setUCSTABLEGEN), :Cap_Size])
maxline_regional = 0
for x in ["TwoH_AC", "ThreeH_AC", "FiveH_AC"]
    if sum(voltage_count[!, x]) >= 1
        maxvoltage = x
    end
    maxline_regional = first(voltage_cap[voltage_cap.Voltages .== maxvoltage, :Capacity])
end
maxnewuc_regional = generators[first(findall(t -> occursin("naturalgas_cc", t), generators.technology)), :Cap_Size]
contn1_regional = maximum([maxuc_regional, maxline_regional, maxnewuc_regional])
