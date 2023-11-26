create table sony_game_additional_files
(
    `id`                           BIGINT(20) AUTO_INCREMENT PRIMARY KEY,

    product_id                     int(10)           DEFAULT NULL,
    source	                       int(10)           DEFAULT 1,
    parent	                       int(10)           DEFAULT 0,
    name	                       varchar(255)      DEFAULT NULL,
    path	                       varchar(255)      DEFAULT NULL,
    file	                       varchar(255)      DEFAULT NULL,
    type                       	   varchar(50)       DEFAULT NULL,
    createdon	                   DATETIME          DEFAULT NULL,
    createdby	                   int(10)           DEFAULT NULL,
    rank	                       tinyint(1)        DEFAULT 0,
    url	                           varchar(255)      DEFAULT NULL,
    INDEX `product_id` (`product_id`),
    INDEX `parent` (`parent`)
) DEFAULT CHARSET = `utf8mb4`
  COLLATE = utf8mb4_unicode_520_ci;
