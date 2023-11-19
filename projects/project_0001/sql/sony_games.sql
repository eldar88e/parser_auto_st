create table sony_games
(
    `id`                           BIGINT(20) AUTO_INCREMENT PRIMARY KEY,

    `name`                         VARCHAR(200)        DEFAULT NULL,
    `platform`                     VARCHAR(20)        DEFAULT NULL,
    `type`                         VARCHAR(20)       DEFAULT NULL,
    `prise_tl`                     VARCHAR(20)       DEFAULT NULL,
    `prise`                        float(7,2)        DEFAULT NULL,
    `prise_discount_tl`            VARCHAR(20)       DEFAULT NULL,
    prise_discount                 float(7,2)        DEFAULT NULL,
    discount_pct                   INT               DEFAULT NULL,
    discount_end_raw               VARCHAR(100)      DEFAULT NULL,

    discount_end_day               DATETIME           DEFAULT NULL,
    image_link_raw                 VARCHAR(255)       DEFAULT NULL,
    image_link                     VARCHAR(255)       DEFAULT NULL,

    link                           VARCHAR(255)       DEFAULT NULL,
    url_end_uniq                   VARCHAR(255)       DEFAULT NULL,
    `data_source_url`              VARCHAR(255)       DEFAULT NULL,
    `md5_hash`                     VARCHAR(32)        DEFAULT NULL,
    `run_id`                       BIGINT(20),
    `touched_run_id`                       BIGINT(20),
    `deleted`                      TINYINT(1)         DEFAULT 0,
    `created_by`                   VARCHAR(20)        DEFAULT 'Eldar Eminov',
    `created_at`                   DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`                   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `md5` (`md5_hash`),
    UNIQUE KEY `ein` (`url_end_uniq`),
    INDEX `deleted` (`deleted`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;