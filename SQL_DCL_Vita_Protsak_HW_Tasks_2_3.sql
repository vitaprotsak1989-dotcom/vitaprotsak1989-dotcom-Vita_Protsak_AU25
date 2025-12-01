-- ================================================
Task 2. Implement role-based authentication model for dvd_rental database
Create a new user with the username "rentaluser" and the password "rentalpassword". 
Give the user the ability to connect to the database but no other permissions.
Grant "rentaluser" SELECT permission for the "customer" table. 
Сheck to make sure this permission works correctly—write a SQL query to select all customers.
Create a new user group called "rental" and add "rentaluser" to the group. 
Grant the "rental" group INSERT and UPDATE permissions for the "rental" table. 
Insert a new row and update one existing row in the "rental" table under that role. 
Revoke the "rental" group's INSERT permission for the "rental" table. 
Try to insert new rows into the "rental" table make sure this action is denied.
Create a personalized role for any customer already existing in the dvd_rental database. 
The name of the role name must be client_{first_name}_{last_name} (omit curly brackets). 
The customer's payment and rental history must not be empty. 


-- ================================================

-- ================================================
-- 1. Create user rentaluser
-- ================================================

CREATE USER rentaluser WITH PASSWORD 'rentalpassword';
-- ================================================
-- 2. REVOKE everything 
-- ================================================
REVOKE ALL PRIVILEGES ON DATABASE dvdrental FROM rentaluser;

-- ================================================
-- 3. Allow only CONNECT permission
-- ================================================
GRANT CONNECT ON DATABASE dvdrental TO rentaluser;


SELECT rolname, rolcanlogin, rolcreaterole, rolcreatedb
FROM pg_roles
WHERE rolname = 'rentaluser';

-- ================================================
-- 3. GRANT SELECT ON customer TABLE
-- ================================================
GRANT SELECT ON public.customer TO rentaluser;

SET ROLE rentaluser;
SELECT * FROM public.customer;
RESET ROLE;

-- ================================================
-- 3. Create group role "rental" and add rentaluser
-- ================================================

CREATE ROLE rental;
GRANT rental TO rentaluser;

-- ================================================
-- 4. Grant INSERT and UPDATE on rental table to the group
-- ================================================

GRANT INSERT, UPDATE ON public.rental TO rental;

SET ROLE rental;


INSERT INTO public.rental (rental_date, inventory_id, customer_id, return_date, staff_id)
VALUES (NOW(), 1, 1, NULL, 1);


------------------------------
UPDATE public.rental
SET return_date = NOW()
WHERE rental_id = 1;

RESET ROLE;

-- ================================================
-- 5. Revoke INSERT from the rental group
-- ================================================

REVOKE INSERT ON public.rental FROM rental;

SET ROLE rental;

INSERT INTO public.rental (rental_date, inventory_id, customer_id, return_date, staff_id)
VALUES (NOW(), 1, 1, NULL, 1); -- Expected: permission denied

RESET ROLE;

-- ================================================
-- 6. Create personalized role for a customer
-- ================================================


CREATE ROLE client_Patricia_Johnson;


GRANT CONNECT ON DATABASE dvdrental TO client_Patricia_Johnson;


GRANT SELECT ON public.customer, public.rental, public.payment TO client_Patricia_Johnson;


SET ROLE client_Patricia_Johnson;

SELECT * FROM public.customer WHERE customer_id = 2;
SELECT * FROM public.rental WHERE customer_id = 2;
SELECT * FROM public.payment WHERE customer_id = 2;

RESET ROLE;

-- ================================================
Task 3. Implement row-level security
Read about row-level security (https://www.postgresql.org/docs/12/ddl-rowsecurity.html) 
Configure that role so that the customer can only access their own data in the "rental" 
and "payment" tables. Write a query to make sure this user sees only their own data.
-- ================================================

-- ================================================
-- 1. Enable Row-Level Security on the tables
-- ================================================
ALTER TABLE public.rental ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment ENABLE ROW LEVEL SECURITY;


-- ================================================
-- 2. Create SELECT policies for the customer
-- ================================================
-- Allow Patricia to SELECT only her own rentals
CREATE POLICY rental_select_own
ON public.rental
FOR SELECT
USING (customer_id = 2);

-- Allow Patricia to SELECT only her own payments
CREATE POLICY payment_select_own
ON public.payment
FOR SELECT
USING (customer_id = 2);

-- ================================================
-- 3.Grant SELECT privileges
-- ================================================
GRANT SELECT ON public.rental, public.payment TO client_Patricia_Johnson;


-- ================================================
-- 4.Test the row-level security
-- ================================================

-- Use the customer role
SET ROLE client_Patricia_Johnson;

-- Rentals — should show only Patricia's rentals
SELECT * FROM public.rental;

-- Payments — should show only Patricia's payments
SELECT * FROM public.payment;

RESET ROLE;
