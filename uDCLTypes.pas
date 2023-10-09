unit uDCLTypes;
{$I DefineType.pas}

interface

Uses
  Controls, ExtCtrls, StdCtrls, ComCtrls, Buttons, cMeDateEdit,
{$IFnDEF FPC}
  Vcl.DBCtrls, Vcl.DBGrids,
{$ELSE}
  EditBtn, DBExtCtrls, DBCtrls, DBGrids,
{$ENDIF}
{$IFDEF ADO}
  ADODB, ADOConst, ADOInt,
{$ENDIF}
{$IFDEF IBX}
  {$IFDEF FPC}
  IBDatabase, IBTable, IBCustomDataSet, IBSQL, IBQuery,
  IBUpdateSQL, //uIBUpdateSQLW,
  {$ELSE}
  IBX.IBDatabase, IBX.IBTable, IBX.IBCustomDataSet, IBX.IBSQL, IBX.IBQuery,
  IBX.IBVisualConst, IBX.IBXConst, IBX.IBUpdateSQL,
  uIBUpdateSQLW,
  {$ENDIF}
{$ENDIF}
{$IFDEF ZEOS}
  ZConnection, ZDataset, ZSqlUpdate, ZAbstractConnection,
{$ENDIF}
{$IFDEF SQLdbFamily}
  IBConnection, sqldb, DB,
{$ENDIF}
  Forms;

type
  TDialogButton=TBitBtn;
  TDCLDBGrid=TDBGrid;
  TDCLDialogButton=TBitBtn;

{$IFDEF ADO}
  TDCLDialogQuery=TADOQuery;
  TDCLSimlyQuery=TADOQuery;
  TDBConnector=TADOConnection;
  TDatabaseObject=TADOConnection;
  TCommandQuery=TADOCommand;
{$ENDIF}
{$IFDEF IBX}
  TDCLDialogQuery=TIBQuery;
  TDCLSimlyQuery=TIBQuery;
  TDBConnector=TIBDatabase;
  TDatabaseObject=TIBDatabase;
  TCommandQuery=TIBQuery;
  TTransaction=TIBTransaction;
  TUpdateObj=TIBUpdateSQL;
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
{$ENDIF}
{$IFDEF SQLdbFamily}
  TDCLDialogQuery=TSQLQuery;
  TDCLSimlyQuery=TSQLQuery;
  TCommandQuery=TSQLQuery;
  TTransaction=TSQLTransaction;
  TUpdateObj=TSQLQuery;
{$IFDEF SQLdbIB}
  TDBConnector=TIBConnection;
  TDatabaseObject=TDatabase;
{$ENDIF}
{$IFDEF SQLdb}
  TDatabaseObject=TDataBase;
  TDBConnector=TSQLConnector;
{$ENDIF}
{$ENDIF}

  TDCLFilterPanel=TScrollBox;
  TDialogPanel=TScrollBox;
  TDCLButtonPanel=TScrollBox;
  TToolBarPanel=TToolBar;
  TDialogLabel=TLabel;

  TDialogSpeedButton=TSpeedButton;
  TFormPanelButton=TSpeedButton;

  {$IFNDEF FPC}
  DateTimePicker=TDateTimePicker;
  TDBDate=TDBEdit;
  TNavButtons=TNavButton;
  TNavButtonsSet=TNavButtonSet;
  {$ENDIF}
  {$IFDEF FPC}
  DateTimePicker={$IFDEF ZVComponents}TZVDateTimePicker{$ELSE}TMyDateEdit{$ENDIF};
  TDBDate=TDBDateEdit;
  TNavButtons=TDBNavButton;
  TNavButtonsSet=TDBNavButtonSet;
  {$ENDIF}


implementation


end.
