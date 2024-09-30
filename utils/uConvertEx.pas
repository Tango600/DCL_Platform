unit uConvertEx;
{$mode Delphi}

interface

uses
  Classes, SysUtils;

function IsHexValue(const HexStr: String): Boolean;

Function StrToIntEx(const St: String): LongInt;
Function StrToFloatEx(const St: String): Real;

implementation

function IsHexValue(const HexStr: String): Boolean;
var
  i: Integer;
  HexData: String;
begin
  Result:=False;
  HexData:='';
  If UpperCase(HexStr[Length(HexStr)])='H' Then
  begin
    Result:=True;
    HexData:=Copy(HexStr, 1, Length(HexStr)-1);
  end;
  If HexStr[Length(HexStr)]='$' Then
  begin
    Result:=True;
    HexData:=Copy(HexStr, 1, Length(HexStr)-1);
  end;
  If HexStr[1]='$' Then
  begin
    Result:=True;
    HexData:=Copy(HexStr, 2, Length(HexStr));
  end;

  if Result and (Length(HexData)>0) then
  begin
    For i:=1 To Length(HexData) Do
    Begin
      If Pos(UpperCase(HexData[i]), '0123456789ABCDEF')=0 then
      Begin
        Result:=False;
        Exit;
      End;
    End;
  end;
end;

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

