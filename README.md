# Rasterizing MODIS 
MODIS Active-Fire data is one of the most commonly used dataset for the analyse of the fire regime. One of the strength of this dataset is that data are available from 2001 to nowadays, allowing analysis over the last two decades. MODIS AF have a relatively coarse resolution, and each active fire recorded occured in a 1km piels around the detection. One way to deal wit the imprecision of this dataset is to rasterize the observation, into raster of at least 1km of precisions. Each MODIS AF contain several information such as the estimated fire density, confidence in the information, time and date of detection. This allow us to derive many characteristicsregarding frequency, intensity and seasonality of the fires. 


# Dataset 
The MODIS AF data can be downloaded from https://firms.modaps.eosdis.nasa.gov/download/ . For the example presented in this repository, we used active fire detection for the 2006-2020 period over a region in the Xingu river Basin, in the South-East state of Para. The MODIS AF data went through a filtering algorithm that is removing the detection with less than 30% of confidence and multiple AF detection over the same pixels for the same days (https://github.com/michel-va/filter_duplicate_modis)

For giving mroe context to our data, we also added the boundaries of several protected areas and indigenous land in the regions, which experience lower deforestation rate and fire occurence than unprotected areas in the region. The area of interest is an active deforestation frontiers, where most of the forest outside protected areas have been turned into pastures and agricultural land and are frequently cleared from regrowing trees through the use of agricultural maintenance. 

# Deriving characteristics of the fires regimes 

## Fire frequency 
For looking at the fire frequency, we simply create an empty raster of the desired resolution (1 km in our case, the minimal resolution of MODIS AF) and we create a count of the number of AF in each cells using the rastirize function, before dividing by the total number of years. Note that we use a projected coordinate reference system, which create some distorsion but allow us to use meters as units. Choose a crs adapted to the size of the area of interest and its location on the globe. 

![plot2](https://user-images.githubusercontent.com/84012797/145017023-deb819df-a4e5-4c7b-b44d-45229459c411.png)

## Fire Radiative Power 
The same approach is use: we rasterize the FRP column into an empty raster, using the mean and the maximum function to derive different characteristics. In our case, high maximum FRP can indicate a deforestation fires, in which tree are cut, pilled and dry before being light on fire and results into large fires.

 ![plot3](https://user-images.githubusercontent.com/84012797/145017600-482628aa-2f7a-4be7-a07b-3e59be6de1f3.png)

![plot4](https://user-images.githubusercontent.com/84012797/145017627-43fed41a-c133-48d8-863e-abc2572d860e.png)

## Confidence 
Once again, we use the rastoerize approach. It oculd be usefull to understand if some area of our landscape tend to constantely have lower confidence in the detection. This could per exampel due to a mountainous landscape, higher tree cover, sources of aerosols preventing the detection. Eventually, it could worth to use alternatives dataset to check for the constancy of data. 
![plot5](https://user-images.githubusercontent.com/84012797/145018099-e39020de-109b-41cf-91fc-ed55cc1737a2.png)


## Month with higher fire count
For deriving this measure (as well as other measure relative to the seasonality) we use two personalized function. One is creating a list with subset of MODIS AF based on one column (such as month or years), and the second is creating a raster stack with the list of subset of MODIS AF. One thing that could be done is to transform the stack into a dataframe and use alogorithm to derive new value, such as the month with a higher fire count. 

![plot6](https://user-images.githubusercontent.com/84012797/145018539-6fc5c1b4-373e-44ed-beaa-617397529a82.png)

##  Length of the fire season 
A personalised function is created to derive the count the number of months between the moment at least 10%  and 90% of the fires detected in a cell have been detected. 

![plot7](https://user-images.githubusercontent.com/84012797/145019162-d7839bd9-5b52-4dc0-876d-e05032ccaba4.png)


## Peak year fire count 
Can give us an indication on how different arra have been affected by different types of events (drought, policies changes ...). 

![plot8](https://user-images.githubusercontent.com/84012797/145019419-ccf0bd82-fcfb-4bd6-b355-091c508d03e0.png)

## Variance in the fire regimes 
Higher variance in the number of fire detected (or other characteristics) can indicate a shift in the fire regimes. 

![plot9](https://user-images.githubusercontent.com/84012797/145019702-f47957a1-6090-4a88-9716-8d6614b75866.png)


# Aknowledgement 
This script have been develloped based on the results presented in Mapping fire regimes in China using MODIS active fire and burned area data.  D. Chen, J. M. C. Pereira, A. Masiero, F. Pirotti, Applied Geography. 85, 14–26 (2017).
