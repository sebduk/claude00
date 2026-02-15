-- =======================================================================
-- See Our Family - MariaDB Schema
-- =======================================================================
--
-- Migrated from: Classic ASP + MS Access (multiple .mdb files)
-- Target: Single MariaDB database consolidating all families
--
-- Naming conventions:
--   Tables: plural, lowercase, English
--   Columns: lowercase, snake_case
--   Primary keys: id (auto-increment)
--   Foreign keys: <singular_table>_id
--   Link tables: <table1>_<table2>_link
--
-- All tables have:
--   is_online: soft-delete flag (1=active, 0=deleted but recoverable)
--   created_at: auto-set on insert
--   updated_by: application user id who last modified
--   updated_at: auto-set on insert and update
--
-- Content tables (people, couples, photos, etc.) all have a family_id.
-- No content is ever shown without filtering on the family in session.
--
-- Date precision: dates that may be partially known (birth, death,
-- marriage) use a DATE column + a _precision column:
--   'ymd' = exact day known
--   'ym'  = only year and month known
--   'y'   = only year known
--   NULL  = date itself is NULL
--
-- Photo/document files are stored on disk. The database holds metadata
-- and the file path. Thumbnails are generated or stored alongside.
-- =======================================================================

DROP DATABASE IF EXISTS `seeourfamily`;
CREATE DATABASE `seeourfamily` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `seeourfamily`;


-- =======================================================================
-- ADMINISTRATIVE TABLES
-- =======================================================================

-- families: each family tree is a tenant in the system
CREATE TABLE `families` (
  `id`              INT          NOT NULL AUTO_INCREMENT,
  `name`            VARCHAR(255) NOT NULL,
  `title`           VARCHAR(255)          COMMENT 'Display title, e.g. "Smith Family Genealogy"',
  `language`        VARCHAR(3)   NOT NULL DEFAULT 'ENG' COMMENT 'ENG, FRA, ESP, ITA, POR, DEU, NLD',
  `date_format`     VARCHAR(3)   NOT NULL DEFAULT 'dmy' COMMENT 'dmy or mdy',
  `package`         VARCHAR(20)  NOT NULL DEFAULT 'Starter' COMMENT 'Starter, Premium, Platinum',
  `url`             VARCHAR(255)          COMMENT 'Custom URL for Platinum packages',
  `hash`            VARCHAR(25)           COMMENT 'Random key for URL-based access',
  `guest_password`  VARCHAR(255)          COMMENT 'Visitor password for Platinum packages',
  `admin_password`  VARCHAR(255)          COMMENT 'Admin password',
  `is_online`       TINYINT      NOT NULL DEFAULT 1,
  `created_at`      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_by`      INT                   DEFAULT NULL,
  `updated_at`      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_families_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- users: application-level user accounts
CREATE TABLE `users` (
  `id`              INT          NOT NULL AUTO_INCREMENT,
  `login`           VARCHAR(255) NOT NULL,
  `password`        VARCHAR(255) NOT NULL COMMENT 'Will be hashed in app layer',
  `name`            VARCHAR(255),
  `email`           VARCHAR(255),
  `is_online`       TINYINT      NOT NULL DEFAULT 1,
  `created_at`      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_by`      INT                   DEFAULT NULL,
  `updated_at`      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_users_login` (`login`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- user_family_link: which users have access to which families, and their role
CREATE TABLE `user_family_link` (
  `user_id`         INT          NOT NULL,
  `family_id`       INT          NOT NULL,
  `role`            VARCHAR(10)  NOT NULL COMMENT 'Owner, Admin, Guest',
  `is_online`       TINYINT      NOT NULL DEFAULT 1,
  `created_at`      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_by`      INT                   DEFAULT NULL,
  `updated_at`      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`, `family_id`),
  KEY `idx_ufl_user`   (`user_id`),
  KEY `idx_ufl_family` (`family_id`),
  CONSTRAINT `fk_ufl_user`   FOREIGN KEY (`user_id`)   REFERENCES `users`    (`id`),
  CONSTRAINT `fk_ufl_family` FOREIGN KEY (`family_id`) REFERENCES `families` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- =======================================================================
-- CONTENT TABLES (all scoped by family_id)
-- =======================================================================

-- people: individual family members
CREATE TABLE `people` (
  `id`              INT          NOT NULL AUTO_INCREMENT,
  `family_id`       INT          NOT NULL,
  `couple_id`       INT                   DEFAULT NULL COMMENT 'FK to parent couple (who are the parents)',
  `couple_sort`     INT                   DEFAULT NULL COMMENT 'Sibling ordering within parent couple',
  `first_name`      VARCHAR(255),
  `first_names`     VARCHAR(255)          COMMENT 'All first/middle names',
  `last_name`       VARCHAR(255),
  `is_male`         TINYINT               COMMENT '1=male, 0=female, NULL=unknown',
  `birth_date`      DATE                  DEFAULT NULL,
  `birth_precision` VARCHAR(3)            DEFAULT NULL COMMENT 'ymd, ym, or y',
  `birth_place`     VARCHAR(255),
  `death_date`      DATE                  DEFAULT NULL,
  `death_precision` VARCHAR(3)            DEFAULT NULL COMMENT 'ymd, ym, or y',
  `death_place`     VARCHAR(255),
  `email`           VARCHAR(255)          COMMENT 'Private, not displayed publicly',
  `biography`       TEXT                  COMMENT 'Free-form biography',
  `links`           TEXT                  COMMENT 'Cross-family links (one per line)',
  `is_online`       TINYINT      NOT NULL DEFAULT 1,
  `created_at`      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_by`      INT                   DEFAULT NULL,
  `updated_at`      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_people_family` (`family_id`),
  KEY `idx_people_couple` (`couple_id`),
  CONSTRAINT `fk_people_family` FOREIGN KEY (`family_id`) REFERENCES `families` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- couples: marriages or partnerships linking two people
CREATE TABLE `couples` (
  `id`              INT          NOT NULL AUTO_INCREMENT,
  `family_id`       INT          NOT NULL,
  `person1_id`      INT                   DEFAULT NULL COMMENT 'Traditionally the husband',
  `person2_id`      INT                   DEFAULT NULL COMMENT 'Traditionally the wife',
  `start_date`      DATE                  DEFAULT NULL COMMENT 'Marriage/union date',
  `start_precision` VARCHAR(3)            DEFAULT NULL,
  `start_place`     VARCHAR(255),
  `end_date`        DATE                  DEFAULT NULL COMMENT 'Divorce/end date',
  `end_precision`   VARCHAR(3)            DEFAULT NULL,
  `end_place`       VARCHAR(255),
  `comment`         TEXT,
  `is_online`       TINYINT      NOT NULL DEFAULT 1,
  `created_at`      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_by`      INT                   DEFAULT NULL,
  `updated_at`      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_couples_family`  (`family_id`),
  KEY `idx_couples_person1` (`person1_id`),
  KEY `idx_couples_person2` (`person2_id`),
  CONSTRAINT `fk_couples_family`  FOREIGN KEY (`family_id`)  REFERENCES `families` (`id`),
  CONSTRAINT `fk_couples_person1` FOREIGN KEY (`person1_id`) REFERENCES `people`   (`id`),
  CONSTRAINT `fk_couples_person2` FOREIGN KEY (`person2_id`) REFERENCES `people`   (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- photos: photo and document metadata (files stored on disk)
CREATE TABLE `photos` (
  `id`              INT          NOT NULL AUTO_INCREMENT,
  `family_id`       INT          NOT NULL,
  `file_name`       VARCHAR(255)          COMMENT 'Filename on disk',
  `description`     TEXT,
  `photo_date`      DATE                  DEFAULT NULL,
  `photo_precision` VARCHAR(3)            DEFAULT NULL COMMENT 'ymd, ym, or y',
  `is_online`       TINYINT      NOT NULL DEFAULT 1,
  `created_at`      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_by`      INT                   DEFAULT NULL,
  `updated_at`      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_photos_family` (`family_id`),
  CONSTRAINT `fk_photos_family` FOREIGN KEY (`family_id`) REFERENCES `families` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- photo_person_link: which people appear in which photos
CREATE TABLE `photo_person_link` (
  `photo_id`        INT          NOT NULL,
  `person_id`       INT          NOT NULL,
  `sort_order`      INT          NOT NULL DEFAULT 0,
  PRIMARY KEY (`photo_id`, `person_id`),
  KEY `idx_ppl_photo`  (`photo_id`),
  KEY `idx_ppl_person` (`person_id`),
  CONSTRAINT `fk_ppl_photo`  FOREIGN KEY (`photo_id`)  REFERENCES `photos` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ppl_person` FOREIGN KEY (`person_id`) REFERENCES `people` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- comments: events, anecdotes, biographical notes attached to people
CREATE TABLE `comments` (
  `id`              INT          NOT NULL AUTO_INCREMENT,
  `family_id`       INT          NOT NULL,
  `title`           VARCHAR(255),
  `event_date`      VARCHAR(255)          COMMENT 'Free-text date (kept flexible as in original)',
  `body`            TEXT,
  `is_online`       TINYINT      NOT NULL DEFAULT 1,
  `created_at`      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_by`      INT                   DEFAULT NULL,
  `updated_at`      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_comments_family` (`family_id`),
  CONSTRAINT `fk_comments_family` FOREIGN KEY (`family_id`) REFERENCES `families` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- comment_person_link: which people are referenced in which comments
CREATE TABLE `comment_person_link` (
  `comment_id`      INT          NOT NULL,
  `person_id`       INT          NOT NULL,
  `sort_order`      INT          NOT NULL DEFAULT 0,
  PRIMARY KEY (`comment_id`, `person_id`),
  KEY `idx_cpl_comment` (`comment_id`),
  KEY `idx_cpl_person`  (`person_id`),
  CONSTRAINT `fk_cpl_comment` FOREIGN KEY (`comment_id`) REFERENCES `comments` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_cpl_person`  FOREIGN KEY (`person_id`)  REFERENCES `people`   (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- forums: message boards (one per topic/category)
CREATE TABLE `forums` (
  `id`              INT          NOT NULL AUTO_INCREMENT,
  `family_id`       INT          NOT NULL,
  `parent_id`       INT                   DEFAULT NULL COMMENT 'For nested forums (IdDad)',
  `sort_order`      INT                   DEFAULT 0,
  `admin_name`      VARCHAR(255)          COMMENT 'Forum administrator name',
  `title`           VARCHAR(255),
  `is_online`       TINYINT      NOT NULL DEFAULT 1,
  `created_at`      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_by`      INT                   DEFAULT NULL,
  `updated_at`      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_forums_family` (`family_id`),
  CONSTRAINT `fk_forums_family` FOREIGN KEY (`family_id`) REFERENCES `families` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- forum_items: individual messages posted to a forum
CREATE TABLE `forum_items` (
  `id`              INT          NOT NULL AUTO_INCREMENT,
  `forum_id`        INT          NOT NULL,
  `title`           VARCHAR(255),
  `author_name`     VARCHAR(255),
  `author_email`    VARCHAR(255),
  `body`            TEXT,
  `posted_at`       TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_online`       TINYINT      NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `idx_fi_forum` (`forum_id`),
  CONSTRAINT `fk_fi_forum` FOREIGN KEY (`forum_id`) REFERENCES `forums` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- infos: free-form information pages per family
CREATE TABLE `infos` (
  `id`              INT          NOT NULL AUTO_INCREMENT,
  `family_id`       INT          NOT NULL,
  `location`        VARCHAR(255)          COMMENT 'Page location/slot identifier',
  `content`         TEXT,
  `is_online`       TINYINT      NOT NULL DEFAULT 1,
  `created_at`      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_by`      INT                   DEFAULT NULL,
  `updated_at`      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_infos_family` (`family_id`),
  CONSTRAINT `fk_infos_family` FOREIGN KEY (`family_id`) REFERENCES `families` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- =======================================================================
-- COLUMN MAPPING REFERENCE (Access -> MariaDB)
-- =======================================================================
-- This section documents how old Access columns map to new columns,
-- for use by the migration script.
--
-- Domain (user.mdb)           -> families
--   IDDomain                  -> id
--   DomainName                -> name
--   DomainHeadTitle           -> title
--   DomainLanguage            -> language
--   DomainDateFormat          -> date_format
--   DomainPackage             -> package
--   DomainURL                 -> url
--   DomainRNDKey              -> hash
--   DomainPwdGuest            -> guest_password
--   DomainPwdAdmin            -> admin_password
--   DomainIsOnline            -> is_online
--   DomainDB                  -> (dropped, no longer needed)
--   DomainUpload              -> (dropped, derive from id)
--
-- User (user.mdb)             -> users
--   IDUser                    -> id
--   UserLogin                 -> login
--   UserPassword              -> password
--   UserName                  -> name
--   UserEmail                 -> email
--   UserIsOnline              -> is_online
--
-- LkDomainUser (user.mdb)     -> user_family_link
--   IdDomain                  -> family_id
--   IdUser                    -> user_id
--   Status                    -> role
--
-- Personne (family .mdb)      -> people
--   IDPersonne                -> id
--   IDCouple                  -> couple_id
--   TriCouple                 -> couple_sort
--   Prenom                    -> first_name
--   Prenoms                   -> first_names
--   Nom                       -> last_name
--   IsMasc                    -> is_male
--   DtNaiss + DateNaiss       -> birth_date + birth_precision
--   DtDec + DateDec           -> death_date + death_precision
--   LieuNaiss                 -> birth_place
--   LieuDec                   -> death_place
--   Email                     -> email
--   Comm                      -> biography
--   Link                      -> links
--   LastUpdateWho             -> updated_by
--   LastUpdateWhen            -> updated_at
--   (new)                     -> family_id (set per source .mdb)
--
-- Couple (family .mdb)        -> couples
--   IDCouple                  -> id
--   IDPersMasc                -> person1_id
--   IDPersFem                 -> person2_id
--   DtCouple + DateCouple     -> start_date + start_precision
--   LieuCouple                -> start_place
--   LastUpdateWho             -> updated_by
--   LastUpdateWhen            -> updated_at
--   (new)                     -> family_id
--
-- Photo (family .mdb)         -> photos
--   IDPhoto                   -> id
--   NomPhoto                  -> file_name
--   DescrPhoto                -> description
--   DtYear/DtMonth/DtDay/Date -> photo_date + photo_precision
--   LastUpdateWho             -> updated_by
--   LastUpdateWhen            -> updated_at
--   (new)                     -> family_id
--
-- LienPhotoPerso              -> photo_person_link
--   IdPhoto                   -> photo_id
--   IdPersonne                -> person_id
--   SortKey                   -> sort_order
--
-- Commentaire (family .mdb)   -> comments
--   IDCommentaire             -> id
--   Titre                     -> title
--   DtVecu                    -> event_date
--   Comm                      -> body
--   LastUpdateWho             -> updated_by
--   LastUpdateWhen            -> updated_at
--   (new)                     -> family_id
--
-- LienCommPerso               -> comment_person_link
--   IdCommentaire             -> comment_id
--   IdPersonne                -> person_id
--   SortKey                   -> sort_order
--
-- Forum (family .mdb)         -> forums
--   IDForum                   -> id
--   IdDad                     -> parent_id
--   ForumSort                 -> sort_order
--   ForumAdmin                -> admin_name
--   ForumTitle                -> title
--   ForumIsOnline             -> is_online
--   LastUpdateWho             -> updated_by
--   LastUpdateWhen            -> updated_at
--   (new)                     -> family_id
--
-- ForumItem (family .mdb)     -> forum_items
--   IDForumItem               -> id
--   IdForum                   -> forum_id
--   ForumItemTitle            -> title
--   ForumItemFrom             -> author_name
--   ForumItemEmail            -> author_email
--   ForumItemBody             -> body
--   ForumItemDate             -> posted_at
--   ForumItemIsOnline         -> is_online
--
-- Info (family .mdb)          -> infos
--   IDInfo                    -> id
--   InfoLocation              -> location
--   InfoContent               -> content
--   InfoIsOnline              -> is_online
--   LastUpdateWho             -> updated_by
--   LastUpdateWhen            -> updated_at
--   (new)                     -> family_id
-- =======================================================================
