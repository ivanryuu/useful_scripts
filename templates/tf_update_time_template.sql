CREATE OR REPLACE FUNCTION <schema_name>.tf_update_update_time()
  RETURNS trigger AS
$BODY$
BEGIN
	IF TG_OP = 'DELETE' THEN
		RETURN OLD;
	END IF;

	NEW._update_time = now();

	RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION <schema_name>.tf_update_update_time()
  OWNER TO postgres;
