CREATE SCHEMA IF NOT EXISTS user_completed;

CREATE TABLE user_completed.questions_first_attempt (
  "createdAt" TIMESTAMPTZ NOT NULL DEFAULT now()
  , "userId" INT NOT NULL
  , "questionId" INT NOT NULL
  , answer BOOLEAN NOT NULL
  , CONSTRAINT questions_first_attempt_userid_fk FOREIGN KEY ("userId") REFERENCES public.users(id) ON DELETE CASCADE ON UPDATE CASCADE
  , CONSTRAINT questions_first_attempt_questionid_fk FOREIGN KEY ("questionId") REFERENCES public.questions(id) ON DELETE CASCADE ON UPDATE CASCADE
  , PRIMARY KEY ("userId", "questionId")
) PARTITION BY RANGE ("userId");

CREATE INDEX ON user_completed.questions_first_attempt ("userId");

CREATE TABLE partman.template_user_completed_questions_first_attempt (
  LIKE user_completed.questions_first_attempt INCLUDING DEFAULTS INCLUDING CONSTRAINTS INCLUDING INDEXES
  , CONSTRAINT template_user_completed_questions_first_attempt_questionid_fk FOREIGN KEY ("questionId") REFERENCES public.questions(id) ON DELETE CASCADE ON UPDATE CASCADE
  , CONSTRAINT template_user_completed_questions_first_attempt_userid_fk FOREIGN KEY ("userId") REFERENCES public.users(id) ON DELETE CASCADE ON UPDATE CASCADE
  , PRIMARY KEY ("userId", "questionId")
);

SELECT partman.create_parent(
  p_parent_table := 'user_completed.questions_first_attempt'
  , p_control := 'userId'
  , p_interval := '10000'
  , p_template_table := 'partman.template_user_completed_questions_first_attempt'
);

ALTER TABLE user_questions_first_attempt SET SCHEMA user_completed;

CALL partman.partition_data_proc(
  p_parent_table := 'user_completed.questions_first_attempt'
  , p_loop_count := 55
  , p_interval := '1000'
  , p_source_table := 'user_completed.user_questions_first_attempt'
);

DROP TABLE user_completed.user_questions_first_attempt CASCADE;
