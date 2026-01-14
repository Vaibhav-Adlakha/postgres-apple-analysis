CREATE TABLE category(
	category_id VARCHAR (10) PRIMARY KEY,
	category_name VARCHAR (50)
);

CREATE TABLE stores(
	Store_ID VARCHAR(10) PRIMARY KEY,
	Store_Name VARCHAR(80),	
	City VARCHAR(80),
	Country VARCHAR(80)
);

CREATE TABLE products(
	Product_ID VARCHAR(10) PRIMARY KEY,
	Product_Name VARCHAR(50),
	Category_ID VARCHAR(10) REFERENCES category(category_id),
	Launch_Date	DATE,
	Price NUMERIC
);

CREATE TABLE sales(
	sale_id VARCHAR(25) PRIMARY KEY,	
	sale_date DATE,	
	store_id VARCHAR(10) REFERENCES stores(store_id),
	product_id VARCHAR(10) REFERENCES products(product_id),
	quantity INT
);

CREATE TABLE warranty(
	claim_id VARCHAR(25) PRIMARY KEY,
	claim_date DATE,
	sale_id	VARCHAR(25) REFERENCES sales(sale_id),
	repair_status VARCHAR(25)
);