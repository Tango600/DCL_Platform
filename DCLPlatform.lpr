program DCLPlatform;
{$I DefineType.pas}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  {$IFDEF FPC}
  Interfaces, lcltype,
  {$ENDIF}
  Classes, Forms, Controls, SysUtils, uDCLMain, uDCLBaseMenu, uDCLMenuSelector,
  uDCLMenuPanels, uDCLMenuClassic, uIDCLForm, uIDCLGrid, uSystemUtils,
  uStringParams, fMain, fDCLLoginForm, fAbout
  ;

{$R *.res}

var
  MainForm: TMainForm;
  LoginForm: TLoginForm;
  DCL: TDCLMain;
  TimeToTerm: Boolean;

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

function FindPackageFileLoad: String;
begin
  Result:=FindCommandStrParam('LoadPackage');
end;

function FindMainMenuDesabled: Boolean;
begin
  Result:=FindCommandStrParam('MainMenu')='0';
end;

function FindVariablesParams: String;
begin
  Result:=FindCommandStrParam('Variables');
end;

procedure RunInterface;
var
  i, p:Integer;
  r: Boolean;
  S, vn, v, DialogName, ScriptName, Variables: String;
begin
  Application.CreateForm(TMainForm, MainForm);

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
            DCL.Variables.NewVariable('', Trim(vn), v);
        end;
      end;
    end;
  end;

  DCL.Update;
  MainForm.DCLMain:=DCL;
  r:=False;
  S:=FindPackageFileLoad;
  if S='' then
  begin
    S:=FindPackageFileRun;
    r:=True;
  end;
  If S<>'' then
    DCL.LoadPackageFromFile(S, r);

  ScriptName:=FindScriptName;
  if ScriptName<>'' then
  begin
    DCL.RunCommandScript(ScriptName);
  end;

  DialogName:=FindDialogCall;
  if DialogName<>'' then
  begin
    DCL.OpenDialog(DialogName, False);
  end;

  if not FindMainMenuDesabled then
    DCL.CreateMenu(MainForm);
end;

begin
  {$IFDEF heaptrc}
  SetHeapTraceOutput('heaptrace.trc');
  {$ENDIF}
  RequireDerivedFormResource:=False;
  Application.Scaled:=True;
  Application.Initialize;

  TimeToTerm:=False;
  DCL:=TDCLMain.Create;
  if DCL.IsNeedLogin or KeyState(vk_Shift) then
  begin
    LoginForm:=TLoginForm.Create(DCL.DBConnector);

    if LoginForm.ShowModal=mrOK then
    begin
      LoginForm.Release;
      RunInterface;
    end
    else
    begin
      TimeToTerm:=True;
    end;
  end
  else
  begin
    RunInterface;
  end;

  if not TimeToTerm then
  begin
    Application.Run;
  end;

  FreeAndNil(DCL);
end.

