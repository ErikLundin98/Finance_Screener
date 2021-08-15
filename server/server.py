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
    returns_graphJSON = get_market_data()
    return render_template('stock.html', linegraphJSON=returns_graphJSON, tickers_info=tickers_info)#, dailyreturntableJSON=today_returns_graphJSON)

@app.route('/stock/select')
def get_selected_market_data():
    selected_tickers = request.args.getlist('data[]')
    print(selected_tickers)

    return get_market_data(tickers=selected_tickers)

def get_market_data(tickers=['NVDA']):
    print(tickers)
    print('querying df')
    returns_df = dm.query_df(
        'SELECT ticker, date, arithmetic_return FROM daily_returns WHERE date > CURRENT_DATE-30 AND ticker IN {}'.format(dm.tuple_string(tickers))
        )
    fig = px.line(returns_df, x='date', y='arithmetic_return', color='ticker')
    fig.update_layout(
        yaxis_tickformat='.001%', 
        margin=dict(l=0, r=0, t=0, b=0))
    
    returns_graphJSON = json.dumps(fig, cls=plotly.utils.PlotlyJSONEncoder)
    return returns_graphJSON

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
