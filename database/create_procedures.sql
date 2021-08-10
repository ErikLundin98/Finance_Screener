CREATE OR REPLACE PROCEDURE portfolio_returns(user_name VARCHAR(30))
RETURNS TABLE AS
$$
SELECT 
$$
LANGUAGE SQL;

WITH ctx AS (
    SELECT date,
            ticker,
            adjusted_close
            

)

with context as(select ticker,
                    name, 
                    row_number() over(partition by id order by name) as rn
             from table_name)
select id,
        [1] as name1,
        [2] as name2,
        [3] as name3
 from cte
 pivot(max(name) for rn in([1],[2],[3]))p