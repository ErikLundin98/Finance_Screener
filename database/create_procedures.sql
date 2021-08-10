CREATE OR REPLACE FUNCTION portfolio_prices_JSON(user_name VARCHAR(30))
RETURNS TABLE(date DATE, ticker_info jsonb) AS
$$

SELECT d.date AS date, 
       JSONB_OBJECT_AGG(d.ticker, d.adjusted_close) as ticker_info
FROM daily d
WHERE d.ticker IN (SELECT ticker FROM portfolios WHERE portfolios.user_name=user_name)
GROUP BY d.date
ORDER BY date ASC

$$
LANGUAGE SQL;

SELECT * FROM portfolio_prices_JSON('snigeln_mjau')
/*
DECLARE @cols AS NVARCHAR(MAX), @query  AS NVARCHAR(MAX);

select @cols = STUFF((SELECT distinct ',' + QUOTENAME(c.ticker) 
FROM daily c
    FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)') 
,1,1,'')


set @query = 'SELECT [date], ' + @cols + ' from 
        (
           SELECT  [date]
           ,[ticker]
           ,[adjusted_close]
           FROM daily
        ) x
        pivot 
        (
            min([adjusted_close])
            for [ticker] in (' + @cols + ')
        ) p '

execute(@query)
*/