unit uSystemUtils;
{$mode Delphi}

interface

uses
{$IFDEF MSWINDOWS}
  Windows, ShlObj,
{$ENDIF}
{$IFDEF UNIX}
  cwstring, lclintf, lcltype,
{$ENDIF}
  Classes, Graphics, SysUtils, uDCLConst;

function ValidObject(const AObj: TObject): Boolean;
function FindCommandStrParam(Str: String): String;

Function KeyState(Key: Integer): Boolean;
Function ShiftDown: Boolean;
Function IsNoFileExt(const FileName:String): Boolean;
Function AddToFileName(Const FileName, AddStr: String): String;
Function GetTempFileName(const Ext: String): String;

function ReplaseCPtoWIN(const CodePageName: String): String;

function GetUserProfileDir: String;
function GetUserDocumentsDir: String;

procedure OpenDir(Dir: String);

function GetGUIDString: String;
Function UpTime: QWord;
function IntToColor(Value: Integer): TColor;
function ColorToHex(Color: TColor): String;

function NegativeColor(Color: TColor): TColor;

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

function ColorToHex(Color: TColor): String;
var
  c, r, g, b: LongInt;
begin
  c:=ColorToRGB(Color);
  r:=c and $ff;
  g:=c and $ff00 div $ff;
  b:=c and $ff0000 div $ff00;

  Result:=HexStr(r, 2)+HexStr(g, 2)+HexStr(b, 2);
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

{$IFDEF MSWINDOWS}
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

function GetUserProfileDir: String;
Begin
{$IFDEF UNIX}
  Result:=GetEnvironmentVariable('HOME')+PathDelim;
{$ENDIF}
{$IFDEF MSWINDOWS}
  Result:=GetSpecialPath(CSIDL_APPDATA)+PathDelim;
{$ENDIF}
End;

function GetUserDocumentsDir: String;
Begin
{$IFDEF UNIX}
  Result:=GetEnvironmentVariable('HOME')+PathDelim;
{$ENDIF}
{$IFDEF MSWINDOWS}
  Result:=GetSpecialPath(CSIDL_PERSONAL)+PathDelim;
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

Function UpTime: QWord;
Begin
  Result:={$IFDEF MSWINDOWS}{$IFDEF CPU64}GetTickCount64{$ELSE}GetTickCount{$ENDIF}
{$ELSE}
    ((StrToInt(FormatDateTime('H', Time))*3600+StrToInt(FormatDateTime('N', Time))*60+
    StrToInt(FormatDateTime('S', Time)))*1000)+StrToInt(FormatDateTime('Z', Time));
{$ENDIF};
End;

procedure OpenDir(Dir: String);
begin
{$IFDEF MSWINDOWS}
  Run('EXPLORER.exe', '/e, "'+Dir+'"', False);
{$ENDIF}
{$IFDEF LINUX}
  Run('xdg-open', '"'+Dir+'"', False);
{$ENDIF}
end;

Function IsNoFileExt(const FileName:String): Boolean;
begin
  Result:=ExtractFileExt(FileName)='';
end;

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

function GetGUIDString: String;
var
  guid: TGUID;
begin
  CreateGUID(guid);
  Result:=GUIDToString(guid);
end;

end.

