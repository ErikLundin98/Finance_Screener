
DROP MATERIALIZED VIEW IF EXISTS clean_daily CASCADE;
CREATE MATERIALIZED VIEW clean_daily AS
SELECT 
    date,
    ticker,
    COALESCE(
        NULLIF(close, 0),
        NULLIF(LAG(close, 1) OVER (PARTITION BY ticker ORDER BY date ASC), 0),
        NULLIF(LAG(close, 2) OVER (PARTITION BY ticker ORDER BY date ASC), 0),
        NULLIF(LAG(close, 3) OVER (PARTITION BY ticker ORDER BY date ASC), 0)
    )
    AS "close",
    COALESCE(
        NULLIF(adjusted_close, 0),
        NULLIF(LAG(adjusted_close, 1) OVER (PARTITION BY ticker ORDER BY date ASC), 0),
        NULLIF(LAG(adjusted_close, 2) OVER (PARTITION BY ticker ORDER BY date ASC), 0),
        NULLIF(LAG(adjusted_close, 3) OVER (PARTITION BY ticker ORDER BY date ASC), 0)
    )
    AS "adjusted_close"
FROM daily
WHERE adjusted_close <> 0
ORDER BY date;

/*Shows the latest updated dates (lazy check)*/
DROP MATERIALIZED VIEW IF EXISTS used_dates CASCADE;
CREATE MATERIALIZED VIEW used_dates AS 
SELECT ticker, first(date, date) as "first_date", last(date, date) AS "last_date" 
FROM clean_daily 
WHERE adjusted_close IS NOT NULL AND adjusted_close <> 0
GROUP BY ticker 
ORDER BY ticker ASC;

DROP MATERIALIZED VIEW IF EXISTS daily_returns CASCADE;
CREATE MATERIALIZED VIEW daily_returns AS
WITH temp AS (
    SELECT 
        date,
        ticker,
        adjusted_close/NULLIF(LAG(adjusted_close) OVER (PARTITION BY ticker ORDER BY date ASC), 0) as div
        FROM clean_daily
        ORDER BY date
)
SELECT
    temp.date,
    temp.ticker,
    CASE WHEN div = 0 THEN 0
    ELSE div - 1
    END
    AS "arithmetic_return",
    CASE WHEN div = 0 THEN 0
    ELSE LN(div)
    END
    AS "logarithmic_return"
FROM temp, used_dates
WHERE temp.ticker = used_dates.ticker AND temp.date > used_dates.first_date
ORDER BY date;

/*Technical analysis view for all assets in database*/

/* CUSTOM AGGREGATE FUNCTION geomean */
CREATE OR REPLACE FUNCTION geomean_accum(float8[], float8)
RETURNS float8[]
LANGUAGE sql
AS $g$
SELECT array[$1[1]*(1+$2), $1[2]+1];
$g$;

CREATE OR REPLACE FUNCTION geomean_finalize(float8[])
RETURNS float8
LANGUAGE sql
AS $g$
SELECT POWER($1[1], 1/$1[2]) - 1;
$g$;

CREATE OR REPLACE AGGREGATE geomean(value float8) (
    sfunc = geomean_accum,
    stype = float8[],
    finalfunc = geomean_finalize,
    initcond = '{1, 0}'
);
/*---*/

/*ASSET INDICATORS VIEW*/
DROP VIEW IF EXISTS common_dates;
CREATE VIEW common_dates
AS 
SELECT
    CURRENT_DATE AS today,
    CAST(CURRENT_DATE - interval '1 year' AS DATE) AS ONE_Y_first_date,
    (SELECT MAX(first_date) FROM used_dates) AS AT_first_date,
    (SELECT MIN(last_date) FROM used_dates) AS AT_last_date;

/* dates for 1y stats */
DROP MATERIALIZED VIEW IF EXISTS closest_1Y_dates;
CREATE MATERIALIZED VIEW closest_1Y_dates AS
SELECT e.ticker, MIN(b.date) first_date, MAX(e.date) last_date FROM clean_daily e, clean_daily b
    WHERE b.ticker = e.ticker 
    AND e.date <= CURRENT_DATE
    AND b.date >= CAST(CURRENT_DATE - interval '1 year' AS DATE)
    GROUP BY e.ticker;
/* One year returns for tickers */
DROP MATERIALIZED VIEW IF EXISTS ticker_1Y_returns;
CREATE MATERIALIZED VIEW ticker_1Y_returns
AS
SELECT 
    closest_1Y_dates.ticker,
    cd2.adjusted_close/cd1.adjusted_close - 1 AS arithmetic,
    LN(cd2.adjusted_close/cd1.adjusted_close) AS logarithmic,
    closest_1Y_dates.last_date,
    closest_1Y_dates.first_date
FROM closest_1Y_dates
INNER JOIN clean_daily cd1 ON closest_1Y_dates.ticker = cd1.ticker AND cd1.date = closest_1Y_dates.first_date
INNER JOIN clean_daily cd2 on closest_1Y_dates.ticker = cd2.ticker AND cd2.date = closest_1Y_dates.last_date;

/* All time returns for tickers */
DROP MATERIALIZED VIEW IF EXISTS ticker_AT_returns;
CREATE MATERIALIZED VIEW ticker_AT_returns
AS
SELECT 
    used_dates.ticker,
    cd2.adjusted_close/cd1.adjusted_close - 1 AS arithmetic,
    LN(cd2.adjusted_close/cd1.adjusted_close) AS logarithmic,
    used_dates.last_date,
    used_dates.first_date
FROM used_dates
INNER JOIN clean_daily cd1 ON used_dates.ticker = cd1.ticker AND cd1.date = used_dates.first_date
INNER JOIN clean_daily cd2 on used_dates.ticker = cd2.ticker AND cd2.date = used_dates.last_date;

/* One-year statistics for tickers */
DROP MATERIALIZED VIEW IF EXISTS ticker_1Y_stats;
CREATE MATERIALIZED VIEW ticker_1Y_stats
AS 
SELECT
    ticker,
    stddev(arithmetic_return) AS ari_r_stddev,
    geomean(arithmetic_return) AS ari_r_geomean,
    stddev(logarithmic_return) AS log_r_stddev,
    avg(logarithmic_return) AS log_r_mean
FROM daily_returns WHERE date >= CURRENT_DATE - interval '1 year'
GROUP BY ticker;

/* All time statistics for tickers */
DROP MATERIALIZED VIEW IF EXISTS ticker_AT_stats;
CREATE MATERIALIZED VIEW ticker_AT_stats
AS 
SELECT
    ticker,
    stddev(arithmetic_return) AS ari_r_stddev,
    geomean(arithmetic_return) AS ari_r_geomean,
    stddev(logarithmic_return) AS log_r_stddev,
    avg(logarithmic_return) AS log_r_mean
FROM daily_returns
GROUP BY ticker;


/* Combined asset indicators view */
DROP VIEW IF EXISTS asset_indicators;
CREATE VIEW asset_indicators AS
SELECT r1y.ticker, r1y.arithmetic AS "arithmetic_1y", rat.arithmetic AS "arithmetic_at", rat.first_date AS "first_date_at", rat.last_date AS "last_date_at", -- Returns
s1y.ari_r_stddev*SQRT(253) AS "stddev_1y_ari", s1y.log_r_stddev*SQRT(253) AS "stddev_1y_log", s1y.ari_r_geomean*253 AS "ari_geomean_1y", s1y.log_r_mean*253 AS "log_mean_1y", -- 1Y stats
sat.ari_r_stddev*SQRT(253) AS "stddev_at_ari", sat.log_r_stddev*SQRT(253) AS "stddev_at_log", sat.ari_r_geomean*253 AS "ari_geomean_at", sat.log_r_mean*253 AS "log_mean_at"-- All time stats
FROM ticker_1Y_returns AS r1y
INNER JOIN ticker_AT_returns AS rat ON r1y.ticker = rat.ticker
INNER JOIN ticker_1Y_stats AS s1y ON s1y.ticker = r1y.ticker
INNER JOIN ticker_AT_stats AS sat ON sat.ticker = r1y.ticker;



/* PROCEDURE to refresh views*/

CREATE OR REPLACE PROCEDURE refresh_views()
LANGUAGE SQL
AS
$$
REFRESH MATERIALIZED VIEW used_dates;
REFRESH MATERIALIZED VIEW clean_daily;
REFRESH MATERIALIZED VIEW daily_returns;
REFRESH MATERIALIZED VIEW closest_1Y_dates;
REFRESH MATERIALIZED VIEW ticker_1Y_returns;
REFRESH MATERIALIZED VIEW ticker_AT_returns;
REFRESH MATERIALIZED VIEW ticker_1Y_stats;
REFRESH MATERIALIZED VIEW ticker_AT_stats;
$$;
