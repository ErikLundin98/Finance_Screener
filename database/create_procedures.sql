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
            str_query := str_query || format(', %s.close AS %s', temprow.ticker, temprow.ticker);
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


CREATE OR REPLACE FUNCTION range_logarithmic_return(in_ticker TEXT, startd DATE, endd DATE)
RETURNS float8
LANGUAGE plpgsql
AS
$$
DECLARE
    ret float8;
BEGIN
    SELECT LN(tend.close/tstart.close) INTO ret 
    FROM clean_daily AS tend, clean_daily AS tstart
    WHERE tend.date = endd AND tend.ticker = in_ticker
    AND tstart.date = startd AND tstart.ticker = in_ticker
    LIMIT 1;

    RETURN ret;
END;
$$;

CREATE OR REPLACE FUNCTION range_arithmetic_return(in_ticker TEXT, startd DATE, endd DATE)
RETURNS float8
LANGUAGE plpgsql
AS
$$
DECLARE
    ret float8;
BEGIN
    SELECT tend.close/tstart.close - 1 INTO ret 
    FROM clean_daily AS tend, clean_daily AS tstart
    WHERE tend.date = endd AND tend.ticker = in_ticker
    AND tstart.date = startd AND tstart.ticker = in_ticker
    LIMIT 1;
    
    RETURN ret;
END;
$$;