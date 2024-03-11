CREATE SCHEMA IF NOT EXISTS user_completed;

CREATE TABLE user_completed.cards (
  id BIGINT NOT NULL
  , "createdAt" TIMESTAMPTZ NOT NULL DEFAULT now()
  , "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT now()
  , "cardId" INT NOT NULL REFERENCES cards(id) ON DELETE CASCADE ON UPDATE CASCADE
  , "userId" INT NOT NULL REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
  , "lastSeen" TIMESTAMPTZ
  , score float4
  , iteration int4 DEFAULT 0
  , "reviewDate" timestamptz
  , "optimalFactor" float4 DEFAULT '2'::REAL NOT NULL
  , PRIMARY KEY ("userId", "cardId")
) PARTITION BY RANGE ("userId");

CREATE INDEX ON user_completed.cards ("userId");

CREATE TABLE partman.template_user_completed_cards (
  LIKE user_completed.cards INCLUDING DEFAULTS INCLUDING CONSTRAINTS INCLUDING INDEXES
  , CONSTRAINT template_user_completed_cards_cardid_fk FOREIGN KEY ("cardId") REFERENCES cards(id) ON DELETE CASCADE ON UPDATE CASCADE
  , CONSTRAINT template_user_completed_cards_userid_fk FOREIGN KEY ("userId") REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
  , PRIMARY KEY ("userId", "cardId")
);

SELECT partman.create_parent(
  p_parent_table := 'user_completed.cards'
  , p_control := 'userId'
  , p_interval := '10000'
  , p_template_table := 'partman.template_user_completed_cards'
);

ALTER TABLE user_completed_cards SET SCHEMA user_completed;

CALL partman.partition_data_proc(
  p_parent_table := 'user_completed.cards'
  , p_loop_count := 55
  , p_interval := '1000'
  , p_source_table := 'user_completed.user_completed_cards'
);

DROP TABLE user_completed.user_completed_cards CASCADE;

ALTER TABLE user_completed.cards DROP COLUMN id;

ALTER TABLE partman.template_user_completed_cards DROP COLUMN id;
