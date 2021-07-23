from typing import Any
import db_utils as dbu
import market_data as mdata
from dotenv import load_dotenv
import os
from datetime import datetime

class DataManager:
    def __init__(self):
        load_dotenv()
        self.SQL_UNAME = os.getenv('PGSQL_USERNAME')
        self.SQL_PASSWORD = os.getenv('PGSQL_PASSWORD')
        self.SQL_HOST = os.getenv('PGSQL_HOST')
        self.SQL_PORT = os.getenv('PGSQL_PORT')
        self.DATABASE_NAME = os.getenv('DATABASE_NAME')


        self.cursor, self.connection = dbu.get_connectors(host=self.SQL_HOST, 
                                                            user=self.SQL_UNAME, 
                                                            password=self.SQL_PASSWORD, 
                                                            database=self.DATABASE_NAME)

    def add_ticker(self, ticker:str, name:str):
        dbu.insert_row(self.connection, self.cursor, 'used_stocks', ('ticker', 'company_name'), (ticker, name))

    def data_query(self, query:str) -> Any:
        self.cursor.execute(query)
        return self.cursor.fetchall()


    def add_daily_data(self, tickers, start_date, end_date):
        daily_data, colnames = mdata.get_daily_data_from_tickers(tickers, start_date, end_date)

        dbu.insert_rows(connection=self.connection, 
                        cursor=self.cursor, 
                        table_name='daily', 
                        columns=self.colnames, 
                        data=self.daily_data, 
                        )

    def add_missing_daily_data(self):
        tickers_and_dates = self.data_query('SELECT ticker, last_date FROM last_dates')
        tickers, dates = zip(*tickers_and_dates) # unpack into two lists
        start_date = min(dates)
        end_date = datetime.now().date()
        print(tickers, start_date, end_date)
        self.add_daily_data(tickers, start_date, end_date)

    def __del__(self):
        self.cursor.close()