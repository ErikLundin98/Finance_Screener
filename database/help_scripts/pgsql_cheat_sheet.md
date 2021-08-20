Execute SQL script:
\i \path\TO\file_name.sql

Show tables:
\dt

Dump to file:
pg_dump -C -h localhost -U postgres tutorial > backup.sql
works, if not hypertable