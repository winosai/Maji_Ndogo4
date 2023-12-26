/*
	Created a view called combined analysis from different table in order to make easier and understand the 
    problem we are trying to solve on regional and town level based on the different water sources.
    Also this will make the view reusable in other queries
*/

CREATE VIEW combined_analysis AS (SELECT
    loc.province_name,
    loc.town_name,
    loc.location_type,
    ws.type_of_water_source,
    ws.number_of_people_served,
    vs.time_in_queue,
    wp.results
FROM
	location AS loc
JOIN 
	visits AS vs
	ON loc.location_id = vs.location_id
JOIN 
	water_source AS ws
    ON vs.source_id = ws.source_id
LEFT JOIN
	well_pollution AS wp
    ON ws.source_id = wp.source_id
WHERE 
	-- Removing duplicated records where visit count was greater than 1
	vs.visit_count = 1
);

/*
This query gives insight into the percentage number of people served by each of the water sources per province.
 It creates a pivot table which can be visualized in order to know which region is mostly affected by the water crisis,
 most commonly used water source in the province and get insights on which regions should be prioritized
*/

WITH province_totals AS (SELECT
	province_name,
    SUM(number_of_people_served) as total_pple_serv
FROM 
	combined_analysis
GROUP BY
	province_name
)SELECT
	ca.province_name,
    ROUND(
		(SUM(CASE WHEN ca.type_of_water_source = "river"
					THEN ca.number_of_people_served
					ELSE 0
			END) / total_pple_serv) * 100
	,0) AS river,
    ROUND(
		(SUM(CASE WHEN ca.type_of_water_source = "shared_tap"
					THEN ca.number_of_people_served
					ELSE 0
			END) / total_pple_serv) * 100
	,0) AS shared_tap,
    ROUND(
		(SUM(CASE WHEN ca.type_of_water_source = "tap_in_home"
					THEN ca.number_of_people_served
					ELSE 0
			END) / total_pple_serv) * 100
	,0) AS tap_in_home,
    ROUND(
		(SUM(CASE WHEN ca.type_of_water_source = "tap_in_home_broken"
					THEN ca.number_of_people_served
					ELSE 0
			END) / total_pple_serv) * 100
	,0) AS tap_in_home_broken,
    ROUND(
		(SUM(CASE WHEN ca.type_of_water_source = "well"
					THEN ca.number_of_people_served
					ELSE 0
			END) / total_pple_serv) * 100
	,0) AS well
FROM
	combined_analysis AS ca
JOIN province_totals as pt
	ON ca.province_name = pt.province_name
GROUP BY
	ca.province_name
ORDER BY
	ca.province_name;

/*
The query below creates a pivot table to show the percentage number of people served by each type of water source
per town in each province. This is to give insight into the most water used sources in each town and priotitize which water
source to be repaired
*/

WITH town_totals AS (SELECT
	province_name,
    town_name,
    SUM(number_of_people_served) as total_pple_serv
FROM 
	combined_analysis
GROUP BY
	province_name, town_name
)SELECT
	ca.province_name,
    tt.town_name,
	ROUND(
		(SUM(
			CASE 
				WHEN ca.type_of_water_source = "river" 
					THEN ca.number_of_people_served
                    ELSE 0 
			END
			) / SUM(number_of_people_served)) * 100
    ,0) AS river,
    ROUND(
		(SUM(
			CASE 
				WHEN ca.type_of_water_source = "shared_tap" 
					THEN ca.number_of_people_served
                    ELSE 0 
			END
			) / SUM(number_of_people_served)) * 100
    ,0) AS shared_tap,
    ROUND(
		(SUM(
			CASE 
				WHEN ca.type_of_water_source = "tap_in_home" 
					THEN ca.number_of_people_served
                    ELSE 0 
			END
			) / SUM(number_of_people_served)) * 100
    ,0) AS tap_in_home,
    ROUND(
		(SUM(
			CASE 
				WHEN ca.type_of_water_source = "tap_in_home_broken" 
					THEN ca.number_of_people_served
                    ELSE 0 
			END
			) / SUM(number_of_people_served)) * 100
    ,0) AS tap_in_home_broken,
    ROUND(
		(SUM(
			CASE 
				WHEN ca.type_of_water_source = "well" 
					THEN ca.number_of_people_served
                    ELSE 0 
			END
			) / SUM(number_of_people_served)) * 100
    ,0) AS well
FROM
	combined_analysis AS ca
JOIN 
	town_totals AS tt ON ca.town_name = tt.town_name AND ca.province_name = tt.province_name
GROUP BY
		-- this group the table first by province name and later by town name. this is because the town names are not 
        -- unique for example Amina is a town in Amanzi and Hawassa.
	ca.province_name, tt.town_name
ORDER BY
	ca.province_name, tt.town_name;


/*
Created a temporary table for the town_totals to speed up result when the query is ran, instead of running 
the whole query.
*/

CREATE TEMPORARY TABLE town_aggregated_water_access
	(WITH town_totals AS (SELECT
		province_name,
		town_name,
		SUM(number_of_people_served) as total_pple_serv
	FROM 
		combined_analysis
	GROUP BY
		province_name, town_name
	)SELECT
		ca.province_name,
		tt.town_name,
		ROUND(
			(SUM(
				CASE 
					WHEN ca.type_of_water_source = "river" 
						THEN ca.number_of_people_served
						ELSE 0 
				END
				) / SUM(number_of_people_served)) * 100
		,0) AS river,
		ROUND(
			(SUM(
				CASE 
					WHEN ca.type_of_water_source = "shared_tap" 
						THEN ca.number_of_people_served
						ELSE 0 
				END
				) / SUM(number_of_people_served)) * 100
		,0) AS shared_tap,
		ROUND(
			(SUM(
				CASE 
					WHEN ca.type_of_water_source = "tap_in_home" 
						THEN ca.number_of_people_served
						ELSE 0 
				END
				) / SUM(number_of_people_served)) * 100
		,0) AS tap_in_home,
		ROUND(
			(SUM(
				CASE 
					WHEN ca.type_of_water_source = "tap_in_home_broken" 
						THEN ca.number_of_people_served
						ELSE 0 
				END
				) / SUM(number_of_people_served)) * 100
		,0) AS tap_in_home_broken,
		ROUND(
			(SUM(
				CASE 
					WHEN ca.type_of_water_source = "well" 
						THEN ca.number_of_people_served
						ELSE 0 
				END
				) / SUM(number_of_people_served)) * 100
		,0) AS well
	FROM
		combined_analysis AS ca
	JOIN 
		town_totals AS tt ON ca.town_name = tt.town_name AND ca.province_name = tt.province_name
	GROUP BY
		ca.province_name, tt.town_name
	ORDER BY
		ca.province_name, tt.town_name);

SELECT
	province_name,
    town_name,
    ROUND((tap_in_home_broken / (tap_in_home + tap_in_home_broken))*100, 0) AS pct_tap_broken
FROM
	town_aggregated_water_access;
    

DROP TABLE IF EXISTS project_progress;
/*
Created a project_progress table to keep track of what need to be done to improve water sources at different location
and the status of each project
*/ 
CREATE TABLE project_progress (
	Project_id SERIAL PRIMARY KEY,
    Source_id VARCHAR(20) NOT NULL REFERENCES water_source(source_id) ON DELETE CASCADE ON UPDATE CASCADE,
    Address VARCHAR(50),
    Town VARCHAR(30),
    Province VARCHAR(30),
    Source_type VARCHAR(50),
    Improvement VARCHAR(50),
    Source_status VARCHAR(50) DEFAULT 'Backlog' CHECK (Source_status IN ('Backlog', 'In progress', 'Complete')),
    Date_of_completion DATE,
    Comments TEXT
);

/*
Populated the project_progress table with the corresponding column
*/

INSERT INTO project_progress(
	source_id,
    address,
    town,
    province,
    source_type,
	improvement
)SELECT
	ws.source_id,
	loc.address,
    loc.town_name,
	loc.province_name,
    ws.type_of_water_source,
    -- well_pollution.results,
    CASE
		WHEN well_pollution.results = "Contaminated: Biological" 
			THEN "Install UV filter"
		WHEN well_pollution.results = "Contaminated: Chemical"
			THEN "Install UV and RO filters"
		WHEN ws.type_of_water_source = "river"
			THEN "Drill well"
		WHEN ws.type_of_water_source = "shared_tap" AND visits.time_in_queue >= 30
			THEN CONCAT("Install", " ", FLOOR(visits.time_in_queue / 30), " ", "tap(s) nearby")
		WHEN ws.type_of_water_source = "tap_in_home_broken"
			THEN "Diagnose Infrastructure"
		ELSE NULL
END AS improvements
FROM
	location AS loc
JOIN
	visits 
	ON loc.location_id = visits.location_id
JOIN
	water_source AS ws
    ON visits.source_id = ws.source_id
LEFT JOIN well_pollution
	ON visits.source_id = well_pollution.source_id
WHERE
	visits.visit_count = 1
    -- Filters the table on sources that need improvements
    AND(
		well_pollution.results != "Clean"
        OR (ws.type_of_water_source IN ("tap_in_home_broken", "river")
        OR (ws.type_of_water_source = "shared_tap" AND visits.time_in_queue >= 30)
        )
    );
