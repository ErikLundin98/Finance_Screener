from flask import Flask, request, render_template
from server_utils.data_management import DataManager

app = Flask(__name__)
#data_manager = DataManager()

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/login', methods=['POST'])
def login():
    if request.method=='POST':
        print('logged in!')
        return index()

@app.route('/hello')
def hello():
    return render_template('hello.html')

@app.route('/post/ticker/<string:ticker>,<string:name>')
def new_ticker(ticker, name):
    
    data_manager.add_ticker(ticker, name)
    return(f'Ticker requested: {ticker, name}')

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=5000, debug=True)
