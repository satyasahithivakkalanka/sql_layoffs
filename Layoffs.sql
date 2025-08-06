-- =======================================================
--  DATA CLEANING & EXPLORATORY DATA ANALYSIS (EDA)
--  Dataset: world_layoffs
--  Objective: Clean, Standardize, and Analyze Layoff Data
-- =======================================================

USE world_layoffs;

-- ======================================
-- 1. DATA PREPROCESSING SETUP
-- ======================================

-- Create a new table for preprocessing
DROP TABLE IF EXISTS layoffs_df; 
CREATE TABLE layoffs_df LIKE layoffs;

INSERT INTO layoffs_df
SELECT * FROM layoffs;

SELECT * FROM layoffs_df; -- Verify data import

-- ======================================
-- 2. REMOVING DUPLICATES
-- ======================================

-- Identify duplicate rows using row_number() function
WITH duplicate_cte AS (
    SELECT *, 
           ROW_NUMBER() OVER (PARTITION BY company, location, industry, total_laid_off, 
                                       percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
    FROM layoffs_df
)
SELECT * FROM duplicate_cte WHERE row_num > 1; -- Identifies duplicate records

-- Since MySQL does not support direct row deletion using window functions, 
-- we create a new table to store cleaned data.

DROP TABLE IF EXISTS layoffs_df2;
CREATE TABLE layoffs_df2 (
    company TEXT,
    location TEXT,
    industry TEXT,
    total_laid_off INT DEFAULT NULL,
    percentage_laid_off TEXT,
    `date` TEXT,
    stage TEXT,
    country TEXT,
    funds_raised_millions INT DEFAULT NULL,
    row_num INT
);

-- Insert unique records
INSERT INTO layoffs_df2
SELECT *, 
       ROW_NUMBER() OVER (PARTITION BY company, location, industry, total_laid_off, 
                                      percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_df;

-- Delete duplicate records
SET SQL_SAFE_UPDATES = 0;
DELETE FROM layoffs_df2 WHERE row_num > 1;
SET SQL_SAFE_UPDATES = 1;

-- ======================================
-- 3. STANDARDIZING THE DATA
-- ======================================

-- Standardizing company names (Removing extra spaces)
SET SQL_SAFE_UPDATES = 0;
UPDATE layoffs_df2 SET company = TRIM(company);
SET SQL_SAFE_UPDATES = 1;

-- Standardizing industry names (Example: All variations of "crypto" to "Crypto")
SET SQL_SAFE_UPDATES = 0;
UPDATE layoffs_df2 SET industry = 'Crypto' WHERE industry LIKE 'crypto%';
SET SQL_SAFE_UPDATES = 1;

-- Standardizing location names with special characters
SELECT location FROM layoffs_df2 WHERE location REGEXP '[À-ÖØ-öø-ÿ]';

SET SQL_SAFE_UPDATES = 0;
UPDATE layoffs_df2
SET location = 
    CASE 
        WHEN location LIKE 'Florian%' THEN 'Florianopolis'
        WHEN location LIKE '%sseldorf' THEN 'Dusseldorf'
        WHEN location LIKE 'malm%' THEN 'Malmo'
    END
WHERE location LIKE 'Florian%' 
   OR location LIKE '%sseldorf' 
   OR location LIKE 'malm%';
SET SQL_SAFE_UPDATES = 1;

-- Standardizing country names
SET SQL_SAFE_UPDATES = 0;
UPDATE layoffs_df2 
SET country = 'United States' 
WHERE country LIKE 'United States%';
SET SQL_SAFE_UPDATES = 1;

-- ======================================
-- 4. CONVERTING DATE FORMAT
-- ======================================

-- Convert date column to proper DATE format
SET SQL_SAFE_UPDATES = 0;
UPDATE layoffs_df2 SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');
SET SQL_SAFE_UPDATES = 1;

ALTER TABLE layoffs_df2 MODIFY COLUMN `date` DATE;

-- ======================================
-- 5. HANDLING NULL OR BLANK VALUES
-- ======================================

-- Checking for null or blank industry values
SELECT * FROM layoffs_df2 WHERE industry IS NULL OR industry = '';

-- Filling missing industry values by matching company & location
UPDATE layoffs_df2 t1
JOIN layoffs_df2 t2
ON t1.company = t2.company AND t1.location = t2.location
SET t1.industry = t2.industry
WHERE t1.industry IS NULL AND t2.industry IS NOT NULL;

-- Removing records where both `total_laid_off` and `percentage_laid_off` are null
DELETE FROM layoffs_df2 WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

-- Dropping unnecessary row_num column
ALTER TABLE layoffs_df2 DROP COLUMN row_num;

-- ======================================
-- 6. FEATURE ENGINEERING: ESTIMATING TOTAL WORKFORCE
-- ======================================

-- Adding a new column to estimate total workforce
ALTER TABLE layoffs_df2 ADD COLUMN total_population INT;

UPDATE layoffs_df2
SET total_population = (total_laid_off / NULLIF(percentage_laid_off, 0)) * 100
WHERE percentage_laid_off IS NOT NULL 
      AND percentage_laid_off <> '' 
      AND percentage_laid_off <> 0;

-- ======================================
-- 7. EXPLORATORY DATA ANALYSIS (EDA)
-- ======================================

-- Analyzing layoffs by company
SELECT company, SUM(total_laid_off) AS total_laid_off
FROM layoffs_df2
GROUP BY company
ORDER BY total_laid_off DESC;

-- Identifying earliest and latest layoff records
SELECT MIN(date) AS earliest_layoff, MAX(date) AS latest_layoff FROM layoffs_df2;

-- Layoffs by industry
SELECT industry, SUM(total_laid_off) AS total_laid_off
FROM layoffs_df2
GROUP BY industry
ORDER BY total_laid_off DESC;

-- Layoffs by country
SELECT country, SUM(total_laid_off) AS total_laid_off
FROM layoffs_df2
GROUP BY country
ORDER BY total_laid_off DESC;

-- Layoffs by startup stage
SELECT stage, SUM(total_laid_off) AS total_laid_off
FROM layoffs_df2
GROUP BY stage
ORDER BY total_laid_off DESC;

-- Monthly layoffs trend
SELECT YEAR(`date`) AS year, MONTH(`date`) AS month, SUM(total_laid_off) AS total_laid_off
FROM layoffs_df2
GROUP BY year, month
ORDER BY year, month ASC;

-- Cumulative layoffs over time
WITH rolling_total AS (
    SELECT SUBSTRING(`date`, 1, 7) AS `month`, SUM(total_laid_off) AS total_laid_sum
    FROM layoffs_df2
    WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
    GROUP BY `month`
    ORDER BY `month` ASC 
)
SELECT `month`, 
       SUM(total_laid_sum) OVER(ORDER BY `month`) AS rolling_sum, 
       total_laid_sum
FROM rolling_total;

-- Identifying top companies with the most layoffs per year
WITH company_year AS (
    SELECT company, YEAR(`date`) AS year, SUM(total_laid_off) AS total_laid_off
    FROM layoffs_df2
    WHERE YEAR(`date`) IS NOT NULL
    GROUP BY company, year
), company_rank AS (
    SELECT *, DENSE_RANK() OVER(PARTITION BY year ORDER BY total_laid_off DESC) AS `rank`
    FROM company_year
)
SELECT * FROM company_rank
WHERE `rank` <= 5
ORDER BY year DESC, `rank` ASC;
