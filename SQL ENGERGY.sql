CREATE DATABASE ENERGY;
SELECT 
    e.country, 
    e.year, 
    e.emission,
    p.value AS population,
    -- Case statement prevents "Division by Zero" errors
    CASE 
        WHEN p.value = 0 THEN 0 
        ELSE (e.emission / p.value) 
    END AS per_capita_emission
FROM emission e
INNER JOIN population p 
    ON e.country = p.countries 
    AND e.year = p.year;
    
    -- we show per capita emmsion using select
    
    
    # We crete a new column and save it into emmission table
    
    ALTER TABLE emission
ADD COLUMN calc_per_capita_emission DOUBLE;

UPDATE emission e
INNER JOIN population p
    ON e.country = p.countries
   AND e.year = p.year
SET e.calc_per_capita_emission =
    CASE
        WHEN p.value = 0 THEN 0
        ELSE e.emission / p.value
    END;
    
    SELECT country, year, emission, calc_per_capita_emission
FROM emission
LIMIT 10;

select * from emission;


-- Per-capita emission cannot be calculated without population data
SELECT 
    e.country,
    e.year,
    p.value AS population
FROM emission e
LEFT JOIN population p
    ON e.country = p.countries
   AND e.year = p.year
WHERE p.value IS NULL;

-- Update into the 0
SET SQL_SAFE_UPDATES = 0; -- safe mode disable

UPDATE emission e
LEFT JOIN population p
    ON e.country = p.countries
   AND e.year = p.year
SET e.calc_per_capita_emission =
    CASE
        WHEN p.value IS NULL THEN 0
        WHEN p.value = 0 THEN 0
        ELSE e.emission / p.value
    END;

-- varifying after fixed
SELECT country, year, emission, calc_per_capita_emission
FROM emission
WHERE year = 2023
LIMIT 20;


-- ----------------------Done for per Capita -----------------------------------------------

-- LETS START SOLVING QUESTION AND ANSWERS------------------------------------------------

# Section 1st:
#General & Comparative Analysis(1-4)

-- Q. 1st What is the total emission per country for 
-- the most recent year available?

select
	country,
    sum(emission) as total_emission
from emission
where year = (select max(year) from emission)
group by country
order by total_emission desc; -- Identifies top polluting countries

-- Q2. What are the top 5 countries by GDP in the most recent year?

select
	country,
    value as gdp
from gdp
where year = (select max(year) from gdp)
order by gdp desc
limit 5; -- Strong economies generally consume more energy

-- Q3.Compare energy production and consumption by country and year?

select
	c.country,
    c.year,
    sum(p.production) as total_production,
    sum(c.consumption) as total_consumption
from consumption c
join production p
	on c.country = p.country
    and c.year = p.year
group by c.country, c.year; -- Countries with higher consumption than production depend on imports


-- Q4.Which energy types contribute most to emissions?

select
	energy_type,
    sum(emission) as total_emission
from emission
group by energy_type
order by total_emission desc; -- Fossil fuels dominate emissions


# Section 2:
 #TREND ANALYSIS OVER TIME(5-9)

-- Q5.How have global emissions changed year over year?


select 
	year,
	sum(emission) as total_emission
from emission
group by year
order by year;


-- Q6.What is the trend in GDP for each country over the given years?


select
	year,
    country,
    value as gdp
from gdp
order by country,year; -- Tracks economic growth patterns


-- Q7.How has population growth affected total emissions?

select
	e.country,
    e.year,
	p.value as population,
    sum(e.emission) as total_emission
from emission e
join population p
	on e.country = p.countries
    and e.year = p.year
group by e.country, e.year,p.value; -- Higher population generally increases emissions


-- Q8.Has energy consumption increased or decreased over time?

select 
	country,
	year,
    sum(consumption) as total_consumption
from consumption
group by country , year
order by country , year; -- Reveals demand growth over years


-- Q9.What is the average yearly change in emissions per capita for each country?

select
	country,
    avg(yearly_change) as avg_yearly_change_per_capita
from (
	select
		country,
        year,
        calc_per_capita_emission
        - LAG(calc_per_capita_emission)
			over(partition by country order by year) as yearly_change
	from emission
) t
where yearly_change is not null
group by country;


# SECTION 3: 
#RATIO & PER CAPITA ANALYSIS (10 - 14)

-- Q10. What is the emission-to-GDP ratio for each country?

select
	e.country,
    e.year,
    sum(e.emission) as total_emission,
    g.value as gdp,
    sum(e.emission) / g.value as emission_to_gdp_ratio
from emission e
join gdp g
	on e.country = g.country
    and e.year = g.year
group by 
	e.country,
    e.year,
    g.value
order by 
	e.country,
    e.year;


-- Q11. What is the energy consumption per capita 
-- for each country over the last decade?


select
	 c.country,
     c.year,
     sum(c.consumption) as total_consumption,
     p.value as population,
     sum(c.consumption) / p.value as consumption_per_capita
from consumption c
join population p
	on c.country = p.countries
    and c.year = p.year
where c.year >= (
	select max(year) - 9 from consumption
)
group by 
	c.country,
    c.year,
    p.value
order by 
	c.country,
    c.year;


-- Q12.Energy production per capita across countries

select 
	p.country,
    p.year,
    sum(p.production) / pop.value as production_per_capita
from production p
join population pop
	on p.country = pop.countries
    and p.year = pop.year
group by p.country , p.year,pop.value; -- Identifies energy-exporting countries


-- Q13.Countries with highest energy consumption relative to GDP

select
	c.country,
    sum(c.consumption) / g.value as consumption_gdp_ratio
from consumption c
join gdp g
	on c.country = g.country
    and c.year = g.year
group by c.country,g.value
order by consumption_gdp_ratio desc;


-- Q14.Correlation between GDP growth and energy production growth?


select
	g.country,
    g.year,
    g.value as gdp,
    p.production
from gdp g
join production p
	on g.Country = p.country
    and g.year = p.year;
    

#SECTION 4 
# GLOBAL COMPARISONS (15–17)

-- Q15.Top 10 countries by population & their emissions

SELECT 
	p.countries,
    p.value as population,
    sum(e.emission) as total_emission
from population p
join emission e
	on p.countries = e.country
    and p.year = e.year
group by p.countries , p.value
order by population desc
limit 10; -- High population ≠ highest emissions always


-- Q16.Countries that reduced per-capita emissions the most
 
select
	country,
    max(calc_per_capita_emission) - min(calc_per_capita_emission) as reduction
from emission
group by country
order by reduction desc; -- Shows sustainability progress


-- Q17.Global average GDP, emission & population by year


select
	e.year,
    avg(e.emission) as avg_emission,
    avg(g.value) as avg_gdp,
    avg(p.value) as avg_population
from emission e
join gdp g
	on e.country = g.country
    and e.year = g.year
join population p
	on e.country = p.countries
    and e.year = p.year
group by e.year
order by e.year; -- Gives global-level trends

--   How have global emissions changed over time?

SELECT
    year,
    SUM(emission) AS total_emission
FROM emission
GROUP BY year
ORDER BY year;

-- 2. Total Consumption vs Total Production by Country

SELECT
    c.country,
    SUM(c.consumption) AS total_consumption,
    SUM(p.production) AS total_production
FROM consumption c
JOIN production p
    ON c.country = p.country
   AND c.year = p.year
GROUP BY c.country;


-- 3. Energy Consumption per Capita

SELECT
    c.country,
    c.year,
    SUM(c.consumption) / pop.value AS consumption_per_capita
FROM consumption c
JOIN population pop
    ON c.country = pop.countries
   AND c.year = pop.year
GROUP BY c.country, c.year, pop.value;


-- 4. Energy Type Contribution to Emissions

SELECT
    energy_type,
    SUM(emission) AS total_emission
FROM emission
GROUP BY energy_type
ORDER BY total_emission DESC;

-- Total Emission by Country

SELECT
    country,
    SUM(emission) AS total_emission
FROM emission
GROUP BY country
ORDER BY total_emission DESC
LIMIT 10;
