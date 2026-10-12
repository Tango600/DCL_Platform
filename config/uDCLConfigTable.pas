unit uDCLConfigTable;
{$I DefineType.pas}

interface

uses
  Classes, SysUtils,
  uDCLDBConnector, uDCLDBAwareTypes, uDCLDBStructure;

type

  { TDCLConfigTable }

  TDCLConfigTable=class
  private
    FDBConnector: TDCLDBConnector;

  public
    constructor Create(DBConnector: TDCLDBConnector); overload;

    function ReadConfig(const ConfigName, UserId: String): String;
    procedure WriteConfig(const ConfigName, NewValue, UserId: String);
  end;

implementation

uses
  uDCLGlobalVariables, uDCLGlobalConfigTable;

{ TDCLConfigTable }

constructor TDCLConfigTable.Create(DBConnector: TDCLDBConnector);
begin
  FDBConnector:=DBConnector;
end;

function TDCLConfigTable.ReadConfig(const ConfigName, UserId: String): String;
var
  ParamsQuery: TDCLSimplyQuery;
begin
  Result:='';
  if Assigned(FDBConnector) and not GPT.NoParamsTable then
  begin
    ParamsQuery:=TDCLSimplyQuery.Create(nil);
    FDBConnector.SetConnector(ParamsQuery);
    ParamsQuery.SQL.Text:='select '+GPTValueField+' from '+GPTTableName+' where lower('+
      GPTNameField+') = lower(:ParamName)';
    if UserID<>'' then
    begin
      ParamsQuery.SQL.Append(' and '+GPTUserIDField+'=:UserID');
      ParamsQuery.ParamByName('UserID').AsString:=UserID;
    end;

    ParamsQuery.ParamByName('ParamName').AsString:=ConfigName;
    ParamsQuery.Open;
    Result:=TrimRight(ParamsQuery.Fields[0].AsString);
    ParamsQuery.Close;
    FreeAndNil(ParamsQuery);
  end;
end;

procedure TDCLConfigTable.WriteConfig(const ConfigName, NewValue, UserId: String);
var
  ParamsQuery: TDCLSimplyQuery;
  Empty: Boolean;
begin
  if Assigned(FDBConnector) and not GPT.NoParamsTable then
  begin
    If Not GPT.NoParamsTable Then
    begin
      ParamsQuery:=TDCLSimplyQuery.Create(nil);
      FDBConnector.SetConnector(ParamsQuery);

      ParamsQuery.SQL.Text:='select count(*) from '+GPTTableName+' where lower('+
        GPTNameField+')=lower(:ParamName)';
      ParamsQuery.ParamByName('ParamName').AsString:=ConfigName;

      if UserID<>'' then
      begin
        ParamsQuery.SQL.Append(' and '+GPTUserIDField+'=:UserID');
        ParamsQuery.ParamByName('UserID').AsString:=UserID;
      end;
      ParamsQuery.Open;
      Empty:=ParamsQuery.Fields[0].AsInteger=0;
      ParamsQuery.Close;

      If not Empty Then
      begin
        ParamsQuery.SQL.Text:='update '+GPTTableName+' set '+
        GPTValueField+' = :ParamValue where lower('+GPTNameField+
          ')=lower(:ParamName)';

        if UserID<>'' then
        begin
          ParamsQuery.SQL.Append(' and '+GPTUserIDField+'=:UserID');
          ParamsQuery.ParamByName('UserID').AsString:=UserID;
        end;
      end
      else
      begin
        If UserID='' then
        begin
          ParamsQuery.SQL.Text:='insert into '+GPTTableName+'('+GPTValueField+', '+
            GPTNameField+') values(:ParamValue, :ParamName)'
        end
        else
        begin
          ParamsQuery.SQL.Text:='insert into '+GPTTableName+'('+GPTValueField+', '+
            GPTNameField+', '+GPTUserIDField+') values(:ParamValue, :ParamName, :UserID)';
          ParamsQuery.ParamByName('UserID').AsString:=UserID;
        end;
      end;

      ParamsQuery.ParamByName('ParamName').AsString:=ConfigName;
      ParamsQuery.ParamByName('ParamValue').AsString:=NewValue;
      ParamsQuery.ExecSQL;
      {$IFDEF TRANSACTIONDB}
      if Assigned(FDBConnector.Transaction) then
        if FDBConnector.Transaction.Active then
          FDBConnector.Transaction.CommitRetaining;
      {$ENDIF}
      FreeAndNil(ParamsQuery);
    end;
  end;
end;

end.

