CREATE SCHEMA <schema_name> AUTHORIZATION postgres;

GRANT ALL ON SCHEMA <schema_name> TO propagate;
GRANT ALL ON SCHEMA <schema_name> TO postgres;
GRANT ALL ON SCHEMA <schema_name> TO dbmirror;
GRANT USAGE ON SCHEMA <schema_name> TO public;
