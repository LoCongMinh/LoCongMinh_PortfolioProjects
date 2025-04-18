--- Cleaning Data in SQL

SELECT * FROM PortfolioProject..NashvilleHousing


--- Standardize Date Format

ALTER TABLE 
PortfolioProject..NashvilleHousing
ADD SaleDateConverted date

UPDATE	
PortfolioProject..NashvilleHousing
SET 
SaleDateConverted = CONVERT(date,Saledate)


SELECT SaleDateConverted 
FROM PortfolioProject..NashvilleHousing


--- Populate Property Address Data


SELECT PropertyAddress 
FROM PortfolioProject..NashvilleHousing
WHERE PropertyAddress IS NULL


SELECT 
	a.UniqueID,
	b.UniqueID,
	a.ParcelID,
	b.ParcelID,
	a.PropertyAddress,
	b.PropertyAddress,
	ISNULL(a.PropertyAddress,b.PropertyAddress) AS populatedAddress
--- ISNULL()returns value if the expression is NULL
FROM		PortfolioProject..NashvilleHousing a
JOIN		PortfolioProject..NashvilleHousing b
ON			a.ParcelID = b.ParcelID
WHERE		a.UniqueID <> b.UniqueID
AND			a.PropertyAddress IS NULL


UPDATE a
SET a.PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM		PortfolioProject..NashvilleHousing a
JOIN		PortfolioProject..NashvilleHousing b
ON			a.ParcelID = b.ParcelID
WHERE		a.UniqueID <> b.UniqueID
AND			a.PropertyAddress IS NULL


SELECT * FROM PortfolioProject..NashvilleHousing


--- Breaking out Address into Individual Collumn (Address, City, State)


SELECT PropertyAddress
FROM PortfolioProject..NashvilleHousing


SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress) -1) AS Address,  
--SUBSTRING(string, start, length)
SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress)) AS City
--LEN(string) return the length of a string
--LTRIM(),RTRIM() remove space if contained from Left,Right side of the string
--CHARINDEX() searches for a substring in a string, and returns the position
--LEFT(string, number_of_chars) extracts a number of characters from a string from left 
FROM PortfolioProject..NashvilleHousing


ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertySplitAddress NVARCHAR(500);
--- USE NVARCHAR(500) because 255 is not enough to fit all character


ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertySplitCity NVARCHAR(500);
--- USE NVARCHAR(500) because 255 is not enough to fit all character


--ALTER TABLE PortfolioProject..NashvilleHousing
--DROP COLUMN PropertySplitAddress


UPDATE PortfolioProject..NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)


UPDATE PortfolioProject..NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress)) 


SELECT * FROM PortfolioProject..NashvilleHousing


--- Split owner address using different way

SELECT 
	PARSENAME(REPLACE(OwnerAddress,',','.'),3),
	PARSENAME(REPLACE(OwnerAddress,',','.'),2),
	PARSENAME(REPLACE(OwnerAddress,',','.'),1)
FROM PortfolioProject..NashvilleHousing


ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(500);


ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitCity NVARCHAR(500);


ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitState NVARCHAR(500);


UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3)


UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)


UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)


SELECT * FROM PortfolioProject..NashvilleHousing


--- Change Y and N to Yes and No in "Sold as Vacant" field


SELECT 
	DISTINCT(SoldAsVacant),
	COUNT(SoldAsVacant)
FROM PortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2


UPDATE PortfolioProject..NashvilleHousing
SET
	SoldAsVacant = 
	CASE
		WHEN SoldAsVacant = 'N' THEN 'No'
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		ELSE SoldAsVacant
	END
FROM PortfolioProject..NashvilleHousing


--- Remove Duplicates


WITH RowNumCTE AS(
SELECT	*, 
		ROW_Number() OVER (PARTITION BY
		PropertyAddress,
		SalePrice,
		SaleDate,
		LegalReference
		ORDER BY UniqueID) AS RowNum
FROM	PortfolioProject..NashvilleHousing
) SELECT * FROM RowNumCTE  --- Replace SELECT with DELETE 
WHERE RowNum > 1


--- Delete unused collumn


SELECT * FROM PortfolioProject..NashvilleHousing
 

ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN SaleDate




