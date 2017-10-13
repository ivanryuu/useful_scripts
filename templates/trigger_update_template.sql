CREATE TRIGGER update_update_time_<table_name>
  BEFORE UPDATE
  ON <schema_name>.<table_name>
  FOR EACH ROW
  EXECUTE PROCEDURE <schema_name>.tf_update_update_time();
