# Part 4: Analysis & Reflection

## Why Is the Star Schema Faster?

The primary reason the star schema outperforms the normalized OLTP schema is that it is designed specifically for analytical workloads, whereas the OLTP schema is optimized for transactional integrity and data consistency.

### Join Complexity Comparison

In the normalized schema, even moderately simple analytical questions require multiple joins across transactional tables. For example:

- Monthly encounters by specialty required joins across:
  - encounters
  - providers
  - specialties
- More complex questions (e.g., diagnosis–procedure analysis or readmissions) required:
  - Multiple bridge tables
  - Self-joins
  - Runtime date calculations

In contrast, the star schema reduces this complexity significantly:

- Most analytical queries involve:
  - One fact table
  - Two to four dimension tables
- No chaining of joins across multiple transactional entities
- No self-joins on large transactional tables

This reduction in join depth lowers CPU usage, reduces I/O, and minimizes intermediate result sets.

### Where Data Is Pre-Computed in the Star Schema

Another major performance advantage comes from pre-computation during ETL. In the star schema:

- Time attributes (year, month, quarter, week) are pre-calculated in dim_date
- Metrics such as:
  - Diagnosis count
  - Procedure count
  - Length of stay
  - Allowed amounts  
    are already stored in the fact table
- Business keys are replaced with integer surrogate keys, which are faster to join and index

As a result, analytical queries no longer need to:
- Format dates at runtime
- Count related rows repeatedly
- Perform complex calculations inside SQL

### Why Denormalization Helps Analytical Queries

Denormalization shifts complexity from query time to ETL time. This trade-off is ideal for analytics because:

- Queries are executed far more frequently than ETL jobs
- Business users expect near-instant responses
- Storage is cheaper than compute in most modern systems

By flattening related attributes into dimensions and facts, the database can answer analytical questions with fewer joins, simpler execution plans, and more predictable performance.

---

## Trade-offs: What Did You Gain? What Did You Lose?

### What Was Given Up

Designing a star schema required accepting several trade-offs:

- Data duplication
  - Specialty names, department attributes, and provider details appear in multiple places
- More complex ETL 
  - Logic is required to manage surrogate keys
  - Late-arriving facts and dimension updates must be handled carefully
- Loss of strict normalization
  - The schema is no longer ideal for transactional updates

These trade-offs increase development and maintenance effort on the ETL side.

### What Was Gained

In return, the star schema provides substantial benefits:

- Dramatically faster query performance
- Simpler SQL for analysts and BI tools
- Better scalability as data volume grows
- Isolation of analytical workloads from the OLTP system

### Was It Worth It?

Yes. The normalized schema works well for recording patient encounters, but it is not suitable for repeated, complex analytical queries. The star schema enables scalable analytics without placing additional load on the transactional system, which is the correct architectural decision for healthcare reporting and decision support.

---

## Bridge Tables: Were They Worth It?

### Why Use Bridge Tables for Diagnoses and Procedures?

Diagnoses and procedures have a true many-to-many relationship with encounters:

- One encounter can have multiple diagnoses
- One diagnosis can occur in many encounters
- The same applies to procedures

Denormalizing these directly into the fact table would have caused:

- Fact table row explosion
- Inflated counts and incorrect aggregations
- Difficult-to-maintain schemas

Bridge tables preserve relational integrity while still supporting analytical queries efficiently.

### Trade-offs of Bridge Tables

Advantages
- Accurate modeling of many-to-many relationships
- Flexibility for detailed clinical analysis
- Prevents duplication of fact records

Disadvantages
- Queries involving diagnoses or procedures require additional joins
- Slightly higher query cost compared to simple fact-only queries

### Would This Be Different in Production?

In a production environment:
- Summary dashboards would rely on fact-level metrics
- Bridge tables would be queried mainly for:
  - Clinical research
  - Detailed reporting
  - Advanced analysis

This approach aligns with common industry practices and provides a good balance between accuracy and performance.

---

## Performance Quantification

### Example 1: Revenue by Specialty & Month

- OLTP execution time: ~0.19 seconds  
- Star schema execution time: ~0.10 seconds  

Improvement:  
0.19 / 0.10 ≈ 1.9× faster

Main reason for speedup:
- Removal of joins to billing, providers, and specialties
- Pre-aggregated revenue stored in the fact table
- No runtime date formatting

---

### Example 2: 30-Day Readmission Rate

- OLTP execution time: ~0.11 seconds  
- Star schema execution time: ~0.08 seconds  

Improvement:  
0.11 / 0.08 ≈ 1.4× faster

Main reason for speedup:
- Avoidance of expensive transactional self-joins
- Integer date key comparisons instead of datetime calculations
- Reduced join complexity

