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
  WhereUser: String;
begin
  Result:='';
  if Assigned(FDBConnector) and not GPT.NoParamsTable then
  begin
    WhereUser:='';
    If Not GPT.NoParamsTable Then
    begin
      If UserID<>'' Then
        WhereUser:=' and '+GPTUserIDField+'='+UserID;

      ParamsQuery:=TDCLSimlyQuery.Create(nil);
      FDBConnector.SetConnector(ParamsQuery);
      ParamsQuery.SQL.Text:='select '+GPTValueField+' from '+GPTTableName+' where '+
        GPT.UpperString+GPTNameField+GPT.UpperStringEnd+'='+GPT.UpperString+':ParamName'+
        GPT.UpperStringEnd+WhereUser;
      ParamsQuery.ParamByName('ParamName').AsString:=ConfigName;
      ParamsQuery.Open;
      Result:=TrimRight(ParamsQuery.Fields[0].AsString);
      ParamsQuery.Close;
      FreeAndNil(ParamsQuery);
    end;
  end;
end;

procedure TDCLConfigTable.WriteConfig(ConfigName, NewValue, UserId: String);
var
  ParamsQuery: TDCLSimlyQuery;
  WhereUser: String;
begin
  WhereUser:='';
  if Assigned(FDBConnector) and not GPT.NoParamsTable then
  begin
    If Not GPT.NoParamsTable Then
    begin
      If UserId<>'' Then
        WhereUser:=' and '+GPTUserIDField+'='+UserId;

      ParamsQuery:=TDCLSimlyQuery.Create(nil);
      FDBConnector.SetConnector(ParamsQuery);
      ParamsQuery.SQL.Text:='select count(*) from '+GPTTableName+' where '+GPT.UpperString+
        GPTNameField+GPT.UpperStringEnd+'='+GPT.UpperString+GPT.StringTypeChar+ConfigName+
        GPT.StringTypeChar+GPT.UpperStringEnd+WhereUser;
      ParamsQuery.Open;
      If ParamsQuery.Fields[0].AsInteger>0 Then
      begin
        ParamsQuery.Close;
        ParamsQuery.SQL.Text:='update '+GPTTableName+' set '+GPTValueField+'='+
          GPT.StringTypeChar+NewValue+GPT.StringTypeChar+' where '+GPT.UpperString+GPTNameField+
          GPT.UpperStringEnd+'='+GPT.UpperString+GPT.StringTypeChar+ConfigName+GPT.StringTypeChar+
          GPT.UpperStringEnd+WhereUser;
        ParamsQuery.ExecSQL;
      end
      Else
      begin
        ParamsQuery.Close;
        If UserID='' Then
          ParamsQuery.SQL.Text:='insert into '+GPTTableName+'('+GPTValueField+', '+
            GPTNameField+') values('+GPT.StringTypeChar+NewValue+GPT.StringTypeChar+', '+
            GPT.StringTypeChar+ConfigName+GPT.StringTypeChar+')'
        Else
          ParamsQuery.SQL.Text:='insert into '+GPTTableName+'('+GPTValueField+', '+
            GPTNameField+', '+GPTUserIDField+') values('+GPT.StringTypeChar+NewValue+
            GPT.StringTypeChar+', '+GPT.StringTypeChar+ConfigName+GPT.StringTypeChar+', '+UserID+')';

        ParamsQuery.ExecSQL;
      end;
      FreeAndNil(ParamsQuery);
    end;
  end;
end;

end.

