/* COVID 19 DATA EXPLORATION

Skills used: Joins, CTE, Views, Temp Tables, Aggregations, Converting Data Types, Window Functions 

*/

-- First exploration of the death table to familiarize with the data

SELECT *
FROM CovidProject.dbo.CovidDeaths
ORDER BY 3,4

-- First exploration of the Vaccination table to familiarize with the data

SELECT *
FROM CovidProject.dbo.CovidVaccinations
ORDER BY 3,4

-- Selecting the data from the Death table that we're going to start our exploration with

SELECT 
		location,
		date,
		total_cases,
		new_cases,
		total_deaths,
		population
FROM
	CovidProject.dbo.CovidDeaths
ORDER BY 
	1,2


-- Total covid cases vs Total deaths
-- It shows likelihood of dying if you contract covid 

SELECT 
		location,
		date,
		total_cases,
		total_deaths,
		(CONVERT(FLOAT,total_deaths)/NULLIF(CONVERT(FLOAT,total_cases),0)) * 100 AS Death_Percentage
FROM
	CovidProject.dbo.CovidDeaths
ORDER BY 
	1,2

--Likelihood of dying because of Covid in the United States

SELECT 
		location,
		date,
		total_cases,
		total_deaths,
		(total_deaths/total_cases) * 100 AS Death_Percentage
FROM
	PortafolioProject.dbo.CovidDeaths
WHERE
	location LIKE '%States%'
ORDER BY 
	1,2

--Total Covid cases vs Population
-- This query shows the percentage of population that got covid in the United States.
-- To get the percentage in the whole population, we can comment out the filter in the WHERE clause

SELECT 
		location,
		date,
		population,
		total_cases,
		(total_cases/population) * 100 AS pop_rate_covid
FROM
	CovidProject.dbo.CovidDeaths
WHERE
	location LIKE '%States%'
ORDER BY 
	1,2


-- Countries with the Highest Infection Rate compared to Population

SELECT
	location,
	population,
	MAX(total_cases) AS Higes_tInfection_Count,
	ROUND(MAX((total_cases/population)) * 100,2) AS Perc_Pop_Infected
FROM
	CovidProject.dbo.CovidDeaths
GROUP BY 
	population,	
	location
ORDER BY 
	Perc_Pop_Infected DESC

-- Countries with the Highest Death Count per Population

SELECT
	location,
	MAX(cast(total_deaths as int)) AS Total_deaths_count
FROM
	CovidProject.dbo.CovidDeaths
WHERE
	continent IS NOT NULL
GROUP BY 	
	location
ORDER BY 
	Total_deaths_count DESC


-- Exploring the data in the Continent Level

-- Continent with the Higest Deaths Count

SELECT
	continent,
	MAX(cast(total_deaths as int)) AS Total_deaths_count
FROM
	CovidProject.dbo.CovidDeaths
WHERE
	continent IS NOT NULL
GROUP BY 	
	continent
ORDER BY 
	Total_deaths_count DESC

-- This query re-check the calculation above to take the correct calculation

SELECT
	location,
	MAX(cast(total_deaths as int)) AS Total_deaths_count
FROM
	CovidProject.dbo.CovidDeaths
WHERE
	continent IS NULL
GROUP BY 	
	location
ORDER BY 
	Total_deaths_count DESC


-- GLOBAL NUMBERS

-- Total cases, death and death percentage across the world by date

SELECT
	date,
	SUM(new_cases) AS Total_cases,
	SUM(CAST(new_deaths AS int)) AS Total_deaths,
	SUM(CAST(new_deaths AS int)) / SUM(new_cases) * 100 AS Death_Percentage
FROM
	CovidProject.dbo.CovidDeaths
WHERE
	continent IS NOT NULL
GROUP BY
	date
ORDER BY
	1,2

-- Total cases, death and death percentage across the world

SELECT
	SUM(new_cases) AS Total_cases,
	SUM(CAST(new_deaths AS int)) AS Total_deaths,
	SUM(CAST(new_deaths AS int)) / SUM(new_cases) * 100 AS Death_Percentage
FROM
	CovidProject.dbo.CovidDeaths
WHERE
	continent IS NOT NULL
ORDER BY
	1,2


-- Moving to explore the vaccionation table

-- Total population vs vaccionations

SELECT 
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_vaccinations,
FROM CovidProject.dbo.CovidDeaths AS d
JOIN CovidProject.dbo.CovidVaccinations AS v
	ON d.location = v.location 
	AND d.date = v.date
WHERE 
	d.continent IS NOT NULL
ORDER BY 
	2,3

-- Total population vs vaccionations rolling count by date and location
-- It shows the percentage of population that has received at least one shot of the Covid Vaccine

SELECT 
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_vaccinations,
	SUM(CAST(v.new_vaccinations AS int)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS Rolling_people_vaccinated_count
FROM CovidProject.dbo.CovidDeaths AS d
JOIN CovidProject.dbo.CovidVaccinations AS v
	ON d.location = v.location 
	AND d.date = v.date
WHERE 
	d.continent IS NOT NULL
ORDER BY 
	2,3

-- Population vs vaccionation CTE 
-- Using a CTE to perfom a calculation on partition by in the previous query

WITH popvsvac (continent, location, date, population, new_vaccionations, Rolling_people_vaccinated_count)
AS
(
SELECT 
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_vaccinations,
	SUM(CAST(v.new_vaccinations AS int)) OVER(PARTITION BY d.location ORDER BY d.location, d.date) AS Rolling_people_vaccinated_count
FROM CovidProject.dbo.CovidDeaths AS d
JOIN CovidProject.dbo.CovidVaccinations AS v
	ON d.location = v.location 
	AND d.date = v.date
WHERE 
	d.continent IS NOT NULL
)
SELECT *, ( Rolling_people_vaccinated_count / population) * 100 AS percentage_rolling_people_vaccinated
FROM popvsvac


-- Creating a Temp table to perfom calculaion on Partition by on the previous query

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
Rolling_people_vaccinated_count numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT 
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_vaccinations,
	SUM(CAST(v.new_vaccinations AS int)) OVER(PARTITION BY d.location ORDER BY d.location, d.date) AS Rolling_people_vaccinated_count
FROM CovidProject.dbo.CovidDeaths AS d
JOIN CovidProject.dbo.CovidVaccinations AS v
	ON d.location = v.location 
	AND d.date = v.date
WHERE 
	d.continent IS NOT NULL

SELECT *, (Rolling_people_vaccinated_count / population) * 100 AS perc_rolling_people_vaccinated
FROM #PercentPopulationVaccinated



-- Creating  a view to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS 
SELECT 
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_vaccinations,
	SUM(CAST(v.new_vaccinations AS int)) OVER(PARTITION BY d.location ORDER BY d.location, d.date) AS Rolling_people_vaccinated_count
FROM CovidProject.dbo.CovidDeaths AS d
JOIN CovidProject.dbo.CovidVaccinations AS v
	ON d.location = v.location 
	AND d.date = v.date
WHERE 
	d.continent IS NOT NULL

-- Querying the view that we just create

SELECT *
FROM PercentPopulationVaccinated