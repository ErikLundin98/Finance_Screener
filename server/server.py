from flask import Flask, request
from data_management import DataManager

app = Flask(__name__)
data_manager = DataManager()

@app.route('/')
def base():
    return 'hello world!'

@app.route('/post/ticker/<string:ticker>,<string:name>')
def new_ticker(ticker, name):
    
    data_manager.add_ticker(ticker, name)
    return(f'Ticker requested: {ticker, name}')

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=5000, debug=True)
