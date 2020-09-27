/* Практическое задание по теме “Оптимизация запросов” */
/* 1. Создайте таблицу logs типа Archive. Пусть при каждом создании записи в таблицах users, 
 * catalogs и products в таблицу logs помещается время и дата создания записи, название таблицы, 
 * идентификатор первичного ключа и содержимое поля name.
 */
DROP TABLE IF EXISTS `logs`;
CREATE TABLE `logs` (
	`created_at` datetime DEFAULT current_timestamp(),
	`table_name` varchar(255),
	`id` bigint(20) unsigned,
	`name` varchar(255)
) ENGINE=Archive;


DELIMITER //
DROP TRIGGER IF EXISTS log_users_insert//
CREATE TRIGGER log_users_insert AFTER INSERT ON users
FOR EACH ROW 
BEGIN
	INSERT INTO logs (table_name, id, name)
	VALUES ('users', NEW.id, NEW.name);
END//

DROP TRIGGER IF EXISTS log_catalogs_insert//
CREATE TRIGGER log_catalogs_insert AFTER INSERT ON catalogs
FOR EACH ROW 
BEGIN
	INSERT INTO logs (table_name, id, name)
	VALUES ('catalogs', NEW.id, NEW.name);
END//

DROP TRIGGER IF EXISTS log_products_insert//
CREATE TRIGGER log_products_insert AFTER INSERT ON products
FOR EACH ROW 
BEGIN
	INSERT INTO logs (table_name, id, name)
	VALUES ('products', NEW.id, NEW.name);
END//

DELIMITER ;

INSERT INTO users (name, birthday_at)
VALUES ('Dmitry', '2000-01-10'), ('Tatiana', '2000-01-10');
SELECT * from users;

INSERT INTO catalogs (name)
VALUES ('Клавиатура'), ('Монитор');
SELECT * FROM catalogs;

INSERT INTO products (name, description, price, catalog_id)
VALUES ('SAMSUNG S27E390H', 'Монитор SAMSUNG S27E390H, 27", черный', 11450, (SELECT id FROM catalogs where name = 'Монитор' LIMIT 1));
SELECT * FROM products;

SELECT * FROM logs;