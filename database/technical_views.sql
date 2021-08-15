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

SELECT * FROM asset_indicators;