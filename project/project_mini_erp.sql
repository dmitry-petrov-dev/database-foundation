/* База данных разработана для решения задач по управлению предприятия.  */
/* Текущая версия Базы данные хранит информацию по закупаемым материалам - заказы поставщиков и текущая информация по запасам на складах. */

/*** Генереция базы данных и таблиц ***/
DROP DATABASE IF EXISTS mini_erp;
CREATE DATABASE mini_erp;
USE mini_erp;

/* Таблица для фотографий сотрудников и изделий */
DROP TABLE IF EXISTS `photos`;
CREATE TABLE `photos`(
    `id` SERIAL,
    `description` VARCHAR(255),
    `filename` VARCHAR(255),
    `size` INT,
    `metadata` JSON,
    `created_at` DATETIME DEFAULT NOW(),
    `updated_at` DATETIME ON UPDATE CURRENT_TIMESTAMP
);

/* Таблица пользователей системы */
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users`(
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, 
    `firstname` VARCHAR(50),
    `lastname` VARCHAR(50),
    `email` VARCHAR(120) UNIQUE,
    `login` VARCHAR(50) UNIQUE,
    `password_hash` VARCHAR(100), 
	
    INDEX users_firstname_lastname_idx(firstname, lastname)
);

/* Таблица с данными сотрудников */
DROP TABLE IF EXISTS `employee`;
CREATE TABLE `employee`(
    `user_id` BIGINT UNSIGNED NOT NULL UNIQUE,
    `gender` CHAR(1),
    `birthday` DATE,
    `photo_id` BIGINT UNSIGNED NULL,
    `position` VARCHAR(50),
    `employment_date` DATETIME,
    `last_date_of_employment` DATETIME,
    `created_at` DATETIME DEFAULT NOW(),
    `updated_at` DATETIME ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (photo_id) REFERENCES photos(id)
);

/* Таблица с данными по единицам измерения */
DROP TABLE IF EXISTS `units`;
CREATE TABLE `units`(
    `id` SERIAL PRIMARY KEY,
    `code` VARCHAR(3),
    `description` VARCHAR(50),
    `created_at` DATETIME DEFAULT NOW(),
    `updated_at` DATETIME ON UPDATE CURRENT_TIMESTAMP
);

/* Справочник изделий */
DROP TABLE IF EXISTS `items`;
CREATE TABLE `items`(
    `item_id` SERIAL PRIMARY KEY,
    `product_name` VARCHAR(50),
    `description` VARCHAR(100),
    `item_type`  ENUM('Purchased', 'Manufactured'),
    `unit_id` BIGINT UNSIGNED NOT NULL,
    `weight_unit_id` BIGINT UNSIGNED NOT NULL,
    `weight` FLOAT UNSIGNED,
    `photo_id` BIGINT UNSIGNED NULL,
    `created_at` DATETIME DEFAULT NOW(),
    `updated_at` DATETIME ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (unit_id) REFERENCES units(id),
    FOREIGN KEY (weight_unit_id) REFERENCES units(id),
    FOREIGN KEY (photo_id) REFERENCES photos(id)
);

/* Справочник валют */
DROP TABLE IF EXISTS `currencies`;
CREATE TABLE `currencies`(
    `id` SERIAL PRIMARY KEY,
    `currency_code` CHAR(3),
    `description` VARCHAR(100), 
    `created_at` DATETIME DEFAULT NOW(),
    `updated_at` DATETIME ON UPDATE CURRENT_TIMESTAMP
);

/* Справочник контрагентов */
DROP TABLE IF EXISTS `business_partners`;
CREATE TABLE `business_partners`(
    `id` SERIAL PRIMARY KEY,
    `name` VARCHAR(100),
    `currency_id` BIGINT UNSIGNED NOT NULL,
    `legal_identifaction` VARCHAR(20),
    `type` ENUM('Buyer', 'Seller'),
    `contact` VARCHAR(100),
    `language` CHAR(2) DEFAULT 'ru' COMMENT 'ru or en',
    `phone` BIGINT UNSIGNED UNIQUE, 
    `created_at` DATETIME DEFAULT NOW(),
    `updated_at` DATETIME ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (currency_id) REFERENCES currencies(id)
);

/* Справочник адресов */
DROP TABLE IF EXISTS `addresses`;
CREATE TABLE `addresses`(
    `id` SERIAL PRIMARY KEY,
    `name` VARCHAR(100),
    `street` VARCHAR(100),
    `house_number` VARCHAR(10),
    `city` VARCHAR(50),
    `postal_code` VARCHAR(10),
    `phone` BIGINT UNSIGNED UNIQUE
);

/* Свзь контрагентов с адресами */
DROP TABLE IF EXISTS `business_partner_address`;
CREATE TABLE `business_partner_address`(
    `business_partner_id` BIGINT UNSIGNED NOT NULL,
    `address_id` BIGINT UNSIGNED NOT NULL,
    `status` ENUM('active', 'expired'),
    `created_at` DATETIME DEFAULT NOW(),
    `updated_at` DATETIME ON UPDATE CURRENT_TIMESTAMP,
	
    PRIMARY KEY (business_partner_id, address_id),
    FOREIGN KEY (business_partner_id) REFERENCES business_partners(id),
    FOREIGN KEY (address_id) REFERENCES addresses(id)
);

/* Справочник складов */
DROP TABLE IF EXISTS `warehouses`;
CREATE TABLE `warehouses`(
    `id` SERIAL PRIMARY KEY,
    `name` VARCHAR(100),
    `address_id` BIGINT UNSIGNED NOT NULL,
    `manager_id` BIGINT UNSIGNED NOT NULL,
    `created_at` DATETIME DEFAULT NOW(),
    `updated_at` DATETIME ON UPDATE CURRENT_TIMESTAMP,
	
    FOREIGN KEY (address_id) REFERENCES addresses(id),
    FOREIGN KEY (manager_id) REFERENCES employee(user_id)
);

/* Запас на складах */
DROP TABLE IF EXISTS `inventory_by_warehouse`;
CREATE TABLE `inventory_by_warehouse`(
    `warehouse_id` BIGINT UNSIGNED NOT NULL,
    `item_id` BIGINT UNSIGNED NOT NULL,
    `on_hand` DOUBLE DEFAULT 0.0,
    `blocked` DOUBLE DEFAULT 0.0,
    `rejected` DOUBLE DEFAULT 0.0,
    `created_at` DATETIME DEFAULT NOW(),
    `updated_at` DATETIME ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (warehouse_id, item_id),
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
    FOREIGN KEY (item_id) REFERENCES items(item_id)
);

/* Заказы поставщиков */
DROP TABLE IF EXISTS `purchase_order`;
CREATE TABLE `purchase_order`(
    `order_number_id` SERIAL PRIMARY KEY,
    `buyer_id` BIGINT UNSIGNED NOT NULL,
    `business_partner_id` BIGINT UNSIGNED NOT NULL,
    `warehouse_id` BIGINT UNSIGNED NOT NULL,
    `order_date` DATETIME DEFAULT NOW(),
    `currency_id` BIGINT UNSIGNED NOT NULL,
    `planned_receipt_date` DATETIME,
    `actual_receipt_date` DATETIME,
    `status` ENUM('created', 'approved', 'cancelled', 'released'),
	
    FOREIGN KEY (buyer_id) REFERENCES employee(user_id),
    FOREIGN KEY (business_partner_id) REFERENCES business_partners(id),
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
    FOREIGN KEY (currency_id) REFERENCES currencies(id)
);

/* Строки заказа поставщика */
DROP TABLE IF EXISTS `purchase_order_lines`;
CREATE TABLE `purchase_order_lines`(
    `order_number_id` BIGINT UNSIGNED NOT NULL,
    `line` INT UNSIGNED DEFAULT 1 NOT NULL,
    `item_id` BIGINT UNSIGNED NOT NULL,
    `ordered_quantity` DOUBLE UNSIGNED NOT NULL,
    `price` DECIMAL (11,2),
    `amount` DECIMAL (11,2),
	
    PRIMARY KEY (order_number_id, line),
    FOREIGN KEY (order_number_id) REFERENCES purchase_order(order_number_id),
    FOREIGN KEY (item_id) REFERENCES items(item_id)
);

/*** Создание триггеров ***/
DELIMITER //

DROP TRIGGER IF EXISTS update_amount_on_insert//
CREATE TRIGGER update_amount_on_insert BEFORE INSERT ON purchase_order_lines
FOR EACH ROW
BEGIN
    /* Расчет суммы по строке */
    SET NEW.amount = NEW.ordered_quantity * NEW.price;
END//

DROP TRIGGER IF EXISTS update_amount_on_update//
CREATE TRIGGER update_amount_on_update BEFORE UPDATE ON purchase_order_lines
FOR EACH ROW
BEGIN
    /* Расчет суммы по строке */
    SET NEW.amount = NEW.ordered_quantity * NEW.price;
END//

DROP TRIGGER IF EXISTS check_employee_age_before_insert//
CREATE TRIGGER check_employee_age_before_insert BEFORE INSERT ON employee
FOR EACH ROW
BEGIN
    /* Дата рождения не может быть позже текущей даты */
    IF NEW.birthday > CURRENT_DATE() THEN
        SET NEW.birthday = CURRENT_DATE();
    END IF;
END//

DROP TRIGGER IF EXISTS check_employment_date_before_insert//
CREATE TRIGGER check_employment_date_before_insert BEFORE INSERT ON employee
FOR EACH ROW
BEGIN
    /* Дата увольнения не может быть раньше чем дата приема */
    IF NEW.last_date_of_employment is not NULL and NEW.employment_date > NEW.last_date_of_employment THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INSERT canceled: last date of employment cannot be early than employment_date';
    END IF;
END//

DROP TRIGGER IF EXISTS check_employment_date_before_update//
CREATE TRIGGER check_employment_date_before_update BEFORE UPDATE ON employee
FOR EACH ROW
BEGIN
    /* Дата увольнения не может быть раньше чем дата приема */
    IF NEW.last_date_of_employment is not NULL and NEW.employment_date > NEW.last_date_of_employment THEN
 	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'UPDATE canceled: last date of employment cannot be early than employment_date';
    END IF;
END//

DROP TRIGGER IF EXISTS check_order_dates_before_insert//
CREATE TRIGGER check_order_dates_before_insert BEFORE INSERT ON purchase_order
FOR EACH ROW
BEGIN
    /* Дата заказа не может быть в будущем */
    IF NEW.order_date > NOW()
    THEN
 	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INSERT canceled: order date cannot be in future';
    END IF;

    /* Плановая дата поступления не может быть раньше чем дата заказа */    
    IF NEW.planned_receipt_date < NEW.order_date
    THEN
 	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INSERT canceled: planned receipt date cannot be early than order date';
    END IF;

    /* Фактическая дата поступления не может быть раньше чем дата заказа */
    IF NEW.actual_receipt_date is not NULL and NEW.actual_receipt_date < NEW.order_date
    THEN
 	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INSERT canceled: actual receipt date cannot be early than order date';
    END IF;
END//

DROP TRIGGER IF EXISTS check_order_dates_before_update//
CREATE TRIGGER check_order_dates_before_update BEFORE UPDATE ON purchase_order
FOR EACH ROW
BEGIN
    /* Дата заказа не может быть в будущем */
    IF NEW.order_date > NOW()
    THEN
 	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'UPDATE canceled: order date cannot be in future';
    END IF;
    
    /* Плановая дата поступления не может быть раньше чем дата заказа */
    IF NEW.planned_receipt_date < NEW.order_date
    THEN
 	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'UPDATE canceled: planned receipt date cannot be early than order date';
    END IF;
    
    /* Фактическая дата поступления не может быть раньше чем дата заказа */
    IF NEW.actual_receipt_date is not NULL and NEW.actual_receipt_date < NEW.order_date
    THEN
 	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'UPDATE canceled: actual receipt date cannot be early than order date';
    END IF;
END//

DELIMITER ;


/*** Генерация данный в таблицах ****/
INSERT INTO `photos` VALUES ('1','Omnis dolorem natus ipsa iure in possimus. Unde voluptatem sed aspernatur impedit eius. Magni eum temporibus aut quisquam et.','/0ffc9c3115c7a79a444e2fa4302525b1.jpg','20693',NULL,'2001-02-08 16:04:55','2020-01-31 23:18:37'),
('2','Voluptates qui sint iste aspernatur itaque iste. Dicta occaecati exercitationem illum nam harum aut tenetur. Aut sunt ut incidunt pariatur commodi ut consequatur et.','/14804cfb6f6fad3dfdf4e9bf3d851f10.jpg','18394',NULL,'1972-09-27 15:25:08','1977-02-12 05:04:55'),
('3','Modi iure velit qui quia dolores iusto debitis. Rem ipsa unde doloremque qui quia et. Enim at cumque voluptas nihil. Blanditiis aut dolorum laudantium cupiditate quis nesciunt ut qui.','/2cffffaf37e7d2a67b2f7f35e5e1bc1d.jpg','29928',NULL,'2007-04-23 23:09:52','1979-10-18 08:22:15'),
('4','Odio ipsa ducimus quia ex voluptas. Earum aut qui voluptatem suscipit qui. Aliquid aut ex excepturi necessitatibus harum temporibus fuga. Sed et voluptatem architecto.','/187899fded16562e34923d8a7c4b9477.jpg','38026',NULL,'1994-05-04 22:39:52','1986-09-07 17:02:08'),
('5','Debitis error dicta rerum laudantium quis aperiam doloribus. Est aut consequuntur alias. Qui et perferendis error est nulla id. Rerum vel modi cupiditate et nam est beatae neque.','/5d05173c698928d6e128b3e9107b4e8b.jpg','14273',NULL,'2019-06-23 01:18:06','2007-10-21 13:11:00'),
('6','Et id totam ullam totam qui itaque. Veniam necessitatibus necessitatibus non qui. Doloribus facere sint rerum. Qui tenetur labore est culpa temporibus placeat laborum.','/be3ee1a87443881893d642950d9c5e46.jpg','33640',NULL,'2018-07-16 10:55:42','2002-05-08 07:18:42'),
('7','Sed nostrum rerum fugiat reiciendis est hic voluptas. Officia tempora suscipit dolorem dolorum sequi ut vel. Voluptatem numquam labore vero neque. Rerum quidem facere qui quis incidunt dolorem eos.','/943e6a7b64ae0509e874c51e46eafb21.jpg','26779',NULL,'1975-04-24 10:00:04','2003-03-22 06:56:44'),
('8','Id odio saepe vitae qui quia id. Illo blanditiis rerum quasi. Reiciendis enim aliquam et.','/01936df48b861305471367d37c592584.jpg','32831',NULL,'1989-05-18 05:38:56','2001-10-06 15:48:27'),
('9','Corporis harum consequatur porro vitae. Architecto amet vel qui nihil. Non aliquid quos debitis quaerat. At sunt dolore eos perferendis rerum.','/e5ecedb94f16a74f228b9658d7b6f105.jpg','38164',NULL,'2013-03-02 09:50:24','2020-09-10 20:43:52'),
('10','Esse earum aut sit eum quas quasi in voluptatem. Voluptatem dolores a doloribus totam. Sed consequatur nam alias aliquid. Esse quam cupiditate velit error quis earum voluptas.','/0ad0c3ad4edfc543503e3d35f139f7b4.jpg','27341',NULL,'1995-08-01 13:42:47','1979-01-03 01:02:57'),
('11','Voluptas quia quidem dignissimos et aut voluptas neque modi. Et nihil ut quas repellat laborum et. Illum in voluptatem commodi sint molestiae. Reprehenderit laudantium non necessitatibus ut.','/0d6aab0b32dcbbe0b9da0ab35c4402b3.jpg','24386',NULL,'1997-08-24 09:16:11','1974-10-03 17:26:19'),
('12','Nobis ratione id dolorum veritatis accusamus et nesciunt nostrum. Atque non iusto deleniti quidem rem qui totam. Distinctio tenetur quos veniam voluptas quae.','/28972bbd31107818faea6e141b740e8f.jpg','27080',NULL,'2015-09-06 17:58:34','1973-09-25 16:56:25'),
('13','Deleniti est labore nihil aperiam aut tenetur reiciendis. Quod voluptates quibusdam deleniti dignissimos molestias. Voluptatibus in nemo doloribus repellat eum vitae. Dolor et suscipit et sed laudantium. Voluptas repudiandae dolores necessitatibus omnis.','/5756e69986f52b1e367cb03f56f97da4.jpg','10765',NULL,'1987-02-12 06:05:19','1987-08-04 09:55:56'),
('14','Et a tempore modi harum sit. Fuga laborum aut molestias et cum excepturi quo. Voluptates sit suscipit odit. Molestiae et occaecati qui autem. Qui quidem consequuntur omnis dolores.','/9c1f745e4e86ba72c4eed920ad3f28be.jpg','14066',NULL,'2006-11-16 16:23:30','1996-07-03 11:41:52'),
('15','Voluptas inventore vero accusamus praesentium. Nisi error odio praesentium ut minus. Ut suscipit sit ut error placeat voluptatibus exercitationem.','/8e5b776444005a88012852707c1d8191.jpg','23880',NULL,'2007-06-11 20:49:50','2001-03-30 15:11:35'),
('16','Quod sunt nostrum consequatur nesciunt iste. Explicabo reiciendis asperiores facere perspiciatis sapiente ut omnis. Ut sed in deserunt non. Id aut et et rerum nisi quaerat est.','/3d44b74416b27fec2a86dd162a07dda3.jpg','29072',NULL,'2005-01-08 06:10:03','1990-07-29 20:33:47'),
('17','Et nisi voluptas eos qui quia non. Et enim voluptatem excepturi ut. Ut sit incidunt voluptas eum porro non minus voluptates.','/da79701fb3b1626f51db506e6ffef78c.jpg','25236',NULL,'1991-10-04 04:35:24','1975-09-27 21:55:05'),
('18','Dolore eos et nisi non est. Quasi blanditiis est repellat recusandae voluptas explicabo. Reiciendis vero ea itaque odit labore quaerat molestiae optio. Rerum et eius vitae repudiandae ut qui.','/1cf56b572ce34de2e75f606b7c6582df.jpg','18493',NULL,'1970-06-07 05:52:36','1991-10-29 18:05:09'),
('19','Impedit corrupti eum non repellendus est voluptatem. Dicta id corrupti voluptas rem sed debitis quia. Sunt et natus quae ut voluptatum adipisci. Impedit ut eos at quam facere aut. Cupiditate nobis consequatur vitae voluptatem quidem itaque.','/764fec3fedc7539313bbf6eff301f91e.jpg','34159',NULL,'2004-09-13 21:11:58','2020-03-17 09:08:27'),
('20','Dolorem nobis nulla nostrum mollitia necessitatibus dolorem sint. Quia error nostrum libero perferendis. Velit consequatur hic omnis qui cum. Expedita debitis quisquam libero voluptas nisi.','/6debd40d3f05f9e582078e5eea6e4774.jpg','23033',NULL,'1970-02-22 06:52:17','2018-07-04 00:52:38'),
('21','Voluptates assumenda est saepe inventore ullam. Maiores voluptas amet quo et. Ullam possimus odit perferendis impedit. Laborum ut architecto ducimus omnis est et cupiditate.','/f11fe4c160cfae865bbc621ba6b51393.jpg','26044',NULL,'1995-09-16 22:22:54','1983-11-13 17:35:44'),
('22','Quia reprehenderit quo veniam eligendi omnis voluptatum. Ut et sint ut repellat rerum vitae. At necessitatibus aut et et est esse rem.','/20540ef22e37167acc4b31aeb1fcdb85.jpg','14566',NULL,'2003-07-06 18:34:13','1981-04-20 17:53:27'),
('23','Et rerum assumenda labore aspernatur quia quos. Dignissimos odio a molestiae. Labore quis enim aspernatur quasi incidunt esse aut. Numquam sint eveniet minus. Sit laborum temporibus modi ut repellendus.','/9067f547e641430f9aa37d0af6f8d439.jpg','11330',NULL,'1999-07-08 16:51:05','1988-08-02 14:22:24'),
('24','Fuga atque totam explicabo cumque unde nobis. Mollitia impedit ut mollitia perspiciatis. Eos id incidunt consectetur rerum aut maxime. Accusamus quasi voluptas ea.','/3c8da8376da3aebd083c014a7afaf154.jpg','10122',NULL,'1988-09-16 14:47:50','1976-07-23 04:59:47'),
('25','In dolor incidunt ipsam facilis sit excepturi quo. Tempora est qui ullam alias quam. Odit et sit qui sapiente sed fugit.','/e0008a0bf007f44426deff8eabce9c4a.jpg','25689',NULL,'1999-01-25 14:49:21','1998-02-27 23:45:15'),
('26','Velit rem occaecati molestias consequuntur consequatur suscipit ea magni. Earum earum et possimus voluptatem qui et et. Ipsam eius et consequatur iusto corporis. Fugit nihil nobis rerum voluptatibus et qui. Impedit doloremque dolorem doloremque enim.','/359fa346fe66e65221fad3c2f2db54fe.jpg','24400',NULL,'1998-09-21 03:42:04','2017-03-30 12:53:03'),
('27','Aut libero aut facere eos illo reprehenderit. Sit cupiditate nam at sed voluptatem delectus accusamus sit. Quibusdam animi omnis qui.','/e450fe80df568a4622e8ca46a9ae4d89.jpg','30443',NULL,'1980-04-06 06:42:53','1984-05-17 08:38:05'),
('28','Corporis voluptas sit est alias ut. Qui quia vel adipisci debitis et numquam porro exercitationem. Quas excepturi voluptas voluptas et non ratione. Animi consequatur voluptates deserunt.','/1c2b53d5cab88033f64ff8b5f6ca0714.jpg','12339',NULL,'2016-10-21 11:50:44','1994-04-30 08:39:45'),
('29','Laboriosam non quisquam dolores voluptate laudantium minus placeat. Quidem dolore ut ex et ut molestias quis qui. Voluptate deleniti consequatur ut veniam.','/956ca899b177ee4d1eec4d7054dd3997.jpg','10154',NULL,'1989-04-26 08:06:37','1985-03-21 03:55:22'),
('30','Ratione ea aspernatur enim vel. Est ut ut alias ut qui quasi. Assumenda et tenetur cupiditate occaecati reprehenderit tempora quo fugit.','/2f6d190f21ccb9ec8c3f0debc0e492ca.jpg','16374',NULL,'2014-06-01 23:24:17','2008-06-21 23:25:44'),
('31','Qui vero est quibusdam ut. Facere eveniet aspernatur dolores quis aut. Est quia id corrupti omnis.','/bdb99a36ea5556df9c2b7f626287962f.jpg','36774',NULL,'2002-12-06 02:07:58','1985-04-30 20:09:53'),
('32','In tempora eveniet quia voluptas molestiae qui est. Sunt veritatis velit incidunt qui commodi mollitia. Labore repellendus praesentium numquam et sunt eius. Omnis voluptas vel nisi beatae sit esse. Aut consectetur optio ullam suscipit ut consequatur.','/1e80a4bf2f69024ecebf96c1c1eeeeae.jpg','33685',NULL,'2020-07-03 20:50:04','1994-08-05 00:49:17'),
('33','Vel minus cumque culpa ipsum. Sint voluptatem sint at et. Facilis voluptatibus sunt omnis cumque expedita. Quisquam voluptas officiis quia corrupti velit molestiae ut. Qui error illum facere sint rem.','/707d842ff5698fcd466b2267b38136fc.jpg','23608',NULL,'1980-07-05 17:50:32','1976-03-19 06:56:48'),
('34','Recusandae consequatur quia aut quia et et esse. Eius facere accusantium aut dolore voluptatibus.','/aeb49458c704cb0640da6a94de27a728.jpg','23697',NULL,'1991-11-27 06:24:47','2007-08-20 09:25:53'),
('35','Vero perferendis ea dicta autem qui. Alias magni expedita adipisci quis sint ea rerum. Recusandae aut officia tempore est possimus quae alias. Deserunt doloremque laudantium autem dicta suscipit. Molestiae tenetur ad consequatur placeat porro ducimus.','/ebdc36adda283f52d7e0779f848817e1.jpg','24131',NULL,'1979-01-02 16:56:42','1979-11-10 00:00:07'),
('36','Rerum mollitia ut distinctio et temporibus. Qui facere rerum minima ad. Et velit deserunt nihil aut. Excepturi quos beatae necessitatibus deserunt explicabo repellendus deleniti assumenda.','/fcda63351876f0bbcced1a66df2c06c2.jpg','33372',NULL,'1996-07-12 21:12:08','1993-03-16 19:14:42'),
('37','Aut expedita eos consequatur. Eveniet veniam nam ipsam velit possimus. Ipsa aut est sit. Blanditiis eos rerum aut iusto et.','/73b3e718fdfb946b3366475b7cf8554a.jpg','33561',NULL,'1990-05-17 20:32:56','2001-09-15 13:52:57'),
('38','Repellat dicta rerum repellat dolor aliquid qui quod. Assumenda maxime sit autem asperiores architecto et. Consequuntur aut praesentium quia rem iure occaecati necessitatibus.','/6489aaee5ace91b24c5a02a03663bb9b.jpg','26799',NULL,'2014-09-19 20:37:53','2012-02-04 12:01:36'),
('39','Quo qui doloremque dicta voluptas similique enim. Repudiandae excepturi eveniet voluptatibus culpa et.','/39ed43a2eca1e1aee4ab956cb805fe80.jpg','16145',NULL,'1996-02-04 10:52:25','1989-01-23 12:39:23'),
('40','Similique odio est ut repellat atque consectetur animi maiores. Harum quis laboriosam id natus. Voluptatibus rerum adipisci fuga nemo esse. Quod iure consectetur et sunt. Ut ad voluptate quo odit.','/3093a86d3f2015e8a1a76f6938fa6bd9.jpg','18447',NULL,'2019-03-03 15:45:48','2018-04-28 14:42:40'),
('41','Iure ut consequatur eum fugit veritatis. Aut suscipit occaecati pariatur qui. Accusantium eaque nostrum magnam natus molestiae ut temporibus.','/853fd5e2942a0c6da172f04df0b4a6f7.jpg','19834',NULL,'1982-02-25 23:48:48','1985-11-16 00:35:42'),
('42','Porro vitae optio minima voluptates provident sed. Omnis et rerum sed. Veritatis voluptate officiis beatae natus libero sed quo. Nihil autem exercitationem facere corporis ratione ut.','/9c013f71602c9cdfaa885989bc4ba660.jpg','13268',NULL,'1996-04-21 11:25:08','2020-08-23 00:01:03'),
('43','Voluptatem neque repudiandae sed voluptas ut. Exercitationem pariatur quisquam esse ut esse deleniti harum. Ab in alias provident voluptatem laborum.','/db9fb33d53173888964f1098d93ceafd.jpg','33419',NULL,'1996-06-30 20:55:40','1986-05-08 00:37:10'),
('44','Voluptatem et molestiae itaque corrupti facilis odio quos. Reiciendis totam quod perspiciatis ipsum. Sit velit optio voluptate et eligendi. Quo et quae ad laudantium nihil asperiores qui et. Repudiandae id et adipisci consequatur ut ut.','/6cc8b58551dbdef90ce24eb95fa624fa.jpg','33432',NULL,'1992-02-25 04:04:15','2008-08-23 01:13:03'),
('45','Quibusdam minus reiciendis sunt itaque voluptatem voluptates facere. Quia ab sequi ut sequi. Facere est nobis qui similique.','/05c3eff6058d58358e4e211b22ad3795.jpg','15626',NULL,'1997-03-10 21:58:29','1998-07-26 15:34:15'),
('46','Tempore nulla quis voluptate ex molestiae natus sequi ad. Similique reiciendis similique qui eveniet animi.','/9ab0b12ebe45ce6e4d3184f42cddfd46.jpg','22168',NULL,'1981-11-27 16:32:12','2001-11-22 19:52:04'),
('47','Aut et mollitia omnis accusantium dolor. Consequatur nesciunt molestiae fugiat animi quis repudiandae et. Ullam dolorem ab sunt molestiae. Voluptate vel sit dolores quo voluptatibus quia quod.','/46de3341c8b861b565ee025cf6bea139.jpg','24572',NULL,'2004-02-25 04:26:50','2006-11-27 23:12:48'),
('48','Atque sunt id tempora dolores occaecati earum. Eaque dicta culpa consequuntur similique fuga. Architecto inventore sunt atque quo incidunt. Et voluptas et tempore optio.','/3efe30c380fccc5e43b0187f953c0a63.jpg','16940',NULL,'1994-12-23 20:29:53','1994-09-17 05:53:36'),
('49','Aspernatur assumenda consequatur iste odio vel dolorum perferendis. Ut inventore ut dolores ut maxime totam. Aut natus beatae magnam velit. Eos blanditiis quibusdam beatae qui dolor qui inventore.','/7ee20bbf178c63af59f2eeefeddf0c8d.jpg','18665',NULL,'1992-06-09 20:45:26','1990-09-07 14:37:58'),
('50','Unde quos labore asperiores quae quaerat. Enim eos excepturi nam explicabo iste sequi quisquam.','/4cc0610dc17d9c846c8e3a63fac83863.jpg','37737',NULL,'1977-05-01 03:07:30','2019-01-20 21:44:48'); 

INSERT INTO `users` VALUES ('1','Baby','Cronin','vgoodwin@example.org','oliver20','e120f440a80e5c4823fa88e593bd09bc7c6e2758'),
('2','Wilfredo','Will','zwisoky@example.net','vhane','ef8126f9a05cc7372557d923a314cc46908b1a82'),
('3','Thora','Rogahn','green.orion@example.net','alan78','37c98459d5a4234594e78d400918da2e91554824'),
('4','Tyler','Schroeder','linnea19@example.com','cristopher76','4a5169a86e5f306732616cdf1504ba2c9b44d381'),
('5','Jasmin','Rempel','maegan85@example.net','deon82','c590e764ce2cf75eb7bedd944f984fe7dafb9ef3'),
('6','Jarrett','Osinski','eladio.robel@example.com','bashirian.amparo','516d3d13231a679569736a8c4bad68710481f20f'),
('7','Lucas','Morar','uschmeler@example.net','shanelle53','97960cd57b031c06f5d70fb279297b7e3d4f1a0b'),
('8','Otis','Will','jamie16@example.com','lcarter','6c5011c4223bf51cdef69a63c80e22fd9175a769'),
('9','Erik','Schiller','emard.gerson@example.org','lacy.wilkinson','a2733eec65ca9f5ca45ce99dc1dbd8609cf9f9e3'),
('10','Cora','Mueller','lucile40@example.net','june11','ecc93833ebef7016c6b92c5f1c790513a683dd0f'),
('11','Shanie','Murray','simonis.cornell@example.com','glover.meghan','b21d50c35355ba1e1c4c1c2ea3151b0d85fda2a0'),
('12','Everette','Keeling','laurianne.ledner@example.com','rutherford.koby','23fd1c9452a5c339d35420d79c378eaeeba89a38'),
('13','Kenna','Morissette','idella17@example.net','kara22','5f94f56bd7c27a74cc3c352ae8aa24a0af9a80b7'),
('14','Germaine','Bogisich','williamson.damaris@example.org','rryan','f0c4562c6741f7e919077b57f0141c30d08bc452'),
('15','Herminia','Hermiston','jerrod34@example.org','lmertz','eb1793b656b24af35b5ac967cab8a71749510c0d'),
('16','Candelario','Bergstrom','ymurazik@example.com','xrippin','e457f9cea9c3f5128832ffde73b6afd3c503cb52'),
('17','Emory','Strosin','elda45@example.org','reichel.peter','093a3cfa798e1e327056f76c371821e6ece9140a'),
('18','Vincenzo','Cummings','durgan.lafayette@example.net','jabari.stokes','b18aa34b58858e0e792d22430e5d54714bcfabfc'),
('19','Susanna','Konopelski','streich.howard@example.org','adolphus00','35f60d170f15b0f9e8d200db052b8383268d179f'),
('20','Orville','Pagac','randy.hills@example.net','witting.justus','80e708ec0a078cd87e2624d96e576dfc65bee0a1'); 

INSERT INTO `employee` VALUES ('1','W','1991-05-22','1','accusantium','1995-10-01 19:00:40','1999-07-08 11:51:47','1979-03-24 08:02:08','2000-02-14 04:36:11'),
('2','M','1987-01-13','2','omnis','2000-02-26 18:02:46','2006-04-12 13:49:17','1988-02-06 21:36:25','1984-01-27 20:54:38'),
('3','W','1989-02-12','3','inventore','2002-11-24 20:50:16',NULL,'1991-08-07 01:06:59','1981-05-25 02:55:08'),
('4','M','2004-06-14','4','vel','2018-04-25 19:05:23','2019-07-15 02:24:36','2000-04-05 15:41:41','1988-08-11 00:17:20'),
('5','M','1999-01-12','5','inventore','2017-12-02 11:59:05',NULL,'2010-12-16 11:03:25','1983-03-04 21:14:11'),
('6','W','1984-06-04','6','qui','2009-07-23 11:57:06',NULL,'1973-11-14 21:42:15','1979-06-11 17:55:47'),
('7','M','1989-08-18','7','possimus','2001-06-12 09:44:25',NULL,'1987-06-10 16:45:30','1999-09-11 05:07:33'),
('8','W','1981-10-09','8','aut','2005-01-20 00:04:18',NULL,'1991-07-19 09:20:05','2006-11-10 15:44:03'),
('9','M','1995-04-25','9','omnis','2003-05-24 03:32:12',NULL,'2008-09-21 21:39:39','1992-07-28 23:05:46'),
('10','W','1995-11-07','10','aut','2007-06-27 18:28:43',NULL,'1971-03-30 02:36:20','2018-05-23 07:37:44'),
('11','M','1988-04-16','11','sit','2004-11-04 12:44:39',NULL,'1984-07-02 05:49:41','2011-08-28 13:28:16'),
('12','W','1989-08-17','12','reiciendis','2011-07-29 12:29:36','2016-08-16 12:29:56','1981-02-19 03:15:03','1976-05-22 22:45:48'),
('13','M','1193-10-24','13','dolores','2001-12-14 02:25:34','2018-12-09 01:59:47','1974-03-19 19:32:45','2006-06-17 07:39:56'),
('14','M','1972-06-30','14','sint','2003-03-20 13:01:16','2019-09-21 04:50:04','2020-02-14 18:11:04','1978-08-15 10:21:24'),
('15','W','1975-06-28','15','omnis','2005-08-16 05:57:41','2020-02-22 20:39:54','1992-04-27 09:48:13','1974-12-28 00:08:14'),
('16','M','1979-02-21','16','atque','2016-10-26 00:38:06','2019-11-20 16:38:16','1994-10-16 16:13:09','2008-07-25 22:32:43'),
('17','W','1976-01-25','17','inventore','2014-07-03 11:43:54',NULL,'1978-09-02 15:49:23','2014-10-22 22:24:30'),
('18','M','1962-07-30','18','voluptate','2004-08-19 17:48:09',NULL,'1978-10-07 02:07:01','1985-02-15 09:05:22'),
('19','M','1991-12-07','19','tempora','2007-11-13 01:20:49',NULL,'2020-07-13 14:34:06','2011-12-15 14:15:13'),
('20','M','1978-07-29','20','assumenda','2005-06-28 14:41:35',NULL,'1998-10-07 18:03:01','2011-09-09 08:13:37'); 

INSERT INTO `units` VALUES ('1',' l','Liter','2019-07-03 13:05:07','2020-01-30 07:31:15'),
('2','pc','Piece','2019-08-24 00:46:13','2020-01-08 06:34:48'),
('3','m','Metr','2019-08-24 06:41:35','2020-06-16 18:57:01'),
('4','t','Ton','2019-01-02 22:59:57','2020-01-10 03:19:15'),
('5','kg','Kilogram','2019-11-08 16:51:28','2020-07-05 19:27:02');

INSERT INTO `items` VALUES ('1','ACER_SF314-57G','Acer Swift 3 SF314-57G','Purchased','2','5','2','1','2019-09-26 03:46:07','2020-06-22 04:02:08'),
('2','ASUS_X512','ASUS VivoBook 15 X512','Purchased','2','5','2.2','2','2019-09-06 02:57:29','2020-08-11 06:20:44'),
('3','APPLE_mbook_13','Apple MacBook Air 13','Purchased','2','5','1.4','3','2019-05-09 07:07:18','2020-09-01 21:13:51'),
('4','HP_2D195EA','HP 340S G7 (2D195EA)','Purchased','2','5','2','4','2019-08-11 06:23:05','2020-04-11 03:32:36'),
('5','Xiaomi_Mi15','Xiaomi Mi Notebook Pro 15.6','Purchased','2','5','2','5','2019-03-15 23:30:49','2020-06-22 04:53:05'),
('6','Acer_TMP215-52','Acer TravelMate P2 TMP215-52','Purchased','2','5','2','6','2016-01-26 23:00:50','2017-09-05 13:42:16'),
('7','APPLE_mbook_pro16',' Apple MacBook Pro 16 with Retina','Purchased','2','5','2','7','2002-11-22 20:56:50','2016-12-25 08:20:09'),
('8','ASUS_S533FL-BQ055T','ASUS VivoBook S15 S533FL-BQ055T','Purchased','2','5','2','8','1972-08-08 15:48:16','1976-08-05 22:43:41'),
('9','ASUS_UX534FTC-AA061T','ASUS ZenBook 15 UX534FTC-AA061T','Purchased','2','5','2','9','1992-08-07 03:07:13','1974-09-22 15:40:21'),
('10','ASUS_G512LV-HN034','ASUS ROG Strix G15 G512LV-HN034','Purchased','5','5','4','10','2015-07-21 23:40:58','2012-01-25 00:41:34'),
('11','ASUS_S533FL-BQ057T','ASUS VivoBook S15 S533FL-BQ057T','Purchased','2','5','2','11','2003-12-21 03:16:56','2009-12-18 14:31:04'),
('12','ASUS_UX325JA-EG069T','ASUS ZenBook 13 UX325JA-EG069T','Purchased','2','5','2','12','1973-02-02 22:30:50','1981-09-19 21:57:34'),
('13','DELL_5593','DELL Inspiron 5593','Purchased','2','5','2','13','2001-09-30 16:26:40','2008-09-16 16:11:08'),
('14','HP_15-dk1015ur','HP PAVILION 15-dk1015ur','Purchased','2','5','2','14','1994-03-21 23:57:05','2009-03-23 04:33:18'),
('15','Acer_A715-75G-73WN','Acer Aspire 7 A715-75G-73WN','Purchased','2','5','2','15','1996-01-11 21:40:20','2011-05-25 08:05:31');

INSERT INTO `currencies` VALUES ('1','RUB','Ruble','1999-10-01 04:09:18','2010-02-13 02:29:52'),
('2','EUR','Euro','2005-03-12 07:02:50','2010-08-02 18:14:48'),
('3','USD','Dollar','2000-12-16 00:21:51','2005-07-13 04:24:09');

INSERT INTO `business_partners` VALUES ('1','et','1','9239460254','Seller','Ms. Lauren Beatty','RU','6766249366','1986-05-24 03:31:18','1975-07-26 16:04:17'),
('2','necessitatibus','2','9748079616','Buyer','Marlene Stehr PhD','RU','3358075560','2005-01-22 12:31:44','1989-03-25 15:47:08'),
('3','non','3','3410462328','Seller','Axel Wisozk','RU','8028676159','2004-04-07 12:10:16','1980-12-31 12:17:49'),
('4','ad','1','7411392087','Buyer','Barrett Rodriguez','EN','7151717557','2007-05-22 01:24:58','1994-01-02 13:11:23'),
('5','asperiores','2','7054994268','Buyer','Leonard Quitzon II','EN','8171130514','2013-10-27 11:39:17','2014-09-22 01:21:49'),
('6','sequi','3','9649482735','Buyer','Jamal Gerlach','RU','7656690745','2003-03-22 06:26:33','1997-05-01 08:30:11'),
('7','quae','1','4468104307','Seller','Eliza Metz','RU','7092125624','2003-04-30 12:33:47','2009-08-31 04:06:38'),
('8','reiciendis','2','8947321985','Buyer','Breanna Ortiz','RU','2277006632','2001-07-11 03:09:43','1977-01-23 01:16:11'),
('9','sint','3','6804578482','Seller','Cleora Gislason','RU','5499378802','2016-10-12 11:02:22','1982-07-30 13:50:05'),
('10','nostrum','1','3793072923','Buyer','Gail Cummerata','EN','4119915667','1984-01-08 08:57:30','2012-04-27 09:01:21'),
('11','quae','2','5981751070','Buyer','Janet Legros','EN','3739713746','2014-08-24 22:52:50','1979-05-16 07:36:39'),
('12','soluta','3','4464939597','Seller','Mr. Seamus Mitchell DVM','EN','9004407204','1975-04-17 16:16:30','2017-09-30 11:29:48'),
('13','nihil','1','5061850914','Buyer','Prof. Llewellyn Dooley MD','EN','2756621726','2020-01-02 01:11:07','1999-04-01 19:41:29'),
('14','dicta','2','8982849109','Buyer','Oscar Zulauf','RU','8970082816','1996-05-30 08:02:12','1989-12-17 13:25:43'),
('15','qui','3','4428985587','Buyer','Catalina McClure DVM','RU','3747525868','1974-08-23 09:45:15','1990-09-05 16:15:27'); 

INSERT INTO `addresses` VALUES ('1','quos','Olson Hollow','2149','East Javier','44568','4217802579'),
('2','quia','Georgette Rest','7617','Nikobury','08814-8754','1386231598'),
('3','iure','Jacobs Harbors','92422','South Barry','01911','4033802550'),
('4','aut','Zemlak Landing','48357','Pagacmouth','92187-0209','3225151681'),
('5','et','Pearl Path','509','North Blazeshire','35613','1825754092'),
('6','sunt','Rene Courts','930','Moorefurt','90998','3862358629'),
('7','reprehenderit','Jacobson Parkway','5393','Huelville','84915-5383','1883731959'),
('8','velit','Shaina Flat','38521','Paolochester','35116','5068830560'),
('9','sed','Kunde Springs','91930','Reggiemouth','11111-4133','8922293534'),
('10','blanditiis','Cleve Road','08070','West Annettahaven','80179-3091','1289111299'),
('11','est','Schmeler Flat','95551','Violetteburgh','54233','7329407006'),
('12','blanditiis','Maximillian Port','404','North Javonbury','79854-7039','3001057418'),
('13','necessitatibus','Parisian Row','8598','Delfinamouth','85446','3728026154'),
('14','dolores','Buckridge Route','4056','East Otilialand','86817-4152','2946999360'),
('15','illum','Zita Meadow','0336','New Shadstad','21922-5539','6919727528'),
('16','fugiat','Yundt Path','16128','South Dave','50811','3010157415'),
('17','quia','Kenyon Cliffs','9103','Lake Adellachester','96549-0875','1830450087'),
('18','eius','Celestino Tunnel','04378','Jessicaside','43776','9265878197'),
('19','et','Narciso Alley','480','Aliyaton','94850-7097','2601622067'),
('20','voluptas','Cristina Fords','19428','Bettymouth','28598-6277','6855331705'),
('21','aut','Nienow Parkway','98769','Watsicafort','00144','9640425179'),
('22','fugiat','Hahn Walks','122','North Aletha','61693-3790','7638912196'),
('23','quia','Obie Ferry','05535','Schowalterside','41418','7154039717'),
('24','qui','Olga Brooks','10566','West Murphy','04823','5221078050'),
('25','porro','Larkin Prairie','04432','South Josuemouth','52979','2831652315'),
('26','sunt','Powlowski Key','18022','Sigurdfort','23026-0049','4454192348'),
('27','ut','Treutel Stravenue','61992','Brakustown','94319-6911','6173392849'),
('28','non','Emilie Street','4098','Wolffmouth','92356-4368','8825724005'),
('29','earum','Thompson Radial','67105','Port Antonetta','41311-1047','6372662933'),
('30','saepe','Birdie Drive','06581','South Cale','56544-7190','3658230017'),
('31','occaecati','Block Ramp','5654','Bogisichburgh','30652-1146','1477381987'),
('32','a','Marvin Courts','7336','East Madgeshire','92825-0117','4335781755'),
('33','dolor','Kshlerin Hills','0009','Schillerchester','52951','2060135809'),
('34','sit','Kenny Crest','6991','Luisachester','19231','8046244163'),
('35','tenetur','Bertram Islands','98937','Joseport','23676-7605','6969346635'),
('36','culpa','Francesco Square','024','New Moriahfurt','45062-6115','1944247678'),
('37','eos','Reilly Corner','21134','North Amandatown','54234-9807','8195990476'),
('38','dignissimos','Florida Loop','770','Skileshaven','27073-6904','5595457838'),
('39','voluptatem','Gutkowski Centers','84670','Romagueraland','68372','2070220114'),
('40','eum','Willms Union','8770','New Mabellebury','78480','4514720824'),
('41','dolores','Medhurst Motorway','930','Binston','74665-7679','7080668045'),
('42','iusto','Ada Tunnel','492','East Jacintheview','64681-4063','6420713509'),
('43','autem','Lorine Burg','72190','Ceasarville','54620','4021620866'),
('44','sit','Marietta Village','772','West Sheilatown','25984','2021494745'),
('45','possimus','Dibbert Way','07464','Vladimirberg','37753-2807','6314326923'),
('46','sapiente','Kilback Haven','9125','South Casper','26302','1124631855'),
('47','quibusdam','Percy Ranch','40167','Lake Aisha','38272-7372','8466891646'),
('48','quae','Heidenreich Heights','10037','Theodoreview','30826-0789','5949711805'),
('49','dolorem','Quitzon Stream','0166','Rempelhaven','50427','3997702602'),
('50','nulla','Lydia Spurs','8379','Percivalchester','67915','2608149680');

INSERT INTO `business_partner_address` VALUES ('1','1','active','1991-08-26 20:42:12','1995-06-24 18:14:14'),
('1','31','active','1985-01-28 07:55:52','1980-07-31 19:15:15'),
('2','2','active','1972-01-07 07:39:22','1988-07-26 00:07:17'),
('2','32','expired','2009-08-16 06:17:37','1974-03-25 01:33:54'),
('3','3','expired','1973-03-07 10:44:18','2009-06-22 11:26:18'),
('3','33','expired','1983-03-08 01:50:05','2010-04-29 05:57:56'),
('4','4','expired','2020-06-02 22:23:33','2015-07-05 02:03:16'),
('4','34','active','1996-10-28 06:09:04','2018-10-02 01:08:21'),
('4','5','active','2017-05-12 01:11:44','1971-04-14 18:25:05'),
('5','35','active','2007-11-22 16:32:09','2014-03-18 06:09:01'),
('5','6','expired','2005-10-23 20:42:12','1980-01-10 15:48:37'),
('6','36','active','1970-07-30 11:31:53','1970-11-28 18:52:58'),
('7','7','expired','1970-03-30 12:31:43','2004-05-27 03:38:27'),
('7','37','active','1980-06-27 21:11:13','1973-11-22 02:09:46'),
('7','8','active','2012-02-24 13:29:23','1978-12-11 07:42:12'),
('7','38','expired','1979-03-08 16:46:14','2002-04-19 12:38:11'),
('7','9','expired','2006-08-08 14:53:35','1972-09-26 08:53:11'),
('8','39','active','1977-04-15 09:54:01','1975-09-24 00:09:01'),
('8','10','expired','1994-08-21 08:42:16','2007-05-07 21:58:19'),
('8','40','active','1982-12-14 01:39:14','1996-11-14 09:34:36'),
('9','11','active','2011-11-08 16:47:44','2017-11-17 11:52:59'),
('9','12','expired','1987-06-02 15:37:33','1989-11-04 00:58:56'),
('9','13','active','2018-06-23 10:49:35','2012-05-13 13:18:49'),
('10','14','expired','2011-09-24 16:29:43','1997-09-29 00:27:59'),
('10','15','active','2003-04-11 00:47:12','1970-12-25 16:03:29'),
('10','16','expired','2018-08-12 15:32:28','1973-11-24 13:10:02'),
('11','17','expired','2008-06-19 02:31:02','2007-08-27 09:10:12'),
('11','18','expired','1975-01-31 15:54:09','1984-01-14 17:42:04'),
('11','19','expired','2012-01-15 00:23:38','2020-08-30 20:32:38'),
('11','20','active','1996-01-22 13:40:17','2017-04-22 17:02:21'),
('12','21','active','1975-09-29 23:48:55','1973-11-29 21:29:28'),
('13','22','expired','1976-04-02 21:16:53','1976-03-24 20:00:52'),
('13','23','expired','1986-11-24 11:34:55','1987-07-04 00:46:33'),
('13','24','active','1991-04-22 22:42:18','2005-11-08 22:29:42'),
('14','25','active','1972-04-01 00:19:04','1998-02-22 03:24:45'),
('14','26','expired','1997-05-29 08:28:26','1976-06-27 10:28:41'),
('14','27','active','1980-11-04 10:57:42','1970-04-26 15:28:04'),
('15','28','expired','1984-11-08 00:22:24','1981-03-25 11:15:27'),
('15','29','active','1980-10-15 16:01:06','1996-07-21 19:49:16'),
('15','30','expired','1996-01-27 16:49:07','1983-06-10 18:59:14');

INSERT INTO `warehouses` VALUES ('1','WRHS_1','1','1','2008-11-14 21:07:44','1977-02-27 07:29:53'),
('2','WRHS_2','2','2','1992-01-24 16:46:08','2006-04-12 15:28:30'),
('3','WRHS_3','3','3','2016-05-12 08:49:56','1999-05-30 15:15:22'),
('4','WRHS_4','4','4','2008-02-14 00:32:38','1973-11-02 23:59:49'),
('5','WRHS_5','5','5','1971-03-01 20:55:44','1988-02-21 06:40:19'),
('6','WRHS_6','6','6','1981-08-13 22:07:39','1993-07-21 10:14:23'),
('7','WRHS_7','7','7','1982-04-23 11:22:12','2016-02-27 07:12:21'),
('8','WRHS_8','8','8','1975-05-03 04:36:38','1977-07-20 14:39:50'),
('9','WRHS_9','9','9','1995-04-11 14:08:46','1983-11-27 09:16:16'),
('10','WRHS_10','10','10','2014-05-25 05:56:14','2019-04-25 04:04:45');

INSERT INTO `inventory_by_warehouse` VALUES ('1','1','6','8','5','1976-11-02 22:43:12','1972-08-16 00:11:03'),
('1','11','6','7','8','1998-01-27 13:51:37','1996-04-05 23:21:06'),
('1','12','6','9','8','1999-03-26 07:24:42','1982-01-31 05:15:59'),
('2','2','8','1','7','1970-12-02 18:11:01','2008-06-10 15:37:33'),
('2','12','6','9','4','2000-02-25 18:57:49','2014-11-09 00:23:52'),
('2','3','5','9','7','2015-02-22 13:03:59','1984-07-08 12:30:15'),
('3','3','4','3','2','2012-07-13 03:10:40','2009-03-24 05:21:55'),
('3','13','6','1','2','2003-01-16 19:33:18','2012-03-26 09:20:47'),
('3','7','4','1','3','1972-03-22 12:54:50','1974-05-12 03:24:03'),
('4','4','1','9','2','2011-05-12 13:14:00','2019-02-15 10:10:02'),
('4','14','7','9','9','1978-10-18 01:55:04','2005-11-13 11:32:05'),
('4','8','6','7','1','2000-03-08 14:58:22','1973-08-21 22:09:43'),
('5','5','6','8','3','1971-04-07 07:39:59','1972-03-01 15:43:50'),
('5','15','6','2','8','1973-12-13 09:32:23','1991-11-18 12:06:32'),
('5','2','6','4','6','1975-04-30 13:45:34','1989-09-22 05:32:50'),
('6','6','9','8','7','1977-04-03 19:34:03','2000-07-16 03:57:06'),
('6','12','3','2','7','1993-12-09 06:27:22','1995-07-12 00:42:07'),
('6','3','7','3','3','2017-03-28 07:38:38','1979-04-21 16:52:35'),
('7','7','2','4','7','2015-05-03 13:48:18','2007-04-28 21:54:22'),
('7','14','6','6','5','1999-05-18 17:11:53','2018-11-08 07:46:25'),
('7','8','1','3','6','1991-04-08 17:35:12','2020-07-08 11:21:33'),
('8','8','9','5','6','1972-04-16 12:43:51','1985-10-06 04:10:07'),
('8','12','7','5','4','2010-08-18 01:02:17','1977-05-25 08:13:48'),
('8','4','2','7','4','2014-12-16 04:10:25','1973-03-14 23:23:24'),
('9','9','8','3','7','2000-01-13 15:30:53','2002-05-15 08:23:12'),
('9','11','4','4','2','1986-07-13 07:30:23','1974-12-15 03:07:28'),
('9','13','6','2','2','2012-12-02 08:54:18','1994-01-09 08:03:31'),
('10','10','3','7','3','1988-09-15 13:44:56','1978-01-10 08:47:06'),
('10','12','2','4','1','1994-11-09 20:10:51','1982-03-24 12:39:55'),
('10','14','7','9','8','1971-03-20 04:15:42','1989-11-25 11:40:18');

INSERT INTO `purchase_order` VALUES ('1','1','1','1','2020-05-23 10:34:30','1','2020-06-27 09:09:35','2020-06-27 04:47:25','released'),
('2','2','2','2','2020-06-19 02:02:28','2','2020-10-01 06:46:59','2020-10-06 02:58:31','released'),
('3','3','3','3','2020-03-28 02:49:49','3','2020-04-15 00:03:53','2020-04-16 06:41:21','released'),
('4','4','4','4','2020-02-18 03:17:01','1','2020-02-28 11:05:07',NULL,'created'),
('5','5','5','5','2020-07-23 23:38:20','2','2020-08-08 23:38:32',NULL,'approved'),
('6','6','6','6','2020-05-13 09:26:29','3','2020-06-28 03:46:31',NULL,'cancelled'),
('7','7','7','7','2020-06-11 13:10:55','1','2020-06-14 02:41:19',NULL,'cancelled'),
('8','8','8','8','2020-06-15 10:31:08','2','2020-06-20 08:15:09',NULL,'approved'),
('9','9','9','9','2020-06-30 06:42:11','3','2020-09-18 13:31:58',NULL,'created'),
('10','10','10','10','2020-07-14 17:21:12','1','2020-11-13 02:55:45',NULL,'cancelled');

INSERT INTO `purchase_order_lines` VALUES ('1','1','11','87','445293.87','653168.61'),
('1','2','1','49','850694.69','45.85'),
('1','3','12','2','899561.49','7131.69'),
('2','1','2','52','890487.16','1070.07'),
('2','2','12','89','421870.23','1751.92'),
('3','1','13','46','785021.20','0.18'),
('3','2','3','91','292801.78','960956.35'),
('3','3','13','90','250617.80','47485.30'),
('4','1','14','27','891260.48','283810133.77'),
('4','2','4','44','804230.85','228329953.26'),
('5','1','15','26','760154.10','154.24'),
('5','2','5','58','487228.40','1096274.00'),
('5','3','3','48','991831.29','3.90'),
('6','1','6','26','73222.29','0.00'),
('6','2','12','15','151750.95','0.00'),
('7','1','7','76','949929.17','26.20'),
('7','2','13','8','816470.70','233485.90'),
('7','3','14','16','522113.70','2012564.76'),
('8','1','1','28','735830.00','5.44'),
('8','2','8','33','965958.00','16026.10'),
('8','3','13','48','795780.28','158266632.11'),
('9','1','1','17','725291.92','22865.46'),
('9','2','9','71','404724.00','3052.32'),
('10','1','5','80','751546.37','1639623.29'),
('10','2','10','93','382538.08','3540.99'),
('10','3','15','41','632471.94','1425.00'); 

/*** SQL-запросы ***/

/* Получить всех активных контрагентов с их адресами */
SELECT bp.name, bp.contact, bp.phone, a2.postal_code, a2.street, a2.house_number
FROM business_partners bp 
	JOIN business_partner_address bpa 
	ON bp.id = bpa.business_partner_id 
	JOIN addresses a2 
	ON bpa.address_id = a2.id
WHERE bpa.status = 'active';

/* Количество запаса на складах */
SELECT w2.name warehouse, SUM(on_hand) total_on_hand_quantity, SUM(blocked) total_blocked, SUM(rejected) total_rejected 
FROM inventory_by_warehouse ibw 
	JOIN warehouses w2 
	ON ibw.warehouse_id = w2.id 
GROUP BY warehouse_id;

/* Список сотрудников (имя, фамиилия, дата рождения) отсортированные по дню рождения */
SELECT u.firstname, u.lastname, (SELECT birthday FROM employee e2 where e2.user_id = u.id) as birthday
FROM users u
order by birthday;

/* Вывод списка заказа с суммой заказа */
SELECT po.order_number_id, po.order_date, po.status, SUM(pol.amount)
FROM purchase_order po 
	JOIN purchase_order_lines pol 
	ON po.order_number_id = pol.order_number_id
GROUP BY po.order_number_id;


/*** Представления ***/
/* Данные о сотруднике */
CREATE OR REPLACE VIEW employee_data (login, firstname, lastname, email, gender, birthday, position)
AS SELECT u.login, u.firstname, u.lastname, u.email, e.gender, e.birthday, e.position 
FROM users u JOIN employee e ON u.id = e.user_id WHERE e.last_date_of_employment is NULL;

SELECT * FROM employee_data;

/* Вывод данных по заказу, вместо внешних ключей указаны данные из родительских таблиц */
CREATE OR REPLACE VIEW purchase_order_data(order_number_id, order_date, business_partner, buyer, planned_receipt_date, status, amount, currency)
AS SELECT po.order_number_id, po.order_date, (SELECT name FROM business_partners bp WHERE bp.id = po.business_partner_id) AS business_partner,
(SELECT CONCAT(u2.firstname, " ", u2.lastname) FROM users u2 WHERE u2.id = po.buyer_id) AS buyer,
po.planned_receipt_date,
po.status,
SUM(pol.amount) AS amount,
(SELECT c2.currency_code FROM currencies c2 WHERE c2.id = po.currency_id) AS currency
FROM purchase_order po JOIN purchase_order_lines pol ON po.order_number_id  = pol.order_number_id
GROUP BY po.order_number_id;

SELECT * FROM purchase_order_data;


/*** Хранимые процедуры ***/
DELIMITER //

/* Положить изделие на склад */
DROP PROCEDURE IF EXISTS put_item_to_warehouse//
CREATE PROCEDURE put_item_to_warehouse (IN wrhs_id INT, IN itm_id INT, qty DOUBLE)
BEGIN
  DECLARE curr_on_hand DOUBLE;
  SET curr_on_hand  = NULL;
  
  IF EXISTS(SELECT warehouse_id FROM inventory_by_warehouse WHERE warehouse_id = wrhs_id AND item_id = itm_id)
  THEN
    SELECT on_hand INTO curr_on_hand FROM inventory_by_warehouse WHERE warehouse_id = wrhs_id AND item_id = itm_id LIMIT 1;
	UPDATE inventory_by_warehouse SET on_hand = curr_on_hand + qty WHERE warehouse_id = wrhs_id AND item_id = itm_id;
  ELSE
	INSERT INTO inventory_by_warehouse (warehouse_id , item_id, on_hand) VALUES (wrhs_id, itm_id, qty);
  END IF;
END//

DELIMITER ;

SELECT * FROM inventory_by_warehouse WHERE warehouse_id = 1;
CALL put_item_to_warehouse(1, 1, 2);
CALL put_item_to_warehouse(1, 2, 1);
SELECT * FROM inventory_by_warehouse WHERE warehouse_id = 1;

/* Создать заказ на закупку с одной строкой, плановая дата поступления расчитывается случайным образом */
DELIMITER //
DROP PROCEDURE IF EXISTS create_purchase_order//
CREATE PROCEDURE create_purchase_order (IN buyer INT, IN bpartner INT, IN wrhs INT, IN currency INT, IN item INT, qty DOUBLE, price DECIMAL)
BEGIN
	DECLARE new_order INT;

	SELECT MAX(order_number_id) + 1 INTO new_order FROM purchase_order;

	INSERT INTO purchase_order (order_number_id, buyer_id, business_partner_id, warehouse_id, currency_id, planned_receipt_date)
	VALUES (new_order, buyer, bpartner, wrhs, currency, NOW() + INTERVAL FLOOR(RAND() * 365) DAY);
	
	INSERT INTO purchase_order_lines (order_number_id, line, item_id, ordered_quantity, price) 
	VALUES (new_order, 1, item, qty, price);
END//
DELIMITER ;

CALL create_purchase_order(2, 3, 5, 1, 1, 5, 60);

SELECT * FROM purchase_order po JOIN purchase_order_lines pol ON po.order_number_id =pol.order_number_id 
ORDER BY po.order_number_id DESC 
LIMIT 1;