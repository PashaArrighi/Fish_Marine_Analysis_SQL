USE marine_fish;

-- Step 1: Create a staging table to preserve the raw data
-- Create a staging table as a replica of the original table (`marine_fish_data`).
-- This ensures that the original data remains unaltered during cleaning and analysis.

CREATE TABLE marine_staging LIKE marine_fish_data;

-- Copy all the data from the original table into the staging table
-- This step sets up a working copy of the data for further processing.
INSERT INTO marine_staging
SELECT * FROM marine_fish_data;

-- Verify that the data has been copied successfully
-- Preview the contents of the staging table for confirmation.
SELECT * FROM marine_staging;

-- Step 2: Data Cleaning
-- Temporarily disable the safe update mode to allow updates without requiring a WHERE clause.
SET SQL_SAFE_UPDATES = 0;

-- Remove leading and trailing spaces from text columns
-- This standardizes textual fields to improve data consistency.
UPDATE marine_staging
SET 
    Species_Name = TRIM(Species_Name),
    Region = TRIM(Region),
    Breeding_Season = TRIM(Breeding_Season),
    Fishing_Method = TRIM(Fishing_Method),
    Overfishing_Risk = TRIM(Overfishing_Risk),
    Water_Pollution_Level = TRIM(Water_Pollution_Level);

-- Adjust data types to improve accuracy and ensure proper data representation.
-- Convert `Average_Size(cm)` to FLOAT for more precise decimal values.
ALTER TABLE marine_staging
MODIFY `Average_Size(cm)` FLOAT;

-- Convert `Water_Temperature(C)` to FLOAT to represent decimal temperature values.
ALTER TABLE marine_staging
MODIFY `Water_Temperature(C)` FLOAT;

-- Step 3: Check for Duplicates
-- Identify duplicate rows by grouping data based on all relevant columns.
-- Duplicate rows will have a COUNT greater than 1.
SELECT *, COUNT(*) AS Duplicate_Count
FROM marine_staging
GROUP BY Species_Name, Region, Breeding_Season, Fishing_Method, Fish_Population, `Average_Size(cm)`, Overfishing_Risk, `Water_Temperature(C)`, Water_Pollution_Level
HAVING COUNT(*) > 1;

-- Review and handle duplicates if any are detected. If no duplicates exist, proceed to the next steps.

-- Step 4: Handle Missing Values
-- Check for missing (NULL) values in all columns to identify data gaps.
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

-- Replace NULL values with appropriate default values or estimates.
-- Set missing fish population to 0 (indicating no recorded data for the population).
UPDATE marine_staging
SET Fish_Population = 0
WHERE Fish_Population IS NULL;

-- Set missing breeding season to 'UNKNOWN' to retain the record while addressing the missing data.
UPDATE marine_staging
SET Breeding_Season = 'UNKNOWN'
WHERE Breeding_Season IS NULL;

-- Step 5: Validate Data Ranges
-- Identify invalid numeric values such as negative values for population, size, or temperature.
SELECT * 
FROM marine_staging
WHERE Fish_Population < 0 OR `Average_Size(cm)` < 0 OR `Water_Temperature(C)` < 0;

-- Review and address invalid values by replacing or removing the affected rows.

-- Step 6: Final Cleanup
-- Check if there are any remaining NULL values in critical columns.
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

-- Data Analysis
-- Step 1: Fish Population Analysis
-- Calculate the total and average fish population for each region to identify the most populated areas.
SELECT 
    Region,
    SUM(Fish_Population) AS Total_Population,
    AVG(Fish_Population) AS Average_Population
FROM marine_staging
GROUP BY Region
ORDER BY Total_Population DESC;

-- Step 2: Overfishing Risk Trends
-- Analyze regions with the highest percentage of species at risk of overfishing.
SELECT 
    Region,
    COUNT(*) AS Total_Species,
    SUM(CASE WHEN Overfishing_Risk = 'YES' THEN 1 ELSE 0 END) AS At_Risk_Species,
    ROUND((SUM(CASE WHEN Overfishing_Risk = 'YES' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS Overfishing_Percentage
FROM marine_staging
GROUP BY Region
ORDER BY Overfishing_Percentage DESC;

-- Step 3: Pollution Levels and Fish Population
-- Examine the relationship between water pollution levels and fish population size.
SELECT 
    Water_Pollution_Level,
    AVG(Fish_Population) AS Average_Population,
    AVG(`Average_Size(cm)`) AS Average_Fish_Size
FROM marine_staging
GROUP BY Water_Pollution_Level
ORDER BY Average_Population DESC;

-- Step 4: Seasonal Breeding Patterns
-- Identify the most common breeding seasons across all species.
SELECT 
    Breeding_Season,
    COUNT(*) AS Species_Count
FROM marine_staging
GROUP BY Breeding_Season
ORDER BY Species_Count DESC;

-- Step 5: Correlation Between Temperature and Fish Population
-- Analyze the relationship between water temperature and fish population across regions.
SELECT 
    Region,
    AVG(Fish_Population) AS Average_Population,
    AVG(`Water_Temperature(C)`) AS Average_Temperature
FROM marine_staging
GROUP BY Region
ORDER BY Average_Temperature DESC;
