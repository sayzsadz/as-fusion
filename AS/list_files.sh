#!/bin/sh
#
# Generate a comma separated ls -l for the directory in which the external table's
# location file resides
#
targetDir='/home/oracle/fin/invoice_img/'
/bin/ls -l --time-style=long-iso $targetDir | /bin/awk 'BEGIN {OFS = ",";} {print $1, $2, $3, $4, $5, $6" "$7, $8}'
exit 0
