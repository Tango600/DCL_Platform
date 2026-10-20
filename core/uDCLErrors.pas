unit uDCLErrors;
{$mode Delphi}{$H+}

interface

uses
  Classes, SysUtils;

 function GetDCLErrorString(ErrorCode: Integer; const AddText: String=''): String;

implementation

uses
  uDCLMultiLang;

function GetDCLErrorString(ErrorCode: Integer; const AddText: String=''): String;
Var
  MessageText: String;
Begin
  MessageText:='';
  Case ErrorCode Of
  -2, -3:
  MessageText:=GetDCLMessageString(msConnectionError);
  -1100, -1101, -1119, -1102, -1106, -1107, -1112, -1200, -1201, -1113, -1114, -1115, -1116, -1118:
  MessageText:=GetDCLMessageString(msErrorQuery)+' '+IntToStr(ErrorCode);
  -1111:
  MessageText:=GetDCLMessageString(msBadFindParams)+' '+IntToStr(ErrorCode);
  -1103, -1104, -1105, -1108, -1110, -1117:
  MessageText:=GetDCLMessageString(msErrorInExpression)+' '+IntToStr(ErrorCode);
  -1109:
  MessageText:=GetDCLMessageString(msErrorQueryInExpression)+' '+IntToStr(ErrorCode);
  -4000:
  MessageText:=GetDCLMessageString(msTooMachParams)+' '+IntToStr(ErrorCode);
  -4002:
  MessageText:=GetDCLMessageString(msBadFieldFormad)+' '+IntToStr(ErrorCode);
  -5002:
  MessageText:=GetDCLMessageString(msNoDATARegion)+' '+IntToStr(ErrorCode);
  -5003:
  MessageText:=GetDCLMessageString(msNoTemplatesTable)+' '+IntToStr(ErrorCode);
  -5004:
  MessageText:=GetDCLMessageString(msTemplateNotFound)+' '+IntToStr(ErrorCode);
  -5005:
  MessageText:=GetDCLMessageString(msLabelNotFound)+' '+IntToStr(ErrorCode);
  -5006, -5007:
  MessageText:=GetDCLMessageString(msTemplFileNotFound)+' '+IntToStr(ErrorCode);
  -5008:
  MessageText:=GetDCLMessageString(msTableUsersNotFound)+' '+IntToStr(ErrorCode);
  -6001, -6002: // OOo
  MessageText:=GetDCLMessageString(msOONotInstalled)+' '+IntToStr(ErrorCode);
  -6003:
  MessageText:=GetDCLMessageString(msFailOpenDocument)+' '+IntToStr(ErrorCode);
  -6000, -6010:
  MessageText:=GetDCLMessageString(msMSNotInstalled)+' '+IntToStr(ErrorCode);
  -6011:
  MessageText:=GetDCLMessageString(msWord2000Req)+' '+IntToStr(ErrorCode);
  -6020:
  MessageText:=GetDCLMessageString(msNoOfficeInstalled)+' '+IntToStr(ErrorCode);
  -7000:
  MessageText:=GetDCLMessageString(msConvertionError)+' '+IntToStr(ErrorCode);
  -8000:
  MessageText:=GetDCLMessageString(msAppRunError)+' '+IntToStr(ErrorCode);
  -8001:
  MessageText:=GetDCLMessageString(msFileNotFound)+' '+IntToStr(ErrorCode);
  -9000:
  MessageText:=GetDCLMessageString(msErrorInRaightExpression)+' '+IntToStr(ErrorCode);
  -10000, -10001, -10002:
  MessageText:=GetDCLMessageString(msFieldNotFound)+' '+IntToStr(ErrorCode);
  -11000:
  MessageText:=GetDCLMessageString(msFildsNotInputValue)+' '+IntToStr(ErrorCode);
  End;

  if MessageText<>'' then
    Result:=MessageText+LineEnding;

  Result:=Result+AddText;
End;

end.
