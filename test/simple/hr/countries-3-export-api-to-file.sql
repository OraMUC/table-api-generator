set termout off heading off pagesize 0 

SPOOL "hr/countries.pks" replace

SELECT
  text
FROM
  user_source
WHERE
  type = 'PACKAGE'
  AND   name = 'COUNTRIES_API'
ORDER BY
  line;

SPOOL OFF

SPOOL "hr/countries.pkb" replace

SELECT
  text
FROM
  user_source
WHERE
  type = 'PACKAGE BODY'
  AND   name = 'COUNTRIES_API'
ORDER BY
  line;

SPOOL OFF

set termout on heading on pagesize 100