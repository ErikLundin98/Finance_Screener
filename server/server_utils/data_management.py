from typing import Any
import server_utils.db_utils as dbu
import server_utils.market_data as mdata
from dotenv import load_dotenv
import os
import datetime
import pandas as pd
import pandas.io.sql as pdsqlio
from collections import defaultdict
import time
from tqdm import tqdm

class DataManager:
    '''
    Manager class to manage the finance screener database
    '''
    def __init__(self):
        load_dotenv()
        self.SQL_UNAME = os.getenv('PGSQL_USERNAME')
        self.SQL_PASSWORD = os.getenv('PGSQL_PASSWORD')
        self.SQL_HOST = os.getenv('PGSQL_HOST')
        self.SQL_PORT = os.getenv('PGSQL_PORT')
        self.DATABASE_NAME = os.getenv('DATABASE_NAME')
        self.START_DATE = datetime.datetime.strptime(os.getenv('START_DATE'), '%Y-%m-%d')

        try:
            self.cursor, self.connection = dbu.get_connectors(host=self.SQL_HOST, 
                                                                user=self.SQL_UNAME, 
                                                                password=self.SQL_PASSWORD, 
                                                                database=self.DATABASE_NAME)
        except Exception as e:
            print('There was an error while instantiating the DataManager object:', e)

    def add_ticker(self, ticker:str, name:str, category:str = 'stock', currency:str = 'USD', refresh_views:bool = True):
        '''
        Adds a ticker to the database, and populates the database with daily prices for that ticker
        '''
        if ticker not in self.get_tickers():
            dbu.insert_row(self.connection, self.cursor, 'used_tickers', ('ticker', 'name', 'category', 'currency'), (ticker, name, category, currency))
            # we also want to populate daily with data for the new ticker
            print('fetching data and adding to db')
            self.add_daily_data([ticker], self.START_DATE, datetime.date.today())
            if refresh_views:
                print('refreshing views...')
                self.data_query('CALL refresh_views();', get_output=False)
            print('done')

    def add_user(self, user_name:str, birth_year:Any, favorite_quote:str=''):
        '''
        Adds a user to the database
        '''
        if not favorite_quote:
            favorite_quote = ''
        dbu.insert_row(self.connection, self.cursor, 'investors', ('user_name', 'birth_date', 'favorite_quote'), (user_name, birth_year, favorite_quote))
        self.connection.commit()

    def add_to_portfolio(self, user_name:str, tickers:list, amounts:list):
        '''
        Function to update a user's portfolio
        '''
        data = [(user_name, ticker, amount) for ticker, amount in zip(tickers, amounts)]
        dbu.insert_rows(self.connection, self.cursor, 'portfolios', ('user_name', 'ticker', 'amount'), data)
        self.connection.commit()

    def data_query(self, query:str, get_output=True) -> Any:
        '''
        Helper function to execute a query

        get_output: Determines if output from query should be returned
        '''
        self.cursor.execute(query)
        if get_output:
            return self.cursor.fetchall()

    def get_tickers(self):
        '''
        Helper function to get all tickers as a Python list
        '''
        return [tuple[0] for tuple in self.data_query('SELECT ticker FROM used_tickers;')]

    def add_daily_data(self, tickers:list, start_date, end_date, do_on_conflict='DO NOTHING', proxy=None, supress_output=True):
        '''
        Add daily data for a specific list of tickers and a start and end date
        '''
        daily_data, colnames = mdata.get_daily_data_from_tickers(tickers, start_date, end_date, proxy=proxy, supress_output=supress_output)

        dbu.insert_rows(connection=self.connection, 
                        cursor=self.cursor, 
                        table_name='daily', 
                        columns=colnames, 
                        data=daily_data, 
                        do_on_conflict=do_on_conflict
                        )
        print('rows inserted')
        self.connection.commit()

    def add_missing_daily_data(self, refresh_views=True, safe_mode=True):
        tickers_and_dates = self.data_query('SELECT ticker, last_date FROM used_dates;')
        tickers, dates = zip(*tickers_and_dates) # unpack into two lists
        end_date = datetime.date.today() + datetime.timedelta(days=2)
        do_on_conflict = '(ticker, date) DO UPDATE SET open=EXCLUDED.open, close=EXCLUDED.close, \
                    adjusted_close=EXCLUDED.adjusted_close, high=EXCLUDED.high, low=EXCLUDED.low, volume=EXCLUDED.volume'
        # group tickers requiring the same amount of new days worth of data
        if not safe_mode:
            
            for i, date in enumerate(dates):
                d.setdefault(date, []).append(i)

            for start_date, ticker_indices in d.items():
                same_date_tickers = [tickers[i] for i in ticker_indices] 
                print(same_date_tickers, start_date)
                self.add_daily_data(same_date_tickers, start_date, end_date, do_on_conflict=do_on_conflict)
        else:
            for ticker, start_date in zip(tickers, dates):
                print(ticker, start_date)
                self.add_daily_data([ticker], start_date, end_date, do_on_conflict=do_on_conflict, supress_output=True)
                time.sleep(1)
        
        
        if refresh_views:
            print('refreshing views')
            self.data_query('CALL refresh_views();', get_output=False)
        self.connection.commit()


    def query_df(self, query:str) -> pd.DataFrame:
        return pdsqlio.read_sql_query(query, self.connection)

    def tuple_string(self, elements):
        return '('+', '.join(f'\'{element}\'' for element in elements)+')'

    def column_string(self, elements, relation_prefix=''):
        return ', '.join(f'{relation_prefix}{element}' for element in elements)

    def __del__(self):
        self.cursor.close()
        self.connection.close()
