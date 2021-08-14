from flask import Flask, request, render_template
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
def prices():
    print('querying df')
    returns_df = dm.query_df('SELECT ticker, date, arithmetic_return FROM daily_returns WHERE date > CURRENT_DATE-30')
    fig = px.line(returns_df, x='date', y='arithmetic_return', color='ticker')
    fig.update_layout(
        yaxis_tickformat='.001%', 
        margin=dict(l=20, r=20, t=20, b=20))
    #tickers = dm.get_tickers()
    tickers_info = dm.query_df('SELECT ticker, company_name, category FROM used_tickers ORDER BY ticker ASC').to_dict('records')
    print(tickers_info)
    # df = dm.query_df('SELECT ticker, arithmetic_return from daily_returns WHERE date = (SELECT MAX(date) FROM daily_returns)')
    # df['arithmetic_return'] = df['arithmetic_return'].astype(float).map("{:.2%}".format)
    # table = go.Figure(data=[go.Table(
    #                     columnwidth=[7, 5],
    #                     header=dict(values=['Stock', 'Daily return'],
    #                                 fill_color='paleturquoise',
    #                                 align='right'),
    #                     cells=dict(values=[df.ticker, df.arithmetic_return],
    #                             fill_color='lavender',
    #                             align='right'))
    #                 ])
    returns_graphJSON = json.dumps(fig, cls=plotly.utils.PlotlyJSONEncoder)
    # today_returns_graphJSON = json.dumps(table, cls=plotly.utils.PlotlyJSONEncoder)
    return render_template('stock.html', linegraphJSON=returns_graphJSON, tickers_info=tickers_info)#, dailyreturntableJSON=today_returns_graphJSON)


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
