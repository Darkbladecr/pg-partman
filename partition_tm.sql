CREATE SCHEMA IF NOT EXISTS marks;

CREATE TABLE marks.todo (
  id BIGINT NOT NULL
  , "createdAt" TIMESTAMPTZ NOT NULL DEFAULT now()
  , "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT now()
  , "todoId" INT NOT NULL
  , "cardId" INT NOT NULL
  , score SMALLINT
  , "timeTaken" INT,
  , CONSTRAINT todo_todoid_fk FOREIGN KEY ("todoId") REFERENCES public.todos(id) ON DELETE CASCADE ON UPDATE CASCADE
  , CONSTRAINT todo_cardid_fk FOREIGN KEY ("cardId") REFERENCES public.cards(id) ON DELETE CASCADE ON UPDATE CASCADE
  , PRIMARY KEY ("id")
) PARTITION BY RANGE ("todoId");

CREATE INDEX ON marks.todo ("todoId");

CREATE TABLE partman.template_marks_todo (
  LIKE marks.todo INCLUDING DEFAULTS INCLUDING CONSTRAINTS INCLUDING INDEXES
  , CONSTRAINT template_marks_todo_todoid_fk FOREIGN KEY ("todoId") REFERENCES public.todos(id) ON DELETE CASCADE ON UPDATE CASCADE
  , CONSTRAINT template_marks_todo_cardid_fk FOREIGN KEY ("cardId") REFERENCES public.cards(id) ON DELETE CASCADE ON UPDATE CASCADE
  , PRIMARY KEY ("id")
);

SELECT partman.create_parent(
  p_parent_table := 'marks.todo'
  , p_control := 'todoId'
  , p_interval := '10000'
  , p_template_table := 'partman.template_marks_todo'
);

ALTER TABLE todo_marks SET SCHEMA marks;

CALL partman.partition_data_proc(
  p_parent_table := 'marks.todo'
  , p_loop_count := 55
  , p_interval := '1000'
  , p_source_table := 'marks.todo_marks'
);

DROP TABLE marks.todo_marks CASCADE;

-- should try to add constraints based on id, createdAt and updatedAt for stale tables
-- this will improve any WHERE requests we do for analysis on this table

UPDATE partman.part_config SET 
  constraint_cols = '{"id", "createdAt", "updatedAt"}'
  , optimize_constraint = 10 -- apply constraints to child tables older than the previous 10
WHERE
  parent_table = 'marks.todo';

-- SELECT partman.apply_constraints('marks.todo', 'marks.todo_p0', TRUE);