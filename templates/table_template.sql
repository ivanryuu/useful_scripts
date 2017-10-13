CREATE TABLE <schema_name>.<table_name>
(
  <table_name>_id bigint NOT NULL DEFAULT nextval('<schema_name>.<table_name>_id_seq'::regclass),
  create_time timestamp without time zone NOT NULL DEFAULT now(),
  _update_time timestamp without time zone NOT NULL DEFAULT now(),
  delete_time timestamp without time zone
)
WITH (
  OIDS=FALSE
);
ALTER TABLE <schema_name>.<table_name>
  OWNER TO postgres;
