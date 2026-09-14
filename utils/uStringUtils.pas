unit uStringUtils;
{$mode Delphi}

interface

uses
  Classes, SysUtils;

Function PosEx(const SubStr, S: String): Integer;
Procedure DeleteNonPrintSimb(Var S: String);
Function CopyStrings(const FromString, ToString: String; Where: TStringList): TStringList;
Function ExtractSection(Var SectionStr: String): String;
Function CopyCut(Var S: String; From, Count: Integer): String;
function OnlyDigits(const Value: String): Boolean;
function OnlyLitters(const S: String): String;
function NormalizeCase(const S: String): String;
Function DCLStringEquals(const S1, S2: String): Boolean;
Function TrimSymbols(const S: String; TrimS: String): String;
Function InitCap(const S: String): String;
function Any(const StrSet, S: String): Boolean;
function TrimChars(const CharsSet, S: String): String;
function DCLCompareStrings(const S1, S2: String): Integer;

implementation

const
  TabSize=2;

Function DCLStringEquals(const S1, S2: String): Boolean;
Begin
  Result:=LowerCase(S1)=LowerCase(S2);
End;

Function PosEx(const SubStr, S: String): Integer;
begin
  Result:=Pos(LowerCase(SubStr), LowerCase(S));
end;

function Any(const StrSet, S: String): Boolean;
var
  c: Char;
begin
  Result:=False;
  if Length(StrSet)>0 then
  begin
    for c in StrSet do
    begin
      if PosEx(c, S)<>0 then
      begin
        Result:=True;
        break;
      end;
    end;
  end;
end;

function TrimChars(const CharsSet, S: String): String;
var
  i:Integer;
begin
  Result:='';
  For i:=1 to Length(S) do
  Begin
    If PosEx(S[i], CharsSet)=0 then
      Result:=Result+S[i];
  End;
end;

Function InitCap(const S: String): String;
begin
  if S<>'' then
    Result:=UpperCase(S[1])+Copy(S, 2, Length(S)-1)
  Else
    Result:='';
end;

function NormalizeCase(const S: String): String;
var
  tmp: String;
  l, i: Integer;
  nextUpper: Boolean;
begin
  Result:='';
  if Length(S)>0 then
  begin
    l:=Length(S);
    tmp:=UpperCase(S[1]);
    if l>1 then
    begin
      nextUpper:=False;
      for i:=2 to l do
      begin
        if S[i]='_' then
        begin
          nextUpper:=True;
          tmp:=tmp+' ';
        end
        else
        begin
          if nextUpper then
            tmp:=tmp+UpperCase(S[i])
          else
            tmp:=tmp+LowerCase(S[i]);

          nextUpper:=False;
        end;
      end;
    end;
    Result:=tmp;
  end;
end;

Function TrimSymbols(const S: String; TrimS: String): String;
var
  i: Cardinal;
begin
  Result:=S;
  for i:=Length(Result) downto 1 do
    if Pos(Result[i], TrimS)<>0 then
      Delete(Result, i, 1);
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

Function TextToString(Text: String): String;
Var
  L: Integer;
  itabsize: byte;
Begin
  Result:='';
  L:=Length(Text);
  While L<>0 Do
  Begin
    If Text[L]=#10 Then
      Text[L]:=' ';
    If Text[L]=#9 Then
    Begin
      For itabsize:=1 To TabSize Do
        Insert(' ', Text, L);
    End;
    If (Text[L]=#13)Or(Text[L]=#0) Then
      Delete(Text, L, 1);
    Dec(L);
  End;

  Result:=Text;
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

function FindSubstrInString(AText: String; AValues: Array of String):Integer;
var
  i, MaxLong:Integer;
Begin
  Result:=-1;
  MaxLong:=0;
  For I := Low(AValues) to High(AValues) do
    If Pos(AValues[I].ToLower, AText.ToLower)<>0 then
    begin
      If MaxLong<Length(AValues[I]) then
      Begin
        MaxLong:=Length(AValues[I]);
        Result:=i;
      End;
    end;
End;

Function InString(Const Sub, S: String; FullMatch: Boolean): Integer;
Var
  i: Integer;
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

Function CopyCut(Var S: String; From, Count: Integer): String;
Begin
  Result:=Copy(S, From, Count);
  Delete(S, From, Count);
End;

function PosInSet(const SimbolsSet, SourceStr: String): Integer;
Var
  i: Integer;
begin
  Result:=0;
  For i:=1 to Length(SourceStr) do
  Begin
    If Pos(LowerCase(SourceStr[i]), SimbolsSet.ToLower)<>0 then
    Begin
      Result:=i;
      Break;
    End;
  End;
end;

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

Function CopyStrings(const FromString, ToString: String; Where: TStringList): TStringList;
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

function OnlyDigits(const Value: String): Boolean;
var
  i: Integer;
begin
  Result:=False;

  if Length(Value)>0 then
  begin
  for I:=1 to Length(Value) do
    if not (Value[i] in ['0'..'9']) then
    begin
      exit;
    end;
  end;
  Result:=True;
end;

function OnlyLitters(const S: String): String;
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

function DCLCompareStrings(const S1, S2: String): Integer;
var
  l1, l2, i1, i2: Integer;
  c1, c2: Char;
  isSame: Boolean;
begin
  isSame:=False;
  l1:=Length(S1);
  l2:=Length(S2);
  if (l1=0) and (l2=0) then Exit(0);
  if l1<l2 then
    Exit(1)
  else
  begin
    if l2<l1 then
      Exit(-1)
    else
    begin
      for i1:=1 to l1 do
      begin
        c1:=S1[i1];
        c2:=S2[i1];

        if c1=c2 then
        begin
          isSame:=True;
          Continue;
        end;
        if c1<c2 then
        begin
          Exit(1);
        end
        else
        begin
          Exit(-1);
        end;
      end;
    end;
  end;

  if isSame then
  begin
    Exit(0);
  end;
end;

end.
