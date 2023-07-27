program DCLPlatform;
{$I DefineType.pas}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Classes, Forms, Controls, SysUtils, fMain, uDCLGlobalVariables, uDCLData,
  uDCLTypes, uDCLConst, uDCLMain, uDCLForm, uDCLCommand, uDCLGrid,
  uDCLVariables, uDCLDBConnector, uDCLConfig, uStringParams, uDCLDebug,
  uDCLMenu, uDBUtils, fDCLLoginForm, uSystemUtils, uSQLUtils, uDCLDBStructure,
  uDCLMultiLang, uDCLValuesParser, uDCLMeasurements,
  uDCLCommandButton, uDCLMD5, uDCLBaseLayoutManger, uDCLButtonLayoutManger,
  uDCLVerticalFieldLayoutManger, uDCLField, uDCLImages, uSQLParser,
  cNoScrollBarDBGrid, cMediaFieldGroup, uDCLDataStorage, uDCLTextReport,
  uRunProgram, uPrintBase, uDCLFormsNotifier, fChangePasswordForm, fAbout,
  uDCLQueryUtils, uDCLVersion, uDCLGlobalConfigTable;

{$R *.res}

var
  MainForm: TMainForm;
  LoginForm: TLoginForm;
  DCL: TDCLMain;

function FindCommandStrParam(Str: String): String;
var
  i: Byte;
begin
  For i:=1 to ParamCount do
  begin
    if PosEx(Str, ParamStr(i))<>0 then
    begin
      Result:=Copy(ParamStr(i), Length(Str)+1, Length(ParamStr(i)));
      break;
    end;
  end;
end;

function FindFormCall: String;
begin
  Result:=FindCommandStrParam('Form=');
end;

function FindScriptName: String;
begin
  Result:=FindCommandStrParam('Script=');
end;

function FindScryptFileCall: String;
begin
  Result:=FindCommandStrParam('ScryptFile=');
end;

function FindMainMenu: Boolean;
begin
  Result:=FindCommandStrParam('MainMenu=')='1';
end;

function FindVariablesParams: String;
begin
  Result:=FindCommandStrParam('Variables=');
end;

procedure RunInterface;
var
  i, p:Integer;
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

  S:=FindScryptFileCall;
  If S<>'' then
    DCL.RunSkriptFromFile(S);

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
      DCL.RunCommand(ScriptName);
    end;
  end
  Else
  begin
    if FindMainMenu then
      DCL.CreateMenu(MainForm);

    DCL.OpenDialog('', DialogName);
  end;
end;

begin
  RequireDerivedFormResource:=False;
  Application.Scaled:=True;
  Application.Initialize;

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
      Application.Terminate;
    end;
  end
  else
  begin
    RunInterface;
  end;
  Application.CreateForm(TAboutForm, AboutForm);
  Application.Run;

  FreeAndNil(DCL);
end.

