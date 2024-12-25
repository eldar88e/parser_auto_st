create table settings
(
    `id`                       BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
    site                       VARCHAR(255)       DEFAULT NULL,
    path_tr                    VARCHAR(255)       DEFAULT NULL,
    path_ru                    VARCHAR(255)       DEFAULT NULL,
    params                     VARCHAR(255)       DEFAULT NULL,
    ps_game                    VARCHAR(255)       DEFAULT NULL,
    dd_game                    VARCHAR(255)       DEFAULT NULL,
    exchange_rate              decimal(3,1)       DEFAULT 1,
    round_price                INT(10)            DEFAULT 1,
    parent_ps5                 INT(10)            DEFAULT NULL,
    parent_ps4                 INT(10)            DEFAULT NULL,
    template_id                INT(10)            DEFAULT NULL,
    limit_upd_lang             INT(10)            DEFAULT 0,
    user_id                    INT(10)            DEFAULT 1,
    limit_export               INT(10)            DEFAULT 0,
    small_size                 VARCHAR(255)       DEFAULT NULL,
    medium_size                VARCHAR(255)       DEFAULT NULL,
    touch_update_desc    tinyint(1)         DEFAULT 0,
    month_since_release        INT(10)            DEFAULT 6,
    day_all_lang_scrap         INT(10)            DEFAULT 0,
    telegram_chat_id           VARCHAR(255)       DEFAULT NULL,
    `created_at`               DATETIME           DEFAULT CURRENT_TIMESTAMP,
    `updated_at`               TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
