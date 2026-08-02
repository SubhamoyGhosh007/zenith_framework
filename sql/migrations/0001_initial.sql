-- Migration: 0001_initial
-- Applied on M0 Scaffold initialization

CREATE TABLE IF NOT EXISTS users (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  license VARCHAR(48) UNIQUE NOT NULL,
  steam VARCHAR(32),
  discord VARCHAR(32),
  fivem VARCHAR(48),
  ip VARCHAR(45),
  last_seen DATETIME,
  banned BOOLEAN DEFAULT FALSE,
  ban_until DATETIME,
  ban_reason TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_license (license)
);

CREATE TABLE IF NOT EXISTS characters (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  slot TINYINT NOT NULL,
  first_name VARCHAR(32),
  last_name VARCHAR(32),
  dob DATE,
  gender VARCHAR(16),
  nationality VARCHAR(32),
  height TINYINT,
  skin_json JSON NOT NULL,
  metadata JSON NOT NULL,
  last_pos JSON DEFAULT NULL,
  json_money JSON NOT NULL,
  json_job JSON NOT NULL,
  is_dead BOOLEAN DEFAULT FALSE,
  deleted_at TIMESTAMP NULL,
  UNIQUE KEY uk_user_slot (user_id, slot),
  INDEX idx_user (user_id),
  CONSTRAINT fk_char_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS items (
  name VARCHAR(48) PRIMARY KEY,
  label VARCHAR(64),
  weight SMALLINT DEFAULT 0,
  stack BOOLEAN DEFAULT TRUE,
  close_on_use BOOLEAN DEFAULT TRUE,
  category VARCHAR(24),
  image VARCHAR(128),
  `unique` BOOLEAN DEFAULT FALSE,
  description TEXT
);

CREATE TABLE IF NOT EXISTS inventory_slots (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  owner_kind VARCHAR(16) NOT NULL,
  owner_id VARCHAR(64) NOT NULL,
  slot SMALLINT NOT NULL,
  item_name VARCHAR(48) NOT NULL,
  count INT NOT NULL DEFAULT 1,
  metadata JSON NOT NULL,
  UNIQUE KEY uk_owner_slot (owner_kind, owner_id, slot),
  INDEX idx_item (item_name),
  CONSTRAINT fk_inv_item FOREIGN KEY (item_name) REFERENCES items(name)
);

CREATE TABLE IF NOT EXISTS drops (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  pos JSON NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  despawn_at DATETIME,
  INDEX idx_pos ( (CAST(pos->>'$.x' AS DOUBLE)) )
);

CREATE TABLE IF NOT EXISTS jobs (
  name VARCHAR(48) PRIMARY KEY,
  label VARCHAR(64),
  type VARCHAR(16) DEFAULT 'job',
  default_duty BOOLEAN DEFAULT FALSE,
  salary INT DEFAULT 0
);

CREATE TABLE IF NOT EXISTS job_grades (
  job_name VARCHAR(48),
  grade TINYINT,
  label VARCHAR(64),
  salary INT,
  is_owner BOOLEAN DEFAULT FALSE,
  perms JSON NOT NULL,
  PRIMARY KEY (job_name, grade),
  CONSTRAINT fk_grades_job FOREIGN KEY (job_name) REFERENCES jobs(name) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS job_members (
  character_id BIGINT PRIMARY KEY,
  job_name VARCHAR(48),
  grade TINYINT,
  is_duty BOOLEAN DEFAULT FALSE,
  UNIQUE KEY uk_char_job (character_id, job_name),
  CONSTRAINT fk_members_char FOREIGN KEY (character_id) REFERENCES characters(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS money_ledger (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  character_id BIGINT NOT NULL,
  kind VARCHAR(16) NOT NULL,
  amount INT NOT NULL,
  balance_after INT NOT NULL,
  reason VARCHAR(48),
  src_id VARCHAR(64),
  dest_id VARCHAR(64),
  metadata JSON NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_char_time (character_id, created_at),
  CONSTRAINT fk_ledger_char FOREIGN KEY (character_id) REFERENCES characters(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS houses (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  label VARCHAR(64),
  shell VARCHAR(48),
  pos JSON,
  price INT,
  stash_slots SMALLINT DEFAULT 50,
  ward_slots SMALLINT DEFAULT 30
);

CREATE TABLE IF NOT EXISTS house_owners (
  house_id BIGINT PRIMARY KEY,
  character_id BIGINT,
  owned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  rent_until DATE NULL,
  keys JSON NOT NULL,
  CONSTRAINT fk_owners_house FOREIGN KEY (house_id) REFERENCES houses(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS user_groups (
  license VARCHAR(48) NOT NULL,
  group_name VARCHAR(32) NOT NULL,
  granted_by VARCHAR(48),
  granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (license, group_name)
);

CREATE TABLE IF NOT EXISTS admin_logs (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  admin_license VARCHAR(48),
  target_license VARCHAR(48),
  action VARCHAR(32),
  reason TEXT,
  evidence_url VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
