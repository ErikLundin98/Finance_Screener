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
    # today_returns_graphJSON = json.dumps(table, cls=plotly.utils.PlotlyJSONEncoder)