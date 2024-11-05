unit uSQLParser;
{$mode Delphi}

interface

uses
  Classes, SysUtils,
  uDCLDBAwareTypes, uDCLData;

type
  TOrderTypes=(otAsc, otDesck);

  { TSQLParser }

  TSQLParser=class
  private
    FSQL: String;
  public
    function GetFindGridCondition(Query: TDCLDialogQuery; GridExemple, FindFieldName: String): String;
    function GetFilterCondition(Query: TDCLDialogQuery; Filter, LastFilter: TDBFilter): String;
    function ConcatSQLWhere(Where1, Where2: String): String;
    function ExcludeOrderBy(var SQL: String): String;
    function ExcludeGroupBy(var SQL: String): String;
    function ConcatWhereToSQL(SQL, Where: String): String;
    function ReplaseSQLFields(SQL, NewFieldsSet: String): String;

    property SQL: String read FSQL;
  end;

implementation

uses
  uDBUtils, uSQLUtils, uDCLConst, uStringParams;

{ TSQLParser }

function TSQLParser.GetFindGridCondition(Query: TDCLDialogQuery; GridExemple,
  FindFieldName: String): String;
var
  Sign, NotCond, Delim, Exemple, Exemple1, Exemple2, Upper, UpperEnd: String;
  OperationType: TConditionTypes;
  FT: TSimplyFieldType;
  IsNot: Boolean;
  i: INteger;
begin
  Result:='';
  if GridExemple='' then Exit;
  Exemple:=Trim(GridExemple);

  FT:=GetSimplyFieldType(FindFieldName, Query);
  Delim:=GetDelimiter(FindFieldName, Query);

  NotCond:='';
  Sign:='=';
  OperationType:=ctEq;
  IsNot:=False;
  if Pos('!', Exemple)=1 then
  begin
    OperationType:=ctNotEq;
    IsNot:=True;
    Delete(Exemple, 1, 1);
    Exemple:=Trim(Exemple);
  end;

  Upper:='';
  UpperEnd:='';
  if FT=sftString then
  begin
    Sign:=' like ';
    Upper:='upper(';
    UpperEnd:=')';
  end;

  If Pos('(', Exemple)=1 Then
    If Pos(')', Exemple)=Length(Exemple) Then
    begin
      if IsNot then
      begin
        NotCond:=' not ';
        OperationType:=ctNotIn;
      end
      else
        OperationType:=ctIn;

      Delete(Exemple, 1, 1);
      Delete(Exemple, Length(Exemple), 1);

      Exemple1:='';
      for i:=1 to ParamsCount(Exemple) do
      begin
        Exemple1:=Exemple1+Delim+GetParam(Exemple, i)+Delim+', ';
      end;
      if Length(Exemple1)>1 then
        Delete(Exemple1, Length(Exemple1)-1, 2);

      Exemple:='('+Exemple1+')';
    end;

  If Pos('[', Exemple)=1 Then
    If Pos(']', Exemple)=Length(Exemple) Then
    begin
      Sign:=' between ';
      if IsNot then
      begin
        NotCond:=' not ';
        OperationType:=ctNotBt;
      end
      else
        OperationType:=ctBt;

      Delete(Exemple, 1, 1);
      Delete(Exemple, Length(Exemple), 1);

      Exemple1:=GetParam(Exemple, 1);
      Exemple2:=GetParam(Exemple, 2);

      Exemple:=Exemple1+' and '+Exemple2;
    end;

  If Pos('<=', Exemple)=1 Then
  begin
    Sign:=Copy(Exemple, 1, 2);
    Delete(Exemple, 1, 2);
    OperationType:=ctLeEq;
    NotCond:='';
  end
  Else If (Pos('<', Exemple)=1) and (Pos('>', Exemple)=0) Then
  begin
    Sign:=Copy(Exemple, 1, 1);
    Delete(Exemple, 1, 1);
    OperationType:=ctLe;
    NotCond:='';
  end;

  If Pos('>=', Exemple)=1 Then
  begin
    Sign:=Copy(Exemple, 1, 2);
    Delete(Exemple, 1, 2);
    OperationType:=ctGtEq;
    NotCond:='';
  end
  Else If (Pos('>', Exemple)=1) and (Pos('<', Exemple)=0) Then
  begin
    Sign:=Copy(Exemple, 1, 1);
    Delete(Exemple, 1, 1);
    OperationType:=ctGt;
    NotCond:='';
  end;

  if OperationType=ctNotEq then
  begin
    if FT=sftString then
    begin
      NotCond:=' not ';
    end
    else
    begin
      NotCond:='!';
    end;
  end;

  case OperationType of
    ctEq: begin
      Result:=Upper+FindFieldName+UpperEnd+Sign+Upper+Delim+Exemple+Delim+UpperEnd;
    end;
    ctNotEq: begin
      Result:=Upper+FindFieldName+UpperEnd+NotCond+Sign+Upper+Delim+Exemple+Delim+UpperEnd;
    end;
    ctLeEq, ctLe, ctGtEq, ctGt: begin
      Result:=FindFieldName+Sign+Delim+Exemple+Delim;
    end;
    ctIn, ctNotIn: begin
      Result:=FindFieldName+NotCond+' in '+Exemple;
    end;
    ctBt, ctNotBt: begin
      Result:=FindFieldName+NotCond+Sign+Exemple;
    end;
  end;
end;

function TSQLParser.GetFilterCondition(Query: TDCLDialogQuery; Filter, LastFilter: TDBFilter
  ): String;
var
  Delim, Operation, isNot, upperFunc1, upperFunc2, Prefix, Suffix: String;
begin
  Result:='';
  if (Filter.FilterString<>'') and (Filter.Field<>'') then
  begin
    Delim:=GetDelimiter(Filter.Field, Query);
    case Filter.FilterType of
      ftDBFilter, ftComboFilter: begin
        if Filter.FilterString<>IntToStr(FilterResetValue) then
        begin
          if Assigned(LastFilter) and LastFilter.Between then
          begin
            isNot:='';
            if Filter.NotFilter then
              isNot:=' not';
            Result:=Filter.Field+isNot+' between '+Delim+LastFilter.FilterString+Delim+' and '+Delim+Filter.FilterString+Delim;
          end
          else
          begin
            isNot:='';
            if Filter.NotFilter then
              isNot:='!';
            Result:=Filter.Field+isNot+'='+Delim+Filter.FilterString+Delim;
          end;
        end;
      end;
      ftContextFilter, ftTempFilter: begin
        isNot:='';
        if Filter.NotFilter then
          isNot:='!';
        Operation:='=';
        Case GetSimplyFieldType(Filter.Field, Query) of
          sftString: begin
            Suffix:='';
            if Filter.NotLike then
            begin
              if Filter.NotFilter then
                isNot:='!';
              Operation:='='
            end
            else
            begin
              if Filter.NotFilter then
                isNot:='not ';
              Operation:=' like ';
              Suffix:='%';
            end;

            Prefix:='';
            if Filter.Contains then
            begin
              Prefix:='%';
            end;

            upperFunc1:='upper(';
            upperFunc2:=')';
            if Filter.CaseC then
            begin
              upperFunc1:='';
              upperFunc2:='';
            end;
          end;
        end;

        Result:=upperFunc1+Filter.Field+upperFunc2+isNot+Operation+upperFunc1+Delim+Prefix+Filter.FilterString+Suffix+Delim+upperFunc2;
      end;
    end;
  end;
end;

function TSQLParser.ConcatSQLWhere(Where1, Where2: String): String;
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

function TSQLParser.ExcludeOrderBy(var SQL: String): String;
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

function TSQLParser.ExcludeGroupBy(var SQL: String): String;
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

function TSQLParser.ConcatWhereToSQL(SQL, Where: String): String;
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

function TSQLParser.ReplaseSQLFields(SQL, NewFieldsSet: String): String;
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

    Result:='select ' + NewFieldsSet + ' from ' +Copy(SQL, f+1, Length(SQL));
  end;
end;

end.

