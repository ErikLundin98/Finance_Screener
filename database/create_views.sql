
/*Shows the latest updated dates (lazy check)*/
CREATE OR REPLACE MATERIALIZED VIEW used_dates AS 
SELECT ticker, first(date, date) as "first_date", last(date, date) AS "last_date" 
FROM daily 
GROUP BY ticker 
ORDER BY ticker ASC;

CREATE OR REPLACE MATERIALIZED VIEW clean_daily AS
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

CREATE OR REPLACE MATERIALIZED VIEW daily_returns AS
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
        (SELECT MAX(first_date) FROM used_dates AS AT_first_date)
),
ticker_returns AS (
    SELECT
        ticker,
        range_return(ticker, dates.ONE_Y_first_date, dates.today, 'arit') AS ONE_Y_arit_return
    FROM used_tickers, dates
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
        stddev(arithmetic_return) AS AT_arit_stdev,
        geomean(arithmetic_return) AS AT_arit_geomean,
        stddev(logarithmic_return) AS AT_log_stdev,
        avg(logarithmic_return) AS AT_log_aritmean,
        (SELECT MAX(first_date) FROM used_dates AS AT_first_date)
    FROM daily_returns WHERE date >= (SELECT MAX(first_date) FROM used_dates)
    GROUP BY ticker
)
SELECT 
    used_tickers.ticker,
    ticker_returns.ONE_Y_arit_return,
    ONE_Y_arit_stdev, ONE_Y_arit_geomean, ONE_Y_log_stdev, ONE_Y_log_aritmean,
    AT_arit_stdev, AT_arit_geomean, AT_log_stdev, AT_log_aritmean
    FROM used_tickers
    JOIN one_year ON used_tickers.ticker = one_year.ticker
    JOIN all_time ON one_year.ticker = all_time.ticker
    JOIN ticker_returns ON ticker_returns.ticker = used_tickers.ticker;


/* PROCEDURE to refresh views*/

CREATE OR REPLACE PROCEDURE refresh_views()
LANGUAGE SQL
RETURNS TRIGGER
AS
$$
REFRESH MATERIALIZED VIEW used_dates;
REFRESH MATERIALIZED VIEW clean_daily;
REFRESH MATERIALIZED VIEW daily_returns;
REFRESH MATERIALIZED VIEW asset_indicators;
$$;

CREATE OR REPLACE FUNCTION trigger_refresh_views_function() 
   RETURNS TRIGGER 
   LANGUAGE PLPGSQL
AS $$
BEGIN
   CALL refresh_views();
   RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_refresh_views ON daily;
CREATE TRIGGER trigger_refresh_views
AFTER INSERT ON daily FOR EACH STATEMENT
EXECUTE PROCEDURE trigger_refresh_views_function();

