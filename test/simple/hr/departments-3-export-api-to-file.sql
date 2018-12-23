set termout off heading off pagesize 0 

SPOOL "hr/DEPARTMENTS_API_spec.sql" replace
SELECT om_tapigen.util_get_ddl('PACKAGE', 'DEPARTMENTS_API') FROM dual;
SPOOL OFF

SPOOL "hr/DEPARTMENTS_API_body.sql" replace
SELECT om_tapigen.util_get_ddl('PACKAGE BODY', 'DEPARTMENTS_API') FROM dual;
SPOOL OFF

SPOOL "hr/DEPARTMENTS_DML_V.sql" replace
SELECT om_tapigen.util_get_ddl('VIEW', 'DEPARTMENTS_DML_V') FROM dual;
SPOOL OFF

SPOOL "hr/DEPARTMENTS_IOIUD.sql" replace
SELECT om_tapigen.util_get_ddl('TRIGGER', 'DEPARTMENTS_IOIUD') FROM dual;
SPOOL OFF

set termout on heading on pagesize 100
