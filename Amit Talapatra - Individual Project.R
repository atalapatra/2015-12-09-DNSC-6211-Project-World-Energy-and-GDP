#' Created on Sat Nov 21
#' 
#' @author: Amit Talapatra
#' 
#' This file pulls data from a local SQL database that was stored there by an
#' accompanying Python file. This file uses the data to create heat maps, 
#' scatter plots, and it performs a cluster analysis to create line plots that
#' summarize the relationship between GDP and energy use for countries.

# All of the following packages must be installed for this code to run
library(RMySQL)
library(plyr)
library(rworldmap)
library(Ckmeans.1d.dp)
library(ggplot2)
library(reshape2)

# Opens the connection to the SQL database
all_cons <- dbListConnections(MySQL())
for(con in all_cons)
  dbDisconnect(con)
mysql_host <- "localhost"
mysql_user <- "root"
mysql_pass <- "root"
mysql_dbname <- "AKTIndProj"
mysql_port <- 3306
drv = dbDriver("MySQL")

mydb = dbConnect(drv, 
                 user=mysql_user, 
                 password=mysql_pass, 
                 dbname=mysql_dbname, 
                 host=mysql_host,
                 port=mysql_port)

# Removes missing data from the dataset
df <- dbReadTable(mydb, "WBEnergyData")
df <- tail(df, -816)
df <- subset(df, year<2013)
df <- subset(df, !is.na(df$GDP))
df <- subset(df, !is.na(df$ALT))
df <- subset(df, !is.na(df$COM))
df <- subset(df, !is.na(df$FOS))
countCountries <- count(df, 'country')
countriesUsed <- subset(countCountries, freq==23)
countriesUsed <- countriesUsed$country
df <- subset(df, country %in% countriesUsed)

# Creates average values for each country based on each data set
AvgGDPdf <- aggregate(df[, 3], list(df$country), mean)
AvgALTdf <- aggregate(df[, 4], list(df$country), mean)
AvgCOMdf <- aggregate(df[, 5], list(df$country), mean)
AvgFOSdf <- aggregate(df[, 6], list(df$country), mean)

# Performs a k-means clustering analysis to group the countries by GDP
k = 5
clusters <- (Ckmeans.1d.dp(AvgGDPdf$x, k=k))
clusters <- clusters["cluster"]
clusters <- data.frame(clusters[1])

# Creates a data frame for the cleaned data, before the cluster summmary
Avg_df <- cbind(AvgGDPdf$Group.1, clusters, AvgGDPdf$x, AvgALTdf$x, AvgCOMdf$x, AvgFOSdf$x)
Avg_df <- rename(Avg_df, c("AvgGDPdf$Group.1"="Country",
                                   "cluster"="Cluster", 
                                   "AvgGDPdf$x"="GDP_Avg", 
                                   "AvgALTdf$x"="ALT_Avg", 
                                   "AvgCOMdf$x"="COM_Avg", 
                                   "AvgFOSdf$x"="FOS_Avg"))

# Creates a data frame for the data grouped by clusters of countries
clusterAvg <- data.frame(matrix(0, ncol = 6, nrow = k))
clusterAvg <- rename(clusterAvg, c("X1"="Cluster",
                                   "X2"="Countries", 
                                   "X3"="GDP_Avg", 
                                   "X4"="ALT_Avg", 
                                   "X5"="COM_Avg", 
                                   "X6"="FOS_Avg"))

# Creates labels for the plots
GDPLabel <- "GDP (Current US$)" # ADD/REMOVE 'per capita' BASED ON GDP INDICATOR PUT ON SQL IN PYTHON CODE
ALTLabel <- "Alternative/Nuclear Energy (% of total energy use)"
COMLabel <- "Combustible Renewables and Waste (% of total energy use)"
FOSLabel <- "Fossil Fuels (% of total energy use)"

# This section plots each of the world heat maps
par(mar=c(0,0,1.5,0))
## WORLD MAPS
# GDP
spdf <- joinCountryData2Map(Avg_df, joinCode="NAME", nameJoinColumn="Country")
mapCountryData(spdf, nameColumnToPlot="GDP_Avg", catMethod="fixedWidth", mapTitle = GDPLabel, colourPalette = c("grey","black"))

## ALT
spdf <- joinCountryData2Map(Avg_df, joinCode="NAME", nameJoinColumn="Country")
mapCountryData(spdf, nameColumnToPlot="ALT_Avg", catMethod="fixedWidth",  mapTitle = ALTLabel, colourPalette = c("light green","#009000"))

## COM
spdf <- joinCountryData2Map(Avg_df, joinCode="NAME", nameJoinColumn="Country")
mapCountryData(spdf, nameColumnToPlot="COM_Avg", catMethod="fixedWidth",  mapTitle = COMLabel, colourPalette = c("light blue","blue"))

## FOS
spdf <- joinCountryData2Map(Avg_df, joinCode="NAME", nameJoinColumn="Country")
mapCountryData(spdf, nameColumnToPlot="FOS_Avg", catMethod="fixedWidth", mapTitle = FOSLabel, colourPalette = c("pink","red"))

## GENERATES CLUSTER-BASED DATAFRAME
for (i in 1:k)
  clusterAvg$Cluster[i] <- i

clusterAvg$Countries <- table(Avg_df$Cluster)
clusterAvg$GDP_Avg <- aggregate(Avg_df[, 3], list(Avg_df$Cluster), mean)[2]
clusterAvg$ALT_Avg <- aggregate(Avg_df[, 4], list(Avg_df$Cluster), mean)[2]
clusterAvg$COM_Avg <- aggregate(Avg_df[, 5], list(Avg_df$Cluster), mean)[2]
clusterAvg$FOS_Avg <- aggregate(Avg_df[, 6], list(Avg_df$Cluster), mean)[2]

clusterAvg$GDP_Avg <- unlist(clusterAvg$GDP_Avg)
clusterAvg$ALT_Avg <- unlist(clusterAvg$ALT_Avg)
clusterAvg$COM_Avg <- unlist(clusterAvg$COM_Avg)
clusterAvg$FOS_Avg <- unlist(clusterAvg$FOS_Avg)

## INDIVIDUAL PLOTS: GDP VS ENERGY TYPE
# # ALT
# plotALT <- ggplot(Avg_df, aes(x=GDP_Avg, y=ALT_Avg)) +
#   geom_point(color="green") +
#   ylim(0, 100)
# plotALTc <- ggplot(clusterAvg, aes(x=GDP_Avg, y=ALT_Avg)) + 
#   geom_point(color="green") +
#   ylim(0, 100) +
#   geom_line(color="green")
# print(plotALT)
# print(plotALTc)
# 
# # COM
# plotCOM <- ggplot(Avg_df, aes(x=GDP_Avg, y=COM_Avg)) +
#   geom_point(color="blue") +
#   ylim(0, 100)
# plotCOMc <- ggplot(clusterAvg, aes(x=GDP_Avg, y=COM_Avg)) + 
#   geom_point(color="blue") +
#   ylim(0, 100) +
#   geom_line(color="blue")
# print(plotCOM)
# print(plotCOMc)
# 
# # FOS
# plotFOS <- ggplot(Avg_df, aes(x=GDP_Avg, y=FOS_Avg)) +
#   geom_point(color="red") +
#   ylim(0, 100)
# plotFOSc <- ggplot(clusterAvg, aes(x=GDP_Avg, y=FOS_Avg)) + 
#   geom_point(color="red") +
#   ylim(0, 100) +
#   geom_line(color="red")
# print(plotFOS)
# print(plotFOSc)

## COMBINED PLOTS: GDP VS ENERGY TYPE
# This is a scatter plot of all of the cleaned data
allAvgData <- melt(Avg_df[3:6], id="GDP_Avg")
plotAllAvg <- ggplot(allAvgData, aes(x=GDP_Avg, y=value, col=variable)) + 
  geom_point() +
  scale_colour_manual(values=c("#009000", "blue", "red"), 
                      name="variable",
                      breaks=c("ALT_Avg", "COM_Avg", "FOS_Avg"),
                      labels=c("Alternative/Nuclear", "Combustibles", "Fossil Fuels")) +
  theme(legend.title=element_blank()) +
  labs(x = GDPLabel,
       y = "% of total energy use",
       title = paste(GDPLabel, "by Energy Type: All Countries"))
print(plotAllAvg)

# This is a line plot summarize the data using cluster-based grouping
allClusterData <- melt(clusterAvg[3:6], id="GDP_Avg")
plotAllClusters <- ggplot(allClusterData, aes(x=GDP_Avg, y=value, col=variable)) + 
  geom_point() +
  geom_line() +
  scale_colour_manual(values=c("#009000", "blue", "red"), 
                      name="variable",
                      breaks=c("ALT_Avg", "COM_Avg", "FOS_Avg"),
                      labels=c("Alternative/Nuclear", "Combustibles", "Fossil Fuels")) +
  theme(legend.title=element_blank()) +
  labs(x = GDPLabel,
       y = "% of total energy use",
       title = paste(GDPLabel, "by Energy Type: Cluster Summary"))

print(plotAllClusters)

## CLOSE CONNECTION TO SQL
dbClearResult(df)
dbDisconnect(mydb)
dbUnloadDriver(drv)