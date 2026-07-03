-- MySQL dump 10.13  Distrib 8.0.46, for Linux (x86_64)
--
-- Host: localhost    Database: sportigo
-- ------------------------------------------------------
-- Server version   8.0.46

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `activities`
--

DROP TABLE IF EXISTS `activities`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `activities` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `type` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `message` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `meta` json DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `activities_user_id_foreign` (`user_id`),
  CONSTRAINT `activities_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `activities`
--

LOCK TABLES `activities` WRITE;
/*!40000 ALTER TABLE `activities` DISABLE KEYS */;
INSERT INTO `activities` VALUES (1,11,'match_joined','Devan joined the Padel match: \"Southern Derby\"','{\"title\": \"Southern Derby\", \"location\": \"CentralSquare\", \"match_id\": 13, \"sport_type\": \"Padel\"}','2026-05-21 06:23:30','2026-05-21 06:23:30'),(2,13,'match_joined','Saina joined the Padel match: \"Southern Derby\"','{\"title\": \"Southern Derby\", \"location\": \"CentralSquare\", \"match_id\": 13, \"sport_type\": \"Padel\"}','2026-05-21 08:34:14','2026-05-21 08:34:14'),(3,13,'match_joined','Saina joined the Football match: \"Women\'s power\"','{\"title\": \"Women\'s power\", \"location\": \"Central Park\", \"match_id\": 14, \"sport_type\": \"Football\"}','2026-05-21 09:26:08','2026-05-21 09:26:08'),(4,13,'match_left','Saina left the Football match: \"Women\'s power\"','{\"title\": \"Women\'s power\", \"location\": \"Central Park\", \"match_id\": 14, \"sport_type\": \"Football\"}','2026-05-21 09:26:23','2026-05-21 09:26:23'),(5,13,'match_joined','Saina joined the Football match: \"Women\'s power\"','{\"title\": \"Women\'s power\", \"location\": \"Central Park\", \"match_id\": 14, \"sport_type\": \"Football\"}','2026-05-21 09:26:45','2026-05-21 09:26:45'),(6,11,'match_created','Devan created a Football match: \"Suiii\"','{\"title\": \"Suiii\", \"location\": \"Khel\", \"match_id\": 15, \"sport_type\": \"Football\"}','2026-05-21 09:36:22','2026-05-21 09:36:22'),(7,14,'match_created','Davi created a Cricket match: \"kings match\"','{\"title\": \"kings match\", \"location\": \"one4all\", \"match_id\": 16, \"sport_type\": \"Cricket\"}','2026-05-21 10:02:24','2026-05-21 10:02:24'),(8,10,'match_joined','Ajith joined the Cricket match: \"kings match\"','{\"title\": \"kings match\", \"location\": \"one4all\", \"match_id\": 16, \"sport_type\": \"Cricket\"}','2026-05-21 11:56:49','2026-05-21 11:56:49'),(9,10,'match_created','Ajith created a Football match: \"kings derby\"','{\"title\": \"kings derby\", \"location\": \"Khel\", \"match_id\": 17, \"sport_type\": \"Football\"}','2026-05-21 11:57:35','2026-05-21 11:57:35'),(10,13,'match_left','Saina left the Football match: \"Women\'s power\"','{\"title\": \"Women\'s power\", \"location\": \"Central Park\", \"match_id\": 14, \"sport_type\": \"Football\"}','2026-05-21 11:58:46','2026-05-21 11:58:46'),(11,10,'match_created','Ajith created a Football match: \"Friday evening\"','{\"title\": \"Friday evening\", \"location\": \"Khel\", \"match_id\": 18, \"sport_type\": \"Football\"}','2026-05-25 04:27:28','2026-05-25 04:27:28'),(12,11,'match_created','Devan created a Cricket match: \"Ball Kali\"','{\"title\": \"Ball Kali\", \"location\": \"one4all\", \"match_id\": 19, \"sport_type\": \"Cricket\"}','2026-05-25 04:38:39','2026-05-25 04:38:39'),(13,13,'match_created','Saina created a Badminton match: \"Girls derby\"','{\"title\": \"Girls derby\", \"location\": \"one4all\", \"match_id\": 20, \"sport_type\": \"Badminton\"}','2026-05-25 04:47:09','2026-05-25 04:47:09'),(14,12,'match_joined','pv sindhu joined the Badminton match: \"Girls derby\"','{\"title\": \"Girls derby\", \"location\": \"one4all\", \"match_id\": 20, \"sport_type\": \"Badminton\"}','2026-05-25 04:50:14','2026-05-25 04:50:14'),(15,10,'match_created','Ajith created a Football match: \"Evening Derby\"','{\"title\": \"Evening Derby\", \"location\": \"khel\", \"match_id\": 21, \"sport_type\": \"Football\"}','2026-06-02 04:29:54','2026-06-02 04:29:54'),(16,11,'match_created','Devan created a Cricket match: \"Bulls vd Petta\"','{\"title\": \"Bulls vd Petta\", \"location\": \"one4all\", \"match_id\": 22, \"sport_type\": \"Cricket\"}','2026-06-02 04:31:36','2026-06-02 04:31:36'),(17,13,'match_created','Saina created a Badminton match: \"women\'s derby\"','{\"title\": \"women\'s derby\", \"location\": \"cetralaquare\", \"match_id\": 23, \"sport_type\": \"Badminton\"}','2026-06-02 04:33:42','2026-06-02 04:33:42'),(18,13,'match_created','Saina created a Badminton match: \"National Derby\"','{\"title\": \"National Derby\", \"location\": \"one4all\", \"match_id\": 24, \"sport_type\": \"Badminton\"}','2026-06-02 09:18:24','2026-06-02 09:18:24'),(19,14,'match_joined','Davi joined the Badminton match: \"National Derby\"','{\"title\": \"National Derby\", \"location\": \"one4all\", \"match_id\": 24, \"sport_type\": \"Badminton\"}','2026-06-02 09:28:38','2026-06-02 09:28:38'),(20,14,'match_left','Davi left the Badminton match: \"National Derby\"','{\"title\": \"National Derby\", \"location\": \"one4all\", \"match_id\": 24, \"sport_type\": \"Badminton\"}','2026-06-02 09:28:48','2026-06-02 09:28:48'),(21,14,'match_joined','Davi joined the Badminton match: \"National Derby\"','{\"title\": \"National Derby\", \"location\": \"one4all\", \"match_id\": 24, \"sport_type\": \"Badminton\"}','2026-06-02 09:28:58','2026-06-02 09:28:58'),(22,14,'match_joined','Davi joined the Cricket match: \"Bulls vd Petta\"','{\"title\": \"Bulls vd Petta\", \"location\": \"one4all\", \"match_id\": 22, \"sport_type\": \"Cricket\"}','2026-06-02 09:29:17','2026-06-02 09:29:17'),(23,10,'match_joined','Ajith joined the Badminton match: \"National Derby\"','{\"title\": \"National Derby\", \"location\": \"one4all\", \"match_id\": 24, \"sport_type\": \"Badminton\"}','2026-06-03 09:56:07','2026-06-03 09:56:07'),(24,10,'match_joined','Ajith joined the Cricket match: \"Bulls vd Petta\"','{\"title\": \"Bulls vd Petta\", \"location\": \"one4all\", \"match_id\": 22, \"sport_type\": \"Cricket\"}','2026-06-03 09:56:24','2026-06-03 09:56:24'),(25,13,'match_joined','Saina joined the Cricket match: \"Bulls vd Petta\"','{\"title\": \"Bulls vd Petta\", \"location\": \"one4all\", \"match_id\": 22, \"sport_type\": \"Cricket\"}','2026-06-03 10:07:13','2026-06-03 10:07:13');
/*!40000 ALTER TABLE `activities` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cache`
--

DROP TABLE IF EXISTS `cache`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cache` (
  `key` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `value` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `expiration` bigint NOT NULL,
  PRIMARY KEY (`key`),
  KEY `cache_expiration_index` (`expiration`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cache`
--

LOCK TABLES `cache` WRITE;
/*!40000 ALTER TABLE `cache` DISABLE KEYS */;
INSERT INTO `cache` VALUES ('laravel-cache-04711b78aa966d7b9581afb539330aaa','i:1;',1779684674),('laravel-cache-04711b78aa966d7b9581afb539330aaa:timer','i:1779684674;',1779684674),('laravel-cache-1d24f8541c2f8c4c2ae0af31edc59d56','i:4;',1780392578),('laravel-cache-1d24f8541c2f8c4c2ae0af31edc59d56:timer','i:1780392578;',1780392578),('laravel-cache-1fd8e4cfeb25c473c174cced2fcfdfb7','i:7;',1780390185),('laravel-cache-1fd8e4cfeb25c473c174cced2fcfdfb7:timer','i:1780390185;',1780390185),('laravel-cache-1ffab215fed93d70020ec70aab22b366','i:1;',1780481293),('laravel-cache-1ffab215fed93d70020ec70aab22b366:timer','i:1780481293;',1780481293),('laravel-cache-21c7ea48997eeecf541f9afb4a8bfc81','i:2;',1780480933),('laravel-cache-21c7ea48997eeecf541f9afb4a8bfc81:timer','i:1780480933;',1780480933),('laravel-cache-6781b99112eccc12ee1b7fafde44da2a','i:2;',1780480627),('laravel-cache-6781b99112eccc12ee1b7fafde44da2a:timer','i:1780480627;',1780480627),('laravel-cache-7f3072bf378b98d6bbf2f013cff3e287','i:11;',1780551001),('laravel-cache-7f3072bf378b98d6bbf2f013cff3e287:timer','i:1780551001;',1780551001),('laravel-cache-a9fbf556bb00b390379f7dc89b796467','i:1;',1780551025),('laravel-cache-a9fbf556bb00b390379f7dc89b796467:timer','i:1780551025;',1780551025),('laravel-cache-ad4954e2e38bb42a3ba5cbc5eebbbdbc','i:1;',1780390110),('laravel-cache-ad4954e2e38bb42a3ba5cbc5eebbbdbc:timer','i:1780390110;',1780390110),('laravel-cache-d039f1c3f507bd8c04cab5ad888e9b83','i:1;',1780374756),('laravel-cache-d039f1c3f507bd8c04cab5ad888e9b83:timer','i:1780374756;',1780374756),('laravel-cache-ddb1b9ec7844ef9cfda4a92d9babf754','i:2;',1779267836),('laravel-cache-ddb1b9ec7844ef9cfda4a92d9babf754:timer','i:1779267835;',1779267835),('laravel-cache-de226f3f5dc0c66a464effdc07ca6b1f','i:1;',1780400399),('laravel-cache-de226f3f5dc0c66a464effdc07ca6b1f:timer','i:1780400399;',1780400399),('laravel-cache-e99134c5c1c2816f0453be60d1965bfc','i:1;',1779267836),('laravel-cache-e99134c5c1c2816f0453be60d1965bfc:timer','i:1779267836;',1779267836);
/*!40000 ALTER TABLE `cache` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cache_locks`
--

DROP TABLE IF EXISTS `cache_locks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cache_locks` (
  `key` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `owner` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `expiration` bigint NOT NULL,
  PRIMARY KEY (`key`),
  KEY `cache_locks_expiration_index` (`expiration`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cache_locks`
--

LOCK TABLES `cache_locks` WRITE;
/*!40000 ALTER TABLE `cache_locks` DISABLE KEYS */;
/*!40000 ALTER TABLE `cache_locks` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `failed_jobs`
--

DROP TABLE IF EXISTS `failed_jobs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `failed_jobs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `uuid` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `connection` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `queue` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `payload` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `exception` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `failed_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `failed_jobs_uuid_unique` (`uuid`),
  KEY `failed_jobs_connection_queue_failed_at_index` (`connection`,`queue`,`failed_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `failed_jobs`
--

LOCK TABLES `failed_jobs` WRITE;
/*!40000 ALTER TABLE `failed_jobs` DISABLE KEYS */;
/*!40000 ALTER TABLE `failed_jobs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `job_batches`
--

DROP TABLE IF EXISTS `job_batches`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `job_batches` (
  `id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `total_jobs` int NOT NULL,
  `pending_jobs` int NOT NULL,
  `failed_jobs` int NOT NULL,
  `failed_job_ids` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `options` mediumtext COLLATE utf8mb4_unicode_ci,
  `cancelled_at` int DEFAULT NULL,
  `created_at` int NOT NULL,
  `finished_at` int DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `job_batches`
--

LOCK TABLES `job_batches` WRITE;
/*!40000 ALTER TABLE `job_batches` DISABLE KEYS */;
/*!40000 ALTER TABLE `job_batches` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jobs`
--

DROP TABLE IF EXISTS `jobs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jobs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `queue` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `payload` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `attempts` smallint unsigned NOT NULL,
  `reserved_at` int unsigned DEFAULT NULL,
  `available_at` int unsigned NOT NULL,
  `created_at` int unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `jobs_queue_index` (`queue`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jobs`
--

LOCK TABLES `jobs` WRITE;
/*!40000 ALTER TABLE `jobs` DISABLE KEYS */;
/*!40000 ALTER TABLE `jobs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `migrations`
--

DROP TABLE IF EXISTS `migrations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `migrations` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `migration` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `batch` int NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `migrations`
--

LOCK TABLES `migrations` WRITE;
/*!40000 ALTER TABLE `migrations` DISABLE KEYS */;
INSERT INTO `migrations` VALUES (1,'0001_01_01_000000_create_users_table',1),(2,'0001_01_01_000001_create_cache_table',1),(3,'0001_01_01_000002_create_jobs_table',1),(4,'2026_05_15_045221_create_sport_matches_table',1),(5,'2026_05_15_045259_create_sport_match_user_table',1),(6,'2026_05_15_045750_create_personal_access_tokens_table',1),(7,'2026_05_18_064644_add_profile_photo_to_users_table',2),(8,'2026_05_18_100718_add_gender_to_users_table',3),(9,'2026_05_18_100751_add_women_only_to_sport_matches_table',3),(10,'2026_05_19_100000_add_creator_id_to_sport_matches_table',4),(11,'2026_05_19_100001_add_unique_user_match_to_sport_match_user_table',4),(12,'2026_05_19_110000_add_indexes_to_sport_matches_table',4),(13,'2026_05_19_120000_add_max_slots_to_sport_matches_table',4),(14,'2026_05_21_114704_create_activities_table',5),(15,'2026_05_21_140000_add_composite_cursor_index_to_sport_matches_table',6),(16,'2026_05_21_150000_add_slot_tracking_to_matches_table',6),(17,'2026_05_25_000000_create_slots_table',6),(18,'2026_05_25_045741_remove_unwanted_slot_columns_from_sport_matches_table',7),(19,'2026_05_25_052315_add_theme_preference_to_users_table',8);
/*!40000 ALTER TABLE `migrations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `password_reset_tokens`
--

DROP TABLE IF EXISTS `password_reset_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `password_reset_tokens` (
  `email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `token` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `password_reset_tokens`
--

LOCK TABLES `password_reset_tokens` WRITE;
/*!40000 ALTER TABLE `password_reset_tokens` DISABLE KEYS */;
/*!40000 ALTER TABLE `password_reset_tokens` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `personal_access_tokens`
--

DROP TABLE IF EXISTS `personal_access_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `personal_access_tokens` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `tokenable_type` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tokenable_id` bigint unsigned NOT NULL,
  `name` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `token` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `abilities` text COLLATE utf8mb4_unicode_ci,
  `last_used_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `personal_access_tokens_token_unique` (`token`),
  KEY `personal_access_tokens_tokenable_type_tokenable_id_index` (`tokenable_type`,`tokenable_id`),
  KEY `personal_access_tokens_expires_at_index` (`expires_at`)
) ENGINE=InnoDB AUTO_INCREMENT=134 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `personal_access_tokens`
--

LOCK TABLES `personal_access_tokens` WRITE;
/*!40000 ALTER TABLE `personal_access_tokens` DISABLE KEYS */;
INSERT INTO `personal_access_tokens` VALUES (2,'App\\Models\\User',2,'auth_token','5e73888d0366f8f68f002c6d49bfbaae2439a43c118b28810dca02f179f0792e','[\"*\"]',NULL,NULL,'2026-05-15 05:51:15','2026-05-15 05:51:15'),(3,'App\\Models\\User',2,'auth_token','ecea58d703bb357f2bea38762170a00d1f3a03ea5ad458a1de4218e1955662d8','[\"*\"]',NULL,NULL,'2026-05-15 05:52:37','2026-05-15 05:52:37'),(4,'App\\Models\\User',2,'auth_token','afc1c360b9c87cf863278c5244e7af3f032e2fae25cbe820ea6883a89ec136ce','[\"*\"]',NULL,NULL,'2026-05-15 05:52:45','2026-05-15 05:52:45'),(7,'App\\Models\\User',4,'auth_token','3b564cd8e04efa6bbf74a5d44071a6143129db14baf28b11dc48d24d4284bda4','[\"*\"]','2026-05-18 06:10:39',NULL,'2026-05-15 11:36:53','2026-05-18 06:10:39'),(8,'App\\Models\\User',2,'auth_token','f51fc09f5798afa877f16a23f43d64d109c8483276163c4e75a59a774c721f3f','[\"*\"]','2026-05-18 12:04:33',NULL,'2026-05-18 06:16:07','2026-05-18 12:04:33'),(27,'App\\Models\\User',6,'auth_token','2e8bb051bc80573a2d64a36c7774866815774c8ab16febe6e8213b63c5a04c42','[\"*\"]','2026-05-19 11:38:19',NULL,'2026-05-19 11:35:42','2026-05-19 11:38:19'),(72,'App\\Models\\User',13,'auth_token','6fc923e11fec285d322405064f3b37f422ddce289ace624e418f89e5c3a52c1f','[\"*\"]','2026-05-25 04:10:00',NULL,'2026-05-22 06:05:24','2026-05-25 04:10:00'),(102,'App\\Models\\User',14,'auth_token','3efa00350f4872ae51f82177f8622ebbd120b20f31313d75e2e1c4f0eb9412b3','[\"*\"]','2026-05-25 12:05:59',NULL,'2026-05-25 10:25:37','2026-05-25 12:05:59'),(103,'App\\Models\\User',11,'auth_token','96c5984bcf61a5fe28e0981cbd2d24ee5c37455fd1b7df4a06a9e8e8cb2958c5','[\"*\"]','2026-05-26 04:03:58',NULL,'2026-05-26 03:43:44','2026-05-26 04:03:58'),(104,'App\\Models\\User',11,'auth_token','56dea569367785bbf9e19149c932e3d76d86661d00621049249fbcbc3884b4fc','[\"*\"]','2026-05-26 04:21:45',NULL,'2026-05-26 04:21:38','2026-05-26 04:21:45'),(105,'App\\Models\\User',10,'auth_token','e8274f23c2deaf6947391a8b548993eeddfd33353ffcb31644cba082482b5d1c','[\"*\"]','2026-05-26 04:26:15',NULL,'2026-05-26 04:23:40','2026-05-26 04:26:15'),(106,'App\\Models\\User',11,'auth_token','72c04cac3c117463dce66a493192d41aa3a4e1262f4f0c0837bc1384c5414695','[\"*\"]','2026-05-26 04:29:38',NULL,'2026-05-26 04:29:31','2026-05-26 04:29:38'),(107,'App\\Models\\User',11,'auth_token','83ca11f2f2bf900cb4ae29621e8c90eadad1353076d8dfb4fbb8c240be3d1d8d','[\"*\"]','2026-05-26 04:36:21',NULL,'2026-05-26 04:36:14','2026-05-26 04:36:21'),(108,'App\\Models\\User',11,'auth_token','a025a7000225ef6ca1cbd0095355f15f764a4e491b6aac173955a92d89a63bf7','[\"*\"]','2026-05-26 04:40:14',NULL,'2026-05-26 04:40:07','2026-05-26 04:40:14'),(109,'App\\Models\\User',11,'auth_token','fe7fef32781ab95f293999ee31d05f27dfdff67347c852f2bfe6200ffa48d922','[\"*\"]','2026-05-26 04:59:57',NULL,'2026-05-26 04:59:49','2026-05-26 04:59:57'),(110,'App\\Models\\User',11,'auth_token','942c62284c61311d4684a1f625b00bb9bf2aeeaf97691a24bc201846ad95d6c3','[\"*\"]','2026-05-26 05:18:56',NULL,'2026-05-26 05:18:43','2026-05-26 05:18:56'),(111,'App\\Models\\User',10,'auth_token','834b34fc396747fa1604add2f01a51b4571ca0b86cd9f269082b5f3b52f1b195','[\"*\"]','2026-05-26 05:23:39',NULL,'2026-05-26 05:22:14','2026-05-26 05:23:39'),(112,'App\\Models\\User',13,'auth_token','545723012e9f51c34ffdbc24370077ed31b129e018799febb63d73b9a07ce834','[\"*\"]','2026-05-26 05:43:01',NULL,'2026-05-26 05:39:56','2026-05-26 05:43:01'),(113,'App\\Models\\User',11,'auth_token','a8af8b0ffb5253e46eb1c4c08ae318285717a22413ed582d6ac9ee2e64a35090','[\"*\"]','2026-05-26 05:57:13',NULL,'2026-05-26 05:57:04','2026-05-26 05:57:13'),(114,'App\\Models\\User',10,'auth_token','034ba2f8b5ae32fcb35b016adaffec0559e26863063d51730c91432f7821ef39','[\"*\"]','2026-05-26 06:22:44',NULL,'2026-05-26 06:20:03','2026-05-26 06:22:44'),(129,'App\\Models\\User',13,'auth_token','99a1f0af94b86a36027d6d25c97c1a8a8dba066a5d57c3c723d699e3941ce6fa','[\"*\"]',NULL,NULL,'2026-06-03 10:22:51','2026-06-03 10:22:51'),(130,'App\\Models\\User',13,'auth_token','099b2c3c510d186067fe69ce7b67ce52ed2b40cd6cf4386eb805d0f12b084b51','[\"*\"]',NULL,NULL,'2026-06-03 11:29:37','2026-06-03 11:29:37'),(131,'App\\Models\\User',13,'auth_token','21b729b2eea62d783e12708996838aec25ce01cb47f94cf7e3f5bd7ac9d2dd40','[\"*\"]',NULL,NULL,'2026-06-03 11:47:10','2026-06-03 11:47:10');
/*!40000 ALTER TABLE `personal_access_tokens` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sessions`
--

DROP TABLE IF EXISTS `sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sessions` (
  `id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` bigint unsigned DEFAULT NULL,
  `ip_address` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_agent` text COLLATE utf8mb4_unicode_ci,
  `payload` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `last_activity` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `sessions_user_id_index` (`user_id`),
  KEY `sessions_last_activity_index` (`last_activity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sessions`
--

LOCK TABLES `sessions` WRITE;
/*!40000 ALTER TABLE `sessions` DISABLE KEYS */;
INSERT INTO `sessions` VALUES ('k0xm6kkh0VPkqIWR3eUQvHI9DJ3a2EPLx9qU5rfP',NULL,'172.24.0.1','Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Mobile Safari/537.36','eyJfdG9rZW4iOiI5ZjQzTmtSWXRwY0lsN1BneE1kS1dsSlBYbXBkaUFPUktKMFVBb3VrIiwiX3ByZXZpb3VzIjp7InVybCI6Imh0dHA6XC9cLzEwLjIxNi45My4yMDQ6ODAwMCIsInJvdXRlIjpudWxsfSwiX2ZsYXNoIjp7Im9sZCI6W10sIm5ldyI6W119fQ==',1780377383);
/*!40000 ALTER TABLE `sessions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `slots`
--

DROP TABLE IF EXISTS `slots`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `slots` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `time` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'available',
  `booked_by` bigint unsigned DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `slots`
--

LOCK TABLES `slots` WRITE;
/*!40000 ALTER TABLE `slots` DISABLE KEYS */;
/*!40000 ALTER TABLE `slots` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sport_match_user`
--

DROP TABLE IF EXISTS `sport_match_user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sport_match_user` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `sport_match_id` bigint unsigned NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `sport_match_user_user_id_sport_match_id_unique` (`user_id`,`sport_match_id`),
  KEY `sport_match_user_sport_match_id_foreign` (`sport_match_id`),
  CONSTRAINT `sport_match_user_sport_match_id_foreign` FOREIGN KEY (`sport_match_id`) REFERENCES `sport_matches` (`id`) ON DELETE CASCADE,
  CONSTRAINT `sport_match_user_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=52 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sport_match_user`
--

LOCK TABLES `sport_match_user` WRITE;
/*!40000 ALTER TABLE `sport_match_user` DISABLE KEYS */;
INSERT INTO `sport_match_user` VALUES (19,10,9,NULL,NULL),(20,11,10,NULL,NULL),(21,12,9,NULL,NULL),(22,12,10,NULL,NULL),(23,12,11,NULL,NULL),(24,13,9,NULL,NULL),(25,13,11,NULL,NULL),(27,14,12,NULL,NULL),(28,10,13,NULL,NULL),(29,15,14,NULL,NULL),(30,11,13,NULL,NULL),(31,13,13,NULL,NULL),(34,11,15,NULL,NULL),(35,14,16,NULL,NULL),(36,10,16,NULL,NULL),(37,10,17,NULL,NULL),(38,10,18,NULL,NULL),(39,11,19,NULL,NULL),(40,13,20,NULL,NULL),(41,12,20,NULL,NULL),(42,10,21,NULL,NULL),(43,11,22,NULL,NULL),(44,13,23,NULL,NULL),(45,13,24,NULL,NULL),(47,14,24,NULL,NULL),(48,14,22,NULL,NULL),(49,10,24,NULL,NULL),(50,10,22,NULL,NULL),(51,13,22,NULL,NULL);
/*!40000 ALTER TABLE `sport_match_user` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sport_matches`
--

DROP TABLE IF EXISTS `sport_matches`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sport_matches` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `creator_id` bigint unsigned DEFAULT NULL,
  `sport_type` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `title` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `date_time` datetime NOT NULL,
  `location` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` enum('open','full') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'open',
  `latitude` decimal(10,7) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `available_slots` int NOT NULL,
  `max_slots` int unsigned NOT NULL DEFAULT '1',
  `skill_level` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `women_only` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `sport_matches_creator_id_foreign` (`creator_id`),
  KEY `sport_matches_sport_type_index` (`sport_type`),
  KEY `sport_matches_skill_level_index` (`skill_level`),
  KEY `sport_matches_date_time_index` (`date_time`),
  KEY `sport_matches_women_only_index` (`women_only`),
  KEY `sport_matches_cursor_idx` (`date_time`,`id`),
  CONSTRAINT `sport_matches_creator_id_foreign` FOREIGN KEY (`creator_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=25 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sport_matches`
--

LOCK TABLES `sport_matches` WRITE;
/*!40000 ALTER TABLE `sport_matches` DISABLE KEYS */;
INSERT INTO `sport_matches` VALUES (9,10,'Cricket','Pettabulls','2026-05-22 19:00:00','One4All','open',NULL,NULL,12,15,'Intermediate',0,'2026-05-19 11:54:09','2026-05-20 06:35:40'),(10,11,'Football','Friday evening match','2026-05-22 21:30:00','KGF','open',NULL,NULL,9,11,'Intermediate',0,'2026-05-20 04:16:15','2026-05-20 04:27:45'),(11,12,'Badminton','National Derby','2026-05-22 19:00:00','one4all','open',NULL,NULL,1,3,'Professional',1,'2026-05-20 04:53:51','2026-05-20 04:56:54'),(12,14,'Tennis','Giants Match','2026-05-21 07:00:00','Avenue park','open',NULL,NULL,2,3,'Advanced',0,'2026-05-20 08:47:34','2026-05-20 08:47:34'),(13,10,'Padel','Southern Derby','2026-05-21 16:00:00','CentralSquare','open',NULL,NULL,1,4,'Intermediate',0,'2026-05-20 08:55:13','2026-05-21 08:34:14'),(14,15,'Football','Women\'s power','2026-05-21 19:30:00','Central Park','open',NULL,NULL,13,14,'Intermediate',1,'2026-05-20 09:02:56','2026-05-21 11:58:46'),(15,11,'Football','Suiii','2026-05-21 16:00:00','Khel','open',NULL,NULL,12,13,'Intermediate',0,'2026-05-21 09:36:22','2026-05-21 09:36:22'),(16,14,'Cricket','kings match','2026-05-21 17:31:26','one4all','open',NULL,NULL,9,11,'Intermediate',0,'2026-05-21 10:02:23','2026-05-21 11:56:49'),(17,10,'Football','kings derby','2026-05-21 19:26:59','Khel','open',NULL,NULL,12,13,'Intermediate',0,'2026-05-21 11:57:35','2026-05-21 11:57:35'),(18,10,'Football','Friday evening','2026-05-29 19:00:00','Khel','open',NULL,NULL,11,12,'Intermediate',0,'2026-05-25 04:27:27','2026-05-25 04:27:27'),(19,11,'Cricket','Ball Kali','2026-05-29 19:00:00','one4all','open',NULL,NULL,14,15,'Intermediate',0,'2026-05-25 04:38:39','2026-05-25 04:38:39'),(20,13,'Badminton','Girls derby','2026-05-27 18:00:00','one4all','open',NULL,NULL,2,4,'Intermediate',1,'2026-05-25 04:47:09','2026-05-25 04:50:14'),(21,10,'Football','Evening Derby','2026-06-05 19:00:00','khel','open',NULL,NULL,13,14,'Intermediate',0,'2026-06-02 04:29:54','2026-06-02 04:29:54'),(22,11,'Cricket','Bulls vd Petta','2026-06-04 19:00:00','one4all','open',NULL,NULL,12,16,'Intermediate',0,'2026-06-02 04:31:36','2026-06-03 10:07:13'),(23,13,'Badminton','women\'s derby','2026-06-06 18:30:00','cetralaquare','open',NULL,NULL,3,4,'Intermediate',1,'2026-06-02 04:33:42','2026-06-02 04:33:42'),(24,13,'Badminton','National Derby','2026-06-03 19:00:00','one4all','open',NULL,NULL,5,8,'Intermediate',0,'2026-06-02 09:18:24','2026-06-03 09:56:07');
/*!40000 ALTER TABLE `sport_matches` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `username` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `gender` enum('male','female','other') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `theme_preference` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'system',
  `phone_number` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `hide_phone` tinyint(1) NOT NULL DEFAULT '0',
  `email` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email_verified_at` timestamp NULL DEFAULT NULL,
  `password` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `profile_picture` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `remember_token` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `profile_photo` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `users_username_unique` (`username`),
  UNIQUE KEY `users_phone_number_unique` (`phone_number`),
  UNIQUE KEY `users_email_unique` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (10,'Ajith','Ajith','male','system',NULL,0,NULL,NULL,'$2y$12$2pFuApdsL2m3t758mdhjxeLlNyGkcgulJQ7OFL.GKoM8Pxft5lUk6','profile-images/UBUCqyP8EWS9N8IbLHGN2vRXVysn82ngoYwGlzjq.jpg',NULL,'2026-05-19 11:46:28','2026-05-20 03:58:32','profile-images/UBUCqyP8EWS9N8IbLHGN2vRXVysn82ngoYwGlzjq.jpg'),(11,'Devan','Devan','male','system',NULL,0,NULL,NULL,'$2y$12$86cplrBZ9mM9hkJ1QBImd.0tiRUgKOceXc9UZFB3uCxxQRbWdKjLG','profile-images/rGJ23KL3WK8ZqL9MTvQqYdM3sBKPsqHdlZnJY9Gq.jpg',NULL,'2026-05-20 04:01:51','2026-05-20 04:19:26','profile-images/rGJ23KL3WK8ZqL9MTvQqYdM3sBKPsqHdlZnJY9Gq.jpg'),(12,'pv sindhu','pvsindhu','female','elegantLavender',NULL,0,NULL,NULL,'$2y$12$j2My.0Iyq.va9UUa.N09/eJa0Cop0ktC86TErwXNDHGRGeWka6Q7i','profile-images/7HSzcvAfWzAwkQBk88G6eqwKIIprmNdswTzAKF9m.jpg',NULL,'2026-05-20 04:26:43','2026-06-02 04:35:38','profile-images/7HSzcvAfWzAwkQBk88G6eqwKIIprmNdswTzAKF9m.jpg'),(13,'Saina','saina','female','elegantLavender',NULL,1,NULL,NULL,'$2y$12$j6FHXp24PyIH2pl8b964aOlFz6TxyCG7bC8jJUkhAb5RZqqWSFB3i','profile-images/Vp90qb7zZlnT9MFBPaU1f8keHuWQcYFBGbF3mESn.jpg',NULL,'2026-05-20 04:51:04','2026-06-04 05:29:34','profile-images/Vp90qb7zZlnT9MFBPaU1f8keHuWQcYFBGbF3mESn.jpg'),(14,'Davi','Davi','male','system',NULL,1,NULL,NULL,'$2y$12$SQw2FkSF0hIcYQvi2fgIruJFqU0PoLL7Xed5qHOiViQ6miUy/YXCq',NULL,NULL,'2026-05-20 08:43:15','2026-05-22 05:09:40',NULL),(15,'ptusha','ptusha','female','system',NULL,0,NULL,NULL,'$2y$12$BUilIxnGaggATVlvKINjBOZYjv5n.aFORzZ2xZWZqn9apxrOBfh4C',NULL,NULL,'2026-05-20 09:00:16','2026-05-20 09:00:16',NULL);
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-06-04  5:56:16
