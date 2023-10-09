unit uDBUtils;
{$I DefineType.pas}

interface

uses
  Classes, SysUtils, DB,
  uDCLTypes, uDCLData, uDCLConst, uDCLDBConnector, uDCLField, uDCLMeasurements;

  function TableExist(DBConnector: TDBConnector; TableName: String): Boolean;
  function FieldExist(DBConnector: TDCLDBConnector; TableName, FieldName: String): Boolean; overload;
  function FieldExist(Query: TDCLDialogQuery; FieldName: String): Boolean; overload;
  Function NormalizeFieldName(Const FieldName: String): String;
  Function GetDelimiter(Const FieldName: String; Query: TDCLDialogQuery): String;
  Function GetSimplyFieldType(Const FieldName: String; Query: TDCLDialogQuery): TSimplyFieldType; overload;
  Function GetSimplyFieldType(Const FieldType:TFieldType): TSimplyFieldType; overload;

  Function FieldExists(Const FieldName: String; Query: TDCLDialogQuery): Boolean;

  Function QueryIsEmpty(Query: TDCLDialogQuery): Boolean;
  function GetFieldFromParam(Param: String; Query: TDCLDialogQuery): TField;

  procedure FieldWidth(Field: TDCLField; FieldType: TFieldType);

implementation

uses
  uDCLGlobalVariables;

Function GetSimplyFieldType(Const FieldName: String; Query: TDCLDialogQuery): TSimplyFieldType;
var
  tmpFieldName:string;
Begin
  tmpFieldName:=NormalizeFieldName(FieldName);
  If Query.FieldByName(tmpFieldName).DataType in TStringTypedFields then
    Result:=sftString
  Else
    If Query.FieldByName(tmpFieldName).DataType in TIntegerTypedFields then
      Result:=sftDigit
    Else
      If Query.FieldByName(tmpFieldName).DataType in TFloatTypedFields then
        Result:=sftFloat
      Else
        If Query.FieldByName(tmpFieldName).DataType in TDateTimeTypedFields then
          Result:=sftDateTime
        Else
          Result:=sftString;
End;

Function GetSimplyFieldType(Const FieldType:TFieldType): TSimplyFieldType; overload;
Begin
  If FieldType in TStringTypedFields then
    Result:=sftString
  Else
    If FieldType in TIntegerTypedFields then
      Result:=sftDigit
    Else
      If FieldType in TFloatTypedFields then
        Result:=sftFloat
      Else
        If FieldType in TDateTimeTypedFields then
          Result:=sftDateTime
        Else
          Result:=sftString;
End;

Function NormalizeFieldName(Const FieldName: String): String;
Begin
  Result:=FieldName;
  If Pos('.', FieldName)<>0 then
  begin
    Result:=Copy(FieldName, Pos('.', FieldName)+1, Length(FieldName));
  end;
end;

Function GetDelimiter(Const FieldName: String; Query: TDCLDialogQuery): String;
var
  tmpFieldName:string;
Begin
  Result:='';
  if FieldName<>'' then
  begin
    tmpFieldName:=NormalizeFieldName(FieldName);
    if Query.Active then
    begin
      Case Query.FieldByName(tmpFieldName).DataType Of
      ftString, ftBCD, ftFloat, ftCurrency:
      Begin
        Result:=GPT.StringTypeChar
      End;
      ftSmallint, ftInteger, ftWord, ftBoolean, ftAutoInc, ftLargeint, ftBytes, ftVarBytes:
      Begin
        Result:='';
      End
      Else
        Result:=GPT.StringTypeChar;
    End;
    end
    Else
      Result:=GPT.StringTypeChar;
  end;
End;

function TableExist(DBConnector: TDBConnector; TableName: String): Boolean;
var
  Tables: TStrings;
  t: String;
begin
  Result:=False;
  Tables:=TStringList.Create;
  {$IFDEF ZEOS}
  DBConnector.GetTableNames('', Tables);
  {$ELSE}
  DBConnector.GetTableNames(Tables);
  {$ENDIF}
  for t in Tables do
  begin
    If UpperCase(t)=UpperCase(TableName) then
    Begin
      Result:=True;
      Break;
    End;
  end;
end;

function FieldExist(DBConnector: TDCLDBConnector; TableName, FieldName: String): Boolean;
var
  Q: TDCLDialogQuery;
  Field: TField;
begin
  Result:=False;
  try
    Q:=TDCLDialogQuery.Create(DBConnector);
    DBConnector.SetConnector(Q);
    Q.SQL.Text:='select * from '+TableName+' where 1=0';
    Q.Open;
    for Field in Q.Fields do
    begin
      if Field.FieldName.ToLower.Contains(FieldName.ToLower) then
      begin
        Result:=True;
        break;
      end;
    end;
  finally
    Q.Close;
  end;
end;

function FieldExist(Query: TDCLDialogQuery; FieldName: String): Boolean;
var
  FieldNames: TStringList;
  Field: String;
begin
  Result:=False;
  FieldNames:=TStringList.Create;
  Query.GetFieldNames(FieldNames);
  if Assigned(FieldNames) then
  begin
    for Field in FieldNames do
    begin
      if Field.ToLower.Contains(FieldName.ToLower) then
      begin
        Result:=True;
        break;
      end;
    end;
  end;
  FreeAndNil(FieldNames);
end;

Function FieldExists(Const FieldName: String; Query: TDCLDialogQuery): Boolean;
Var
  v1FieldNum: Word;
  tmpFieldName: string;
Begin
  Result:=False;
  tmpFieldName:=NormalizeFieldName(FieldName);

  If Assigned(Query) then
  Begin
{$IFDEF DELPHI}
    If GPT.DebugOn Then
      Query.FieldList.SaveToFile(AppConfigDir+'Existing_Fields.txt');
{$ENDIF}
    If tmpFieldName<>'' then
      If Query.FieldCount<>0 Then
        For v1FieldNum:=0 To Query.FieldCount-1 Do
          If UpperCase(Trim(tmpFieldName))=UpperCase(Query.Fields[v1FieldNum].FieldName) Then
          Begin
            Result:=True;
            Break;
          End;
  End;
End;

Function QueryIsEmpty(Query: TDCLDialogQuery): Boolean;
Begin
  Result:=Query.Eof And Query.Bof;
End;

function GetFieldFromParam(Param: String; Query: TDCLDialogQuery): TField;
const
  StopSimbols='( ){}=/\<>|-%^!~[],.%:;&$`?#@*'#39#9;
var
  FieldName: String;
  L, i: Word;
Begin
  Result:=nil;
  If Pos(FieldObjectPrefix, Param)<>0 then
  begin
    FieldName:='';
    L:=Length(Param);
    i:=Pos(FieldObjectPrefix, Param)+Length(FieldObjectPrefix);
    while i<L do
    Begin
      If Pos(Param[i], StopSimbols)<>0 then
      Begin
        Break;
      End;
      FieldName:=FieldName+Param[i];
      Inc(i);
    End;
    If Query.Active then
    Begin
      If FieldExists(FieldName, Query) then
        Result:=Query.FieldByName(FieldName);
    End;
  end;
End;

procedure FieldWidth(Field: TDCLField; FieldType: TFieldType);
begin
  if Field.Width<=0 then
  begin
    case FieldType of
      //ftDateTime: Field.Width:=DateTimeBoxWidth;
      //ftDate, ftTime: Field.Width:=DateTimeBoxWidth;
      ftFloat, ftCurrency, ftSmallint, ftInteger, ftWord, ftAutoInc,
        ftLargeint, ftBCD: Field.Width:=DigitEditWidth;
      else
      begin
        Field.Width:=EditWidth;
      end;
    end;
  end;
end;

end.

