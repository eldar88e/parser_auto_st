create table sony_games_products
(
    `id`                           BIGINT(20) AUTO_INCREMENT PRIMARY KEY,

    article                        varchar(50)       DEFAULT NULL,
    prise                          decimal(10,2)     DEFAULT 0.00,
    old_prise                      decimal(10,2)     DEFAULT 0.00,
    image                          VARCHAR(255)      DEFAULT NULL,
    thumb                          VARCHAR(255)      DEFAULT NULL,
    new                            tinyint(1)        DEFAULT 0,
    popular                        tinyint(1)        DEFAULT 0,
    source	                       int(10)		     DEFAULT 1,
    price_tl                       decimal(10,2)     DEFAULT 0.00,
    old_price_tl                   decimal(10,2)     DEFAULT 0.00,
    link                           VARCHAR(255)      DEFAULT NULL,

    INDEX `new` (`new`),
    INDEX `popular` (`popular`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;