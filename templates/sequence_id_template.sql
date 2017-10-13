CREATE FUNCTION <schema_name>.create_<table_name>_id_seq() RETURNS void AS $$
	DECLARE _sequence_start INT;
	BEGIN
		_sequence_start := (public.get_location_int())::INT + 2;

		EXECUTE '
		CREATE SEQUENCE <schema_name>.<table_name>_id_seq
			START WITH '|| _sequence_start || '
			INCREMENT BY 2
			NO MINVALUE
			NO MAXVALUE
			CACHE 1;
		';

		ALTER SEQUENCE <schema_name>.<table_name>_id_seq OWNER TO postgres;
		GRANT ALL ON SEQUENCE <schema_name>.<table_name>_id_seq TO postgres;
	END
$$ LANGUAGE plpgsql;

SELECT <schema_name>.create_<table_name>_id_seq();

DROP FUNCTION <schema_name>.create_<table_name>_id_seq();
