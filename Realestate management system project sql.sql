use mydatabase;
-- owners
CREATE TABLE Owners (
    owner_id INT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone VARCHAR(15),
    email VARCHAR(100) UNIQUE NOT NULL
);

INSERT INTO Owners VALUES
(101, 'Robert', 'Davis', '555-1001', 'robert.davis@mail.com'),
(102, 'Linda', 'Smith', '555-1002', 'linda.smith@mail.com'),
(103, 'David', 'Garcia', '555-1003', 'david.garcia@mail.com'),
(104, 'Sarah', 'Miller', '555-1004', 'sarah.miller@mail.com');

-- Agents Table
CREATE TABLE Agents (
    agent_id INT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone VARCHAR(15),
    email VARCHAR(100) UNIQUE NOT NULL,
    hire_date DATE);

INSERT INTO Agents VALUES
(201, 'Maria', 'Lee', '555-2001', 'maria.lee@agency.com', '2019-01-15'),
(202, 'Chris', 'Evans', '555-2002', 'chris.evans@agency.com', '2021-05-20'),
(203, 'James', 'Chen', '555-2003', 'james.chen@agency.com', '2023-11-01');

-- Clients/Buyers Table
CREATE TABLE Clients (
    client_id INT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone VARCHAR(15),
    email VARCHAR(100) UNIQUE NOT NULL,
    budget_min DECIMAL(12, 2) CHECK (budget_min >= 0),
    budget_max DECIMAL(12, 2),
    CHECK (budget_max >= budget_min)
);

INSERT INTO Clients VALUES
(301, 'Anna', 'Wilson', '555-3001', 'anna.wilson@search.com', 250000.00, 350000.00),
(302, 'Ben', 'Chen', '555-3002', 'ben.chen@search.com', 400000.00, 600000.00),
(303, 'Emily', 'Clark', '555-3003', 'emily.clark@search.com', 150000.00, 250000.00);


-- Properties Table
CREATE TABLE Properties (
    property_id INT PRIMARY KEY,
    owner_id INT NOT NULL,
    address VARCHAR(255) UNIQUE NOT NULL,
    city VARCHAR(50) NOT NULL,
    zip_code VARCHAR(10),
    property_type VARCHAR(20) CHECK (property_type IN ('House', 'Apartment', 'Condo', 'Land')),
    num_bedrooms INT CHECK (num_bedrooms >= 0),
    square_footage INT CHECK (square_footage > 0),
    FOREIGN KEY (owner_id) REFERENCES Owners(owner_id)
);

INSERT INTO Properties VALUES
(401, 101, '123 Oak St', 'Springfield', '62704', 'House', 3, 1800),
(402, 102, '45 Pine Ave', 'Shelbyville', '62565', 'Apartment', 2, 1100),
(403, 103, '789 Maple Rd', 'Springfield', '62704', 'House', 4, 2500),
(404, 104, '300 River Ln', 'Shelbyville', '62565', 'Condo', 1, 850);

-- Listings Table
CREATE TABLE Listings (
    listing_id INT PRIMARY KEY,
    property_id INT NOT NULL UNIQUE,
    agent_id INT NOT NULL,
    list_price DECIMAL(12, 2) CHECK (list_price > 1000),
    listing_date DATE NOT NULL,
    status VARCHAR(20) CHECK (status IN ('Active', 'Pending', 'Sold', 'Expired', 'Withdrawn')) NOT NULL,
    FOREIGN KEY (property_id) REFERENCES Properties(property_id),
    FOREIGN KEY (agent_id) REFERENCES Agents(agent_id)
);

INSERT INTO Listings VALUES
(501, 401, 201, 320000.00, '2024-05-01', 'Sold'),
(502, 402, 202, 210000.00, '2024-06-10', 'Active'),
(503, 403, 201, 550000.00, '2024-07-25', 'Pending'),
(504, 404, 203, 185000.00, '2024-08-05', 'Active');

-- Sales Table (Records successful transactions)
CREATE TABLE Sales (
    sale_id INT PRIMARY KEY,
    listing_id INT NOT NULL UNIQUE,
    buyer_id INT NOT NULL,
    sale_price DECIMAL(12, 2) NOT NULL,
    sale_date DATE NOT NULL,
    commission_rate DECIMAL(4, 3) CHECK (commission_rate BETWEEN 0.01 AND 0.10) NOT NULL, -- 1% to 10%
    FOREIGN KEY (listing_id) REFERENCES Listings(listing_id),
    FOREIGN KEY (buyer_id) REFERENCES Clients(client_id)
);

INSERT INTO Sales VALUES
(601, 501, 301, 315000.00, '2024-06-15', 0.06), -- Sale for 123 Oak St (Maria)
(602, 503, 302, 545000.00, '2024-08-10', 0.05); -- Sale for 789 Maple Rd (Maria)

-- 7. Showings Table (New table for complex relationship demonstration)
CREATE TABLE Showings (
    showing_id INT PRIMARY KEY,
    listing_id INT NOT NULL,
    client_id INT NOT NULL,
    showing_date DATETIME NOT NULL,
    feedback_rating INT CHECK (feedback_rating BETWEEN 1 AND 5),
    FOREIGN KEY (listing_id) REFERENCES Listings(listing_id),
    FOREIGN KEY (client_id) REFERENCES Clients(client_id)
);

INSERT INTO Showings VALUES
(701, 502, 303, '2024-10-01 10:00:00', 4), -- Client Emily showed 45 Pine Ave
(702, 504, 301, '2024-10-02 14:30:00', 3), -- Client Anna showed 300 River Ln
(703, 502, 301, '2024-10-03 11:00:00', 5); -- Client Anna showed 45 Pine Ave


-- Creates a reusable virtual table of current active/pending listings
CREATE VIEW Current_Inventory_Summary AS
SELECT
    L.listing_id,
    P.address,
    P.city,
    P.property_type,
    P.square_footage,
    L.list_price,
    A.first_name AS Agent_FirstName,
    L.status
FROM
    Listings L
JOIN
    Properties P ON L.property_id = P.property_id
JOIN
    Agents A ON L.agent_id = A.agent_id
WHERE
    L.status IN ('Active', 'Pending');
    
SELECT
    A.first_name,
    A.last_name,
    COUNT(S.sale_id) AS Total_Properties_Sold,
    SUM(S.sale_price) AS Total_Sales_Volume,
    SUM(S.sale_price * S.commission_rate) AS Total_Commission_Earned,
    AVG(S.commission_rate) AS Average_Commission_Rate
FROM
    Agents A
JOIN
    Listings L ON A.agent_id = L.agent_id
JOIN
    Sales S ON L.listing_id = S.listing_id
GROUP BY
    A.agent_id, A.first_name, A.last_name
ORDER BY
    Total_Commission_Earned DESC;
    
    -- stored procedure
    -- Stored Procedure to easily update a listing price
-- Delimiter required in MySQL/MariaDB. Remove for MSSQL/PostgreSQL.
DELIMITER //

CREATE PROCEDURE Update_Listing_Price (
    IN listingID INT,
    IN newPrice DECIMAL(12, 2)
)
BEGIN
    UPDATE Listings
    SET list_price = newPrice
    WHERE listing_id = listingID;

    SELECT CONCAT('Listing ', listingID, ' updated to $', newPrice) AS Message;
END //

DELIMITER ;
    
    -- market analysis avg price per square foot by city and type
    SELECT
    P.city,
    P.property_type,
    COUNT(S.sale_id) AS Total_Sold,
    AVG(S.sale_price / P.square_footage) AS Avg_Price_Per_SqFt
FROM
    Sales S
JOIN
    Listings L ON S.listing_id = L.listing_id
JOIN
    Properties P ON L.property_id = P.property_id
WHERE
    S.sale_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 6 MONTH) -- Filter for the last 6 months
GROUP BY
    P.city, P.property_type
HAVING
    COUNT(S.sale_id) >= 1 -- Only show groups with at least one sale
ORDER BY
    P.city, Avg_Price_Per_SqFt DESC;
    
    -- client intrest and potential lead
    SELECT
    C.first_name AS Client_FirstName,
    C.last_name AS Client_LastName,
    P.address AS Property_Viewed,
    COUNT(S.showing_id) AS Times_Viewed
FROM
    Showings S
JOIN
    Clients C ON S.client_id = C.client_id
JOIN
    Listings L ON S.listing_id = L.listing_id
JOIN
    Properties P ON L.property_id = P.property_id
GROUP BY
    C.client_id, C.first_name, C.last_name, P.address
HAVING
    COUNT(S.showing_id) > 1 -- Shows repeat viewings (high interest)
ORDER BY
    Times_Viewed DESC;
    
    -- Example of using the stored procedure
CALL mydatabase.Update_Listing_Price(502, 215000.00);

SELECT * FROM Current_Inventory_Summary;

show tables;

-- 1. View all Owners
SELECT * FROM Owners;

-- 2. View all Agents
SELECT * FROM Agents;

-- 3. View all Clients/Buyers
SELECT * FROM Clients;

-- 4. View all Properties
SELECT * FROM Properties;

-- 5. View all Listings
SELECT * FROM Listings;

-- 6. View all Sales
SELECT * FROM Sales;

-- 7. View all Showings
SELECT * FROM Showings;