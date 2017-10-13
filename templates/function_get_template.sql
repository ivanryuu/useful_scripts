CREATE OR REPLACE FUNCTION <schema_name>.<function_name>(
  _ret refcursor,
  _<col> <col_type>
)
  RETURNS refcursor AS
$BODY$
BEGIN
  OPEN _ret FOR
  SELECT
    t.<table_name>_id,<cols>
    t.create_time
  FROM <schema_name>.<table_name> as t
  WHERE t.<col> = _<col>
  AND t.delete_time IS NULL;

  RETURN _ret;
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

ALTER FUNCTION <schema_name>.<function_name>(refcursor, <col_type>)
  OWNER TO postgres;
