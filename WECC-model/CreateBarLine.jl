
function CreateBarLine(; isbarplot::Bool,
                         fname::String,
                         barnumbers,
                         plotvalues_one,
                         plotvalues_two,
                         barnam,
                         ylab::String,
                         xlab::String,
                         tlab::String,
                         leglab,
                         rpath::String)

   figsize1 = 20
   figsize2 = 12
   wdth = 0.2
   fs = 18
   dotperinch = 600

   fig = figure(figsize = (figsize1, figsize2))

   if isbarplot == true
      bar(barnumbers, plotvalues_one, width = wdth, color = "red")
   else
      plot(plotvalues_one)
   end

   if plotvalues_two != nothing
      bar(barnumbers .+ wdth, plotvalues_two, width = wdth, color = "blue")
   else
      nothing
   end

   yticks(fontsize = fs)
   ylabel(ylab, fontsize = fs)
   title(tlab, fontsize = fs)
   xticks(fontsize = 10, rotation = 90)
   xlabel(xlab, fontsize = fs)
   if isbarplot == true
      axis("tight")
      ylim(bottom = 0)
      xticks(barnumbers .+ wdth / 2, barnam)
   else
      nothing
   end

   if leglab != nothing
      legend(leglab, fontsize = fs, frameon = false)
   else
      nothing
   end

   if isbarplot == true
      fig.subplots_adjust(bottom = 0.40)
   else
      nothing
   end
   fig.savefig(string(rpath, first(split(fname, ".")), ".pdf"), dpi = dotperinch)
   close(fig)
end
