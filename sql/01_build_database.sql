
/*
--Foreign key
ALTER TABLE Rosters DROP CONSTRAINT FK_Rosters_Sizes;
ALTER TABLE Products DROP CONSTRAINT FK_Products_SportField;
ALTER TABLE Addresses DROP CONSTRAINT FK_Addresses_Country;
ALTER TABLE Orders DROP CONSTRAINT FK_Orders_ShippingCountry;
ALTER TABLE Addresses DROP CONSTRAINT FK_Addresses_City;
ALTER TABLE Orders DROP CONSTRAINT FK_Orders_ShippingCity;
ALTER TABLE Reviews DROP CONSTRAINT FK_Reviews_Stars;
ALTER TABLE Designs DROP CONSTRAINT FK_Designs_Color;

--check constraint
ALTER TABLE Orders DROP CONSTRAINT CK_Orders_CardCVV_Length;
ALTER TABLE Carts DROP CONSTRAINT CK_Carts_TotalAmount_Positive;
ALTER TABLE Rosters DROP CONSTRAINT CK_Rosters_PieceQuantity_Positive;
ALTER TABLE Customers DROP CONSTRAINT CK_Customers_EmailFormat;
ALTER TABLE Customers DROP CONSTRAINT CK_Customers_PhoneFormat;
ALTER TABLE Orders DROP CONSTRAINT CK_Orders_CardExp_Valid;
ALTER TABLE Orders DROP CONSTRAINT CK_Orders_CardNumber_Format;
ALTER TABLE Orders DROP CONSTRAINT CK_Orders_ZipCode_Valid;
ALTER TABLE Addresses DROP CONSTRAINT CK_Addresses_ZipCode_Valid;

*/


DROP TABLE IF EXISTS Reviews;
DROP TABLE IF EXISTS Rosters;
DROP TABLE IF EXISTS Designs;
DROP TABLE IF EXISTS ProductDetails;
DROP TABLE IF EXISTS Orders;
DROP TABLE IF EXISTS GuestCustomers;
DROP TABLE IF EXISTS UserAddresses;
DROP TABLE IF EXISTS Carts;
DROP TABLE IF EXISTS UserCustomers;
DROP TABLE IF EXISTS Customers;
DROP TABLE IF EXISTS Addresses;
DROP TABLE IF EXISTS Products;
DROP TABLE IF EXISTS Sizes;
DROP TABLE IF EXISTS SportFields;
DROP TABLE IF EXISTS Countries;
DROP TABLE IF EXISTS Cities;
DROP TABLE IF EXISTS RatingScale;
DROP TABLE IF EXISTS Colors;
DROP TABLE IF EXISTS Months;



CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY,
    Email VARCHAR(40) NOT NULL,
	Phone VARCHAR(15),
    FirstName VARCHAR(20),
    LastName VARCHAR(20)
);

CREATE TABLE UserCustomers (
    CustomerID INT NOT NULL PRIMARY KEY ,
	UserName VARCHAR(40) NOT NULL,
	Password VARCHAR(255) NOT NULL,
	createdAt DATETIME,
	lastLogin DATETIME,
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);


CREATE TABLE Addresses (
    AddressID INT PRIMARY KEY,
    ZipCode VARCHAR(10),
    Country VARCHAR(50),
    City VARCHAR(50),
    Street VARCHAR(100)
);



CREATE TABLE UserAddresses (
    CustomerID INT NOT NULL,
    AddressID INT,
    PRIMARY KEY (CustomerID, AddressID),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    FOREIGN KEY (AddressID) REFERENCES Addresses(AddressID)
);

CREATE TABLE Carts (
    CartID INT PRIMARY KEY,
    CustomerID INT,
	createdAt DATETIME,
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);

CREATE TABLE Orders (
    OrderID INT PRIMARY KEY,
    OrderDate DATETIME,
    ShippingCountry VARCHAR(50),
    ShippingCity VARCHAR(50),
    ShippingStreet VARCHAR(100),
    ShippingZipCode VARCHAR(10),
    CardNumber VARCHAR(20),
    CardExpDate Date,
    CardCVV VARCHAR(4),
    CartID INT,
    FOREIGN KEY (CartID) REFERENCES Carts(CartID)
);

CREATE TABLE Products (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(50),
    SportField VARCHAR(30),
    UnitPrice MONEY
);

CREATE TABLE ProductDetails (
    ProductDetail VARCHAR(255),
    ProductID INT,
    PRIMARY KEY (ProductDetail, ProductID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

CREATE TABLE Reviews (
    CustomerID INT,
    ProductID INT,
    ReviewDate DATE,
    StarAmount TINYINT,
    ReviewText NVARCHAR(MAX),
    PRIMARY KEY (CustomerID, ProductID),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

CREATE TABLE Designs (
    ProductID INT,
    DesignID INT,
    Color VARCHAR(30),
    Logo VARCHAR(100),
    DesignText VARCHAR(255),
    PRIMARY KEY (ProductID, DesignID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

CREATE TABLE Rosters (
    ProductID INT,
    DesignID INT,
    CartID INT,
    PieceSize VARCHAR(8),
    PieceQuantity INT,
    PRIMARY KEY (ProductID, DesignID, CartID, PieceSize),
    FOREIGN KEY (ProductID, DesignID) REFERENCES Designs(ProductID, DesignID),
    FOREIGN KEY (CartID) REFERENCES Carts(CartID)
);

CREATE TABLE Sizes (
    SizeCode VARCHAR(8) PRIMARY KEY,
    Description VARCHAR(50)
);

CREATE TABLE SportFields (
    SportCode VARCHAR(30) PRIMARY KEY,
    Description VARCHAR(100)
);

CREATE TABLE Countries (
    CountryName VARCHAR(50) PRIMARY KEY
);

CREATE TABLE Cities (
    CityName VARCHAR(50) PRIMARY KEY
);

CREATE TABLE RatingScale (
    StarAmount TINYINT PRIMARY KEY
);


CREATE TABLE Colors (
    ColorName VARCHAR(30) PRIMARY KEY
);


ALTER TABLE Rosters
ADD CONSTRAINT FK_Rosters_Sizes
FOREIGN KEY (PieceSize) REFERENCES Sizes(SizeCode);

ALTER TABLE Products
ADD CONSTRAINT FK_Products_SportField
FOREIGN KEY (SportField) REFERENCES SportFields(SportCode);

ALTER TABLE Addresses
ADD CONSTRAINT FK_Addresses_Country
FOREIGN KEY (Country) REFERENCES Countries(CountryName);

ALTER TABLE Orders
ADD CONSTRAINT FK_Orders_ShippingCountry
FOREIGN KEY (ShippingCountry) REFERENCES Countries(CountryName);

ALTER TABLE Addresses
ADD CONSTRAINT FK_Addresses_City
FOREIGN KEY (City) REFERENCES Cities(CityName);

ALTER TABLE Orders
ADD CONSTRAINT FK_Orders_ShippingCity
FOREIGN KEY (ShippingCity) REFERENCES Cities(CityName);

ALTER TABLE Reviews
ADD CONSTRAINT FK_Reviews_Stars
FOREIGN KEY (StarAmount) REFERENCES RatingScale(StarAmount);

ALTER TABLE Designs
ADD CONSTRAINT FK_Designs_Color
FOREIGN KEY (Color) REFERENCES Colors(ColorName);

ALTER TABLE Orders
ADD CONSTRAINT CK_Orders_CardCVV_Length
CHECK (LEN(CardCVV) IN (3, 4));


--check with email
/*ALTER TABLE Carts
ADD CONSTRAINT CK_Carts_TotalAmount_Positive
CHECK (TotalAmount >= 0);
*/


ALTER TABLE Rosters
ADD CONSTRAINT CK_Rosters_PieceQuantity_Positive
CHECK (PieceQuantity >= 1);

ALTER TABLE Customers
ADD CONSTRAINT CK_Customers_EmailFormat
CHECK (Email LIKE '%@%.%' AND CHARINDEX(' ', Email) = 0);

ALTER TABLE Customers
ADD CONSTRAINT CK_Customers_PhoneFormat
CHECK (Phone LIKE '05%' AND LEN(Phone) = 10 AND Phone NOT
LIKE '%[^0-9]%');

ALTER TABLE Orders
ADD CONSTRAINT CK_Orders_CardExp_Valid
CHECK (Year(CardExpDate) > YEAR(GETDATE()) OR (Year(CardExpDate) = YEAR(GETDATE()) AND Month(CardExpDate) >= MONTH(GETDATE())));

ALTER TABLE Orders
ADD CONSTRAINT CK_Orders_CardNumber_Format
CHECK (CardNumber NOT LIKE '%[^0-9]%');

ALTER TABLE Orders
ADD CONSTRAINT CK_Orders_ZipCode_Valid
CHECK (ShippingZipCode LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9]');

ALTER TABLE Addresses
ADD CONSTRAINT CK_Addresses_ZipCode_Valid
CHECK (ZipCode LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9]');


INSERT INTO Sizes (SizeCode, Description) VALUES
('XS', 'Extra Small'),
('S', 'Small'),
('M', 'Medium'),
('L', 'Large'),
('XL', 'Extra Large'),
('XXL', 'Double Extra Large'),
('XXXL', 'Triple Extra Large');

INSERT INTO SportFields (SportCode, Description) VALUES
('SOCCER', 'Soccer'),
('BASKETBALL', 'Basketball'),
('CYCLING', 'Cycling'),
('ESPORTS', 'Esports'),
('YOGA', 'Yoga'),
('RUNNING', 'Running'),
('SWIMMING', 'Swimming');



INSERT INTO RatingScale (StarAmount) VALUES
(1),(2),(3),(4),(5);


INSERT INTO Colors (ColorName) VALUES
('Red'),
('Blue'),
('Green'),
('Black'),
('White'),
('Yellow'),
('Purple'),
('Orange');