unit uSystemUtils;
{$I DefineType.pas}

interface

uses
{$IFDEF MSWINDOWS}
  Windows, Variants, ShlObj, ComObj,
{$ENDIF}
{$IFDEF FPC}
  LConvEncoding,
{$ENDIF}
{$IFDEF FPC}
  InterfaceBase, LCLType,
{$ENDIF}
{$IFDEF UNIX}
  cwstring, process, unix, lclintf,
{$ENDIF}
  Classes, Graphics, SysUtils;

function ValidObject(const AObj: TObject): Boolean;
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

Function BaseToInterface(S: String): String;

implementation

uses
  uDCLData, uDCLGlobalVariables, uRunProgram;

function ValidObject(const AObj: TObject): Boolean;
begin
  Result:=Assigned(AObj){$IFDEF AUTOREFCOUNT}and(not AObj.Disposed){$ENDIF};
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

function GetParams(App: String): String;
var
  p:Integer;
begin
  p:=Pos(' ', App);
  if p=0 then
    Result:=App
  else
  begin
    Result:=Copy(App, p+1, Length(App));
  end;
end;

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

function GetMacAddress: string;
var
  aProcess: TProcess;
  aStrings: TStringList;
  aString, aBuffer: String;
  i: Integer;
begin
  Result:='00-00-00-00-00-00';
  aProcess:=TProcess.Create(Nil);
  aProcess.Commandline:='/sbin/ifconfig';
  aProcess.Options:=[poUsePipes, poNoConsole];
  aProcess.Execute;
  SetLength(aBuffer, 3000);
  Repeat
    i:=aProcess.Output.Read(aBuffer[1], Length(aBuffer));
    aString:=aString+Copy(aBuffer, 1, i);
  Until i=0;
  aProcess.Free;
  aStrings:=TStringList.Create;
  aStrings.Text:=aString;
  For i:=0 To aStrings.Count-1 Do
    If Not(Pos('HWaddr ', aStrings[i])=0) Then
    Begin
      aString:=aStrings[i];
      Delete(aString, 1, Pos('HWaddr ', aString)+6);
      Result:=aString;
    End;
  aStrings.Free;
end;

Function KeyState(Key: Integer): Boolean;
Begin
  Result:=GetKeyState(Key)<>0;
End;

Function ExecuteApp(App: String; Wait: Boolean=False): Boolean;
Var
  aProcess: TProcess;
Begin
  Try
    aProcess:=TProcess.Create(nil);
    aProcess.Commandline:=App;
    If Wait then
      aProcess.Options:=aProcess.Options+[poWaitOnExit, poUsePipes];
    aProcess.Execute;
    Result:=True;
    FreeAndNil(aProcess);
  Except
    Result:=False;
  end;
End;

procedure ExecApp(const App: String; const CurrDir: String);
Begin
  ExecuteApp(App);
End;

Function ExecAndWait(Const FileName: ShortString; Const WinState: Word; Wait:Boolean=True): Boolean;
Begin
  Result:=ExecuteApp(FileName, Wait);
End;

Procedure Exec(Const FileName, Directory: String);
Begin
  ExecuteApp(FileName);
End;

{$ENDIF}

Function ShiftDown: Boolean;
Begin
  Result:=KeyState(VK_SHIFT);
End;

Function UpTime: Cardinal;
Begin
  Result:={$IFDEF MSWINDOWS}GetTickCount
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

Function BaseToInterface(S: String): String;
Begin
  Result:=ConvertEncoding(S, GPT.ServerCodePage, 'utf8');  // DefaultInterfaceEncoding);
End;

end.

