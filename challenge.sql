-- =========================================
-- Challenge Extensions
-- =========================================


-- =========================================
-- Tier 1 — Complex Analytics Queries
-- =========================================

-- 1) At-risk projects:
-- Projects where total allocated hours exceed 80% of the project budget

SELECT p.project_id,
       p.name AS project_name,
       p.budget,
       COALESCE(SUM(pa.hours_allocated), 0) AS total_allocated_hours,
       ROUND((COALESCE(SUM(pa.hours_allocated), 0) * 100.0 / p.budget), 2) AS utilization_percent
FROM projects p
LEFT JOIN project_assignments pa
  ON p.project_id = pa.project_id
GROUP BY p.project_id, p.name, p.budget
HAVING COALESCE(SUM(pa.hours_allocated), 0) > p.budget * 0.8
ORDER BY utilization_percent DESC;


-- 2) Employee project assignment overview
-- Shows employee assignments with project details

SELECT e.employee_id,
       e.first_name,
       e.last_name,
       e.department_id AS employee_department_id,
       p.project_id,
       p.name AS project_name,
       pa.role
FROM employees e
JOIN project_assignments pa
  ON e.employee_id = pa.employee_id
JOIN projects p
  ON pa.project_id = p.project_id
WHERE e.department_id IS NOT NULL
ORDER BY e.employee_id, p.project_id;


-- =========================================
-- Tier 2 — Dynamic Reporting with Views and Functions
-- =========================================

-- 1) Department summary view

CREATE OR REPLACE VIEW department_summary_view AS
SELECT d.department_id,
       d.name AS department_name,
       COUNT(e.employee_id) AS employee_count,
       COALESCE(SUM(e.salary), 0) AS total_salary,
       ROUND(COALESCE(AVG(e.salary), 0), 2) AS average_salary
FROM departments d
LEFT JOIN employees e
  ON d.department_id = e.department_id
GROUP BY d.department_id, d.name;


-- 2) Project status view

CREATE OR REPLACE VIEW project_status_view AS
SELECT p.project_id,
       p.name AS project_name,
       p.budget,
       COUNT(pa.employee_id) AS assigned_employees,
       COALESCE(SUM(pa.hours_allocated), 0) AS total_allocated_hours
FROM projects p
LEFT JOIN project_assignments pa
  ON p.project_id = pa.project_id
GROUP BY p.project_id, p.name, p.budget;


-- 3) Materialized view example

DROP MATERIALIZED VIEW IF EXISTS project_status_materialized_view;

CREATE MATERIALIZED VIEW project_status_materialized_view AS
SELECT p.project_id,
       p.name AS project_name,
       p.budget,
       COUNT(pa.employee_id) AS assigned_employees,
       COALESCE(SUM(pa.hours_allocated), 0) AS total_allocated_hours
FROM projects p
LEFT JOIN project_assignments pa
  ON p.project_id = pa.project_id
GROUP BY p.project_id, p.name, p.budget;


-- 4) Function returning JSON summary for a department

CREATE OR REPLACE FUNCTION get_department_summary(dept_name_input VARCHAR)
RETURNS JSON
LANGUAGE plpgsql
AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'department_name', d.name,
        'employee_count', COUNT(DISTINCT e.employee_id),
        'total_salary', COALESCE(SUM(e.salary), 0)
    )
    INTO result
    FROM departments d
    LEFT JOIN employees e
      ON d.department_id = e.department_id
    WHERE d.name = dept_name_input
    GROUP BY d.name;

    RETURN result;
END;
$$;


-- Example calls
SELECT * FROM department_summary_view;
SELECT * FROM project_status_view;
SELECT * FROM project_status_materialized_view;
SELECT get_department_summary('Engineering');


-- =========================================
-- Tier 3 — Schema Evolution and Migration
-- =========================================

-- 1) Salary history table

DROP TABLE IF EXISTS salary_history;

CREATE TABLE salary_history (
    salary_history_id SERIAL PRIMARY KEY,
    employee_id INT NOT NULL REFERENCES employees(employee_id),
    salary_amount NUMERIC(10,2) NOT NULL CHECK (salary_amount > 0),
    effective_date DATE NOT NULL,
    end_date DATE,
    change_reason VARCHAR(100)
);


-- 2) Initial migration / backfill from employees table

INSERT INTO salary_history (employee_id, salary_amount, effective_date, end_date, change_reason)
SELECT employee_id,
       salary,
       hire_date,
       NULL,
       'Initial migration from employees table'
FROM employees;


-- 3) Additional realistic seed data

INSERT INTO salary_history (employee_id, salary_amount, effective_date, end_date, change_reason) VALUES
(1, 62000.00, '2022-01-01', '2023-01-01', 'Annual review'),
(1, 68000.00, '2023-01-02', NULL, 'Promotion'),
(2, 58000.00, '2022-02-01', '2023-02-01', 'Annual review'),
(2, 65000.00, '2023-02-02', NULL, 'Promotion'),
(3, 54000.00, '2022-03-01', '2023-03-01', 'Annual review'),
(3, 60000.00, '2023-03-02', NULL, 'Promotion');


-- 4) Salary growth by department over time

WITH department_salary_by_date AS (
    SELECT d.name AS department_name,
           sh.effective_date,
           AVG(sh.salary_amount) AS average_salary
    FROM salary_history sh
    JOIN employees e
      ON sh.employee_id = e.employee_id
    JOIN departments d
      ON e.department_id = d.department_id
    GROUP BY d.name, sh.effective_date
)
SELECT department_name,
       effective_date,
       average_salary
FROM department_salary_by_date
ORDER BY department_name, effective_date;


-- 5) Employees due for salary review
-- No salary change in 12+ months

SELECT e.employee_id,
       e.first_name,
       e.last_name,
       MAX(sh.effective_date) AS last_salary_change
FROM employees e
JOIN salary_history sh
  ON e.employee_id = sh.employee_id
GROUP BY e.employee_id, e.first_name, e.last_name
HAVING MAX(sh.effective_date) <= CURRENT_DATE - INTERVAL '12 months'
ORDER BY last_salary_change;