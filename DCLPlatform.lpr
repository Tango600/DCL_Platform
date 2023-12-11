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
  Classes, Forms, Controls, SysUtils, uDCLMain, uSystemUtils, uStringParams,
  fMain, fDCLLoginForm, fAbout
  ;

{$R *.res}

var
  MainForm: TMainForm;
  LoginForm: TLoginForm;
  DCL: TDCLMain;
  TimeToTerm: Boolean;

function FindFormCall: String;
begin
  Result:=FindCommandStrParam('Form');
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

function FindMainMenu: Boolean;
begin
  Result:=FindCommandStrParam('MainMenu')='1';
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

  DialogName:=FindFormCall;
  if DialogName='' then
  begin
    ScriptName:=FindScriptName;
    if ScriptName='' then
    begin
      DCL.CreateMenu(MainForm);
    end
    else
    begin
      DCL.RunCommandScript(ScriptName);
    end;
  end
  Else
  begin
    if FindMainMenu then
      DCL.CreateMenu(MainForm);

    DCL.OpenDialog(DialogName, False);
  end;
end;

begin
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

