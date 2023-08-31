unit uSQLUtils;
{$I DefineType.pas}

interface

uses
  Classes, SysUtils;


Function IsReturningQuery(SQQL: String): Boolean;
function TrimSQLComment(SQLText: String): String;
function FindSQLToken(SQL, FindToken:String):Integer;
Function ReplaceSQLFields(SQL, Fields: String): String;

implementation

uses
  uStringParams;

function TrimSQLComment(SQLText: String): String;
var
  p1, p2: Word;
begin
  p1:=Pos('/*', SQLText);
  p2:=Pos('*/', SQLText);
  If ((p1>0)and(p1<p2)) Then
    Delete(SQLText, p1, p2-p1);
  Result:=SQLText;
end;

Function IsReturningQuery(SQQL: String): Boolean;
Begin
  Result:=False;
  If PosEx('select', SQQL)<=5 then
    If PosEx('from', SQQL)>8 then
      Result:=True;

  If not Result then
  Begin
    If (PosEx('update', SQQL)<=5)and(PosEx('set', SQQL)>10) then
      Result:=False
    Else If (PosEx('delete', SQQL)<=5)and(PosEx('from', SQQL)>7) then
      Result:=False
    Else If (PosEx('insert', SQQL)<=5)and(PosEx('into', SQQL)>7) then
      Result:=False
    Else If (PosEx('execute', SQQL)<=5)and(PosEx('procedure', SQQL)>8) then
      Result:=False;
  End;
End;

function FindSQLToken(SQL, FindToken:String):Integer;
const
  Apostrof='''';
var
  i, skb, l: Integer;
  First, Last, str: Boolean;
  tmp1, DelimsSet, OpenerSet, CloseerSet: String;
begin
  Result:=0;
  DelimsSet:='/\|#!(* )[]'#39#10#13;
  OpenerSet:='(';
  CloseerSet:=')';
  First:=True;
  Last:=False;
  l:=Length(FindToken);
  i:=1;
  skb:=0;
  str:=True;
  while i<Length(SQL) do
  Begin
    Last:=i=Length(SQL);

    If Pos(SQL[i], OpenerSet)<>0 then
      Inc(skb)
    Else
      If Pos(SQL[i], CloseerSet)<>0 then
        Dec(skb);

    If SQL[i]=Apostrof then
    begin
      str:=not str;
    end;

    if str then
    begin
      If (Pos(SQL[i], DelimsSet)<>0) or First then
      Begin
        If i+Length(FindToken)<Length(SQL) then
        Begin
          If (Pos(SQL[i+l+1], DelimsSet)<>0) or Last then
          Begin
            tmp1:=LowerCase(Copy(SQL, i+1, l));
            If (skb=0) and str then
              If LowerCase(tmp1)=LowerCase(FindToken) then
              Begin
                Result:=i+1;
                Break;
              End;
          End;
        End;
      End;
    end;
    Inc(i);
    First:=False;
  End;
end;

Function ReplaceSQLFields(SQL, Fields: String): String;
var
  l, s, FromTokenPos:Integer;
  SQLNoFields:String;
begin
  Result:='';
  l:=Length(SQL);
  FromTokenPos:=FindSQLToken(SQL, 'from');
  s:=PosEx('select ', SQL);
  if (s>0) and (FromTokenPos>s) then
  begin
    SQLNoFields:=Copy(SQL, FromTokenPos, l-FromTokenPos+1);
    Result:='select ' + Fields + ' ' +SQLNoFields;
  end;
end;


end.

