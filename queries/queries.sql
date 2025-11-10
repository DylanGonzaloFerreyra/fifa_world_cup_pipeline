-- countries_with_most_finals_played
SELECT country, COUNT(*) AS total_finals
FROM (
    SELECT winners AS country FROM fifa_finals_clean
    UNION ALL
    SELECT runners_up AS country FROM fifa_finals_clean
) AS all_finalists
GROUP BY country
ORDER BY total_finals DESC;

-- countries_with_most_goals_in_finals
SELECT country, SUM(goals) AS total_goals
FROM (
    SELECT winners AS country, CAST(winner_goals AS INT) AS goals FROM fifa_finals_clean
    UNION ALL
    SELECT runners_up AS country, CAST(runner_up_goals AS INT) AS goals FROM fifa_finals_clean
) AS all_goals
GROUP BY country
ORDER BY total_goals DESC;

-- final_with_largest_goal_difference
SELECT year, winners, runners_up,
       CAST(winner_goals AS INT) - CAST(runner_up_goals AS INT) AS goal_diff
FROM fifa_finals_clean
ORDER BY goal_diff DESC
LIMIT 1;

-- countries_that_changed_stadium
SELECT host_country, COUNT(DISTINCT venue) AS stadiums_used
FROM fifa_finals_clean
GROUP BY host_country
HAVING COUNT(DISTINCT venue) > 1
ORDER BY stadiums_used DESC;

-- final_with_highest_attendance
SELECT year, winners, runners_up, venue, attendance
FROM fifa_finals_clean
ORDER BY attendance DESC
LIMIT 1;

-- finals_decided_by_penalties
SELECT year, winners, runners_up, winner_penalties, runner_up_penalties
FROM fifa_finals_clean
WHERE winner_penalties IS NOT NULL AND runner_up_penalties IS NOT NULL
ORDER BY year DESC;