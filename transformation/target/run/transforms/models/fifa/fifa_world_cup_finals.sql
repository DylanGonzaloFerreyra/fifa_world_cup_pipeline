
  
    

  create  table "fifa_dw_project"."analytics"."fifa_world_cup_finals__dbt_tmp"
  
  
    as
  
  (
    

with raw as (
    SELECT * FROM "fifa_dw_project"."staging"."fifa_raw_finals"
)
SELECT
    "Year"::int as year,
    "Winners" as winners,
    SPLIT_PART(SPLIT_PART("Score", ' ', 1), '–', 1) as winner_goals,
    SPLIT_PART(SPLIT_PART(REGEXP_REPLACE("Score", '\[.*\]', ''), ' ', 1), '–', 2) as runner_up_goals,
    REGEXP_SUBSTR("Score", '\((\d+)–\d+ pen\.\)', 1, 1, 'e') as penalties_winner,
    REGEXP_SUBSTR("Score", '\(\d+–(\d+) pen\.\)', 1, 1, 'e') as penalties_runner_up,
    "Runners-up" as runners_up,
    "Venue" as venue,
    SPLIT_PART("Location", ',', 1) as host_city,
    SPLIT_PART("Location", ',', 2) as host_country,
    "Attendance"::int as attendance
FROM raw WHERE raw."Winners" IS NOT NULL
  );
  