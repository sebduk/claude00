-- ---------------------------------------
-- Commentaires Generaux:
-- ---------------------------------------
-- Tous les noms sont en Anglais pour avoir la possibilite de trouver de l'aide ailleurs s'il faut.
-- Les tables sont toutes au pluriel et les elements de contenu au singulier: table: families, element: family donc familyid et pas familiesid pour les clefs de reference
--
-- Toutes les tables ont une clef unique: ID sauf si ce sont des tables de liens (...lk pour link)
-- Les clefs externes suivent le schema nom-d-elementid (ex `familyid`)
--
-- Toutes les tables ont un drapeau `isonline`.
--    Si `isonline`=0 l'element n'est plus a prendre en compte et pourra etre efface.
--    C'est un moyen pour pouvoir laisser les utilisateurs effacer et permettre a un admin d'annuler s'il le faut.
-- Toutes les tables ont un createwho/when et updatewho/when pour noter les creations et dernieres mises a jour.
--    Le who c'est l'utilisateur (userid) en session d'application (pas l'utilisateur MySQL).
--
-- La table `idkey` sert a generer des clefs pour masquer les ID passes en clair dans l'application.
--    Chaque identifiant (quelqu'il soit) aura une clef unique par utilisateur generee au vol et ajoutee si l'identifiant n'est pas deja present.
--    Les clefs d'un utilisateur pourront etre purgees a chaque nouvelle sessions.
--
-- Toutes les tables de contenu (a partir de `people`) on un familyid.
--    Aucun contenu sera presente sans etre attache a la famille en session d'application.
--    C'est une deuxieme securite avec le systeme d'idkey.
--
-- J'ai simplifie la notion de commentaires/documents/photos
--    On a une table pour les commentaires (table `comments`) auxquels on peut ajouter un ou plusieurs documents (table `documents`).
--    Photos et documents sont tous dans la base de donnees dans la table `documents`. On a plus de repertoires de stockage.
--    Les documents sont presentes dans le cadre d'un commentaire sous forme de document ou photo selon leur type.
--    Les vignettes (thumbnails) de photos seront soit generees au vol a l'affichage; soit stockees aves la photo correspontdante dans le commentaire (2 documents attaches a 1 commentaire)
-- ---------------------------------------
-- Questions:
-- ---------------------------------------
-- Toutes les donnees sont partagees dans une seule base.
--    Est-ce que je m'enquiquine a attacher les donnees a des utilisateurs MySQL par mesure de protection?
--    Ou idkey + le filtre sur le familyid ca peut suffir?
--
-- Updatewho/when j'utlise maintenant pour debuger et trouver la source quand il y a litige.
--    Createwho/when on s'en fout ou ca vaut le coup de garder?
--
-- Les dates affichables sont maintenant en vraies dates avec un filtre de precision (ymd veut dire que la precision et donc l'affichage et au jour pres, y ou ym sont precis a l'annee ou a mois pres)
--    Adrien, tu m'as parle d'une methode pour ca... tu pensais a autre chose?
-- ---------------------------------------



DROP DATABASE IF EXISTS `seeourfamily`;
CREATE DATABASE `seeourfamily`;
USE `seeourfamily`;

-- ---------------------------------------
-- Administrative Tables
-- ---------------------------------------

-- Table structure for table `families`
DROP TABLE IF EXISTS `families`;
CREATE TABLE `families` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
	`title` varchar(255),
	`domain` varchar(255),
	`language` varchar(3) NOT NULL DEFAULT 'ENG',
	`intlformat` varchar(3) NOT NULL DEFAULT 'ENG',
	`packageid` int(11) NOT NULL DEFAULT '1',
	`adminpw` varchar(255),
	`guestpw` varchar(255),
	`hash` varchar(25),
	`isqueryman` tinyint(4) DEFAULT '0',
	`isonline` tinyint(4) DEFAULT '1',
	`createwho` int(11) NOT NULL DEFAULT '1',
	`createwhen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	`updatewho` int(11) NOT NULL DEFAULT '1',
	`updatewhen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO `families` (`name`) VALUES ('Tajan'), ('Ducos'), ('Moeskops');


-- Table structure for table `packages`
DROP TABLE IF EXISTS `packages`;
CREATE TABLE `packages` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
	`isonline` tinyint(4) DEFAULT '1',
	`createwho` int(11) NOT NULL DEFAULT '1',
	`createwhen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	`updatewho` int(11) NOT NULL DEFAULT '1',
	`updatewhen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO `packages` (`name`) values ('Starter'), ('Premium'), ('Platinum');
UPDATE `families` SET `packageid`=3;

-- Table structure for table `users`
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
	`user` varchar(255) NOT NULL,
	`passwd` varchar(25) NOT NULL DEFAULT 'temp',
	`name` varchar(255),
	`email` varchar(255),
	`isonline` tinyint(4) DEFAULT '1',
	`createwho` int(11) NOT NULL DEFAULT '1',
	`createwhen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	`updatewho` int(11) NOT NULL DEFAULT '1',
	`updatewhen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `user` (`user`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO `users` (`user`) values ('sebduk'), ('francois'), ('test');


-- Table structure for table `userfamilylk`
DROP TABLE IF EXISTS `userfamilylk`;
CREATE TABLE `userfamilylk` (
  `userid` int(11) NOT NULL,
  `familyid` int(11) NOT NULL,
	`rights` varchar(5) NOT NULL,
	`isonline` tinyint(4) DEFAULT '1',
	`createwho` int(11) NOT NULL DEFAULT '1',
	`createwhen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	`updatewho` int(11) NOT NULL DEFAULT '1',
	`updatewhen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`userid`, `familyid`),
  KEY `userid` (`userid`),
  KEY `familyid` (`familyid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO `userfamilylk` (`userid`, `familyid`, `rights`) SELECT 1, ID, 'Owner' from `families`;
INSERT INTO `userfamilylk` (`userid`, `familyid`, `rights`) SELECT 2, ID, 'Admin' from `families`;
INSERT INTO `userfamilylk` (`userid`, `familyid`, `rights`) SELECT 3, ID, 'Guest' from `families`;


-- Table structure for table `idkey`
DROP TABLE IF EXISTS `idkey`;
CREATE TABLE `idkey` (
	`userid` int(11) NOT NULL,
  `id` int(11) NOT NULL,
  `key` varchar(25) NOT NULL,
	`isonline` tinyint(4) DEFAULT '1',
	`createwho` int(11) NOT NULL DEFAULT '1',
	`createwhen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	`updatewho` int(11) NOT NULL DEFAULT '1',
	`updatewhen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`userid`, `id`),
  KEY `key` (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO `idkey` (`userid`, `id`, `key`) VALUES (1, 1, '9x2+UmKKP4OnerSUgXUlxg');


-- ---------------------------------------
-- Content Tables
-- ---------------------------------------

-- Table structure for table `people`
DROP TABLE IF EXISTS `people`;
CREATE TABLE `people` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
	`familyid` int(11) NOT NULL,
	`coupleid` int(11) NOT NULL DEFAULT 0,
	`couplesort` int(11) NOT NULL DEFAULT 0,
	`firstname` varchar(255),
	`lastname` varchar(255),
	`fullname` varchar(255),
	`ismale` tinyint(4),
	`birthdate` date,
	`birthform` varchar(3),
	`birthplace` varchar(255),
	`deathdate` date,
	`deathform` varchar(3),
	`deathplace` varchar(255),
	`email` varchar(255),
	`comment` text,
	`isdirect` tinyint(4) DEFAULT '0',
	`isvip` tinyint(4) DEFAULT '0',
	`isonline` tinyint(4) DEFAULT '1',
	`createwho` int(11) NOT NULL DEFAULT '1',
	`createwhen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	`updatewho` int(11) NOT NULL DEFAULT '1',
	`updatewhen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO `people` (`familyid`, `firstname`, `lastname`, `ismale`, `birthdate`, `birthform`, `birthplace`, `isdirect`) values (1, 'Sebastien', 'Ducos', 1, '1967-12-02', 'ymd', 'Paris', 1);
INSERT INTO `people` (`familyid`, `firstname`, `lastname`, `ismale`, `birthdate`, `birthform`, `birthplace`, `isdirect`) values (1, 'Francois', 'Ducos', 1, '1942-05-15', 'ymd', 'Paris', 1);
INSERT INTO `people` (`familyid`, `firstname`, `lastname`, `ismale`, `birthdate`, `birthform`, `birthplace`, `isdirect`) values (1, 'Magda', 'Moeskops', 1, '1943-06-06', 'ymd', 'Voorburg', 0);


-- Table structure for table `couples`
DROP TABLE IF EXISTS `couples`;
CREATE TABLE `couples` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
	`familyid` int(11) NOT NULL,
	`person1id` int(11) NOT NULL DEFAULT 0,
	`person2id` int(11) NOT NULL DEFAULT 0,
	`sort` int(11) NOT NULL DEFAULT 0,
	`startdate` date,
	`startform` varchar(3),
	`startplace` varchar(255),
	`enddate` date,
	`endform` varchar(3),
	`endplace` varchar(255),
	`comment` text,
	`isonline` tinyint(4) DEFAULT '1',
	`createwho` int(11) NOT NULL DEFAULT '1',
	`createwhen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	`updatewho` int(11) NOT NULL DEFAULT '1',
	`updatewhen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO `couples` (`familyid`, `person1id`, `person2id`) values (1, 2, 3);
UPDATE `people` SET coupleid=1 WHERE ID=1;


-- Table structure for table `comments`
DROP TABLE IF EXISTS `comments`;
CREATE TABLE `comments` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
	`familyid` int(11) NOT NULL,
	`title` varchar(255),
	`actiondate` date,
	`actionform` varchar(3),
	`actionplace` varchar(255),
	`comment` text,
	`author` varchar(255),
	`authordate` date,
	`authorform` varchar(3),
	`authorplace` varchar(255),
	`isonline` tinyint(4) DEFAULT '1',
	`createwho` int(11) NOT NULL DEFAULT '1',
	`createwhen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	`updatewho` int(11) NOT NULL DEFAULT '1',
	`updatewhen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO `comments` (`familyid`, `title`, `actiondate`, `actionform`, `actionplace`, `author`) values (1, 'Seb\'s born', '1967-12-02', 'ymd', 'Paris', 'Seb');


-- Table structure for table `personcommentlk`
DROP TABLE IF EXISTS `personcommentlk`;
CREATE TABLE `personcommentlk` (
	`familyid` int(11) NOT NULL,
	`personid` int(11) NOT NULL,
	`commentid` int(11) NOT NULL,
	`sort` int(11) NOT NULL DEFAULT 0,
	`isonline` tinyint(4) DEFAULT '1',
	`createwho` int(11) NOT NULL DEFAULT '1',
	`createwhen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	`updatewho` int(11) NOT NULL DEFAULT '1',
	`updatewhen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`personid`, `commentid`),
	KEY `personid` (`personid`),
	KEY `commentid` (`commentid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO `personcommentlk` (`familyid`, `personid`, `commentid`) values (1, 1, 1);


-- Table structure for table `documents`
DROP TABLE IF EXISTS `documents`;
CREATE TABLE `documents` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
	`familyid` int(11) NOT NULL,
	`commentid` int(11) NOT NULL,
	`filename` varchar(255),
	`filetype` varchar(3),
	`document` mediumblob,
	`isonline` tinyint(4) DEFAULT '1',
	`createwho` int(11) NOT NULL DEFAULT '1',
	`createwhen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	`updatewho` int(11) NOT NULL DEFAULT '1',
	`updatewhen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO `documents` (`familyid`, `commentid`, `filename`, `filetype`) values (1, 1, 'Seb\'s pic', 'jpg');


-- ---------------------------------------
-- Show Contents
-- ---------------------------------------
SELECT * FROM `tables`;
SELECT * FROM `families`;
SELECT * FROM `packages`;
SELECT * FROM `users`;
SELECT * FROM `userfamilylk`;
SELECT * FROM `people`;
SELECT * FROM `couples`;
SELECT * FROM `comments`;
SELECT * FROM `personcommentlk`;
SELECT * FROM `documents`;
