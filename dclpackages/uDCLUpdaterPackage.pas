unit uDCLUpdaterPackage;
{$I DefineType.pas}

interface

uses
  Classes, SysUtils, DB, fgl,
  uDCLDBAwareTypes, uDCLScriptsPackage;

type
  TScriptUpdateState=(susNone, susDone, susError);
  TPackageUpdateState=(pusNone, pusDone, pusInProcess, pusError, pusNotDepend);

  { TDCLUpdaterPackage }

  TDCLUpdaterPackage=class
  private
    FReadTrans, FWriteTrans: TTransaction;
    FQuery: TDCLSimlyQuery;
    FDBConnector: TDBConnector;
    SQLScript: TSQLScripter;

    function CheckDependencies(Package: TPackage): Boolean;

    function UpdateScript(PackageID: Integer; Script: TDCLScriptItem): TScriptUpdateState;
    function UpdateFromPackage(PackageID: Integer; Package: TPackage; StopOnError: Boolean): TPackageUpdateState;
  public
    constructor Create(DBConnector: TDBConnector);
    function Update(Package: TPackage; StopOnError: Boolean): TPackageUpdateState;
    function GetPackageUpdateResult(Package: TPackage): TPackageUpdateState;

    function GetUpdateResultText(Value: TPackageUpdateState): String;
  end;

implementation

uses
  uDCLDBStructure;

{ TDCLUpdaterPackage }

function TDCLUpdaterPackage.CheckDependencies(Package: TPackage): Boolean;
var
  Empty: Boolean;
  D: String;
begin
  Result:=True;
  for D in Package.PackageInfo.Dependencies do
  begin
    FWriteTrans.StartTransaction;
    FQuery.Transaction:=FReadTrans;
    FQuery.Params.Clear;
    FQuery.SQL.Text:='select * from '+UpdatePackageTable+' where '+PackageHashField+' = :HASH and '+PackageUpdateState+' = :STATE';
    FQuery.Params.ParamByName('HASH').AsString:=D;
    FQuery.Params.ParamByName('STATE').AsInteger:=Ord(pusDone);
    FQuery.Open;
    Empty:=FQuery.IsEmpty;
    FQuery.Close;
    FWriteTrans.Commit;

    if Empty then
    begin
      Result:=False;
      break;
    end;
  end;
end;

function TDCLUpdaterPackage.UpdateScript(PackageID: Integer;
  Script: TDCLScriptItem): TScriptUpdateState;
var
  ScriptText: TStringList;
  r, id, sid: Integer;
  Empty, IsSuccess: Boolean;
  UpdateState: TScriptUpdateState;
begin
  Result:=susNone;
  sid:=-1;
  IsSuccess:=False;

  FWriteTrans.StartTransaction;
  FQuery.Transaction:=FReadTrans;
  FQuery.Params.Clear;
  FQuery.SQL.Text:='select * from '+UpdateScriptsTable+' where '+PackageIDField+' = :PID and '+UpdateScriptNameField+' = :PNAME';
  FQuery.Params.ParamByName('PID').AsInteger:=PackageID;
  FQuery.Params.ParamByName('PNAME').AsString:=Script.ScriptName;
  FQuery.Open;
  Empty:=FQuery.IsEmpty;
  if not Empty then
    sid:=FQuery.FieldByName(UpdateScriptIDField).AsInteger;
  UpdateState:=TScriptUpdateState(FQuery.FieldByName(UpdateScriptStateField).AsInteger);
  FQuery.Close;
  FWriteTrans.Commit;

  if Empty or (UpdateState<>susDone) then
  begin
    ScriptText:=TStringList.Create;
    ScriptText.Clear;

    try
      if (not Script.SQL) and (Script.Ident=0) then
      begin
        FWriteTrans.StartTransaction;
        FQuery.Transaction:=FWriteTrans;
        FQuery.Params.Clear;
        FQuery.SQL.Text:='select * from '+DCLTable+' where lower('+DCLNameField+') = lower(:ScrName)';
        FQuery.ParamByName('ScrName').AsString:=Script.ScriptName;
        FQuery.Open;
        if not FQuery.IsEmpty then
        begin
          id:=FQuery.FieldByName(IdField).AsInteger;
        end;
        FQuery.Last;
        r:=FQuery.RecordCount;
        FQuery.Close;
        FWriteTrans.Commit;

        Script.ScriptText.Position:=0;
        if r=1 then
        begin
          FWriteTrans.StartTransaction;
          FQuery.Transaction:=FWriteTrans;
          FQuery.Params.Clear;
          FQuery.SQL.Text:='update '+DCLTable+' set '+ScriptField+' = :DCLTEXT '+
            ' where '+IdField+' = :ID';
          FQuery.ParamByName('DCLTEXT').LoadFromStream(Script.ScriptText, ftMemo);
          FQuery.ParamByName('ID').AsInteger:=id;
          FQuery.ExecSQL;
          FWriteTrans.Commit;
        end
        else if r=0 then
        begin
          FWriteTrans.StartTransaction;
          FQuery.SQL.Text:='insert into '+DCLTable+' ('+DCLNameField+', '+ScriptField+') '+
            'values (:DCLNAME, :DCLTEXT)';
          FQuery.ParamByName('DCLNAME').AsString:=Script.ScriptName;
          FQuery.ParamByName('DCLTEXT').LoadFromStream(Script.ScriptText, ftMemo);
          FQuery.ExecSQL;
          FWriteTrans.Commit;
        end;
        IsSuccess:=True;
      end
      else if (not Script.SQL) and (Script.Ident<>0) then
      begin
        FWriteTrans.StartTransaction;
        FQuery.Transaction:=FWriteTrans;
        FQuery.Params.Clear;
        FQuery.SQL.Text:='select * from '+DCLTable+' where '+IdentifyField+' = :IDENT';
        FQuery.ParamByName('IDENT').AsInteger:=Script.Ident;
        FQuery.Open;
        if not FQuery.IsEmpty then
        begin
          id:=FQuery.FieldByName(IdField).AsInteger;
        end;
        FQuery.Last;
        r:=FQuery.RecordCount;
        FQuery.Close;
        FWriteTrans.Commit;

        if r=1 then
        begin
          FWriteTrans.StartTransaction;
          FQuery.Transaction:=FWriteTrans;
          FQuery.Params.Clear;
          FQuery.SQL.Text:='update '+DCLTable+' set '+IdentifyField+' = :IDENT, '+
            ParentField+' = :PARENT, '+CommandField+' = :COMMAND, '+
            DCLNameField+' = :SCRNAME '+
            'where '+IdField+' = :ID';
          FQuery.ParamByName('DCLTEXT').LoadFromStream(Script.ScriptText, ftMemo);
          FQuery.ParamByName('COMMAND').AsString:=Script.Command;
          FQuery.ParamByName('SCRNAME').AsString:=Script.ScriptName;
          FQuery.ParamByName('IDENT').AsInteger:=Script.Ident;
          FQuery.ParamByName('PARENT').AsInteger:=Script.Parent;
          FQuery.ParamByName('ID').AsInteger:=id;
          FQuery.ExecSQL;
          FWriteTrans.Commit;
        end
        else if r=0 then
        begin
          FWriteTrans.StartTransaction;
          FQuery.Transaction:=FWriteTrans;
          FQuery.Params.Clear;
          FQuery.SQL.Text:='insert into '+DCLTable+'('+IdentifyField+', '+ParentField+', '+CommandField+', '+DCLNameField+') '+
            'values(:IDENT, :PARENT, :COMMAND, :SCRNAME)';
          FQuery.ParamByName('DCLTEXT').LoadFromStream(Script.ScriptText, ftMemo);
          FQuery.ParamByName('COMMAND').AsString:=Script.Command;
          FQuery.ParamByName('SCRNAME').AsString:=Script.ScriptName;
          FQuery.ParamByName('IDENT').AsInteger:=Script.Ident;
          FQuery.ParamByName('PARENT').AsInteger:=Script.Parent;
          FQuery.ExecSQL;
          FWriteTrans.Commit;
        end;
        IsSuccess:=True;
      end
      else if Script.SQL then
      begin
        Script.ScriptText.Position:=0;
        ScriptText.LoadFromStream(Script.ScriptText);

        FWriteTrans.StartTransaction;
        SQLScript.Script:=ScriptText;
        SQLScript.Execute;
        FWriteTrans.Commit;
        IsSuccess:=True;
      end;
      Result:=susDone;
    except
      IsSuccess:=False;
      Result:=susError;
    end;

    FWriteTrans.StartTransaction;
    FQuery.Transaction:=FWriteTrans;
    FQuery.Params.Clear;

    if Empty then
    begin
      FQuery.SQL.Text:='insert into '+UpdateScriptsTable+'('+PackageIDField+', '+UpdateScriptNameField+', '+UpdateScriptStateField+') '+
        'values(:PID, :PNAME, :STATE)';
      FQuery.Params.ParamByName('PID').AsInteger:=PackageID;
      FQuery.Params.ParamByName('PNAME').AsString:=Script.ScriptName;
    end
    else
    begin
      FQuery.SQL.Text:='update '+UpdateScriptsTable+' set '+UpdateScriptStateField+' = :STATE '+
        'where '+UpdateScriptIDField+' = :ID';
      FQuery.Params.ParamByName('ID').AsInteger:=sid;
    end;

    if not IsSuccess then
      FQuery.Params.ParamByName('STATE').AsInteger:=Ord(susError)
    else
      FQuery.Params.ParamByName('STATE').AsInteger:=Ord(Result);
    FQuery.ExecSQL;
    FWriteTrans.Commit;

    FreeAndNil(ScriptText);
  end;
end;

function CompareScripts(const Item1, Item2: TDCLScriptItem): Integer;
begin
  if Item1.Order<Item2.Order then
    Result:=-1
  else if Item1.Order>Item2.Order then
    Result:=1
  else if Item1.Order=Item2.Order then
    Result:=0;
end;

function TDCLUpdaterPackage.UpdateFromPackage(PackageID: Integer; Package: TPackage; StopOnError: Boolean): TPackageUpdateState;
var
  ScriptItems: TFPGObjectList<TDCLScriptItem>;
  Script: TDCLScriptItem;
  ScrUpdStatus: TScriptUpdateState;
  r: TPackageUpdateState;
begin
  r:=pusNone;

  ScriptItems:=TFPGObjectList<TDCLScriptItem>.Create;
  for Script in Package.Scripts do
    ScriptItems.Add(Script);

  ScriptItems.Sort(CompareScripts);
  for Script in ScriptItems do
  begin
    ScrUpdStatus:=UpdateScript(PackageID, Script);
    if StopOnError and (ScrUpdStatus=susError) then
    begin
      r:=pusError;
      break;
    end;
  end;
  FreeAndNil(ScriptItems);
  Result:=r;
end;

constructor TDCLUpdaterPackage.Create(DBConnector: TDBConnector);
begin
  FDBConnector:=DBConnector;

  FReadTrans:=TTransaction.Create(nil);
  FReadTrans.DataBase:=DBConnector;

  FWriteTrans:=TTransaction.Create(nil);
  FWriteTrans.DataBase:=DBConnector;

  FQuery:=TDCLSimlyQuery.Create(nil);
  FQuery.DataBase:=DBConnector;

  SQLScript:=TSQLScripter.Create(nil);
  SQLScript.DataBase:=DBConnector;
  SQLScript.Transaction:=FWriteTrans;
  SQLScript.AutoCommit:=False;
end;

function TDCLUpdaterPackage.Update(Package: TPackage; StopOnError: Boolean): TPackageUpdateState;
var
  UpdateState: TPackageUpdateState;
  Empty: Boolean;
  PackageID: Integer;
begin
  Result:=pusNone;
  if Package.PackageInfo.ForUpdate then
  begin
    if CheckDependencies(Package) then
    begin
      FQuery.Transaction:=FReadTrans;
      UpdateState:=pusNone;
      FQuery.Params.Clear;
      FQuery.SQL.Text:='select * from '+UpdatePackageTable+' where '+PackageHashField+'=:PH';
      FQuery.Params.ParamByName('PH').AsString:=Package.PackageInfo.Hash;
      FQuery.Open;

      Empty:=FQuery.IsEmpty;
      UpdateState:=TPackageUpdateState(FQuery.FieldByName(PackageUpdateState).AsInteger);
      PackageID:=FQuery.FieldByName(IDPackageField).AsInteger;
      FQuery.Close;

      if Empty then
      begin
        FWriteTrans.StartTransaction;
        FQuery.Transaction:=FWriteTrans;
        FQuery.Params.Clear;
        FQuery.SQL.Text:='insert into '+UpdatePackageTable+' ('+PackageHashField+', '+PackageNameField+', '+PackageUpdateState+') '+
          'values(:HASH, :NAME, :STATE) returning '+IDPackageField;
        FQuery.Params.ParamByName('HASH').AsString:=Package.PackageInfo.Hash;
        FQuery.Params.ParamByName('NAME').AsString:=Package.PackageInfo.Name;
        FQuery.Params.ParamByName('STATE').AsInteger:=Ord(pusInProcess);
        FQuery.Open;
        PackageID:=FQuery.Fields[0].AsInteger;
        FQuery.Close;
        FWriteTrans.Commit;
      end;

      if UpdateState<>pusDone then
      begin
        UpdateState:=UpdateFromPackage(PackageID, Package, StopOnError);

        FWriteTrans.StartTransaction;
        FQuery.Transaction:=FWriteTrans;
        FQuery.Params.Clear;
        FQuery.SQL.Text:='update '+UpdatePackageTable+' set '+PackageUpdateState+' = :STATE, '+
          PackageLastUpdate+' = :LAST_UPDATE where '+IDPackageField+' = :ID';
        FQuery.Params.ParamByName('ID').AsInteger:=PackageID;
        FQuery.Params.ParamByName('LAST_UPDATE').AsDateTime:=Now;
        FQuery.Params.ParamByName('STATE').AsInteger:=Ord(pusDone);
        FQuery.ExecSQL;
        FWriteTrans.Commit;
        UpdateState:=pusDone;
      end;
    end
    else
      UpdateState:=pusNotDepend;

    Result:=UpdateState;
  end;
end;

function TDCLUpdaterPackage.GetPackageUpdateResult(Package: TPackage
  ): TPackageUpdateState;
begin
  Result:=pusNone;
  if Package.PackageInfo.ForUpdate then
  begin
    FQuery.Transaction:=FReadTrans;
    FQuery.Params.Clear;
    FQuery.SQL.Text:='select * from '+UpdatePackageTable+' where '+PackageHashField+'=:PH';
    FQuery.Params.ParamByName('PH').AsString:=Package.PackageInfo.Hash;
    FQuery.Open;

    if not FQuery.IsEmpty then
      Result:=TPackageUpdateState(FQuery.FieldByName(PackageUpdateState).AsInteger);
    FQuery.Close;
  end;
end;

function TDCLUpdaterPackage.GetUpdateResultText(Value: TPackageUpdateState
  ): String;
begin
  Result:='';
  case Value of
  pusDone: Result:='готово';
  pusError: Result:='ошибка';
  pusInProcess: Result:='обновление';
  pusNotDepend: Result:='зависимости не удовлетворены';
  pusNone: Result:='<>';
  end;
end;

end.

