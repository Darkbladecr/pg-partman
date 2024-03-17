CREATE SCHEMA IF NOT EXISTS marks;

CREATE TABLE marks.marksheet (
  id BIGINT NOT NULL
  , "createdAt" TIMESTAMPTZ NOT NULL DEFAULT now()
  , "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT now()
  , "marksheetId" INT NOT NULL
  , "questionId" INT NOT NULL
  , "questionChoiceId" INT
  , "timeTaken" INT,
  , flagged BOOLEAN DEFAULT false NOT NULL
  , mark JSONB
  , "index" INT NOT NULL
  , striked INT[] DEFAULT '{}'::INT[]
  , CONSTRAINT marksheet_marksheetid_fk FOREIGN KEY ("marksheetId") REFERENCES public.marksheets(id) ON DELETE CASCADE ON UPDATE CASCADE
  , CONSTRAINT marksheet_questionid_fk FOREIGN KEY ("questionId") REFERENCES public.questions(id) ON DELETE CASCADE ON UPDATE CASCADE
  , CONSTRAINT marksheet_questionchoiceid_fk FOREIGN KEY ("questionChoiceId") REFERENCES public.question_choices(id) ON DELETE CASCADE ON UPDATE CASCADE
  , PRIMARY KEY ("id")
) PARTITION BY RANGE ("marksheetId");

CREATE INDEX ON marks.marksheet ("marksheetId");

CREATE TABLE partman.template_marks_marksheet (
  LIKE marks.marksheet INCLUDING DEFAULTS INCLUDING CONSTRAINTS INCLUDING INDEXES
  , CONSTRAINT template_marks_marksheet_marksheetid_fk FOREIGN KEY ("marksheetId") REFERENCES public.marksheets(id) ON DELETE CASCADE ON UPDATE CASCADE
  , CONSTRAINT template_marksheet_marks_questionid_fk FOREIGN KEY ("questionId") REFERENCES public.questions(id) ON DELETE CASCADE ON UPDATE CASCADE
  , CONSTRAINT template_marks_marksheet_questionchoiceid_fk FOREIGN KEY ("questionChoiceId") REFERENCES public.question_choices(id) ON DELETE CASCADE ON UPDATE CASCADE
  , PRIMARY KEY ("id")
);

SELECT partman.create_parent(
  p_parent_table := 'marks.marksheet'
  , p_control := 'marksheetId'
  , p_interval := '10000'
  , p_template_table := 'partman.template_marks_marksheet'
);

ALTER TABLE marksheet_marks SET SCHEMA marks;

CALL partman.partition_data_proc(
  p_parent_table := 'marks.marksheet'
  , p_loop_count := 55
  , p_interval := '1000'
  , p_source_table := 'marks.marksheet_marks'
);

DROP TABLE marks.marksheet_marks CASCADE;

-- should try to add constraints based on id, createdAt and updatedAt for stale tables
-- this will improve any WHERE requests we do for analysis on this table

UPDATE partman.part_config SET 
  constraint_cols = '{"id", "createdAt", "updatedAt"}'
  , optimize_constraint = 10 -- apply constraints to child tables older than the previous 10
WHERE
  parent_table = 'marks.marksheet';

-- SELECT partman.apply_constraints('marks.marksheet', 'marks.marksheet_p0', TRUE);

CREATE TABLE deleted.marks_marksheet (
  "deletedAt" TIMESTAMP DEFAULT now()
  , LIKE marks.marksheet INCLUDING ALL
);

CREATE VIEW combined.marks_marksheet AS (
  SELECT NULL AS "deletedAt"
  , *
  FROM marks.marksheet
  UNION ALL
  SELECT * FROM deleted.marks_marksheet
);

CREATE TRIGGER marks_marksheet_deleted_at
AFTER DELETE ON marks.marksheet
FOR EACH ROW
EXECUTE PROCEDURE soft_delete_partition();