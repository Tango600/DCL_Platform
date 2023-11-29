unit uDCLUtils;
{$mode Delphi}

interface

uses
  SysUtils, Forms, ExtCtrls, Dialogs,
  Controls, Classes, DateUtils,
{$IFNDEF FPC}
  JPEG,
{$ENDIF}
  Graphics,
  uLZW, uSystemUtils, uDCLMultiLang,
  uDCLData, uDCLConst, uStringParams;

function IsLexem(const Lexem, S: String): Boolean;

Function StrToIntEx(St: String): LongInt;
Function StrToFloatEx(St: String): Real;
Function HexToInt64(HexStr: String): Int64;
Function HexToInt(HexStr: String): Integer;
Function Pow(const Base:Cardinal; PowNum: Word): Cardinal; overload;
Function Pow(Const Base: Real; PowNum: Word): Real; overload;
Procedure DeleteNonPrintSimb(Var S: String);
Function CountSimb(S: String; C: Char): Integer;
Function LeadingZero(Const aVal: Word): String;
Function CopyCut(Var S: String; From, Count: Word): String;
function ReplaseCPtoWIN(CodePageName:String):String;
function ReplaseWINtoCP(CodePageName:String):String;

Procedure InitGetAppConfigDir;
Function NoFileExt(const FileName:String):Boolean;
Function FakeFileExt(Const FileName, Ext: String): String;
Function AddToFileName(Const FileName, AddStr: String): String;
Function GetFileNameToTranslite(Const FullFileName: String): String;

Function FindDisableAction(Action: String): Boolean;
Function TranslateDigitToUserLevel(Level: byte): TUserLevelsType; overload;
Function TranslateDigitToUserLevel(Level: String): TUserLevelsType; overload;
Function GetStringDataType(const S: String): TIsDigitType;
function CheckStrFmtType(const S:string; SimplyFormatType:TSimplyFieldType):Boolean;
function FindSubstrInString(AText:string; AValues:Array of String):Integer;

function PosInSet(SimbolsSet, SourceStr: String): Cardinal;
Function GetTempFileName(Ext: String): String;

Function ExtractSection(Var SectionStr: String): String;
function GetGraficFileType(FileName: string): TGraficFileType;
function GetExtByType(FileType:TGraficFileType):String;
Function CopyStrings(FromString, ToString: String; Where: TStringList): TStringList;

function ConvertToJPEG(BitMap:TBitmap; Quality:Byte=JPEGCompressionQuality):TJpegImage;

function IsDigits(Value: String): Boolean;
function OnlyLitters(S: String): String;

implementation

uses
  SumProps, uDCLGlobalVariables;

function IsLexem(const Lexem, S: String): Boolean;
var
  t: String;
begin
  t:=Trim(S);
  Result:=Pos(LowerCase(Lexem), LowerCase(t))=1;
end;

Function LeadingZero(Const aVal: Word): String;
Begin
  If aVal<10 Then
    Result:='0'+IntToStr(aVal)
  Else
    Result:=IntToStr(aVal);
End;

Procedure DeleteNonPrintSimb(Var S: String);
Var
  L, i: Integer;
Begin
  L:=Length(S);
  While L<>0 Do
  Begin
    If S[L]=#10 Then
      S[L]:=' ';
    If S[L]=#9 Then
    Begin
      For i:=1 To TabSize Do
        Insert(' ', S, L);
    End;
    If (S[L]=#13)Or(S[L]=#0) Then
      Delete(S, L, 1);
    Dec(L);
  End;
End;

Function CountSimb(S: String; C: Char): Integer;
Var
  L: Integer;
Begin
  Result:=0;
  For L:=1 To Length(S) Do
    If S[L]=C Then
      Inc(Result, 1);
End;

Function GetTempFileName(Ext: String): String;
Begin
  If Ext<>'' then
  Begin
    If Ext[1]='.' then
      Delete(Ext, 1, 1);
    Result:='tmp'+IntToStr(UpTime)+'.'+Ext;
  End
  Else
    Result:='tmp'+IntToStr(UpTime);
End;

function CheckStrFmtType(const S:string; SimplyFormatType:TSimplyFieldType):Boolean;
Begin
  Case SimplyFormatType of
  sftNotDefine, sftString:Result:=True;
  sftDigit:Result:=GetStringDataType(S)=idDigit;
  sftFloat:Result:=GetStringDataType(S)=idFloatDigit;
  sftDateTime:Result:=GetStringDataType(S)=idDateTime;
  End;
End;

function FindSubstrInString(AText:string; AValues:Array of String):Integer;
var
  i, MaxLong:Integer;
Begin
  Result:=-1;
  MaxLong:=0;
  For I := Low(AValues) to High(AValues) do
    If PosEx(AValues[I], AText)<>0 then
    begin
      If MaxLong<Length(AValues[I]) then
      Begin
        MaxLong:=Length(AValues[I]);
        Result:=i;
      End;
    end;
End;

Function GetFileNameToTranslite(Const FullFileName: String): String;
Var
  FileName, NewFileName, FilePath: String;
Begin
  FileName:=ExtractFileName(FullFileName);
  FilePath:=ExtractFilePath(FullFileName);

  NewFileName:=Transcode(tdtTranslit, FileName);

  Result:=FilePath+NewFileName;
End;

Function Pow(const Base:Cardinal; PowNum: Word): Cardinal; overload;
var
  i: Word;
  s: Cardinal;
Begin
  s:=Base;
  If PowNum>1 then
  For i:=1 to PowNum-1 do
    s:=s*Base;
  Result:=s;
End;

Function Pow(Const Base: Real; PowNum: Word): Real; overload;
Var
  i: Word;
  S: Real;
Begin
  S:=Base;
  If PowNum>1 then
  For i:=1 To PowNum-1 Do
    S:=S*Base;
  Result:=S;
End;

Function StrToIntEx(St: String): LongInt;
Var
  iI, L: Integer;
  tmpS: String;
Begin
  //St:=Calculate(St);
  L:=Length(St);
  tmpS:='';
  For iI:=1 To L Do
  Begin
    If (St[iI]>='0')And(St[iI]<='9')Or(St[iI]='-') Then
      tmpS:=tmpS+St[iI];
  End;
  If tmpS='' Then
    tmpS:='0';
  Try
    Result:=StrToInt(tmpS);
  Except
    Result:=0;
  End;
End;

Function StrToFloatEx(St: String): Real;
Var
  iI, L: Integer;
  tmpS: String;
Begin
  L:=Length(St);
  tmpS:='';
  For iI:=L Downto 1 Do
    If Pos(St[iI], '.,')<>0 Then
      St[iI]:=FormatSettings.DecimalSeparator;

  //St:=Calculate(St);
  L:=Length(St);
  tmpS:='';
  For iI:=1 To L Do
  Begin
    If (St[iI]>='0')And(St[iI]<='9')Or(St[iI]='-')Or(St[iI]='.')Or(St[iI]=',') Then
      tmpS:=tmpS+St[iI];
  End;
  If tmpS='' Then
    tmpS:='0';
  Try
    Result:=StrToFloat(tmpS);
  Except
    Result:=0;
  End;
End;

Function InString(Const Sub, S: String; FullMatch: Boolean): Word;
Var
  i: Word;
Begin
  Result:=0;
  If FullMatch Then
  Begin
    Result:=Pos(Sub, S);
  End
  Else
    For i:=1 To Length(Sub) Do
    Begin
      Result:=Pos(Sub[i], S);
      If Result<>0 Then
        Break;
    End;
End;

Function CopyCut(Var S: String; From, Count: Word): String;
Begin
  Result:=Copy(S, From, Count);
  Delete(S, From, Count);
End;

function PosInSet(SimbolsSet, SourceStr: String): Cardinal;
Var
  i: Cardinal;
begin
  Result:=0;
  For i:=1 to Length(SourceStr) do
  Begin
    If PosEx(SourceStr[i], SimbolsSet)<>0 then
    Begin
      Result:=i;
      Break;
    End;
  End;
end;

Function FindDisableAction(Action: String): Boolean;
Var
  iI: Byte;
Begin
  Result:=False;
  For iI:=1 To ToolCommandsCount Do
    If LowerCase(ToolButtonsCmd[iI])=LowerCase(Action) Then
    Begin
      Result:=True;
      Break;
    End;
End;

Function TranslateDigitToUserLevel(Level: byte): TUserLevelsType; overload;
Begin
  Result:=TUserLevelsType(Level);
End;

Function TranslateDigitToUserLevel(Level: String): TUserLevelsType; overload;
const
  ulPrefix='ul';
Begin
  If DCLCompareString(Level, ulPrefix+'Undefined') Then
    Result:=ulUndefined
  Else If DCLCompareString(Level, ulPrefix+'Deny') Then
    Result:=ulDeny
  Else If DCLCompareString(Level, ulPrefix+'ReadOnly') Then
    Result:=ulReadOnly
  Else If DCLCompareString(Level, ulPrefix+'Write') Then
    Result:=ulWrite
  Else If DCLCompareString(Level, ulPrefix+'Execute') Then
    Result:=ulExecute
  Else If DCLCompareString(Level, ulPrefix+'Level1') Then
    Result:=ulLevel1
  Else If DCLCompareString(Level, ulPrefix+'Level2') Then
    Result:=ulLevel2
  Else If DCLCompareString(Level, ulPrefix+'Level3') Then
    Result:=ulLevel3
  Else If DCLCompareString(Level, ulPrefix+'Level4') Then
    Result:=ulLevel4
  Else If DCLCompareString(Level, ulPrefix+'Updater') Then
    Result:=ulUpdater
  Else If DCLCompareString(Level, ulPrefix+'Signer') Then
    Result:=ulSigner
  Else If DCLCompareString(Level, ulPrefix+'Developer') Then
    Result:=ulDeveloper
  Else
    Result:=ulUndefined;
End;

Function GetStringDataType(const S: String): TIsDigitType;
Var
  iI: Integer;
Begin
  Result:=idString;
  If S<>'' Then
  Begin
    If Length(S)>1 then
    Begin
      If (PosEx('cl', S)=1) and (Length(S)>4) Then
      Begin
        Result:=idColor;
        Exit;
      End;
      If (PosEx('ul', S)=1) and (Length(S)>5) and (IndexInSet(UserLevelsSet, S.Substring(2))<>0) then
      Begin
        Result:=idUserLevel;
        Exit;
      End;
      If (LowerCase(S[1])='h') or (S[1]='$') Then
      Begin
        For iI:=2 To Length(S) Do
        Begin
          If PosEx(S[iI], '0123456789ABCDEF')=0 then
          Begin
            Result:=idString;
            Exit;
          End;
        End;
        Result:=idHex;
        Exit;
      End;
      For iI:=1 To Length(S) Do
      Begin
        If Pos(S[iI], '0123456789-.,')=0 then
        Begin
          If (Pos(S[iI], '0123456789-.: ')<>0) and (Length(S)>=9) then
          Begin
            Result:=idDateTime;
            Exit;
          End;
          Result:=idString;
          Exit;
        End
        Else
        Begin
          If Pos(S[iI], '0123456789-')<>0 then
            Result:=idDigit
          Else
            If Pos(S[iI], '0123456789-,.')<>0 then
              Result:=idFloatDigit;
          Exit;
        End;
      End;
    End
    Else
    Begin
      If Pos(S, '0123456789')=0 then
      Begin
        Result:=idString;
        Exit;
      End
      Else
      Begin
        Result:=idDigit;
        Exit;
      End;
    End;
  End
  Else
    Result:=idString;
End;

Function NoFileExt(const FileName:String):Boolean;
var
  i, p, l, k:Integer;
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

Procedure InitGetAppConfigDir;
Begin
  UserProfileDir:=GetUserProfileDir;
  if not DirectoryExists(UserProfileDir) then
    ForceDirectories(UserProfileDir);

  AppConfigDir:=UserProfileDir+DCLDir;
End;

/// ////////////////////////////////////////////////////////////

Function HexToInt64(HexStr: String): Int64;
Var
  RetVar: Int64;
  i: Word;
Begin
  HexStr:=UpperCase(HexStr);
  If UpperCase(HexStr[Length(HexStr)])='H' Then
    Delete(HexStr, Length(HexStr), 1);
  RetVar:=0;
  For i:=1 To Length(HexStr) Do
  Begin
    RetVar:=RetVar Shl 4;
    If HexStr[i] In ['0'..'9'] Then
      RetVar:=RetVar+(byte(HexStr[i])-48)
    Else If HexStr[i] In ['A'..'F'] Then
      RetVar:=RetVar+(byte(HexStr[i])-55);
  End;
  Result:=RetVar;
End;

Function HexToInt(HexStr: String): Integer;
Var
  RetVar: Integer;
  i: Word;
Begin
  HexStr:=UpperCase(HexStr);
  If UpperCase(HexStr[Length(HexStr)])='H' Then
    Delete(HexStr, Length(HexStr), 1);
  RetVar:=0;
  For i:=1 To Length(HexStr) Do
  Begin
    RetVar:=RetVar Shl 4;
    If HexStr[i] In ['0'..'9'] Then
      RetVar:=RetVar+(byte(HexStr[i])-48)
    Else If HexStr[i] In ['A'..'F'] Then
      RetVar:=RetVar+(byte(HexStr[i])-55);
  End;
  Result:=RetVar;
End;

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

Function ExtractSection(Var SectionStr: String): String;
Var
  PosD: Word;
Begin
  PosD:=Pos('/', SectionStr);
  If PosD=0 Then
  Begin
    Result:=SectionStr;
    SectionStr:='';
  End
  Else
  Begin
    Result:=Copy(SectionStr, 1, PosD-1);
    Delete(SectionStr, 1, PosD);
  End;
End;

function GetGraficFileType(FileName: string): TGraficFileType;
var
  Ext: String;
Begin
  Result:=gftNone;
  Ext:=LowerCase(ExtractFileExt(FileName));
  If Ext='.bmp' then
    Result:=gftBMP;
  If (Ext='.jpg')or(Ext='.jpeg') then
    Result:=gftJPEG;
End;

function GetExtByType(FileType:TGraficFileType):String;
Begin
  Case FileType of
  gftBMP:Result:='bmp';
  gftJPEG, gftOther:Result:='jpg';
  gftPNG:Result:='png';
  gftIcon:Result:='ico';
  gftGIF:Result:='gif';
  gftTIFF:Result:='tiff';
  end;
End;

Function CopyStrings(FromString, ToString: String; Where: TStringList): TStringList;
Var
  li, FromPos, CurrPos: Integer;
Begin
  Result:=TStringList.Create;
  Result.Clear;
  If Where.Count>0 Then
  Begin
    CurrPos:=0;
    While (UpperCase(Where[CurrPos])<>UpperCase(FromString)) And
      (CurrPos+1<>Where.Count) Do
      Inc(CurrPos);
    FromPos:=CurrPos;
    While (UpperCase(Where[CurrPos])<>UpperCase(ToString)) And
      (CurrPos+1<>Where.Count) Do
      Inc(CurrPos);
    For li:=FromPos+1 To CurrPos-1 Do
      Result.Append(Where[li]);
  End;
End;

function ConvertToJPEG(BitMap:TBitmap; Quality:Byte=JPEGCompressionQuality):TJpegImage;
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

function ReplaseCPtoWIN(CodePageName:String):String;
begin
  Result:=CodePageName;
  If PosEx('cp', CodePageName)=1 then
  Begin
    Result:='WIN'+Copy(CodePageName, 3, Length(CodePageName));
  End;
end;

function ReplaseWINtoCP(CodePageName:String):String;
begin
  Result:='';
  If PosEx('win', CodePageName)=1 then
  Begin
    Result:='cp'+Copy(CodePageName, 4, Length(CodePageName));
  End;
end;

function IsDigits(Value: String): Boolean;
var
  i: Integer;
begin
  Result:=False;

  if Length(Value)>0 then
  begin
  for I:=1 to Length(Value) do
    if not ((Value[i] in ['0'..'9']) or (Value[I] in ['-', '+'])) then
    begin
      exit;
    end;
  end;
  Result:=True;
end;

function OnlyLitters(S: String): String;
var
  c: Char;
begin
  Result:='';
  for C in S.ToLower do
  begin
    if C in ['a'..'z'] then
    begin
      Result:=Result+C;
    end;
  end;
end;

end.
