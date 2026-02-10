-- Space Scraper Database Schema for MySQL

-- Create the database (optional - uncomment if needed)
-- CREATE DATABASE IF NOT EXISTS space_scraper CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- USE space_scraper;

-- Main content table
CREATE TABLE IF NOT EXISTS space_content (
  id INT AUTO_INCREMENT PRIMARY KEY,
  url VARCHAR(2048) NOT NULL,
  site_name VARCHAR(255),
  category VARCHAR(100),
  collection_timestamp DATETIME NOT NULL,
  title TEXT,
  description TEXT,
  meta_tags JSON,
  keywords JSON,
  content_hash CHAR(64) NOT NULL,
  content_length INT,
  text_preview TEXT,
  local_links_count INT DEFAULT 0,
  local_links JSON,
  status_code INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_url (url(255)),
  INDEX idx_hash (content_hash),
  INDEX idx_timestamp (collection_timestamp),
  INDEX idx_category (category),
  INDEX idx_site_name (site_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- View for latest content per URL
CREATE OR REPLACE VIEW latest_content AS
SELECT sc.*
FROM space_content sc
INNER JOIN (
  SELECT url, MAX(collection_timestamp) as max_timestamp
  FROM space_content
  GROUP BY url
) latest ON sc.url = latest.url AND sc.collection_timestamp = latest.max_timestamp;

-- Table for tracking content changes
CREATE TABLE IF NOT EXISTS content_changes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  url VARCHAR(2048) NOT NULL,
  previous_hash CHAR(64),
  new_hash CHAR(64) NOT NULL,
  change_detected_at DATETIME NOT NULL,
  change_type VARCHAR(50),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_changes_url (url(255)),
  INDEX idx_changes_date (change_detected_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table for storing site statistics
CREATE TABLE IF NOT EXISTS site_statistics (
  id INT AUTO_INCREMENT PRIMARY KEY,
  site_name VARCHAR(255) NOT NULL,
  category VARCHAR(100),
  total_scrapes INT DEFAULT 0,
  last_scrape DATETIME,
  total_changes INT DEFAULT 0,
  average_content_length INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY unique_site (site_name),
  INDEX idx_category (category)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Stored procedure to update statistics
DELIMITER //
CREATE PROCEDURE IF NOT EXISTS update_site_statistics()
BEGIN
  INSERT INTO site_statistics (site_name, category, total_scrapes, last_scrape, average_content_length)
  SELECT
    site_name,
    category,
    COUNT(*) as total_scrapes,
    MAX(collection_timestamp) as last_scrape,
    AVG(content_length) as average_content_length
  FROM space_content
  GROUP BY site_name, category
  ON DUPLICATE KEY UPDATE
    total_scrapes = VALUES(total_scrapes),
    last_scrape = VALUES(last_scrape),
    average_content_length = VALUES(average_content_length),
    updated_at = CURRENT_TIMESTAMP;
END //
DELIMITER ;
