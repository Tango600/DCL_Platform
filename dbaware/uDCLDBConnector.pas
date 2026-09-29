unit uDCLDBConnector;
{$I DefineType.pas}

interface

uses
  Classes, SysUtils,
  {$IFDEF IBX}
  IB, IBDatabase, IBCustomDataSet, uDCLConst,
  {$ENDIF}
  {$IFDEF ZEOS}
  ZDbcIntfs,
  {$ENDIF}
  {$IFDEF SQLdbFamily}
  // добавить сюда модули Коннектров тех типов БД, с которыми предпологается
  // работать через SQLdb
  SQLDB, SQLDBLib, IBConnection,
  {$ENDIF}
  FileUtil, LazUTF8, LazFileUtils,
  uDCLDBAwareTypes, uDCLDebug;

type
  { TDCLDBConnector }

  TDCLDBConnector=class(TDBConnector)
  private
    FErrorCode: Integer;
{$IFDEF SQLdbFamily}
    FSQLDBLibraryLoader: TSQLDBLibraryLoader;
{$ENDIF}
{$IFDEF TRANSACTIONDB}
    UniversalTransaction: TTransaction;
{$IFDEF ZEOS}
    WriteTransaction: TTransaction;
{$ENDIF}
{$ENDIF}
    ///SQLMon: TDCLSQLMon;
  public
    constructor Create; overload;

    procedure SetConnector(Query: TDCLDialogQuery);

    property ErrorCode: Integer read FErrorCode;
  end;


implementation

uses
  uDCLConst, uSystemUtils, uDCLGlobalVariables, uDCLException;

{ TDCLDBConnector }

constructor TDCLDBConnector.Create;
begin
  inherited Create(nil);
  Name:='DCL_DBConnector';
  FErrorCode:=255;

  {$IFDEF IBX}
  GPT.IBAll:=True;

  If Not Assigned(DefaultTransaction) Then
  begin
    UniversalTransaction:=TTransaction.Create(Self);
    UniversalTransaction.Params.Clear;
    UniversalTransaction.Params.Append('nowait');
    UniversalTransaction.Params.Append('read_committed');
    UniversalTransaction.Params.Append('rec_version');
    UniversalTransaction.DefaultAction:=TACommit;
    {$IFNDEF FPC}
    UniversalTransaction.AllowAutoStart:=True;
    {$ENDIF}
    UniversalTransaction.DefaultDataBase:=Self;
    DefaultTransaction:=UniversalTransaction;
  end
  Else
    UniversalTransaction:=DefaultTransaction;

  If GPT.DBPath<>'' Then
  begin
    {$IFDEF FPC}
    If GPT.LibPath<>'' Then
      FirebirdLibraryPathName:=GPT.LibPath
    Else
      FirebirdLibraryPathName:=DefaultLibraryLocation;
    {$ENDIF}

    Params.Clear;
    If Not FilenameIsAbsolute(GPT.DBPath) Then
      GPT.DBPath:=ExtractFilePath(ParamStr(0))+GPT.DBPath;

    If IsUNCPath(GPT.DBPath) Then
    begin
      DebugProc('  DBPath: '+GPT.DBPath);
      DebugProc('UNC paths not supported.');
      Exit;
    end;

    If GPT.ServerName<>'' Then
    begin
      DatabaseName:=GPT.ServerName+':'+GPT.DBPath;
      DebugProc('  DBPath: '+GPT.ServerName+':'+GPT.DBPath);
    end
    Else
    begin
      DatabaseName:=GPT.DBPath;
      DebugProc('  DBPath: '+GPT.DBPath);
    end;
    Params.Append('USER_NAME='+GPT.DBUserName);
    DebugProc('  USER NAME='+GPT.DBUserName);
    If GPT.DBPassword<>'' Then
    begin
      Params.Append('PASSWORD='+GPT.DBPassword);
      LoginPrompt:=False;
    end
    Else
      LoginPrompt:=True;

    If GPT.ServerCodePage='' Then
    Begin
      raise Exception.Create('Server code page not define!');
    End
    Else
      Params.Append('lc_ctype='+UpperCase(ReplaseCPtoWIN(GPT.ServerCodePage)));

    SQLDialect:=GPT.SQLDialect;
    UniversalTransaction.DefaultAction:=TACommit; // Retaining;
    UniversalTransaction.DefaultDataBase:=Self;
    DefaultTransaction:=UniversalTransaction;
  end;
  {$ENDIF}
  {$IFDEF ZEOS}
  If GPT.DBPath<>'' Then
  begin
    If PosEx(DBTypeFirebird, GPT.DBType)>0 then
    Begin
      GPT.IBAll:=True;
      GPT.DBType:=DefaultDBType;
    End;
    If PosEx(DBTypeInterbase, GPT.DBType)>0 then
    Begin
      GPT.IBAll:=True;
      GPT.DBType:=DefaultDBTInterBaseType;
    End;

    If Not FilenameIsAbsolute(GPT.DBPath) Then
      GPT.DBPath:=ExtractFilePath(ParamStr(0))+GPT.DBPath;

    If IsUNCPath(GPT.DBPath) Then
    begin
      DebugProc('  DBPath: '+GPT.DBPath);
      DebugProc('UNC paths not supported.');
      FErrorCode:=255;
      Exit;
    end;

    TransactIsolationLevel:=tiReadCommitted;
    AutoCommit:=True;
    SQLHourGlass:=True;

    Database:=GPT.DBPath;
    If GPT.ServerName<>'' Then
    begin
      If Pos('/', GPT.ServerName)<>0 Then
      begin
        GPT.Port:=StrToIntEx(Copy(GPT.ServerName, Pos('/', GPT.ServerName)+1,
            Length(GPT.ServerName)));
        Delete(GPT.ServerName, Pos('/', GPT.ServerName), Length(GPT.ServerName));
      end;
      HostName:=GPT.ServerName;
      If GPT.Port=0 Then
        GPT.Port:=DefaultIBPort;
      DebugProc('  DBPath: '+GPT.ServerName+':'+GPT.DBPath);
    end
    Else
    begin
      DebugProc('  DBPath: '+GPT.DBPath);
    end;

    User:=GPT.DBUserName;
    DebugProc('  USER NAME='+GPT.DBUserName);

    If GPT.Port<>0 Then
      Port:=GPT.Port;

    If GPT.DBPassword<>'' Then
    begin
      DebugProc('  Password=******');
      Password:=GPT.DBPassword;
      LoginPrompt:=False;
    end
    Else
      LoginPrompt:=True;

    Protocol:=GPT.DBType;
    If GPT.LibPath<>'' Then
      LibraryLocation:=GPT.LibPath
    Else
      LibraryLocation:=DefaultLibraryLocation;

    GPT.ServerCodePage:=NormalizeEncoding(GPT.ServerCodePage);
    If GPT.ServerCodePage='' Then
    begin
      raise Exception.Create('Server code page not define!');
    end
    Else
      Properties.Append('lc_ctype='+UpperCase(GPT.ServerCodePage));
  end;
  {$ENDIF}
  {$IFDEF SQLdbIB}
  GPT.IBAll:=True;
  UniversalTransaction:=TTransaction.Create(Self);
  UniversalTransaction.Params.Clear;
  UniversalTransaction.Params.Append('nowait');
  UniversalTransaction.Params.Append('read_committed');
  UniversalTransaction.Params.Append('rec_version');
  UniversalTransaction.Action:=caCommit;
  UniversalTransaction.DataBase:=Self;
  Transaction:=UniversalTransaction;
// IBTransaction.Action:=TACommitRetaining;

  If GPT.LibPath<>'' Then
  begin
    FSQLDBLibraryLoader:=TSQLDBLibraryLoader.Create(Self);
    FSQLDBLibraryLoader.ConnectionType:='Firebird';
    FSQLDBLibraryLoader.LibraryName:=GPT.LibPath;
    FSQLDBLibraryLoader.Enabled:=True;
  end;

  If GPT.DBPath<>'' Then
  begin
    If Not FilenameIsAbsolute(GPT.DBPath) Then
      GPT.DBPath:=ExtractFilePath(ParamStr(0))+GPT.DBPath;

    if GPT.Port<>0 then
      Port:=GPT.Port;

    If GPT.ServerName<>'' Then
    begin
      DatabaseName:=GPT.DBPath;
      HostName:=GPT.ServerName;
      DebugProc('  DBPath: '+GPT.ServerName+':'+GPT.DBPath);
    end
    Else
    begin
      DatabaseName:=GPT.DBPath;
      HostName:='';
      DebugProc('  DBPath: '+GPT.DBPath);
    end;
    UserName:=GPT.DBUserName;
    DebugProc('  USER NAME='+GPT.DBUserName);
    If GPT.DBPassword<>'' Then
    begin
      Password:=GPT.DBPassword;
      LoginPrompt:=False;
    end
    Else
      LoginPrompt:=True;

    If GPT.ServerCodePage='' Then
      Charset:=DefaultCodePage
    Else
      Charset:=ReplaseCPtoWIN(GPT.ServerCodePage);

    Dialect:=GPT.SQLDialect;
  end;
  {$ENDIF}
  {$IFDEF SQLdb}
  DebugProc('Creating Connection...');
  If (PosEx(DBTypeFirebird, GPT.DBType)>0) or (PosEx(DBTypeInterbase, GPT.DBType)>0) then
  Begin
    GPT.IBAll:=True;
    GPT.DBType:=DBTypeFirebird;
  End;

  If Not Assigned(Transaction) Then
  Begin
    UniversalTransaction:=TTransaction.Create(Self);
    UniversalTransaction.Params.Clear;
    UniversalTransaction.Params.Append('nowait');
    UniversalTransaction.Params.Append('read_committed');
    If GPT.IBAll then
      UniversalTransaction.Params.Append('rec_version');
    UniversalTransaction.Action:=caCommit;
    UniversalTransaction.DataBase:=Self;
    Transaction:=UniversalTransaction;
  End
  Else
    UniversalTransaction:=Transaction;

  If GPT.LibPath<>'' Then
  begin
    FSQLDBLibraryLoader:=TSQLDBLibraryLoader.Create(Self);
    FSQLDBLibraryLoader.ConnectionType:=GPT.DBType;
    FSQLDBLibraryLoader.LibraryName:=GPT.LibPath;
    FSQLDBLibraryLoader.Enabled:=True;
  end;

  If GPT.DBPath<>'' Then
  begin
    If Not FilenameIsAbsolute(GPT.DBPath) Then
      GPT.DBPath:=ExtractFilePath(ParamStr(0))+GPT.DBPath;

    ConnectorType:=GPT.DBType;
    If GPT.ServerName<>'' Then
    begin
      DatabaseName:=GPT.DBPath;
      HostName:=GPT.ServerName;
      DebugProc('  DBPath: '+GPT.ServerName+':'+GPT.DBPath);
    end
    Else
    begin
      DatabaseName:=GPT.DBPath;
      HostName:='';
      DebugProc('  DBPath: '+GPT.DBPath);
    end;
    UserName:=GPT.DBUserName;
    DebugProc('  USER NAME='+GPT.DBUserName);
    If GPT.DBPassword<>'' Then
    begin
      Password:=GPT.DBPassword;
      LoginPrompt:=False;
    end
    Else
      LoginPrompt:=True;

    If GPT.ServerCodePage='' Then
      Charset:='utf8'
    Else
      Charset:=ReplaseCPtoWIN(GPT.ServerCodePage);

    UniversalTransaction.Database:=Self;
  end;
  {$ENDIF}
  {$IFDEF ODBC}
  if GPT.ServerCodePage='' then
    GPT.ServerCodePage:='utf8';

  If PosEx(DBTypeFirebird, GPT.DBType)>0 then
  Begin
    GPT.IBAll:=True;
    GPT.DBType:=DBTypeFirebird;
  End;
  UniversalTransaction:=TTransaction.Create(Self);
  UniversalTransaction.Params.Clear;
  UniversalTransaction.Params.Append('nowait');
  UniversalTransaction.Params.Append('read_committed');
  If GPT.IBAll then
    UniversalTransaction.Params.Append('rec_version');
  UniversalTransaction.Action:=caCommit;
  UniversalTransaction.DataBase:=Self;
  Transaction:=UniversalTransaction;

  If GPT.DataBaseName<>'' Then
  begin
    DatabaseName:=GPT.DataBaseName;
    DebugProc('  DSN: '+GPT.DataBaseName);

    UserName:=GPT.DBUserName;
    DebugProc('  USER NAME='+GPT.DBUserName);
    If GPT.DBPassword<>'' Then
    begin
      Password:=GPT.DBPassword;
      LoginPrompt:=False;
    end
    Else
      LoginPrompt:=True;

    If GPT.ServerCodePage='' Then
      Charset:='utf8'
    Else
      Charset:=ReplaseCPtoWIN(GPT.ServerCodePage);

    KeepConnection:=True;
  end;
  {$ENDIF}
  {$IFDEF SQLdbMySQL}
  if GPT.ServerCodePage='' then
    GPT.ServerCodePage:='utf8';

  GPT.MySQL:=True;
  UniversalTransaction:=TTransaction.Create(Self);
  UniversalTransaction.Params.Clear;
  UniversalTransaction.Params.Append('nowait');
  UniversalTransaction.Params.Append('read_committed');
  UniversalTransaction.Params.Append('rec_version');
  UniversalTransaction.Action:=caCommit;
  UniversalTransaction.DataBase:=Self;
  Transaction:=UniversalTransaction;
// IBTransaction.Action:=TACommitRetaining;

  If GPT.LibPath<>'' Then
  begin
    FSQLDBLibraryLoader:=TSQLDBLibraryLoader.Create(Self);
    FSQLDBLibraryLoader.ConnectionType:='MySQL 8.0';
    FSQLDBLibraryLoader.LibraryName:=GPT.LibPath;
    FSQLDBLibraryLoader.Enabled:=True;
  end;

  If (GPT.DataBaseName<>'') and (GPT.ServerName<>'') Then
  begin
    DatabaseName:=GPT.DataBaseName;
    DebugProc('  Schama: '+GPT.DataBaseName);

    if GPT.Port<>0 then
      Port:=GPT.Port;

    SkipLibraryVersionCheck:=True;
    UserName:=GPT.DBUserName;
    DebugProc('  USER NAME='+GPT.DBUserName);
    If GPT.DBPassword<>'' Then
    begin
      Password:=GPT.DBPassword;
      LoginPrompt:=False;
    end
    Else
      LoginPrompt:=True;

    If GPT.ServerCodePage='' Then
      Charset:='utf8'
    Else
      Charset:=ReplaseCPtoWIN(GPT.ServerCodePage);

    If GPT.ServerName<>'' Then
    begin
      HostName:=GPT.ServerName;
      DebugProc('  Server: '+GPT.ServerName);
    end;

    KeepConnection:=True;
  end;
  {$ENDIF}
  try
    DebugProc('Connect ...');
    Open;
    FErrorCode:=0;
    DebugProc('  ... OK');
  Except
    On E: Exception do
    begin
      DebugProc('  ... Fail');
      raise TDCLException.Create(-2, E.Message, True);
    end;
  end;
end;

procedure TDCLDBConnector.SetConnector(Query: TDCLDialogQuery);
begin
  {$IFDEF IBX}
  Query.DataBase:=Self;
  {$ENDIF}
  {$IFDEF ZEOS}
  Query.Connection:=Self;
  {$ENDIF}
  {$IFDEF SQLdbFamily}
  Query.DataBase:=Self;
  {$ENDIF}
  {$IFDEF TRANSACTIONDB}
  {$IFDEF SQLdbFamily}
  Query.Transaction:=Transaction;
  {$ENDIF}
  {$IFDEF IBX}
  Query.Transaction:=Self.DefaultTransaction;
  {$ENDIF}
  {$IFDEF IBXLaz}
  Query.AllowAutoActivateTransaction:=True;
  {$ENDIF}
  {$IFDEF ZEOS}
  Query.Transaction:=TDCLDBTransaction.Create(Self, trtRead);
  Query.UpdateTransaction:=TDCLDBTransaction.Create(Self, trtWrite);
  {$ENDIF}
  {$ENDIF}
end;

end.

