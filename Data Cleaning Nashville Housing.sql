
-- Taking a first look of the data set

SELECT * 
  FROM DataCleaning.dbo.NashvilleHousing;
  

-- 1.Standardize SaleDate Format from a timestamp to date

SELECT SaleDateConverted, 
	   CONVERT(Date,SaleDate)
  FROM DataCleaning.dbo.NashvilleHousing

-- First, we alter the table to add a new column
ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

-- Then, we aupdate the column we just created with the values we wan, in this case is the SaleDate in formart "YYYY-MM-DD"
UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate);


-- 2. Populate Property Address data. By using the ParceID colunm and a self joing, we can use the addresses that have the same parcelid but
-- different UniqueID, to fill the addresses that are null since is the same one.

SELECT a.ParcelID,
		a.PropertyAddress,
		b.ParcelID,
		b.PropertyAddress,
		ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM DataCleaning.dbo.NashvilleHousing AS a
	JOIN DataCleaning.dbo.NashvilleHousing AS b
		ON a.ParcelID = b.ParcelID
		AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL

-- After populate the addresses, we are going to update it on place.

UPDATE a 
SET PropertyAddress =  ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM DataCleaning.dbo.NashvilleHousing AS a
	JOIN DataCleaning.dbo.NashvilleHousing AS b
		ON a.ParcelID = b.ParcelID
		AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL


-- 3. Breaking out address into Individual Columns ( Address, City, State) by using SUBSTRING
-- The SUBSTRING function needs 3 values: The column that we want to separate values, in this case PropertyAddress,
-- The position of the firt value we want to separete, in this case 1 and the delimeter being either "," , space whichever the case
-- In this case is "," together with the function CHARINDEX. Since CHARINDEX give a position in number, we can use (-1) to avoid getting the "," 
-- in the address column.

SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address,
		SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS City
FROM DataCleaning.dbo.NashvilleHousing

-- After splitting the values in different columns, we are going to alter and update the table to add this columns

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress Nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) 

ALTER TABLE NashvilleHousing
ADD PropertyCity Nvarchar(255);

UPDATE NashvilleHousing
SET PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))

-- Cheking that the columns are added
SELECT *
FROM DataCleaning.dbo.NashvilleHousing


-- Let's  split the owner address in this case using PARSENAME.
-- PARSENAME take the column we want to split and the position. Something to consider is that this function look for periods and the position
-- start from the end. In this case, we have comas as delimeter, so we are going to replace it for periods to separate the address in diferent
-- columns. This approach is simplier that using SUBSTRING

SELECT 
		PARSENAME(REPLACE(OwnerAddress, ',' , '.'), 3),
		PARSENAME(REPLACE(OwnerAddress, ',' , '.'), 2),
		PARSENAME(REPLACE(OwnerAddress, ',' , '.'), 1)
FROM DataCleaning.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',' , '.'), 3)

ALTER TABLE NashvilleHousing
ADD OwnerCity Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',' , '.'), 2)

ALTER TABLE NashvilleHousing
ADD OwnerState Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerState = PARSENAME(REPLACE(OwnerAddress, ',' , '.'), 1)

--Lets check 

SELECT *
FROM DataCleaning.dbo.NashvilleHousing



--4. Change Y and N to Yes and No in "SoldAsVacant" Column by using a CASE statement
-- First, lets check the values that we want to change

SELECT 
		DISTINCT(SoldAsVacant), 
		COUNT(SoldAsVacant)
FROM DataCleaning.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

-- Now, let change Y and N for Yes and No to standardize this column

SELECT SoldAsVacant,
		CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END
FROM DataCleaning.dbo.NashvilleHousing

-- Updating the table 
UPDATE  NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
					WHEN SoldAsVacant = 'N' THEN 'No'
					ELSE SoldAsVacant
					END


--5. Removing Duplicates using windows functions to find where are duplicates values. In real life practice is not recommended to delete data
-- For this project purpose, we are doind it.

WITH CTE AS(
SELECT *,
		ROW_NUMBER() OVER (
		PARTITION BY ParcelID,
					 PropertyAddress,
					 SalePrice,
					 SaleDate,
					 LegalReference
					 ORDER BY 
						UniqueID
						) AS row_num
FROM DataCleaning.dbo.NashvilleHousing
)
DELETE
FROM CTE
WHERE row_num > 1
--ORDER BY PropertyAddress


--6.Deleting unused columns and duplicate columns. In real world practice, this method is not used without authorization. 
-- It is never a good idea to delete data from our raw data or database. An alternative is to use views.

ALTER TABLE DataCleaning.dbo.NashvilleHousing
DROP COLUMN OwnerAddress,
			TaxDistrict,
			PropertyAddress,
			SaleDate

SELECT *
FROM DataCleaning.dbo.NashvilleHousing
