set termout off heading off pagesize 0 

SPOOL "hr/REGIONS_API_spec.sql" replace
SELECT om_tapigen.util_get_ddl('PACKAGE', 'REGIONS_API') FROM dual;
SPOOL OFF

SPOOL "hr/REGIONS_API_body.sql" replace
SELECT om_tapigen.util_get_ddl('PACKAGE BODY', 'REGIONS_API') FROM dual;
SPOOL OFF

SPOOL "hr/REGIONS_DML_V.sql" replace
SELECT om_tapigen.util_get_ddl('VIEW', 'REGIONS_DML_V') FROM dual;
SPOOL OFF

SPOOL "hr/REGIONS_IOIUD.sql" replace
SELECT om_tapigen.util_get_ddl('TRIGGER', 'REGIONS_IOIUD') FROM dual;
SPOOL OFF

set termout on heading on pagesize 100
