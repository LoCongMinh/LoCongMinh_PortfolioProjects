
SELECT *
FROM PortfolioProject.dbo.Covidfulldata


--- Create a new collumn called DateCoverted


ALTER TABLE 
	PortfolioProject.dbo.fulldata
ADD 
	DateConverted date --- Data type is date


SELECT 
	DateConverted
FROM
	PortfolioProject.dbo.fulldata


--- Convert date to normal format

	
UPDATE 
	PortfolioProject.dbo.fulldata
SET
	DateConverted = CONVERT(DATE,date)


--- Calculate Death% per day in US Fulldata


SELECT		continent, location, ConvertedDate, population, total_cases, total_deaths,
		CONCAT(ROUND(((total_deaths / total_cases)*100),2), '%') AS DeathPercentage
FROM		PortfolioProject..Covidfulldata
WHERE		location = 'United States'
		AND ConvertedDate >= '2024-01-01'
ORDER BY	ConvertedDate


--- Compare Total Cases with Population -> Expose rate


SELECT		continent, location, ConvertedDate, population, total_cases, 
		CONCAT(ROUND(((total_cases/population)*100),2), '%') AS ExposeRate
FROM		PortfolioProject..Covidfulldata
WHERE		location = 'Vietnam'
		AND ConvertedDate >= '2024-01-01'
ORDER BY	ConvertedDate


-- Country with highest infection rate

SELECT
	continent,
	location, 
	population,
	MAX(total_cases) AS HighestCovidCases, 
	ROUND((MAX(total_cases)/population*100),2) AS HighestExposeRate
FROM
PortfolioProject..Covidfulldata
WHERE		continent IS NOT NULL --- In our full data there is line grouped by a whole continent
GROUP BY	continent, location, population
ORDER BY	HighestExposeRate DESC


--- Showing countries with highest death count


SELECT
	continent,
	location,
	population,
	MAX(total_deaths) AS HighestDeathCount, 
	ROUND((MAX(total_deaths)/population*100),2) AS DeathPercentage
FROM
	PortfolioProject..Covidfulldata
WHERE		continent IS NOT NULL --- In our full data there is line grouped by a whole continent
GROUP BY	continent, location, population
ORDER BY	HighestDeathCount DESC


--- Breaking down by continent

SELECT
	continent,
	MAX(total_deaths) AS HighestDeathCount
FROM
	PortfolioProject..Covidfulldata
WHERE		continent IS NOT NULL
GROUP BY	continent
ORDER BY	HighestDeathCount DESC


--- Global Number

SELECT		
	SUM(new_cases) AS TOTAL_CASES, 
	SUM(new_deaths) AS TOTAL_DEATHS,
	CONCAT(ROUND((SUM(new_deaths)/SUM(new_cases)*100),2),'%') AS TotalDeathPercentage
FROM		PortfolioProject..Covidfulldata
WHERE		continent IS NOT NULL


-- Looking at total population vs vaccination

SELECT
	continent,
	location,
	ConvertedDate,
	population,
	new_vaccinations,
	SUM(CAST(new_vaccinations AS BIGINT)) OVER (PARTITION BY location ORDER BY location, ConvertedDate) AS VaccinatedCumulative
FROM	PortfolioProject..Covidfulldata
WHERE	continent IS NOT NULL


-- Adding CTE to calculate Vaccinated vs Population % 

	
WITH VacvsPop (continent, location, ConvertedDate, population, new_vaccinations, VaccinatedCumulative)
AS (
SELECT
	continent,
	location,
	ConvertedDate,
	population,
	new_vaccinations,
	SUM(CAST(new_vaccinations AS BIGINT)) OVER (PARTITION BY location ORDER BY location, ConvertedDate) AS VaccinatedCumulative
FROM	PortfolioProject..Covidfulldata
WHERE	continent IS NOT NULL
)

SELECT *, (VaccinatedCumulative/population)*100 AS VaccinatedPercentageCummulative
FROM VacvsPop


--- Create Temp Table

	
DROP TABLE if exists #PercentPopulationVaccinated

CREATE TABLE #PercentPopulationVaccinated (
	continent nvarchar(255),
	location nvarchar(255),
	ConvertedDate datetime,
	Population numeric,
	new_vaccinations numeric,
	VaccinatedCumulative numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT
		continent,
		location,
		ConvertedDate,
		population,
		new_vaccinations,
		SUM(CAST(new_vaccinations AS BIGINT)) OVER (PARTITION BY location ORDER BY location, ConvertedDate) AS VaccinatedCumulative
FROM	PortfolioProject..Covidfulldata
WHERE	continent IS NOT NULL

SELECT *, (VaccinatedCumulative/population)*100 AS VaccinatedPercentageCummulative
FROM #PercentPopulationVaccinated


--- Creating Views to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated as
SELECT
		continent,
		location,
		ConvertedDate,
		population,
		new_vaccinations,
		SUM(CAST(new_vaccinations AS BIGINT)) OVER (PARTITION BY location ORDER BY location, ConvertedDate) AS VaccinatedCumulative
FROM	PortfolioProject..Covidfulldata
WHERE	continent IS NOT NULL


SELECT * FROM PercentPopulationVaccinated
