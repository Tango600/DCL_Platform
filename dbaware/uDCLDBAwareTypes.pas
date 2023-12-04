unit uDCLDBAwareTypes;
{$I DefineType.pas}

interface

uses
  DBGrids, DBExtCtrls, DBCtrls,
  {$IFDEF IBX}
    IBDatabase, IBTable, IBCustomDataSet, IBSQL, IBQuery,
    IBUpdateSQL, //uIBUpdateSQLW,
  {$ENDIF}
  {$IFDEF ZEOS}
    ZConnection, ZDataset, ZSqlUpdate, ZAbstractConnection,
  {$ENDIF}
  {$IFDEF SQLdbFamily}
    IBConnection, sqldb, DB,
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
  {$IFDEF SQLdbIB}
    TDBConnector=TIBConnection;
    TDatabaseObject=TDatabase;
  {$ENDIF}
  {$IFDEF SQLdb}
    TDatabaseObject=TDataBase;
    TDBConnector=TSQLConnector;
  {$ENDIF}
  {$ENDIF}

  TDBDate=TDBDateEdit;
  TNavButtons=TDBNavButton;
  TNavButtonsSet=TDBNavButtonSet;

implementation

end.

