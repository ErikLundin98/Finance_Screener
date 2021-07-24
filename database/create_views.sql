DROP VIEW IF EXISTS used_dates;
DROP MATERIALIZED VIEW IF EXISTS daily_returns;
DROP MATERIALIZED VIEW IF EXISTS clean_daily;
/*Shows the latest updated dates (lazy check)*/
CREATE VIEW used_dates AS SELECT ticker, first(date, date) as "first_date", last(date, date) AS "last_date" FROM daily GROUP BY ticker ORDER BY ticker ASC;

/*Cleaned up version of the daily-table by replacing blanks with the price from the previous day*/
CREATE MATERIALIZED VIEW clean_daily AS
SELECT 
    date,
    ticker,
    CASE WHEN adjusted_close = 0 THEN LAG(adjusted_close) OVER (PARTITION BY ticker ORDER BY date ASC)
    ELSE adjusted_close 
    END 
    AS "adjusted_close"
FROM daily
ORDER BY date;


CREATE MATERIALIZED VIEW daily_returns AS
WITH temp AS (
    SELECT 
        date,
        ticker,
        adjusted_close/NULLIF(LAG(adjusted_close) OVER (PARTITION BY ticker ORDER BY date ASC), 0) as div
        FROM clean_daily
)
SELECT
    date,
    ticker,
    CASE WHEN div = 0 THEN 0
    ELSE div - 1
    END
    AS "arithmetic return",
    CASE WHEN div = 0 THEN 0
    ELSE LOG(div)
    END
    AS "logarithmic_return"
FROM temp
ORDER BY DATE;

/*
Schedule a job that refreshes the view every hour
*/
