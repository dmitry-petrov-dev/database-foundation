/* 1. Составьте список пользователей users, которые осуществили хотя бы один заказ orders в интернет магазине. */
SELECT count(id) FROM orders;

-- Вариант 1
SELECT u.id, u.name, count(o.id) as total_orders
FROM users u JOIN orders o ON u.id = o.user_id
GROUP BY u.id, u.name;

-- Вариант 2
SELECT u.id, u.name
FROM users u
WHERE u.id IN (SELECT user_id FROM orders);

/* 2. Выведите список товаров products и разделов catalogs, который соответствует товару. */
SELECT p.id, p.name product_name, p.description, p.price, c.name `catalog`
FROM products p JOIN catalogs c ON p.catalog_id = c.id ;

/* 3. (по желанию) Пусть имеется таблица рейсов flights (id, from, to) и таблица городов cities (label, name). 
 * Поля from, to и label содержат английские названия городов, поле name — русское. Выведите список рейсов
 * flights с русскими названиями городов.
 */ 

DROP TABLE IF EXISTS `flights`;
CREATE TABLE `flights` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `from` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `to` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
);

INSERT INTO `flights` VALUES 
('1','moscow', 'omsk'),
('2','novgorod', 'kazan'),
('3','irkutsk', 'moscow'),
('4','omsk', 'irkutsk'),
('5','moscow', 'kazan'); 

DROP TABLE IF EXISTS `cities`;
CREATE TABLE `cities` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `label` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  UNIQUE unique_name(label(10)),
  PRIMARY KEY (`id`)
);

INSERT INTO `cities` VALUES 
('1','moscow', 'Москва'),
('2','irkutsk', 'Иркутск'),
('3','novgorod', 'Новгород'),
('4','kazan', 'Казань'),
('5','omsk', 'Омск'); 

SELECT f.id, c_from.name from_city, c_to.name to_city
FROM flights f JOIN cities c_from ON f.`from` = c_from.label JOIN cities c_to ON f.`to` = c_to.label;