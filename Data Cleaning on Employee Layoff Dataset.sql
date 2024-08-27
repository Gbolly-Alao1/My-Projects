-- DATA CLEANING PROJECT ON LAYOFFS DATASET
-- During this project, we're gonna work on the following:
-- 1. Remove Duplicates
-- 2. Standardize the data
-- 3. Handling Null and Blank Values
-- 4. Remove any unwanted column(s)

SELECT * FROM layoffs;

-- We will create another table for staging which will contain the exact information from our original table

CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT layoffs_staging
SELECT * FROM layoffs;

SELECT * FROM layoffs_staging;

-- First, we identify any duplicates in our dataset
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, 
percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, 
percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT * FROM duplicate_cte
WHERE row_num > 1;

-- It would have been much easier to delete duplicates directly but we can't do that in MySQL.
-- An alternative approach we can take is to create another table having the extra row (row_num) and deleting where the row = 2
-- because that indicates the duplicates

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, 
percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- Now, we can delete the duplicates from the new layoffs table we just created

DELETE FROM layoffs_staging2
WHERE row_num > 1
;

SELECT * FROM layoffs_staging2;

-- Standardizing Data

-- It's noticed that some of the companies have unnecessary white spaces before them, so we can trim those spaces off
SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

-- It is noticed that there are similar industries (Crypto, CryptoCurrency and Crypto Currency)
-- with distinct names and this shouldn't be so

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

-- We can set every one of these industries to just be named 'Crypto'
UPDATE layoffs_staging2
SET industry = 'Crypto' WHERE industry LIKE 'Crypto%';

SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;
-- An issue was observed with the country column. There were two distinct values for the United States
-- with one of the values having full-stop at the end when it's the same country. So, we'll need to fix this

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- It would be best to convert the 'date' column to a date datatype incase we would like to do time series analysis later
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- Handling Null And Blank Values
SELECT *
FROM layoffs_staging2 WHERE total_laid_off IS NULL;

-- Looking at the Airbnb rows
SELECT * FROM layoffs_staging2
WHERE company = 'Airbnb';

SELECT * 
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
WHERE t1.industry IS NULL 
AND t2.industry IS NOT NULL;

UPDATE layoffs_staging2
SET industry = NULL WHERE industry = '';

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- We will then proceed to drop rows that have both null total_laid_off and percent_laid_off as they are practically
-- useless to our analysis
DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

-- Removing unwanted column (row_num)
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

SELECT *
FROM layoffs_staging2;

