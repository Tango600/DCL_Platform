unit uDCLQuery;
{$I DefineType.pas}

interface

uses
  SysUtils, Classes, uStringParams,
  Dialogs, Generics.Collections,
{$IFDEF ADO}
  WideStrings, ADODB, ADOConst, ADOInt,
{$ENDIF}
{$IFDEF FPC}
  {$IFDEF IBX}
  IB, IBDatabase, IBCustomDataSet, IBQuery, uIBUpdateSQLW,
  {$ENDIF}
{$ELSE}
  {$IFDEF IBX}
  IBX.IBDatabase, IBX.IBTable, IBX.IBCustomDataSet, IBX.IBSQL, IBX.IBQuery,
  IBX.IBVisualConst, IBX.IBXConst, uIBUpdateSQLW,
  {$ENDIF}
{$ENDIF}
{$IFDEF SQLdbFamily}
  BufDataset, sqldb,
{$ENDIF}
{$IFDEF ZEOS}
  //ZConnection, ZDataset, ZSqlUpdate,
{$ENDIF}
  DB, uDCLDBAwareTypes, uDCLData, uDCLConst;

const
  FetchAllData=True;

type
  TUpdateKind=(ukAll, ukKeys);
  TOperationsTypes=Array of TNotAllowedOperation;

  { TDCLQuery }
  TDCLQuery=class(TDCLDialogQuery)
  private
    ShadowQuery: TDCLSimlyQuery;
    FUpdateSQL: TUpdateObj;
    {$IFDEF TRANSACTIONDB}
    ShadowTransaction: TTransaction;
    {$ENDIF}

    FMainTable, FKeyField: string;
    FAfterPost, FAfterCancel, FAfterOpen, FBeforePost, FBeforeInsert, FAfterDelete,
      FAfterInsert: TDataSetNotifyEvent;
    FNotAllowOperations: TOperationsTypes;
    FUpdateSQLDefined:Boolean;
    {$IFDEF ZEOS}
    FFieldsDefsDefined:Boolean;
    FieldsDefs:Array of TField;
    {$ENDIF}
    FDBConnector: TDBConnector;

    function GetPrimaryKeyField(TableName: String; OneField: Boolean): String;
    function GetGeneratorName(TableName: String): String;
    function GetMainQueryTable: string;

    procedure SetRequiredFields;
    Procedure FillDatasetUpdateSQL(KeyField, TableName: String);

    procedure AfterInsertData(Data: TDataSet);
    procedure AfterDeleteData(Data: TDataSet);
    procedure AfterPostData(Data: TDataSet);
    procedure AfterCancelData(Data: TDataSet);
    procedure AfterOpenData(Data: TDataSet);
    procedure BeforePostData(Data: TDataSet);
    procedure BeforeInsertData(Data: TDataSet);

    function GetAfterPostEvent: TDataSetNotifyEvent;
    procedure SetAfterPostEvent(Event: TDataSetNotifyEvent);
    function GetAfterCancelEvent: TDataSetNotifyEvent;
    procedure SetAfterCancelEvent(Event: TDataSetNotifyEvent);
    function GetAfterOpenEvent: TDataSetNotifyEvent;
    procedure SetAfterOpenEvent(Event: TDataSetNotifyEvent);
    function GetBeforePostEvent: TDataSetNotifyEvent;
    procedure SetBeforePostEvent(Event: TDataSetNotifyEvent);
    function GetBeforeInsertEvent: TDataSetNotifyEvent;
    procedure SetBeforeInsertEvent(Event: TDataSetNotifyEvent);
    function GetAfterDeleteEvent: TDataSetNotifyEvent;
    procedure SetAfterDeleteEvent(Event: TDataSetNotifyEvent);
    function GetAfterInsertEvent: TDataSetNotifyEvent;
    procedure SetAfterInsertEvent(Event: TDataSetNotifyEvent);

    Procedure SetNotAllowedOperations(Value: TOperationsTypes);
    Function GetNotAllowedOperations: TOperationsTypes;

    procedure SetSQL(const AValue: {$IFDEF WITH_WIDEDATASET}TWideStrings{$ELSE}TStringList{$ENDIF});
    function GetSQL: {$IFDEF WITH_WIDEDATASET}TWideStrings{$ELSE}TStringList{$ENDIF};

    Function FindNotAllowedOperation(Value: TNotAllowedOperation): Boolean;

    procedure SetDBConnector(Database: TDBConnector);
    function GetConnector: TDatabaseObject;

    procedure SetDCLDBConnector(Query: TDCLSimlyQuery);
    function GetDBConnector(Query: TDCLSimlyQuery): TDatabaseObject;
  public
    constructor Create(DatabaseObj: TDBConnector); overload;
    constructor Create(AOwner : TComponent); {$IFDEF FPC}override;{$ELSE}overload;{$ENDIF}
    destructor Destroy; override;

    procedure Open; overload;
    procedure Append;
    procedure Insert;
    procedure Edit;
    procedure Delete; {$IFDEF FPC}override;{$ENDIF}
    procedure Post; override;
    procedure SetUpdateSQL(TableName, KeyField: String);
    procedure ExecSQL; {$IFDEF SQLdbFamily}override;{$ENDIF}

    procedure SaveDB;
    procedure CancelDB;

    function GetKeyBookmark: TBookmark;
    procedure GotoKeyBookmark(Bookmark: TBookmark);

    property NotAllowOperations: TOperationsTypes read GetNotAllowedOperations write SetNotAllowedOperations;
    property KeyField: String read FKeyField;
    property MainTable: String read FMainTable;
  published
    property Connector: TDBConnector read FDBConnector write FDBConnector;
    property SQL:{$IFDEF WITH_WIDEDATASET}TWideStrings{$ELSE}TStringList{$ENDIF} read GetSQL write SetSQL;
    property AfterDelete: TDataSetNotifyEvent read GetAfterDeleteEvent write SetAfterDeleteEvent;
    property AfterPost: TDataSetNotifyEvent read GetAfterPostEvent write SetAfterPostEvent;
    property AfterCancel: TDataSetNotifyEvent read GetAfterCancelEvent write SetAfterCancelEvent;
    property AfterInsert: TDataSetNotifyEvent read GetAfterInsertEvent write SetAfterInsertEvent;
    property AfterOpen: TDataSetNotifyEvent read GetAfterOpenEvent write SetAfterOpenEvent;
    property BeforePost: TDataSetNotifyEvent read GetBeforePostEvent write SetBeforePostEvent;
    property BeforeInsert: TDataSetNotifyEvent read GetBeforeInsertEvent write SetBeforeInsertEvent;
    property UpdateSQLDefined: Boolean read FUpdateSQLDefined;
  end;

implementation

uses
  {$IFDEF TRANSACTIONDB}
  uDCLDBTransaction,
  {$ENDIF}
  uDCLGlobalVariables, Variants;

{ TDCLQuery }

procedure TDCLQuery.AfterCancelData(Data: TDataSet);
begin
  If Assigned(FAfterCancel) then
    FAfterCancel(Data);
  CancelDB;
end;

procedure TDCLQuery.AfterDeleteData(Data: TDataSet);
begin
  SaveDB;
  If Assigned(FAfterDelete) then
    FAfterDelete(Data);
end;

procedure TDCLQuery.AfterInsertData(Data: TDataSet);
begin
  If Assigned(FAfterInsert) then
    FAfterInsert(Data);
end;

procedure TDCLQuery.AfterOpenData(Data: TDataSet);
{$IFDEF ZEOS}
var
  i, j:Integer;
  LocalAfterOpen:TDataSetNotifyEvent;
{$ENDIF}
begin
{
    ftCursor,
    ftADT, ftReference,
    ftDataSet, ftOraClob, ftInterface,
    ftIDispatch, ftGuid
}
{$IFDEF ZEOS}
  If not FFieldsDefsDefined then
  Begin
    FFieldsDefsDefined:=True;
    FieldDefs.Clear;
    j:=Fields.Count;
    SetLength(FieldsDefs, j);
    j:=0;
    For i:=1 to Fields.Count do
    Begin
      Fields[i-1].Required:=False;
      Case Fields[i-1].DataType of
      ftSmallint, ftInteger, ftLargeint, ftWord, ftAutoInc:Begin
        FieldsDefs[j]:=TIntegerField.Create(Self);
        FieldsDefs[j].FieldName:=Fields[i-1].FieldName;
        FieldsDefs[j].Required:=False;
        Inc(j);
      end;
      ftFloat:Begin
        FieldsDefs[j]:=TFloatField.Create(Self);
        FieldsDefs[j].FieldName:=Fields[i-1].FieldName;
        TFloatField(FieldsDefs[j]).Precision:=5;
        TFloatField(FieldsDefs[j]).DisplayFormat:='#.#####0.00000';
        FieldsDefs[j].Required:=False;
        Inc(j);
      End;
      ftCurrency:Begin
        FieldsDefs[j]:=TCurrencyField.Create(Self);
        FieldsDefs[j].FieldName:=Fields[i-1].FieldName;
        TFloatField(FieldsDefs[j]).DisplayFormat:='#.##0.00';
        FieldsDefs[j].Required:=False;
        Inc(j);
      End;
      ftBCD, ftFMTBcd:Begin
        FieldsDefs[j]:=TNumericField.Create(Self);
        FieldsDefs[j].FieldName:=Fields[i-1].FieldName;
        TNumericField(FieldsDefs[j]).DisplayFormat:='#.#####0.00000';
        FieldsDefs[j].Required:=False;
        Inc(j);
      End;
      ftString, ftFixedChar, ftVariant:Begin
        FieldsDefs[j]:=TStringField.Create(Self);
        FieldsDefs[j].Size:=Fields[i-1].Size;
        FieldsDefs[j].FieldName:=Fields[i-1].FieldName;
        FieldsDefs[j].Required:=False;
        Inc(j);
      End;
      ftFixedWideChar, ftWideString:Begin
        FieldsDefs[j]:=TWideStringField.Create(Self);
        FieldsDefs[j].Size:=Fields[i-1].Size;
        FieldsDefs[j].FieldName:=Fields[i-1].FieldName;
        FieldsDefs[j].Required:=False;
        Inc(j);
      End;
      ftDate:Begin
        FieldsDefs[j]:=TDateField.Create(Self);
        FieldsDefs[j].FieldName:=Fields[i-1].FieldName;
        FieldsDefs[j].Required:=False;
        Inc(j);
      End;
      ftTime:Begin
        FieldsDefs[j]:=TTimeField.Create(Self);
        FieldsDefs[j].FieldName:=Fields[i-1].FieldName;
        FieldsDefs[j].Required:=False;
        Inc(j);
      End;
      ftDateTime{$IFDEF FPC}, ftTimeStamp{$ENDIF}:Begin
        FieldsDefs[j]:=TDateTimeField.Create(Self);
        FieldsDefs[j].FieldName:=Fields[i-1].FieldName;
        FieldsDefs[j].Required:=False;
        Inc(j);
      End;
      {$IFnDEF FPC}
      ftTimeStamp:Begin
        FieldsDefs[j]:=TSQLTimeStampField.Create(Self);
        FieldsDefs[j].FieldName:=Fields[i-1].FieldName;
        FieldsDefs[j].Required:=False;
        Inc(j);
      End;
      {$ENDIF}
      ftBoolean:Begin
        FieldsDefs[j]:=TBooleanField.Create(Self);
        FieldsDefs[j].FieldName:=Fields[i-1].FieldName;
        FieldsDefs[j].Required:=False;
        Inc(j);
      End;
      ftBytes, ftOraBlob, ftVarBytes, ftBlob, ftMemo, ftGraphic, ftFmtMemo,
      ftParadoxOle, ftDBaseOle, ftTypedBinary, ftArray,
      ftWideMemo:Begin
        FieldsDefs[j]:=TBlobField.Create(Self);
        FieldsDefs[j].FieldName:=Fields[i-1].FieldName;
        FieldsDefs[j].Required:=False;
        Inc(j);
      End;
      End;
    End;

    inherited Close;
    LocalAfterOpen:=AfterOpen;
    AfterOpen:=nil;
    FieldDefs.Clear;
    Fields.Clear;
    For i:=1 to Length(FieldsDefs) do
    Begin
      If Assigned(FieldsDefs[i-1]) then
      Begin
        FieldsDefs[i-1].Required:=False;
        FieldsDefs[i-1].DataSet:=Self;
      end;
    End;
    FieldDefs.Update;
    inherited Open;
    AfterOpen:=LocalAfterOpen;
  end;
{$ENDIF}
  If FetchAllData then
  begin
    inherited DisableControls;
    Last;
    First;
    inherited EnableControls;
  end;

  If Assigned(FAfterOpen) then
    FAfterOpen(Data);
  SetRequiredFields;
end;

procedure TDCLQuery.AfterPostData(Data: TDataSet);
begin
  SaveDB;
  If Assigned(FAfterPost) then
    FAfterPost(Data);
end;

procedure TDCLQuery.BeforeInsertData(Data: TDataSet);
begin
  if FindNotAllowedOperation(dsoInsert) then
    Cancel
  Else
    If Assigned(FBeforeInsert) then
      FBeforeInsert(Data);
end;

procedure TDCLQuery.BeforePostData(Data: TDataSet);
begin
  If FindNotAllowedOperation(dsoEdit) then
    Cancel
  Else
    If Assigned(FBeforePost) then
      FBeforePost(Data);
end;

procedure TDCLQuery.CancelDB;
begin
{$IFDEF CACHEDDB}
  If RowsAffected<>-1 then
    CancelUpdates;
{$ENDIF}
{$IFDEF ZEOS}
  If not Connection.AutoCommit then
    Connection.Rollback;
{$ENDIF}
end;

constructor TDCLQuery.Create(DatabaseObj: TDBConnector);
begin
  inherited Create(nil);
  FUpdateSQLDefined:=False;
{$IFDEF ZEOS}
  FFieldsDefsDefined:=False;
  Connection:=DatabaseObj;
{$ENDIF}
{$IFDEF ADO}
  Connection:=DatabaseObj;
{$ENDIF}
{$IFDEF IBX}
  Database:=DatabaseObj;
  {$IFDEF FPC}
  AllowAutoActivateTransaction:=True;
  AutoCommit:=acCommitRetaining;
  {$ENDIF}
{$ENDIF}
{$IFDEF SQLdbFamily}
  Database:=DatabaseObj;
{$ENDIF}
{$IFDEF TRANSACTIONDB}
  Transaction:=TDCLDBTransaction.Create(GetConnector, trtWrite);
{$ENDIF}
  inherited AfterDelete:=AfterDeleteData;
  inherited AfterInsert:=AfterInsertData;
  inherited AfterPost:=AfterPostData;
  inherited AfterCancel:=AfterCancelData;
  inherited AfterOpen:=AfterOpenData;
  inherited BeforePost:=BeforePostData;
  inherited BeforeInsert:=BeforeInsertData;

  ShadowQuery:=TDCLDialogQuery.Create(Self);
{$IFDEF TRANSACTIONDB}
  ShadowTransaction:=TDCLDBTransaction.Create(GetConnector, trtWrite);
  ShadowQuery.Transaction:=Transaction;
{$ENDIF}
{$IFDEF ZEOS}
  ShadowQuery.Connection:=DatabaseObj;
{$ENDIF}
{$IFDEF IBX}
  ShadowQuery.Database:=DatabaseObj;
  {$IFDEF FPC}
  ShadowQuery.AllowAutoActivateTransaction:=True;
  ShadowQuery.AutoCommit:=acCommitRetaining;
  //ShadowQuery.AutoTrim:=True;
  {$ENDIF}
{$ENDIF}
{$IFDEF SQLdbFamily}
  ShadowQuery.Database:=DatabaseObj;
{$ENDIF}
end;

constructor TDCLQuery.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FUpdateSQLDefined:=False;
{$IFDEF ZEOS}
  FFieldsDefsDefined:=False;
{$ENDIF}
{$IFDEF ADO}
{$ENDIF}
{$IFDEF IBX}
  {$IFDEF FPC}
  AllowAutoActivateTransaction:=True;
  AutoCommit:=acCommitRetaining;
  {$ENDIF}
{$ENDIF}
{$IFDEF TRANSACTIONDB}
  Transaction:=TDCLDBTransaction.Create(GetConnector, trtWrite);
{$ENDIF}
  inherited AfterDelete:=AfterDeleteData;
  inherited AfterInsert:=AfterInsertData;
  inherited AfterPost:=AfterPostData;
  inherited AfterCancel:=AfterCancelData;
  inherited AfterOpen:=AfterOpenData;
  inherited BeforePost:=BeforePostData;
  inherited BeforeInsert:=BeforeInsertData;

  ShadowQuery:=TDCLSimlyQuery.Create(Self);
{$IFDEF TRANSACTIONDB}
  ShadowTransaction:=TDCLDBTransaction.Create(GetConnector, trtWrite);
  ShadowQuery.Transaction:=Transaction;
{$ENDIF}
{$IFDEF IBX}
  {$IFDEF FPC}
  ShadowQuery.AllowAutoActivateTransaction:=True;
  ShadowQuery.AutoCommit:=acCommitRetaining;
  {$ENDIF}
{$ENDIF}
end;

procedure TDCLQuery.FillDatasetUpdateSQL(KeyField, TableName: String);
var
  UpdatesFieldsSet, KeyFieldsSet, FieldN: String;
  lUpdateSQL, lInsertSQL, lDeleteSQL, lRefreshSQL: String;
  v1, v2: Integer;
  DBField: TField;
  KeyFields, UpdateFields: TList<String>;
Begin
  If TableName<>'' Then
  Begin
    FMainTable:=TableName;
{$IFDEF ADO}
    If ToOpen then
      If not Active Then
        If SQL.Text<>'' Then
          inherited Open;
    If Active Then
      Properties['Unique Table'].Value:=TableName;
{$ENDIF}

    If KeyField<>'' then
    Begin
      FKeyField:=KeyField;

      If not Assigned(FUpdateSQL) then
      Begin
        {$IFnDEF SELFUPDATESQL}
        FUpdateSQL:=TUpdateObj.Create(Self);
        {$IFDEF ZEOS}
        FUpdateSQL.UseSequenceFieldForRefreshSQL:=False;
        {$ENDIF}
        {$IFDEF TRANSACTIONDB}
        {$IFDEF IBX}
        {$IFDEF DOUBLTRANSACTION}
        FUpdateSQL.UpdateTransaction:=ShadowTransaction;
        {$ENDIF}
        {$ENDIF}
        {$ENDIF}
        {$ELSE}
        FUpdateSQL:=Self;
        {$ENDIF}
      End;
      {$IFnDEF SELFUPDATESQL}
      UpdateObject:=FUpdateSQL;
      {$ENDIF}

      lUpdateSQL:='';
      lInsertSQL:='';
      lDeleteSQL:='';
      lRefreshSQL:='';

      ShadowQuery.SQL.Text:='select * from '+TableName+' where 1=0';
      ShadowQuery.Open;

      KeyFields:=TList<String>.Create;
      UpdateFields:=TList<String>.Create;

      v1:=ParamsCount(KeyField);
      If v1>1 then
      Begin
        For v2:=1 to v1 do
        Begin
          KeyFields.Add(UpperCase(GetParam(KeyField, v2)));
        End;
      End
      Else
      Begin
        KeyFields.Add(UpperCase(KeyField));
      end;

      For DBField in ShadowQuery.Fields do
        UpdateFields.Add(UpperCase(DBField.FieldName));

      ShadowQuery.Close;

      UpdatesFieldsSet:='';
      For FieldN in UpdateFields do
      Begin
        UpdatesFieldsSet:=UpdatesFieldsSet+FieldN+'=:'+FieldN+', ';
      End;

      If UpdatesFieldsSet<>'' then
        System.Delete(UpdatesFieldsSet, Length(UpdatesFieldsSet)-1, 2);

      KeyFieldsSet:='';
      For FieldN in KeyFields do
        KeyFieldsSet:=KeyFieldsSet+FieldN+'=:OLD_'+FieldN+' and ';

      If KeyFieldsSet<>'' then
        System.Delete(KeyFieldsSet, Length(KeyFieldsSet)-4, 5);

      If not FindNotAllowedOperation(dsoEdit) then
        lUpdateSQL:='update '+TableName+' set '+UpdatesFieldsSet+' where '+
          KeyFieldsSet;

      UpdatesFieldsSet:='';
      For FieldN in UpdateFields Do
      begin
        UpdatesFieldsSet:=UpdatesFieldsSet+FieldN+', ';
      end;

      If UpdatesFieldsSet<>'' then
        System.Delete(UpdatesFieldsSet, Length(UpdatesFieldsSet)-1, 2);

      KeyFieldsSet:='';
      For FieldN in UpdateFields Do
      begin
        KeyFieldsSet:=KeyFieldsSet+':'+FieldN+', ';
      end;

      If KeyFieldsSet<>'' then
        System.Delete(KeyFieldsSet, Length(KeyFieldsSet)-1, 2);

      If not FindNotAllowedOperation(dsoInsert) then
        lInsertSQL:='insert into '+TableName+'('+UpdatesFieldsSet+') values('+
          KeyFieldsSet+')';

      KeyFieldsSet:='';
      For FieldN in KeyFields do
        KeyFieldsSet:=KeyFieldsSet+FieldN+'=:OLD_'+FieldN+' and ';

      If KeyFieldsSet<>'' then
        System.Delete(KeyFieldsSet, Length(KeyFieldsSet)-4, 5);

      If not FindNotAllowedOperation(dsoDelete) then
        lDeleteSQL:='delete from '+TableName+' where '+KeyFieldsSet;

      {$IFDEF REFRESHSQLDB}
      KeyFieldsSet:='';
      For FieldN in KeyFields do
        KeyFieldsSet:=KeyFieldsSet+FieldN+'=:'+FieldN+' and ';
      If KeyFieldsSet<>'' then
        System.Delete(KeyFieldsSet, Length(KeyFieldsSet)-4, 5);

      lRefreshSQL:='select * from '+TableName+' where '+KeyFieldsSet;
      if FUpdateSQL.RefreshSQL.Text<>lRefreshSQL then
        FUpdateSQL.RefreshSQL.Text:=lRefreshSQL;
      {$ENDIF}

      if FUpdateSQL.{$IFNDEF SQLdbFamily}ModifySQL{$ELSE}UpdateSQL{$ENDIF}.Text<>lUpdateSQL then
        FUpdateSQL.{$IFNDEF SQLdbFamily}ModifySQL{$ELSE}UpdateSQL{$ENDIF}.Text:=lUpdateSQL;

      if FUpdateSQL.InsertSQL.Text<>lInsertSQL then
        FUpdateSQL.InsertSQL.Text:=lInsertSQL;

      if FUpdateSQL.DeleteSQL.Text<>lDeleteSQL then
        FUpdateSQL.DeleteSQL.Text:=lDeleteSQL;
    End;
  end;
End;

function TDCLQuery.FindNotAllowedOperation(Value: TNotAllowedOperation
  ): Boolean;
Var
  l, i: Byte;
Begin
  l:=Length(FNotAllowOperations);
  Result:=False;
  If l>0 then
    For i:=1 to l do
    Begin
      If FNotAllowOperations[i-1]=Value then
      Begin
        Result:=True;
        Break;
      End;
    End;
end;

procedure TDCLQuery.SetDBConnector(Database: TDBConnector);
begin
  {$IFDEF ADO}
  Connection:=Database;
  {$ENDIF}
  {$IFDEF IBX}
  Self.DataBase:=Database;
  {$ENDIF}
  {$IFDEF ZEOS}
  Self.Connector:=Database;
  {$ENDIF}
  {$IFDEF SQLdbFamily}
  Self.DataBase:=Database;
  {$ENDIF}
  {$IFDEF TRANSACTIONDB}
  {$IFDEF SQLdbFamily}
  Self.Transaction:=Database.Transaction;
  {$ENDIF}
  {$IFDEF IBX}
  Self.Transaction:=Database.DefaultTransaction;
  {$ENDIF}
  {$IFDEF IBXLaz}
  Self.AllowAutoActivateTransaction:=True;
  {$ENDIF}
  {$ENDIF}
end;

function TDCLQuery.GetConnector: TDatabaseObject;
begin
  Result:=
  {$IFDEF ADO}
  Self.Connection
  {$ENDIF}
  {$IFDEF IBX}
  Self.DataBase
  {$ENDIF}
  {$IFDEF ZEOS}
  Self.Connector
  {$ENDIF}
  {$IFDEF SQLdbFamily}
  Self.DataBase
  {$ENDIF};
end;

procedure TDCLQuery.SetDCLDBConnector(Query: TDCLSimlyQuery);
begin
  {$IFDEF ADO}
  Query.Connection:=Self.Connection;
  {$ENDIF}
  {$IFDEF IBX}
  Query.DataBase:=Self.DataBase;
  {$ENDIF}
  {$IFDEF ZEOS}
  Query.Connection:=Self.Connection;
  {$ENDIF}
  {$IFDEF SQLdbFamily}
  Query.DataBase:=Self.DataBase;
  {$ENDIF}
  {$IFDEF TRANSACTIONDB}
  {$IFDEF SQLdbFamily}
  Query.Transaction:=Transaction;
  {$ENDIF}
  {$IFDEF IBX}
  Query.Transaction:=Self.Transaction;
  {$ENDIF}
  {$IFDEF IBXLaz}
  Query.AllowAutoActivateTransaction:=True;
  {$ENDIF}
  {$IFDEF ZEOS}
  Query.Transaction:=Self.Transaction;
  {$ENDIF}
  {$ENDIF}
end;

function TDCLQuery.GetDBConnector(Query: TDCLSimlyQuery): TDatabaseObject;
begin
  Result:=
  {$IFDEF ADO}
  Query.Connection
  {$ENDIF}
  {$IFDEF IBX}
  Query.DataBase
  {$ENDIF}
  {$IFDEF ZEOS}
  Query.Connection
  {$ENDIF}
  {$IFDEF SQLdbFamily}
  Query.DataBase
  {$ENDIF};
end;

destructor TDCLQuery.Destroy;
begin
  FAfterDelete:=nil;
  FAfterPost:=nil;
  FAfterCancel:=nil;
  FAfterInsert:=nil;
  FAfterOpen:=nil;
  FBeforePost:=nil;
  FBeforeInsert:=nil;

  Cancel;
  Close;
{$IFDEF TRANSACTIONDB}
  If Assigned(ShadowTransaction) then
    FreeAndNil(ShadowTransaction);
{$ENDIF}
{$IFnDEF SELFUPDATESQL}
  If Assigned(FUpdateSQL) then
    FreeAndNil(FUpdateSQL);
{$ENDIF}
  If Assigned(ShadowQuery) then
    FreeAndNil(ShadowQuery);

  inherited Destroy;
end;

function TDCLQuery.GetAfterCancelEvent: TDataSetNotifyEvent;
begin
  Result:=FAfterCancel;
end;

function TDCLQuery.GetAfterDeleteEvent: TDataSetNotifyEvent;
begin
  Result:=FAfterDelete;
end;

function TDCLQuery.GetAfterInsertEvent: TDataSetNotifyEvent;
begin
  Result:=FAfterInsert;
end;

function TDCLQuery.GetAfterOpenEvent: TDataSetNotifyEvent;
begin
  Result:=FAfterOpen;
end;

function TDCLQuery.GetAfterPostEvent: TDataSetNotifyEvent;
begin
  Result:=FAfterPost;
end;

function TDCLQuery.GetBeforeInsertEvent: TDataSetNotifyEvent;
begin
  Result:=FBeforeInsert;
end;

function TDCLQuery.GetBeforePostEvent: TDataSetNotifyEvent;
begin
  Result:=FBeforePost;
end;

function TDCLQuery.GetMainQueryTable: string;
var
  S, Tables, from, stopSymbols: String;
  braket, l, p, pos1, p2: Integer;
  preFind, find:Boolean;
begin
  Result:='';
  from:='from ';
  S:=SQL.Text;
  l:=Length(S);
  Tables:='';
  p:=1;
  braket:=0;
  preFind:=False;
  find:=False;
  pos1:=1;
  while p<l do
  begin
    if (S[p]='(') then
    begin
      Inc(braket);
      pos1:=1;
      preFind:=False;
    end;

    if (braket=0) then
    begin
      if preFind then
      begin
        if S[p]=from[pos1] then
        begin
          Inc(pos1);

          if pos1-1=Length(from) then
          begin
            find:=True;
            break;
          end;
        end
        else
        begin
          pos1:=1;
          preFind:=False;
        end;
      end
      else
      if (braket=0) and (LowerCase(S[p])=from[pos1]) then
      begin
        preFind:=True;
        Inc(pos1);
      end;
    end;

    if (S[p]=')') then
    begin
      Dec(braket);
      pos1:=1;
      preFind:=False;
    end;
    Inc(p);
  end;

  If find then
  begin
    if p>1 then
    begin
      stopSymbols:=' /\=-+~`"<>!@#%^&*()[]|?,.'#10#13#39;
      while (Pos(S[p], stopSymbols)<>0) do
      begin
        Inc(p);
      end;
      p2:=p;

      while (Pos(S[p2], stopSymbols)=0) do
      begin
        Inc(p2);

        if p2=l then
        begin
          Inc(p2);
          break;
        end;
      end;

      Tables:=Copy(S, p, p2-p);
    end;
  end;

  Result:=Tables;
end;

function TDCLQuery.GetNotAllowedOperations: TOperationsTypes;
begin
  Result:=FNotAllowOperations;
end;

procedure TDCLQuery.SetSQL(const AValue: {$IFDEF WITH_WIDEDATASET}TWideStrings{$ELSE}TStringList{$ENDIF});
begin
  FUpdateSQLDefined:=False;
  inherited Close;
  inherited SQL.Assign(AValue);
end;

function TDCLQuery.GetSQL: {$IFDEF WITH_WIDEDATASET}TWideStrings{$ELSE}TStringList{$ENDIF};
begin
  Result:={$IFDEF WITH_WIDEDATASET}TWideStrings{$ELSE}TStringList{$ENDIF}(inherited SQL);
end;

function TDCLQuery.GetPrimaryKeyField(TableName: String; OneField: Boolean): String;
begin
  Result:='';
  If GPT.IBAll then
  Begin
    If (TableName<>'') and Assigned(ShadowQuery) then
    Begin
      if not Assigned(GetDBConnector(ShadowQuery)) then
        SetDCLDBConnector(ShadowQuery);

      ShadowQuery.Params.Clear;
      ShadowQuery.SQL.Text:='select RDB$FIELD_NAME '+
        'from RDB$RELATION_CONSTRAINTS C, RDB$INDICES I, RDB$INDEX_SEGMENTS S '+
        'where upper(C.RDB$RELATION_NAME) = upper(:TABLENAME) and '+
              'C.RDB$CONSTRAINT_TYPE = ''PRIMARY KEY'' and I.RDB$UNIQUE_FLAG = 1 and '+
              '((I.RDB$INDEX_INACTIVE = 0) or (I.RDB$INDEX_INACTIVE is null)) and '+
              'C.RDB$RELATION_NAME = I.RDB$RELATION_NAME and '+
              'I.RDB$INDEX_NAME = C.RDB$INDEX_NAME and '+
              'S.RDB$INDEX_NAME = I.RDB$INDEX_NAME '+
        'union '+
        'select RDB$FIELD_NAME '+
                'from RDB$RELATION_CONSTRAINTS C, RDB$INDICES I, RDB$INDEX_SEGMENTS S '+
                'where upper(C.RDB$RELATION_NAME) = upper(:TABLENAME) and '+
                      'C.RDB$CONSTRAINT_TYPE = ''UNIQUE'' and I.RDB$UNIQUE_FLAG = 1 and '+
                      '((I.RDB$INDEX_INACTIVE = 0) or (I.RDB$INDEX_INACTIVE is null)) and '+
                      'C.RDB$RELATION_NAME = I.RDB$RELATION_NAME and '+
                      'I.RDB$INDEX_NAME = C.RDB$INDEX_NAME and '+
                      'S.RDB$INDEX_NAME = I.RDB$INDEX_NAME and '+
                      'not exists(select * '+
                                       'from RDB$RELATION_CONSTRAINTS C1, RDB$INDICES I1 '+
                                       'where upper(C1.RDB$RELATION_NAME) = upper(:TABLENAME) and '+
                                             'C1.RDB$CONSTRAINT_TYPE = ''PRIMARY KEY'' and I1.RDB$UNIQUE_FLAG = 1 and '+
                                             '((I1.RDB$INDEX_INACTIVE = 0) or (I1.RDB$INDEX_INACTIVE is null)) and '+
                                             'C1.RDB$RELATION_NAME = I1.RDB$RELATION_NAME and '+
                                             'I1.RDB$INDEX_NAME = C1.RDB$INDEX_NAME)';

      ShadowQuery.ParamByName('TABLENAME').AsString:=TableName;
      ShadowQuery.Open;
      while not ShadowQuery.Eof do
      Begin
        Result:=Result+Trim(ShadowQuery.Fields[0].AsString)+',';
        if OneField then
          break;
        ShadowQuery.Next;
      End;
      ShadowQuery.Close;
      If Result<>'' then
        Result:=Copy(Result, 1, Length(Result)-1);
    End;
  End;
end;

function TDCLQuery.GetGeneratorName(TableName: String): String;
var
  Empty: Boolean;
  Triggers: TList<String>;
  Trigger: String;
begin
  Result:='';
  If GPT.IBAll then
  Begin
    If (TableName<>'') and Assigned(ShadowQuery) then
    Begin
      if not Assigned(GetDBConnector(ShadowQuery)) then
        SetDCLDBConnector(ShadowQuery);

      ShadowQuery.Params.Clear;
      ShadowQuery.SQL.Text:='select first 1 1 from RDB$DEPENDENCIES dp, RDB$TRIGGERS tr where dp.rdb$dependent_name=tr.rdb$trigger_name and '+
        'tr.rdb$relation_name=dp.rdb$depended_on_name and dp.rdb$dependent_type=2 and '+
        'dp.rdb$depended_on_name=upper(:TABLENAME) and dp.rdb$field_name=(select RDB$FIELD_NAME '+
                'from RDB$RELATION_CONSTRAINTS C, RDB$INDICES I, RDB$INDEX_SEGMENTS S '+
                'where upper(C.RDB$RELATION_NAME) = upper(:TABLENAME) and '+
                      'C.RDB$CONSTRAINT_TYPE = ''PRIMARY KEY'' and I.RDB$UNIQUE_FLAG = 1 and '+
                      '((I.RDB$INDEX_INACTIVE = 0) or (I.RDB$INDEX_INACTIVE is null)) and '+
                      'C.RDB$RELATION_NAME = I.RDB$RELATION_NAME and '+
                      'I.RDB$INDEX_NAME = C.RDB$INDEX_NAME and '+
                      'S.RDB$INDEX_NAME = I.RDB$INDEX_NAME) and '+
        'dp.rdb$depended_on_type=0 and tr.rdb$system_flag = 0 and tr.rdb$trigger_inactive = 0';
      ShadowQuery.ParamByName('TABLENAME').AsString:=TableName;
      ShadowQuery.Open;
      Empty:=ShadowQuery.IsEmpty;
      ShadowQuery.Close;

      if Empty then
      begin
        ShadowQuery.Params.Clear;
        ShadowQuery.SQL.Text:='select ff.rdb$generator_name from RDB$RELATION_FIELDS ff where ff.rdb$relation_name = upper(:TABLENAME) and ff.rdb$field_name=(select RDB$FIELD_NAME '+
          'from RDB$RELATION_CONSTRAINTS C, RDB$INDICES I, RDB$INDEX_SEGMENTS S '+
          'where upper(C.RDB$RELATION_NAME) = upper(:TABLENAME) and '+
                'C.RDB$CONSTRAINT_TYPE = ''PRIMARY KEY'' and I.RDB$UNIQUE_FLAG = 1 and '+
                '((I.RDB$INDEX_INACTIVE = 0) or (I.RDB$INDEX_INACTIVE is null)) and '+
                'C.RDB$RELATION_NAME = I.RDB$RELATION_NAME and '+
                'I.RDB$INDEX_NAME = C.RDB$INDEX_NAME and '+
                'S.RDB$INDEX_NAME = I.RDB$INDEX_NAME) and ff.rdb$generator_name is not null and ff.rdb$identity_type = 1';
        try
          ShadowQuery.Open;
          Result:=Trim(ShadowQuery.Fields[0].AsString);
        finally
          ShadowQuery.Close;
        end;
      end
      else
      begin
        ShadowQuery.Params.Clear;
        ShadowQuery.SQL.Text:='select tr.rdb$trigger_name from RDB$DEPENDENCIES dp, RDB$TRIGGERS tr where dp.rdb$dependent_name=tr.rdb$trigger_name and '+
          'tr.rdb$relation_name=dp.rdb$depended_on_name and dp.rdb$dependent_type=2 and '+
          'dp.rdb$depended_on_name=upper(:TABLENAME) and dp.rdb$field_name=(select RDB$FIELD_NAME '+
                  'from RDB$RELATION_CONSTRAINTS C, RDB$INDICES I, RDB$INDEX_SEGMENTS S '+
                  'where upper(C.RDB$RELATION_NAME) = upper(:TABLENAME) and '+
                        'C.RDB$CONSTRAINT_TYPE = ''PRIMARY KEY'' and I.RDB$UNIQUE_FLAG = 1 and '+
                        '((I.RDB$INDEX_INACTIVE = 0) or (I.RDB$INDEX_INACTIVE is null)) and '+
                        'C.RDB$RELATION_NAME = I.RDB$RELATION_NAME and '+
                        'I.RDB$INDEX_NAME = C.RDB$INDEX_NAME and '+
                        'S.RDB$INDEX_NAME = I.RDB$INDEX_NAME) and '+
          'dp.rdb$depended_on_type=0 and tr.rdb$system_flag = 0 and tr.rdb$trigger_inactive = 0';
        ShadowQuery.Open;

        Triggers:=TList<String>.Create;
        while not ShadowQuery.EOF do
        begin
          Triggers.Add(Trim(ShadowQuery.Fields[0].AsString));
          ShadowQuery.Next;
        end;
        ShadowQuery.Close;

        for Trigger in Triggers do
        begin
          ShadowQuery.Params.Clear;
          ShadowQuery.SQL.Text:='select ge.rdb$generator_name from RDB$DEPENDENCIES dp, RDB$TRIGGERS tr, rdb$generators ge where '+
                                  'dp.rdb$dependent_name=:GEN_NAME and '+
                                  'ge.rdb$generator_name = dp.rdb$depended_on_name and '+
                                  'dp.rdb$dependent_name=tr.rdb$trigger_name';
          ShadowQuery.ParamByName('GEN_NAME').AsString:=Trigger;
          ShadowQuery.Open;

          Result:=Trim(ShadowQuery.Fields[0].AsString);
          ShadowQuery.Close;
          if Result<>'' then break;
        end;
      end;
    End;
  End;
end;

procedure TDCLQuery.Open;
var
  GenName: String;
begin
  inherited Close;
  If not FUpdateSQLDefined then
  begin
    FMainTable:=GetMainQueryTable;
    FKeyField:=GetPrimaryKeyField(FMainTable, True);

    {$IFDEF SEQUENCENAME}
    GenName:=GetGeneratorName(FMainTable);
    if (GenName<>'') and (FKeyField<>'') then
    begin
      Self.Sequence.SequenceName:=GenName;
      Self.Sequence.FieldName:=FKeyField;
    end;
    {$ENDIF}

    FillDatasetUpdateSQL(FKeyField, FMainTable);
    FUpdateSQLDefined:=True;
  end;

  inherited Open;
end;

procedure TDCLQuery.Append;
begin
  If not FindNotAllowedOperation(dsoInsert) then
     inherited Append;
end;

procedure TDCLQuery.Insert;
begin
  If not FindNotAllowedOperation(dsoInsert) then
     inherited Insert;
end;

procedure TDCLQuery.Edit;
begin
  If not FindNotAllowedOperation(dsoEdit) then
     inherited Edit;
end;

function TDCLQuery.GetKeyBookmark: TBookmark;
var
  S: String;
  MS: TMemoryStream;
begin
  Result:=nil;
  if FKeyField<>'' then
  begin
    if Active then
    begin
      S:=FieldByName(FKeyField).AsString;
      MS:=TMemoryStream.Create;
      MS.Write(S[1], S.Length);
      SetLength(Result, S.Length);
      MS.Position:=0;
      MS.Read(Result[0], S.Length);
      FreeAndNil(MS);
    end;
  end;
end;

procedure TDCLQuery.GotoKeyBookmark(Bookmark: TBookmark);
var
  KValues: Variant;
  MS: TMemoryStream;
  S: String;
begin
  if Active and (FKeyField<>'') then
  begin
    S:='';
    SetLength(S, Length(Bookmark));
    MS:=TMemoryStream.Create;
    MS.Write(Bookmark[0], Length(Bookmark));
    MS.Position:=0;
    MS.Read(S[1], Length(Bookmark));
    FreeAndNil(MS);
    KValues:=S;
    Locate(FKeyField, KValues, [loCaseInsensitive]);
  end;
end;

procedure TDCLQuery.ExecSQL;
begin
  If not (FindNotAllowedOperation(dsoEdit) or FindNotAllowedOperation(dsoDelete) or FindNotAllowedOperation(dsoInsert)) then
    inherited ExecSQL;
end;

procedure TDCLQuery.Delete;
begin
  If not FindNotAllowedOperation(dsoDelete) then
    inherited Delete;
end;

procedure TDCLQuery.Post;
begin
  If not FindNotAllowedOperation(dsoEdit) then
    inherited Post;
end;

procedure TDCLQuery.SaveDB;
begin
{$IFDEF CACHEDDB}
{$IFnDEF SQLdbFamily}
  If UpdatesPending then
    If CachedUpdates then
{$ENDIF}
      ApplyUpdates;
{$IFDEF ZEOS}
  If Active then
    CommitUpdates;
  If not Connection.AutoCommit then
    Connection.Commit;
{$ENDIF}
{$ENDIF}
{$IFDEF TRANSACTIONDB}
{$IFDEF SELFUPDATESQL}
  If Transaction.Active then
    (Transaction as TTransaction).CommitRetaining;
{$ELSE}
  If Assigned(ShadowTransaction) then
{$IFDEF IBX}
  If ShadowTransaction.InTransaction then
{$ENDIF}
  If ShadowTransaction.Active then
    ShadowTransaction.Commit;
{$ENDIF}
{$ENDIF}
end;

procedure TDCLQuery.SetAfterCancelEvent(Event: TDataSetNotifyEvent);
begin
  If (@FAfterCancel<>@AfterCancel)or(@FAfterCancel=nil) then
    FAfterCancel:=Event;
end;

procedure TDCLQuery.SetAfterDeleteEvent(Event: TDataSetNotifyEvent);
begin
  If (@FAfterDelete<>@AfterDelete)or(@FAfterDelete=nil) then
    FAfterDelete:=Event;
end;

procedure TDCLQuery.SetAfterInsertEvent(Event: TDataSetNotifyEvent);
begin
  If (@FAfterInsert<>@AfterInsert)or(@FAfterInsert=nil) then
    FAfterInsert:=Event;
end;

procedure TDCLQuery.SetAfterOpenEvent(Event: TDataSetNotifyEvent);
begin
  If (@FAfterOpen<>@AfterOpen)or(@FAfterOpen=nil) then
    FAfterOpen:=Event;
end;

procedure TDCLQuery.SetAfterPostEvent(Event: TDataSetNotifyEvent);
begin
  If (@FAfterPost<>@AfterPost)or(@FAfterPost=nil) then
    FAfterPost:=Event;
end;

procedure TDCLQuery.SetBeforeInsertEvent(Event: TDataSetNotifyEvent);
begin
  If (@FBeforeInsert<>@BeforeInsert)or(@FBeforeInsert=nil) then
    FBeforeInsert:=Event;
end;

procedure TDCLQuery.SetBeforePostEvent(Event: TDataSetNotifyEvent);
begin
  If (@FBeforePost<>@BeforePost)or(@FBeforePost=nil) then
    FBeforePost:=Event;
end;

procedure TDCLQuery.SetNotAllowedOperations(Value: TOperationsTypes);
begin
  if FNotAllowOperations<>Value then
  begin
    FNotAllowOperations:=Value;
    If not FUpdateSQLDefined then
    Begin
      FMainTable:=GetMainQueryTable;
      FKeyField:=GetPrimaryKeyField(FMainTable, True);
      FUpdateSQLDefined:=True;
    End;
    SetUpdateSQL(FMainTable, FKeyField);
  end;
end;

procedure TDCLQuery.SetRequiredFields;
Var
  v1: Word;
Begin
{$IFDEF FREQUIREDDB}
  If Active then
    For v1:=1 to FieldCount do
      Fields[v1-1].Required:=False;
{$ENDIF}
end;

procedure TDCLQuery.SetUpdateSQL(TableName, KeyField: String);
begin
  inherited Close;
  FillDatasetUpdateSQL(KeyField, TableName);
  inherited Open;
end;

end.
