CREATE TABLE `executor` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `host` VARCHAR(256) NOT NULL,
  `geohash` VARCHAR(256) NOT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
  -- SPATIAL KEY `location` (`location`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;