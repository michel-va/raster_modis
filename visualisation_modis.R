################################################################################
################################################################################
################## Using active fire to see fire regimes  ######################




################################################################################
############        Preliminary steps         ##################################
################################################################################


################################################################################
### Load the package 
library(sf)
library(raster)
library(dplyr)
library(lubridate)
library(ggplot2)
library(tmap)

################################################################################
### Load the data

  # Indigenous land and protected areas 
reserves<-st_read("shapefile/reserves/reserves.shp")

  # modis fire
modis<-read_sf("shapefile/modis_cropped/modis_cropped.shp")

################################################################################
### Create a background map 

  # Create a map with borders of the protected areas
tm1<-tm_shape(reserves,bbox=reserves)+
  tm_borders()

tm1
  # Create a map with indigenous reserves in gray
tm1bis<-tm_shape(reserves,bbox=reserves)+
  tm_borders()+
  tm_fill(col="#F5F5F5")

tm1bis

  # Visualize active fires with simple dots 
tm2<-tm1+tm_shape(modis)+
  tm_dots(col="red")+
  tm_scale_bar(breaks=c(0,50,100),text.size=1,position=c("left","bottom"))+
  tm_layout(main.title="Active fires between 2010 and 2020")

tm2

################################################################################
### Create an empty raster  

  # define the resolution of the raster to map fire regimes (size of the pixels)
res=1       #Change the value to the size of the pixel in km
res=1/111   #Value of 111km per degree correspond to WGS84 projection, working well in tropical latitude, other projection might be more relevant to others context 

# Create an empty raster
raster_template=raster(extent(modis),resolution=res,crs=st_crs(modis)$proj4string)





################################################################################
############        Simple fire regime characteristics        ##################
################################################################################

################################################################################
### Calculate the fire frequency 

 
  # Rasterize the number of pixel by year 
raster1=rasterize(modis,raster_template,field=1,fun="count")

  # Divide by the number of year
y=as.numeric(length(unique(modis$year)))
raster1=raster1/y

  # Plot
tm3<-tm1bis+tm_shape(raster1)+          
  tm_raster(alpha=0.7,
            style="quantile",
            title="",
            palette="Reds")+
  tm_scale_bar(breaks=c(0,50,100),text.size=1,position=c("right","bottom"))+
  tm_layout(main.title="Number of fire by square kilometer
            each year", legend.position=c("left","bottom"))

tm3

# The breaks for the raster legend can be adjusted to fit the data

tm3bis<-tm1bis+tm_shape(raster1)+
  tm_raster(alpha=0.7,
            breaks=c(0,0.1,0.15,0.20,0.5,1,5,30),
            title="",
            palette="Reds")+
  tm_scale_bar(breaks=c(0,50,100),text.size=1,position=c("right","bottom"))+
  tm_layout(main.title="Number of fire by square kilometer
            each year", legend.position=c("left","bottom"))

tm3bis


###############################################################################
### Mean fire intensity of the pixels 

  # Rasterize using FRP column
raster2=rasterize(modis,raster_template,field="FRP",fun=mean)

  #Plot
tm4<-tm1+tm_shape(raster2)+
  tm_raster(alpha = 0.7,
            style="fisher",
            title="",
            palette="Reds")+
  tm_scale_bar(breaks=c(0,50,100),text.size=1,position=c("right","bottom"))+
  tm_layout(main.title="Mean fire radiative power (Kelvin)", legend.position=c("left","bottom"))

tm4

  # Adjust the breaks scale
tmf4bis<-tm1+tm_shape(raster2)+
  tm_raster(alpha = 0.7,
            breaks=c(0,50,100,200,300,500,3800),
            title="",
            palette="Reds")+
  tm_scale_bar(breaks=c(0,50,100),text.size=1,position=c("right","bottom"))+
  tm_layout(main.title="Mean fire radiative power (Kelvin)", legend.position=c("left","bottom"))

tmf4bis

###############################################################################
### Max fire intensity of the pixels 

  # Rasterize using FRP column
raster3=rasterize(modis,raster_template,field="FRP",fun=max)

  #Plot
tm5<-tm1+tm_shape(raster3)+
  tm_raster(alpha = 0.7,
            style="fisher",
            title="",
            palette="Reds")+
  tm_scale_bar(breaks=c(0,50,100),text.size=1,position=c("right","bottom"))+
  tm_layout(main.title="Max fire radiative power (Kelvin)", legend.position=c("left","bottom"))

tm5

# Adjust the breaks scale
tm5bis<-tm1+tm_shape(raster3)+
  tm_raster(alpha = 0.7,
            breaks=c(0,100,200,500,1000,2000,5000,7000),
            title="",
            palette="Reds")+
  tm_scale_bar(breaks=c(0,50,100),text.size=1,position=c("right","bottom"))+
  tm_layout(main.title="Max fire radiative power (Kelvin)", legend.position=c("left","bottom"))

tm5bis


################################################################################
### Visualise the confidence in the fire observation

  # Rasterize using confidence column
raster4=rasterize(modis,raster_template,field="CONFIDENCE",fun=mean)

#Plot
tm6<-tm1+tm_shape(raster4)+
  tm_raster(alpha = 0.7,
            style="fisher",
            title="",
            palette="Reds")+
  tm_scale_bar(breaks=c(0,50,100),text.size=1,position=c("right","bottom"))+
  tm_layout(main.title="Mean confidence in observations", legend.position=c("left","bottom"))

tm6

# Adjust the breaks scale
tm6bis<-tm1+tm_shape(raster4)+
  tm_raster(alpha = 0.7,
            breaks=c(30,50,75,100),
            title="",
            palette="Reds")+
  tm_scale_bar(breaks=c(0,50,100),text.size=1,position=c("right","bottom"))+
  tm_layout(title="Mean confidence in observations", legend.position=c("left","bottom"))

tm6bis




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

tm7<-tm1+tm_shape(raster5)+
  tm_raster(alpha=0.7,palette=co,title="")+
  tm_scale_bar(breaks=c(0,50,100),text.size=1,position=c("right","bottom"))+
  tm_layout(main.title="Peak month for fire count", legend.position=c("left","bottom"))

tm7


################################################################################
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
tm8<-tm1+tm_shape(raster6)+
  tm_raster(alpha=0.7,palette="Reds",title="",breaks=c(1,2,3,4,6,10,12))+
  tm_scale_bar(breaks=c(0,50,100),text.size=1,position=c("right","bottom"))+
  tm_layout(main.title="length fire season (months)", legend.position=c("left","bottom"))

tm8


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

tm9<-tm1+tm_shape(raster7)+
  tm_raster(alpha=0.7,palette="Reds",title="")+
  tm_scale_bar(breaks=c(0,50,100),text.size=1,position=c("right","bottom"))+
  tm_layout(main.title="Peak year for fire count", legend.position=c("left","bottom"))

tm9


  # We can create a personalised color scale with the year with dry climatic conditions (2004, 2005,2010,2015) in red and wet climatic conditions in orange

co<-c("#EBC43F",  #2003
      "#FF0000",  #2004
      "#FF0000",  #2005
      "#EBC43F",  #2006
      "#EBC43F",  #2007
      "#EBC43F",  #2008
      "#EBC43F",  #2009
      "#FF0000",  #2010
      "#EBC43F",  #2011
      "#EBC43F",  #2012
      "#EBC43F",  #2013
      "#EBC43F",  #2014
      "#FF0000",  #2015
      "#EBC43F",  #2016
      "#EBC43F",  #2017
      "#EBC43F",  #2018
      "#EBC43F")  #2019


### with tm_maps
tm10<-tm1+tm_shape(raster7)+
  tm_raster(alpha=0.7,palette=co,title="",legend.show=FALSE)+
  tm_scale_bar(breaks=c(0,50,100),text.size=1,position=c("right","bottom"))+
  tm_add_legend("fill",col=c("#EBC43F","#FF0000"),labels=c("normal years","dry years"))+
  tm_layout(main.title="Peak year for fire count", legend.position=c("left","bottom"))

tm10


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
tm11<-tm1+tm_shape(raster8)+
  tm_raster(alpha=0.7,palette="Reds",title="",style="fisher")+
  tm_scale_bar(breaks=c(0,50,100),text.size=1,position=c("right","bottom"))+
  tm_layout(main.title="Interannual variance in fire count (sd)", legend.position=c("left","bottom"))

tm11




