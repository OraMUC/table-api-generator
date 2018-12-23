set termout off heading off pagesize 0 

SPOOL "hr/EMPLOYEES_API_spec.sql" replace
SELECT om_tapigen.util_get_ddl('PACKAGE', 'EMPLOYEES_API') FROM dual;
SPOOL OFF

SPOOL "hr/EMPLOYEES_API_body.sql" replace
SELECT om_tapigen.util_get_ddl('PACKAGE BODY', 'EMPLOYEES_API') FROM dual;
SPOOL OFF

SPOOL "hr/EMPLOYEES_DML_V.sql" replace
SELECT om_tapigen.util_get_ddl('VIEW', 'EMPLOYEES_DML_V') FROM dual;
SPOOL OFF

SPOOL "hr/EMPLOYEES_IOIUD.sql" replace
SELECT om_tapigen.util_get_ddl('TRIGGER', 'EMPLOYEES_IOIUD') FROM dual;
SPOOL OFF

set termout on heading on pagesize 100
