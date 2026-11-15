# E-Pharmacy Data Quality, Pricing & Analytics

## 1. Project Overview

This project focuses on improving medicine data quality, standardising product information, comparing medicine prices across datasets and identifying potential pricing anomalies.

The project uses MySQL for data processing, data validation and analytical queries, with Tableau for interactive dashboard development.

## 2. Project Objectives

- Clean and standardise medicine product information.
- Identify missing, invalid and duplicate records.
- Compare medicine records across multiple data sources.
- Analyse price differences between matching medicines.
- Identify unusual price and pack-size patterns.
- Present key findings through interactive Tableau dashboards.

## 3. Datasets

The project uses three publicly available medicine datasets from Kaggle:

1. A-Z Medicine Dataset of India
2. 250K Medicines Dataset
3. Indian Medicine Data

The datasets provide medicine-related information such as product names, manufacturers, prices, compositions and pack sizes.

## 4. Tools & Technologies

- MySQL 8.0
- MySQL Workbench
- Tableau
- Microsoft Excel (data inspection and preparation)

## 5. Project Workflow

### Step 1: Data Import
Imported the source datasets into MySQL and maintained separate raw data tables.

### Step 2: Data Profiling
Examined source records to understand data structure, completeness and quality issues.

### Step 3: Data Cleaning & Standardisation
Worked on standardising medicine names and manufacturer information and identifying data-quality issues.

### Step 4: Data Quality Validation
Designed validation checks to identify missing values, invalid prices, duplicate records and other data-quality concerns.

### Step 5: Cross-Source Matching
Compared medicine records across datasets using standardised product and manufacturer information.

### Step 6: Pricing Analysis
Analysed price differences between matched medicine records and identified potential pricing review cases.

### Step 7: Tableau Dashboard Development
Created two Tableau dashboards to present analytical results.

## 6. Key Dashboard Metrics

| Metric | Result |
|---|---:|
| Clean Medicine Records | 253,968 |
| 250K Match Rate | 88.93% |
| Price Gap Review | 5,585 |
| Average Absolute Price Gap | 35.05% |
| Price-Pack Anomalies | 54 |

## 7. Tableau Dashboards

### E-Pharmacy Executive Dashboard

Presents key performance indicators and analytical charts covering medicine data quality, matching results and pricing analysis.

### E-Pharmacy Methodology & Definitions

Explains the analytical methodology, metric definitions and interpretation of the results.

## 8. Key Analytical Outcomes

- Established a cleaned medicine dataset containing 253,968 records.
- Achieved an 88.93% match rate against the 250K medicine dataset.
- Identified 5,585 price-gap cases requiring review.
- Calculated an average absolute price gap of 35.05%.
- Identified 54 price-pack anomaly groups for further investigation.

**Note:** Price gaps and anomalies are analytical review indicators, not proof of incorrect pricing or actual market-price violations.

## 9. Project Structure

- `SQL/` – SQL scripts for data processing and analysis.
- `Tableau/` – Tableau workbook.
- `Screenshots/` – Dashboard screenshots.

## 10. Skills Demonstrated

- MySQL and SQL
- Data Cleaning and Validation
- Data Profiling
- Data Standardisation
- Data Matching and Reconciliation
- Pricing Analysis
- Data Quality Assessment
- Tableau Dashboard Development
- Analytical Reporting

## 11. Conclusion

This project demonstrates how SQL and business intelligence tools can be used to transform multiple raw medicine datasets into structured analytical information.

It combines data-quality assessment, cross-source comparison, pricing analysis and dashboard reporting in an end-to-end data analytics workflow.
