from server_utils.data_management import DataManager
import pandas as pd
import os
import time


# filepath = os.path.join(os.getcwd(), 'misc/tickers.csv')
# print(filepath)
# df = pd.read_csv(os.path.join(os.getcwd(), 'server', 'misc', 'tickers.csv'), delimiter=';')
# print(df.head())



dm = DataManager()
dm.add_missing_daily_data(safe_mode=True)
# ticker_batch_size = 1
# all_tickers = dm.get_tickers()
# ticker_groups = [all_tickers[i:min(len(all_tickers), i+ticker_batch_size)] for i in range(0, len(all_tickers), ticker_batch_size)] # groups of 

# time_to_sleep = 1
# n_groups = len(ticker_groups)
# print(f'expected time: > {time_to_sleep*n_groups} seconds')
# for i, group in enumerate(ticker_groups):
    
#     print(f'{i}/{n_groups-1}')
#     dm.add_daily_data(group, '2021-08-26', '2021-09-01', do_on_conflict='(ticker, date) DO UPDATE SET open=EXCLUDED.open, close=EXCLUDED.close, \
#                     adjusted_close=EXCLUDED.adjusted_close, high=EXCLUDED.high, low=EXCLUDED.low, volume=EXCLUDED.volume')
#     time.sleep(time_to_sleep)