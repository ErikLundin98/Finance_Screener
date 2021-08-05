# Finance_Screener

**DISCLAIMER: This project is still in progress**


## Purpose & Overview

This projects purpose is to build a financial instrument screener service that I and others can use for free to analyze financial assets. The plan is to offer the following functionality to the user:

- Query prices and other relevant information for ~1000 stocks and other assets
- Sort and filter assets by performance
- Visualize these assets and their development over time with charts
- Provide metrics and indicators that are useful for quantitative analysis
- Allow the user to save/update their portfolio and monitor relevant measures (including risk metrics as Value-at-Risk, volatility etc)
- Provide forecasts from various machine learning models to assist the user with their analysis

## Architectural overview

The service will consist of these three standard-components:
- Front end client
- Server
- Database

### Front end client

The client is the part that the user will interact with. It provides an interface that the user uses to send requests to the server using HTTP requests.

Currently, the plan is to implement the front end using **standard HTML/CSS/JavaScript**

### Server

The server serves the client to the user when the user makes their initial request and serves the client with data and information that the client wants. It servers the client with data by executing queries to the database. The server is also responsible for updating the database with new instrument data.

The plan is to implement the server using **Flask**, a Python web framework.

### Database

Contains all the financial instrument data, as well as user data such as portfolio info. 

The database will be implemented with **TimescaleDB**