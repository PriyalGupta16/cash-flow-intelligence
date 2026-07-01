# Cash Flow Intelligence System

A MySQL project that simulates how businesses track unpaid invoices, measure customer payment risk, and automatically update payment status — without manual intervention.

# The Problem

When a business sells on credit, they send invoices and wait for payment. Managing hundreds of such invoices manually in Excel is messy and error-prone. This project solves that using a structured MySQL database with smart queries on top.

# Database Design

Three tables that connect to each other:

- `customers` — stores company details
- `invoices` — bills raised against each customer with due dates and amounts
- `payments` — actual payments received, linked to invoices

# What This System Does

**Invoice Aging Report**  
Groups all unpaid invoices into buckets — 0-30 days, 31-60 days, 61-90 days, and 90+ days critical. Sorted by most overdue first so the finance team knows where to follow up immediately.

**Running Payment Total**  
Shows how much each customer has paid over time, accumulating with each payment. Built using window functions.

**Customer Risk View**  
A saved view that scores every customer as HIGH, MEDIUM, or LOW risk based on how many overdue invoices they have. Updates automatically as data changes.

**Stored Procedure**  
A reusable procedure called GetOverdueInvoices that takes number of days as input and returns all invoices past that threshold. Call it anytime with different values.

**Auto Status Trigger**  
When a payment is inserted, a trigger automatically checks if the invoice is fully paid. If yes, it updates the invoice status to PAID without any manual query needed.

# Concepts Used

- Schema design with Foreign Keys
- INNER JOIN across multiple tables
- CASE WHEN for conditional logic
- DATEDIFF for date calculations
- SUM() OVER(PARTITION BY) — window function
- GROUP BY with aggregations
- CREATE VIEW
- Stored Procedure with input parameter
- AFTER INSERT Trigger

# How To Run

1. Install MySQL 8.0 and MySQL Workbench
2. Connect to local MySQL instance
3. Open cash_flow_intelligence.sql
4. Run the full script
5. Everything gets created automatically — tables, data, views, procedure, and trigger

# Author

Priyal Gupta  
B.E. Computer Science, Chitkara University  
GitHub: https://github.com/PriyalGupta16
