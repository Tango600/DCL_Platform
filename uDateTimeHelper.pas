unit uDateTimeHelper;
{$I DefineType.pas}

interface

uses
  Classes, SysUtils;

  Function DateToStr_(Date: TDate): String;
  Function TimeToStr_(Time: TDateTime): String;
  Function TimeStampToStr(NowDate: TDateTime): String;

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

end.

