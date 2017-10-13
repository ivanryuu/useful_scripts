ALTER TABLE <schema_name>.<table_name>
	ADD CONSTRAINT <table_name>_<fk_table>_fkey FOREIGN KEY (<col>)
    REFERENCES <fk_schema>.<fk_table> (<fk_col>) MATCH SIMPLE
    ON UPDATE CASCADE ON DELETE CASCADE
    DEFERRABLE INITIALLY DEFERRED;
