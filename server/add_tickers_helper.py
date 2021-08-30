from server_utils.data_management import DataManager
import pandas as pd
import os

# filepath = os.path.join(os.getcwd(), 'misc/tickers.csv')
# print(filepath)
# df = pd.read_csv(os.path.join(os.getcwd(), 'server', 'misc', 'tickers.csv'), delimiter=';')
# print(df.head())

dm = DataManager()

# cryptos = [
#     {
#         'ticker': 'BTC-USD',
#         'name': 'Bitcoin',
#         'category': 'cryptocurrency',
#         'currency': 'USD'
#     },
#     {
#         'ticker': 'ETH-USD',
#         'name': 'Ethereum',
#         'category': 'cryptocurrency',
#         'currency': 'USD'
#     },
#     {
#         'ticker': 'ADA-USD',
#         'name': 'Cardano',
#         'category': 'cryptocurrency',
#         'currency': 'USD'
#     },
#     {
#         'ticker': 'DOT1-USD',
#         'name': 'Polkadot',
#         'category': 'cryptocurrency',
#         'currency': 'USD'
#     },
#     {
#         'ticker': 'BNB-USD',
#         'name': 'BinanceCoin',
#         'category': 'cryptocurrency',
#         'currency': 'USD'
#     },
#     {
#         'ticker': 'SOL1-USD',
#         'name': 'Solana',
#         'category': 'cryptocurrency',
#         'currency': 'USD'
#     },
# ]
# for d in cryptos:
#     dm.add_ticker(d['ticker'], d['name'], d['category'], d['currency'], refresh_views=False)

#dm.add_daily_data(['SBB-B.ST','BTC-USD','ETH-USD','ADA-USD'], '2000-01-01', '2020-08-30')
dm.add_daily_data(['ADA-USD'], '2000-01-01', '2020-08-30')
