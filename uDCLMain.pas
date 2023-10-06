unit uDCLMain;
{$I DefineType.pas}

interface

uses
  {$IFDEF MSWINDOWS}
  Windows,
  {$ENDIF}
  Classes, SysUtils, Generics.Collections, Forms, ExtCtrls,
  uDCLTypes, uDCLForm, uDCLVariables, uDCLDBConnector, uDCLMenu, uDCLNotifier,
  uIDCLMain, uDCLFormsNotifier, uDCLConst;

type

  { TDCLMain }

  TDCLMain=class(TComponent, IDCLMain)
  private
    FMainForm: TForm;
    FForms: TList<TForm>;
    FVariables: TVariables;
    FDBConnector: TDCLDBConnector;
    FDCLMenu: TDCLMenu;
    LocalQuery: TDCLSimlyQuery;
    KillerDog: TTimer;
    FBusyMode: Boolean;
    FDCLNotifier: TDCLNotifier;

    procedure KillerForms(Sender: TObject);
    function GetDialogScript(DialogName: String): String;
    procedure CloseForm(Form: TDCLForm);

    procedure WriteBaseID;
    function ReadBaseID: String;

    function TestGlobalParamsTable: Boolean;
  public
    constructor Create; overload;
    destructor Destroy; override;

    procedure CloseAllDialogs;

    function GetVariables: TVariables;
    function GetForms: TList<TForm>;
    function GetDBConnector: TDCLDBConnector;

    procedure CreateMenu(MainForm: TForm);

    procedure OpenDialog(DialogName: String);
    procedure RunCommand(CommandName: String);
    procedure About;

    procedure Exit;

    function IsNeedLogin: Boolean;

    procedure RunSkriptFromFile(FileName: String);

    procedure NotifyForms(Action: TFormsNotifyAction);

    property DBConnector: TDCLDBConnector read FDBConnector;
    property Variables: TVariables read FVariables;
    property MainForm: TForm read FMainForm write FMainForm;
    property Forms: TList<TForm> read FForms;
  end;

implementation

uses
  uDCLConfig, uDCLCommand, uDCLDBStructure, uDCLMultiLang, fAbout,
  uDCLGlobalVariables, uDCLUtils, uDCLMessages, uDBUtils;

{ TDCLMain }

function TDCLMain.IsNeedLogin: Boolean;
begin
  Result:=False;

  LocalQuery.SQL.Text:='select * from '+UsersTable;
  LocalQuery.Open;
  Result:=not LocalQuery.IsEmpty;
  LocalQuery.Close;

  if Result and (GPT.DCLUserName<>'') and (GPT.EnterPass<>'') then
  begin
    LocalQuery.SQL.Text:='select * from '+UsersTable+' where lower('+UserNameField+')=lower(:UN) '+
      'and '+UserAdminField+'>:UL';
    LocalQuery.Prepare;
    LocalQuery.ParamByName('UN').AsString:=GPT.DCLUserName;
    LocalQuery.ParamByName('UL').AsInteger:=Ord(ulDeny);
    LocalQuery.Open;
    Result:=not ((GPT.EnterPass=LocalQuery.FieldByName(UserPassField).AsString) and not LocalQuery.IsEmpty);
    if not Result then
    begin
      GPT.UserID:=LocalQuery.FieldByName(UserIDField).AsString;
      GPT.AccessLevel:=TranslateDigitToUserLevel(LocalQuery.FieldByName(UserAdminField).AsInteger);
      GPT.DCLLongUserName:=LocalQuery.FieldByName(LongUserNameField).AsString;
      GPT.DCLUserName:=LocalQuery.FieldByName(UserNameField).AsString;
    end;
    LocalQuery.Close;
  end;
end;

procedure TDCLMain.RunSkriptFromFile(FileName: String);
begin

end;

procedure TDCLMain.NotifyForms(Action: TFormsNotifyAction);
begin

end;

procedure TDCLMain.KillerForms(Sender: TObject);
var
  ff: TForm;
begin
  FBusyMode:=True;
  For ff in FForms do
  Begin
    If Assigned(ff) then
      If (ff as TDCLForm).CloseAction=fcaClose then
        CloseForm(ff as TDCLForm);
  End;
  FBusyMode:=False;
end;

function TDCLMain.GetDialogScript(DialogName: String): String;
begin
  LocalQuery.Params.Clear;
  LocalQuery.SQL.Text:='select '+ScriptField+' from '+DCLTable+' where lower('+DCLNameField+') = lower(:NAME)';
  LocalQuery.ParamByName('NAME').AsString:=DialogName;
  LocalQuery.Open;

  Result:=LocalQuery.Fields[0].AsString;
  LocalQuery.Close;
end;

procedure TDCLMain.CloseForm(Form: TDCLForm);
begin
  Form.Release;
  FForms.Remove(Form);
  FreeAndNil(Form);
end;

procedure TDCLMain.WriteBaseID;
var
  guid:TGUID;
  sGuid:String;
  IsEmpty: Boolean;
begin
  if not GPT.NoParamsTable then
  begin
    LocalQuery.Params.Clear;
    LocalQuery.SQL.Text:='select count(*) from '+GPTTableName+' where lower('+GPTNameField+') = lower(:BID)';
    LocalQuery.ParamByName('BID').AsString:='BaseUID';
    LocalQuery.Open;
    IsEmpty:=LocalQuery.Fields[0].AsInteger=0;
    LocalQuery.Close;

    If IsEmpty then
    begin
      If CreateGUID(guid)=0 then
      Begin
        sGuid:=GUIDToString(guid);
        sGuid:=sGuid.Replace('-', '').Replace('{', '').Replace('}', '');
        GPT.BaseID:=sGuid;
        LocalQuery.SQL.Text:='insert into '+GPTTableName+'('+GPTNameField+', '+
          GPTValueField+') values(:BID, :BG)';
        LocalQuery.ParamByName('BID').AsString:='BaseUID';
        LocalQuery.ParamByName('BG').AsString:=sGuid;

        LocalQuery.ExecSQL;
      End;
    end;
  end;
end;

function TDCLMain.ReadBaseID: String;
begin
  Result:='';
  if not GPT.NoParamsTable and FDBConnector.Connected then
  begin
    LocalQuery.Params.Clear;
    LocalQuery.SQL.Text:='select * from '+GPTTableName+' where lower('+GPTNameField+') = lower(:BID)';
    LocalQuery.ParamByName('BID').AsString:='BaseUID';
    LocalQuery.Open;
    Result:=LocalQuery.FieldByName(GPTValueField).AsString;
    LocalQuery.Close;
    If Result='' then
    Begin
      WriteBaseID;
      Result:=ReadBaseID;
    End;
    GPT.BaseID:=Result;
  end;
end;

function TDCLMain.TestGlobalParamsTable: Boolean;
begin
  Result:=FDBConnector.Connected and not TableExist(FDBConnector, GPTTableName);
end;

constructor TDCLMain.Create;
var
  FDCLConfig: TDCLConfig;
  Params: TStringList;
begin
  {$IFDEF ADO}
  CoInitialize(nil);
  {$ENDIF}
  GPT.NoParamsTable:=False;

  Path:=ExtractFilePath(Application.ExeName);
  SetCurrentDir(Path);

  InitGetAppConfigDir;
  FDCLConfig:=TDCLConfig.Create;
  FVariables:=TVariables.Create;
  FForms:=TList<TForm>.Create;

  GPT.AccessLevel:=ulExecute;

  FDCLConfig.GetParamsStructure;

  InitLangEnv;

  LoadLangRes(LangName, Path);

  {$IFDEF MSWINDOWS}
  If GPT.OneCopy Then
  begin
    CreateMutex(nil, True, MemFileName);
    If GetLastError=ERROR_ALREADY_EXISTS Then
    begin
      ShowErrorMessage(1, GetDCLMessageString(msAppRunning));
      Halt;
    end;
  end;
  {$ENDIF}

  KillerDog:=TTimer.Create(Self);
  KillerDog.Interval:=KillerTimerInterval;
  KillerDog.OnTimer:=KillerForms;
  KillerDog.Enabled:=True;

  FormsNotifier:=TDCLFormsNotifier.Create(FForms);

  FDBConnector:=TDCLDBConnector.Create;
  if FDBConnector.Connected then
  begin
    LocalQuery:=TDCLSimlyQuery.Create(Self);
    FDBConnector.SetConnector(LocalQuery);

    GPT.NoParamsTable:=TestGlobalParamsTable;

    if not GPT.NoParamsTable then
    begin
      LocalQuery.SQL.Text:='select '+GPTNameField+', '+GPTValueField+' from '+GPTTableName;
      LocalQuery.Open;
      Params:=TStringList.Create;
      LocalQuery.First;
      While Not LocalQuery.Eof do
      begin
        Params.Append(LocalQuery.FieldByName(GPTNameField).AsString+'='+
            LocalQuery.FieldByName(GPTValueField).AsString);
        LocalQuery.Next;
      end;
      LocalQuery.Close;
      FDCLConfig.LoadExternalParams(Params);

      FDCLConfig.GetParamsStructure;

      ReadBaseID;
    end;
  end;

  {$IFDEF IBALL}
  GPT.IBAll:=True;
  {$ELSE}
  GPT.IBAll:=False;
  {$ENDIF}
  GPT.DebugMesseges:=False;
  GPT.OneCopy:=False;
  GPT.ExitCnf:=False;
  GPT.UseMessages:=True;
  GPT.DebugOn:=False;
  GPT.DialogsSettings:=True;
  GPT.Port:=0;
  {$IFDEF ZEOS}
  GPT.DBType:=DefaultDBType;
  {$ENDIF}
  GPT.UserLogging:=False;
  GPT.UserLoggingHistory:=False;
  {$IFDEF MSWINDOWS}
  GPT.Viewer:='notepad';
  {$ELSE}
  GPT.Viewer:='pluma';
  {$ENDIF}

  GPT.OfficeFormat:=ofMSO;
  GPT.OfficeDocumentFormat:=odfMSO2007;

  GPT.TimeFormat:=DefaultTimeFormat;
  GPT.DateFormat:=DefaultDateFormat;
  GPT.DateSeparator:=DefaultDateSeparator;
  GPT.TimeSeparator:=DefaultTimeSeparator;
  GPT.TimeStampFormat:=GPT.DateFormat+' '+GPT.TimeFormat;
{$IFDEF MSWINDOWS}
  SysUtils.GetFormatSettings;
{$ENDIF}
{$IFDEF FPC}
{$IFDEF UNIX}
  FormatSettings.DateSeparator:=GPT.DateSeparator;
  FormatSettings.ShortDateFormat:=GPT.DateFormat;
  FormatSettings.LongTimeFormat:=GPT.TimeFormat;
  FormatSettings.TimeSeparator:=GPT.TimeSeparator;
{$ENDIF}
{$ENDIF}
end;

destructor TDCLMain.Destroy;
begin
  CloseAllDialogs;
  inherited Destroy;
  if Assigned(FDCLMenu) then
    FreeAndNil(FDCLMenu);
  if Assigned(FormsNotifier) then
    FreeAndNil(FormsNotifier);
end;

procedure TDCLMain.CloseAllDialogs;
var
  ff: TForm;
begin
  FBusyMode:=True;
  For ff in FForms do
  Begin
    If Assigned(ff) then
      CloseForm(ff as TDCLForm);
  End;
  FBusyMode:=False;
end;

function TDCLMain.GetVariables: TVariables;
begin
  Result:=FVariables;
end;

function TDCLMain.GetForms: TList<TForm>;
begin
  Result:=FForms;
end;

function TDCLMain.GetDBConnector: TDCLDBConnector;
begin
  Result:=FDBConnector;
end;

procedure TDCLMain.CreateMenu(MainForm: TForm);
begin
  FMainForm:=MainForm;

  FDCLMenu:=TDCLMenu.Create(Self, FMainForm);

  {$IFNDEF NODCLMESSAGES}
  If GPT.UseMessages then
    FDCLNotifier:=TDCLNotifier.Create(Self);
  {$ENDIF}
end;

procedure TDCLMain.OpenDialog(DialogName: String);
var
  Command: TDCLCommand;
begin
  Command:=TDCLCommand.Create(Self, '', nil, nil);
  Command.OpenDialog(DialogName);
end;

procedure TDCLMain.RunCommand(CommandName: String);
var
  Command: TDCLCommand;
begin
  Command:=TDCLCommand.Create(Self, '', nil, nil);
  Command.RunCommandScript(CommandName);
end;

procedure TDCLMain.About;
var
  About: TAboutForm;
begin
  About:=TAboutForm.Create(Application, FDBConnector);
  About.ShowModal;
  About.Release;
end;

procedure TDCLMain.Exit;
begin
  Application.MainForm.Close;
end;

end.

