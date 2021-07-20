'''
This module contains utilities for connecting to the TimescaleDB server, querying and inserting data and other related use cases
'''
from typing import Any
import psycopg2

def get_connectors(CONNECTION: str):
    '''
    Get the objects needed to interact with the database

    Keyword arguments:
    CONNECTION -- String of the form "postgres://username:password@host:port/dbname"

    Returns:
    connection: sql connection object
    cursor: cursor object that is used to execute queries agains the database
    '''
    connection = psycopg2.connect(CONNECTION)
    cursor = connection.cursor()

    return cursor, connection

def insert_row(connection:Any, cursor:Any, table_name:str, tuple:Any):
    '''
    Insert single row into a specified table

    Keyword arguments:
    cursor: cursor object
    table_name: the name of the table to insert to
    data: the data to insert. Either a tuple or a list of tuples
    '''

    try:
        cursor.execute('INSERT INTO {} VALUES ();'.format(table_name), tuple)
    except (Exception, psycopg2.Error) as error:
        print(error.pgerror)
    
    connection.commit()

def insert_rows(connection:Any, cursor:Any, table_name:str, data:Any):
    '''
    Insert multiple rows into a specified table.
    Optimized for many inserts
    
    Keyword arguments:
    cursor: cursor object
    table_name: the name of the table to insert to
    data: the data to insert. Either a tuple or a list of tuples
    '''

    connection.commit()