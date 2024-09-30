unit uDCLUtils;
{$mode Delphi}

interface

uses
  SysUtils, Classes, DateUtils,
  uDCLConst, uStringUtils, uStringParams;

Function ConvertOfficeType(const OfficeType: String): TOfficeFormat;

Function TranslateDigitToUserLevel(Level: byte): TUserLevelsType; overload;
Function TranslateDigitToUserLevel(Level: String): TUserLevelsType; overload;
Function GetStringDataType(const S: String): TIsDigitType;
function CheckStrFmtType(const S: String; SimplyFormatType: TSimplyFieldType): Boolean;

function GetGraficFileType(const FileName: String): TGraficFileType;
function GetExtByType(FileType: TGraficFileType): String;

implementation

uses
  SumProps;

function CheckStrFmtType(const S: String; SimplyFormatType: TSimplyFieldType): Boolean;
Begin
  Case SimplyFormatType of
  sftNotDefine, sftString:Result:=True;
  sftDigit:Result:=GetStringDataType(S)=idDigit;
  sftFloat:Result:=GetStringDataType(S)=idFloatDigit;
  sftDateTime:Result:=GetStringDataType(S)=idDateTime;
  End;
End;

Function ConvertOfficeType(const OfficeType: String): TOfficeFormat;
Begin
  If LowerCase(OfficeType)='oo' then
    Result:=ofOO
  Else If LowerCase(OfficeType)='mso' then
    Result:=ofMSO
  Else
    Result:=ofPossible;
End;

Function TranslateDigitToUserLevel(Level: Byte): TUserLevelsType; overload;
Begin
  Result:=TUserLevelsType(Level);
End;

Function TranslateDigitToUserLevel(Level: String): TUserLevelsType; overload;
const
  ulPrefix='ul';
Begin
  If DCLStringEquals(Level, ulPrefix+'Undefined') Then
    Result:=ulUndefined
  Else If DCLStringEquals(Level, ulPrefix+'Deny') Then
    Result:=ulDeny
  Else If DCLStringEquals(Level, ulPrefix+'ReadOnly') Then
    Result:=ulReadOnly
  Else If DCLStringEquals(Level, ulPrefix+'Write') Then
    Result:=ulWrite
  Else If DCLStringEquals(Level, ulPrefix+'Execute') Then
    Result:=ulExecute
  Else If DCLStringEquals(Level, ulPrefix+'Level1') Then
    Result:=ulLevel1
  Else If DCLStringEquals(Level, ulPrefix+'Level2') Then
    Result:=ulLevel2
  Else If DCLStringEquals(Level, ulPrefix+'Level3') Then
    Result:=ulLevel3
  Else If DCLStringEquals(Level, ulPrefix+'Level4') Then
    Result:=ulLevel4
  Else If DCLStringEquals(Level, ulPrefix+'Updater') Then
    Result:=ulUpdater
  Else If DCLStringEquals(Level, ulPrefix+'Signer') Then
    Result:=ulSigner
  Else If DCLStringEquals(Level, ulPrefix+'Developer') Then
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

function GetGraficFileType(const FileName: string): TGraficFileType;
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

function GetExtByType(FileType: TGraficFileType): String;
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

end.
