unit uSystemUtils;
{$mode Delphi}

interface

uses
  uDCLConst,
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
Function NoFileExt(const FileName:String): Boolean;
Function FakeFileExt(Const FileName, Ext: String): String;
Function AddToFileName(Const FileName, AddStr: String): String;
Function GetTempFileName(const Ext: String): String;

function ReplaseCPtoWIN(const CodePageName: String): String;
function ReplaseWINtoCP(const CodePageName: String): String;

function GetUserProfileDir: String;
function GetUserDocumentsDir: String;

function GetAppName(App: String): String;

procedure OpenDir(Dir: String);

function GetScreen:TBitmap;
function ConvertToJPEG(const BitMap: TBitmap; Quality: Byte=JPEGCompressionQuality): TJpegImage;

function GetGUIDString: String;
Function UpTime: Cardinal;
function IntToColor(Value: Integer): TColor;

function NegativeColor(Color: TColor): TColor;

{$IFDEF MSWINDOWS}
function GetSpecialPath(CSIDL: Word): string;
{$ENDIF}

implementation

uses
  uDCLGlobalVariables, uRunProgram, uStringParams;

function ValidObject(const AObj: TObject): Boolean;
begin
  Result:=Assigned(AObj){$IFDEF AUTOREFCOUNT}and(not AObj.Disposed){$ENDIF};
end;

function IntToColor(Value: Integer): TColor;
begin
  Result:=RGBToColor(Value and $ff0000 div $00ffff, Value and $00ff00 div $ff, Value and $0000ff);
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

function NegativeColor(Color: TColor): TColor;
var
  r, g, b: Byte;
begin
  b:=Color and $ff0000 div $00ffff;
  g:=Color and $00ff00 div $ff;
  r:=Color and $0000ff;

  Result:=RGBToColor(r xor $ff, g xor $ff, b xor $ff);
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

Function NoFileExt(const FileName:String): Boolean;
var
  i, p, l, k: Integer;
begin
  p:=0;
  k:=0;
  i:=Length(FileName);
  l:=i-5;
  If i<=5 then
    l:=1;

  For i:=Length(FileName) downto l do
  Begin
    If FileName[i]=PathDelim then
    begin
      Result:=True;
      Exit;
    end;

    If FileName[i]='.' then
    Begin
      k:=p;
      Break;
    End;
    Inc(p);
  End;

  Result:=not (k>1);
end;

Function FakeFileExt(Const FileName, Ext: String): String;
Begin
  Result:=ChangeFileExt(FileName, '.'+Ext);
End;

Function AddToFileName(Const FileName, AddStr: String): String;
Var
  tmpS, P, Ext: String;
Begin
  tmpS:=ExtractFileName(ChangeFileExt(FileName, ''));
  P:=ExtractFilePath(FileName);
  Ext:=ExtractFileExt(FileName);
  Result:=P+tmpS+AddStr+Ext;
End;

Function GetTempFileName(const Ext: String): String;
var
  ep: Integer;
Begin
  If Ext<>'' then
  Begin
    ep:=1;
    If Ext[1]='.' then
      ep:=2;
    Result:='tmp'+IntToStr(UpTime)+'.'+Copy(Ext, ep, Length(Ext));
  End
  Else
    Result:='tmp'+IntToStr(UpTime);
End;

function ReplaseCPtoWIN(const CodePageName: String): String;
begin
  Result:=CodePageName;
  If Pos('cp', LowerCase(CodePageName))=1 then
  Begin
    Result:='WIN'+Copy(CodePageName, 3, Length(CodePageName));
  End;
end;

function ReplaseWINtoCP(const CodePageName: String): String;
begin
  Result:='';
  If Pos('win', LowerCase(CodePageName))=1 then
  Begin
    Result:='cp'+Copy(CodePageName, 4, Length(CodePageName));
  End;
end;

function GetGUIDString: String;
var
  guid: TGUID;
begin
  CreateGUID(guid);
  Result:=GUIDToString(guid);
end;

function GetScreen: TBitmap;
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

function ConvertToJPEG(const BitMap: TBitmap; Quality: Byte=JPEGCompressionQuality): TJpegImage;
begin
  if Quality=0 then
    Quality:=JPEGCompressionQuality;
  Result:=TJpegImage.Create;
  Result.ProgressiveEncoding:=True;
  try
    Result.CompressionQuality:=Quality;
    Result.Assign(BitMap);
  finally
    ///
  end;
end;

end.

