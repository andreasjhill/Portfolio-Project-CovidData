--review

SELECT *
FROM COVIDDEATHS
ORDER BY 3,4 -----------------------------------------------------------------------------------------------
--review

SELECT *
FROM COVIDVACCINATIONS
ORDER BY 3,4 -----------------------------------------------------------------------------------------------

SELECT LOCATION, date, TOTAL_CASES,
	NEW_CASES,
	TOTAL_DEATHS,
	POPULATION
FROM COVIDDEATHS
ORDER BY 3,4 -----------------------------------------------------------------------------------------------
--total cases vs total deaths

SELECT LOCATION, date, TOTAL_CASES,
	TOTAL_DEATHS,
	(TOTAL_DEATHS::float / TOTAL_CASES::float) * 100 AS DEATH_PERCENTAGE
FROM COVIDDEATHS
WHERE LOCATION like '%States%'
ORDER BY 3,4 -----------------------------------------------------------------------------------------------
--total cases vs population

SELECT LOCATION, date, POPULATION,
	TOTAL_CASES,
	(TOTAL_CASES::float / POPULATION::float) * 100 AS PERCENT_POPULATION_INFECTED
FROM COVIDDEATHS --where location like '%States%'
ORDER BY 1,2 -----------------------------------------------------------------------------------------------
--countries with highest infection rates

SELECT LOCATION,
	POPULATION,
	MAX(TOTAL_CASES) AS HIGHEST_INFECTION_COUNT,
	MAX((TOTAL_CASES::float / POPULATION::float)) * 100 AS PERCENT_POPULATION_INFECTED
FROM COVIDDEATHS --where location like '%States%'
GROUP BY LOCATION,
	POPULATION
HAVING MAX(TOTAL_CASES) IS NOT NULL
ORDER BY PERCENT_POPULATION_INFECTED DESC -----------------------------------------------------------------------------------------------
--countries with highest death rates

SELECT LOCATION,
	MAX(CAST(TOTAL_DEATHS AS int)) AS TOTAL_DEATH_COUNT
FROM COVIDDEATHS -- WHERE Location LIKE '%States%'

WHERE CONTINENT IS NOT NULL
GROUP BY LOCATION
HAVING MAX(TOTAL_DEATHS) IS NOT NULL
ORDER BY TOTAL_DEATH_COUNT DESC;

-----------------------------------------------------------------------------------------------
--continental data

SELECT CONTINENT,
	MAX(CAST(TOTAL_DEATHS AS int)) AS TOTAL_DEATH_COUNT
FROM COVIDDEATHS -- WHERE Location LIKE '%States%'

WHERE CONTINENT IS NOT NULL
GROUP BY CONTINENT
HAVING MAX(TOTAL_DEATHS) IS NOT NULL
ORDER BY TOTAL_DEATH_COUNT DESC;

-----------------------------------------------------------------------------------------------
--GLOBAL NUMBERS

SELECT --date,
 SUM(NEW_CASES) AS TOTAL_CASES,
	SUM(CAST(NEW_DEATHS AS INT)) AS TOTAL_DEATHS,
	CASE
					WHEN SUM(NEW_CASES) = 0 THEN NULL
					ELSE SUM(CAST(NEW_DEATHS AS INT)) / SUM(NEW_CASES) * 100
	END AS DEATH_PERCENTAGE
FROM COVIDDEATHS
WHERE CONTINENT IS NOT NULL --GROUP BY
 --date
ORDER BY 1,2 -----------------------------------------------------------------------------------------------
--Joining Covid Deaths and Covid Vaccination datasets

SELECT *
FROM COVIDDEATHS DEA
JOIN COVIDVACCINATIONS VAC ON DEA.LOCATION = VAC.LOCATION
AND DEA.DATE = VAC.DATE -----------------------------------------------------------------------------------------------
--seeing the vaccination total (rolling)

SELECT DEA.CONTINENT,
	DEA.LOCATION,
	DEA.DATE,
	DEA.POPULATION,
	VAC.NEW_VACCINATIONS,
	SUM(CAST(VAC.NEW_VACCINATIONS AS int)) OVER (PARTITION BY DEA.LOCATION
																																														ORDER BY DEA.LOCATION,
																																															DEA.DATE) AS PEOPLE_VACCINATED_ROLLING,
FROM COVIDDEATHS DEA
JOIN COVIDVACCINATIONS VAC ON DEA.LOCATION = VAC.LOCATION
AND DEA.DATE = VAC.DATE
WHERE DEA.CONTINENT IS NOT NULL
ORDER BY 2,3 
-----------------------------------------------------------------------------------------------
--USE CTE
WITH POPVSVAC (CONTINENT,

							LOCATION, date, POPULATION,

							NEW_VACCINATIONS,
							PEOPLE_VACCINATED_ROLLING) AS
	(SELECT DEA.CONTINENT,
			DEA.LOCATION,
			DEA.DATE,
			DEA.POPULATION,
			VAC.NEW_VACCINATIONS,
			SUM(CAST(VAC.NEW_VACCINATIONS AS int)) OVER (PARTITION BY DEA.LOCATION
																																																ORDER BY DEA.LOCATION,
																																																	DEA.DATE) AS PEOPLE_VACCINATED_ROLLING
		FROM COVIDDEATHS DEA
		JOIN COVIDVACCINATIONS VAC ON DEA.LOCATION = VAC.LOCATION
		AND DEA.DATE = VAC.DATE
		WHERE DEA.CONTINENT IS NOT NULL --order by 2,3
)
SELECT *,
	(PEOPLE_VACCINATED_ROLLING:: numeric / POPULATION::numeric) * 100 AS PERCENTAGE_VACCINATED_ROLLING
FROM POPVSVAC;

-- USE TEMP TABLE

drop table if exists percentpopulationvaccinated
create table percentpopulationvaccinated (
	continent varchar(255),
	location varchar(255),
	date date,
	population numeric,
	new_vaccinations numeric,
	people_vaccinated_rolling numeric
);

INSERT INTO PERCENTPOPULATIONVACCINATED
SELECT DEA.CONTINENT,
	DEA.LOCATION,
	DEA.DATE,
	DEA.POPULATION,
	VAC.NEW_VACCINATIONS,
	SUM(CAST(VAC.NEW_VACCINATIONS AS int)) OVER (PARTITION BY DEA.LOCATION order by dea.location, dea.date) as PEOPLE_VACCINATED_ROLLING

FROM COVIDDEATHS DEA
JOIN COVIDVACCINATIONS VAC ON DEA.LOCATION = VAC.LOCATION
AND DEA.DATE = VAC.DATE; --WHERE DEA.CONTINENT IS NOT NULL --order by 2,3

SELECT *, (PEOPLE_VACCINATED_ROLLING:: numeric / POPULATION::numeric) * 100 AS PERCENTAGE_VACCINATED_ROLLING
FROM PERCENTPOPULATIONVACCINATED;

-----------------------------------------------------------------------------------------------
--create view to store date for later visualization

create view PERCENTPOPULATIONVACCINATED_view as
SELECT 
	DEA.CONTINENT,
	DEA.LOCATION,
	DEA.DATE,
	DEA.POPULATION,
	VAC.NEW_VACCINATIONS,
	SUM(CAST(VAC.NEW_VACCINATIONS AS int)) OVER (PARTITION BY DEA.LOCATION order by dea.location, dea.date) 
	as PEOPLE_VACCINATED_ROLLING

FROM COVIDDEATHS DEA
JOIN COVIDVACCINATIONS VAC ON DEA.LOCATION = VAC.LOCATION
AND DEA.DATE = VAC.DATE
WHERE DEA.CONTINENT IS NOT NULL;