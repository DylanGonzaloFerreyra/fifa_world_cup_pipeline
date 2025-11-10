{{ config(materialized='table') }}

with raw as (
    SELECT * FROM {{ source('staging', 'fifa_raw_finals') }}
)
SELECT
    "Year"::int as year,
    "Winners" as winners,
    SPLIT_PART(SPLIT_PART("Score", ' ', 1), '–', 1) as winner_goals,
    SPLIT_PART(SPLIT_PART(REGEXP_REPLACE("Score", '\[.*\]', ''), ' ', 1), '–', 2) as runner_up_goals,
    
    CASE WHEN "Score" LIKE '%pen.%' THEN
        SPLIT_PART(
            REGEXP_REPLACE(
                REGEXP_SUBSTR("Score", '\(\d+–\d+ pen\.\)'), 
                '[^0-9–]', 
                '', 
                'g'
            ), 
        '–', 1)
    END as penalties_winner,

    CASE WHEN "Score" LIKE '%pen.%' THEN
        SPLIT_PART(
            REGEXP_REPLACE(
                REGEXP_SUBSTR("Score", '\(\d+–\d+ pen\.\)'),
                '[^0-9–]', 
                '', 
                'g'
            ), 
        '–', 2)
    END as penalties_runner_up,
    
    "Runners-up" as runners_up,
    "Venue" as venue,
    SPLIT_PART("Location", ',', 1) as host_city,
    SPLIT_PART("Location", ',', 2) as host_country,
    "Attendance"::int as attendance
FROM raw WHERE raw."Winners" IS NOT NULL