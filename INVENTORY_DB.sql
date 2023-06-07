-----------------------------CREATING DATABASE------------------------------
CREATE DATABASE INVENTORY_DB;
USE INVENTORY_DB

------------------------------CREATING TABLES-------------------------------

CREATE TABLE SUPPLIER
(SID CHAR(5) PRIMARY KEY,
SNAME VARCHAR(30) NOT NULL,
SADDR VARCHAR(80) NOT NULL,
SCITY VARCHAR(20) DEFAULT 'DELHI',
SPHONE CHAR(15) UNIQUE,
EMAIL VARCHAR(30)
);

SELECT * FROM SUPPLIER;

----------------------------------------------------------------------------

CREATE TABLE PRODUCT
(PID CHAR(5) PRIMARY KEY,
PDESC VARCHAR(100) NOT NULL,
PRICE INT CHECK(PRICE>0),
CATEGORY CHAR(2) CHECK(CATEGORY IN ('HA', 'IT', 'HC')),
SID CHAR(5) REFERENCES SUPPLIER(SID),
);

SELECT * FROM PRODUCT;

----------------------------------------------------------------------------

CREATE TABLE STOCK
(PID CHAR(5) REFERENCES PRODUCT(PID),
SQTY INT CHECK(SQTY >= 0),
ROL INT CHECK(ROL > 0),
MOQ INT CHECK(MOQ >= 5),
);

SELECT * FROM STOCK;

----------------------------------------------------------------------------

CREATE TABLE CUSTOMER
(CID CHAR(5) PRIMARY KEY,
CNAME VARCHAR(30) NOT NULL,
CADDR VARCHAR(80) NOT NULL,
CCITY VARCHAR(20) NOT NULL,
CPHONE CHAR(15) NOT NULL,
CEMAIL VARCHAR(30) NOT NULL,
DOB DATE CHECK(DOB < '1-JAN-2000'),
);

SELECT * FROM CUSTOMER;

----------------------------------------------------------------------------

CREATE TABLE ORDERS
(OID CHAR(5) PRIMARY KEY,
ODATE DATE,
PID CHAR(5) REFERENCES PRODUCT(PID),
CID CHAR(5) REFERENCES CUSTOMER(CID),
OQTY INT CHECK(OQTY >= 1),
);

SELECT * FROM ORDERS;

----------------------------------------------------------------------------

CREATE TABLE PURCHASE(
PID CHAR(5),
SID CHAR(5),
PQTY INT,
DOP DATE);

----------------------------------------------------------------------------
-------CREATING A USER DEFINED FUNCTION FOR AUTO GENERATION OF ID's---------

CREATE FUNCTION IDGEN(@C AS CHAR, @I AS INT)
RETURNS CHAR(5)
AS
BEGIN
	DECLARE @ID AS CHAR(5);

	SELECT @ID = CASE
			WHEN @I < 10 THEN CONCAT(@C,'000',@I)
			WHEN @I < 100 THEN CONCAT(@C,'00',@I)
			WHEN @I < 1000 THEN CONCAT(@C,'0',@I)
			WHEN @I < 10000 THEN CONCAT(@C,@I)
			ELSE 'NA'
	END;
	RETURN @ID;
END;


--------------------------------------------------------------------------------
--CREATING A TRIGGER FOR CONFIRMING STOCK AVAILABILITY FOR ORDER PLACEMENT AND--
-----------------AUTO UPDATION OF STOCK QTY BASED ON ORDER QTY------------------

CREATE TRIGGER STOCK_UPDATE
ON ORDERS
FOR INSERT
AS
BEGIN
	DECLARE @OQ AS INT;
	DECLARE @SQ AS INT;
	SET NOCOUNT ON;

	SET @OQ = (SELECT OQTY FROM INSERTED);
	SET @SQ = (SELECT SQTY FROM STOCK WHERE PID = (SELECT PID FROM INSERTED));

	IF @OQ <= @SQ
		BEGIN
			UPDATE STOCK SET SQTY = SQTY - @OQ
			WHERE PID = (SELECT PID FROM INSERTED);
		
			COMMIT;
			PRINT('ORDER CONFIRMED');
		END;
	
	ELSE
		BEGIN
			ROLLBACK;
			PRINT('INSUFFICIENT STOCK - ORDER REJECTED');
		END;
END;


----------------------------------------------------------------------------
------------------CREATING A TRIGGER FOR AUTO UPDATION----------------------
-----------------OF STOCK QTY WHEN ORDER QTY IS UPDATED---------------------

CREATE TRIGGER ORDER_QTY_UPDATE
ON ORDERS
FOR UPDATE
AS
BEGIN
	DECLARE @OQ AS INT
	DECLARE @NQ AS INT
	DECLARE @SQ AS INT
	SET NOCOUNT ON;

	SET @OQ = (SELECT OQTY FROM DELETED);
	SET @NQ = (SELECT OQTY FROM INSERTED);
	SET @SQ = (SELECT SQTY FROM STOCK WHERE PID = (SELECT PID FROM INSERTED));

	IF (@SQ + @OQ) >= @NQ
		BEGIN
		UPDATE STOCK SET SQTY = (SQTY + @OQ - @NQ)
		WHERE PID = (SELECT PID FROM INSERTED);
		COMMIT;
		PRINT('ORDER QTY UPDATED SUCCESSFULLY');
		END;
	ELSE
		BEGIN
		ROLLBACK;
		PRINT('INSUFFICIENT STOCK - ORDER QTY NOT UPDATED');
		END;
END;


----------------------------------------------------------------------------
--------CREATING A TRIGGER FOR AUTO UPDATION OF PURCHASE TABLE--------------
---------------WHEN THE STOCK QUANTITY FALLS BELOW ROL----------------------

CREATE TRIGGER PURCHASE_ORDER
ON STOCK
FOR UPDATE
AS
BEGIN
	DECLARE @SQ AS INT
	DECLARE @RQ AS INT
	DECLARE @MQ AS INT
	DECLARE @PID AS CHAR(5)
	DECLARE @SID AS CHAR(5)
	SET NOCOUNT ON;

	SET @PID = (SELECT PID FROM INSERTED);
	SET @SQ = (SELECT SQTY FROM STOCK WHERE PID = @PID);
	SET @RQ = (SELECT ROL FROM STOCK WHERE PID = @PID);
	SET @MQ = (SELECT MOQ FROM STOCK WHERE PID = @PID);
	SET @SID = (SELECT SID FROM PRODUCT WHERE PID = @PID);

	IF (@SQ < @RQ) AND (@PID NOT IN (SELECT PID FROM PURCHASE))
		INSERT INTO PURCHASE VALUES (@PID, @SID, @MQ, GETDATE());
END;


----------------------------------------------------------------------------

----------------------------------------------------------------------------
-----CREATING A STORED PROCEDURE FOR INSERTING VALUES TO SUPPLIER TABLE-----

CREATE SEQUENCE SID
AS INT
START WITH 1
INCREMENT BY 1
MAXVALUE 9999;

----------------------------------------------------------------------------

CREATE PROCEDURE ADD_SUPP @SN AS VARCHAR(30), @SA AS VARCHAR(80), @SC AS VARCHAR(20), @SPH AS CHAR(15), 
@EML AS VARCHAR(30)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @SID AS CHAR(5)
	SET @SID = DBO.IDGEN('S', NEXT VALUE FOR SID)

	INSERT INTO SUPPLIER VALUES(@SID, @SN, @SA, @SC, @SPH, @EML);

	SELECT * FROM SUPPLIER WHERE SID = @SID;
END;

DELETE FROM SUPPLIER;

----------------------------------------------------------------------------

ADD_SUPP 'GEEPAS', '59, Minerva Complex', 'Secunderabad', '9899955500', 'geepas_sales@gmail.com';
ADD_SUPP 'Wipro', '46, Regal Building, Outer Circle Road', 'Delhi', '9999882200', 'ibm_sales@gmail.com';
ADD_SUPP 'BOSCH', '4/1 D, Rajappa Ln Pb No 6745, S J P Road', 'Bangalore', '7777444220', 'bosch_sales@gmail.com';
ADD_SUPP 'Accu-Chek', '19, Akbar Market, Western Express Highway', 'Mumbai', '8888844422', 'medtronic_sales@yahoo.com';
ADD_SUPP 'HP', '4, Piramal Nagar Indl E, S V Road, Goregaon', 'Mumbai', '8666663222', 'hp_sales@gmail.com';
ADD_SUPP 'LG', 'Mohan Cooperative Industrial Estate, Mathura Road', 'Delhi', '8069379999', 'LG_sales@gmail.com';

----------------------------------------------------------------------------
-----CREATING A STORED PROCEDURE FOR INSERTING VALUES TO PRODUCTS TABLE-----

CREATE SEQUENCE PID
AS INT
START WITH 1
INCREMENT BY 1
MAXVALUE 9999;

----------------------------------------------------------------------------

CREATE PROCEDURE ADD_PRO @PD AS VARCHAR(100), @PR AS INT, @CAT AS CHAR(2), @SID AS CHAR(5)
AS
BEGIN
	DECLARE @PID AS CHAR(5);
	SET @PID = DBO.IDGEN('P', NEXT VALUE FOR PID)

	INSERT INTO PRODUCT VALUES(@PID, @PD, @PR, @CAT, @SID)

	SELECT * FROM PRODUCT WHERE PID = @PID;
END;

----------------------------------------------------------------------------

ADD_PRO 'HP Z3700 Silver Wireless Mouse', 2149, 'IT', 'S0005';
ADD_PRO 'BOSCH Series 6 washing machine, front loader 10 kg', 77590, 'HA', 'S0003';
ADD_PRO 'ACCU-CHEK Active Glucometer Kit', 949, 'HC', 'S0004';
ADD_PRO 'HP 230 Wireless Mouse and Keyboard Combo', 2199, 'IT', 'S0005';
ADD_PRO 'GEEPAS Large 650L Side-By-Side Refrigerator', 45980, 'HA', 'S0001';
ADD_PRO 'WIPRO Next Smart Camera', 4200, 'IT', 'S0002';
ADD_PRO 'ACCU-CHEK Instant Glucometer Kit', 1395, 'HC', 'S0004';
ADD_PRO 'GEEPAS Front Load Washing Machine', 14880, 'HA', 'S0001';
ADD_PRO 'WIPRO Smart Wireless Doorbell', 7109, 'HA', 'S0002';
ADD_PRO 'GEEPAS Split Type 2.0 Ton Air Conditioner', 35980, 'HA', 'S0001';
ADD_PRO 'BOSCH Freestanding cooker Stainless steel', 122990, 'HA', 'S0003';
ADD_PRO 'HP Laser 108w Printer', 13073, 'IT', 'S0005';
ADD_PRO 'GEEPAS Stand Fan GF9488', 2000, 'HA', 'S0001';
ADD_PRO 'HP DeskJet 2332 All-in-One Printer', 4499, 'IT', 'S0005';
ADD_PRO 'GEEPAS GVC2598 Drum Vacuum Cleaner', 3785, 'HA', 'S0001';
ADD_PRO 'LG 242 Ltr, 3 Star, Refrigerator', 24990, 'HA', 'S0006';

----------------------------------------------------------------------------
-----CREATING A STORED PROCEDURE FOR INSERTING VALUES TO CUSTOMER TABLE-----

CREATE SEQUENCE CID
AS INT 
START WITH 1
INCREMENT BY 1
MAXVALUE 9999;

----------------------------------------------------------------------------


CREATE PROCEDURE ADD_CUST @CN AS VARCHAR(30), @CA AS VARCHAR(80), @CC AS VARCHAR(20), 
@CPH AS CHAR(15), @CE AS VARCHAR(30), @DOB AS DATE
AS
BEGIN
	DECLARE @CID AS CHAR(5);
	SET @CID = DBO.IDGEN('C', NEXT VALUE FOR CID)

	INSERT INTO CUSTOMER VALUES (@CID, @CN, @CA, @CC, @CPH, @CE, @DOB)

	SELECT * FROM CUSTOMER WHERE CID = @CID;
END;


----------------------------------------------------------------------------

ADD_CUST 'TOMMY HILFIGER', '21th Floor, International Trade Tower', 'Delhi', '9513015058', 'tommmmy@gmail.com', '08-MAR-1975';
ADD_CUST 'JOHN LEGEND', '1-98-90/24/4, Madhapur', 'Hyderabad', '8756981237', 'johnthelegend@gmail.com', '13-JUN-1983';
ADD_CUST 'NARUTO UZUMAKI', '301, Richmond, Lokhandwala Complex, Andheri', 'Mumbai', '8569724937', 'naruto_uzu@gmail.com', '02-JAN-1994';
ADD_CUST 'LUFFY D M', '3, Montieth Lane,egmore, Egmore', 'Chennai', '7598468779', 'kingofpirates@yahoo.com', '25-FEB-1999';
ADD_CUST 'JOHN CENA', '122, Sector 7, Rohini', 'Delhi', '9956887234', 'cantseeme@gmail.com', '17-DEC-1982';
ADD_CUST 'VLAD PUTIN', 'No 7, Ramakrishnapuram, Gandhi Nagar', 'Bangalore', '9514132125', 'motherland@yahoo.com', '19-OCT-1963';
ADD_CUST 'GOJO SATURO', '615, Janki Center, Andheri', 'Mumbai', '8996578255', 'saturogojo@gmail.com', '30-APR-1998';
ADD_CUST 'THOR ODINSON', 'Opp. Surya Hospital, Kasba Peth', 'Pune', '7778592672', 'lightning_strike@gmail.com', '21-SEP-1961';
ADD_CUST 'PETER PARKER', '193, Phase 4, Udyog Vihar', 'Delhi', '8855667280', 'web_shooter@yahoo.com', '03-JAN-1999';
ADD_CUST 'BRUCE WAYNE', '25, A 1st Floor, Virwani Ind Estate', 'Mumbai', '9999900990', 'dadsmoney@gmail.com', '11-MAY-1988';
ADD_CUST 'HENRY FORD', 'B 112, Lajpat Nagar', 'Delhi', '9657982399', 'stangV8@gmail.com', '10-AUG-1966';


----------------------------------------------------------------------------


INSERT INTO STOCK
VALUES ('P0007', 60, 30, 15),
('P0013', 50, 20, 10),
('P0003', 100, 50, 20),
('P0001', 250, 100, 50),
('P0010', 10, 10, 5),
('P0012', 50, 20, 10),
('P0011', 5, 5, 5),
('P0006', 50, 20, 10),
('P0004', 250, 100, 50),
('P0015', 10, 10, 10);

SELECT * FROM STOCK;


----------------------------------------------------------------------------
------CREATING A STORED PROCEDURE FOR INSERTING VALUES TO ORDERS TABLE------

CREATE SEQUENCE OID
AS INT
START WITH 1
INCREMENT BY 1
MAXVALUE 9999;

----------------------------------------------------------------------------

CREATE PROCEDURE ADD_ORD @PI AS CHAR(5), @CI AS CHAR(5), @OQ AS INT
AS
BEGIN
	DECLARE @OID AS CHAR(5)
	SET @OID = DBO.IDGEN('O',NEXT VALUE FOR OID)

	INSERT INTO ORDERS VALUES (@OID, GETDATE(), @PI, @CI, @OQ);
	SELECT * FROM ORDERS WHERE OID = @OID;
END;

----------------------------------------------------------------------------

ADD_ORD 'P0004', 'C0002', 50;
ADD_ORD 'P0011', 'C0010', 5;
ADD_ORD 'P0014', 'C0006', 10;
ADD_ORD 'P0001', 'C0003', 50;
ADD_ORD 'P0007', 'C0008', 15;
ADD_ORD 'P0006', 'C0007', 10;
ADD_ORD 'P0013', 'C0001', 10;

----------------------------------------------------------------------------

UPDATE ORDERS SET OQTY = 40
WHERE OID = 'O0006';

----------------------------------------------------------------------------


SELECT * FROM PURCHASE;


----------------------------------------------------------------------------
-------CREATING A STORED PROCEDURE FOR CHECKING SUPPLIER OF A PRODUCT-------

CREATE PROCEDURE PRODUCT_SUPPLIERS
AS
BEGIN
	SELECT PID, PDESC, CATEGORY, SNAME, SCITY
	FROM PRODUCT
	INNER JOIN SUPPLIER
	ON PRODUCT.SID = SUPPLIER.SID;
END;

----------------------------------------------------------------------------

PRODUCT_SUPPLIERS

----------------------------------------------------------------------------
---CREATING A STORED PROCEDURE FOR VIEWING THE BILLS OF ALL ORDERS PLACED---


CREATE PROCEDURE VIEW_BILLS
AS
BEGIN
	SELECT OID, ODATE, CNAME, CADDR, CPHONE, PDESC, PRICE, OQTY, ORDERS.OQTY * PRODUCT.PRICE AS AMOUNT
	FROM ORDERS
	INNER JOIN PRODUCT
	ON ORDERS.PID = PRODUCT.PID
	INNER JOIN CUSTOMER
	ON ORDERS.CID = CUSTOMER.CID;
END;

----------------------------------------------------------------------------

VIEW_BILLS

----------------------------------------------------------------------------