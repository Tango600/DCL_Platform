unit uDCLConfigTable;
{$mode Delphi}

interface

uses
  Classes, SysUtils,
  uDCLDBConnector, uDCLTypes, uDCLDBStructure;

type

  { TDCLConfigTable }

  TDCLConfigTable=class
  private
    FDBConnector: TDCLDBConnector;

  public
    constructor Create(DBConnector: TDCLDBConnector); overload;

    function ReadConfig(ConfigName, UserId: String): String;
    procedure WriteConfig(ConfigName, NewValue, UserId: String);
  end;

implementation

uses
  uDCLGlobalVariables, uDCLGlobalConfigTable;

{ TDCLConfigTable }

constructor TDCLConfigTable.Create(DBConnector: TDCLDBConnector);
begin
  FDBConnector:=DBConnector;
end;

function TDCLConfigTable.ReadConfig(ConfigName, UserId: String): String;
var
  ParamsQuery: TDCLSimlyQuery;
begin
  Result:='';
  if Assigned(FDBConnector) and not GPT.NoParamsTable then
  begin
    ParamsQuery:=TDCLSimlyQuery.Create(nil);
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

procedure TDCLConfigTable.WriteConfig(ConfigName, NewValue, UserId: String);
var
  ParamsQuery: TDCLSimlyQuery;
begin
  if Assigned(FDBConnector) and not GPT.NoParamsTable then
  begin
    If Not GPT.NoParamsTable Then
    begin
      ParamsQuery:=TDCLSimlyQuery.Create(nil);
      FDBConnector.SetConnector(ParamsQuery);
      if UserID<>'' then
      begin
        ParamsQuery.SQL.Text:='select count(*) from '+GPTTableName+' where lower('+
          GPTNameField+')=lower(:ParamName) and '+GPTUserIDField+'=:UserID';
        ParamsQuery.ParamByName('UserID').AsString:=UserID;
      end
      else
      begin
        ParamsQuery.SQL.Text:='select count(*) from '+GPTTableName+' where lower('+
          GPTNameField+')=lower(:ParamName)';
      end;
      ParamsQuery.ParamByName('ParamName').AsString:=ConfigName;
      ParamsQuery.Open;

      If ParamsQuery.Fields[0].AsInteger>0 Then
      begin
        ParamsQuery.Close;
        if UserID<>'' then
        begin
          ParamsQuery.SQL.Text:='update '+GPTTableName+' set '+
          GPTValueField+' = :ParamValue where lower('+GPTNameField+
            ')=lower(:ParamName) and '+GPTUserIDField+'=:UserID';
          ParamsQuery.ParamByName('UserID').AsString:=UserID;
        end
        else
        begin
          ParamsQuery.SQL.Text:='update '+GPTTableName+' set '+
          GPTValueField+' = :ParamValue where lower('+GPTNameField+
            ')=lower(:ParamName)';
        end;

        ParamsQuery.ParamByName('ParamName').AsString:=ConfigName;
        ParamsQuery.ParamByName('ParamValue').AsString:=NewValue;
        ParamsQuery.ExecSQL;
      end
      else
      begin
        ParamsQuery.Close;
        If UserID='' then
          ParamsQuery.SQL.Text:='insert into '+GPTTableName+'('+GPTValueField+', '+
            GPTNameField+') values(:ParamValue, :ParamName)'
        else
        begin
          ParamsQuery.SQL.Text:='insert into '+GPTTableName+'('+GPTValueField+', '+
            GPTNameField+', '+GPTUserIDField+') values(:ParamValue, :ParamName, :UserID)';
          ParamsQuery.ParamByName('UserID').AsString:=UserID;
        end;

        ParamsQuery.ParamByName('ParamName').AsString:=ConfigName;
        ParamsQuery.ParamByName('ParamValue').AsString:=NewValue;
        ParamsQuery.ExecSQL;
      end;
      FreeAndNil(ParamsQuery);
    end;
  end;
end;

end.

