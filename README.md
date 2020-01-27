# mangro_mud3

Version 0.1.0

Project to read Landsat 8 satellite imagery and convert the spectral signal to
ndvi values for the purpose of time series analysis.
In a second step you could reclassify all index values [-1, 1] to a binary
map indicating which pixels fall within a certain range.

Requirements for running:
A landsat folder (as downloaded from USGS) containing the spectral bands
functions.R 
processing_landsat8_cleaned

Requirements:
Rstudio (version 3.6)
libraries:
	- Snow
	- Rstoolbox
	- SP
	- rgdal
	- raster
	- spatial



## Project organization

```
.
├── .gitignore
├── CITATION.md
├── LICENSE.md			
├── README.md			<- this file
├── requirements.txt
├── bin                	<- Compiled and external code, ignored by git (PG)
│   └── external       	<- Any external source code, ignored by git (RO)
├── config             	<- Configuration files (HW)
├── data               	<- All project data, ignored by git
│   ├── processed      	<- The final time series after running the analysis script
│   ├── raw            	<- The original data files in Reflectance
│   └── temp           	<- Intermediate data that has been transformed to NDVI
├── docs               	<- Documentation notebook for users (HW)
│   ├── manuscript     	<- Manuscript source
│   └── reports        	<- Other project reports and notebooks
├── results
│   ├── figures        	<- Figures for the manuscript or reports (PG)
│   └── output         	<- Other output for the manuscript or reports (PG)
└── src                	<- Source code for this project (HW)

```


## License

This project is licensed under the terms of the [MIT License](/LICENSE.md)

## Citation

Please [cite this project as described here](/CITATION.md).
