CREATE OR REPLACE VIEW forestation 
AS 
SELECT fa.country_code, fa.country_name, fa.year, fa.forest_area_sqkm, la.total_area_sq_mi,  r.region, r.income_group,
fa.forest_area_sqkm * 100 / (2.59 * la.total_area_sq_mi) AS pct_area_forest
FROM forest_area fa
JOIN land_area la
ON fa.country_code = la.country_code AND fa.year = la.year
JOIN regions r
ON fa.country_code = r.country_code;


-- World Forest Area
SELECT forest_area_sqkm  AS total_forest_area_1990
FROM forestation
WHERE country_name = 'World'
AND year = 1990;

--Q1 b

SELECT forest_area_sqkm AS total_forest_area_2016
FROM forestation
WHERE country_name = 'World'
AND year = 2016;

-- Change in forest cover from 1990 to 2016
SELECT previous.forest_area_sqkm - current.forest_area_sqkm AS deforest_area_sq_km
      FROM (SELECT f.country_code, f.forest_area_sqkm
      	    FROM forest_area f
              WHERE f.country_name = 'World'
              	AND f.year = 1990) AS previous
      JOIN (SELECT f.country_code,f.forest_area_sqkm
      		FROM forest_area f
              WHERE f.country_name = 'World'
              	AND f.year = 2016) AS current
      ON previous.country_code = current.country_code;

--  Change in forest cover %
SELECT ROUND((((previous.forest_area_sqkm - current.forest_area_sqkm) / previous.forest_area_sqkm )*100)::numeric, 4)  AS pct_change_fa
      FROM (SELECT f.country_code, f.forest_area_sqkm
      	    FROM forest_area f
              WHERE f.country_name = 'World'
              	AND f.year = 1990) AS previous
      JOIN (SELECT f.country_code,f.forest_area_sqkm
      		FROM forest_area f
              WHERE f.country_name = 'World'
              	AND f.year = 2016) AS current
      ON previous.country_code = current.country_code;
	  
	  
-- Similar to country (Peru)
SELECT country_name, ABS((total_area_sq_mi * 2.59) - 1324449) AS diff_fa_loss
FROM forestation
WHERE year = 2016
ORDER BY 2
LIMIT 1;


-- Regional Outlook
CREATE OR REPLACE VIEW region_forest_area
AS
WITH forest_area_2016 AS 
	(SELECT region, SUM(fa.forest_area_sqkm) AS total_forest_area_sqkm_2016,
       SUM(la.total_area_sq_mi * 2.59) AS total_area_sqkm_2016,
       SUM(fa.forest_area_sqkm) * 100 / SUM(la.total_area_sq_mi * 2.59) AS percent_fa_region_2016
	   FROM forest_area fa
       JOIN land_area la
       ON fa.country_code = la.country_code AND fa.year = la.year
       JOIN regions r
       ON la.country_code = r.country_code
	   WHERE fa.year = 2016
       GROUP BY 1
       ORDER BY 1
	   ),
	   forest_area_1990 AS 
	  (SELECT region, SUM(fa.forest_area_sqkm) AS total_forest_area_sqkm_1990,
       SUM(la.total_area_sq_mi * 2.59) AS total_area_sqkm_1990,
       SUM(fa.forest_area_sqkm) * 100 / SUM(la.total_area_sq_mi * 2.59) AS percent_fa_region_1990
	   FROM forest_area fa
       JOIN land_area la
       ON fa.country_code = la.country_code AND fa.year = la.year
       JOIN regions r
       ON la.country_code = r.country_code
	   WHERE fa.year = 1990
       GROUP BY 1
       ORDER BY 1
	   )
	   SELECT fa2016.region, total_forest_area_sqkm_2016, total_area_sqkm_2016, percent_fa_region_2016,
	   total_forest_area_sqkm_1990, total_area_sqkm_1990, percent_fa_region_1990
	   FROM forest_area_2016 fa2016
	   JOIN forest_area_1990 fa1990
	   ON fa1990.region = fa2016.region;

-- World
SELECT ROUND(percent_fa_region_2016::numeric, 2)
	   FROM region_forest_area
     WHERE region = 'World';

-- Highest forest cover 2016
SELECT region,
       ROUND(total_area_sqkm_2016::numeric, 2) AS total_area_sqkm,
       ROUND(percent_fa_region_2016::numeric, 2) AS percent_fa_region
       FROM region_forest_area
       WHERE region != 'World'
	   ORDER BY 3 DESC
	   LIMIT 1;

-- Lowest forest cover 2016
SELECT region,
       ROUND(total_area_sqkm_2016::numeric, 2) AS total_area_sqkm,
       ROUND(percent_fa_region_2016::numeric, 2) AS percent_fa_region
       FROM region_forest_area
       WHERE region != 'World'
	   ORDER BY 3 ASC
	   LIMIT 1;


-- World Forest cover 1990
SELECT ROUND(percent_fa_region_1990::numeric, 2)
	   FROM region_forest_area
     WHERE region = 'World';

-- Highest forest cover 1990
SELECT region,
       ROUND(total_area_sqkm_1990::numeric, 2) AS total_area_sqkm,
       ROUND(percent_fa_region_1990::numeric, 2) AS percent_fa_region
       FROM region_forest_area
       WHERE region != 'World'
	   ORDER BY 3 DESC
	   LIMIT 1;

-- Lowest forest cover 1990
SELECT region,
       ROUND(total_area_sqkm_1990::numeric, 2) AS total_area_sqkm,
       ROUND(percent_fa_region_1990::numeric, 2) AS percent_fa_region
       FROM region_forest_area
       WHERE region != 'World'
	   ORDER BY 3 ASC
	   LIMIT 1;

SELECT region "Region", 
      ROUND(percent_fa_region_1990::numeric, 2) "1990 Forest Percentage",
      ROUND(percent_fa_region_2016::numeric, 2) "2016 Forest Percentage"
FROM
region_forest_area;

-- Regions that declined in area
SELECT region,
	ROUND(percent_fa_region_1990::numeric, 2) AS percent_fa_region_1990,
	ROUND(percent_fa_region_2016::numeric, 2) AS percent_fa_region_2016,
	ROUND((percent_fa_region_1990 - percent_fa_region_2016)::numeric, 2) AS percent_fa_decrease
FROM region_forest_area
WHERE percent_fa_region_1990 > percent_fa_region_2016
ORDER BY 3 DESC


-- Country Outlook
CREATE OR REPLACE VIEW country_forest_area 
AS
WITH forest_area_2016 AS 
	(SELECT fa.country_name, region, SUM(fa.forest_area_sqkm) AS total_forest_area_sqkm_2016,
       SUM(la.total_area_sq_mi * 2.59) AS total_area_sqkm_2016,
       SUM(fa.forest_area_sqkm) * 100 / SUM(la.total_area_sq_mi * 2.59) AS percent_fa_region_2016
	   FROM forest_area fa
       JOIN land_area la
       ON fa.country_code = la.country_code AND fa.year = la.year
       JOIN regions r
       ON la.country_code = r.country_code
	   WHERE fa.year = 2016
         AND fa.forest_area_sqkm IS NOT NULL
       GROUP BY 1, 2
       ORDER BY 1
	   ),
	   forest_area_1990 AS 
	  (SELECT fa.country_name, region, SUM(fa.forest_area_sqkm) AS total_forest_area_sqkm_1990,
       SUM(la.total_area_sq_mi * 2.59) AS total_area_sqkm_1990,
       SUM(fa.forest_area_sqkm) * 100 / SUM(la.total_area_sq_mi * 2.59) AS percent_fa_region_1990
	   FROM forest_area fa
       JOIN land_area la
       ON fa.country_code = la.country_code AND fa.year = la.year
       JOIN regions r
       ON la.country_code = r.country_code
	   WHERE fa.year = 1990
         AND fa.forest_area_sqkm IS NOT NULL
       GROUP BY 1, 2
       ORDER BY 1
	   ) SELECT fa2016.country_name "country", fa2016.region, total_forest_area_sqkm_2016, total_area_sqkm_2016, percent_fa_region_2016,
	   total_forest_area_sqkm_1990, total_area_sqkm_1990, percent_fa_region_1990
	   FROM forest_area_2016 fa2016
	   JOIN forest_area_1990 fa1990
	   ON fa1990.country_name = fa2016.country_name;


-- Absolute decrease country
SELECT country,
      region,
      ROUND(total_forest_area_sqkm_1990 - total_forest_area_sqkm_2016, 2) "Absolute Forest Change"
FROM country_forest_area
WHERE country != 'World'
ORDER BY 3 DESC;


-- decrease by country %
SELECT country, region, 
      ROUND(((total_forest_area_sqkm_1990 - total_forest_area_sqkm_2016) * 100 / total_forest_area_sqkm_1990)::numeric, 2) 
      "Forest Change Pctage"
FROM country_forest_area
WHERE country != 'World'
ORDER BY 3 DESC;

-- Quartiles 2016
WITH country_fa_2016 AS (SELECT 
                       fa.country_name,
                       fa.year,
                       fa.forest_area_sqkm,
                       la.total_area_sq_mi * 2.59 AS total_area_sqkm,
                        (fa.forest_area_sqkm * 100/(la.total_area_sq_mi * 2.59))  AS pct_fa
                        FROM forest_area fa
                        JOIN land_area la
                        ON fa.country_code = la.country_code
                        AND fa.country_name != 'World' 
                        AND fa.forest_area_sqkm IS NOT NULL
                        AND la.total_area_sq_mi IS NOT NULL
                        AND fa.year = 2016
                        AND la.year = 2016
                        ORDER BY 5 DESC
                  ),
      country_fa_qtile AS (SELECT 
                        country_name,
                        year,
                        pct_fa,
                        CASE WHEN pct_fa >= 75 THEN 4
                              WHEN pct_fa < 75 AND pct_fa >= 50 THEN 3
                              WHEN pct_fa < 50 AND pct_fa >=25 THEN 2
                              ELSE 1
                        END AS percentile
                        FROM country_fa_2016 ORDER BY 4 DESC
                  )
SELECT percentile,
       COUNT(percentile)
       FROM country_fa_qtile
       GROUP BY 1
       ORDER BY 2 DESC;

-- Countries in top Quartile
WITH country_fa_2016 AS (SELECT 
                       fa.country_name,
                       r.region,
                       fa.year,
                       fa.forest_area_sqkm,
                       la.total_area_sq_mi * 2.59 AS total_area_sqkm,
                        (fa.forest_area_sqkm * 100/(la.total_area_sq_mi * 2.59))  AS pct_fa
                        FROM forest_area fa
                        JOIN land_area la
                        ON fa.country_code = la.country_code
                        JOIN regions r
                        ON fa.country_code = r.country_code 
                        AND fa.country_name != 'World' 
                        AND fa.forest_area_sqkm IS NOT NULL
                        AND la.total_area_sq_mi IS NOT NULL
                        AND fa.year = 2016
                        AND la.year = 2016
                        ORDER BY 5 DESC
                  ),
      country_fa_qtile AS (SELECT 
                        country_name,
                        region,
                        year,
                        pct_fa,
                         CASE WHEN pct_fa >= 75 THEN 4
                              WHEN pct_fa < 75 AND pct_fa >= 50 THEN 3
                              WHEN pct_fa < 50 AND pct_fa >=25 THEN 2
                              ELSE 1
                         END AS percentile
                         FROM country_fa_2016 ORDER BY 4 DESC
                  )

SELECT country_name "Country",
       region "Region",
       pct_fa "Pct Designated As Forest"
       FROM country_fa_qtile
       WHERE percentile = 4
       ORDER BY 3 DESC;
	   
-- No. of Countries with % greater than the United States
WITH country_fa_2016 AS (SELECT 
                       fa.country_name,
                       r.region,
                       fa.year,
                       fa.forest_area_sqkm,
                       la.total_area_sq_mi * 2.59 AS total_area_sqkm,
                        (fa.forest_area_sqkm * 100/(la.total_area_sq_mi * 2.59))  AS pct_fa
                        FROM forest_area fa
                        JOIN land_area la
                        ON fa.country_code = la.country_code
                        JOIN regions r
                        ON fa.country_code = r.country_code 
                        AND fa.country_name != 'World' 
                        AND fa.forest_area_sqkm IS NOT NULL
                        AND la.total_area_sq_mi IS NOT NULL
                        AND fa.year = 2016
                        AND la.year = 2016
                        ORDER BY 5 DESC
                  ),
      country_fa_qtile AS (SELECT 
                        country_name,
                        region,
                        year,
                        pct_fa,
                         CASE WHEN pct_fa >= 75 THEN 4
                              WHEN pct_fa < 75 AND pct_fa >= 50 THEN 3
                              WHEN pct_fa < 50 AND pct_fa >=25 THEN 2
                              ELSE 1
                         END AS percentile
                         FROM country_fa_2016 ORDER BY 4 DESC
                  )
SELECT COUNT(country_name)
       FROM country_fa_qtile
       WHERE pct_fa > (SELECT pct_fa FROM country_fa_qtile WHERE country_name = 'United States');