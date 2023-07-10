unit fMain;
{$I DefineType.pas}

interface

uses
  {$IFDEF MSWINDOWS}
  Windows, Messages, LazUTF8,
  {$ENDIF}
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls,
  uDCLConst, uDCLData, uDCLMultiLang;

type

  { TMainForm }

  TMainForm = class(TForm)
    StatusBar1: TStatusBar;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private
    procedure ShowAbout;
    {$IFDEF MSWINDOWS}
    procedure WMSysCommand(var message: TWMSysCommand); message WM_SysCommand;
    {$ENDIF}
  public

  end;

{$IFDEF MSWINDOWS}
Const
  AboutMenuItem=WM_USER+1;
  LockMenuItem=AboutMenuItem+1;
{$ENDIF}

implementation

{$R *.lfm}

{ TMainForm }

{$IFDEF MSWINDOWS}
procedure TMainForm.WMSysCommand(var message: TWMSysCommand);
begin
  Case message.CmdType of
  AboutMenuItem: ShowAbout;
  //LockMenuItem: DCLMainLogOn.Lock;
  Else
    inherited;
  End;
end;
{$ENDIF}

procedure TMainForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin

end;

function FindCommandStrParam(Str: String): String;
var
  i: Byte;
begin
  For i:=1 to ParamCount do
  begin
    if Pos(LowerCase(Str), LowerCase(ParamStr(i)))<>0 then
    begin
      Result:=Copy(ParamStr(i), Length(Str)+1, Length(ParamStr(i)));
      break;
    end;
  end;
end;

function FindMDI: Boolean;
begin
  Result:=FindCommandStrParam('MDI=')='1';
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  MDI: Boolean;
  S: String;
  T: TextFile;
begin
  Caption:='DCL Run v.'+Version;
  {$IFDEF MSWINDOWS}
  ParentFont:=True;
  AppendMenu(GetSystemMenu(Handle, False), MF_SEPARATOR, 0, '');
  AppendMenu(GetSystemMenu(Handle, False), MF_STRING, AboutMenuItem,
    Pchar(UTF8ToWinCP('DCL '+GetDCLMessageString(msVersion)+' : '+uDCLConst.Version)));
  AppendMenu(GetSystemMenu(Handle, False), MF_STRING, LockMenuItem, PChar(UTF8ToWinCP(GetDCLMessageString(msLock)+'...')));
  {$ENDIF}

  MDI:=False;
  if FileExists('interface.ini') then
  begin
    AssignFile(T, 'interface.ini');
    ReSet(T);
    While not EOF(T) do
    begin
      ReadLn(T, S);
      if Pos('mdi', LowerCase(S))<>0 then
        MDI:=True;
    end;
    CloseFile(T);
  end;

  if MDI or FindMDI then
    FormStyle:=fsMDIForm;
end;

procedure TMainForm.ShowAbout;
begin

end;

end.

