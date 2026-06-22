#!/bin/bash

echo "=== Creating Jake's PostgreSQL Tables"
JAKE=${HOME}/adalovespace/buildscripts/lib/jakebase
TBLS=$(ls ${JAKE}/psql_tables)
for tbl in ${TBLS}; do
    echo "  - ${tbl}"
    psql -U postgres -d postgres -f ${JAKE}/psql_tables/${tbl}
done
echo ""
