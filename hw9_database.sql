/* Практическое задание по теме “Транзакции, переменные, представления” */
/* 1. В базе данных shop и sample присутствуют одни и те же таблицы, учебной базы данных. 
 * Переместите запись id = 1 из таблицы shop.users в таблицу sample.users. Используйте транзакции. */

START TRANSACTION;

INSERT INTO sample.users 
SELECT id, name FROM shop.users
WHERE shop.users.id = 1;

COMMIT;

SELECT *
FROM sample.users;

/* 2. Создайте представление, которое выводит название name товарной позиции из таблицы products и 
 * соответствующее название каталога name из таблицы catalogs.
 */
CREATE VIEW goods AS SELECT p.name Product_name, c.name Catalog_name 
FROM products p JOIN catalogs c ON p.catalog_id = c.id;

/* 3. по желанию) Пусть имеется таблица с календарным полем created_at. В ней размещены разряженые
 * календарные записи за август 2018 года '2018-08-01', '2016-08-04', '2018-08-16' и 2018-08-17.
 * Составьте запрос, который выводит полный список дат за август, выставляя в соседнем поле
 * значение 1, если дата присутствует в исходном таблице и 0, если она отсутствует.
 */
CREATE TEMPORARY TABLE temp_date1 (created_at DATE);
INSERT INTO temp_date1 VALUES
('2018.08.01'),
('2018.08.04'),
('2018.08.16'),
('2018.08.17');
CREATE TEMPORARY TABLE temp_date2 (tmp_date DATE);
INSERT INTO temp_date2 VALUES
('2018.08.01'),
('2018.08.02'),
('2018.08.03'),
('2018.08.04'),
('2018.08.05'),
('2018.08.06'),
('2018.08.07'),
('2018.08.08'),
('2018.08.09'),
('2018.08.10'),
('2018.08.11'),
('2018.08.12'),
('2018.08.13'),
('2018.08.14'),
('2018.08.15'),
('2018.08.16'),
('2018.08.17'),
('2018.08.18'),
('2018.08.19'),
('2018.08.20'),
('2018.08.21'),
('2018.08.22'),
('2018.08.23'),
('2018.08.24'),
('2018.08.25'),
('2018.08.26'),
('2018.08.27'),
('2018.08.28'),
('2018.08.29'),
('2018.08.30'),
('2018.08.31');
SELECT tmp_date, (SELECT EXISTS(SELECT * FROM temp_date1 WHERE created_at = tmp_date)) has_exist FROM temp_date2;

/* Практическое задание по теме “Администрирование MySQL” (эта тема изучается по вашему желанию) */
/* 1. Создайте двух пользователей которые имеют доступ к базе данных shop. Первому пользователю shop_read 
 * должны быть доступны только запросы на чтение данных, второму пользователю shop — любые операции в пределах базы данных shop.
 */
GRANT SELECT ON shop.* TO 'shop_read'@'localhost' IDENTIFIED WITH sha256_password BY 'pa$S1234';
GRANT ALL ON shop.* TO 'shop'@'localhost' IDENTIFIED WITH sha256_password BY 'pa$S1234';

/* Практическое задание по теме “Хранимые процедуры и функции, триггеры" */
/* 1. Создайте хранимую функцию hello(), которая будет возвращать приветствие, в зависимости от текущего времени суток. 
 * С 6:00 до 12:00 функция должна возвращать фразу "Доброе утро", с 12:00 до 18:00 функция должна возвращать фразу "Добрый день",
 * с 18:00 до 00:00 — "Добрый вечер", с 00:00 до 6:00 — "Доброй ночи".
 */
DELIMITER //
DROP FUNCTION IF EXISTS hello//
CREATE FUNCTION hello()
RETURNS VARCHAR(255)
BEGIN
	CASE
		WHEN CURRENT_TIME() BETWEEN '06:00:00' AND '12:00:00' THEN
			RETURN 'Доброе утро';
		WHEN CURRENT_TIME() BETWEEN '12:00:00' AND '18:00:00' THEN
			RETURN 'Добрый день';
		WHEN CURRENT_TIME() BETWEEN '18:00:00' AND '24:00:00' THEN
			RETURN 'Добрый вечер';
		WHEN CURRENT_TIME() BETWEEN '00:00:00' AND '06:00:00' THEN
			RETURN 'Доброй ночи';
	END CASE;
END//
DELIMITER ;

SELECT CURRENT_TIME(), hello();

/* 2. В таблице products есть два текстовых поля: name с названием товара и description с его описанием. 
 * Допустимо присутствие обоих полей или одно из них. Ситуация, когда оба поля принимают неопределенное значение NULL неприемлема.
 * Используя триггеры, добейтесь того, чтобы одно из этих полей или оба поля были заполнены.
 * При попытке присвоить полям NULL-значение необходимо отменить операцию.
 */
DELIMITER //
DROP TRIGGER IF EXISTS check_product_insert//
CREATE TRIGGER check_product_insert BEFORE INSERT ON products
FOR EACH ROW 
BEGIN
	IF ISNULL(NEW.name) AND ISNULL(NEW.description) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INSERT canceled';
	END IF;
END//
DROP TRIGGER IF EXISTS check_product_update//
CREATE TRIGGER check_product_update BEFORE UPDATE ON products
FOR EACH ROW 
BEGIN
	IF ISNULL(NEW.name) AND ISNULL(NEW.description) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Update canceled';
	END IF;
END//

DELIMITER ;

INSERT INTO products (name, description, price, catalog_id)
VALUES (NULL, NULL, 1000, 1); -- FAILED
INSERT INTO products (name, description, price, catalog_id)
VALUES (NULL, 'Processor', 1000, 1); -- SUCCESS
INSERT INTO products (name, description, price, catalog_id)
VALUES ('Intel Core Gen 10', NULL, 1000, 1); -- SUCCESS

SELECT * FROM products;

UPDATE products SET description = NULL WHERE name IS NULL; -- FAILED
 