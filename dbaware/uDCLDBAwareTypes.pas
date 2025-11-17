unit uDCLDBAwareTypes;
{$I DefineType.pas}

interface

uses
  {$IFDEF IBX}
  IBDatabase, IBCustomDataSet, IBQuery, IBUpdateSQL, ibxscript,
  {$ENDIF}
  {$IFDEF ZEOS}
  ZConnection, ZDataset, ZSqlUpdate, ZAbstractConnection,
  {$ENDIF}
  {$IFDEF SQLdbFamily}
  sqldb, DB,
  {$IFDEF SQLdb}
  IBConnection, mysql80conn,
  {$ENDIF}
  {$IFDEF SQLdbIB}
  IBConnection,
  {$ENDIF}
  {$IFDEF ODBC}
  odbcconn,
  {$ENDIF}
  {$ENDIF}
  Classes;

type
  {$IFDEF IBX}
    TDCLDialogQuery=TIBQuery;
    TDCLSimplyQuery=TIBQuery;
    TDBConnector=TIBDatabase;
    TDatabaseObject=TIBDatabase;
    TCommandQuery=TIBQuery;
    TTransaction=TIBTransaction;
    TUpdateObj=TIBUpdateSQL;
    TSQLScripter=TIBXScript;
  {$ENDIF}
  {$IFDEF ZEOS}
    TDBConnector=TZConnection;
    TDatabaseObject=TZAbstractConnection;
    TDCLSimplyQuery=TZQuery;
    TDCLDialogQuery=TZQuery;
    {$IFDEF TRANSACTIONDB}
    TTransaction=TZTransaction;
    {$ENDIF}
    TUpdateObj=TZUpdateSQL;
    TCommandQuery=TZReadOnlyQuery;
    TSQLScripter=TZSQLProcessor;
  {$ENDIF}
  {$IFDEF SQLdbFamily}
    TDCLDialogQuery=TSQLQuery;
    TDCLSimplyQuery=TSQLQuery;
    TCommandQuery=TSQLQuery;
    TTransaction=TSQLTransaction;
    TUpdateObj=TSQLQuery;
    TSQLScripter=TSQLScript;
    TDatabaseObject=TDataBase;
  {$IFDEF SQLdbIB}
    TDBConnector=TIBConnection;
  {$ENDIF}
  {$IFDEF SQLdb}
    TDBConnector=TSQLConnector;
  {$ENDIF}
  {$IFDEF ODBC}
    TDBConnector=TODBCConnection;
  {$ENDIF}
  {$ENDIF}

implementation

end.

