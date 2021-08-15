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
WITH one_year AS (
    SELECT
        ticker,
        stddev(arithmetic_return) AS ONE_Y_arit_stdev,
        geomean(arithmetic_return) AS ONE_Y_arit_geomean,
        stddev(logarithmic_return) AS ONE_Y_log_stdev,
        avg(logarithmic_return) AS ONE_Y_log_aritmean,
        CURRENT_DATE - interval '1 year' AS ONE_Y_first_date,
        (SELECT range_arit_return(ticker, CAST(CURRENT_DATE - interval '1 year' AS DATE), CURRENT_DATE)) AS ONE_Y_arit_return
    FROM daily_returns WHERE date >= ONE_Y_first_date
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
    FROM daily_returns WHERE date >= AT_first_date
    GROUP BY ticker
)
SELECT 
    used_tickers.ticker,
    ONE_Y_arit_stdev, ONE_Y_arit_geomean, ONE_Y_log_stdev, ONE_Y_log_aritmean,
    AT_arit_stdev, AT_arit_geomean, AT_log_stdev, AT_log_aritmean
    FROM used_tickers
    JOIN one_year ON used_tickers.ticker = one_year.ticker
    JOIN all_time ON one_year.ticker = all_time.ticker;