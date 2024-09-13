/*
Covid 19 Data Exploration 

Skills used: Joins, CTEs, Temp Tables, Window Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

-- Select all records from CovidDeaths table where continent is not null
Select *
From CovidDeaths
Where continent is not null 
Order by 3, 4;


-- Select Data that we are going to be starting with
Select Location, date, total_cases, new_cases, total_deaths, population
From CovidDeaths
Where continent is not null 
Order by 1, 2;


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
Select Location, date, total_cases, total_deaths, 
       (total_deaths * 1.0 / total_cases) * 100 as DeathPercentage
From CovidDeaths
Where location like '%states%'
  and continent is not null 
Order by 1, 2;


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid
Select Location, date, Population, total_cases, 
       (total_cases * 1.0 / population) * 100 as PercentPopulationInfected
From CovidDeaths
Order by 1, 2;


-- Countries with Highest Infection Rate compared to Population
Select Location, Population, 
       MAX(total_cases) as HighestInfectionCount,  
       MAX((total_cases * 1.0 / population)) * 100 as PercentPopulationInfected
From CovidDeaths
Group by Location, Population
Order by PercentPopulationInfected desc;


-- Countries with Highest Death Count per Population
Select Location, MAX(CAST(Total_deaths as INTEGER)) as TotalDeathCount
From CovidDeaths
Where continent is not null 
Group by Location
Order by TotalDeathCount desc;


-- BREAKING THINGS DOWN BY CONTINENT
-- Showing continents with the highest death count per population
Select continent, MAX(CAST(Total_deaths as INTEGER)) as TotalDeathCount
From CovidDeaths
Where continent is not null 
Group by continent
Order by TotalDeathCount desc;


-- GLOBAL NUMBERS
Select SUM(new_cases) as total_cases, 
       SUM(CAST(new_deaths as INTEGER)) as total_deaths, 
       (SUM(CAST(new_deaths as INTEGER)) * 1.0 / SUM(New_Cases)) * 100 as DeathPercentage
From CovidDeaths
Where continent is not null 
Order by 1, 2;

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has received at least one Covid Vaccine
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.Date) as RollingPeopleVaccinated
From CovidDeaths dea
Join CovidVaccinations vac
  On dea.location = vac.location
  and dea.date = vac.date
Where dea.continent is not null 
Order by 2, 3;


-- Using CTE to perform Calculation on Partition By in previous query
With PopvsVac as (
    Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
           SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.Date) as RollingPeopleVaccinated
    From CovidDeaths dea
    Join CovidVaccinations vac
      On dea.location = vac.location
      and dea.date = vac.date
    Where dea.continent is not null 
)
Select *, (RollingPeopleVaccinated * 1.0 / Population) * 100 as PercentPopulationVaccinated
From PopvsVac;


-- Using Temp Table to perform Calculation on Partition By in previous query
DROP Table if exists PercentPopulationVaccinated;

Create Table PercentPopulationVaccinated (
    Continent TEXT,
    Location TEXT,
    Date TEXT,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

Insert into PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.Date) as RollingPeopleVaccinated
From CovidDeaths dea
Join CovidVaccinations vac
  On dea.location = vac.location
  and dea.date = vac.date;

Select *, (RollingPeopleVaccinated * 1.0 / Population) * 100 as PercentPopulationVaccinated
From PercentPopulationVaccinated;


-- Creating View to store data for later visualizations
DROP VIEW if exists PercentPopulationVaccinatedView;

Create View PercentPopulationVaccinatedView as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.Date) as RollingPeopleVaccinated
From CovidDeaths dea
Join CovidVaccinations vac
  On dea.location = vac.location
  and dea.date = vac.date
Where dea.continent is not null;
