set termout off heading off pagesize 0 

SPOOL "hr/JOBS_API_spec.sql" replace
SELECT om_tapigen.util_get_ddl('PACKAGE', 'JOBS_API') FROM dual;
SPOOL OFF

SPOOL "hr/JOBS_API_body.sql" replace
SELECT om_tapigen.util_get_ddl('PACKAGE BODY', 'JOBS_API') FROM dual;
SPOOL OFF

SPOOL "hr/JOBS_DML_V.sql" replace
SELECT om_tapigen.util_get_ddl('VIEW', 'JOBS_DML_V') FROM dual;
SPOOL OFF

SPOOL "hr/JOBS_IOIUD.sql" replace
SELECT om_tapigen.util_get_ddl('TRIGGER', 'JOBS_IOIUD') FROM dual;
SPOOL OFF

set termout on heading on pagesize 100
