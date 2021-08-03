@ECHO starting finance screener...
@ECHO starting database server...
CALL database\help_scripts\start_db.bat
TIMEOUT /t 5
@ECHO starting webserver
CALL venv\scripts\activate.bat
python server\server.py
