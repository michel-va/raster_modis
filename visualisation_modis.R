
################################################################################
### Load the package and data 
library(sf)
library(raster)
library(dplyr)
library(lubridate)
library(ggplot2)
library(tmap)
library()


  # Shape of interest 
border<-st_read("shapefile/border/border.shp")

  # modis AF 
modis<-read_sf("shapefile/modis/modis_processed.shp")


border<-st_transform(border,4674)
modis<-st_transform(modis,4674)
  # Use a projected crs (adapt crs to size and location of the area of interest)
border<-st_transform(border,crs='+proj=aea +lat_1=-5 +lat_2=-42 +lat_0=-32 +
                     lon_0=-60 +x_0=0 +y_0=0 +ellps=aust_SA +units=m no_defs')

modis<-st_transform(modis,crs='+proj=aea +lat_1=-5 +lat_2=-42 +lat_0=-32 +
                    lon_0=-60 +x_0=0 +y_0=0 +ellps=aust_SA +units=m no_defs')

modis<-st_crop(modis,border)

################################################################################
### Create a background map 

  # Visualize active fires with simple dots 
tm_shape(modis)+
  tm_dots(col="red",alpha=0.15)+
  tm_shape(border,bbox=border)+
  tm_borders(lwd=2)+
  tm_scale_bar(breaks=c(0,50,100),text.size=1,position=c("left","bottom"))+
  tm_layout(main.title="Active fires between 2006 and 2019")




################################################################################
### Create an empty raster  

  # define the resolution of the raster to map fire regimes (1km is the 
  # resolution of MODIS AF)

res=1000

# Create an empty raster
raster_template=raster(extent(modis),resolution=res,crs=st_crs(modis)$proj4string)


################################################################################
############        Simple fire regime characteristics        ##################
################################################################################

################################################################################
### Calculate the fire frequency 


# Rasterize the number of AF in each pixels  
raster1=rasterize(modis,raster_template,field=1,fun="count")

  # Divide by the number of year
y=as.numeric(length(unique(modis$year)))
raster1=raster1/y

  # Plot
tm_shape(raster1)+          
  tm_raster(alpha=0.7,
            style="fisher",
            n=10,
            title="",
            palette="YlOrRd")+
  tm_shape(border,bbox=border)+
  tm_borders(lwd=2)+
  tm_layout(main.title="Average Number of fire by square kilometer
            each year", legend.outside=TRUE)






###############################################################################
### Mean fire intensity of the pixels 

  # Rasterize using FRP column
raster2=rasterize(modis,raster_template,field="FRP",fun=mean)

  #Plot
tm_shape(raster2)+          
  tm_raster(alpha=0.7,
            style="quantile",
            n=10,
            title="",
            palette="YlOrRd")+
  tm_shape(border,bbox=border)+
  tm_borders(lwd=2)+
  tm_layout(main.title="Mean FRP (Kelvin)", legend.outside=TRUE)






###############################################################################
### Max fire intensity of the pixels 

  # Rasterize using FRP column
raster3=rasterize(modis,raster_template,field="FRP",fun=max)

  #Plot
tm_shape(raster3)+          
  tm_raster(alpha=0.7,
            style="quantile",
            n=10,
            title="",
            palette="YlOrRd")+
  tm_shape(border,bbox=border)+
  tm_borders(lwd=2)+
  tm_layout(main.title="Max FRP (Kelvin)", legend.outside=TRUE)


################################################################################
### Visualise the confidence in the fire observation

  # Rasterize using confidence column
raster4=rasterize(modis,raster_template,field="CONFIDENCE",fun=mean)

#Plot
tm_shape(raster4)+          
  tm_raster(alpha=0.7,
            style='cont',
            title="",
            palette="YlOrRd")+
  tm_shape(border,bbox=border)+
  tm_borders(lwd=2)+
  tm_layout(main.title="Confidence", legend.outside=TRUE)







################################################################################
######################        Seasonality        ###############################
################################################################################

################################################################################
### Creation of the function to assess the seasonality 

  # Function creating a list of dataframe divided by the value of a column we desire in the data (e.g: month)
list_modis<-function(df,column){
  
  list_df<-list()
  
  for (i in unique(as.character(df[[column]]))){
    nam<-paste("modis",i,sep=".")
    output<-assign(nam,df[df[[column]]==i,])
    list_df[[i]]<-output
  }
  
  return(list_df)
}


  # Function is creating a stack of raster layer from the list previously created  

stack_modis<-function(lis){
  
  r_stack<-stack()
  raster_template=raster(extent(modis),resolution=res,crs=st_crs(modis)$proj4string)
  
  for (i in lis){
    output<-rasterize(i,raster_template,field=1,fun="count")
    r_stack<-addLayer(r_stack,output)
  }
  
  names(r_stack)<-names(lis)
  return(r_stack)
  
}


################################################################################
### Create a raster with the peak month for fire  

  # Add a column with the month name for each detection 
modis = modis %>% 
  mutate(ACQ_DATE = ymd(ACQ_DATE)) %>% 
  mutate_at(vars(ACQ_DATE), funs(year, month)) %>%
  mutate(month_name=month.name[month]) 

  # Create a rasterstack with the data from every month  using the previous function
list_month<-list_modis(modis,"month_name")
stack_month<-stack_modis(list_month)
  
  #convert the stack to a dataframe and replace NA by 0
df_month<-as.data.frame(stack_month)
df_month[is.na(df_month)]<-0

  # Add a value with the peak month and assign NA value to row with no fires
y<-as.numeric(ncol(df_month))

for (i in 1:nrow(df_month)){
  if (sum(df_month[i,1:y])==0){
    df_month[i,y+1]<-NA
  }else {
    df_month[i,y+1]<-colnames(df_month[which.max(df_month[i,])])
  }
}

  # Turn the created column into a factor and assign levels
factor_month<-as.factor(df_month[,13])
factor_month<-factor(factor_month,levels=c("January",'February',"March","April","May",
                                           "June","July","August","September","October","November","December"))

  # Assign these value to a raster 
raster5<-setValues(raster_template,factor_month)
  # Plot with a personalized scale of colors
co<-c("#AED56E","#ACFA68","#9CF84B","#8BFA2A","#7CF510","#7FFF00","#71DD11","#F1F774","#F79212","#F73C12","#C92501","#950909")

tm_shape(raster5)+
  tm_raster(alpha=0.7,palette=co,title="")+
  tm_shape(border,bbox=border)+
  tm_borders(lwd=2)+
  tm_layout(main.title="Peak month for fire count", legend.outside=TRUE)



##############################################################################
### Look at the lengths of the fire season

  #Use the rasterstack to have a dataframe of the count of fire every month in each pixels 
df_month<-as.data.frame(stack_month)

  # Replace NA value of  column and do rowsum
df_month[is.na(df_month)]<-0
df_month$total<-rowSums(df_month)

  # Create a function returning the number of months since the moment 10% of the AF and 90% of the AF have been detected on a pixel
len<-function(df){
  
  val1=0            # Initializing all the value
  val2=0
  step1=0
  step2=0
  a=df[13]
  beg=0.1*a
  end=0.9*a
  
  
  if (df[13]==0){  #Return NA when there is no fires
    output<-NA
    return (output)
    break
  }
  
  for (i in df){   # Compute start date 
    if
    (val1<beg){
      val1=val1+i
      step1=step1+1
    }  
    else{
      mon_beg<-step1
    }
  }
  
  
  for (i in df){  # Compute end date
    if(val2<end){
      val2=val2+i
      step2=step2+1
    } 
    else{
      mon_end<-step2
    }
  }
  
  
  output<-(step2-step1)+1 # Return final value 
  return(output)
  
  
}


  # Run the function to compute the value 
len_mon<-apply(df_month,1,len)

  # Rasterize the value
raster6<-setValues(raster_template,len_mon)

  # Plot 
tm_shape(raster6)+
  tm_raster(alpha=0.7,palette="YlOrRd",title="",breaks=c(1,2,3,4,6,10,12))+
  tm_shape(border,bbox=border)+
  tm_borders(lwd=2)+
  tm_layout(main.title="length fire season (months)", legend.outside=TRUE)



################################################################################
### Look at the year of the time serie with the most frequent burning 

  # Create a rasterstack with the data from every year
list_year<-list_modis(modis,"year")
stack_year<-stack_modis(list_year)

  #convert the stack to a dataframe
df_year<-as.data.frame(stack_year)
df_year[is.na(df_year)]<-0


  # Add a value with the peak month and assign NA value to row with no fires
y<-as.numeric(ncol(df_year))

for (i in 1:nrow(df_year)){
  if (sum(df_year[i,1:y])==0){
    df_year[i,y+1]<-NA
  }else {
    df_year[i,y+1]<-colnames(df_year[which.max(df_year[i,])])
  }
}




  # Turn the created column into a factor and assign levels
factor_year<-as.factor(df_year[,y+1])

  # Assign these value to a raster 
raster7<-setValues(raster_template,factor_year)

tm_shape(raster7)+
  tm_raster(alpha=0.7,palette="Reds",title="")+
  tm_shape(border,bbox=border)+
  tm_borders(lwd=2)+
  tm_layout(main.title="Peak year for fire count", legend.outside=TRUE)



#######################################################################################
############ Internannual variability

  #Create a raster stack with the different years
list_year<-list_modis(modis,"year")
years<-stack_modis(list_year)

  # Convert to dataframe, replace na by 0 and create a column with standard deviation
years<-as.data.frame(years)
years[is.na(years)]<-0
years<-transform(years, sd=apply(years,1, sd, na.rm = TRUE))

  # Reset 0 value by NA
years[years==0]<-NA


  # Let's select only one column
sd<-years[,"sd"]

  # Assign these value to a raster 
raster8<-setValues(raster_template,sd)


  # Plot
tm_shape(raster8)+
  tm_raster(alpha=0.7,palette="YlOrRd",title="",style="quantile",n=5)+
  tm_shape(border,bbox=border)+
  tm_borders(lwd=2)+
  tm_layout(main.title="Interannual variance in fire count (sd)", legend.outside="TRUE")





