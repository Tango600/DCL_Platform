unit uDCLDBAwareTypes;
{$I DefineType.pas}

interface

uses
  DBGrids, DBExtCtrls, DBCtrls,
  {$IFDEF IBX}
  IBDatabase, IBCustomDataSet, IBQuery,
  IBUpdateSQL, ibxscript, //uIBUpdateSQLW,
  {$ENDIF}
  {$IFDEF ZEOS}
  ZConnection, ZDataset, ZSqlUpdate, ZAbstractConnection,
  {$ENDIF}
  {$IFDEF SQLdbFamily}
  sqldb, DB,
  {$IFDEF SQLdbIB}
  IBConnection,
  {$ENDIF}
  {$IFDEF ODBC}
  odbcconn,
  {$ENDIF}
  {$ENDIF}
  Classes, SysUtils;

type
  TDCLDBGrid=TDBGrid;
  {$IFDEF IBX}
    TDCLDialogQuery=TIBQuery;
    TDCLSimlyQuery=TIBQuery;
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
    TDCLSimlyQuery=TZQuery;
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
    TDCLSimlyQuery=TSQLQuery;
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

  TDBDate=TDBDateEdit;
  TNavButtons=TDBNavButton;
  TNavButtonsSet=TDBNavButtonSet;

implementation

end.

