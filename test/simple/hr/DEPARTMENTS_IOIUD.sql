CREATE OR REPLACE TRIGGER "HR"."DEPARTMENTS_IOIUD"
  INSTEAD OF INSERT OR UPDATE OR DELETE
  ON "DEPARTMENTS_DML_V"
  FOR EACH ROW
BEGIN
  IF INSERTING THEN
    "DEPARTMENTS_API".create_row (
      p_department_id   => :new."DEPARTMENT_ID",
      p_department_name => :new."DEPARTMENT_NAME",
      p_manager_id      => :new."MANAGER_ID",
      p_location_id     => :new."LOCATION_ID" );
  ELSIF UPDATING THEN
    "DEPARTMENTS_API".update_row (
      p_department_id   => :new."DEPARTMENT_ID",
      p_department_name => :new."DEPARTMENT_NAME",
      p_manager_id      => :new."MANAGER_ID",
      p_location_id     => :new."LOCATION_ID" );
  ELSIF DELETING THEN
    raise_application_error (-20000, 'Deletion of a row is not allowed.');
  END IF;
END "DEPARTMENTS_IOIUD";
/
ALTER TRIGGER "HR"."DEPARTMENTS_IOIUD" ENABLE;

