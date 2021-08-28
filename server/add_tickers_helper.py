from server_utils.data_management import DataManager
import pandas as pd
import os

filepath = os.path.join(os.getcwd(), 'misc/tickers.csv')
print(filepath)
df = pd.read_csv(os.path.join(os.getcwd(), 'server', 'misc', 'tickers.csv'), delimiter=';')
print(df.head())

dm = DataManager()

for index, row in df.iterrows():
    print(index)
    dm.add_ticker(row['ticker'], row['name'], row['category'], row['currency'], refresh_views=False)