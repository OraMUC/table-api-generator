set termout off heading off pagesize 0 

SPOOL "hr/departments.pks" replace

SELECT
  text
FROM
  user_source
WHERE
  type = 'PACKAGE'
  AND   name = 'DEPARTMENTS_API'
ORDER BY
  line;

SPOOL OFF

SPOOL "hr/departments.pkb" replace

SELECT
  text
FROM
  user_source
WHERE
  type = 'PACKAGE BODY'
  AND   name = 'DEPARTMENTS_API'
ORDER BY
  line;

SPOOL OFF

set termout on heading on pagesize 100