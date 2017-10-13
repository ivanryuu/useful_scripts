CREATE TRIGGER replicate
  AFTER INSERT OR UPDATE OR DELETE
  ON <schema_name>.<table_name>
  FOR EACH ROW
  EXECUTE PROCEDURE dbmirror.recordchange();
