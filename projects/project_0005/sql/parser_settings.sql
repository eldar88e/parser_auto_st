create table settings
(
    `id`                       BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    variable                   VARCHAR(255)       DEFAULT NULL,
    value                      VARCHAR(255)       DEFAULT NULL,
    description                VARCHAR(255)       DEFAULT NULL,
    `created_at`               DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`               TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci
  COMMENT 'Parser settings table';