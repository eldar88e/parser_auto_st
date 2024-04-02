create table sony_game_intro
(
    resource                         BIGINT(20)       DEFAULT NULL,
    intro                            TEXT             DEFAULT NULL,
    INDEX `resource` (`resource`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
