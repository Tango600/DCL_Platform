unit uStringUtils;
{$mode Delphi}

interface

uses
  Classes, SysUtils;

Function PosEx(const SubStr, S: String): Integer;
Procedure DeleteNonPrintSimb(Var S: String);
Function ExtractSection(Var SectionStr: String): String;
Function CopyStringsBlock(const FromString, ToString: String; Where: TStringList): TStringList;
Function CopyCut(Var S: String; From, Count: Integer): String;
function FilterOnlyLitters(const S: String): String;
function NormalizeCase(const S: String): String;
Function DCLStringEquals(const S1, S2: String): Boolean;
Function TrimSymbols(const S: String; TrimS: String): String;
Function InitCap(const S: String): String;
function TrimChars(const CharsSet, S: String): String;
function DCLCompareStrings(const S1, S2: String): Integer;

implementation

const
  TabSize=2;

Function DCLStringEquals(const S1, S2: String): Boolean;
Begin
  Result:=DCLCompareStrings(S1, S2)=0;
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
    If (S[L]=#9) or (S[L]=#10) Then
      S[L]:=' ';
    If S[L]=#9 Then
    Begin
      For i:=1 To TabSize-1 Do
        Insert(' ', S, L);
    End;
    If (S[L]=#13)Or(S[L]=#0) Then
      Delete(S, L, 1);
    Dec(L);
  End;
End;

Function CopyCut(Var S: String; From, Count: Integer): String;
Begin
  Result:=Copy(S, From, Count);
  Delete(S, From, Count);
End;

Function ExtractSection(Var SectionStr: String): String;
Var
  PosD: Integer;
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

Function CopyStringsBlock(const FromString, ToString: String; Where: TStringList): TStringList;
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

function FilterOnlyLitters(const S: String): String;
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
  l1, l2, i1: Integer;
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
        end
        else
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
