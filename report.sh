#!/bin/bash
#------------------------------------------------------------------------------------------#
#  SCRIPT:   BTEQ DATABASE OBJECT HIERACHY REPORT GENERATOR                                #
#  VERSION:  1.0                                                                           #
#  RELEASED: 28/09/2017                                                                    #
#  AUTHOR:   James Armitage, Teradata                                                      #
#  EMAIL:    james.armitage@teradata.com                                                   #
#  STYLE:    https://google.github.io/styleguide/shell.xml                                 #
#  DESC:     script reads in tables\views from objects.txt and generates bteq export       #
#            scripts.  The scripts are then executed and the Teradata SHOW QUALIFIED       #
#            function is used to return object dependancies. GREP is used on the output    #
#            file to produce a .rep file for each object. Change code accordingly for a    #
#            single output file                                                            #     
#------------------------------------------------------------------------------------------#

#******************************************************************************************#
# STEP 1 declare bteq path constants and variables and setup logging                       #
#******************************************************************************************#

# set path for bteq
PATH="$PATH":/opt/teradata/client/15.10/bin/bteq

# set input file to variable
tbls=objects.txt

# stdout and stderr to terminal and log file
exec > >(tee job.log)

# change to job directory
cd "$(dirname "$0")"

#******************************************************************************************#
# STEP 2 - generate and run BTEQ scripts                                                   #
#******************************************************************************************#

# remove existing script
rm tables.bteq

# set field seperator used in input file
IFS=","

# read database name and table name sequentially from the input file
# generate BTEQ script
while read -r db tb
do
  echo "[tdip]/[username], [password]" >> tables.bteq
  echo ".export file=~/bteq-object-hierachy/"$tb".txt" >> tables.bteq
  echo ".set width 4500;" >> tables.bteq
  echo "database $db;" >> tables.bteq
  echo "SHOW QUALIFIED SELECT * FROM $db.$tb;" >> tables.bteq
  echo " " >> tables.bteq
  echo "*********************************************************************" >> tables.bteq
  echo " " >> tables.bteq
  #tb1=$tb
done < $tbls

echo ".logoff" >> tables.bteq
echo ".exit" >> tables.bteq

# run bteq
bteq < tables.bteq 

# copy objects.txt file to export directory 
cp $tbls export/

# change directory to export
cd export

# use the object file to pass object names into GREP for .rep files
while read -r db tb
do
  vws=`cat "$tb.txt" | grep VIEW | tr -d '"' | awk '{print $3}' | sort`
  vtb=`cat "$tb.txt" | grep TABLE | awk '{print $4}' | sort` 
  echo "VIEW HIERACHY REPORT FOR $tb REPORT" > $tb.rep
  echo "------------------------------------------------------------" >> $tb.rep
  echo "VIEWS" >> $tb.rep
  echo "------------------------------------------------------------" >> $tb.rep
  echo $vws >> $tb.rep
  echo "------------------------------------------------------------" >> $tb.rep
  echo "TABLES" >> $tb.rep
  echo "------------------------------------------------------------" >> $tb.rep
  echo $vtb >> $tb.rep
  echo "------------------------------------------------------------" >> $tb.rep
done < $tbls
