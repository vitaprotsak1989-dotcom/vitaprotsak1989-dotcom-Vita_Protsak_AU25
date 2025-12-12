-- Fuel station network 

--========================================
-- Create Database & Schema
--========================================
CREATE DATABASE  Fuel_Station_DB;

CREATE SCHEMA IF NOT EXISTS fuel_network;

SET search_path TO fuel_network;

--========================================
-- Tables 
--========================================

CREATE TABLE Station (
    Station_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Station_code VARCHAR(10) NOT NULL UNIQUE,
    Name VARCHAR(100) NOT NULL,
    Address VARCHAR(255),
    City VARCHAR(100),
    Opened_date DATE NOT NULL CHECK (Opened_date >= '2024-01-01')
);

CREATE TABLE Fuel_Type (
    Fuel_type_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Fuel_code VARCHAR(10) NOT NULL UNIQUE,
    Fuel_name VARCHAR(50) NOT NULL,
    Octane_rating INT CHECK (Octane_rating >= 0)
);


CREATE TABLE Customer (
    Customer_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    First_name VARCHAR(50) NOT NULL,
    Last_name VARCHAR(50) NOT NULL,
    Phone VARCHAR(20),
    Email VARCHAR(100) UNIQUE
);


CREATE TABLE Payment_Method (
    Payment_method_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Method_name VARCHAR(50) NOT NULL UNIQUE
);


CREATE TABLE Pump (
    Pump_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Station_id INT NOT NULL,
    Pump_number INT NOT NULL,
    Pump_type VARCHAR(20),
    Active_flag BOOLEAN DEFAULT TRUE,
    CONSTRAINT FK_Pump_Station FOREIGN KEY (Station_id) REFERENCES Station(Station_id),
    CONSTRAINT UQ_Pump_Number UNIQUE (Station_id, Pump_number)
);


CREATE TABLE Station_Fuel_Storage (
    Station_id INT NOT NULL,
    Fuel_type_id INT NOT NULL,
    Current_quantity_liters NUMERIC(10,2) DEFAULT 0 CHECK (Current_quantity_liters >= 0),
    Tank_capacity_liters NUMERIC(10,2) NOT NULL CHECK (Tank_capacity_liters > 0 AND Current_quantity_liters <= Tank_capacity_liters),
    PRIMARY KEY (Station_id, Fuel_type_id),
    CONSTRAINT FK_SFS_Station FOREIGN KEY (Station_id) REFERENCES Station(Station_id),
    CONSTRAINT FK_SFS_Fuel FOREIGN KEY (Fuel_type_id) REFERENCES Fuel_Type(Fuel_type_id)
);

CREATE TABLE Price_History (
    Price_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Station_id INT NOT NULL,
    Fuel_type_id INT NOT NULL,
    Regular_price NUMERIC(10,2) NOT NULL CHECK (Regular_price > 0),
    Discounted_price NUMERIC(10,2) CHECK (Discounted_price >= 0),
    Effective_date DATE NOT NULL CHECK (Effective_date >= '2024-10-01'),
    CONSTRAINT FK_PH_Station FOREIGN KEY (Station_id) REFERENCES Station(Station_id),
    CONSTRAINT FK_PH_Fuel FOREIGN KEY (Fuel_type_id) REFERENCES Fuel_Type(Fuel_type_id)
);



CREATE TABLE Transaction (
    Transaction_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Pump_id INT NOT NULL,
    Fuel_type_id INT NOT NULL,
    Customer_id INT NOT NULL,
    Payment_method_id INT NOT NULL,
    Transaction_datetime TIMESTAMP NOT NULL CHECK (Transaction_datetime >= '2024-10-01'),
    Liters_sold NUMERIC(10,2) NOT NULL CHECK (Liters_sold > 0),
    Price_per_liter NUMERIC(10,2) NOT NULL CHECK (Price_per_liter > 0),
    Total_amount NUMERIC(12,2) GENERATED ALWAYS AS (Liters_sold * Price_per_liter) STORED,
    CONSTRAINT FK_Trans_Pump FOREIGN KEY (Pump_id) REFERENCES Pump(Pump_id),
    CONSTRAINT FK_Trans_Fuel FOREIGN KEY (Fuel_type_id) REFERENCES Fuel_Type(Fuel_type_id),
    CONSTRAINT FK_Trans_Customer FOREIGN KEY (Customer_id) REFERENCES Customer(Customer_id),
    CONSTRAINT FK_Trans_Payment FOREIGN KEY (Payment_method_id) REFERENCES Payment_Method(Payment_method_id)
);

--========================================
-- DML INSERTS 
--========================================

INSERT INTO Station (Station_code, Name, Address, City, Opened_date)
VALUES
('ST001', 'Central Station', '123 Main St', 'Kyiv', '2024-10-01'),
('ST002', 'North Station', '45 North Ave', 'Lviv', '2024-10-05'),
('ST003', 'South Station', '78 South Rd', 'Odessa', '2024-10-10'),
('ST004', 'East Station', '12 East Blvd', 'Kharkiv', '2024-10-15'),
('ST005', 'West Station', '9 West St', 'Dnipro', '2024-10-20'),
('ST006', 'Airport Station', '1 Airport Rd', 'Kyiv', '2024-10-25');



INSERT INTO Fuel_Type (Fuel_code, Fuel_name, Octane_rating)
VALUES
('F001', 'Petrol 95', 95),
('F002', 'Petrol 98', 98),
('F003', 'Diesel', 0),
('F004', 'Gas', 0),
('F005', 'Premium Diesel', 0),
('F006', 'Electric Charge', 0);


INSERT INTO Customer (First_name, Last_name, Phone, Email)
VALUES
('Ivan', 'Ivanov', '+380501234567', 'ivan@example.com'),
('Petro', 'Petrov', '+380671234567', 'petro@example.com'),
('Oleg', 'Olegov', '+380931234567', 'oleg@example.com'),
('Anna', 'Annov', '+380991234567', 'anna@example.com'),
('Olena', 'Olenova', '+380681234567', 'olena@example.com'),
('Sergiy', 'Sergiev', '+380631234567', 'sergiy@example.com');

INSERT INTO Payment_Method (Method_name)
VALUES
('Cash'), ('Card'), ('Mobile Pay'), ('Voucher'), ('Company Account'), ('Crypto')
ON CONFLICT (Method_name) DO NOTHING;



INSERT INTO Pump (Station_id, Pump_number, Pump_type, Active_flag)
VALUES
(1, 1, 'Petrol', TRUE),
(1, 2, 'Diesel', TRUE),
(2, 1, 'Petrol', TRUE),
(2, 2, 'Diesel', TRUE),
(3, 1, 'Petrol', TRUE),
(3, 2, 'Diesel', TRUE);


INSERT INTO Station_Fuel_Storage (Station_id, Fuel_type_id, Current_quantity_liters, Tank_capacity_liters)
VALUES
(1, 1, 5000, 10000),
(1, 3, 3000, 8000),
(2, 1, 4000, 9000),
(2, 3, 2000, 7000),
(3, 1, 4500, 9500),
(3, 3, 2500, 7500)
ON CONFLICT (Station_id, Fuel_type_id) DO NOTHING;




INSERT INTO Price_History (Station_id, Fuel_type_id, Regular_price, Discounted_price, Effective_date)
VALUES
(1, 1, 40.50, 38.50, '2024-10-01'),
(1, 3, 38.00, 36.50, '2024-10-01'),
(2, 1, 41.00, 39.00, '2024-10-05'),
(2, 3, 37.50, 36.00, '2024-10-05'),
(3, 1, 40.75, 39.00, '2024-10-10'),
(3, 3, 38.25, 37.00, '2024-10-10')
ON CONFLICT DO NOTHING;

--=======================================
-- Functions
--=======================================

CREATE OR REPLACE FUNCTION fuel_network.update_table_column(
    table_name TEXT,
    pk_column TEXT,
    pk_value INT,
    column_name TEXT,
    new_value TEXT
)
RETURNS VOID AS $$
BEGIN
    EXECUTE format('UPDATE fuel_network.%I SET %I = $1 WHERE %I = $2',
                    table_name, column_name, pk_column)
    USING new_value, pk_value;
END;
$$ LANGUAGE plpgsql;

--==========================================
-- Insert a transaction using natural keys
--==========================================

CREATE OR REPLACE FUNCTION fuel_network.add_transaction(
    p_pump_id INT,
    p_fuel_type_id INT,
    p_customer_id INT,
    p_payment_method_id INT,
    p_datetime TIMESTAMP,
    p_liters NUMERIC,
    p_price NUMERIC
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO fuel_network.Transaction
    (Pump_id, Fuel_type_id, Customer_id, Payment_method_id, Transaction_datetime, Liters_sold, Price_per_liter)
    VALUES
    (p_pump_id, p_fuel_type_id, p_customer_id, p_payment_method_id, p_datetime, p_liters, p_price);
END;
$$ LANGUAGE plpgsql;

-- ===========================
-- Quarterly Analytics View
-- ===========================

CREATE OR REPLACE VIEW fuel_network.recent_quarter_sales AS
SELECT
    t.Transaction_datetime,
    s.Name AS Station_name,
    f.Fuel_name,
    c.First_name || ' ' || c.Last_name AS Customer_name,
    t.Liters_sold,
    t.Price_per_liter,
    t.Total_amount,
    pm.Method_name AS Payment_method
FROM fuel_network.Transaction t
JOIN fuel_network.Pump p ON t.Pump_id = p.Pump_id
JOIN fuel_network.Station s ON p.Station_id = s.Station_id
JOIN fuel_network.Fuel_Type f ON t.Fuel_type_id = f.Fuel_type_id
JOIN fuel_network.Customer c ON t.Customer_id = c.Customer_id
JOIN fuel_network.Payment_Method pm ON t.Payment_method_id = pm.Payment_method_id
WHERE t.Transaction_datetime >= (CURRENT_DATE - INTERVAL '3 months');


=======================================
-- Read-Only Manager Role
=======================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'manager_readonly') THEN
        CREATE ROLE manager_readonly LOGIN PASSWORD 'SecurePass123';
    END IF;
END$$;

GRANT CONNECT ON DATABASE Fuel_Station_DB TO manager_readonly;
GRANT USAGE ON SCHEMA fuel_network TO manager_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA fuel_network TO manager_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA fuel_network GRANT SELECT ON TABLES TO manager_readonly;