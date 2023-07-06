unit uDateTimeHelper;
{$mode Delphi}{$H+}

interface

uses
  Classes, SysUtils;

  Function DateToStr_(Date: TDate): String;
  Function TimeToStr_(Time: TDateTime): String;
  Function TimeStampToStr(NowDate: TDateTime): String;
  Function Date: TDateTime;
  Function Time: TDateTime;

implementation

uses
  uDCLData, uDCLGlobalVariables;

Function DateToStr_(Date: TDate): String;
Var
  tmpS: system.string;
Begin
  tmpS:='';
  DateTimeToString(tmpS, GPT.DateFormat, Date);
  Result:=tmpS;
End;

Function TimeToStr_(Time: TDateTime): String;
Var
  tmpS: system.string;
Begin
  tmpS:='';
  DateTimeToString(tmpS, GPT.TimeFormat, Time);
  Result:=tmpS;
End;

Function TimeStampToStr(NowDate: TDateTime): String;
Begin
  Result:=DateToStr_(NowDate)+' '+TimeToStr_(NowDate);
End;

{$IFDEF FPC}
Function Date: TDateTime;
Begin
  Result:=Now;
End;

Function Time: TDateTime;
Begin
  Result:=Now;
End;
{$ENDIF}

end.

