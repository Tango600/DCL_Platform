unit uDCLMain;
{$I DefineType.pas}

interface

uses
  Classes, SysUtils, Generics.Collections, Forms, ExtCtrls, LazFileUtils, DB,
  Controls, StdCtrls, lcltype, Dialogs,
  fDCLLoginForm, fChangePasswordForm, fDCLProtectionForm,
  uDCLDBAwareTypes, uDCLForm, uDCLVariables, uDCLDBConnector, uDCLMenuSelector,
  uDCLNotifier, uIDCLMain, uIDCLForm, uIDCLGrid, uReturnFormValue, uDCLData,
  uDCLConst, uIDCLCommand, uDCLScriptsPackage, uDCLImages, uVariableNamespace,
  uIDCLProtectionEngine, uDCLControls, uSingleInstance;

type
  { TDCLMain }

  TDCLMain=class(TInterfacedObject, IDCLMain)
  private
    FMainForm: TForm;
    FForms: TList<IDCLForm>;
    FVariables: TVariables;
    FDBConnector: TDCLDBConnector;
    FDCLMenuSelector: TDCLMenuSelector;
    LocalQuery: TDCLSimplyQuery;
    FDCLNotifier: TDCLNotifier;
    FPackages: TList<TPackageInfo>;
    FScripts: TList<TDCLScriptItem>;
    FPicturesIndexes: TDictionary<TPicturesTypes, Integer>;
    ProtectionForm: TProtectionForm;
    FImages: TImageList;
    IProtectionEngine: IDCLProtectionEngine;
    TerminateByLastDialog: Boolean;
    SingleInstanceMutex: TSingleInstanceMutex;

    function GetScriptText(const ScriptName: String): TStringList;
    function GetScript(const ScriptName: String): TDCLScript;
    function GetScriptByIdent(Ident: Integer; OutRoles: Boolean): TDCLScript;
    procedure RunScript(IdentFrom, IdentTo: Integer);

    procedure WriteBaseID;
    function ReadBaseID: String;

    function TestGlobalParamsTable: Boolean;
    function TestUsersTable: Boolean;
    function TestScriptTable: Boolean;
    procedure CreateImageList;

    function LoadPackage(const FileName: String): TDCLScriptsPackage;
    procedure UpdateFromPackages(const PackagePath: String);
    function GetProtectionEngine: IDCLProtectionEngine;

    function Start: Boolean;
    procedure RunInterface(MainForm: TForm);

    procedure ReleaseForm(const Form: IDCLForm);
    procedure CheckLastDialog;

    procedure CloseAllDialogs;

    procedure Update;

    function GetVariables: TVariables;
    function GetForms: TList<IDCLForm>;
    function GetDBConnector: TDCLDBConnector;

    procedure CreateMenu;
    function GetUsersList: TStringList;

    procedure OpenDialog(const DialogName: String);
    procedure RunCommandScript(const CommandName: String);
    procedure About;

    procedure ExitApp;
    function GetImageList: TImageList;
    function GetImageIndex(PictureType: TPicturesTypes): Integer;
    function GetImageIndexes: TDictionary<TPicturesTypes, Integer>;

    function IsNeedLogin: Boolean;
    function CheckPassword(const Login, Password: String): Boolean;
    procedure SetPassword(const Login, Password: String);
    procedure FillUserInfoToGPT(const Login: String);

    procedure NotifyForms(Action: TFormsNotifyAction);
    procedure NotifyForm(const Form: IDCLForm; Action: TFormsNotifyAction);

    function CreateDialog(const NameSpace: TVariableNamespace; const DialogName: String; NoContext: Boolean;
      const ParentForm: IDCLForm; const Grid: IDCLGrid; UserLevel: TUserLevelsType;
      ReturnValueParams: TReturnValueParams; Modal: Boolean): IDCLForm;
    function CloseForm(const Form: IDCLForm; Force: Boolean): IDCLForm;
    procedure GetValueProc(const NameSpace: TVariableNamespace; const Form: IDCLForm; ReturnValue: TReturnFormValue);
    function HasChildForm(const Form: IDCLForm): Boolean;
    function HasParentForm(const Form: IDCLForm): Boolean;

    procedure LoadPackageFromFile(const FileName: String; Run: Boolean);
    function CheckSigned(Package: TDCLScriptsPackage): Boolean;
    procedure ClearScriptPool;
    function GetLoadedScripts: TList<TDCLScriptItem>;
    function GetPackages: TList<TPackageInfo>;

    procedure InitActions;
    procedure CloseActions;

    procedure StartNotifier;
    procedure StopNotifier;
    procedure Finalize;
  public
    constructor Create; overload;
    destructor Destroy; override;
  end;

implementation

uses
  uDCLConfig, uDCLDBStructure, uDCLMultiLang, fDCLAbout, uDBUtils, uSystemUtils,
  uDCLGlobalVariables, uDCLUtils, uDCLMessages, uStringParams, uDCLCommand,
  {$IFDEF PROTECTION}uDCLProtectionEngine,{$ENDIF} uDCLUpdaterPackage,
  uStringUtils, uDCLQueryUtils, uDCLTranscode;

{ TDCLMain }

function TDCLMain.IsNeedLogin: Boolean;
begin
  Result:=False;

  {$IFDEF ALLOWNODCL}
  if not TestUsersTable then
  begin
    Exit;
  end;
  {$ENDIF}

  LocalQuery.SQL.Text:='select * from '+UsersTable;
  LocalQuery.Open;
  Result:=not LocalQuery.IsEmpty;
  LocalQuery.Close;

  if Result and (GPT.DCLUserName<>'') and (GPT.EnterPass<>'') then
  begin
    Result:=not CheckPassword(GPT.DCLUserName, GPT.EnterPass);
  end;
end;

function TDCLMain.CheckPassword(const Login, Password: String): Boolean;
begin
  LocalQuery.Params.Clear;
  LocalQuery.SQL.Text:='select * from '+UsersTable+' where lower('+UserNameField+')=lower(:User) '+
    'and '+UserAdminField+'>:UL';
  LocalQuery.ParamByName('User').AsString:=Login;
  LocalQuery.ParamByName('UL').AsInteger:=Ord(ulDeny);
  LocalQuery.Open;
  LocalQuery.First;
  Result:=not LocalQuery.IsEmpty;
  if Result then
    Result:=(Password=LocalQuery.FieldByName(UserPassField).AsString);

  LocalQuery.Close;
end;

procedure TDCLMain.SetPassword(const Login, Password: String);
begin
  LocalQuery.Params.Clear;
  LocalQuery.SQL.Text:='update '+UsersTable+' set '+UserPassField+'=:pass where lower('+UserNameField+')=lower(:User)';
  LocalQuery.ParamByName('User').AsString:=Login;
  LocalQuery.ParamByName('pass').AsString:=Password;
  LocalQuery.ExecSQL;
  {$IFDEF TRANSACTIONDB}
  if Assigned(FDBConnector.Transaction) then
    if FDBConnector.Transaction.Active then
      FDBConnector.Transaction.CommitRetaining;
  {$ENDIF}
end;

procedure TDCLMain.FillUserInfoToGPT(const Login: String);
begin
  LocalQuery.Params.Clear;
  LocalQuery.SQL.Text:='select * from '+UsersTable+' where lower('+UserNameField+')=lower(:UN) '+
    'and '+UserAdminField+'>:UL';
  LocalQuery.Prepare;
  LocalQuery.ParamByName('UN').AsString:=Login;
  LocalQuery.ParamByName('UL').AsInteger:=Ord(ulDeny);
  LocalQuery.Open;
  if not LocalQuery.IsEmpty then
  begin
    GPT.UserID:=LocalQuery.FieldByName(UserIDField).AsString;
    GPT.AccessLevel:=TranslateDigitToUserLevel(LocalQuery.FieldByName(UserAdminField).AsInteger);
    GPT.DCLLongUserName:=LocalQuery.FieldByName(LongUserNameField).AsString;
    GPT.DCLUserName:=LocalQuery.FieldByName(UserNameField).AsString;
  end;
  LocalQuery.Close;
end;

procedure TDCLMain.LoadPackageFromFile(const FileName: String; Run: Boolean);
var
  Package: TDCLScriptsPackage;
  I: TDCLScriptItem;
  RunItem: TDCLScriptItem;
  Command: IDCLCommand;
  c: Integer;
  Files: TStringList;
  S, fn: String;
begin
  Files:=TStringList.Create;
  if ParamsCount(FileName)=1 then
  begin
    Files.Append(FileName);
  end
  else
  begin
    for c:=1 to ParamsCount(FileName) do
    begin
      Files.Append(GetParam(FileName, c));
    end;
  end;

  for S in Files do
  begin
    if IsNoFileExt(S) then
      fn:=S+PackagesFileExt
    else
      fn:=S;

    if FileExists(fn) then
    begin
      Package:=LoadPackage(fn);

      if not Package.PackageInfo.ForUpdate then
      begin
        if CheckSigned(Package) then
        begin
          if Package.PackageInfo.Name='' then
            Package.PackageInfo.Name:=ExtractFileNameOnly(fn);

          FPackages.Add(Package.PackageInfo);

          for I in Package.Scripts do
          begin
            if not I.SQL then
              FScripts.Add(I);
          end;

          if Run then
          begin
            c:=FScripts.Count;
            for RunItem in FScripts do
            begin
              if Package.PackageInfo.RunOnStart and ((RunItem.RunType<>rtNone) or (c=1)) then
              begin
                if RunItem.RunType=rtCommand then
                begin
                  Command:=TDCLCommand.Create(Self, TVariableNamespace.Create('', ''), nil, nil);
                  Command.RunCommandScript(RunItem.ScriptName);
                  Command:=nil;
                end
                else
                begin
                  OpenDialog(RunItem.ScriptName);
                end;

                break;
              end;
            end;
          end;
        end
        else
        begin
          ShowErrorMessage(0, GetDCLMessageString(msPackageSignNotValid));
        end;
      end
      else
      begin
        ShowErrorMessage(0, GetDCLMessageString(msCantOpenForUpdatePackage));
      end;

      FreeAndNil(Package);
    end;
  end;
  FreeAndNil(Files);
end;

function TDCLMain.CheckSigned(Package: TDCLScriptsPackage): Boolean;
{$IFDEF ALLOWNODCL}
var
  Signer, Password: String;
{$ENDIF}
begin
  Result:=False;
  {$IFDEF ALLOWNODCL}
  if not TestUsersTable then
  begin
    {$IFDEF NOCHECKSIGN}
    Result:=True;
    Exit;
    {$ELSE}
    Signer:=InputBox('Package check', 'Signer', '');
    if Signer<>'' then
    begin
      Password:=PasswordBox('Package check', 'Password');
      if Package.CheckPackage(Signer, Password) then
      begin
        Result:=True;
      end;
    end;
    Exit;
    {$ENDIF}
  end;
  {$ENDIF}
  LocalQuery.Params.Clear;
  LocalQuery.SQL.Text:='select * from '+UsersTable+' where '+UserAdminField+'>=:UL';
  LocalQuery.Prepare;
  LocalQuery.ParamByName('UL').AsInteger:=Ord(ulSigner);
  LocalQuery.Open;
  LocalQuery.First;
  while not LocalQuery.EOF do
  begin
    if Package.CheckPackage(LocalQuery.FieldByName(UserNameField).AsString, LocalQuery.FieldByName(UserPassField).AsString) then
    begin
      Result:=True;
      break;
    end;

    LocalQuery.Next;
  end;
  LocalQuery.Close;
end;

procedure TDCLMain.ClearScriptPool;
begin
  FScripts.Clear;
end;

function TDCLMain.GetLoadedScripts: TList<TDCLScriptItem>;
begin
  Result:=FScripts;
end;

function TDCLMain.GetPackages: TList<TPackageInfo>;
begin
  Result:=FPackages;
end;

procedure TDCLMain.InitActions;
begin
  RunScript(40001, 40100);
end;

procedure TDCLMain.CloseActions;
begin
  RunScript(40101, 40200);
end;

procedure TDCLMain.StartNotifier;
begin
  {$IFNDEF NODCLMESSAGES}
  FDCLNotifier:=TDCLNotifier.Create(Self);
  {$ENDIF}
end;

procedure TDCLMain.StopNotifier;
begin
  {$IFNDEF NODCLMESSAGES}
  if Assigned(FDCLNotifier) then
    FreeAndNil(FDCLNotifier);
  {$ENDIF}
end;

procedure TDCLMain.Finalize;
begin
  CloseActions;
  StopNotifier;
  if Assigned(FDCLMenuSelector) then
    FreeAndNil(FDCLMenuSelector);
end;

procedure TDCLMain.NotifyForms(Action: TFormsNotifyAction);
var
  F: IDCLForm;
begin
  for F in FForms do
  begin
    NotifyForm(F, Action);
  end;
end;

procedure TDCLMain.NotifyForm(const Form: IDCLForm; Action: TFormsNotifyAction);
begin
  case Action of
  fnaMinimize: Form.WindowState:=wsMinimized;
  fnaMaximaze: Form.WindowState:=wsMaximized;
  fnaRefresh: Form.RefreshForm;
  fnaClose: Form.ForceClose;
  fnaHide: Form.Hide;
  fnaShow: begin
    if not Form.Showing then
      Form.Show;
    Form.SetFocus;
    end;
  end;
end;

function TDCLMain.CreateDialog(const NameSpace: TVariableNamespace; const DialogName: String; NoContext: Boolean;
  const ParentForm: IDCLForm; const Grid: IDCLGrid; UserLevel: TUserLevelsType;
  ReturnValueParams: TReturnValueParams; Modal: Boolean): IDCLForm;
var
  DCL: TStringList;
  lForm, F: IDCLForm;
  level: Integer;
begin
  Result:=nil;
  DCL:=GetScriptText(DialogName);
  if DCL.Count>0 then
  begin
    if PosEx('script type=command', DCL[0])<>0 then
      Exit;

    if NoContext or not Assigned(Grid) then
      lForm:=TDCLForm.Create(Self, DialogName, NameSpace, ParentForm, DCL,
        UserLevel, nil, nil, ReturnValueParams, Modal)
    else
      lForm:=TDCLForm.Create(Self, DialogName, NameSpace, ParentForm, DCL,
        UserLevel, Grid.Query, Grid.Data, ReturnValueParams, Modal);

    if not lForm.Reject then
    begin
      level:=0;
      for F in FForms do
      begin
        if level<F.StackLevel then
        begin
          level:=F.StackLevel;
        end;
      end;
      lForm.StackLevel:=level+1;

      FForms.Add(lForm);
      Result:=lForm;
    end
    else
    begin
      lForm:=nil;
    end;
  end;
  FreeAndNil(DCL);
end;

procedure TDCLMain.GetValueProc(const NameSpace: TVariableNamespace; const Form: IDCLForm; ReturnValue: TReturnFormValue);
var
  ReturnValueItem: TGetValueItem;
  Edit: TDCLEdit;
  lDCLForm: IDCLForm;
  lDCLGrid: IDCLGrid;
  Command: IDCLCommand;
begin
  If Assigned(ReturnValue) and (ReturnValue.Values.Count>0) Then
  begin
    lDCLForm:=Form;
    lDCLGrid:=lDCLForm.CurrentGrid;

    Command:=TDCLCommand.Create(Self, NameSpace, lDCLForm, lDCLGrid);
    for ReturnValueItem in ReturnValue.Values do
    begin
      If FieldExists(lDCLForm.CurrentGrid.Query, ReturnValue.KeyModifyField) Then
      begin
        If lDCLForm.CurrentGrid.Query.Active then
        begin
          if lDCLForm.CurrentGrid.Query.CanModify then
          begin
            if not (lDCLForm.CurrentGrid.Query.State in dsEditModes) then
              lDCLForm.CurrentGrid.Query.Edit;
            lDCLForm.CurrentGrid.Query.FieldByName(ReturnValue.KeyModifyField).AsString:=ReturnValueItem.Key;
          end;
        end;
      end;

      If FieldExists(lDCLForm.CurrentGrid.Query, ReturnValue.ValueModifyField) Then
      begin
        If lDCLForm.CurrentGrid.Query.Active Then
        begin
          If lDCLForm.CurrentGrid.Query.CanModify Then
          begin
            if not (lDCLForm.CurrentGrid.Query.State in dsEditModes) then
              lDCLForm.CurrentGrid.Query.Edit;
            lDCLForm.CurrentGrid.Query.FieldByName(ReturnValue.ValueModifyField).AsString:=ReturnValueItem.Value;
          end;
        end;
      end;

      If ReturnValue.KeyEditName<>'' Then
      begin
        For Edit in lDCLForm.CurrentGrid.Edits do
        begin
          If DCLStringEquals(ReturnValue.KeyEditName, Edit.Control.Name) Then
          begin
            (Edit.Control as TEdit).Text:=ReturnValueItem.Key;
            break;
          end;
        end;
      end;

      If ReturnValue.ValueEditName<>'' Then
      begin
        For Edit in lDCLForm.CurrentGrid.Edits do
        begin
          If DCLStringEquals(ReturnValue.ValueEditName, Edit.Control.Name) Then
          begin
            (Edit.Control as TEdit).Text:=ReturnValueItem.Value;
            break;
          end;
        end;
      end;

      if ReturnValue.KeyVar<>'' then
      begin
        FVariables.NewVariableWithTest(Namespace, ReturnValue.KeyVar);
        FVariables.Variables[Namespace.CurrentNamespace, ReturnValue.KeyVar]:=ReturnValueItem.Key;
      end;

      if ReturnValue.ValueVar<>'' then
      begin
        FVariables.NewVariableWithTest(Namespace, ReturnValue.ValueVar);
        FVariables.Variables[Namespace.CurrentNamespace, ReturnValue.ValueVar]:=ReturnValueItem.Value;
      end;

      if ReturnValue.BatchScript<>'' then
      begin
        Command.RunCommandScript(ReturnValue.BatchScript);
      end;
    end;

    if ReturnValue.FinishScript<>'' then
    begin
      Command.RunCommandScript(ReturnValue.FinishScript);
    end;

    Command:=nil;
  end;
end;

function TDCLMain.HasChildForm(const Form: IDCLForm): Boolean;
var
  F: IDCLForm;
  G, G2: IDCLGrid;
begin
  Result:=False;
  for F in FForms do
  begin
    if Form<>F then
    for G in F.Grids do
    begin
      for G2 in Form.Grids do
      begin
        if G2.Data=G.Query.DataSource then
        begin
          Result:=True;
          Exit;
        end;
      end;
    end;
  end;
end;

function TDCLMain.HasParentForm(const Form: IDCLForm): Boolean;
var
  F: IDCLForm;
begin
  Result:=False;
  for F in FForms do
  begin
    if Assigned(F.GetParentDialog) and (F.GetParentDialog=Form) then
    begin
      Result:=True;
      Exit;
    end;
  end;
end;

function TDCLMain.CloseForm(const Form: IDCLForm; Force: Boolean): IDCLForm;
var
  level, l: Integer;
  Parent, F, C: IDCLForm;
  Cancel: Boolean;
begin
  Cancel:=False;
  if Force then
    Cancel:=HasChildForm(Form);

  if Cancel then
  begin
    Result:=Form;
  end
  else
  begin
    Parent:=Form.ParentDialog;
    if Assigned(Parent) then
    begin
      Result:=Parent
    end
    else
    begin
      level:=Form.StackLevel;
      l:=0;
      C:=nil;
      for F in FForms do
      begin
        if F.StackLevel<level then
        if l<F.StackLevel then
        begin
          l:=F.StackLevel;
          C:=F;
        end;
      end;
      Result:=C;
    end;

    if Force then
      Form.ForceClose
    else
      Form.Close;
  end;
end;

procedure TDCLMain.ReleaseForm(const Form: IDCLForm);

  procedure CloseChild(const F: IDCLForm);
  var
    Form, FF: IDCLForm;
  begin
    Form:=FForms.Extract(F);
    if Assigned(Form) then
    begin
      while HasParentForm(Form) do
      begin
        for FF in FForms do
        begin
          if Assigned(FF.GetParentDialog) and (FF.GetParentDialog=Form) then
          begin
            CloseChild(FF);
            break;
          end;
        end;
      end;
    end;

    Form:=nil;
  end;

begin
  CloseChild(Form);
  CheckLastDialog;
end;

procedure TDCLMain.CheckLastDialog;
begin
  if TerminateByLastDialog then
  if FForms.Count=0 then
  begin
    ExitApp;
  end;
end;

procedure TDCLMain.RunInterface(MainForm: TForm);
var
  i, p:Integer;
  run: Boolean;
  S, vn, v, DialogName, ScriptName, PackageName, Variables: String;

  function FindDialogCall: String;
  begin
    Result:=FindCommandStrParam('Dialog');
  end;

  function FindScriptName: String;
  begin
    Result:=FindCommandStrParam('Script');
  end;

  function FindPackageFileRun: String;
  begin
    Result:=FindCommandStrParam('RunPackage');
  end;

  function FindVariablesParams: String;
  begin
    Result:=FindCommandStrParam('Variables');
  end;

  function FindPackageFileLoad: String;
  begin
    Result:=FindCommandStrParam('LoadPackage');
  end;

  function FindMainMenuDesabled: Boolean;
  begin
    Result:=FindCommandStrParam('MainMenu')='0';
  end;

  function FindTerminateByLastDialog: Boolean;
  begin
    Result:=FindCommandStrParam('TerminateByLast')='1';
  end;

  function FindKioskMode: Boolean;
  begin
    Result:=FindCommandStrParam('KioskMode')='1';
  end;

begin
  FMainForm:=MainForm;
  if not GPT.DisableColorScheme and (GPT.MainColor<>NoColorValue) and Assigned(FMainForm) then
    MainForm.Color:=GPT.MainColor;

  {$IFDEF PROTECTION}IProtectionEngine:=TDCLProtectionEngine.Create;{$ENDIF}
  if {$IFDEF PROTECTION}IProtectionEngine.GetProtectionStatus{$ELSE}True{$ENDIF} then
  begin
    TerminateByLastDialog:=FindTerminateByLastDialog;

    Variables:=FindVariablesParams;
    if Variables<>'' then
    begin
      for i:=1 to ParamsCount(Variables) do
      begin
        S:=GetParam(Variables, i);
        if S<>'' then
        begin
          p:=Pos('=', S);
          if p<>0 then
          begin
            vn:=Copy(S, 1, p-1);
            v:=Copy(S, p+1, Length(S));

            if vn<>'' then
              GetVariables.NewVariable(TVariableNamespace.Create('', ''), Trim(vn), v);
          end;
        end;
      end;
    end;

    Update;
    run:=False;
    PackageName:=FindPackageFileLoad;
    if PackageName='' then
    begin
      PackageName:=FindPackageFileRun;
      run:=True;
    end;
    If PackageName<>'' then
    begin
      LoadPackageFromFile(PackageName, run);
    end;

    ScriptName:=FindScriptName;
    if ScriptName<>'' then
    begin
      RunCommandScript(ScriptName);
    end;

    DialogName:=FindDialogCall;
    if DialogName<>'' then
    begin
      OpenDialog(DialogName);
    end;

    if FindKioskMode or GPT.KioskMode then
    begin
      GPT.KioskMode:=True;
    end;

    if not FindMainMenuDesabled then
    begin
      CreateMenu;
    end;

    InitActions;
  end
  else
  begin
    ProtectionForm:=TProtectionForm.Create(Application, Self, False);
    ProtectionForm.ShowModal;

    Application.Terminate;
  end;
end;

function TDCLMain.GetScriptText(const ScriptName: String): TStringList;
var
  Script: TDCLScript;
begin
  Result:=TStringList.Create;
  Script:=GetScript(ScriptName);
  if Assigned(Script) then
    Result.Text:=Script.ScriptText.Text;
  FreeAndNil(Script);
end;

function TDCLMain.GetScript(const ScriptName: String): TDCLScript;
var
  i: TDCLScriptItem;
begin
  Result:=nil;

  for i in FScripts do
  begin
    if not i.SQL and (i.ScriptName.ToLower=ScriptName.ToLower) then
    begin
      i.ScriptText.Position:=0;

      Result:=TDCLScript.Create;
      Result.Id:=i.Id;
      Result.Ident:=i.Ident;
      Result.Command:=i.Command;
      Result.ScriptText:=TStringList.Create;
      Result.ScriptText.LoadFromStream(i.ScriptText);
      Exit;
    end;
  end;

  if {$IFDEF ALLOWNODCL}TestScriptTable{$ELSE}True{$ENDIF} then
  begin
    LocalQuery.Params.Clear;
    LocalQuery.SQL.Text:='select * from '+DCLTable+' where lower('+DCLNameField+') = lower(:sn)';
    LocalQuery.ParamByName('sn').AsString:=ScriptName;
    LocalQuery.Open;
    LocalQuery.First;

    Result:=TDCLScript.Create;
    Result.Id:=LocalQuery.FieldByName(IdField).AsInteger;
    Result.Ident:=LocalQuery.FieldByName(IdentifyField).AsInteger;
    Result.Command:=LocalQuery.FieldByName(CommandField).AsString;

    Result.ScriptText:=TStringList.Create;
    Result.ScriptText.Text:=LocalQuery.FieldByName(ScriptField).AsString;
    LocalQuery.Close;
  end;
end;

function TDCLMain.GetScriptByIdent(Ident: Integer; OutRoles: Boolean): TDCLScript;
var
  i: TDCLScriptItem;
begin
  Result:=nil;

  for i in FScripts do
  begin
    if i.Ident=Ident then
    begin
      i.ScriptText.Position:=0;

      Result:=TDCLScript.Create;
      Result.Id:=i.Id;
      Result.Ident:=i.Ident;
      Result.Command:=i.Command;
      Result.ScriptText:=TStringList.Create;
      Result.ScriptText.LoadFromStream(i.ScriptText);
      Exit;
    end;
  end;

  if {$IFDEF ALLOWNODCL}TestScriptTable{$ELSE}True{$ENDIF} then
  begin
    LocalQuery.Params.Clear;
    if OutRoles then
      LocalQuery.SQL.Text:=GetRolesQueryText(IdentifyField+'='+IntToStr(Ident), '')
    else
      LocalQuery.SQL.Text:=GetRolesQueryText(IdentifyField+'='+IntToStr(Ident), GPT.UserID);
    LocalQuery.Open;
    LocalQuery.First;

    Result:=TDCLScript.Create;
    Result.Id:=LocalQuery.FieldByName(IdField).AsInteger;
    Result.Ident:=LocalQuery.FieldByName(IdentifyField).AsInteger;
    Result.Command:=LocalQuery.FieldByName(CommandField).AsString;

    Result.ScriptText:=TStringList.Create;
    Result.ScriptText.Text:=LocalQuery.FieldByName(ScriptField).AsString;
    LocalQuery.Close;
  end;
end;

procedure TDCLMain.RunScript(IdentFrom, IdentTo: Integer);
var
  I: TDCLScriptItem;
  Scr: TStringList;
  LocalQuery: TDCLSimplyQuery;
begin
  for I in GetLoadedScripts do
  begin
    if (I.Ident>=IdentFrom) and (I.Ident<=IdentTo) then
    begin
      if Assigned(I.ScriptText) then
      begin
        Scr:=TStringList.Create;
        I.ScriptText.Position:=0;
        Scr.LoadFromStream(I.ScriptText);

        RunCommandScript(Scr.Text);
        FreeAndNil(Scr);
      end;
    end;
  end;

  if TestScriptTable then
  begin
    LocalQuery:=TDCLSimplyQuery.Create(nil);
    FDBConnector.SetConnector(LocalQuery);

    LocalQuery.SQL.Text:=GetRolesQueryText(IdentifyField+' between '+IntToStr(IdentFrom)+' and '+IntToStr(IdentTo), GPT.UserID);
    LocalQuery.Open;
    while not LocalQuery.EOF do
    begin
      RunCommandScript(LocalQuery.FieldByName(DCLNameField).AsString);
      LocalQuery.Next;
    end;
    LocalQuery.Close;
    FreeAndNil(LocalQuery);
  end;
end;

procedure TDCLMain.WriteBaseID;
var
  sGuid: String;
  IsEmpty: Boolean;
begin
  if not GPT.NoParamsTable then
  begin
    LocalQuery.Params.Clear;
    LocalQuery.SQL.Text:='select count(*) from '+GPTTableName+' where lower('+GPTNameField+') = lower(:BID)';
    LocalQuery.ParamByName('BID').AsString:=BaiseUIDParamName;
    LocalQuery.Open;
    IsEmpty:=LocalQuery.Fields[0].AsInteger=0;
    LocalQuery.Close;

    If IsEmpty then
    begin
      sGuid:=GetGUIDString.Replace('-', '').Replace('{', '').Replace('}', '');
      GPT.BaseID:=sGuid;
      LocalQuery.SQL.Text:='insert into '+GPTTableName+'('+GPTNameField+', '+
        GPTValueField+') values(:BID, :BG)';
      LocalQuery.ParamByName('BID').AsString:=BaiseUIDParamName;
      LocalQuery.ParamByName('BG').AsString:=sGuid;

      LocalQuery.ExecSQL;
      {$IFDEF TRANSACTIONDB}
      if Assigned(FDBConnector.Transaction) then
        if FDBConnector.Transaction.Active then
          FDBConnector.Transaction.CommitRetaining;
      {$ENDIF}
    end;
  end;
end;

function TDCLMain.ReadBaseID: String;
begin
  Result:='';
  if not GPT.NoParamsTable and FDBConnector.Connected then
  begin
    LocalQuery.Params.Clear;
    LocalQuery.SQL.Text:='select * from '+GPTTableName+' where lower('+GPTNameField+') = lower(:BID)';
    LocalQuery.ParamByName('BID').AsString:=BaiseUIDParamName;
    LocalQuery.Open;
    Result:=LocalQuery.FieldByName(GPTValueField).AsString;
    LocalQuery.Close;
    If Result='' then
    Begin
      WriteBaseID;
      Result:=ReadBaseID;
    End;
    GPT.BaseID:=Result;
  end;
end;

function TDCLMain.TestGlobalParamsTable: Boolean;
begin
  Result:=FDBConnector.Connected and not TableExists(FDBConnector, GPTTableName);
end;

function TDCLMain.TestUsersTable: Boolean;
begin
  Result:=FDBConnector.Connected and TableExists(FDBConnector, RolesTable) and TableExists(FDBConnector, UsersTable);
end;

function TDCLMain.TestScriptTable: Boolean;
begin
  Result:=FDBConnector.Connected and TableExists(FDBConnector, DCLTable);
end;

procedure TDCLMain.CreateImageList;
  procedure PictureAdd(PictureType: TPicturesTypes);
  begin
    FPicturesIndexes.Add(PictureType, FImages.Add(DrawBMPButton(PictureType), nil));
  end;
begin
  FPicturesIndexes:=TDictionary<TPicturesTypes, Integer>.Create;

  FImages:=TImageList.Create(Application);
  FImages.Scaled:=True;
  FImages.RegisterResolutions([16, 24, 48]);

  PictureAdd(ptFind);
  PictureAdd(ptStructure);
  PictureAdd(ptPrint);

  PictureAdd(ptDownArrow);
  PictureAdd(ptUpArrow);

  PictureAdd(ptFindCurrCell);
  PictureAdd(ptClearAllFind);

  PictureAdd(ptCopy);
  PictureAdd(ptCut);
  PictureAdd(ptPaste);
  PictureAdd(ptUndo);

  PictureAdd(ptTools);

  PictureAdd(ptLoad);
  PictureAdd(ptClear);
  PictureAdd(ptSave);

  PictureAdd(ptGridFilter);
end;

function TDCLMain.LoadPackage(const FileName: String): TDCLScriptsPackage;
var
  RawPackage: TFileStream;
begin
  Result:=nil;
  if FileExists(FileName) then
  begin
    RawPackage:=TFileStream.Create(FileName, fmOpenRead);

    Result:=TDCLScriptsPackage.Create;
    Result.Load(RawPackage);
    RawPackage.Free;
  end;
end;

procedure TDCLMain.UpdateFromPackages(const PackagePath: String);
var
  SRec: TSearchRec;
  retval: Integer;

  procedure Update(FileName: String);
  var
    Package: TPackage;
    Packager: TDCLScriptsPackage;
    UpdaterPackage: TDCLUpdaterPackage;
    UpdResult: TPackageUpdateState;
  begin
    Packager:=LoadPackage(FileName);
    if Assigned(Packager) then
    begin
      if Packager.PackageInfo.ForUpdate then
      begin
        if CheckSigned(Packager) then
        begin
          Package:=TPackage.Create;
          Package.PackageInfo:=Packager.PackageInfo;
          Package.Scripts:=Packager.Scripts;

          UpdaterPackage:=TDCLUpdaterPackage.Create(GetDBConnector);
          UpdResult:=UpdaterPackage.Update(Package, True);
          FreeAndNil(Package);
          FreeAndNil(UpdaterPackage);

          if UpdResult=pusDone then
          begin
            DeleteFile(FileName);
          end;
        end;
      end;
    end;
    FreeAndNil(Packager);
  end;

begin
  retval:=FindFirst(PackagePath+'*'+PackagesFileExt, faAnyFile, SRec);
  While retval=0 Do
  Begin
    If (SRec.Name<>'.')and(SRec.Name<>'..') then
    begin
      If SRec.Attr<>faDirectory Then
      begin
        Update(PackagePath+SRec.Name);
      end;
    end;
    retval:=FindNext(SRec);
  end;
end;

function TDCLMain.GetProtectionEngine: IDCLProtectionEngine;
begin
  Result:=IProtectionEngine;
end;

constructor TDCLMain.Create;
var
  FDCLConfig: TDCLConfig;
  Params: TStringList;
  S, mfn, appSuffix: String;
  AppSufixFile: TextFile;

  Procedure InitGetAppConfigDir;
  Begin
    UserProfileDir:=GetUserProfileDir;
    if not DirectoryExists(UserProfileDir) then
      ForceDirectories(UserProfileDir);

    GPT.AppConfigDir:=UserProfileDir+DCLDir+PathDelim;
  End;

begin
  GPT.NoParamsTable:=False;
  {$IFDEF IBALL}
  GPT.IBAll:=True;
  {$ELSE}
  GPT.IBAll:=False;
  {$ENDIF}
  GPT.StringTypeChar:='''';
  GPT.MenuType:=mtClassic;
  GPT.DebugMesseges:=False;
  GPT.OneCopy:=ocmNone;
  GPT.ExitCnf:=False;
  GPT.UseMessages:=True;
  GPT.DialogsSettings:=True;
  GPT.Port:=0;
  {$IFDEF ZEOS}
  GPT.DBType:=DefaultDBType;
  {$ENDIF}
  GPT.OfficeFormat:=ofMSO;
  //GPT.OfficeDocumentFormat:=odfMSO2007;

  GPT.TimeFormat:='';  // DefaultTimeFormat;
  GPT.DateFormat:='';  // DefaultDateFormat;
  GPT.DateSeparator:=#0;  // DefaultDateSeparator;
  GPT.TimeSeparator:=#0;  // DefaultTimeSeparator;
  GPT.DecimalSeparator:=#0;  // DefaultDecimalSeparator;
  GPT.ThousandSeparator:=#0;

  Path:=ExtractFilePath(Application.ExeName);
  SetCurrentDir(Path);

  InitGetAppConfigDir;

  FDCLConfig:=TDCLConfig.Create;
  if FDCLConfig.FileName<>'' then
  begin
    FDCLConfig.LoadConfig(FDCLConfig.FileName);
  end
  else
  begin
    FDCLConfig.LoadConfig(GPT.IniFileName);
  end;
  FDCLConfig.GetParamsStructure;

  FVariables:=TVariables.Create;
  FForms:=TList<IDCLForm>.Create;

  GPT.AccessLevel:=ulExecute;

  InitLangEnv;
  if GPT.LangName<>'' then
  begin
    LangName:=GPT.LangName;
  end;
  LoadLangRes(LangName, Path);
  LoadTranscodeRes(LangName, Path);

  CreateImageList;

  If GPT.OneCopy<>ocmNone Then
  begin
    mfn:=MemFileName;
    case GPT.OneCopy of
    ocmSuffix: begin

      appSuffix:='';
      S:=Path+SuffixFileName;
      if FileExists(S) then
      begin
        AssignFile(AppSufixFile, S);
        Reset(AppSufixFile);
        ReadLn(AppSufixFile, appSuffix);
        CloseFile(AppSufixFile);
      end;

      if appSuffix<>'' then
        mfn:=mfn+appSuffix
      else
        mfn:=mfn+DBEngineType.Replace(' ', '');
    end;
    ocmApp: begin
      mfn:=MemFileName;
    end;
    end;

    SingleInstanceMutex:=TSingleInstanceMutex.Create(GPT.AppConfigDir+mfn+'.si');
    If SingleInstanceMutex.Check Then
    begin
      ShowErrorMessage(1, GetDCLMessageString(msAppRunning));
      Halt;
    end;
  end;

  FDBConnector:=TDCLDBConnector.Create;
  if FDBConnector.Connected then
  begin
    LocalQuery:=TDCLSimplyQuery.Create(nil);
    FDBConnector.SetConnector(LocalQuery);

    GPT.NoParamsTable:=TestGlobalParamsTable;

    if not GPT.NoParamsTable then
    begin
      LocalQuery.SQL.Text:='select '+GPTNameField+', '+GPTValueField+' from '+GPTTableName;
      LocalQuery.Open;
      Params:=TStringList.Create;
      LocalQuery.First;
      While Not LocalQuery.Eof do
      begin
        Params.Append(LocalQuery.FieldByName(GPTNameField).AsString+'='+
            LocalQuery.FieldByName(GPTValueField).AsString);
        LocalQuery.Next;
      end;
      LocalQuery.Close;

      if Params.Count>0 then
      begin
        FDCLConfig.LoadExternalParams(Params);
        FDCLConfig.GetParamsStructure;
      end;

      ReadBaseID;
    end;
  end;
  FreeAndNil(FDCLConfig);

  If GPT.OneCopy=ocmBase Then
  begin
    SingleInstanceMutex:=TSingleInstanceMutex.Create(GPT.AppConfigDir+MemFileName+GPT.BaseID+'.si');
    If SingleInstanceMutex.Check Then
    begin
      ShowErrorMessage(1, GetDCLMessageString(msAppRunning));
      Halt;
    end;
  end;

  FPackages:=TList<TPackageInfo>.Create;
  FScripts:=TList<TDCLScriptItem>.Create;

  GPT.TimeStampFormat:=GPT.DateFormat+' '+GPT.TimeFormat;
{$IFDEF MSWINDOWS}
  SysUtils.GetFormatSettings;
{$ENDIF}

  if GPT.TimeSeparator<>#0 then
    FormatSettings.TimeSeparator:=GPT.TimeSeparator;
  if GPT.DateSeparator<>#0 then
    FormatSettings.DateSeparator:=GPT.DateSeparator;
  if GPT.DateFormat<>'' then
    FormatSettings.ShortDateFormat:=GPT.DateFormat;
  if GPT.TimeFormat<>'' then
    FormatSettings.LongTimeFormat:=GPT.TimeFormat;

  if GPT.ThousandSeparator<>#0 then
    FormatSettings.ThousandSeparator:=GPT.ThousandSeparator;
  if GPT.DecimalSeparator<>#0 then
    FormatSettings.DecimalSeparator:=GPT.DecimalSeparator;

  {$IFNDEF NODCLMESSAGES}
  If GPT.UseMessages then
    FDCLNotifier:=TDCLNotifier.Create(Self);
  {$ENDIF}
end;

destructor TDCLMain.Destroy;
begin
  IProtectionEngine:=nil;
  CloseAllDialogs;
  StopNotifier;
  if Assigned(FDCLMenuSelector) then
    FreeAndNil(FDCLMenuSelector);
  FreeAndNil(LocalQuery);
  FreeAndNil(SingleInstanceMutex);
  inherited Destroy;
end;

function TDCLMain.Start: Boolean;
var
  LoginForm: TLoginForm;
  ChangePasswordForm: TFormChangePassword;
  TimeToTerm: Boolean;
  ul: TStringList;
  Attempts: Integer;
begin
  TimeToTerm:=False;
  if FDBConnector.Connected and IsNeedLogin or KeyState(vk_Shift) then
  begin
    Attempts:=0;
    ul:=GetUsersList;
    LoginForm:=TLoginForm.Create(ul);
    TimeToTerm:=True;
    while (Attempts<3) and (LoginForm.ShowModal=mrOK) do
    begin
      TimeToTerm:=not CheckPassword(LoginForm.Login, LoginForm.Password);
      if not TimeToTerm and not LoginForm.IsChange then
        break;

      if LoginForm.IsChange and not TimeToTerm then
      begin
        ChangePasswordForm:=TFormChangePassword.Create(LoginForm);
        if ChangePasswordForm.ShowModal=mrOK then
        begin
          SetPassword(LoginForm.Login, ChangePasswordForm.NewPassword);
          ShowMessage('Пароль изменён.');
        end
        else
        begin
          TimeToTerm:=True;
        end;
      end
      else
        Inc(Attempts);
    end;
    LoginForm.Release;
    FreeAndNil(ul);
  end
  else
  if not FDBConnector.Connected then
  begin
    TimeToTerm:=True;
    ShowErrorMessage(0, GetDCLMessageString(msConnectDBError));
  end;

  if not TimeToTerm then
    FillUserInfoToGPT(GPT.DCLUserName);

  Result:=TimeToTerm;
end;

procedure TDCLMain.CloseAllDialogs;
var
  ff: IDCLForm;
begin
  For ff in FForms do
  Begin
    If Assigned(ff) then
    begin
      CloseForm(ff, True);
      ReleaseForm(ff);
    end;
  End;
end;

procedure TDCLMain.Update;
begin
  if GPT.AccessLevel>=ulUpdater then
  begin
    if not DirectoryExists(GPT.AppConfigDir+UpdatesDir) then
      ForceDirectories(GPT.AppConfigDir+UpdatesDir);

    UpdateFromPackages(GPT.AppConfigDir+UpdatesDir+PathDelim);
  end;
end;

function TDCLMain.GetVariables: TVariables;
begin
  Result:=FVariables;
end;

function TDCLMain.GetForms: TList<IDCLForm>;
begin
  Result:=FForms;
end;

function TDCLMain.GetDBConnector: TDCLDBConnector;
begin
  Result:=FDBConnector;
end;

procedure TDCLMain.CreateMenu;
begin
  if Assigned(FMainForm) then
    FDCLMenuSelector:=TDCLMenuSelector.Create(Self, FMainForm, GPT.MenuType);
end;

function TDCLMain.GetUsersList: TStringList;
begin
  Result:=TStringList.Create;

  LocalQuery.Params.Clear;
  LocalQuery.SQL.Text:='select * from '+UsersTable+' where '+ShowInListField+' is not null';
  LocalQuery.Open;
  while not LocalQuery.EOF do
  begin
    Result.Append(LocalQuery.FieldByName(UserNameField).AsString);
    LocalQuery.Next;
  end;
  LocalQuery.Close;
end;

procedure TDCLMain.OpenDialog(const DialogName: String);
begin
  CreateDialog(TVariableNamespace.Create('', ''), DialogName, True, nil, nil, GPT.AccessLevel, nil, False);
end;

procedure TDCLMain.RunCommandScript(const CommandName: String);
var
  Command: IDCLCommand;
begin
  Command:=TDCLCommand.Create(Self, TVariableNamespace.Create('', ''), nil, nil);
  Command.RunCommandScript(CommandName);
  Command:=nil;
end;

procedure TDCLMain.About;
var
  About: TAboutForm;
begin
  About:=TAboutForm.Create(Application, Self);
  About.ShowModal;
  About.Release;
end;

procedure TDCLMain.ExitApp;
begin
  Application.MainForm.Close;
end;

function TDCLMain.GetImageList: TImageList;
begin
  Result:=FImages;
end;

function TDCLMain.GetImageIndex(PictureType: TPicturesTypes): Integer;
begin
  if FPicturesIndexes.ContainsKey(PictureType) then
    Result:=FPicturesIndexes[PictureType]
  else
    Result:=-1;
end;

function TDCLMain.GetImageIndexes: TDictionary<TPicturesTypes, Integer>;
begin
  Result:=FPicturesIndexes;
end;

end.

