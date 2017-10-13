CREATE TRIGGER <table_name>_before_insert
  BEFORE INSERT ON <schema_name>.<table_name>
  FOR EACH ROW EXECUTE PROCEDURE partitioning_utils.trigfunc_partition_by_<time>('<col>');
