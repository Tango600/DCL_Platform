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
  Classes, Forms, SysUtils, uIDCLMain, fMain, uDCLMain, uDCLConst
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
  Application.Initialize;

  DCL:=TDCLMain.Create;
  if not DCL.Start then
  begin
    Application.CreateForm(TMainForm, MainForm);
    DCL.RunInterface;
    Application.Run;
  end;

  DCL:=nil;
end.

