unit uSystemUtils;
{$mode Delphi}

interface

uses
{$IFDEF MSWINDOWS}
  Windows, ShlObj,
{$ENDIF}
{$IFDEF FPC}
  LConvEncoding,
{$ENDIF}
{$IFDEF FPC}
  InterfaceBase, LCLType,
{$ENDIF}
{$IFDEF UNIX}
  cwstring, lclintf,
{$ENDIF}
  Classes, Graphics, SysUtils;

function ValidObject(const AObj: TObject): Boolean;
function FindCommandStrParam(Str: String): String;

Function KeyState(Key: Integer): Boolean;
Function IsUNCPath(Path: String): Boolean;
Function IsFullPath(Path: String): Boolean;
Function ShiftDown: Boolean;

function GetUserProfileDir: String;
function GetUserDocumentsDir: String;

function GetAppName(App: String): String;

procedure OpenDir(Dir: String);

function GetScreen:TBitmap;

Function UpTime: Cardinal;

{$IFDEF MSWINDOWS}
function GetSpecialPath(CSIDL: Word): string;
{$ENDIF}

implementation

uses
  uDCLData, uDCLGlobalVariables, uRunProgram, uStringParams;

function ValidObject(const AObj: TObject): Boolean;
begin
  Result:=Assigned(AObj){$IFDEF AUTOREFCOUNT}and(not AObj.Disposed){$ENDIF};
end;

function FindCommandStrParam(Str: String): String;
var
  i: Byte;
  s: String;
begin
  Result:='';
  For i:=1 to ParamCount do
  begin
    s:=FindParam(Str+'=', ParamStr(i));
    if s<>'' then
    begin
      Result:=s;
      break;
    end;
  end;
end;

function GetUserProfileDir: String;
Begin
{$IFDEF UNIX}
  Result:=GetEnvironmentVariable('HOME')+PathDelim;
{$ENDIF}
{$IFDEF MSWINDOWS}
  Result:=GetSpecialPath(CSIDL_PERSONAL)+PathDelim;
{$ENDIF}
End;

function GetUserDocumentsDir: String;
Begin
{$IFDEF UNIX}
  Result:=GetEnvironmentVariable('HOME')+PathDelim;
{$ENDIF}
{$IFDEF MSWINDOWS}
  Result:=GetSpecialPath(CSIDL_MYDOCUMENTS)+PathDelim;
{$ENDIF}
End;

{$IFDEF MSWINDOWS}
Function KeyState(Key: Integer): Boolean;
Begin
{$R-}
  Result:=HiWord(GetKeyState(Key))<>0;
{$R+}
End;

function GetSpecialPath(CSIDL: Word): string;
var
  S: string;
begin
  SetLength(S, MAX_PATH-1);
  if not SHGetSpecialFolderPath(0, PChar(S), CSIDL, True) then
    S:='';
  S:=S+#0#0;
  Result:=String(PChar(S));
end;
{$ENDIF}
{$IFDEF UNIX}

Function KeyState(Key: Integer): Boolean;
Begin
  Result:=GetKeyState(Key)<>0;
End;

{$ENDIF}

Function ShiftDown: Boolean;
Begin
  Result:=KeyState(VK_SHIFT);
End;

Function UpTime: Cardinal;
Begin
  Result:={$IFDEF MSWINDOWS}{$IFDEF CPU64}GetTickCount64{$ELSE}GetTickCount{$ENDIF}
{$ELSE}
    ((StrToInt(FormatDateTime('H', Time))*3600+StrToInt(FormatDateTime('N', Time))*60+
    StrToInt(FormatDateTime('S', Time)))*1000)+StrToInt(FormatDateTime('Z', Time));
{$ENDIF};
End;

Function IsFullPath(Path: String): Boolean;
Begin
  If Length(Path)>1 then
    Result:=((Pos(':\', Path)=2)or(Path[1]='/')or(Path[1]='~')) and (LastDelimiter('/\', Path)<>0)
  Else
    Result:=False;
End;

Function IsUNCPath(Path: String): Boolean;
Begin
  Result:=Pos('\\', Path)=1;
End;

function GetAppName(App: String): String;
var
  p:Integer;
begin
  p:=Pos(' ', App);
  if p=0 then
    Result:=App
  else
  begin
    Result:=Copy(App, 1, p-1);
  end;
end;

procedure OpenDir(Dir: String);
begin
{$IFDEF MSWINDOWS}
  Run('EXPLORER.exe', '/e, "'+Dir+'"', False);
{$ENDIF}
{$IFDEF LINUX}
  Run('xdg-open', '"'+Dir+'"', False);
{$ENDIF}
end;

function GetScreen:TBitmap;
var
  DC:HDC;
{$IFNDEF FPC}
  r:TRect;
  c:TCanvas;
  w, h:Word;
{$ENDIF}
begin
  Result:=TBitmap.Create;
{$IFNDEF FPC}
  w:=GetSystemMetrics(SM_CXSCREEN);
  h:=GetSystemMetrics(SM_CYSCREEN);
  c:=TCanvas.Create;
  DC:=GetDesktopWindow;
  c.Handle:=GetWindowDC(DC);
  try
    r:=Rect(0, 0, w, h);
    Result.Width:=w;
    Result.Height:=h;
    Result.Canvas.CopyRect(r, c, r);
  finally
    ReleaseDC(DC, c.Handle);
    c.Free;
  end;
{$ELSE}
  DC:=WidgetSet.GetDC(0);
  try
    Result.LoadFromDevice(DC);
  finally
    WidgetSet.ReleaseDC(0, DC);
  end;
{$ENDIF}
end;

end.

