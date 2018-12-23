prompt Drop FKs
BEGIN
  FOR i IN (
    SELECT
      *
    FROM
      user_constraints t
    WHERE
      t.constraint_type = 'R'
      AND t.table_name IN (
        'COUNTRIES',
        'DEPARTMENTS',
        'EMPLOYEES',
        'JOBS',
        'JOB_HISTORY',
        'LOCATIONS',
        'REGIONS'
      )
  ) LOOP
    EXECUTE IMMEDIATE 'ALTER TABLE '
                      || i.table_name
                      || ' DROP CONSTRAINT '
                      || i.constraint_name;
  END LOOP;
END;
/


prompt Drop other objects

BEGIN
  FOR i IN (
  --
    SELECT
      *
    FROM
      user_objects t
    WHERE
      t.object_type = 'TABLE'
      AND t.object_name IN (
        'COUNTRIES',
        'DEPARTMENTS',
        'EMPLOYEES',
        'JOBS',
        'JOB_HISTORY',
        'LOCATIONS',
        'REGIONS'
      )
      OR t.object_type = 'VIEW'
      AND t.object_name IN (
        'EMP_DETAILS_VIEW'
      )
      OR t.object_type = 'SEQUENCE'
      AND t.object_name IN (
        'DEPARTMENTS_SEQ',
        'EMPLOYEES_SEQ',
        'LOCATIONS_SEQ'
      )
      OR t.object_type = 'PROCEDURE'
      AND t.object_name IN (
        'ADD_JOB_HISTORY',
        'SECURE_DML'
      )
      --
  ) LOOP
    EXECUTE IMMEDIATE 'DROP '
                      || i.object_type
                      || ' '
                      || i.object_name
                      || CASE
      WHEN i.object_type = 'TABLE' THEN ' PURGE'
    END;
  END LOOP;
END;
/