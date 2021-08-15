CREATE OR REPLACE FUNCTION portfolio_prices_JSON(user_name VARCHAR(30))
RETURNS TABLE(date DATE, ticker_info jsonb) 
LANGUAGE SQL
AS
$$
SELECT d.date AS date, 
       JSONB_OBJECT_AGG(d.ticker, d.adjusted_close) as ticker_info
FROM daily d
WHERE d.ticker IN (SELECT ticker FROM portfolios WHERE portfolios.user_name=user_name)
GROUP BY d.date
ORDER BY date ASC
$$;


CREATE OR REPLACE FUNCTION get_portfolio_query()
RETURNS text
LANGUAGE plpgsql
AS
$$
    DECLARE
        temprow record;
        str_query text := 'SELECT DISTINCT(t1.date) AS date';
        prev_table text := 't1';
    BEGIN
        FOR temprow IN SELECT * FROM portfolios WHERE user_name='snigelnmjau'
        LOOP
            str_query := str_query || format(', %s.adjusted_close AS %s', temprow.ticker, temprow.ticker);
        END LOOP;

        str_query := str_query || format(' FROM clean_daily AS t1 ');

        FOR temprow IN SELECT * FROM portfolios WHERE user_name='snigelnmjau'
        LOOP
            str_query := str_query || format(E'INNER JOIN clean_daily AS %s ON %s.date=%s.date AND %s.ticker=''%s'' ', temprow.ticker, prev_table, temprow.ticker, temprow.ticker, temprow.ticker);
            prev_table := temprow.ticker;
        END LOOP;
        str_query := str_query || 'ORDER BY t1.date DESC;';

        --EXECUTE str_query;
        RETURN str_query;
    END;
$$;

