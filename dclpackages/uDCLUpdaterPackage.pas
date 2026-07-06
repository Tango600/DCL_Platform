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
    FQuery: TDCLSimplyQuery;
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
    FQuery.Params.Clear;
    FQuery.SQL.Text:='select * from '+UpdatePackageTable+' where '+PackageHashField+' = :HASH and '+PackageUpdateState+' = :STATE';
    FQuery.Prepare;
    FQuery.Params.ParamByName('HASH').AsString:=D;
    FQuery.Params.ParamByName('STATE').AsInteger:=Ord(pusDone);
    FQuery.Open;
    Empty:=FQuery.IsEmpty;
    FQuery.Close;
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
  r, id: Integer;
  ScriptType: TScriptType;
begin
  Result:=susNone;

  {$IFDEF TRANSACTIONDB}
  if not FWriteTrans.Active then
    FWriteTrans.StartTransaction;
  {$ENDIF}
  FQuery.Params.Clear;
  FQuery.SQL.Text:='select count(*) from '+UpdateScriptsTable+' where '+PackageIDField+' = :PID and lower('+UpdateScriptNameField+') = lower(:PNAME)';
  FQuery.Prepare;
  FQuery.Params.ParamByName('PID').AsInteger:=PackageID;
  FQuery.Params.ParamByName('PNAME').AsString:=Script.ScriptName;
  FQuery.Open;
  r:=FQuery.Fields[0].AsInteger;
  FQuery.Close;

  if r=0 then
  begin
    ScriptText:=TStringList.Create;
    ScriptText.Clear;

    ScriptType:=stND;
    try
      if Script.Delete then
      begin
        if Script.Ident=0 then
        begin
          FQuery.Params.Clear;
          FQuery.SQL.Text:='select * from '+DCLTable+' where lower('+DCLNameField+') = lower(:ScrName) and '+
            IdentifyField+' is null';
          FQuery.Prepare;
          FQuery.ParamByName('ScrName').AsString:=Script.ScriptName;
          FQuery.Open;
          if not FQuery.IsEmpty then
          begin
            id:=FQuery.FieldByName(IdField).AsInteger;
          end;
          FQuery.Last;
          r:=FQuery.RecordCount;
          FQuery.Close;

          if r=1 then
          begin
            FQuery.Params.Clear;
            FQuery.SQL.Text:='delete from '+DCLTable+' where '+IdField+' = :ID';
            FQuery.Prepare;
            FQuery.ParamByName('ID').AsInteger:=id;
            FQuery.ExecSQL;
            ScriptType:=stDeleteScript;
          end;
        end
        else
        begin
          FQuery.Params.Clear;
          FQuery.SQL.Text:='select * from '+DCLTable+' where '+IdentifyField+' = :IDENT';
          FQuery.Prepare;
          FQuery.ParamByName('IDENT').AsInteger:=Script.Ident;
          FQuery.Open;
          if not FQuery.IsEmpty then
          begin
            id:=FQuery.FieldByName(IdField).AsInteger;
          end;
          FQuery.Last;
          r:=FQuery.RecordCount;
          FQuery.Close;

          if r=1 then
          begin
            FQuery.Params.Clear;
            FQuery.SQL.Text:='delete from '+DCLTable+' where '+IdField+' = :ID';
            FQuery.Prepare;
            FQuery.ParamByName('ID').AsInteger:=id;
            FQuery.ExecSQL;
            ScriptType:=stDeleteMenuItem;
          end;
        end;
      end
      else if (not Script.SQL) and (Script.Ident=0) then
      begin
        FQuery.Params.Clear;
        FQuery.SQL.Text:='select * from '+DCLTable+' where lower('+DCLNameField+') = lower(:ScrName)';
        FQuery.Prepare;
        FQuery.ParamByName('ScrName').AsString:=Script.ScriptName;
        FQuery.Open;
        if not FQuery.IsEmpty then
        begin
          id:=FQuery.FieldByName(IdField).AsInteger;
        end;
        FQuery.Last;
        r:=FQuery.RecordCount;
        FQuery.Close;

        Script.ScriptText.Position:=0;
        if r=1 then
        begin
          FQuery.Params.Clear;
          FQuery.SQL.Text:='update '+DCLTable+' set '+ScriptField+' = :DCLTEXT '+
            ' where '+IdField+' = :ID';
          FQuery.Prepare;
          FQuery.ParamByName('DCLTEXT').LoadFromStream(Script.ScriptText, ftMemo);
          FQuery.ParamByName('ID').AsInteger:=id;
          FQuery.ExecSQL;
        end
        else if r=0 then
        begin
          FQuery.SQL.Text:='insert into '+DCLTable+' ('+DCLNameField+', '+ScriptField+') '+
            'values (:DCLNAME, :DCLTEXT)';
          FQuery.Prepare;
          FQuery.ParamByName('DCLNAME').AsString:=Script.ScriptName;
          FQuery.ParamByName('DCLTEXT').LoadFromStream(Script.ScriptText, ftMemo);
          FQuery.ExecSQL;
        end;
        ScriptType:=stDCLScript;
      end
      else if (not Script.SQL) and (Script.Ident<>0) then
      begin
        FQuery.Params.Clear;
        FQuery.SQL.Text:='select * from '+DCLTable+' where '+IdentifyField+' = :IDENT';
        FQuery.Prepare;
        FQuery.ParamByName('IDENT').AsInteger:=Script.Ident;
        FQuery.Open;
        if not FQuery.IsEmpty then
        begin
          id:=FQuery.FieldByName(IdField).AsInteger;
        end;
        FQuery.Last;
        r:=FQuery.RecordCount;
        FQuery.Close;

        if r=1 then
        begin
          FQuery.Params.Clear;
          FQuery.SQL.Text:='update '+DCLTable+' set '+IdentifyField+' = :IDENT, '+
            ParentField+' = :PARENT, '+CommandField+' = :COMMAND, '+
            DCLNameField+' = :SCRNAME '+
            'where '+IdField+' = :ID';
          FQuery.Prepare;
          FQuery.ParamByName('COMMAND').AsString:=Script.Command;
          FQuery.ParamByName('SCRNAME').AsString:=Script.ScriptName;
          FQuery.ParamByName('IDENT').AsInteger:=Script.Ident;
          FQuery.ParamByName('PARENT').AsInteger:=Script.Parent;
          FQuery.ParamByName('ID').AsInteger:=id;
          FQuery.ExecSQL;
        end
        else if r=0 then
        begin
          FQuery.Params.Clear;
          FQuery.SQL.Text:='insert into '+DCLTable+'('+IdentifyField+', '+ParentField+', '+CommandField+', '+DCLNameField+') '+
            'values(:IDENT, :PARENT, :COMMAND, :SCRNAME)';
          FQuery.Prepare;
          FQuery.ParamByName('COMMAND').AsString:=Script.Command;
          FQuery.ParamByName('SCRNAME').AsString:=Script.ScriptName;
          FQuery.ParamByName('IDENT').AsInteger:=Script.Ident;
          FQuery.ParamByName('PARENT').AsInteger:=Script.Parent;
          FQuery.ExecSQL;
        end;
        ScriptType:=stMenuItem;
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
        ScriptType:=stSQL;
      end;
      Result:=susDone;
    except
      Result:=susError;
    end;
    {$IFDEF TRANSACTIONDB}
    if FWriteTrans.Active then
      FWriteTrans.Commit;
    {$ENDIF}

    if Result=susDone then
    begin
      {$IFDEF TRANSACTIONDB}
      if not FWriteTrans.Active then
        FWriteTrans.StartTransaction;
      {$ENDIF}
      FQuery.Params.Clear;
      FQuery.SQL.Text:='insert into '+UpdateScriptsTable+'('+PackageIDField+', '+UpdateScriptNameField+', '+UpdateScriptTypeField+') '+
        'values(:PID, :PNAME, :ST)';
      FQuery.Prepare;
      FQuery.Params.ParamByName('PID').AsInteger:=PackageID;
      FQuery.Params.ParamByName('PNAME').AsString:=Script.ScriptName;
      FQuery.Params.ParamByName('ST').AsString:=GetScriptTypeName(ScriptType);
      FQuery.ExecSQL;
      {$IFDEF TRANSACTIONDB}
      if FWriteTrans.Active then
        FWriteTrans.Commit;
      {$IFDEF SQLdbFamily}
      FWriteTrans.EndTransaction;
      {$ENDIF}
      {$ENDIF}
    end;

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
  {$IFDEF TRANSACTIONDB}
  FWriteTrans:=TDCLDBTransaction.Create(DBConnector, trtWrite);
  {$ENDIF}

  FQuery:=TDCLSimplyQuery.Create(nil);
  FQuery.DataBase:=DBConnector;
  {$IFDEF TRANSACTIONDB}
  FQuery.Transaction:=FWriteTrans;
  {$ENDIF}

  FQuery:=TDCLSimplyQuery.Create(nil);
  FQuery.DataBase:=DBConnector;
  {$IFDEF TRANSACTIONDB}
  FQuery.Transaction:=FWriteTrans;
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
      FQuery.Params.Clear;
      FQuery.SQL.Text:='select * from '+UpdatePackageTable+' where '+PackageHashField+'=:PH';
      FQuery.Prepare;
      FQuery.Params.ParamByName('PH').AsString:=Package.PackageInfo.Hash;
      FQuery.Open;

      Empty:=FQuery.IsEmpty;
      UpdateState:=TPackageUpdateState(FQuery.FieldByName(PackageUpdateState).AsInteger);
      PackageID:=FQuery.FieldByName(IDPackageField).AsInteger;
      FQuery.Close;

      if Empty then
      begin
        FQuery.Params.Clear;
        FQuery.SQL.Text:='insert into '+UpdatePackageTable+' ('+PackageHashField+', '+PackageNameField+', '+PackageUpdateState+') '+
          'values(:HASH, :NAME, :STATE) returning ('+IDPackageField+')';
        FQuery.Prepare;
        FQuery.Params.ParamByName('HASH').AsString:=Package.PackageInfo.Hash;
        FQuery.Params.ParamByName('NAME').AsString:=Package.PackageInfo.Name;
        FQuery.Params.ParamByName('STATE').AsInteger:=Ord(pusInProcess);
        FQuery.ExecSQL;

        FQuery.SQL.Text:='select '+IDPackageField+' from '+UpdatePackageTable+' where '+PackageHashField+' = :HASH';
        FQuery.Prepare;
        FQuery.Params.ParamByName('HASH').AsString:=Package.PackageInfo.Hash;
        FQuery.Open;

        PackageID:=FQuery.Fields[0].AsInteger;
        FQuery.Close;
      end;

      if UpdateState<>pusDone then
      begin
        UpdateState:=UpdateFromPackage(PackageID, Package, StopOnError);

        {$IFDEF TRANSACTIONDB}
        if not FWriteTrans.Active then
          FWriteTrans.StartTransaction;
        {$ENDIF}
        FQuery.Params.Clear;
        FQuery.SQL.Text:='update '+UpdatePackageTable+' set '+PackageUpdateState+' = :STATE, '+
          PackageLastUpdate+' = :LAST_UPDATE where '+IDPackageField+' = :ID';
        FQuery.Prepare;
        FQuery.Params.ParamByName('ID').AsInteger:=PackageID;
        FQuery.Params.ParamByName('LAST_UPDATE').AsDateTime:=Now;
        FQuery.Params.ParamByName('STATE').AsInteger:=Ord(UpdateState);
        FQuery.ExecSQL;
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
    FQuery.Params.Clear;
    FQuery.SQL.Text:='select * from '+UpdatePackageTable+' where '+PackageHashField+'=:PH';
    FQuery.Prepare;
    FQuery.Params.ParamByName('PH').AsString:=Package.PackageInfo.Hash;
    FQuery.Open;

    if not FQuery.IsEmpty then
      Result:=TPackageUpdateState(FQuery.FieldByName(PackageUpdateState).AsInteger);
    FQuery.Close;
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

