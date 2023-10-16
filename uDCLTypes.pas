unit uDCLTypes;
{$I DefineType.pas}

interface

Uses
  Controls, ExtCtrls, StdCtrls, ComCtrls, Buttons, cMeDateEdit,
  EditBtn, DBExtCtrls, DBCtrls, DBGrids,
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
  Forms;

type
  TDialogButton=TBitBtn;
  TDCLDBGrid=TDBGrid;
  TDCLDialogButton=TBitBtn;

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

  TDateTimePicker={$IFDEF ZVComponents}TZVDateTimePicker{$ELSE}TMyDateEdit{$ENDIF};
  TDBDate=TDBDateEdit;
  TNavButtons=TDBNavButton;
  TNavButtonsSet=TDBNavButtonSet;


implementation


end.
