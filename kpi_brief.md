# KPI Brief — Levant Tech Solutions

## KPI 1: Total Employee Headcount
**Definition:** Total number of employees in the company, calculated using the employees table (SELECT COUNT(*) FROM employees).

**Current value:** 60

**Interpretation:** The company currently has 60 employees, providing a baseline for workforce planning and capacity management.

---

## KPI 2: Departments with High Salary Spend
**Definition:** Number of departments where total salary exceeds 150,000, calculated using employees and departments tables with GROUP BY and HAVING (Q2).

**Current value:** 8

**Interpretation:** All departments exceed the salary threshold, indicating consistently high investment in human resources across the organization.

---

## KPI 3: Highest Salary by Department
**Definition:** The highest-paid employee in each department, calculated using a window function (ROW_NUMBER OVER PARTITION BY department_id ORDER BY salary DESC) from Q3.

**Current value:** Engineering department highest salary = 120,000

**Interpretation:** Engineering has the highest top salary, reflecting strong demand for technical expertise and leadership roles.