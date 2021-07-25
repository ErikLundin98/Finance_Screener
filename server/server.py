from flask import Flask, request, render_template
from server_utils.data_management import DataManager
import plotly
from plotly import express as px
import json
import pandas as pd

app = Flask(__name__)
dm = DataManager()

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

@app.route('/prices')
def prices():
    print('querying df')
    df = dm.query_df('SELECT ticker, date, adjusted_close FROM clean_daily')
    fig = px.line(df, x='date', y='adjusted_close', color='ticker')
    graphJSON = json.dumps(fig, cls=plotly.utils.PlotlyJSONEncoder)
    print('returning it')
    print(df.head())
    return render_template('prices_chart.html', graphJSON=graphJSON)

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
