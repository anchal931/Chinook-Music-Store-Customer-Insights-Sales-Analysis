# Chinook Music Store Customer Insights & Sales Analysis

## Overview
This project analyzes customer data and sales trends for the Chinook Music Store. The analysis focuses on customer purchasing behavior, revenue distribution, top-selling tracks and genres, market performance, customer retention, and churn trends. The insights aim to optimize marketing strategies and improve customer engagement.

## Data Sources
- *Chinook SQL Database* – Contains customer, invoice, and track information.
- *Analysis Report* – SQL queries and results for various analytical tasks.
- *Presentation* – Summarized insights, trends, and recommendations.

## Key Analyses

### Data Cleaning & Preparation
- Replaced missing values in the Composer column with 'Unknown'.
- Dropped columns with excessive null values (Company, Fax).
- Set default values for State, Postal Code, and Phone.

### Customer Demographics
- *Highest Customer Concentration:*  
  - USA: 13 customers  
  - Canada: 8 customers  
  - Brazil & France: 5 each  
- *Key Markets:* Strongest presence in North America, Europe, and South America.

### Sales Performance
- *Top-Selling Genre:* Rock (50%+ of USA sales).
- *Top-Selling Track:* War Pigs by Cake ($5.94 revenue).
- *Top-Selling Artist:* Queen (best-selling globally).

### Customer Behavior & Churn Analysis
- *Customer Segments:*  
  - Frequent buyers: Small but regular purchases.  
  - Occasional buyers: Larger purchases at longer intervals.  
- *Churn Trends:*  
  - 2017: 3.51%  
  - 2018: 1.82%  
  - 2019: -7.41% (negative churn, indicating growth).  
- *Regional Churn Rates:*  
  - *High churn (100%)* – Belgium, Chile, Denmark, Netherlands, Norway, Spain.  
  - *Moderate churn (33-50%)* – Germany, Brazil, France, UK.  
  - *Low churn (≤15%)* – USA, Canada.  

### Customer Lifetime Value (CLV)
- *High CLV Countries:* Czech Republic, Ireland, India, Portugal.
- *Moderate CLV Countries:* USA, Canada, UK, Germany, Brazil.
- *Low CLV Countries:* Belgium, Chile, Denmark, Netherlands, Norway, Spain (high churn, low engagement).

## Recommendations
1. *Prioritize Rock music promotions, especially in **North America and Europe*.
2. *Implement loyalty programs* (discounts, exclusive releases) to improve retention.
3. *Use targeted marketing strategies* to engage high-churn countries.
4. *Encourage cross-selling & bundling* of frequently purchased tracks and genres.
5. *Introduce subscription models* for long-term engagement and revenue growth.

## How to Use This Project
- Run the *SQL queries* to replicate the analysis.
- Use findings to *optimize marketing efforts, personalize recommendations, and improve customer retention*.

## Tools Used
- *SQL* (MySQL) – Querying and data retrieval.
- *Excel* – Advanced analysis and visualization.
- *PowerPoint* – Presentation of key insights and recommendations.

## Conclusion
This analysis provides a data-driven approach to improving Chinook Music Store’s sales, customer retention, and market expansion. Implementing the recommendations will enhance engagement, increase revenue, and refine marketing strategies.

---

*Author:* Anchal Rani Barnowal 
*Date:* March 2025
