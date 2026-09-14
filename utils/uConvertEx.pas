unit uConvertEx;
{$mode Delphi}

interface

uses
  Classes, SysUtils;

Function StrToIntEx(const St: String): LongInt;
Function StrToFloatEx(const St: String): Real;

implementation

Function StrToIntEx(const St: String): LongInt;
Var
  iI, L: Integer;
  tmpS: String;
Begin
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

Function StrToFloatEx(const St: String): Real;
Var
  iI, L: Integer;
  tmpS: String;
Begin
  L:=Length(St);
  tmpS:='';
  For iI:=1 To L Do
  Begin
    If Pos(St[iI], '.,')<>0 Then
      tmpS:=tmpS+FormatSettings.DecimalSeparator;
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

end.

