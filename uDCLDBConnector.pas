unit uDCLDBConnector;
{$I DefineType.pas}

interface

uses
  Classes, SysUtils, DB, Forms,
  {$IFDEF ADO}
    ActiveX, ADODB, ADOConst, ADOInt,
  {$ENDIF}
  {$IFDEF FPC}
    {$IFDEF IBX}
      IB, IBDatabase, IBTable, IBCustomDataSet, IBHeader, IBSQL, IBQuery,
    {$ENDIF}
  {$ELSE}
    {$IFDEF IBX}
      IBX.IBDatabase, IBX.IBTable, IBX.IBCustomDataSet, IBX.IBHeader, IBX.IBSQL, IBX.IBQuery,
      IBX.IBVisualConst, IBX.IBXConst,
    {$ENDIF}
  {$ENDIF}
  {$IFDEF ZEOS}
    ZDbcIntfs, // ZConnection, ZDataset, ZSqlUpdate,
  {$ENDIF}
  {$IFDEF SQLdbFamily}
    SQLDB, SQLDBLib,
  {$ENDIF}
  {$IFDEF FPC}
    FileUtil, LazUTF8, LConvEncoding, {$IFDEF ZVComponents}ZVDateTimePicker, {$ENDIF}
  {$ENDIF}
  uDCLData, uDCLConst, uDCLTypes, uDCLDebug, uDCLUtils, uSystemUtils;

type
  { TDCLDBConnector }

  TDCLDBConnector=class(TDBConnector)
  private
    FErrorCode, ConnectErrorCode: Integer;
{$IFDEF FPC}{$IFDEF SQLdbFamily}
    FSQLDBLibraryLoader: TSQLDBLibraryLoader;
{$ENDIF}{$ENDIF}
{$IFDEF TRANSACTIONDB}
    IBTransaction: TTransaction;
{$ENDIF}
    ///SQLMon: TDCLSQLMon;
    FGPT: TGPT;

  public
    constructor Create(GPT: TGPT); overload;

    procedure SetConnector(Query: TDCLDialogQuery);
    {$IFDEF TRANSACTIONDB}
    function NewTransaction(RW:TTransactionType): TTransaction;
    {$ENDIF}

    property ErrorCode: Integer read FErrorCode;
  end;


implementation

uses
  uDCLGlobalVariables;

{ TDCLDBConnector }

constructor TDCLDBConnector.Create(GPT: TGPT);
begin
  FGPT:=GPT;
  inherited Create(Application);
  Name:='DCL_DBConnector1';

  {$IFDEF ADO}
    If Length(GPT.ConnectionString)>20 Then
    begin
      If CompareString(GPT.DBType, DBTypeFirebird) then
        GPT.IBAll:=True;

      GPT.NewConnectionString:='';
      FDBLogOn.ConnectionString:=GPT.ConnectionString;
      FDBLogOn.LoginPrompt:=False;

      try
        If FDBLogOn.Properties.Count>0 Then
          FDBLogOn.Open;
        Result:=0;
        ConnectErrorCode:=0;
      Except
        On E: Exception do
        begin
          DebugProc('  ... Fail');
          ConnectErrorCode:=255;
          ShowErrorMessage(0, GetDCLMessageString(msConnectDBError)+' 0000 / '+
                E.Message);
          FErrorCode:=255;
        end;
      end;
    end
    Else
    begin
      ConnectErrorCode:=255;
      Result:=255;
      ShowErrorMessage(0, GetDCLMessageString(msConnectionStringIncorrect)+
            ' 0100');
    end;
  {$ENDIF}
  {$IFDEF IBX}
    GPT.NewDBUserName:='';
    GPT.IBAll:=True;

    If Not Assigned(DefaultTransaction) Then
    begin
      IBTransaction:=TTransaction.Create(nil);
      IBTransaction.Params.Clear;
      IBTransaction.Params.Append('nowait');
      IBTransaction.Params.Append('read_committed');
      IBTransaction.Params.Append('rec_version');
      IBTransaction.DefaultAction:=TACommit;
      {$IFNDEF FPC}
      IBTransaction.AllowAutoStart:=True;
      {$ENDIF}
      IBTransaction.DefaultDataBase:=Self;
      DefaultTransaction:=IBTransaction;
    end
    Else
      IBTransaction:=DefaultTransaction;

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
          //ShowErrorMessage(0, 'UNC '+GetDCLMessageString(msPathsNotSupported)+'.');
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

          IBTransaction.DefaultAction:=TACommit; // Retaining;
          IBTransaction.DefaultDataBase:=Self;
          DefaultTransaction:=IBTransaction;

          DebugProc('  ... OK');
          ConnectErrorCode:=0;
        Except
          On E: Exception do
          begin
            DebugProc('  ... Fail');
            ConnectErrorCode:=255;
            //ShowErrorMessage(0, GetDCLMessageString(msConnectDBError)+' 0000 / '+E.Message);
          end;
        end;
      end;
    end
    Else
      FErrorCode:=0;
  {$ENDIF}
  {$IFDEF ZEOS}
    GPT.NewDBUserName:='';

    If Not FDBLogOn.Connected Then
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
        ShowErrorMessage(0, 'UNC '+GetDCLMessageString(msPathsNotSupported)+'.');
        Result:=255;
        Exit;
      end;

      GPT.NewDBUserName:='';
      FDBLogOn.AutoEncodeStrings:=True;
      FDBLogOn.TransactIsolationLevel:=tiReadCommitted;
      FDBLogOn.AutoCommit:=True;
      FDBLogOn.SQLHourGlass:=True;

      FDBLogOn.Database:=GPT.DBPath;
      If GPT.ServerName<>'' Then
      begin
        If Pos('/', GPT.ServerName)<>0 Then
        begin
          GPT.Port:=StrToIntEx(Copy(GPT.ServerName, Pos('/', GPT.ServerName)+1,
              Length(GPT.ServerName)));
          Delete(GPT.ServerName, Pos('/', GPT.ServerName), Length(GPT.ServerName));
        end;
        FDBLogOn.HostName:=GPT.ServerName;
        If GPT.Port=0 Then
          GPT.Port:=DefaultIBPort;
        DebugProc('  DBPath: '+GPT.ServerName+':'+GPT.DBPath);
      end
      Else
      begin
        DebugProc('  DBPath: '+GPT.DBPath);
      end;

      FDBLogOn.User:=GPT.DBUserName;
      DebugProc('  USER NAME='+GPT.DBUserName);

      If GPT.Port<>0 Then
        FDBLogOn.Port:=GPT.Port;

      If GPT.DBPassword<>'' Then
      begin
        DebugProc('  Password=******');
        FDBLogOn.Password:=GPT.DBPassword;
        FDBLogOn.LoginPrompt:=False;
      end
      Else
        FDBLogOn.LoginPrompt:=True;

      FDBLogOn.Protocol:=GPT.DBType;
      If GPT.LibPath<>'' Then
        FDBLogOn.LibraryLocation:=GPT.LibPath
      Else
        FDBLogOn.LibraryLocation:=DefaultLibraryLocation;

  {$IFDEF FPC}
      GPT.ServerCodePage:=NormalizeEncoding(GPT.ServerCodePage);
  {$ENDIF}
      If GPT.ServerCodePage='' Then
      begin
        raise Exception.Create('Server code page not define!');
      end
      Else
        FDBLogOn.Properties.Append('lc_ctype='+UpperCase(GPT.ServerCodePage));

      try
        DebugProc('Connected...');
        FDBLogOn.Connect;
        DebugProc('  ... OK');
        FErrorCode:=0;
        ConnectErrorCode:=0;
      Except
        On E: Exception do
        begin
          DebugProc('  ... Fail');
          ConnectErrorCode:=255;
          ShowErrorMessage(0, GetDCLMessageString(msConnectDBError)+' 0000 / '+
                E.Message);
          FErrorCode:=255;
        end;
      end;
    end;
  {$ENDIF}
  {$IFDEF SQLdbIB}
    ///DebugProc('Creating Connection...');
    Charset:='UTF8';

    if GPT.ServerCodePage='' then
      GPT.ServerCodePage:='utf8';

    GPT.IBAll:=True;
    IBTransaction:=TTransaction.Create(Self);
    IBTransaction.Params.Clear;
    IBTransaction.Params.Append('nowait');
    IBTransaction.Params.Append('read_committed');
    IBTransaction.Params.Append('rec_version');
    IBTransaction.Action:=caCommit;
    IBTransaction.DataBase:=Self;
    Transaction:=IBTransaction;
  // IBTransaction.Action:=TACommitRetaining;

    If GPT.LibPath<>'' Then
    begin
      FSQLDBLibraryLoader:=TSQLDBLibraryLoader.Create(Self);
      FSQLDBLibraryLoader.ConnectionType:='Firebird';
      FSQLDBLibraryLoader.LibraryName:=GPT.LibPath;
      FSQLDBLibraryLoader.Enabled:=True;
    end;

    If Not Connected Then
    begin
      If GPT.DBPath<>'' Then
      begin
        If Not IsFullPAth(GPT.DBPath) Then
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
          DebugProc('  ... OK');
          FErrorCode:=0;
          ConnectErrorCode:=0;
        Except
          On E: Exception do
          begin
            DebugProc('  ... Fail');
            ConnectErrorCode:=255;
            {ShowErrorMessage(0, GetDCLMessageString(msConnectDBError)+' 0000 / '+
                  E.Message);}
            FErrorCode:=255;
          end;
        end;
      end;
    end
    else
      FErrorCode:=0;
  {$ENDIF}
  {$IFDEF SQLdb}
    DebugProc('Creating Connection...');
    FDBLogOn.Charset:='UTF8';

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
    If Not Assigned(FDBLogOn.Transaction) Then
    Begin
      IBTransaction:=TTransaction.Create(nil);
      IBTransaction.Params.Clear;
      IBTransaction.Params.Append('nowait');
      IBTransaction.Params.Append('read_committed');
      If GPT.IBAll then
        IBTransaction.Params.Append('rec_version');
      IBTransaction.Action:=caCommit;
      IBTransaction.DataBase:=FDBLogOn;
      FDBLogOn.Transaction:=IBTransaction;
    End
    Else
      IBTransaction:=FDBLogOn.Transaction;

    If Not FDBLogOn.Connected Then
    begin
      If GPT.DBPath<>'' Then
      begin
        If Not IsFullPAth(GPT.DBPath) Then
          GPT.DBPath:=ExtractFilePath(Application.ExeName)+GPT.DBPath;

        FDBLogOn.ConnectorType:=GPT.DBType;
        If GPT.ServerName<>'' Then
        begin
          FDBLogOn.DatabaseName:=GPT.DBPath;
          FDBLogOn.HostName:=GPT.ServerName;
          DebugProc('  DBPath: '+GPT.ServerName+':'+GPT.DBPath);
        end
        Else
        begin
          FDBLogOn.DatabaseName:=GPT.DBPath;
          FDBLogOn.HostName:='';
          DebugProc('  DBPath: '+GPT.DBPath);
        end;
        FDBLogOn.UserName:=GPT.DBUserName;
        DebugProc('  USER NAME='+GPT.DBUserName);
        If GPT.DBPassword<>'' Then
        begin
          FDBLogOn.Password:=GPT.DBPassword;
          FDBLogOn.LoginPrompt:=False;
        end
        Else
          FDBLogOn.LoginPrompt:=True;

        If GPT.ServerCodePage='' Then
          FDBLogOn.Charset:='utf8'
        Else
          FDBLogOn.Charset:=ReplaseCPtoWIN(GPT.ServerCodePage);

        IBTransaction.Database:=FDBLogOn;
        try
          DebugProc('Connected...');
          FDBLogOn.Open;
          DebugProc('  ... OK');
          Result:=0;
          ConnectErrorCode:=0;
        Except
          On E: Exception do
          begin
            DebugProc('  ... Fail');
            ConnectErrorCode:=255;
            ShowErrorMessage(0, GetDCLMessageString(msConnectDBError)+' 0000 / '+
                  E.Message);
            Result:=255;
          end;
        end;
      end;
    end
    else
      Result:=0;
  {$ENDIF}
end;

procedure TDCLDBConnector.SetConnector(Query: TDCLDialogQuery);
begin
  {$IFDEF ADO}
  Query.Connection:=Self;
  {$ENDIF}
  {$IFDEF IBX}
  Query.DataBase:=Self;
  {$ENDIF}
  {$IFDEF ZEOS}
  Query.DataBase:=Self;
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
  {$ENDIF}
end;

{$IFDEF TRANSACTIONDB}
function TDCLDBConnector.NewTransaction(RW: TTransactionType): TTransaction;
begin
  Result:=TTransaction.Create(Self);
  {$IFDEF IBX}
  Result.DefaultDatabase:=Self;
  Result.DefaultAction:=TACommit;
  {$ENDIF}
  {$IFDEF SQLdbFamily}
  Result.Database:=Self;
  Result.Action:=caCommit;
  {$ENDIF}
  Result.Params.Clear;
  Case RW of
  trtWrite:Begin
    Result.Params.Append('write');
  End;
  trtRead:Begin
    Result.Params.Append('read');
  End;
  End;
  Result.Params.Append('nowait');
  Result.Params.Append('read_committed');
  If GPT.IBAll then
    Result.Params.Append('rec_version');
end;
{$ENDIF}

end.

