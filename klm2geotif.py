# -*- coding: utf-8 -*-
"""
Created on Wed Apr 24 17:45:14 2024

@author: misch
"""

import xml.etree.ElementTree as ET
from osgeo import gdal, osr
import os

def parse_kml(kml_file):
    tree = ET.parse(kml_file)
    root = tree.getroot()
    
    ground_overlays = []
    
    for folder in root.findall('.//{http://www.opengis.net/kml/2.2}Folder'):
        for ground_overlay in folder.findall('.//{http://www.opengis.net/kml/2.2}GroundOverlay'):
            name = ground_overlay.find('{http://www.opengis.net/kml/2.2}name').text
            icon_href = ground_overlay.find('.//{http://www.opengis.net/kml/2.2}Icon/{http://www.opengis.net/kml/2.2}href').text
            north = float(ground_overlay.find('.//{http://www.opengis.net/kml/2.2}north').text)
            south = float(ground_overlay.find('.//{http://www.opengis.net/kml/2.2}south').text)
            east = float(ground_overlay.find('.//{http://www.opengis.net/kml/2.2}east').text)
            west = float(ground_overlay.find('.//{http://www.opengis.net/kml/2.2}west').text)
            
            ground_overlays.append({
                'name': name,
                'icon_href': icon_href,
                'north': north,
                'south': south,
                'east': east,
                'west': west
            })
    
    return ground_overlays

def create_geotiff(png_file, output_file, north, south, east, west, view_bound_scale):
    gdal.UseExceptions()
    
    
    # Calculate adjusted bounding coordinates based on viewBoundScale
    width = east - west
    height = north - south
    east = west + width * view_bound_scale
    south = north - height * view_bound_scale
   
    # Open PNG file
    ds = gdal.Open(png_file)
    
    # Set geospatial information
    geotransform = [west, (east - west) / ds.RasterXSize, 0, north, 0, (south - north) / ds.RasterYSize]
    
    # Set projection
    srs = osr.SpatialReference()
    srs.ImportFromEPSG(4326)
    
    # Create GeoTIFF
    driver = gdal.GetDriverByName("GTiff")
    dst_ds = driver.Create(output_file, ds.RasterXSize, ds.RasterYSize, 3, gdal.GDT_Byte)
    dst_ds.SetGeoTransform(geotransform)
    dst_ds.SetProjection(srs.ExportToWkt())
    
    # Write PNG data to GeoTIFF
    for i in range(1, 4):
        band = ds.GetRasterBand(i)
        data = band.ReadAsArray()
        dst_ds.GetRasterBand(i).WriteArray(data)
    
    # Close datasets
    ds = None
    dst_ds = None

if __name__ == "__main__":
    kml_file = "C:/Users/misch/IOW Marine Geophysik Dropbox/Mischa Schönke/4_Projekte/2024_Osterolz_DroneData/airship-areas2024/airship-areas2024/Areas_background/doc.kml"

    ground_overlays = parse_kml(kml_file)
    
    for overlay in ground_overlays:
        name = overlay['name']
        icon_href = overlay['icon_href']
        north = overlay['north']
        south = overlay['south']
        east = overlay['east']
        west = overlay['west']
        
        png_file = os.path.join(os.path.dirname(kml_file), icon_href)
        output_file = f"{os.path.splitext(png_file)[0]}.tif"
        
        create_geotiff(png_file, output_file, north, south, east, west, 0.75)
        print(f"GeoTIFF saved: {output_file}")
