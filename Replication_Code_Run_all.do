
cd "/Users/miranaaazzz/Desktop/Replication_UI as a Housing Market Stabilizer"

* Log file
capture log close
log using replication_log.log, replace text

* Figure 1
do "Figure_1/Figure_1_Replication.do"

do "Figure_1/Figure_1_Same.do"

* Table 3
do "Table_3/Table_3_Replication.do"

do "Table_3/Table_3_Extension.do"

* Table 4
do "Table_4/Table_4_Replication.do"

log close
