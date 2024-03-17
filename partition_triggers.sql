CREATE SCHEMA IF NOT EXISTS deleted;
-- e.g. Partition marks.marksheet_p0 will use the deleted table:
-- deleted.marks_marksheet
CREATE OR REPLACE FUNCTION soft_delete_partition() RETURNS trigger AS $$
  BEGIN
    EXECUTE FORMAT('INSERT INTO deleted.%I
      VALUES(now(), $1.*);',
      TG_TABLE_SCHEMA || '_' || REGEXP_REPLACE(TG_TABLE_NAME, '_p[0-9]*$', '')
    )
    USING OLD;
    RETURN NULL;
  END;
$$ language 'plpgsql';