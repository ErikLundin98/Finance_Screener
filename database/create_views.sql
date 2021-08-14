DROP MATERIALIZED VIEW IF EXISTS used_dates;
DROP MATERIALIZED VIEW IF EXISTS daily_returns;
DROP MATERIALIZED VIEW IF EXISTS clean_daily;
/*Shows the latest updated dates (lazy check)*/
CREATE MATERIALIZED VIEW used_dates AS SELECT ticker, first(date, date) as "first_date", last(date, date) AS "last_date" FROM daily GROUP BY ticker ORDER BY ticker ASC;

CREATE MATERIALIZED VIEW clean_daily AS
SELECT 
    date,
    ticker,
    COALESCE(
        NULLIF(adjusted_close, 0),
        NULLIF(LAG(adjusted_close, 1) OVER (PARTITION BY ticker ORDER BY date ASC), 0),
        NULLIF(LAG(adjusted_close, 2) OVER (PARTITION BY ticker ORDER BY date ASC), 0),
        NULLIF(LAG(adjusted_close, 3) OVER (PARTITION BY ticker ORDER BY date ASC), 0)
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



CREATE OR REPLACE PROCEDURE refresh_views()
LANGUAGE SQL
AS
$$
REFRESH MATERIALIZED VIEW used_dates;
REFRESH MATERIALIZED VIEW clean_daily;
REFRESH MATERIALIZED VIEW daily_returns;
$$;