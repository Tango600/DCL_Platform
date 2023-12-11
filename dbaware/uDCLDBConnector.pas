unit uDCLDBConnector;
{$I DefineType.pas}

interface

uses
  Classes, SysUtils, Forms,
  {$IFDEF IBX}
  IB, IBDatabase, IBCustomDataSet,
  {$ENDIF}
  {$IFDEF ZEOS}
  ZDbcIntfs,
  {$ENDIF}
  {$IFDEF SQLdbFamily}
  SQLDB, {$IFDEF IBALL}SQLDBLib,{$ENDIF}
  {$ENDIF}
  FileUtil, LazUTF8,
  uDCLData, uDCLConst, uDCLDBAwareTypes, uDCLDebug, uDCLUtils;

type
  { TDCLDBConnector }

  TDCLDBConnector=class(TDBConnector)
  private
    FErrorCode: Integer;
{$IFDEF SQLdbFamily}
  {$IFDEF IBALL}
    FSQLDBLibraryLoader: TSQLDBLibraryLoader;
  {$ENDIF}
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
  uSystemUtils, uDCLGlobalVariables;

{ TDCLDBConnector }

constructor TDCLDBConnector.Create;
begin
  inherited Create(Application);
  Name:='DCL_DBConnector1';
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

  If Not Connected Then
  begin
    If GPT.DBPath<>'' Then
    begin
      {$IFDEF FPC}
      If GPT.LibPath<>'' Then
        FirebirdLibraryPathName:=GPT.LibPath
      Else
        FirebirdLibraryPathName:=DefaultLibraryLocation;
      {$ENDIF}

      Params.Clear;
      If Not IsFullPAth(GPT.DBPath) Then
        GPT.DBPath:=ExtractFilePath(Application.ExeName)+GPT.DBPath;

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
      try
        DebugProc('Connected...');
        Open;

        UniversalTransaction.DefaultAction:=TACommit; // Retaining;
        UniversalTransaction.DefaultDataBase:=Self;
        DefaultTransaction:=UniversalTransaction;

        FErrorCode:=0;
        DebugProc('  ... OK');
      Except
        On E: Exception do
        begin
          DebugProc('  ... Fail');
        end;
      end;
    end;
  end;
  {$ENDIF}
  {$IFDEF ZEOS}
  If Not Connected Then
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

    If Not IsFullPAth(GPT.DBPath) Then
      GPT.DBPath:=ExtractFilePath(Application.ExeName)+GPT.DBPath;

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

    try
      DebugProc('Connected...');
      Connect;
      DebugProc('  ... OK');
      FErrorCode:=0;
    Except
      On E: Exception do
      begin
        DebugProc('  ... Fail');
      end;
    end;
  end;
  {$ENDIF}
  {$IFDEF SQLdbIB}
  if GPT.ServerCodePage='' then
    GPT.ServerCodePage:='utf8';

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
    If Not IsFullPath(GPT.DBPath) Then
      GPT.DBPath:=ExtractFilePath(Application.ExeName)+GPT.DBPath;

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

    Dialect:=GPT.SQLDialect;
    try
      DebugProc('Connected...');
      Open;
      FErrorCode:=0;
      DebugProc('  ... OK');
    Except
      On E: Exception do
      begin
        DebugProc('  ... Fail');
      end;
    end;
  end;
  {$ENDIF}
  {$IFDEF SQLdb}
  DebugProc('Creating Connection...');
  If PosEx(DBTypeFirebird, GPT.DBType)>0 then
  Begin
    GPT.IBAll:=True;
    GPT.DBType:=DBTypeFirebird;
  End;
  If PosEx(DBTypeInterbase, GPT.DBType)>0 then
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

  If Not Connected Then
  begin
    If GPT.DBPath<>'' Then
    begin
      If Not IsFullPAth(GPT.DBPath) Then
        GPT.DBPath:=ExtractFilePath(Application.ExeName)+GPT.DBPath;

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
      try
        DebugProc('Connected...');
        Open;
        FErrorCode:=0;
        DebugProc('  ... OK');
      Except
        On E: Exception do
        begin
          DebugProc('  ... Fail');
        end;
      end;
    end;
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
    try
      DebugProc('Connected...');
      Open;
      FErrorCode:=0;
      DebugProc('  ... OK');
    Except
      On E: Exception do
      begin
        DebugProc('  ... Fail');
      end;
    end;
  end;
  {$ENDIF}
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

