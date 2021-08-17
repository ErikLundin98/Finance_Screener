/*TODO: remove non-null values from this view*/
DROP MATERIALIZED VIEW IF EXISTS clean_daily CASCADE;
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
ORDER BY DATE;

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

DROP MATERIALIZED VIEW IF EXISTS asset_indicators;
CREATE MATERIALIZED VIEW asset_indicators
AS 
WITH dates AS (
    SELECT
        CURRENT_DATE AS today,
        CAST(CURRENT_DATE - interval '1 year' AS DATE) AS ONE_Y_first_date,
        (SELECT MAX(first_date) FROM used_dates) AS AT_first_date,
        (SELECT MIN(last_date) FROM used_dates) AS AT_last_date
),
ticker_returns AS (
    SELECT
        used_tickers.ticker AS ticker,
        range_return(used_tickers.ticker, dates.ONE_Y_first_date, dates.today, 'arit') AS ONE_Y_arit_return,
        range_return(used_tickers.ticker, dates.AT_first_date, dates.AT_last_date, 'arit') AS ALL_SAME_T_arit_return,
        range_return(used_tickers.ticker, used_dates.first_date, used_dates.last_date, 'arit') AS ALL_T_arit_return
    FROM used_tickers, dates, used_dates
    WHERE used_tickers.ticker = used_dates.ticker
),
one_year AS (
    SELECT
        ticker,
        stddev(arithmetic_return) AS ONE_Y_arit_stdev,
        geomean(arithmetic_return) AS ONE_Y_arit_geomean,
        stddev(logarithmic_return) AS ONE_Y_log_stdev,
        avg(logarithmic_return) AS ONE_Y_log_aritmean
    FROM daily_returns WHERE date >= CURRENT_DATE - interval '1 year'
    GROUP BY ticker
),
all_time AS (
    SELECT
        ticker,
        stddev(arithmetic_return) AS LCT_arit_stdev,
        geomean(arithmetic_return) AS LCT_arit_geomean,
        stddev(logarithmic_return) AS LCT_log_stdev,
        avg(logarithmic_return) AS LCT_log_aritmean,
        (SELECT MAX(first_date) FROM used_dates AS LCT_first_date)
    FROM daily_returns, dates WHERE date <= dates.AT_last_date AND date >= dates.AT_first_date
    GROUP BY ticker
)
SELECT 
    used_tickers.ticker AS ticker,
    ticker_returns.ONE_Y_arit_return AS "one year arithmetic return", 
    ticker_returns.ALL_SAME_T_arit_return AS "longest common timespan arithmetic return", 
    ticker_returns.ALL_T_arit_return AS "all time arithmetic return",
    ONE_Y_arit_stdev*SQRT(253) AS "(arithetic return) one year volatility", 
    ONE_Y_arit_geomean AS "(arithetic return) one year geometric mean", 
    ONE_Y_log_stdev*SQRT(253) AS "(logarithmic return) one year volatility", 
    ONE_Y_log_aritmean AS "(logarithmic return) one year arithmetic mean",
    LCT_arit_stdev*SQRT(253) AS "(arithmetic return) longest common timespan volatility", 
    LCT_arit_geomean AS "(arithmetic return) longest common timespan geometric mean", 
    LCT_log_stdev*SQRT(253) AS "(logarithmic return) longest common timespan volatility", 
    LCT_log_aritmean AS "(logarithmic return) longest common timespan arithmetic mean"
    FROM used_tickers
    JOIN one_year ON used_tickers.ticker = one_year.ticker
    JOIN all_time ON one_year.ticker = all_time.ticker
    JOIN ticker_returns ON ticker_returns.ticker = used_tickers.ticker;


/* PROCEDURE to refresh views*/

CREATE OR REPLACE PROCEDURE refresh_views()
LANGUAGE SQL
AS
$$
REFRESH MATERIALIZED VIEW used_dates;
REFRESH MATERIALIZED VIEW clean_daily;
REFRESH MATERIALIZED VIEW daily_returns;
REFRESH MATERIALIZED VIEW asset_indicators;
$$;

CALL refresh_views();
