Clean data
================

Clean Moosilauke and BC data.

## Moosilauke data
Depends on [read-moose.R](https://github.com/ghandi9000/ecodatascripts/blob/master/read/read-moose.R) to read raw data from master file.

* Checks for columns: "DBH", "HT", "EHT", "BV"
 * "EHT" is estimated height
* Replaces "HTTCR" and "ebv" with "HT" and "BV"
* Creates BA columns for each year (Basal Area)
* Creates BAGROWTH columns (annualized basal area growth)
* Creates PRIORDBH/PRIORBA/PRIORHT/PRIORBV (dbh/ba/ht/bv from prior time period)
* Converts column names to lowercase
* Removes unused columns
* Creates [moose-wide.csv](https://github.com/ghandi9000/data/tree/master/moose)

