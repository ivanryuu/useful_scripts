CREATE INDEX <table_name>_<col>_idx
	ON <schema_name>.<table_name>
	USING btree(<col>);
