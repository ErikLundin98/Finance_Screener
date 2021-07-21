DROP TABLE IF EXISTS used_stocks CASCADE;
DROP TABLE IF EXISTS daily CASCADE;

/*Table that contains the list of tickers that are to be used in the database*/


CREATE TABLE used_stocks(
    ticker varchar(8) PRIMARY KEY,
    company_name varchar(30)
);

/*Table that contains the main datasource*/

CREATE TABLE daily(
    date DATE NOT NULL,
    ticker varchar(8),
    open FLOAT(2),
    close FLOAT(2),
    high FLOAT(2),
    low FLOAT(2),
    volume INT,
    FOREIGN KEY(ticker) REFERENCES USED_STOCKS(ticker)
);
/*TimescaleDB hypertable*/
SELECT create_hypertable('DAILY', 'date');