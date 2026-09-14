unit uDCLUtils;
{$mode Delphi}

interface

uses
  SysUtils, Classes, DateUtils,
  uDCLConst, uStringUtils, uDetectDataType, uStringParams;

Function ConvertOfficeType(const OfficeType: String): TOfficeFormat;

Function TranslateDigitToUserLevel(Level: byte): TUserLevelsType;
Function TranslateStrToUserLevel(Level: String): TUserLevelsType;
Function IsUserLevel(const S: String): Boolean;

function CheckStrFmtType(const S: String; SimplyFormatType: TSimplyFieldType): Boolean;

function GetGraficFileType(const FileName: String): TGraficFileType;
function GetExtByType(FileType: TGraficFileType): String;

implementation

function CheckStrFmtType(const S: String; SimplyFormatType: TSimplyFieldType): Boolean;
Begin
  Case SimplyFormatType of
  sftNotDefine, sftString:Result:=True;
  sftDigit:Result:=IsDigit(S);
  sftFloat:Result:=IsFloat(S);
  sftDateTime:Result:=IsTime(S) or IsDate(S) or IsDateTime(S);
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

Function TranslateDigitToUserLevel(Level: Byte): TUserLevelsType;
Begin
  Result:=TUserLevelsType(Level);
End;

Function TranslateStrToUserLevel(Level: String): TUserLevelsType;
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

function IsUserLevel(const S: String): Boolean;
begin
  Result:=TranslateStrToUserLevel(S)<>ulUndefined;
end;

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
