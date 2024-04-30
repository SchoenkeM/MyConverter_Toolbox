# -*- coding: utf-8 -*-
"""
Created on Tue Aug  9 15:55:08 2022

@author: Mischa
"""
# to install osgeo for anaconda or WLS2
# conda install -c anaconda osgeo 
# sudo apt-get install gdal-bin

from osgeo import gdal  
import glob, os
import subprocess

output_fname="merged_file_name.tif"
input_dir="" # for input dir only use "/"
NoDataValue=-9999 # set no data value 

#============================================================================================
if not os.path.isdir(input_dir):
    print(f"UNable to find or open input direcotry: {input_dir}")

os.chdir(input_dir)
fileList = glob.glob("*.tif")

fname = input_dir + output_fname
if fname in fileList: fileList.remove(fname)

print("\n___________________________________________________________________________________")
print("Start merging the individual Geotiff files into a single grid....")
print(f"\nCurrent processing directory: {input_dir}")

NoDataValue=str(NoDataValue)
cmd = "gdal_merge.py -n " + NoDataValue + " -a_nodata " + NoDataValue + " -ot Float32 -of GTiff -o " + fname # on ubuntu subsystem

print("GDAL command used to merge data: " + cmd)
print("\nList of Selected Files : ")
print('\n\t -'+'\n\t- '.join(fileList))
print('\nMering in Process: ', end='')
subprocess.call(cmd.split()+fileList)
print('\nProcessing successfull ')
print("___________________________________________________________________________________\n\n")

