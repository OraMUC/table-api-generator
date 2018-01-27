BEGIN
  FOR i IN 1..100 LOOP
    employees_api.create_a_row;
  END LOOP;
END;
/

BEGIN
  FOR i IN 1..10 LOOP
    employees_api.create_a_row(p_job_id => 2);
  END LOOP;
END;
/

select to_char(systimestamp,'yyyymmddhh24missff')||'@dummy.com' from dual;
select substr(sys_guid(),1,15)||'@dummy.com' from dual;
select ltrim('    *   test',' *') from dual;
SELECT
  x.column_name,
  x.data_default
FROM
  XMLTABLE ( 'for $i in /custom_defaults/column return $i' PASSING xmltype(
    q'{
<custom_defaults>
    <column name="ERRORS"><![CDATA[]]></column>
    <column name="OWNER"><![CDATA[TOOLS]]></column>
    <column name="P_API_NAME"><![CDATA[COUNTRIES_API]]></column>
    <column name="P_SEQUENCE_NAME"><![CDATA[COUNTRIES_SEQ]]></column>
    <column name="P_EXCLUDE_COLUMN_LIST"><![CDATA[]]></column>
    <column name="P_ENABLE_CUSTOM_DEFAULTS"><![CDATA[FALSE]]></column>
    <column name="P_CUSTOM_DEFAULT_VALUES"><![CDATA[]]></column>
</custom_defaults>
}'
  ) COLUMNS --
   column_name VARCHAR2(128) PATH '@name', --
   data_default VARCHAR2(4000) PATH 'text()' --
   ) x;
   
   

     
     