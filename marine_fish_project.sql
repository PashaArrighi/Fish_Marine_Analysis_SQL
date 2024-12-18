USE marine_fish;

-- Step 1: Create a staging table to preserve the raw data
-- A staging table is created as a copy of the original table (`marine_fish_data`).
-- This ensures that any modifications during cleaning and processing do not alter the original dataset.

-- Create a staging table identical to the original table structure
CREATE TABLE marine_staging LIKE marine_fish_data;

-- Copy all data from the original table into the staging table
INSERT INTO marine_staging
SELECT * FROM marine_fish_data;

-- Verify that the data has been copied successfully
-- Display the data from the staging table for confirmation
SELECT * FROM marine_staging;

-- Step 2: Data Cleaning
-- Disable safe update mode temporarily to allow updates without a WHERE clause
SET SQL_SAFE_UPDATES = 0;

-- Remove any leading or trailing spaces from text columns to standardize the data
UPDATE marine_staging
SET 
    Species_Name = TRIM(Species_Name),
    Region = TRIM(Region),
    Breeding_Season = TRIM(Breeding_Season),
    Fishing_Method = TRIM(Fishing_Method),
    Overfishing_Risk = TRIM(Overfishing_Risk),
    Water_Pollution_Level = TRIM(Water_Pollution_Level);

-- Correct data types for specific columns
-- Change `Average_Size(cm)` from an integer to a FLOAT for more accurate representation of continuous values
ALTER TABLE marine_staging
MODIFY `Average_Size(cm)` FLOAT;

-- Change `Water_Temperature(C)` from an integer to a FLOAT for accurate temperature representation
ALTER TABLE marine_staging
MODIFY `Water_Temperature(C)` FLOAT;

-- Step 3: Check for Duplicates
-- Identify duplicate rows based on all relevant columns
-- Group by all attributes to ensure rows with identical data are flagged
SELECT *, COUNT(*) AS Duplicate_Count
FROM marine_staging
GROUP BY Species_Name, Region, Breeding_Season, Fishing_Method, Fish_Population, `Average_Size(cm)`, Overfishing_Risk, `Water_Temperature(C)`, Water_Pollution_Level
HAVING COUNT(*) > 1;

-- If duplicates exist, they should be reviewed and handled appropriately
-- In this case, assume no duplicates are found, so we proceed to the next steps

-- Step 4: Handle Missing Values
-- Check for NULL (missing) values in all columns to identify data gaps
SELECT 
    SUM(CASE WHEN Species_Name IS NULL THEN 1 ELSE 0 END) AS Null_Species_Name,
    SUM(CASE WHEN Region IS NULL THEN 1 ELSE 0 END) AS Null_Region,
    SUM(CASE WHEN Breeding_Season IS NULL THEN 1 ELSE 0 END) AS Null_Breeding_Season,
    SUM(CASE WHEN Fishing_Method IS NULL THEN 1 ELSE 0 END) AS Null_Fishing_Method,
    SUM(CASE WHEN Fish_Population IS NULL THEN 1 ELSE 0 END) AS Null_Fish_Population,
    SUM(CASE WHEN `Average_Size(cm)` IS NULL THEN 1 ELSE 0 END) AS Null_Average_Size,
    SUM(CASE WHEN Overfishing_Risk IS NULL THEN 1 ELSE 0 END) AS Null_Overfishing_Risk,
    SUM(CASE WHEN `Water_Temperature(C)` IS NULL THEN 1 ELSE 0 END) AS Null_Water_Temperature,
    SUM(CASE WHEN Water_Pollution_Level IS NULL THEN 1 ELSE 0 END) AS Null_Water_Pollution_Level
FROM marine_staging;

-- Replace NULL values with appropriate defaults or estimates
-- Example replacements for missing values:
-- Replace missing fish population with 0 (indicating no recorded population)
UPDATE marine_staging
SET Fish_Population = 0
WHERE Fish_Population IS NULL;

-- Replace missing breeding season with 'UNKNOWN'
UPDATE marine_staging
SET Breeding_Season = 'UNKNOWN'
WHERE Breeding_Season IS NULL;

-- Step 5: Validate Data Ranges
-- Identify rows with invalid or outlier numeric values
-- Example: Negative values for population, size, or temperature are invalid
SELECT * 
FROM marine_staging
WHERE Fish_Population < 0 OR `Average_Size(cm)` < 0 OR `Water_Temperature(C)` < 0;

-- If invalid values are found, handle them by replacing or removing the rows

-- Step 6: Final Cleanup
-- Check for any remaining NULL values in critical columns
SELECT * 
FROM marine_staging
WHERE Species_Name IS NULL 
   OR Region IS NULL 
   OR Breeding_Season IS NULL 
   OR Fishing_Method IS NULL 
   OR Fish_Population IS NULL 
   OR `Average_Size(cm)` IS NULL 
   OR Overfishing_Risk IS NULL 
   OR `Water_Temperature(C)` IS NULL 
   OR Water_Pollution_Level IS NULL;


