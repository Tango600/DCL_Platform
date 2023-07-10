unit uDCLUtils;
{$I DefineType.pas}

interface

uses
  SysUtils, Forms, ExtCtrls, Dialogs,
  Controls, Classes, DateUtils,
{$IFDEF UNIX}
  cwstring, process, unix, lclintf,
{$ENDIF}
{$IFNDEF FPC}
  JPEG,
{$ENDIF}
  Graphics,
  uLZW, uSystemUtils, uDCLDBStructure, uDCLMultiLang,
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

function GetIniToRole(UserID: String): String;

function ConvertToJPEG(BitMap:TBitmap; Quality:Byte=JPEGCompressionQuality):TJpegImage;

function ConvertBinToXBase(Data:TMemoryStream; Base:Byte):TMemoryStream;
function ConvertXBaseToBin(Data:TMemoryStream; Base:Byte):TMemoryStream;
function SaveFormatedBlock(Data:TMemoryStream; Width:Word):TMemoryStream;
function LoadFormatedBlock(Data:TMemoryStream):TMemoryStream;

function DecodeScriptData(Data:TMemoryStream):TStringList;
function EncodeScriptData(Script:TStringList):TMemoryStream;

function GetScriptVersion(Data:TMemoryStream):String;

function IsDigits(Value: String): Boolean;

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
  L: Integer;
  itabsize: byte;
Begin
  L:=Length(S);
  While L<>0 Do
  Begin
    If S[L]=#10 Then
      S[L]:=' ';
    If S[L]=#9 Then
    Begin
      For itabsize:=1 To TabSize Do
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
  { Case Level Of
    0:
    Result:=ulDeny;
    1:
    Result:=ulReadOnly;
    2:
    Result:=ulWrite;
    3:
    Result:=ulExecute;
    4:
    Result:=ulLevel1;
    5:
    Result:=ulLevel2;
    6:
    Result:=ulLevel3;
    7:
    Result:=ulLevel4;
    8:
    Result:=ulDeveloper;
    Else
    $IFDEF DEVELOPERMODE
    Result:=ulDeveloper;
    $ELSE
    Result:=ulExecute;
    $ENDIF
    End; }
End;

Function TranslateDigitToUserLevel(Level: String): TUserLevelsType; overload;
Begin
  If CompareString(Level, 'ulDeny') Then
    Result:=ulDeny
  Else If CompareString(Level, 'ulReadOnly') Then
    Result:=ulReadOnly
  Else If CompareString(Level, 'ulWrite') Then
    Result:=ulWrite
  Else If CompareString(Level, 'ulExecute') Then
    Result:=ulExecute
  Else If CompareString(Level, 'ulLevel1') Then
    Result:=ulLevel1
  Else If CompareString(Level, 'ulLevel2') Then
    Result:=ulLevel2
  Else If CompareString(Level, 'ulLevel3') Then
    Result:=ulLevel3
  Else If CompareString(Level, 'ulLevel4') Then
    Result:=ulLevel4
  Else If CompareString(Level, 'ulDeveloper') Then
    Result:=ulDeveloper
  Else
{$IFDEF DEVELOPERMODE}
    Result:=ulDeveloper;
{$ELSE}
    Result:=ulExecute;
{$ENDIF}
End;

Function GetStringDataType(const S: String): TIsDigitType;
Var
  iI: Word;
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
      If (PosEx('ul', S)=1) and (PosSet(UserLevelsSet, S)<>0) and (Length(S)>5)
      then
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
  UserProfileDir:=GetUserDocumentsDir;
  if not DirectoryExists(UserProfileDir) then
    ForceDirectories(UserProfileDir);

  AppConfigDir:=UserProfileDir+PathDelim+DCLDir;
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

function GetIniToRole(UserID: String): String;
Begin
  Result:='';
  If GPT.DCLUserName<>'' Then
    Result:=IniUserFieldName+'='+UserID+' and ';
End;

function ConvertToJPEG(BitMap:TBitmap; Quality:Byte=JPEGCompressionQuality):TJpegImage;
begin
  if Quality=0 then
    Quality:=JPEGCompressionQuality;
  Result:=TJpegImage.Create;
{$IFNDEF FPC}
  Result.ProgressiveEncoding:=True;
{$ENDIF}
  try
    Result.CompressionQuality:=Quality;
    Result.Assign(BitMap);
  finally
    ///
  end;
end;

function ConvertBinToXBase(Data:TMemoryStream; Base:Byte):TMemoryStream;
var
  BaseStep:Byte;
  BasseSet:Array[0..64] of Byte;
  Buffer:Int64;
  i:Integer;
  S:String;
begin
  Result:=TMemoryStream.Create;
  If Data.Size>0 then
  Begin
    For i:=0 to 9 do
      BasseSet[i]:=Ord('0')+i;
    For i:=10 to Base do
      BasseSet[i]:=Ord('A')+i-10;

    BaseStep:=1;//(Base div 8)+((8+(Base mod 8)-1) div 8);
    Data.Position:=0;

    While Data.Position<Data.Size do
    Begin
      Buffer:=0;
      Data.Read(Buffer, BaseStep);
      S:=IntToHex(Buffer, 2);
      For i:=1 to Length(S) do
        Result.WriteBuffer(S[i], 1);
		End;
	End;
end;

function ConvertXBaseToBin(Data:TMemoryStream; Base:Byte):TMemoryStream;
var
  BasseSet:Array[0..64] of Byte;
  SingleDig, b:Byte;
  S:string;
  i:Integer;
Begin
  Result:=TMemoryStream.Create;
  If Data.Size>0 then
  Begin
    For i:=0 to 9 do
      BasseSet[i]:=Ord('0')+i;
    For i:=10 to Base do
      BasseSet[i]:=Ord('A')+i-10;

    Data.Position:=0;
    While Data.Position<Data.Size-1 do
    Begin
      S:='';
      For i:=1 to ((Base div 8)+((8+(Base mod 8)-1) div 8)) do
      Begin
        Data.Read(SingleDig, 1);
        S:=S+Chr(SingleDig);
  		End;
      b:=HexToInt(S);
      Result.Write(b, 1);
  	End;
	End;
End;

function SaveFormatedBlock(Data:TMemoryStream; Width:Word):TMemoryStream;
var
  Buffer:array of Byte;
  i:Integer;
  S:String;
Begin
  S:=CR;
  Result:=TMemoryStream.Create;
  If Data.Size>0 then
  Begin
    Data.Position:=0;
    While Data.Position<Data.Size-1 do
    Begin
      If Data.Size-Data.Position>=Width then
        SetLength(Buffer, Width+Length(CR))
      Else
        SetLength(Buffer, Data.Size-Data.Position+Length(CR));

      Data.Read(Buffer[0], Width);
      For i:=1 to Length(S) do
        Buffer[Length(Buffer)-Length(S)+i-1]:=Ord(S[i]);
      Result.WriteBuffer(Buffer[0], Length(Buffer));
    End;
  End;
End;

function LoadFormatedBlock(Data:TMemoryStream):TMemoryStream;
var
  Buffer:array of Byte;
  i, p, l:Integer;
Begin
  Result:=TMemoryStream.Create;
  SetLength(Buffer, 100);
  If Data.Size>0 then
  Begin
    Data.Position:=0;
    While Data.Position<Data.Size-1 do
    Begin
      l:=Data.Read(Buffer[0], 100);
      p:=0;
      For i:=1 to l do
      Begin
        If Chr(Buffer[i-1]) in ['A'..'Z', '0'..'9'] then
        Begin
          Buffer[p]:=Buffer[i-1];
          Inc(p);
        End;
      End;

      Result.WriteBuffer(Buffer[0], p);
    End;
  End;
End;

function GetScriptVersion(Data:TMemoryStream):String;
var
  tmp:TStringList;
Begin
  Result:='';
  If Data.Size>0 then
  Begin
    Data.Position:=0;
    tmp:=TStringList.Create;
    tmp.LoadFromStream(Data);
    If (Pos('[', tmp[0])<Pos(']', tmp[0])) and (Pos('[', tmp[0])>0) then
      If tmp[0]='['+SignMethodVer+']' then
      Begin
        Result:=GetClearParam(tmp[0], '[]');
      End;
    FreeAndNil(tmp);
  End;
End;

function DecodeScriptData(Data:TMemoryStream):TStringList;
var
  tmpMem, tmpArc: TMemoryStream;
  tmp:TStringList;
Begin
  Result:=TStringList.Create;
  If Data.Size>0 then
  Begin
    Data.Position:=0;
    tmp:=TStringList.Create;
    tmp.LoadFromStream(Data);
    If (Pos('[', tmp[0])<Pos(']', tmp[0])) and (Pos('[', tmp[0])>0) then
      If tmp[0]='['+SignMethodVer+']' then
      Begin
        tmp.Delete(0);
        Data.Clear;
        tmp.SaveToStream(Data);
        Data.Position:=0;
        tmpArc:=ConvertXBaseToBin(LoadFormatedBlock(Data), 16);
        tmpArc.Position:=0;
        tmpMem:=TMemoryStream.Create;
        DecompressProc(tmpArc, tmpMem);
        tmpMem.Position:=0;
        Result.LoadFromStream(tmpMem);
        FreeAndNil(tmpMem);
        FreeAndNil(tmpArc);
      End;
    FreeAndNil(tmp);
  End;
End;

function EncodeScriptData(Script:TStringList):TMemoryStream;
var
  tmpMem, tmpArc: TMemoryStream;
  i:Byte;
  Buffer:Array of Byte;
  S:string;
Begin
  Result:=TMemoryStream.Create;
  S:='['+SignMethodVer+']'+CR;
  SetLength(Buffer, Length(S));
  For i:=1 to Length(S) do
    Buffer[i-1]:=Ord(S[i]);
  Result.Write(Buffer[0], Length(Buffer));

  tmpArc:=TMemoryStream.Create;
  tmpMem:=TMemoryStream.Create;
  Script.SaveToStream(tmpMem);
  tmpMem.Position:=0;
  CompressProc(tmpMem, tmpArc);
  tmpArc.Position:=0;
  Result.CopyFrom(SaveFormatedBlock(ConvertBinToXBase(tmpArc, 16), ScrDataBlockWidth), 0);
  Result.Position:=0;
  FreeAndNil(tmpArc);
  FreeAndNil(tmpMem);
End;

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

end.
