from flask import Flask, request, render_template, jsonify, make_response
from flask_login import LoginManager
from server_utils.data_management import DataManager
import plotly
from plotly import express as px, graph_objects as go
import json
import pandas as pd
import os
from dotenv import load_dotenv

app = Flask(__name__)
dm = DataManager()
#lm = LoginManager()
#lm.init_app(app)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/login', methods=['POST'])
def login():
    if request.method=='POST':
        return

@app.route('/api/update')
def update():
    dm.add_missing_daily_data(refresh_views=True)
    res = make_response("Update complete!", 200)
    res.mimetype = 'text/plain'
    return res

@app.route('/api/add_tickers')
def add_tickers_to_db():
    new_tickers = request.args.getlist('tickers[]')
    print(new_tickers)

@app.route('/stock')
def get_market_data_page():
    tickers_info = dm.query_df('SELECT ticker, name, category FROM used_tickers ORDER BY ticker ASC').to_dict('records')
    indicators = dm.query_df('SELECT * FROM asset_indicators LIMIT 0').columns
    indicators_info = [{'indicator':column, 'explanation':'nan'} for column in indicators]
    
    prices_graphJSON = get_market_prices()
    indicators_table_html = get_market_indicators()
    
    return render_template('stock.html', linegraphJSON=prices_graphJSON, tickers_info=tickers_info, indicators_info=indicators_info, tableHTML=indicators_table_html)

@app.route('/stock/select')
def get_selected_market_data():
    selected_tickers = request.args.getlist('tickers[]')
    selected_daterange = request.args.get('date-range')
    selected_indicators = request.args.getlist('indicators[]')
    prices_chart = get_market_prices(tickers=selected_tickers, daterange=selected_daterange)
    indicators_table = get_market_indicators(tickers=selected_tickers, indicators=selected_indicators)
    data = {
        'chart': prices_chart,
        'table': indicators_table
    }
    
    return jsonify(data)

def get_market_prices(tickers=['NVDA'], daterange='1 year'):
    
    if not tickers:
        tickers = [""]

    print('querying df')
    prices_df = dm.query_df(
        'SELECT ticker, date, close AS "close" FROM clean_daily WHERE ticker IN {} AND date > CURRENT_DATE-interval \'{}\' ORDER BY date'.format(dm.tuple_string(tickers), daterange)
        )
    fig = px.line(prices_df, x='date', y='close', color='ticker')
    fig.update_layout( 
        margin=dict(l=0, r=0, t=0, b=0))
    
    prices_graphJSON = json.dumps(fig, cls=plotly.utils.PlotlyJSONEncoder)
    return prices_graphJSON

def get_market_indicators(tickers=['NVDA'], indicators='*'):
    if not tickers:
        tickers = [""]
    if not indicators:
        indicators = [""]

    indicators_query = 'SELECT {} FROM asset_indicators WHERE ticker IN {}'.format(dm.column_string(indicators), dm.tuple_string(tickers))
    print(indicators_query)
    indicators_df = dm.query_df(indicators_query)
    percentage_formatters = { key : '{:.2%}'.format for key, value in indicators_df.dtypes.items() if value == 'float64' }
    df_html = indicators_df.to_html(classes=["table-bordered", "table-striped", "table-hover"], formatters=percentage_formatters)
    return df_html

@app.route('/update')
def update_db():
    dm.add_missing_daily_data(refresh_views=True)
    print('updated data!')
    return 200

@app.route('/test')
def test():
    df = pd.DataFrame({
      "Fruit": ["Apples", "Oranges", "Bananas", "Apples", "Oranges", "Bananas"],
      "Amount": [4, 1, 2, 2, 4, 5],
      "City": ["SF", "SF", "SF", "Montreal", "Montreal", "Montreal"]
   })
    fig = px.bar(df, x="Fruit", y="Amount", color="City",    barmode="group")
    graphJSON = json.dumps(fig, cls=plotly.utils.PlotlyJSONEncoder)
    return render_template('test.html', graphJSON=graphJSON)

@app.route('/post/ticker/<string:ticker>,<string:name>')
def new_ticker(ticker, name):
    
    dm.add_ticker(ticker, name)
    return(f'Ticker requested: {ticker, name}')

if __name__ == '__main__':
    
    load_dotenv()
    app.run(host=os.getenv('HOST_IP'), port=os.getenv('HOST_PORT'), debug=True)
