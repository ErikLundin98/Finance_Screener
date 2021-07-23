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
    open FLOAT(6),
    close FLOAT(6),
    adjusted_close FLOAT(6),
    high FLOAT(6),
    low FLOAT(6),
    volume INT,
    FOREIGN KEY(ticker) REFERENCES USED_STOCKS(ticker)
);

/*TimescaleDB hypertable*/
SELECT create_hypertable('daily', 'date');