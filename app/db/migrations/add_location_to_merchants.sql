-- Add location fields to merchants table
ALTER TABLE merchants
ADD COLUMN latitude FLOAT NOT NULL DEFAULT 0,
ADD COLUMN longitude FLOAT NOT NULL DEFAULT 0,
ADD COLUMN address VARCHAR(512),
ADD COLUMN city VARCHAR(100),
ADD COLUMN country VARCHAR(100),
ADD COLUMN phone VARCHAR(20),
ADD COLUMN website VARCHAR(512);

-- Add spatial index for location-based queries
CREATE INDEX idx_merchant_location ON merchants (latitude, longitude); 