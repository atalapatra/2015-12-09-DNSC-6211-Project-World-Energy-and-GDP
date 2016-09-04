# -*- coding: utf-8 -*-
"""
Created on Sat Nov 21 15:03:24 2015

@author: Amit Talapatra

This file contains functions to get data through the World Bank API. These
functions create a dataframe of the data, format the dataframe, store the data 
in a SQL database, and pull the data back into a dataframe. The accompanying R 
script pulls the data from SQL and produces several plots and maps from it.
"""
import pandas as pd
from pandas.io import wb
import MySQLdb as mySQL
#import csv
#import warnings
#import pandas.io.sql as pdSQL

# This function creates the data frame
def create_data_frame():
##   ONE OF THE FOLLOWING 'wbGDP' LINES SHOULD BE COMMENTED OUT:
##   GDP (current US$)
    wbGDP = wb.download(indicator='NY.GDP.MKTP.CD', country='all', start = 1990, end = 2013)
##   GDP per capita (current US$)
#    wbGDP = wb.download(indicator='NY.GDP.PCAP.CD', country='all', start = 1990, end = 2013)

#   ENERGY INDICATORS
    wbALT = wb.download(indicator='EG.USE.COMM.CL.ZS', country='all', start = 1990, end = 2013)
    wbCOM = wb.download(indicator='EG.USE.CRNW.ZS', country='all', start = 1990, end = 2013)
    wbFOS = wb.download(indicator='EG.USE.COMM.FO.ZS', country='all', start = 1990, end = 2013)

#   Combines the datasets into a single data frame
    df = wbGDP
    df = df.join(wbALT)
    df = df.join(wbCOM)
    df = df.join(wbFOS)
    df.columns = ['GDP', 'ALT', 'COM', 'FOS'] # replace columns names in dataframe
    df.reset_index(level=0, inplace=True)
    df.reset_index(level=1, inplace=True)
    return df

# This function sends the data frame to the SQL database
def df_to_mysql(dbName, tableName, df, keys):
#   Opens the connection
    conn = mySQL.connect(host='localhost', user='root', passwd='root')
    cursor = conn.cursor()
    cursor.execute("CREATE DATABASE IF NOT EXISTS " + dbName + ";")      
    conn = mySQL.connect(host='localhost', user='root', passwd='root', db=dbName)
    df.to_sql(tableName, conn, flavor='mysql', if_exists='replace', index=False)
    cursor = conn.cursor()
    cursor.execute(' USE %s; ' % (dbName) ) 
##   UNCOMMENT TO SEE SQL TABLE DATA
#    myDataFrame = pdSQL.read_sql('SELECT * FROM %s' % (tableName), conn)
#    print myDataFrame
    conn.close()

# This function pulls the data from the SQL database as a data frame. It was 
# used for testing purposes.
def mysql_to_df(dbName, tableName):
    conn = mySQL.connect(host='localhost', user='root', passwd='root', db=dbName)
#    cursor = conn.cursor()
    df = pd.read_sql('SELECT * FROM %s;' % (tableName), con=conn)  
    return df
    conn.close()

# The main functions runs the necesarry steps to store the data in the SQL 
# database
def main():
    df = create_data_frame()
    df_to_mysql('AKTIndProj', 'WBEnergyData', df, 'country, year')
    df = mysql_to_df('AKTIndProj', 'WBEnergyData')
    print df
    print "The data printed above was uploaded to and retrieved from the SQL Database"

if __name__ == "__main__":
    main()
    