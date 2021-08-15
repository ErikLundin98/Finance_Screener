from flask import Flask, request, render_template, jsonify
from flask_login import LoginManager
from server_utils.data_management import DataManager
import plotly
from plotly import express as px, graph_objects as go
import json
import pandas as pd

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

@app.route('/hello')
def hello():
    return render_template('hello.html')

@app.route('/stock')
def get_market_data_page():
    tickers_info = dm.query_df('SELECT ticker, company_name, category FROM used_tickers ORDER BY ticker ASC').to_dict('records')
    prices_graphJSON = get_market_data()
    return render_template('stock.html', linegraphJSON=prices_graphJSON, tickers_info=tickers_info)#, dailyreturntableJSON=today_prices_graphJSON)

@app.route('/stock/select')
def get_selected_market_data():
    selected_tickers = request.args.getlist('tickers[]')
    selected_daterange = request.args.get('date-range')
    print(selected_tickers, selected_daterange)

    return get_market_data(tickers=selected_tickers, daterange=selected_daterange)

def get_market_data(tickers=['NVDA'], daterange='1 year'):
    
    if not tickers:
        tickers = [""]

    print('querying df')
    prices_df = dm.query_df(
        'SELECT ticker, date, adjusted_close AS "adjusted close" FROM clean_daily WHERE date > CURRENT_DATE-interval \'{}\' AND ticker IN {}'.format(daterange, dm.tuple_string(tickers))
        )
    fig = px.line(prices_df, x='date', y='adjusted close', color='ticker')
    fig.update_layout(
        #yaxis_tickformat='.001%', 
        margin=dict(l=0, r=0, t=0, b=0))
    
    prices_graphJSON = json.dumps(fig, cls=plotly.utils.PlotlyJSONEncoder)
    return prices_graphJSON

@app.route('/update')
def update_db():
    dm.add_missing_daily_data()
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
    app.run(host='127.0.0.1', port=5000, debug=True)
