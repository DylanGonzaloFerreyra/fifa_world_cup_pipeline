{{ config(materialized='table') }}

with raw as (
    SELECT * FROM {{ source('staging', 'fifa_raw_finals') }}
)
SELECT
    "Year"::int as year,
    "Winners" as winners,
    SPLIT_PART(SPLIT_PART("Score", ' ', 1), '–', 1)::int as winner_goals,
    SPLIT_PART(SPLIT_PART(REGEXP_REPLACE("Score", '\[.*\]', ''), ' ', 1), '–', 2)::int as runner_up_goals,
    
    COALESCE(
        CASE WHEN "Score" LIKE '%pen.%' THEN
            SPLIT_PART(
                REGEXP_REPLACE(
                    REGEXP_SUBSTR("Score", '\(\d+–\d+ pen\.\)'), 
                    '[^0-9–]', 
                    '', 
                    'g'
                ), 
            '–', 1)
        END::int,
    0) as winner_penalties,

    COALESCE(
        CASE WHEN "Score" LIKE '%pen.%' THEN
            SPLIT_PART(
                REGEXP_REPLACE(
                    REGEXP_SUBSTR("Score", '\(\d+–\d+ pen\.\)'),
                    '[^0-9–]', 
                    '', 
                    'g'
                ), 
            '–', 2)
        END::int,
    0) as runner_up_penalties,
    
    "Runners-up" as runners_up,
    "Venue" as venue,
    SPLIT_PART("Location", ',', 1) as host_city,
    SPLIT_PART("Location", ',', 2) as host_country,
    "Attendance"::int as attendance
FROM raw
WHERE raw."Winners" IS NOT NULL
