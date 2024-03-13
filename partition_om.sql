CREATE SCHEMA IF NOT EXISTS marks;

CREATE TABLE marks.osce_marksheet (
  id BIGINT NOT NULL
  , "osceMarksheetId" INT NOT NULL
  , "osceStationMarkId" INT NOT NULL
  , mark BOOLEAN DEFAULT false NOT NULL
  , "index" INT NOT NULL
  , CONSTRAINT osce_marksheet_oscemarksheetid_fk FOREIGN KEY ("osceMarksheetId") REFERENCES public.osce_marksheets(id) ON DELETE CASCADE ON UPDATE CASCADE
  , CONSTRAINT osce_marksheet_oscestationmarkid_fk FOREIGN KEY ("osceStationMarkId") REFERENCES public.osce_station_marks(id) ON DELETE CASCADE ON UPDATE CASCADE
  , PRIMARY KEY ("id")
) PARTITION BY RANGE ("osceMarksheetId");

CREATE INDEX ON marks.osce_marksheet ("osceMarksheetId");

CREATE TABLE partman.template_marks_osce_marksheet (
  LIKE marks.osce_marksheet INCLUDING DEFAULTS INCLUDING CONSTRAINTS INCLUDING INDEXES
  , CONSTRAINT template_marks_osce_marksheet_oscemarksheetid_fk FOREIGN KEY ("osceMarksheetId") REFERENCES public.osce_marksheets(id) ON DELETE CASCADE ON UPDATE CASCADE
  , CONSTRAINT template_marks_osce_marksheet_oscestationmarkid_fk FOREIGN KEY ("osceStationMarkId") REFERENCES public.osce_station_marks(id) ON DELETE CASCADE ON UPDATE CASCADE
  , PRIMARY KEY ("id")
);

SELECT partman.create_parent(
  p_parent_table := 'marks.osce_marksheet'
  , p_control := 'marksheetId'
  , p_interval := '10000'
  , p_template_table := 'partman.template_marks_osce_marksheet'
);

ALTER TABLE osce_marksheet_marks SET SCHEMA marks;

CALL partman.partition_data_proc(
  p_parent_table := 'marks.osce_marksheet'
  , p_loop_count := 55
  , p_interval := '1000'
  , p_source_table := 'marks.osce_marksheet_marks'
);

DROP TABLE marks.osce_marksheet_marks CASCADE;

-- should try to add constraints based on id, createdAt and updatedAt for stale tables
-- this will improve any WHERE requests we do for analysis on this table

UPDATE partman.part_config SET 
  constraint_cols = '{"id"}'
  , optimize_constraint = 10 -- apply constraints to child tables older than the previous 10
WHERE
  parent_table = 'marks.osce_marksheet';

-- SELECT partman.apply_constraints('marks.marksheet', 'marks.marksheet_p0', TRUE);