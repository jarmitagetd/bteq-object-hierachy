-- sql generates list of tables for parameter file param/object.txt
SELECT DATABASENAME ||','||TABLENAME
FROM dbc.tablesv
WHERE databasename = '[databasename]'
ORDER BY TABLENAME
