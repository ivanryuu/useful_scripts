CREATE OR REPLACE FUNCTION <schema_name>.add_<table_name>(<params>)
  RETURNS bigint AS
$BODY$
DECLARE
	_id bigint;
BEGIN
	INSERT INTO <schema_name>.<table_name>
  (<table_names>)
	VALUES (<param_names>)
  RETURNING <table_name>_id INTO _id;
  RETURN _id;
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION <schema_name>.add_<table_name>(<param_types>)
  OWNER TO postgres;
