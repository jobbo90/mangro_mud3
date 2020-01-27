# Processing LANDSAT 8 images for vegetation indexes
library(sp)
library(rgdal)
library(raster)
library(spatial)
library(landsat)
library(RStoolbox)
library(snow)


wd <- 'C:/proef/mangro_mud3'
# C:\proef\mangro_mud3\data\raw 
# setwd(wd)
folders <- list.dirs("./data/raw", full.names=FALSE, recursive = FALSE)

func <- source('src/functions.R')

# If only want to test on 1 file:
#folders <- Sys.glob("*LC08_L1GT_228056_20190309_20190325_01_T2")

#################### Calculations

## set up the cluster object for parallel computing
beginCluster()
## start mesure the time for fun
start <- Sys.time()
counter = 1

# Calculate index of interest
for(scene in folders){
  # scene <- folders[counter]
  print(counter)
  print(scene)
  
  # Read Metadata file from folder
  #metadatas <- readMeta(paste(scene,'/',scene,'_MTL.TXT', sep=''))
  year <- substr(scene, start=18, stop=21)
  day <- substr(scene, start=24, stop=25)
  
  # Read layers with atmospheric corrected values and clouds & shadows exluded
  RED <- raster(paste('./data/raw/', scene,'/',scene,'_sr_band4.TIF', sep=''))
  NIR <- raster(paste('./data/raw/', scene,'/',scene,'_sr_band5.TIF', sep=''))
  # SWIR1 <- raster(paste(scene,'/','_REFL_VERYCLEAR_SWIR1.TIF', sep=''))
  #SWIR2 <- raster(paste(scene,'/','_REFL_VERYCLEAR_SWIR2.TIF', sep=''))
  #BQA <- raster(paste(scene,'/',scene,'_qa.TIF', sep=''))

  stacked <- stack(NIR, RED)
  NDVI <- clusterR(stacked, overlay, args = list(fun=calc.index))
  name <- paste0(scene,'/', year, '_', day, '_NDVI')
  writeRaster(NDVI, filename=paste0('./data/temp','/',year,'_', day, '_NDVI'), format='GTiff', 
              datatype='FLT4S', overwrite=TRUE)
  counter = counter + 1
}

endCluster()
# end counting time
end <- Sys.time()
# print out total calculation time
difftime(end, start)

# #Delete unwanted files
# for (scene in folders){
#   year <- substr(scene, start=10, stop=13)
#   day <- substr(scene, start=14, stop=16)
#   #LSWI <- paste(scene,'/',year,"_", day,'_Fmask.TIF', sep='')
#   file <- paste(scene,'/', scene, "_MTLFmask.hdr", sep='')
#   file2 <- paste(scene,'/', scene, "_MTLFmask", sep='')
#   file.remove(file)
#   file.remove(file2)
# }


################################ Calculate reclassified values

## set up the cluster object for parallel computing
beginCluster()
## start mesure the time for fun
start <- Sys.time()
counter = 1
## Matrix used for classification in 2(binair 0/1) classes: -1 -> 0 and 0 -> 1
# For visualization classess of severity required, reclassify here in multiple classes e.g 1-4?
M <- matrix(c(-1, 0, 1, 0 , 1 , 0),nrow = 2, ncol=3,byrow = TRUE)

for(scene in folders){
  print(counter)
  print(scene)
  year <- substr(scene, start=10, stop=13)
  day <- substr(scene, start=14, stop=16)
  
  # LSWI <- raster(paste(scene,'/', year, '_', day, '_LSWI.TIF', sep=''))
  NDVI <- raster(paste(scene,'/', year, '_', day, '_NDVI.TIF', sep=''))
  #reclassified <- reclassify(LSWI, M)
  # write raster, to smallest possible data type:
  # writeRaster(reclassified, filename=paste0(scene,'/', year, '_', day, '_LSWI_reclass'), format='GTiff',
  # datatype='INT1U', overwrite=TRUE)

  # 0 => clear land pixel
  # 1 => clear water pixel
  # 2 => cloud shadow
  # 3 => snow
  # 4 => cloud
  # 255 => no observation
    #LSWI.reclass <- raster(paste(scene,'/', year, '_', day, '_LSWI_reclass.TIF', sep=''))
  fmask <- raster(paste(scene, '/', year, '_', day, '_Fmask.tif', sep=''))
  fmask[fmask %in% c(0, 1, 3, 255)] <- NA

  # LSWI.cloudfree <- overlay(x=LSWI, y=fmask, fun = cloud2NA)
  # writeRaster(LSWI.cloudfree, filename=paste0(scene,'/', year, '_', day, '_LSWI_NOcloud'), 
  #             format='GTiff', datatype='flt4s', overwrite=TRUE)
  # 
  NDVI.reclass.cloudfree <- overlay(x=NDVI, y=fmask, fun = cloud2NA)
  writeRaster(NDVI.reclass.cloudfree, filename=paste0(scene,'/', year, '_', day, '_NDVI_NOcloud'), 
              format='GTiff', datatype='flt8s', overwrite=TRUE)

  counter = counter + 1
}
endCluster()
# end counting time
end <- Sys.time()
# print out total calculation time
difftime(end, start)