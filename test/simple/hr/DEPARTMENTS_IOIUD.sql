CREATE OR REPLACE EDITIONABLE TRIGGER "HR"."DEPARTMENTS_IOIUD"
  INSTEAD OF INSERT OR UPDATE OR DELETE
  ON "DEPARTMENTS_DML_V"
  FOR EACH ROW
  /**
   * generator="OM_TAPIGEN"
   * generator_version="0.7.0"
   * generator_action="COMPILE_API"
   * generated_at="2020-01-03 21:39:42"
   * generated_by="DATA-ABC\INFO"
   */
BEGIN
  IF INSERTING THEN
    "DEPARTMENTS_API".create_row (
      p_department_id   => :new."DEPARTMENT_ID" /*PK*/,
      p_department_name => :new."DEPARTMENT_NAME",
      p_manager_id      => :new."MANAGER_ID" /*FK*/,
      p_location_id     => :new."LOCATION_ID" /*FK*/ );
  ELSIF UPDATING THEN
    "DEPARTMENTS_API".update_row (
      p_department_id   => :new."DEPARTMENT_ID" /*PK*/,
      p_department_name => :new."DEPARTMENT_NAME",
      p_manager_id      => :new."MANAGER_ID" /*FK*/,
      p_location_id     => :new."LOCATION_ID" /*FK*/ );
  ELSIF DELETING THEN
    raise_application_error (-20000, 'Deletion of a row is not allowed.');
  END IF;
END "DEPARTMENTS_IOIUD";
/
ALTER TRIGGER "HR"."DEPARTMENTS_IOIUD" ENABLE;

