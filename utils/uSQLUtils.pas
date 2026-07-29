unit uSQLUtils;
{$mode Delphi}

interface

uses
  Classes, SysUtils;

Function IsReturningQuery(SQQL: String): Boolean;
function TrimSQLComment(SQLText: String): String;
function FindSQLToken(SQL, FindToken:String):Integer;
Function ReplaceSQLFields(SQL, Fields: String): String;
function ConcatSQLWhere(Where1, Where2: String): String;
function ExcludeOrderBy(var SQL: String): String;
function ExcludeGroupBy(var SQL: String): String;
function ConcatWhereToSQL(SQL, Where: String): String;
function ReplaseSQLFields(SQL, NewFieldsSet: String): String;

implementation

uses
  uStringUtils;

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
  If PosEx('select', SQQL)=1 then
    If PosEx('from', SQQL)>8 then
      Result:=True;

  If not Result then
  Begin
    If (PosEx('update', SQQL)=1)and(PosEx('set', SQQL)>10)and(PosEx('returning', SQQL)>17) then
      Result:=True
    Else If (PosEx('update', SQQL)=1)and(PosEx('set', SQQL)>10) then
      Result:=False
    Else If (PosEx('delete', SQQL)=1)and(PosEx('from', SQQL)>7) then
      Result:=False
    Else If (PosEx('insert', SQQL)=1)and(PosEx('into', SQQL)>7)and(PosEx('returning', SQQL)>17) then
      Result:=True
    Else If (PosEx('insert', SQQL)=1)and(PosEx('into', SQQL)>7) then
      Result:=False
    Else If (PosEx('execute', SQQL)=1)and(PosEx('procedure', SQQL)>8) then
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

function ConcatSQLWhere(Where1, Where2: String): String;
begin
  Result:='';
  if Trim(Where1)='' then
    Result:=Where2
  else if Trim(Where2)='' then
    Result:=Where1
  else if (Trim(Where1)<>'') and (Trim(Where2)<>'') then
  begin
    Result:=Where1+' and '+Where2;
  end;
end;

function ExcludeOrderBy(var SQL: String): String;
var
  pos: Integer;
begin
  pos:=FindSQLToken(SQL, 'order by');
  if pos<>0 then
  begin
    Result:=Copy(SQL, pos, Length(SQL)-pos+1);
    Delete(SQL, pos, Length(SQL)-pos+1);
  end
  else
    Result:='';
end;

function ExcludeGroupBy(var SQL: String): String;
var
  gbPos, obPos: Integer;
begin
  Result:='';
  gbPos:=FindSQLToken(SQL, 'group by');
  obPos:=FindSQLToken(SQL, 'order by');
  if obPos=0 then
    obPos:=Length(SQL);
  if gbPos<>0 then
  begin
    Result:=Copy(SQL, gbPos, obPos-gbPos+1);
    Delete(SQL, gbPos, obPos-gbPos+1);
  end
  else
    Result:='';
end;

function ConcatWhereToSQL(SQL, Where: String): String;
var
  WhereExists: Boolean;
begin
  Result:=SQL;
  if Trim(Where)<>'' then
  begin
    WhereExists:=FindSQLToken(SQL, 'where')<>0;
    If WhereExists Then
      Result:=SQL+' and '+Where
    else
      Result:=SQL+' where '+Where;
  end;
end;

function ReplaseSQLFields(SQL, NewFieldsSet: String): String;
var
  i, f, skb, t: Integer;
  OpenerSet, CloseerSet, FindToken: String;
begin
  Result:='';

  FindToken:=' from';
  i:=Pos('select ', LowerCase(SQL));
  if i>0 then
  begin
    OpenerSet:='(';
    CloseerSet:=')';
    i:=1;
    t:=1;
    skb:=0;
    while i<Length(SQL) do
    Begin
      If Pos(SQL[i], OpenerSet)<>0 then
        Inc(skb)
      Else
        If Pos(SQL[i], CloseerSet)<>0 then
          Dec(skb);

      if skb=0 then
      If SQL[i]=FindToken[t] then
      Begin
        If i+Length(FindToken)<Length(SQL) then
        Begin
          if t=Length(FindToken) then
          begin
            f:=i;
            Break;
          end;
        End;
        Inc(t);
      End
      Else
      Begin
        t:=1;
      End;
      Inc(i);
    End;

    Result:='select ' + NewFieldsSet + ' from ' +Trim(Copy(SQL, f+1, Length(SQL)));
  end;
end;

end.

