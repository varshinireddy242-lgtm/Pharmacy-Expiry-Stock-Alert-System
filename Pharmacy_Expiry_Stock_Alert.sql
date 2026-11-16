
DROP DATABASE IF EXISTS PharmacyDB;
CREATE DATABASE PharmacyDB;
USE PharmacyDB;

CREATE TABLE Category (
    category_id INT PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE Supplier (
    supplier_id INT PRIMARY KEY,
    supplier_name VARCHAR(100) NOT NULL,
    phone VARCHAR(15)
);

CREATE TABLE Medicines (
    medicine_id INT PRIMARY KEY,
    medicine_name VARCHAR(100) NOT NULL,
    category_id INT NOT NULL,
    supplier_id INT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    quantity INT NOT NULL,
    expiry_date DATE NOT NULL,
    minimum_stock INT NOT NULL,
    FOREIGN KEY (category_id) REFERENCES Category(category_id),
    FOREIGN KEY (supplier_id) REFERENCES Supplier(supplier_id)
);

CREATE TABLE Sales (
    sale_id INT PRIMARY KEY,
    medicine_id INT NOT NULL,
    quantity_sold INT NOT NULL,
    sale_date DATE NOT NULL,
    FOREIGN KEY (medicine_id) REFERENCES Medicines(medicine_id)
);

INSERT INTO Category VALUES
(1, 'Tablets'),
(2, 'Syrups'),
(3, 'Antibiotics'),
(4, 'Vitamins'),
(5, 'Injections');

INSERT INTO Supplier VALUES
(1, 'ABC Medical Suppliers', '9876543210'),
(2, 'HealthCare Distributors', '9876501234'),
(3, 'MedPlus Suppliers', '9123456780');

INSERT INTO Medicines VALUES
(101, 'Paracetamol', 1, 1, 25.00, 100, '2027-06-30', 20),
(102, 'Cough Syrup', 2, 2, 85.00, 15, '2026-11-20', 10),
(103, 'Amoxicillin', 3, 1, 60.00, 8, '2027-03-15', 15),
(104, 'Vitamin C', 4, 3, 40.00, 50, '2026-11-25', 10),
(105, 'Insulin', 5, 2, 250.00, 5, '2027-10-30', 10),
(106, 'Cetirizine', 1, 3, 30.00, 40, '2027-08-15', 10);

CREATE VIEW Low_Stock_Alert AS
SELECT medicine_id, medicine_name, quantity, minimum_stock
FROM Medicines
WHERE quantity <= minimum_stock;

CREATE VIEW Expiry_Alert AS
SELECT medicine_id, medicine_name, expiry_date
FROM Medicines
WHERE expiry_date BETWEEN CURDATE()
AND DATE_ADD(CURDATE(), INTERVAL 30 DAY);

CREATE VIEW Stock_Summary AS
SELECT medicine_id, medicine_name, quantity, minimum_stock, expiry_date
FROM Medicines;

DELIMITER //

CREATE TRIGGER Update_Stock
BEFORE INSERT ON Sales
FOR EACH ROW
BEGIN
    IF NEW.quantity_sold <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Sale quantity must be greater than zero';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM Medicines
        WHERE medicine_id = NEW.medicine_id
        AND quantity >= NEW.quantity_sold
        AND expiry_date >= CURDATE()
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Medicine not found, insufficient stock, or medicine expired';
    END IF;

    UPDATE Medicines
    SET quantity = quantity - NEW.quantity_sold
    WHERE medicine_id = NEW.medicine_id;
END//

DELIMITER ;

INSERT INTO Sales VALUES
(1, 101, 5, CURDATE()),
(2, 102, 2, CURDATE()),
(3, 104, 3, CURDATE());

SELECT * FROM Category;
SELECT * FROM Supplier;
SELECT * FROM Medicines;
SELECT * FROM Sales;

SELECT
    Medicines.medicine_name,
    Supplier.supplier_name,
    Supplier.phone
FROM Medicines
INNER JOIN Supplier
ON Medicines.supplier_id = Supplier.supplier_id;

SELECT
    Medicines.medicine_name,
    Category.category_name,
    Medicines.price
FROM Medicines
INNER JOIN Category
ON Medicines.category_id = Category.category_id;

SELECT
    category_id,
    COUNT(*) AS total_medicines
FROM Medicines
GROUP BY category_id;

SELECT
    category_id,
    COUNT(*) AS total_medicines
FROM Medicines
GROUP BY category_id
HAVING COUNT(*) > 1;

SELECT COUNT(*) AS total_medicines
FROM Medicines;

SELECT MAX(price) AS highest_price
FROM Medicines;

SELECT AVG(price) AS average_price
FROM Medicines;

SELECT SUM(quantity) AS total_stock
FROM Medicines;

SELECT MIN(price) AS lowest_price
FROM Medicines;

SELECT * FROM Low_Stock_Alert;

SELECT * FROM Expiry_Alert;

SELECT * FROM Stock_Summary;

SELECT
    category_id,
    AVG(price) AS average_price,
    MAX(price) AS maximum_price,
    COUNT(*) AS total_medicines
FROM Medicines
GROUP BY category_id;
