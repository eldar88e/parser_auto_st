create table sony_games
(
    `id`                           BIGINT(20) AUTO_INCREMENT PRIMARY KEY,

    `pagetitle`                    VARCHAR(200)       DEFAULT NULL,
    `longtitle`                    VARCHAR(255)       DEFAULT NULL,
    description                    VARCHAR(1000)       DEFAULT NULL,
    alias                          VARCHAR(200)       DEFAULT NULL,
    parent                         int(10)            DEFAULT 0,
    properties                     mediumtext         DEFAULT NULL,
    deleted                        TINYINT(1)         DEFAULT 0,
    publishedon                    int(20)            DEFAULT NULL,
    editedon                       int(20)            DEFAULT NULL,

    INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;