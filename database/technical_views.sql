/*Technical analysis view for all assets in database*/

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

SELECT geomean(arithmetic_return) FROM daily_returns WHERE date > '2006-01-01' GROUP BY TICKER;

DROP MATERIALIZED VIEW IF EXISTS asset_indicators;
CREATE MATERIALIZED VIEW asset_indicators
AS 
WITH one_year AS (
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
        avg(logarithmic_return) AS AT_log_aritmean
    FROM daily_returns WHERE date >= (SELECT MAX(first_date) FROM used_dates)
    GROUP BY ticker
)
SELECT 
    used_tickers.ticker,
    ONE_Y_arit_stdev, ONE_Y_arit_geomean, ONE_Y_log_stdev, ONE_Y_log_aritmean,
    AT_arit_stdev, AT_arit_geomean, AT_log_stdev, AT_log_aritmean
    FROM used_tickers
    JOIN one_year ON used_tickers.ticker = one_year.ticker
    JOIN all_time ON one_year.ticker = all_time.ticker;