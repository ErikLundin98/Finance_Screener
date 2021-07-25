DROP TABLE IF EXISTS used_tickers CASCADE;
DROP TABLE IF EXISTS daily CASCADE;

/*Table that contains the list of tickers that are to be used in the database*/


CREATE TABLE used_tickers(
    ticker varchar(16) PRIMARY KEY,
    company_name varchar(30),
    currency varchar(3)
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

/*Table with investors*/
CREATE TABLE investors(
    user_name VARCHAR(30) NOT NULL PRIMARY KEY,
    birth_date DATE,
    favorite_quote VARCHAR(200)
);
/*Table with portfolios*/
CREATE TABLE portfolios(
    user_name VARCHAR(30),
    ticker varchar(16),
    amount INT,
    FOREIGN KEY(user_name) REFERENCES investors(user_name),
    FOREIGN KEY(ticker) REFERENCES used_tickers(ticker),
    PRIMARY KEY(user_name, ticker)
);
