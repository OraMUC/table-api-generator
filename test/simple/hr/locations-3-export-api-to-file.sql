set termout off heading off pagesize 0 

SPOOL "hr/LOCATIONS_API_spec.sql" replace
SELECT om_tapigen.util_get_ddl('PACKAGE', 'LOCATIONS_API') FROM dual;
SPOOL OFF

SPOOL "hr/LOCATIONS_API_body.sql" replace
SELECT om_tapigen.util_get_ddl('PACKAGE BODY', 'LOCATIONS_API') FROM dual;
SPOOL OFF

SPOOL "hr/LOCATIONS_DML_V.sql" replace
SELECT om_tapigen.util_get_ddl('VIEW', 'LOCATIONS_DML_V') FROM dual;
SPOOL OFF

SPOOL "hr/LOCATIONS_IOIUD.sql" replace
SELECT om_tapigen.util_get_ddl('TRIGGER', 'LOCATIONS_IOIUD') FROM dual;
SPOOL OFF

set termout on heading on pagesize 100
