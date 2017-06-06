#!/bin/bash

set -ev

sqlplus -S -L ${DB_USER}/${DB_PASS} <<SQL
@@OM_TAPIGEN.pks
@@OM_TAPIGEN_BODY.pkb
@@OM_TAPIGEN_ODDGEN_WRAPPER.pks
@@OM_TAPIGEN_ODDGEN_WRAPPER_BODY.pkb
exit
SQL
