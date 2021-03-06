'''
This module contains utilities for connecting to the TimescaleDB server, querying and inserting data and other related use cases
'''
from typing import Any
import psycopg2
import pgcopy
from datetime import datetime
from tqdm import tqdm

def str_to_date(datestr: str, format='%Y-%m-%d') -> Any:
    '''
    Small helper function to convert a string to a datetime
    '''
    return datetime.strptime(datestr, format).date()

def get_connectors(host, user, password, database):
    '''
    Get the objects needed to interact with the database

    Keyword arguments:
    

    Returns:
    connection: sql connection object
    cursor: cursor object that is used to execute queries agains the database
    '''
    print(host, user, database)
    connection = psycopg2.connect(host=host, user=user, password=password, database=database)
    cursor = connection.cursor()

    return cursor, connection



def insert_row(connection:Any, cursor:Any, table_name:str, columns:tuple, tuple:Any):
    '''
    Insert single row into a specified table

    Keyword arguments:
    connection: database connection
    cursor: cursor object
    table_name: the name of the table to insert to
    data: the data to insert. A tuple
    '''

    sql_string = 'INSERT INTO '+ table_name +'('+ ', '.join(columns) +') VALUES (' + ', '.join(['%s']*len(columns)) + ');'
    try:
        cursor.execute(sql_string, tuple)
    except (Exception, psycopg2.Error) as error:
        print(error.pgerror)
    
    connection.commit()

def insert_rows(connection:Any, cursor:Any, table_name:str, columns:tuple, data:Any, do_on_conflict='DO NOTHING'):
    '''
    Insert many into a specified table

    Keyword arguments:
    connection: database connection
    cursor: cursor object
    table_name: the name of the table to insert to
    data: the data to insert. A tuple
    '''
    sql = sql_string = 'INSERT INTO '+ table_name +'('+ ', '.join(columns) +') VALUES (' + ', '.join(['%s']*len(columns)) + ')'
    sql += ' ON CONFLICT '+do_on_conflict
    sql += ';'
    for i, row in enumerate(tqdm(data)):
        try:
            cursor.execute(sql, row)
        except (Exception, psycopg2.Error) as error:
            print(error.pgerror)

    
    connection.commit()

def insert_rows_copy(connection:Any, table_name:str, columns, data:Any):
    '''
    Insert multiple rows into a specified table.
    Optimized for many inserts, BUT: does not handle duplicates
    
    Keyword arguments:
    connection: database connection
    table_name: the name of the table to insert to
    columns: the column names to insert data into
    data: the data to insert. A list of tuples
    '''
    copy_manager = pgcopy.CopyManager(connection, table_name, columns)
    copy_manager.copy(data)
    connection.commit()

