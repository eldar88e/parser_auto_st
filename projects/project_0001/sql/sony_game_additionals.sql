create table sony_game_additionals
(
    `id`                           BIGINT(20) AUTO_INCREMENT PRIMARY KEY,

    article                        varchar(50)       DEFAULT NULL,
    made_in                        varchar(255)      DEFAULT NULL,
    price                          decimal(10,2)     DEFAULT 0.00,
    price_tl                       decimal(10,2)     DEFAULT NULL,
    old_price                      decimal(10,2)     DEFAULT 0.00,
    old_price_tl                   decimal(10,2)     DEFAULT NULL,
    price_bonus                    decimal(10,2)     DEFAULT NULL,
    price_bonus_tl                 decimal(10,2)     DEFAULT NULL,
    image                          VARCHAR(255)      DEFAULT NULL,
    thumb                          VARCHAR(255)      DEFAULT NULL,
    new                            tinyint(1)        DEFAULT 0,
    popular                        tinyint(1)        DEFAULT 0,
    source	                       int(10)		     DEFAULT 1,
    site_link                      VARCHAR(255)      DEFAULT NULL,
    discount_end_date              DATETIME          DEFAULT NULL,
    platform                       VARCHAR(30)       DEFAULT NULL,
    type_game                      VARCHAR(20)       DEFAULT NULL,
    image_link_raw                 VARCHAR(255)      DEFAULT NULL,
    data_source_url                VARCHAR(255)      DEFAULT NULL,
    janr                           VARCHAR(255)      DEFAULT NULL,
    publisher                      VARCHAR(255)      DEFAULT NULL,
    genre                          VARCHAR(255)      DEFAULT NULL,
    `release`                      DATE              NULL,
    rus_voice                      tinyint(1)        DEFAULT 0,
    rus_screen                     tinyint(1)        DEFAULT 0,

    `run_id`                       BIGINT(20)        DEFAULT NULL,
    `touched_run_id`               BIGINT(20)        DEFAULT NULL,
    `md5_hash`                     VARCHAR(32)       DEFAULT NULL,
    UNIQUE KEY `md5` (`md5_hash`),
    INDEX `new` (`new`),
    INDEX `popular` (`popular`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
