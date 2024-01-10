
import pandas as pd
import os
import geopandas as gpd
from shapely.ops import unary_union

# def process_shape():

shapefolder = '/Users/Kucuksayacigil/Desktop/ipm_v6_regions'

uszone_shapes = gpd.read_file(os.path.join(shapefolder, "IPM_Regions_201770405.shp"))
wecczone_shapes = uszone_shapes[uszone_shapes['IPM_Region'].str.contains("WECC") | uszone_shapes['IPM_Region'].str.contains("WEC")]
wecczone_shapes["IPM_Region"] = wecczone_shapes["IPM_Region"].str.replace("WECC_", "")
wecczone_shapes["IPM_Region"] = wecczone_shapes["IPM_Region"].str.replace("WEC_", "")
wecczone_shapes = wecczone_shapes.set_index('IPM_Region')
wecczone_shapes = wecczone_shapes.to_crs("EPSG:4269")

# Process shape files and create modeling zones
zone_aggregation = {
    "NV": ["NNV", "SNV"],
    "NorCal": ["BANC", "CALN"],
    "SoCal": ["LADW", "SCE"],
    "SD_IID": ["IID", "SDGE"]
}

for key in zone_aggregation:
    combined_zones = wecczone_shapes[wecczone_shapes.index.isin(zone_aggregation[key])]
    combined_shapes = unary_union(combined_zones['geometry'])

    df = pd.DataFrame(pd.Series({key: combined_shapes}))
    df.columns = ['geometry']

    wecczone_shapes = pd.concat([wecczone_shapes, df])

    wecczone_shapes.drop(zone_aggregation[key], inplace = True)

os.mkdir("/Users/Kucuksayacigil/Desktop/wecczone_shapes")

wecczone_shapes.to_file('/Users/Kucuksayacigil/Desktop/wecczone_shapes/wecczone_shapes.shp') # writing a geodataframe as shape file

    # return wecczone_shapes
