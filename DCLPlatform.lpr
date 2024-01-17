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
  Classes, Forms, Controls, SysUtils, uIDCLMain, fMain, uDCLMain
  ;

{$R *.res}

var
  MainForm: TMainForm;
  DCL: IDCLMain;
begin
  {$IFDEF heaptrc}
  SetHeapTraceOutput('heaptrace.trc');
  {$ENDIF}
  RequireDerivedFormResource:=False;
  Application.Scaled:=True;
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

