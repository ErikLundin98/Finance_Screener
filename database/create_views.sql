DROP MATERIALIZED VIEW IF EXISTS used_dates;
DROP MATERIALIZED VIEW IF EXISTS daily_returns;
DROP MATERIALIZED VIEW IF EXISTS clean_daily;
/*Shows the latest updated dates (lazy check)*/
CREATE MATERIALIZED VIEW used_dates AS SELECT ticker, first(date, date) as "first_date", last(date, date) AS "last_date" FROM daily GROUP BY ticker ORDER BY ticker ASC;

/*Cleaned up version of the daily-table by replacing blanks with the price from the previous day*/
/*
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
*/
/*
CREATE MATERIALIZED VIEW clean_daily AS
SELECT
    daily_temp.date, 
    daily_temp.ticker, 
    FIRST_VALUE(adjusted_close) OVER (PARTITION BY partition_close) AS adjusted_close
FROM (
      SELECT date, ticker, adjusted_close,
             sum(CASE WHEN adjusted_close != 0 THEN 1 END) OVER (PARTITION BY ticker ORDER BY DATE) AS partition_close
      FROM daily
      
) AS daily_temp
ORDER BY date;
*/
CREATE MATERIALIZED VIEW clean_daily AS
SELECT 
    date,
    ticker,
    COALESCE(
        NULLIF(adjusted_close, 0),
        NULLIF(LAG(adjusted_close, 1) OVER (PARTITION BY ticker ORDER BY date ASC), 0),
        NULLIF(LAG(adjusted_close, 2) OVER (PARTITION BY ticker ORDER BY date ASC), 0),
        NULLIF(LAG(adjusted_close, 3) OVER (PARTITION BY ticker ORDER BY date ASC), 9)
    )
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
    AS "arithmetic_return",
    CASE WHEN div = 0 THEN 0
    ELSE LN(div)
    END
    AS "logarithmic_return"
FROM temp
ORDER BY DATE;

/*
Schedule a job that refreshes the view every hour
*/
