unit uDCLMain;
{$I DefineType.pas}

interface

uses
  {$IFDEF MSWINDOWS}
  Windows,
  {$ENDIF}
  Classes, SysUtils, Generics.Collections, Forms, ExtCtrls, LazFileUtils,
  Controls,
  uDCLTypes, uDCLForm, uDCLVariables, uDCLDBConnector, uDCLMenu, uDCLNotifier,
  uIDCLMain, uDCLConst, uDCLScriptSigner, uDCLImages;

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
    FScripts: TList<TDCLScriptItem>;
    FPicturesIndexes: TDictionary<TPicturesTypes, Integer>;
    FImages: TImageList;

    procedure KillerForms(Sender: TObject);
    function GetScriptText(ScriptName: String): TStringList;
    procedure CloseForm(Form: TDCLForm);
    procedure ReleaseForm(Form: TDCLForm);

    procedure WriteBaseID;
    function ReadBaseID: String;

    function TestGlobalParamsTable: Boolean;
    procedure CreateImageList;
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
    function GetImageList: TImageList;
    function GetImageIndex(PictureType: TPicturesTypes): Integer;
    function GetImageIndexes: TDictionary<TPicturesTypes, Integer>;

    function IsNeedLogin: Boolean;

    procedure NotifyForms(Action: TFormsNotifyAction);
    procedure NotifyForm(Form: TForm; Action: TFormsNotifyAction);

    procedure LoadScriptsFromFile(FileName: String; Run: Boolean);
    function CheckSigned(Package: TStringList): Boolean;
    procedure ClearScriptPool;

    property DBConnector: TDCLDBConnector read FDBConnector;
    property Variables: TVariables read FVariables;
    property MainForm: TForm read FMainForm write FMainForm;
    property Forms: TList<TForm> read FForms;
    property ImageList: TImageList read FImages;
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

procedure TDCLMain.LoadScriptsFromFile(FileName: String; Run: Boolean);
var
  RawPackage: TFileStream;
  Package: TStringList;
  PackageName: String;
  FLoadedScripts: TDictionary<String, TDCLScriptItem>;
  I: TPair<String, TDCLScriptItem>;
  RunItem: TDCLScriptItem;
  Command: TDCLCommand;
  PackageInfo: TPackageInfo;
  c: Integer;
begin
  if FileExists(FileName) then
  begin
    PackageName:=ExtractFileNameOnly(FileName);
    RawPackage:=TFileStream.Create(FileName, fmOpenRead);

    Package:=DecodePackage(RawPackage);
    RawPackage.Free;
    PackageInfo:=TPackageInfo.Create;
    PackageInfo.PackageName:=PackageName;
    PackageInfo.PackageHash:=GetPackageSignedHash(Package);

    if CheckSigned(Package) then
    begin
      FLoadedScripts:=DisassemblyPackage(Package);

      for I in FLoadedScripts do
      begin
        FScripts.Add(I.Value);
      end;

      if Run then
      begin
        c:=FScripts.Count;
        for RunItem in FScripts do
        begin
          if RunItem.RunOnStart or (c=1) then
          begin
            Package:=TStringList.Create;
            Package.LoadFromStream(RunItem.ScriptText);

            if RunItem.RunType=1 then
            begin
              Command:=TDCLCommand.Create(Self, '', nil, nil);
              Command.RunCommandScript(RunItem.ScriptName);
            end
            else
            begin
              OpenDialog(RunItem.ScriptName);
            end;

            break;
          end;
        end;
      end;
    end;
  end;
end;

function TDCLMain.CheckSigned(Package: TStringList): Boolean;
begin
  Result:=False;
  LocalQuery.Params.Clear;
  LocalQuery.SQL.Text:='select * from '+UsersTable+' where '+UserAdminField+'=:UL';
  LocalQuery.Prepare;
  LocalQuery.ParamByName('UL').AsInteger:=Ord(ulDeveloper);
  LocalQuery.Open;
  LocalQuery.First;
  while not LocalQuery.EOF do
  begin
    if CheckPackage(LocalQuery.FieldByName('DCL_USER_NAME').AsString, LocalQuery.FieldByName('DCL_USER_PASS').AsString, Package) then
    begin
      Result:=True;
      break;
    end;

    LocalQuery.Next;
  end;
  LocalQuery.Close;
end;

procedure TDCLMain.ClearScriptPool;
begin
  FScripts.Clear;
end;

procedure TDCLMain.NotifyForms(Action: TFormsNotifyAction);
var
  F: TForm;
begin
  for F in FForms do
  begin
    NotifyForm(F as TDCLForm, Action);
  end;
end;

procedure TDCLMain.NotifyForm(Form: TForm; Action: TFormsNotifyAction);
begin
  case Action of
  fnaMinimize: Form.WindowState:=wsMinimized;
  fnaMaximaze: Form.WindowState:=wsMaximized;
  fnaRefresh: (Form as TDCLForm).RefreshForm;
  fnaClose: Form.Close;
  fnaHide: Form.Hide;
  fnaShow: begin
    if not Form.Showing then
      Form.Show;
    Form.SetFocus;
    end;
  end;
end;

procedure TDCLMain.KillerForms(Sender: TObject);
var
  ff: TForm;
begin
  FBusyMode:=True;
  For ff in FForms do
  Begin
    If Assigned(ff) then
    begin
      if ff is TDCLForm then
      begin
        If (ff as TDCLForm).CloseAction=fcaRelease then
        begin
          ReleaseForm(ff as TDCLForm);
        end;
      end;
    end;
  End;
  FBusyMode:=False;
end;

procedure TDCLMain.CloseForm(Form: TDCLForm);
begin
  Form.Close;
end;

procedure TDCLMain.ReleaseForm(Form: TDCLForm);
begin
  FForms.Remove(Form);
  Form.Release;
  FreeAndNil(Form);
end;

function TDCLMain.GetScriptText(ScriptName: String): TStringList;
var
  Empty: Boolean;
  RunItem: TDCLScriptItem;
begin
  Result:=TStringList.Create;
  LocalQuery.Params.Clear;
  LocalQuery.SQL.Text:='select '+ScriptField+' from '+DCLTable+' where lower('+DCLNameField+') = lower(:sn)';
  LocalQuery.ParamByName('sn').AsString:=ScriptName;
  LocalQuery.Open;
  LocalQuery.First;
  Empty:=LocalQuery.IsEmpty;
  Result.Text:=LocalQuery.Fields[0].AsString;
  LocalQuery.Close;

  if Empty then
  begin
    for RunItem in FScripts do
    begin
      if RunItem.ScriptName.ToLower=ScriptName.ToLower then
      begin
        Result.Clear;
        RunItem.ScriptText.Position:=0;
        Result.LoadFromStream(RunItem.ScriptText);
        break;
      end;
    end;
  end;
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

procedure TDCLMain.CreateImageList;
  procedure PictureAdd(PictureType: TPicturesTypes);
  begin
    FPicturesIndexes.Add(PictureType, FImages.Add(DrawBMPButton(PictureType), nil));
  end;
begin
  FPicturesIndexes:=TDictionary<TPicturesTypes, Integer>.Create;

  FImages:=TImageList.Create(Self);
  FImages.Scaled:=True;
  FImages.RegisterResolutions([16, 24, 48]);

  PictureAdd(ptFind);
  PictureAdd(ptStructure);
  PictureAdd(ptPrint);

  PictureAdd(ptDownArrow);
  PictureAdd(ptUpArrow);

  PictureAdd(ptFindCurrCell);
  PictureAdd(ptClearAllFind);

  PictureAdd(ptCopy);
  PictureAdd(ptCut);
  PictureAdd(ptPaste);
  PictureAdd(ptUndo);

  PictureAdd(ptTools);

  PictureAdd(ptLoad);
  PictureAdd(ptClear);
  PictureAdd(ptSave);

  PictureAdd(ptGridFilter);
end;

constructor TDCLMain.Create;
var
  FDCLConfig: TDCLConfig;
  Params: TStringList;
begin
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
  CreateImageList;

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

  FScripts:=TList<TDCLScriptItem>.Create;

  {$IFDEF IBALL}
  GPT.IBAll:=True;
  {$ELSE}
  GPT.IBAll:=False;
  {$ENDIF}
  GPT.DebugMesseges:=False;
  GPT.OneCopy:=False;
  GPT.ExitCnf:=False;
  GPT.UseMessages:=True;
  GPT.DialogsSettings:=True;
  GPT.Port:=0;
  {$IFDEF ZEOS}
  GPT.DBType:=DefaultDBType;
  {$ENDIF}
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
{$IFDEF UNIX}
  FormatSettings.DateSeparator:=GPT.DateSeparator;
  FormatSettings.ShortDateFormat:=GPT.DateFormat;
  FormatSettings.LongTimeFormat:=GPT.TimeFormat;
  FormatSettings.TimeSeparator:=GPT.TimeSeparator;
{$ENDIF}
end;

destructor TDCLMain.Destroy;
begin
  CloseAllDialogs;
  inherited Destroy;
  if Assigned(FDCLMenu) then
    FreeAndNil(FDCLMenu);
end;

procedure TDCLMain.CloseAllDialogs;
var
  ff: TForm;
begin
  FBusyMode:=True;
  For ff in FForms do
  Begin
    If Assigned(ff) and ((ff as TDCLForm).CloseAction=fcaNone) then
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

function TDCLMain.GetImageList: TImageList;
begin
  Result:=FImages;
end;

function TDCLMain.GetImageIndex(PictureType: TPicturesTypes): Integer;
begin
  if FPicturesIndexes.ContainsKey(PictureType) then
    Result:=FPicturesIndexes[PictureType]
  else
    Result:=-1;
end;

function TDCLMain.GetImageIndexes: TDictionary<TPicturesTypes, Integer>;
begin
  Result:=FPicturesIndexes;
end;

end.

