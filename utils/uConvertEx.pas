unit uConvertEx;
{$mode Delphi}

interface

uses
  Classes, SysUtils;

Function StrToIntEx(const S: String): LongInt;
Function StrToFloatEx(const S: String): Real;

implementation

Function StrToIntEx(const S: String): LongInt;
Var
  i, L: Integer;
  tmpS: String;
Begin
  L:=Length(S);
  tmpS:='';
  For i:=1 To L Do
  Begin
    If (S[i]>='0') and (S[i]<='9') or (S[i]='-') or (S[i]='e') Then
      tmpS:=tmpS+S[i];
  End;
  If tmpS='' Then
    tmpS:='0';
  Try
    Result:=StrToInt(tmpS);
  Except
    Result:=0;
  End;
End;

Function StrToFloatEx(const S: String): Real;
Var
  i, L: Integer;
  tmpS: String;
Begin
  L:=Length(S);
  tmpS:='';
  For i:=1 To L Do
  Begin
    If Pos(S[i], '.,')<>0 Then
      tmpS:=tmpS+FormatSettings.DecimalSeparator;
    If ((S[i]>='0') and (S[i]<='9')) or ((S[i]='-') or (S[i]=FormatSettings.DecimalSeparator) or (S[i]='e')) Then
      tmpS:=tmpS+S[i];
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

