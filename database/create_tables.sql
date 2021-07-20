/*Table that contains the list of tickers that are to be used in the database*/

DROP TABLE IF EXISTS USED_TICKERS;

CREATE TABLE USED_STOCKS(
    ticker varchar(8),
    company_name varchar(30),
);

/*Table that contains the main datasource*/

DROP TABLE IF EXISTS DAILY;

CREATE TABLE DAILY(
    date date,
    ticker varchar(8),
    open numeric,
    close numeric,
    high numeric,
    low numeric,
    volume int,
    FOREIGN KEY(ticker) REFERENCES USED_STOCKS(ticker)
);
/*TimescaleDB hypertable*/
SELECT create_hypertable('DAILY_STOCKS', 'date');