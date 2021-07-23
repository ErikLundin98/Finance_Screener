import db_utils as dbu
import market_data as mdata
from dotenv import load_dotenv
import os
from datetime import datetime

load_dotenv()

SQL_UNAME = os.getenv('PGSQL_USERNAME')
SQL_PASSWORD = os.getenv('PGSQL_PASSWORD')
SQL_HOST = os.getenv('PGSQL_HOST')
SQL_PORT = os.getenv('PGSQL_PORT')
DATABASE_NAME = os.getenv('DATABASE_NAME')

cursor, connection = dbu.get_connectors(host=SQL_HOST, user=SQL_UNAME, password=SQL_PASSWORD, database=DATABASE_NAME)


dbu.insert_row(connection, cursor, 'USED_STOCKS', ('ticker', 'company_name'), ('AAPL', 'Apple'))
dbu.insert_row(connection, cursor, 'USED_STOCKS', ('ticker', 'company_name'), ('NVDA', 'Nvidia'))

cursor.execute('SELECT * FROM USED_STOCKS')
print(cursor.fetchone())

cursor.execute('SELECT * FROM DAILY')
print(cursor.fetchone())

# daily_columns = ('date', 'ticker', 'open', 'close', 'high', 'low', 'volume')

# dummy_data = [
#     (dbu.str_to_date('2020-01-01'), 'AAPL', 1000.10, 990, 2000, 500, 100000),
#     (dbu.str_to_date('2020-01-02'), 'AAPL', 990, 990, 2000, 500, 100000),
# ]



daily_data, colnames = mdata.get_daily_data_from_tickers(['AAPL', 'NVDA'], '2020-01-01', '2021-07-22')

dbu.insert_rows(connection=connection, 
                cursor=cursor, 
                table_name='daily', 
                columns=colnames, 
                data=daily_data, 
                )

cursor.execute('SELECT * FROM daily;')
print(cursor.fetchone())

cursor.close()
