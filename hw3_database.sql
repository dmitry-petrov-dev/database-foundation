/* Написать крипт, добавляющий в БД vk, которую создали на занятии, 3 новые таблицы (с перечнем полей, указанием индексов и внешних ключей) */

DROP TABLE IF EXISTS `media_comments`;
CREATE TABLE `media_comments` (
	id BIGINT UNSIGNED NOT NULL,
	`media_id` BIGINT UNSIGNED NOT NULL,
	`user_id` BIGINT UNSIGNED NOT NULL,
	body text,
	`parent_comment_id` BIGINT UNSIGNED DEFAULT NULL,
	created_at DATETIME DEFAULT NOW(),
	updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP,

	PRIMARY KEY (id, media_id), -- В рамках каждого медия-контента своя нумерация комментариев
	FOREIGN KEY (user_id) REFERENCES users(id),
	FOREIGN KEY (media_id) REFERENCES media(id),
	FOREIGN KEY (parent_comment_id) REFERENCES media_comments(id)
);

DROP TABLE IF EXISTS `video_albums`;
CREATE TABLE `video_albums` (
	`id` SERIAL,
	`name` varchar(255) DEFAULT NULL,
	`user_id` BIGINT UNSIGNED DEFAULT NULL,

	FOREIGN KEY (user_id) REFERENCES users(id),
	PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `videos`;
CREATE TABLE `videos` (
	id SERIAL,
	`album_id` BIGINT unsigned NOT NULL,
	`media_id` BIGINT unsigned NOT NULL,

	FOREIGN KEY (album_id) REFERENCES video_albums(id),
	FOREIGN KEY (media_id) REFERENCES media(id)
);

DROP TABLE IF EXISTS `song_albums`;
CREATE TABLE `song_albums` (
	`id` SERIAL,
	`name` varchar(255) DEFAULT NULL,
	`author` varchar(255) DEFAULT NULL,
	`year` DATE DEFAULT NULL,
	`user_id` BIGINT UNSIGNED DEFAULT NULL,

	FOREIGN KEY (user_id) REFERENCES users(id),
	PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `song_playlists`;
CREATE TABLE `song_playlists` (
	`id` SERIAL,
	`name` varchar(255) DEFAULT NULL,
	`user_id` BIGINT UNSIGNED DEFAULT NULL,
	created_at DATETIME DEFAULT NOW(),
	updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP,

	FOREIGN KEY (user_id) REFERENCES users(id),
	PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `songs`;
CREATE TABLE `songs` (
	id SERIAL,
	album_id BIGINT unsigned NOT NULL,
	media_id BIGINT unsigned NOT NULL,

	FOREIGN KEY (album_id) REFERENCES song_albums(id),
	FOREIGN KEY (media_id) REFERENCES media(id)
);

DROP TABLE IF EXISTS song_song_playlists;
CREATE TABLE song_song_playlists(
	song_id BIGINT UNSIGNED NOT NULL,
	playlists_id BIGINT UNSIGNED NOT NULL,

	PRIMARY KEY (song_id, playlists_id),
	FOREIGN KEY (song_id) REFERENCES songs(id),
	FOREIGN KEY (playlists_id) REFERENCES song_playlists(id)
);