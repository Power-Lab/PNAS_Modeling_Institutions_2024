def CreateDisStack(rpathname, fname, sname):

    import matplotlib.pyplot as plt
    import csv
    from matplotlib.ticker import FixedLocator, FixedFormatter

    figsize1 = 20
    figsize2 = 10
    fs = 18
    dotperinch = 900

    # with open(rpathname + 'dispatch_agg.csv', newline = '') as csvfile:
    with open(rpathname + fname + '.csv', newline = '') as csvfile:
        data = list(csv.reader(csvfile, delimiter = '\t'))

    with open(rpathname + sname + '.csv', newline = '') as csvfile:
        data_charge = list(csv.reader(csvfile, delimiter = '\t'))

    keys = data[0][0].split(",")
    keys_charge = data_charge[0][0].split(",")

    values = []
    for x in range(0,len(keys)):
        subvalues = []
        for y in range(1,len(data)):
            subvalues.append(float(data[y][0].split(",")[x]))
        values.append(subvalues)
    disdict = dict(zip(keys, values))
    # disdict.pop('Hour', None)

    values_charge = []
    for x in range(0,len(keys_charge)):
        subvalues = []
        for y in range(1,len(data_charge)):
            subvalues.append(float(data_charge[y][0].split(",")[x]))
        values_charge.append(subvalues)
    values_charge[0] = [i * -1 for i in values_charge[0]]
    disdict_charge = dict(zip(keys_charge, values_charge))

    selected_hours = [0, 6, 12, 18] * 7
    selected_hours.append(0)
    selected_locations = range(0, 169, 6)
    x_formatter = FixedFormatter(selected_hours)
    x_locator = FixedLocator(list(selected_locations))

    fig, ax = plt.subplots(figsize = (figsize1,figsize2))
    ax.stackplot(list(range(0, len(list(disdict.values())[0]))), disdict.values(), labels = disdict.keys())
    ax.stackplot(list(range(0, len(list(disdict_charge.values())[0]))), disdict_charge.values(), labels = disdict_charge.keys())
    ax.legend(bbox_to_anchor = (1.05, 1), fontsize = fs)
    ax.set_title('Dispatch (MW)', fontsize = fs)
    ax.set_xlabel('Hours', fontsize = fs)
    ax.set_ylabel('MW', fontsize = fs)
    ax.xaxis.set_major_formatter(x_formatter)
    ax.xaxis.set_major_locator(x_locator)
    ax.tick_params(axis = 'both', which = 'major', labelsize = fs)

    # fig.savefig(rpathname + 'dispatch_agg.pdf', dpi = 900)
    fig.savefig(rpathname + fname + '.pdf', dpi = dotperinch)
    plt.close(fig)
