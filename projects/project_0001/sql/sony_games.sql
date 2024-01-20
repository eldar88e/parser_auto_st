create table sony_games
(
    `id`                           BIGINT(20) AUTO_INCREMENT PRIMARY KEY,

    `pagetitle`                    VARCHAR(200)       DEFAULT NULL,
    `longtitle`                    VARCHAR(255)       DEFAULT NULL,
    description                    VARCHAR(1000)      DEFAULT NULL,
    alias                          VARCHAR(200)       DEFAULT NULL,
    published                      tinyint(1)         DEFAULT 0,
    parent                         int(10)            DEFAULT 0,
    template                       int(10)            DEFAULT 0,
    menuindex                      int(10)            DEFAULT 0,
    properties                     mediumtext         DEFAULT NULL,
    deleted                        TINYINT(1)         DEFAULT 0,
    publishedon                    int(20)            DEFAULT NULL,
    publishedby                    int(10)            DEFAULT 0,
    createdon                      int(20)            DEFAULT NULL,
    createdby                      int(10)            DEFAULT 0,
    editedon                       int(20)            DEFAULT NULL,
    editedby                       int(10)            DEFAULT 0,
    deletedon                      int(20)            DEFAULT NULL,
    deletedby                      int(10)            DEFAULT 0,
    uri                            VARCHAR(255)       DEFAULT NULL,
    show_in_tree                   TINYINT(1)         DEFAULT 0,

    UNIQUE `uri` (`uri`),
    INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
