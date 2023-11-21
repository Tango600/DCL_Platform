unit uDCLDBTransaction;
{$I DefineType.pas}

interface

uses
  Classes,
  {$IFDEF FPC}
    {$IFDEF IBX}
      IB, IBDatabase, IBCustomDataSet,
    {$ENDIF}
  {$ELSE}
    {$IFDEF IBX}
      IBX.IBDatabase, IBX.IBCustomDataSet, IBX.IBHeader, IBX.IBSQL, IBX.IBQuery,
      IBX.IBVisualConst, IBX.IBXConst,
    {$ENDIF}
  {$ENDIF}
  {$IFDEF ZEOS}
    ZDbcIntfs,
  {$ENDIF}
  {$IFDEF SQLdbFamily}
    SQLDB,
  {$ENDIF}
  uDCLTypes, uDCLConst;

type

  { TDCLDBTransaction }

  TDCLDBTransaction=class(TTransaction)
  private
    procedure SetDefaultParams(RW: TTransactionType);
  public
    constructor Create(Connector: TDatabaseObject; RW: TTransactionType); overload;
  end;

implementation

uses
  uDCLGlobalVariables;

{ TDCLDBTransaction }

procedure TDCLDBTransaction.SetDefaultParams(RW: TTransactionType);
var
  {$IFDEF ZEOS}
  TrParams: TStrings;
  {$ENDIF}
  {$IFDEF SQLdbFamily}
  TrParams: TStringList;
  {$ENDIF}
  {$IFDEF IBX}
  TrParams: TStrings;
  {$ENDIF}
begin
  {$IFDEF ZEOS}
  TrParams:=Properties;
  {$ELSE}
  TrParams:=Params;
  {$ENDIF}
  TrParams.Clear;
  Case RW of
  trtWrite:Begin
    TrParams.Append('write');
  End;
  trtRead:Begin
    TrParams.Append('read');
  End;
  End;
  TrParams.Append('nowait');
  TrParams.Append('read_committed');
  If GPT.IBAll then
    TrParams.Append('rec_version');
end;

constructor TDCLDBTransaction.Create(Connector: TDatabaseObject;
  RW: TTransactionType);
begin
  inherited Create(Connector);
  {$IFDEF IBX}
  DefaultDatabase:=Connector;
  DefaultAction:=TACommit;
  {$ENDIF}
  {$IFDEF SQLdbFamily}
  Database:=Connector;
  Action:=caCommit;
  {$ENDIF}
  {$IFDEF ZEOS}
  Self.Connection:=Connector;
  {$ENDIF}

  SetDefaultParams(RW);
end;

end.

