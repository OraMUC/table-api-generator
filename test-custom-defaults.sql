SELECT
    x.column_name,
    x.data_default
FROM
    XMLTABLE ( 'for $i in /custom_defaults/column return $i' PASSING xmltype(q'{
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