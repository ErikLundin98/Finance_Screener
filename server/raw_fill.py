from datetime import datetime

from data_management import DataManager

dm = DataManager()


# dm.add_ticker('AMD', 'Advanced Micro Devices, Inc.')
# dm.add_ticker('INVE-B.ST', 'Investor AB (publ)')
# dm.add_ticker('NAS.OL', 'Norwegian Air Shuttle')
# dm.add_ticker('VOLV-B.ST', 'Volvo B')

# tickers = dm.get_tickers()
# print(tickers)
# dm.add_daily_data(tickers, '2000-01-01', datetime.today().date())

dm.add_ticker('GME', 'GameStop Corp.')