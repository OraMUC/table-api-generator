set termout off heading off pagesize 0 

SPOOL "hr/COUNTRIES_API_spec.sql" replace
SELECT om_tapigen.util_get_ddl('PACKAGE', 'COUNTRIES_API') FROM dual;
SPOOL OFF

SPOOL "hr/COUNTRIES_API_body.sql" replace
SELECT om_tapigen.util_get_ddl('PACKAGE BODY', 'COUNTRIES_API') FROM dual;
SPOOL OFF

SPOOL "hr/COUNTRIES_DML_V.sql" replace
SELECT om_tapigen.util_get_ddl('VIEW', 'COUNTRIES_DML_V') FROM dual;
SPOOL OFF

SPOOL "hr/COUNTRIES_IOIUD.sql" replace
SELECT om_tapigen.util_get_ddl('TRIGGER', 'COUNTRIES_IOIUD') FROM dual;
SPOOL OFF

set termout on heading on pagesize 100
