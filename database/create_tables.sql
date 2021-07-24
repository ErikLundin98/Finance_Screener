DROP VIEW IF EXISTS used_dates;
DROP TABLE IF EXISTS used_tickers CASCADE;
DROP TABLE IF EXISTS daily CASCADE;

/*Table that contains the list of tickers that are to be used in the database*/


CREATE TABLE used_tickers(
    ticker varchar(16) PRIMARY KEY,
    company_name varchar(30)
);

/*Table that contains the main datasource*/

CREATE TABLE daily(
    date DATE NOT NULL,
    ticker varchar(16),
    open FLOAT(6),
    close FLOAT(6),
    adjusted_close FLOAT(6),
    high FLOAT(6),
    low FLOAT(6),
    volume INT,
    FOREIGN KEY(ticker) REFERENCES used_tickers(ticker)
);

CREATE UNIQUE INDEX ON daily(date, ticker);

/*TimescaleDB hypertable*/
SELECT create_hypertable('daily', 'date');
/*Shows the latest updated dates (lazy check)*/
CREATE VIEW used_dates AS SELECT ticker, MIN(date) as "first_date", MAX(date) AS "last_date" FROM daily GROUP BY ticker ORDER BY ticker ASC;