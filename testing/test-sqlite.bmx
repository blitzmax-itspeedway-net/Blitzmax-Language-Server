SuperStrict

'	SQLITE TEST

Import bah.database
Import bah.dbsqlite

Local dbpath:String = AppDir+"/test-sqlite.db"
Local db:TDBConnection = LoadDatabase( "SQLITE", dbpath )
Local SQL:String

SQL = "CREATE TABLE IF NOT EXISTS attr(" +..
				"key VARCHAR(10) NOT NULL PRIMARY KEY, " +..
				"value VARCHAR(10) NOT NULL DEFAULT ''" +..
				");"
				
db.executeQuery( sql )

DebugStop

db.executeQuery( "DROP TABLE attr;" )
End


db.Close()









