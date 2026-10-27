program DCLPlatform;
{$mode Delphi}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  {$IFDEF FPC}
  Interfaces,
  {$ENDIF}
  Classes, Forms, SysUtils, uIDCLMain, fPlatformMain,
  uDCLMain, uDCLConst, uDCLException, uDCLMessages
  ;

{$R *.res}

function GetAppName: String;
begin
  Result:=SelfAppName;
end;

var
  MainForm: TMainForm;
  DCL: IDCLMain;
begin
  {$IFDEF heaptrc}
  SetHeapTraceOutput('heaptrace.trc');
  {$ENDIF}
  RequireDerivedFormResource:=False;
  Application.Scaled:=True;
  OnGetApplicationName:=GetAppName;

  try
    Application.Initialize;

    DCL:=TDCLMain.Create;
    if not DCL.Start then
    begin
      Application.CreateForm(TMainForm, MainForm);
      MainForm.SetDCLMain(DCL);
      DCL.RunInterface(MainForm);
      Application.Run;
      DCL.Finalize;
    end;
  except
    on E: EDCLException do
    begin
      ShowErrorMessage(E.HelpContext, E.Message);
    end;
    on E: Exception do
    begin
      ShowErrorMessage(-1, E.Message);
    end;
  end;
  DCL:=nil;
end.

