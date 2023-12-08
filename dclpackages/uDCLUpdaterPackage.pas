unit uDCLUpdaterPackage;
{$I DefineType.pas}

interface

uses
  Classes, SysUtils, DB, fgl,
  uDCLDBAwareTypes, uDCLDBTransaction, uDCLScriptsPackage;

type
  TScriptUpdateState=(susNone, susDone, susError);
  TPackageUpdateState=(pusNone, pusDone, pusInProcess, pusError, pusNotDepend);

  { TDCLUpdaterPackage }

  TDCLUpdaterPackage=class
  private
    {$IFDEF TRANSACTIONDB}
    FWriteTrans: TDCLDBTransaction;
    {$ENDIF}
    FReadQuery, FWriteQuery: TDCLSimlyQuery;
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
  uDCLConst, uDCLDBStructure;

{ TDCLUpdaterPackage }

function TDCLUpdaterPackage.CheckDependencies(Package: TPackage): Boolean;
var
  Empty: Boolean;
  D: String;
begin
  Result:=True;
  for D in Package.PackageInfo.Dependencies do
  begin
    {$IFDEF TRANSACTIONDB}
    if not FWriteTrans.Active then
      FWriteTrans.StartTransaction;
    {$ENDIF}
    FReadQuery.Params.Clear;
    FReadQuery.SQL.Text:='select * from '+UpdatePackageTable+' where '+PackageHashField+' = :HASH and '+PackageUpdateState+' = :STATE';
    FReadQuery.Prepare;
    FReadQuery.Params.ParamByName('HASH').AsString:=D;
    FReadQuery.Params.ParamByName('STATE').AsInteger:=Ord(pusDone);
    FReadQuery.Open;
    Empty:=FReadQuery.IsEmpty;
    FReadQuery.Close;
    {$IFDEF TRANSACTIONDB}
    FWriteTrans.Commit;
    {$IFDEF SQLdbFamily}
    FWriteTrans.EndTransaction;
    {$ENDIF}
    {$ENDIF}

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

  {$IFDEF TRANSACTIONDB}
  if not FWriteTrans.Active then
    FWriteTrans.StartTransaction;
  {$ENDIF}
  FReadQuery.Params.Clear;
  FReadQuery.SQL.Text:='select * from '+UpdateScriptsTable+' where '+PackageIDField+' = :PID and '+UpdateScriptNameField+' = :PNAME';
  FReadQuery.Prepare;
  FReadQuery.Params.ParamByName('PID').AsInteger:=PackageID;
  FReadQuery.Params.ParamByName('PNAME').AsString:=Script.ScriptName;
  FReadQuery.Open;
  Empty:=FReadQuery.IsEmpty;
  if not Empty then
    sid:=FReadQuery.FieldByName(UpdateScriptIDField).AsInteger;
  UpdateState:=TScriptUpdateState(FReadQuery.FieldByName(UpdateScriptStateField).AsInteger);
  FReadQuery.Close;

  if Empty or (UpdateState<>susDone) then
  begin
    ScriptText:=TStringList.Create;
    ScriptText.Clear;

    try
      if (not Script.SQL) and (Script.Ident=0) then
      begin
        FWriteQuery.Params.Clear;
        FWriteQuery.SQL.Text:='select * from '+DCLTable+' where lower('+DCLNameField+') = lower(:ScrName)';
        FWriteQuery.Prepare;
        FWriteQuery.ParamByName('ScrName').AsString:=Script.ScriptName;
        FWriteQuery.Open;
        if not FWriteQuery.IsEmpty then
        begin
          id:=FWriteQuery.FieldByName(IdField).AsInteger;
        end;
        FWriteQuery.Last;
        r:=FWriteQuery.RecordCount;
        FWriteQuery.Close;

        Script.ScriptText.Position:=0;
        if r=1 then
        begin
          FWriteQuery.Params.Clear;
          FWriteQuery.SQL.Text:='update '+DCLTable+' set '+ScriptField+' = :DCLTEXT '+
            ' where '+IdField+' = :ID';
          FWriteQuery.Prepare;
          FWriteQuery.ParamByName('DCLTEXT').LoadFromStream(Script.ScriptText, ftMemo);
          FWriteQuery.ParamByName('ID').AsInteger:=id;
          FWriteQuery.ExecSQL;
        end
        else if r=0 then
        begin
          FWriteQuery.SQL.Text:='insert into '+DCLTable+' ('+DCLNameField+', '+ScriptField+') '+
            'values (:DCLNAME, :DCLTEXT)';
          FWriteQuery.Prepare;
          FWriteQuery.ParamByName('DCLNAME').AsString:=Script.ScriptName;
          FWriteQuery.ParamByName('DCLTEXT').LoadFromStream(Script.ScriptText, ftMemo);
          FWriteQuery.ExecSQL;
        end;
        IsSuccess:=True;
      end
      else if (not Script.SQL) and (Script.Ident<>0) then
      begin
        FWriteQuery.Params.Clear;
        FWriteQuery.SQL.Text:='select * from '+DCLTable+' where '+IdentifyField+' = :IDENT';
        FWriteQuery.Prepare;
        FWriteQuery.ParamByName('IDENT').AsInteger:=Script.Ident;
        FWriteQuery.Open;
        if not FWriteQuery.IsEmpty then
        begin
          id:=FWriteQuery.FieldByName(IdField).AsInteger;
        end;
        FWriteQuery.Last;
        r:=FWriteQuery.RecordCount;
        FWriteQuery.Close;

        if r=1 then
        begin
          FWriteQuery.Params.Clear;
          FWriteQuery.SQL.Text:='update '+DCLTable+' set '+IdentifyField+' = :IDENT, '+
            ParentField+' = :PARENT, '+CommandField+' = :COMMAND, '+
            DCLNameField+' = :SCRNAME '+
            'where '+IdField+' = :ID';
          FWriteQuery.Prepare;
          FWriteQuery.ParamByName('DCLTEXT').LoadFromStream(Script.ScriptText, ftMemo);
          FWriteQuery.ParamByName('COMMAND').AsString:=Script.Command;
          FWriteQuery.ParamByName('SCRNAME').AsString:=Script.ScriptName;
          FWriteQuery.ParamByName('IDENT').AsInteger:=Script.Ident;
          FWriteQuery.ParamByName('PARENT').AsInteger:=Script.Parent;
          FWriteQuery.ParamByName('ID').AsInteger:=id;
          FWriteQuery.ExecSQL;
        end
        else if r=0 then
        begin
          FWriteQuery.Params.Clear;
          FWriteQuery.SQL.Text:='insert into '+DCLTable+'('+IdentifyField+', '+ParentField+', '+CommandField+', '+DCLNameField+') '+
            'values(:IDENT, :PARENT, :COMMAND, :SCRNAME)';
          FWriteQuery.Prepare;
          FWriteQuery.ParamByName('DCLTEXT').LoadFromStream(Script.ScriptText, ftMemo);
          FWriteQuery.ParamByName('COMMAND').AsString:=Script.Command;
          FWriteQuery.ParamByName('SCRNAME').AsString:=Script.ScriptName;
          FWriteQuery.ParamByName('IDENT').AsInteger:=Script.Ident;
          FWriteQuery.ParamByName('PARENT').AsInteger:=Script.Parent;
          FWriteQuery.ExecSQL;
        end;
        IsSuccess:=True;
      end
      else if Script.SQL then
      begin
        Script.ScriptText.Position:=0;

        {$IFDEF IBX}
        SQLScript.RunScript(Script.ScriptText);
        {$ENDIF}
        {$IFDEF SQLdbFamily}
        ScriptText.LoadFromStream(Script.ScriptText);
        SQLScript.Script:=ScriptText;
        SQLScript.Execute;
        {$ENDIF}
        IsSuccess:=True;
      end;
      Result:=susDone;
    except
      IsSuccess:=False;
      Result:=susError;
    end;
    {$IFDEF TRANSACTIONDB}
    if FWriteTrans.Active then
      FWriteTrans.Commit;
    {$ENDIF}

    {$IFDEF TRANSACTIONDB}
    if not FWriteTrans.Active then
      FWriteTrans.StartTransaction;
    {$ENDIF}
    FWriteQuery.Params.Clear;

    if Empty then
    begin
      FWriteQuery.SQL.Text:='insert into '+UpdateScriptsTable+'('+PackageIDField+', '+UpdateScriptNameField+', '+UpdateScriptStateField+') '+
        'values(:PID, :PNAME, :STATE)';
      FWriteQuery.Prepare;
      FWriteQuery.Params.ParamByName('PID').AsInteger:=PackageID;
      FWriteQuery.Params.ParamByName('PNAME').AsString:=Script.ScriptName;
    end
    else
    begin
      FWriteQuery.SQL.Text:='update '+UpdateScriptsTable+' set '+UpdateScriptStateField+' = :STATE '+
        'where '+UpdateScriptIDField+' = :ID';
      FWriteQuery.Params.ParamByName('ID').AsInteger:=sid;
    end;

    if not IsSuccess then
      FWriteQuery.Params.ParamByName('STATE').AsInteger:=Ord(susError)
    else
      FWriteQuery.Params.ParamByName('STATE').AsInteger:=Ord(Result);
    FWriteQuery.ExecSQL;
    {$IFDEF TRANSACTIONDB}
    if FWriteTrans.Active then
      FWriteTrans.Commit;
    {$IFDEF SQLdbFamily}
    FWriteTrans.EndTransaction;
    {$ENDIF}
    {$ENDIF}

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

  {$IFDEF TRANSACTIONDB}
  //FReadTrans:=TDCLDBTransaction.Create(DBConnector, trtRead);
  FWriteTrans:=TDCLDBTransaction.Create(DBConnector, trtWrite);
  {$ENDIF}

  FReadQuery:=TDCLSimlyQuery.Create(nil);
  FReadQuery.DataBase:=DBConnector;
  {$IFDEF TRANSACTIONDB}
  FReadQuery.Transaction:=FWriteTrans;  ///FReadTrans;
  {$ENDIF}

  FWriteQuery:=TDCLSimlyQuery.Create(nil);
  FWriteQuery.DataBase:=DBConnector;
  {$IFDEF TRANSACTIONDB}
  FWriteQuery.Transaction:=FWriteTrans;
  {$ENDIF}

  SQLScript:=TSQLScripter.Create(nil);
  SQLScript.DataBase:=DBConnector;
  {$IFDEF TRANSACTIONDB}
  SQLScript.Transaction:=FWriteTrans;
  {$ENDIF}

  {$IFDEF SQLdbFamily}
  SQLScript.AutoCommit:=False;
  {$ENDIF}
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
      UpdateState:=pusNone;
      {$IFDEF TRANSACTIONDB}
      if not FWriteTrans.Active then
        FWriteTrans.StartTransaction;
      {$ENDIF}
      FReadQuery.Params.Clear;
      FReadQuery.SQL.Text:='select * from '+UpdatePackageTable+' where '+PackageHashField+'=:PH';
      FReadQuery.Prepare;
      FReadQuery.Params.ParamByName('PH').AsString:=Package.PackageInfo.Hash;
      FReadQuery.Open;

      Empty:=FReadQuery.IsEmpty;
      UpdateState:=TPackageUpdateState(FReadQuery.FieldByName(PackageUpdateState).AsInteger);
      PackageID:=FReadQuery.FieldByName(IDPackageField).AsInteger;
      FReadQuery.Close;

      if Empty then
      begin
        FWriteQuery.Params.Clear;
        FWriteQuery.SQL.Text:='insert into '+UpdatePackageTable+' ('+PackageHashField+', '+PackageNameField+', '+PackageUpdateState+') '+
          'values(:HASH, :NAME, :STATE) returning ('+IDPackageField+')';
        FWriteQuery.Prepare;
        FWriteQuery.Params.ParamByName('HASH').AsString:=Package.PackageInfo.Hash;
        FWriteQuery.Params.ParamByName('NAME').AsString:=Package.PackageInfo.Name;
        FWriteQuery.Params.ParamByName('STATE').AsInteger:=Ord(pusInProcess);
        FWriteQuery.ExecSQL;

        FWriteQuery.SQL.Text:='select '+IDPackageField+' from '+UpdatePackageTable+' where '+PackageHashField+' = :HASH';
        FWriteQuery.Prepare;
        FWriteQuery.Params.ParamByName('HASH').AsString:=Package.PackageInfo.Hash;
        FWriteQuery.Open;

        PackageID:=FWriteQuery.Fields[0].AsInteger;
        FWriteQuery.Close;
      end;

      if UpdateState<>pusDone then
      begin
        UpdateState:=UpdateFromPackage(PackageID, Package, StopOnError);

        {$IFDEF TRANSACTIONDB}
        if not FWriteTrans.Active then
          FWriteTrans.StartTransaction;
        {$ENDIF}
        FWriteQuery.Params.Clear;
        FWriteQuery.SQL.Text:='update '+UpdatePackageTable+' set '+PackageUpdateState+' = :STATE, '+
          PackageLastUpdate+' = :LAST_UPDATE where '+IDPackageField+' = :ID';
        FWriteQuery.Prepare;
        FWriteQuery.Params.ParamByName('ID').AsInteger:=PackageID;
        FWriteQuery.Params.ParamByName('LAST_UPDATE').AsDateTime:=Now;
        FWriteQuery.Params.ParamByName('STATE').AsInteger:=Ord(pusDone);
        FWriteQuery.ExecSQL;
        UpdateState:=pusDone;
      end;

      {$IFDEF TRANSACTIONDB}
      if FWriteTrans.Active then
        FWriteTrans.Commit;
      {$IFDEF SQLdbFamily}
        FWriteTrans.EndTransaction;
      {$ENDIF}
      {$ENDIF}
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
    {$IFDEF TRANSACTIONDB}
    FWriteTrans.StartTransaction;
    {$ENDIF}
    FReadQuery.Params.Clear;
    FReadQuery.SQL.Text:='select * from '+UpdatePackageTable+' where '+PackageHashField+'=:PH';
    FReadQuery.Prepare;
    FReadQuery.Params.ParamByName('PH').AsString:=Package.PackageInfo.Hash;
    FReadQuery.Open;

    if not FReadQuery.IsEmpty then
      Result:=TPackageUpdateState(FReadQuery.FieldByName(PackageUpdateState).AsInteger);
    FReadQuery.Close;
    {$IFDEF TRANSACTIONDB}
    FWriteTrans.Commit;
    {$IFDEF SQLdbFamily}
    FWriteTrans.EndTransaction;
    {$ENDIF}
    {$ENDIF}
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

