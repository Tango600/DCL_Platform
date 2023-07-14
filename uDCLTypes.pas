unit uDCLTypes;
{$I DefineType.pas}

interface

Uses
  Controls, ExtCtrls, StdCtrls, ComCtrls, Buttons,
{$IFnDEF FPC}
  Vcl.DBCtrls, Vcl.DBGrids,
{$ELSE}
  EditBtn,
  DBCtrls, DBGrids,
{$ENDIF}
{$IFDEF ADO}
  ADODB, ADOConst, ADOInt,
{$ENDIF}
{$IFDEF FPC}
  {$IFDEF IBX}
    IBDatabase, IBTable, IBCustomDataSet, IBSQL, IBQuery,
    IBUpdateSQL, uIBUpdateSQLW,
  {$ENDIF}
{$ELSE}
  {$IFDEF IBX}
    IBX.IBDatabase, IBX.IBTable, IBX.IBCustomDataSet, IBX.IBSQL, IBX.IBQuery,
    IBX.IBVisualConst, IBX.IBXConst, IBX.IBUpdateSQL,
    uIBUpdateSQLW,
  {$ENDIF}
{$ENDIF}
{$IFDEF ZEOS}
  ZConnection, ZDataset, ZSqlUpdate,
{$ENDIF}
{$IFDEF SQLdbFamily}
  IBConnection, sqldb,
{$ENDIF}
  Forms;

type
  TDialogButton=TBitBtn;
  TDCLDBGrid=TDBGrid;
  TDCLDialogButton=TBitBtn;

  TOpenDialogMethod=procedure(ns, s: String) of Object;

{$IFDEF ADO}
  TDCLDialogQuery=TADOQuery;
  TDCLSimlyQuery=TADOQuery;
  TDBConnector=TADOConnection;
  TCommandQuery=TADOCommand;
{$ENDIF}
{$IFDEF IBX}
  TDCLDialogQuery=TIBQuery;
  TDCLSimlyQuery=TIBQuery;
  TDBConnector=TIBDatabase;
  TCommandQuery=TIBQuery;
  TTransaction=TIBTransaction;
  TUpdateObj=TIBUpdateSQLW;
{$ENDIF}
{$IFDEF ZEOS}
  TDBConnector=TZConnection;
  TDCLSimlyQuery=TZQuery;
  TDCLDialogQuery=TZQuery;
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
{$ENDIF}
{$IFDEF SQLdb}
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
  TNavButtons=TNavButton;
  TNavButtonsSet=TNavButtonSet;
  {$ENDIF}
  {$IFDEF FPC}
  DateTimePicker={$IFDEF ZVComponents}TZVDateTimePicker;{$ELSE}TDateEdit;{$ENDIF}
  TNavButtons=TDBNavButton;
  TNavButtonsSet=TDBNavButtonSet;
  {$ENDIF}


implementation


end.
