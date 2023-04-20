--Data Cleaning by SQL
/*
We learn by doing what to do
But We learn more by doing what not to do
Thus, this project does not conceal the mistakes 
committed while undertaking this project.
My only aim is to learn from the mistake that I commit and 
do not repeat the same mistake twice.
This way mistakes will eventually keep on reducing and I will get better at it
*/

-- Creating a structure of the table matching with the excel file
DROP TABLE IF EXISTS Nashville_housing;
CREATE TABLE Nashville_housing(
	UniqueID INTEGER,
	ParcelID VARCHAR(50),
	LandUse VARCHAR(100),
	PropertyAddress VARCHAR(250),
	SaleDate DATE,
	SalePrice TEXT,
	LegalReference VARCHAR(100),
	SoldAsVacant VARCHAR(10),
	OwnerName VARCHAR(100),
	OwnerAddress VARCHAR(250),
	Acreage FLOAT,
	TaxDistrict VARCHAR(100),
	LandValue INTEGER,
	BuildingValue INTEGER,
	TotalValue INTEGER,
	YearBuilt VARCHAR(10),
	Bedrooms SMALLINT,
	FullBath SMALLINT,
	HalfBath SMALLINT
);

-- Copying Data from the excel (csv) file
COPY Nashville_housing FROM 'Y:\Data\Projects\SQL\Data Cleaning\Nashville Housing Data.csv'
DELIMITER ',' CSV HEADER
SELECT COUNT(*) FROM Nashville_housing

--1. Standardising the Date Format
UPDATE nashville_housing
SET saledate = CAST (saledate AS DATE)
--2. Populating the property address based on parcel ID
SELECT * FROM nashville_housing
WHERE propertyaddress IS null

--Self Joining to populate the propertyaddress
SELECT a. parcelid, b.parcelid,a.propertyaddress, b.propertyaddress
FROM nashville_housing a JOIN nashville_housing b
ON a. parcelid = b. parcelid 
AND a.uniqueid <> b.uniqueid-- This ensures that its the not the same row
WHERE a.propertyaddress IS null
/*
Somehow the values of all the rows corresponding to 
propertyaddress became null. To rectify this, instead of
updating the entire table from the excel file again, 
the best method I felt was to create a temporary file and 
populate it with the excel file data.
Then UPDATE JOIN was used to repopulate propertyadress values
in the main table from the temporary table.
This can be seen the queries that follow.
What I (re)learnt in the process is that while INSERT commnad 
adds rows in the original table, the UPDATE command chnages (updates)
the present values of the table.
*/

DROP TABLE IF EXISTS t;
CREATE TEMPORARY TABLE t (
	UniqueID INTEGER,
	ParcelID VARCHAR(50),
	LandUse VARCHAR(100),
	PropertyAddress VARCHAR(250),
	SaleDate DATE,
	SalePrice TEXT,
	LegalReference VARCHAR(100),
	SoldAsVacant VARCHAR(10),
	OwnerName VARCHAR(100),
	OwnerAddress VARCHAR(250),
	Acreage FLOAT,
	TaxDistrict VARCHAR(100),
	LandValue INTEGER,
	BuildingValue INTEGER,
	TotalValue INTEGER,
	YearBuilt VARCHAR(10),
	Bedrooms SMALLINT,
	FullBath SMALLINT,
	HalfBath SMALLINT
);
COPY t FROM 'Y:\Data\Projects\SQL\Data Cleaning\Nashville Housing Data.csv'
DELIMITER ',' CSV HEADER;

SELECT * FROM t 

-- A few failed attempts follow
INSERT INTO nashville_housing (propertyaddress)
SELECT propertyaddress FROM t

INSERT INTO nashville_housing
SELECT FROM t
SELECT * FROM nashville_housing
WHERE uniqueid <> null

SELECT COUNT(*) FROM nashville_housing
WHERE propertyaddress <> null

ALTER TABLE nashville_housing
DROP propertyaddress

SELECT * FROM nashville_housing

ALTER TABLE nashville_housing
ADD propertyaddress VARCHAR(250)

--The following method finally worked (UPDATE JOIN)
UPDATE nashville_housing
SET propertyaddress = t.propertyaddress
FROM t
WHERE nashville_housing.uniqueid = t.uniqueid

SELECT * FROM nashville_housing

--Following query populates the empty values in propertyaddress(Unsolved)
SELECT a. parcelid, b.parcelid,a.propertyaddress, b.propertyaddress, 
COALESCE(a.propertyaddress, b.propertyaddress) address
FROM nashville_housing a JOIN nashville_housing b
ON a. parcelid = b. parcelid 
AND a.uniqueid <> b.uniqueid
WHERE a.propertyaddress IS null

UPDATE nashville_housing
SET propertyaddress = COALESCE(a.propertyaddress, MAX(b.propertyaddress))
FROM nashville_housing a 
JOIN nashville_housing b
ON a. parcelid = b. parcelid 
AND a.uniqueid != b.uniqueid
WHERE a.propertyaddress IS null

SELECT * FROM nashville_housing
WHERE propertyaddress IS null
SELECT * FROM t

UPDATE nashville_housing
SET propertyaddress = t.propertyaddress
FROM t
WHERE nashville_housing.uniqueid = t. uniqueid
-- Trying with CASE statements
UPDATE nashville_housing
SET propertyaddress = CASE WHEN a.propertyaddress IS null 
						   THEN b.propertyaddress
						END
FROM nashville_housing a 
JOIN nashville_housing b
ON a. parcelid = b. parcelid 
AND a.uniqueid != b.uniqueid
WHERE a.propertyaddress IS null

SELECT CASE WHEN a.propertyaddress IS null 
						   THEN b.propertyaddress
						END
FROM nashville_housing a 
JOIN nashville_housing b
ON a. parcelid = b. parcelid 
AND a.uniqueid != b.uniqueid
WHERE a.propertyaddress IS null




--3.Breaking out address into address, state  and city
SELECT * FROM nashville_housing

SELECT
SUBSTRING(propertyaddress,1,POSITION(',' IN propertyaddress)-1) Address,
SUBSTRING(propertyaddress, STRPOS(propertyaddress, ',')+1, LENGTH(propertyaddress)) state
FROM nashville_housing

-- Adding new columns for split address and split city of property address
ALTER TABLE nashville_housing
ADD address_split VARCHAR(250),
ADD city_split VARCHAR (100)

--Updating the address and city names of property address
UPDATE nashville_housing
	SET 
	address_split = 
	SUBSTRING(propertyaddress,1,POSITION(',' IN propertyaddress)-1),
	city_split = 
	SUBSTRING(propertyaddress, POSITION(',' IN propertyaddress)+1, LENGTH(propertyaddress))
	
SELECT * FROM nashville_housing

--Renaming the newly created columns 
/*(Renaming Multiple columns in one statement is not supported
 Hence the following query does not work
)*/
ALTER TABLE nashville_housing
RENAME
	COLUMN city_split TO property_city_split,
	COLUMN address_split TO property_address_split
	
ALTER TABLE nashville_housing
RENAME COLUMN city_split TO property_city_split
	
ALTER TABLE nashville_housing
RENAME COLUMN address_split TO property_address_split

SELECT * FROM nashville_housing
LIMIT 10

--Splitting Owner Address into address, city and state
SELECT owneraddress
FROM nashville_housing
SELECT
	SPLIT_PART(owneraddress,',',1) owner_address_split,
	SPLIT_PART(owneraddress,',',2) owner_city_split,
	SPLIT_PART(owneraddress,',',3) owner_state_split
FROM nashville_housing

-- Adding new columns for split address, split city and split state for owner address
ALTER TABLE nashville_housing
ADD owner_address_split VARCHAR(250),
ADD owner_city_split VARCHAR (100),
ADD owner_state_split VARCHAR (100)

-- Updating the new columns of split address, split city and split state for owner address
UPDATE nashville_housing
SET 
	owner_address_split =SPLIT_PART(owneraddress,',',1),
	owner_city_split = SPLIT_PART(owneraddress,',',2),
	owner_state_split = SPLIT_PART(owneraddress,',',3)
	
SELECT * FROM nashville_housing
LIMIT 10

--4. Changing 'Y' to 'Yes' and 'N' to 'No'
SELECT soldasvacant, COUNT(soldasvacant)
FROM nashville_housing
GROUP BY soldasvacant
ORDER BY 2


SELECT soldasvacant,
CASE
	WHEN soldasvacant = 'Y' THEN 'Yes'
	WHEN soldasvacant ='N' THEN 'No'
	ELSE soldasvacant
END
FROM nashville_housing
--Updating the Values of 'Y' as 'Yes' and 'N' as 'No'
UPDATE nashville_housing
SET soldasvacant=
	CASE
	WHEN soldasvacant = 'Y' THEN 'Yes'
	WHEN soldasvacant ='N' THEN 'No'
	ELSE soldasvacant
END
-- Confirming that the change has taken place
SELECT soldasvacant, COUNT(soldasvacant)
FROM nashville_housing
GROUP BY soldasvacant
ORDER BY 2

--5. Remove Duplicates(Not a common practice to remove data from the database)
-- DELETE clause does not work with CTE in PostgreSQL
/*
WITH duplicate_cte AS
(SELECT *,
ROW_NUMBER() OVER 
(PARTITION BY parcelid, propertyaddress, saledate, saleprice,legalreference ) row_num
FROM
nashville_housing)
SELECT * FROM duplicate_cte
WHERE row_num >1

WITH duplicate_cte AS
(SELECT parcelid
FROM
(SELECT *,
ROW_NUMBER() OVER 
(PARTITION BY parcelid, propertyaddress, saledate, saleprice,legalreference ) row_num
FROM
nashville_housing)t
WHERE row_num>1) 
SELECT 
FROM nashville_housing
WHERE parcelid IN(SELECT * FROM duplicate_cte) */

--The task of removing duplicates is thus performed by using subquery
SELECT * FROM nashville_housing
WHERE uniqueid IN(
	SELECT 
	uniqueid
	FROM
		(SELECT *, ROW_NUMBER() OVER
		(PARTITION BY parcelid, propertyaddress, saledate, saleprice,legalreference)row_num
		FROM nashville_housing 
		) t
	WHERE row_num >1
)

DELETE FROM nashville_housing
WHERE uniqueid IN(
	SELECT 
	uniqueid
	FROM
		(SELECT *, ROW_NUMBER() OVER
		(PARTITION BY parcelid, propertyaddress, saledate, saleprice,legalreference)row_num
		FROM nashville_housing 
		) t
	WHERE row_num >1
)

--6. Deleting redundant columns
ALTER TABLE nashville_housing
DROP taxdistrict,
DROP propertyaddress


SELECT * FROM nashville_housing

