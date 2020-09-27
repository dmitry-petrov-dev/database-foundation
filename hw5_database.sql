/************* Task 1 ***************************************************************************************************/
/* Пусть в таблице users поля created_at и updated_at оказались незаполненными. Заполните их текущими датой и временем. */
/************************************************************************************************************************/
ALTER TABLE users 
	ADD created_at datetime DEFAULT current_timestamp(), 
	ADD updated_at datetime DEFAULT NULL ON UPDATE current_timestamp();

UPDATE users 
SET created_at = NOW(), updated_at = NOW();

/************* Task 2 ***************************************************************************************************/
/* Таблица users была неудачно спроектирована. Записи created_at и updated_at были заданы типом VARCHAR и в них долгое	*/ 
/* время помещались значения в формате "20.10.2017 8:10". Необходимо преобразовать поля к типу DATETIME, сохранив		*/ 
/* введеные ранее значения. 																							*/
/************************************************************************************************************************/
ALTER TABLE users 
	DROP created_at, 
	DROP updated_at;
ALTER TABLE users 
	ADD created_at VARCHAR(20), 
	ADD updated_at VARCHAR(20);
UPDATE users 
SET created_at = DATE_FORMAT(NOW(), '%d-%m-%Y %H:%i:%s'), updated_at = DATE_FORMAT(NOW(), '%d-%m-%Y %H:%i:%s');

CREATE TABLE `users_new` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `firstname` varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL,
  `lastname` varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL COMMENT 'Фамиль',
  `email` varchar(120) COLLATE utf8_unicode_ci DEFAULT NULL,
  `password_hash` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL,
  `phone` bigint(20) unsigned DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(), 
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`),
  UNIQUE KEY `phone` (`phone`),
  KEY `users_firstname_lastname_idx` (`firstname`,`lastname`));
  
INSERT INTO `users_new`
SELECT id, firstname, lastname, email, password_hash, phone, STR_TO_DATE(created_at, '%d-%m-%Y %H:%i:%s'), STR_TO_DATE(updated_at, '%d-%m-%Y %H:%i:%s')
FROM users;

/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
DROP TABLE users;
ALTER TABLE users_new  RENAME users;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;

/************* Task 3 ***************************************************************************************************/
/* В таблице складских запасов storehouses_products в поле value могут встречаться самые разные цифры: 0, если товар	*/
/* закончился и выше нуля, если на складе имеются запасы. Необходимо отсортировать записи таким образом, чтобы они 		*/
/* выводились в порядке увеличения значения value. Однако, нулевые запасы должны выводиться в конце, после всех записей.*/
/************************************************************************************************************************/
DROP TABLE IF EXISTS storehouses_products;
CREATE TABLE storehouses_products (
  id SERIAL PRIMARY KEY,
  storehouse_id INT UNSIGNED,
  product_id INT UNSIGNED,
  value INT UNSIGNED COMMENT 'Запас товарной позиции на складе',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) COMMENT = 'Запасы на складе';

INSERT INTO `storehouses_products` (`id`, `storehouse_id`, `product_id`, `value`, `created_at`, `updated_at`) VALUES 
('1', 1, 9, 0, '1991-12-17 23:13:25', '1971-12-29 02:51:03'),
('2', 6, 1, 0, '1979-08-24 01:07:23', '2014-05-08 04:05:16'),
('3', 4, 2, 2500, '2003-07-28 13:15:52', '2006-11-06 18:06:39'),
('4', 8, 9, 0, '1991-01-24 09:16:26', '2008-01-30 06:56:06'),
('5', 3, 8, 30, '2017-08-02 12:49:05', '2013-04-11 21:24:31'),
('6', 7, 9, 500, '2019-12-31 23:13:47', '1977-11-09 17:32:17'),
('7', 8, 3, 1, '2009-06-21 18:35:46', '1977-10-26 22:04:03');

SELECT `value`
FROM `storehouses_products`
order by case when `value` = 0 then 1 else 0 end, `value`

/************* Task 2.1 ***************************************************************************************************/
/* Практическое задание теме “Агрегация данных”																			  */
/* Подсчитайте средний возраст пользователей в таблице users															  */
/**************************************************************************************************************************/
DROP TABLE IF EXISTS users;
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255),
  birthday_at DATE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) COMMENT = 'Покупатели';

INSERT INTO users (name, birthday_at) VALUES
  ('Gennadiy', '1990-10-05'),
  ('Natalia', '1984-11-12'),
  ('Aleksander', '1985-05-20'),
  ('Sergey', '1988-02-14'),
  ('Ivan', '1998-01-12'),
  ('Maria', '1992-08-29');
 
 SELECT AVG(TIMESTAMPDIFF(YEAR, birthday_at, NOW())) average_age
 FROM users;

/************* Task 2.2 ***************************************************************************************************/
/* Подсчитайте количество дней рождения, которые приходятся на каждый из дней недели. Следует учесть, что необходимы дни  */
/* недели текущего года, а не года рождения.																		   	  */
/**************************************************************************************************************************/
SELECT DATE_FORMAT(DATE(CONCAT(YEAR(NOW()), "-", MONTH(birthday_at), "-", DAY(birthday_at))), '%W') as day_of_week, count(*) as total
 from users
group by day_of_week;