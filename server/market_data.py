from requests.api import get
import yfinance as yf
import pandas as pd

def get_daily_data_from_tickers(tickers:list, start:str, end:str):
    '''
    Uses yfinance to fetch data for a list of tickers for a specified period,
     processes it into a dataframe sorted by date
    '''
    data = yf.download(
        tickers = ' '.join(tickers),
        start=start,
        end=end,
        group_by='ticker'
    )
    # returns a multi-indexed pandas dataframe that needs to be processed!
    processed_df = pd.DataFrame()
    for i, ticker in enumerate(tickers):
        df = data[ticker]
        df['ticker'] = ticker # add ticker value as column
        if i == 0:
            processed_df = df
        else:
            processed_df = pd.concat([processed_df, df], axis=0) # concat dataframes


    processed_df.reset_index(level=0, inplace=True)
    colnames = list(processed_df.columns)
    colnames = [colname.lower() for colname in colnames] # colnames to lower case
    colnames[colnames.index('adj close')] = 'adjusted_close'
    processed_df.columns = colnames
    processed_df.sort_values(by='date', inplace=True) # sort by date
    return processed_df


if __name__ == '__main__':
    # test case
    data = get_daily_data_from_tickers(['AAPL', 'NVDA'], '2021-07-01', '2021-07-22')
    print(data)