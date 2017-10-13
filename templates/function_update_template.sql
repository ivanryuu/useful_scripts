CREATE OR REPLACE FUNCTION <schema_name>.update_<table_name>(
  _<table_name>_id bigint,<params>)
  RETURNS bigint AS
$BODY$
BEGIN
  UPDATE <schema_name>.<table_name>
  SET <set_statements>
  WHERE <table_name>_id = _<table_name>_id;

  RETURN _<table_name>_id;
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION <schema_name>.update_<table_name>(bigint, <param_types>)
  OWNER TO postgres;
