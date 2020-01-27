# Process and analyse vegetation index
library(sp)
library(rgdal)
library(raster)
library(spatial)
library(landsat)
library(RStoolbox)
library(snow)

# If only want to test on 1 file:
#folders <- Sys.glob("*LC81730382013114LGN01")
folders <- list.dirs("./data/raw", full.names=FALSE, recursive = FALSE)


################################### functions #########################################
# how to fix issue of sum layers with many NA values
func <- source('src/functions.R')

###################################### location ANALYSIS #############################

# All transformations julian day -> to accurate date, relate to 1-jan of that year
jan <- "-01-01" 

# Non irrigated chosen location:
X1 <- 229847.918
Y1 <- 3513232.711
# Irrigated location (round)
X2 <- 375940.632
Y2 <- 3433689.961
# location in the North of image (parcel)
X3 <- 256473.828
Y3 <- 3611514.187

data1 <-data.frame(X1,Y1)
coordinates(data1) <- c("X1","Y1")
data2 <-data.frame(X2,Y2)
coordinates(data2) <- c("X2","Y2")
data3 <-data.frame(X3,Y3)
coordinates(data3) <- c("X3","Y3")

# create an empty list with the acquisition dates in a readable format.
date_list <- outer(1:length(folders),1:7)

q = 1
beginCluster()
start <- Sys.time()

for (scene in folders){
  year <- substr(scene, start=10, stop=13)
  day <- substr(scene, start=14, stop=16)
  datum <- paste(year, day, sep='_')
  
  # LSWI_image <- raster(paste(scene,'/',year,"_", day,'_LSWI.TIF', sep=''))
  LSWI_image <- raster(paste(scene,'/','_REFL_VERYCLEAR_TIR2.TIF', sep=''))
  #qlt <- freq(LSWI_image, value = NA, useNA = "always")
  LSWI_extract1 <- extract(LSWI_image, data1)
  LSWI_extract2 <- extract(LSWI_image, data2)
  LSWI_extract3 <- extract(LSWI_image, data3)
  
  # Test this approach from Khalid, original is in the LSWI_mapitirate.R. Khalid's approach does this for all cells, 
  # not just specified locations. This can be used to monitor the duration needed for the combined map.
  # Extract for each pixel: max, min and mean over the whole time frame?
  # construct LSWI anomaly?
  # values  <- extract(LSWI_image, 1:ncell(LSWI_image))
  # longlat <- xyFromCell(LSWI_image, 1:ncell(LSWI_image))
  # dataset <- cbind(longlat, values)
  # write.table(dataset, "xyValue.txt")
  
  date_list[q, 1] <- datum
  date_list[q, 2] <- year
  date_list[q, 3] <- day
  date_list[q, 4] <- as.character(as.Date(datum, format = "%Y_%j")) #For each image the origin is the 1st of jan of that
  #date_list[q, 5] <- qlt
  date_list[q, 5] <- LSWI_extract1
  date_list[q, 6] <- LSWI_extract2
  date_list[q, 7] <- LSWI_extract3
  q = q + 1
  print(q)
}
write.table(date_list, 'F:/ICARDA/DroughtMapping/Output/TIR2_extract_alternativeLocations.txt')

## end counting time
end <- Sys.time()
## print out total calculation time
difftime(end, start)
## done with cluster object		
endCluster()

##################################### Image analysis

# extract and stack relevant images (LSWI and Reclassified images withouth clouds)
LSWI_list <- list.files(full.names = TRUE, recursive = TRUE, pattern = "LSWI_NOcloud.tif$")
LSWI_stack <- stack(LSWI_list, quick = TRUE)
recl_list <- list.files(full.names = FALSE, recursive = TRUE, pattern = "LSWI_reclass.tif$")
recl_stack <- stack(recl_list, quick = TRUE)

### Min & Max values

## set up the cluster object for parallel computing
beginCluster()
## start mesure the time for fun
start <- Sys.time()
# image with min&max value
max_image <- max(LSWI_stack, na.rm = TRUE)
writeRaster(max_image, filename = 'F:/ICARDA/DroughtMapping/Output/LSWI_all_inclCloud.tif', format = 'GTiff',
            datatype='flt8s', overwrite = TRUE)
# min_image <- min(LSWI_stack, na.rm = TRUE)
# writeRaster(min_image, filename = 'F:/ICARDA/DroughtMapping/Output/min_all.tif', format = 'GTiff',
#             datatype='flt8s', overwrite = TRUE)
## end counting time
end <- Sys.time()
## print out total calculation time
difftime(end, start)
## done with cluster object		
endCluster()

### Drought duration

## Sum classified images to count the amount of days classified as drougth
list2013 <- as.numeric(grep("2013", recl_list))
list2014 <- as.numeric(grep("2014", recl_list))
list2015 <- as.numeric(grep("2015", recl_list))
list2016 <- as.numeric(grep("2016", recl_list))

## set up the cluster object for parallel computing
beginCluster()
## start mesure the time for fun
start <- Sys.time()

test.sum <- clusterR(recl_stack, calc, args=list(fun=calc.sum))
#test.qlt <- clusterR(recl_stack, calc, args=list(fun=calc.qlt))
writeRaster(test.sum, filename = 'F:/ICARDA/DroughtMapping/Output/duration_1516.tif', 
            format = 'GTiff', datatype='flt8s', overwrite = TRUE)
## end counting time
end <- Sys.time()
## print out total calculation time
difftime(end, start)
## done with cluster object		
endCluster()

###### Anomaly

maximum <- raster("F:/ICARDA/DroughtMapping/Output/max_all.tif")
minimum <- raster("F:/ICARDA/DroughtMapping/Output/min_all.tif")

## set up the cluster object for parallel computing
beginCluster()
## start mesure the time for fun
start <- Sys.time()
counter = 1

# Calculate index of interest
for(scene in folders){
  print(counter)
  print(scene)
  year <- substr(scene, start=10, stop=13)
  day <- substr(scene, start=14, stop=16)
  
  #anomaly <- calc(x=LSWI, minimum = minimum, maximum = maximum, fun=calc.anomaly)
  
  LSWI <- raster(paste(scene,'/', year, '_', day, '_LSWI.TIF', sep=''))
  stack <- stack(minimum, maximum, quick = TRUE)
  anomaly <- clusterR(LSWI, calc, args = list(stack, fun=calc.anomaly))
  counter = counter + 1
} 

endCluster()
# end counting time
end <- Sys.time()
# print out total calculation time
difftime(end, start)