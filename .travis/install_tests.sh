#!/bin/bash

set -ev
cd test
sqlplus -S -L ${DB_USER}/${DB_PASS} <<SQL
@@ut_om_tapigen.pks
@@ut_om_tapigen.pkb
exit
SQL
