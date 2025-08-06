# About the project 
In this project, I conducted comprehensive data cleaning and exploratory data analysis (EDA) on a dataset of company layoffs. The objective was to standardize, clean, and extract meaningful insights from the data.

## Key Steps Taken:

### Data Cleaning & Preprocessing:
Removed duplicate records using SQL window functions.
Standardized company names, industries, and locations by trimming extra spaces and correcting inconsistencies.
Converted date fields into proper DATE format for accurate analysis.
Replaced missing values in the industry column by referencing companies with similar attributes.
Eliminated records with insufficient data (where both total_laid_off and percentage_laid_off were missing).
Created a new column total_population by estimating the total workforce based on layoff percentages.

### Exploratory Data Analysis (EDA):
Trends Over Time: Aggregated layoffs per month and year to analyze macroeconomic impacts.
Industry Analysis: Identified which industries were most affected by layoffs.
Company-Wise Insights: Ranked companies based on total layoffs per year.
Country-Wise Comparison: Determined the most impacted countries based on total layoffs.
Startup Lifecycle Analysis: Evaluated layoffs by company funding stages (e.g., Series A, Post-IPO).
Rolling Sum Analysis: Implemented a cumulative sum approach to track trends over time.

### Insights Derived:
Industries like Tech, Real Estate, and Media saw the highest layoffs.
Companies like Atlassian, SiriusXM, and Loft had significant layoffs in early 2023.
Layoffs peaked in certain months, revealing seasonal or economic trends.
Startups in later funding stages (Post-IPO) had higher layoffs, indicating potential financial struggles.
By performing data cleaning and analysis, this project demonstrates my ability to handle messy real-world data, implement SQL transformations, and generate data-driven insights.
