unit uDCLMain;
{$I DefineType.pas}

interface

uses
  {$IFDEF MSWINDOWS}
  Windows,
  {$ENDIF}
  Classes, SysUtils, Generics.Collections, Forms, ExtCtrls, LazFileUtils,
  Controls,
  uDCLDBAwareTypes, uDCLForm, uDCLVariables, uDCLDBConnector, uDCLMenu, uDCLNotifier,
  uIDCLMain, uDCLConst, uDCLScriptsPackage, uDCLImages;

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
    FPackages: TList<TPackageInfo>;
    FScripts: TList<TDCLScriptItem>;
    FPicturesIndexes: TDictionary<TPicturesTypes, Integer>;
    FImages: TImageList;

    procedure KillerForms(Sender: TObject);
    function GetScriptText(ScriptName: String): TStringList;
    procedure CloseForm(Form: TForm);
    procedure ReleaseForm(Form: TForm);

    procedure WriteBaseID;
    function ReadBaseID: String;

    function TestGlobalParamsTable: Boolean;
    procedure CreateImageList;

    function LoadPackage(FileName: String): TDCLScriptsPackage;
    procedure UpdateFromPackages(PackagePath: String);
  public
    constructor Create; overload;
    destructor Destroy; override;

    procedure CloseAllDialogs;

    procedure Update;

    function GetVariables: TVariables;
    function GetForms: TList<TForm>;
    function GetDBConnector: TDCLDBConnector;

    procedure CreateMenu(MainForm: TForm);

    procedure OpenDialog(DialogName: String; Host: Boolean);
    procedure RunCommandScript(CommandName: String);
    procedure About;

    procedure ExitApp;
    function GetImageList: TImageList;
    function GetImageIndex(PictureType: TPicturesTypes): Integer;
    function GetImageIndexes: TDictionary<TPicturesTypes, Integer>;

    function IsNeedLogin: Boolean;

    procedure NotifyForms(Action: TFormsNotifyAction);
    procedure NotifyForm(Form: TForm; Action: TFormsNotifyAction);

    procedure LoadPackageFromFile(FileName: String; Run: Boolean);
    function CheckSigned(Package: TDCLScriptsPackage): Boolean;
    procedure ClearScriptPool;
    function GetLoadedScripts: TList<TDCLScriptItem>;
    function GetPackages: TList<TPackageInfo>;

    property DBConnector: TDCLDBConnector read FDBConnector;
    property Variables: TVariables read FVariables;
    property MainForm: TForm read FMainForm write FMainForm;
    property Forms: TList<TForm> read FForms;
    property ImageList: TImageList read FImages;
  end;

implementation

uses
  uDCLConfig, uDCLCommand, uDCLDBStructure, uDCLMultiLang, fAbout, uDBUtils,
  uDCLGlobalVariables, uDCLUtils, uDCLMessages, uStringParams,
  uDCLUpdaterPackage;

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

procedure TDCLMain.LoadPackageFromFile(FileName: String; Run: Boolean);
var
  Package: TDCLScriptsPackage;
  I: TDCLScriptItem;
  RunItem: TDCLScriptItem;
  Command: TDCLCommand;
  c: Integer;
  Files: TStringList;
  S, fn: String;
begin
  Files:=TStringList.Create;
  if ParamsCount(FileName)=1 then
  begin
    Files.Append(FileName);
  end
  else
  begin
    for c:=1 to ParamsCount(FileName) do
    begin
      Files.Append(GetParam(FileName, c));
    end;
  end;

  for S in Files do
  begin
    if NoFileExt(S) then
      fn:=S+PackagesFileExt
    else
      fn:=S;

    if FileExists(fn) then
    begin
      Package:=LoadPackage(fn);

      if not Package.PackageInfo.ForUpdate then
      begin
        if CheckSigned(Package) then
        begin
          if Package.PackageInfo.Name='' then
            Package.PackageInfo.Name:=ExtractFileNameOnly(fn);

          FPackages.Add(Package.PackageInfo);

          for I in Package.Scripts do
          begin
            if not I.SQL then
              FScripts.Add(I);
          end;

          if Run then
          begin
            c:=FScripts.Count;
            for RunItem in FScripts do
            begin
              if (Run or Package.PackageInfo.RunOnStart) and ((RunItem.RunType<>rtNone) or (c=1)) then
              begin
                if RunItem.RunType=rtCommand then
                begin
                  Command:=TDCLCommand.Create(Self, Self, '', nil, nil);
                  Command.RunCommandScript(RunItem.ScriptName);
                end
                else
                begin
                  OpenDialog(RunItem.ScriptName, False);
                end;

                break;
              end;
            end;
          end;
        end
        else
        begin
          ShowErrorMessage(0, GetDCLMessageString(msPackageSignNotValid));
        end;
      end
      else
      begin
        ShowErrorMessage(0, GetDCLMessageString(msCantOpenForUpdatePackage));
      end;

      FreeAndNil(Package);
    end;
  end;
  FreeAndNil(Files);
end;

function TDCLMain.CheckSigned(Package: TDCLScriptsPackage): Boolean;
begin
  Result:=False;
  LocalQuery.Params.Clear;
  LocalQuery.SQL.Text:='select * from '+UsersTable+' where '+UserAdminField+'>=:UL';
  LocalQuery.Prepare;
  LocalQuery.ParamByName('UL').AsInteger:=Ord(ulSigner);
  LocalQuery.Open;
  LocalQuery.First;
  while not LocalQuery.EOF do
  begin
    if Package.CheckPackage(LocalQuery.FieldByName(UserNameField).AsString, LocalQuery.FieldByName(UserPassField).AsString) then
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

function TDCLMain.GetLoadedScripts: TList<TDCLScriptItem>;
begin
  Result:=FScripts;
end;

function TDCLMain.GetPackages: TList<TPackageInfo>;
begin
  Result:=FPackages;
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
          ReleaseForm(ff);
        end;
      end;
    end;
  End;
  FBusyMode:=False;
end;

procedure TDCLMain.CloseForm(Form: TForm);
begin
  Form.Close;
end;

procedure TDCLMain.ReleaseForm(Form: TForm);
begin
  FForms.Remove(Form);
  Form.Release;
  FreeAndNil(Form);
end;

function TDCLMain.GetScriptText(ScriptName: String): TStringList;
var
  RunItem: TDCLScriptItem;
begin
  Result:=TStringList.Create;

  for RunItem in FScripts do
  begin
    if not RunItem.SQL and (RunItem.ScriptName.ToLower=ScriptName.ToLower) then
    begin
      Result.Clear;
      RunItem.ScriptText.Position:=0;
      Result.LoadFromStream(RunItem.ScriptText);
      Exit;
    end;
  end;

  LocalQuery.Params.Clear;
  LocalQuery.SQL.Text:='select '+ScriptField+' from '+DCLTable+' where lower('+DCLNameField+') = lower(:sn)';
  LocalQuery.ParamByName('sn').AsString:=ScriptName;
  LocalQuery.Open;
  LocalQuery.First;
  Result.Text:=LocalQuery.Fields[0].AsString;
  LocalQuery.Close;
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
    LocalQuery.ParamByName('BID').AsString:=BaiseUIDParamName;
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
        LocalQuery.ParamByName('BID').AsString:=BaiseUIDParamName;
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
    LocalQuery.ParamByName('BID').AsString:=BaiseUIDParamName;
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

function TDCLMain.LoadPackage(FileName: String): TDCLScriptsPackage;
var
  RawPackage: TFileStream;
begin
  Result:=nil;
  if FileExists(FileName) then
  begin
    RawPackage:=TFileStream.Create(FileName, fmOpenRead);

    Result:=TDCLScriptsPackage.Create;
    Result.Load(RawPackage);
    RawPackage.Free;
  end;
end;

procedure TDCLMain.UpdateFromPackages(PackagePath: String);
var
  SRec: TSearchRec;
  retval: Integer;

  procedure Update(FileName: String);
  var
    Package: TPackage;
    Packager: TDCLScriptsPackage;
    UpdaterPackage: TDCLUpdaterPackage;
    UpdResult: TPackageUpdateState;
  begin
    Packager:=LoadPackage(FileName);
    if Assigned(Packager) then
    begin
      if Packager.PackageInfo.ForUpdate then
      begin
        if CheckSigned(Packager) then
        begin
          Package:=TPackage.Create;
          Package.PackageInfo:=Packager.PackageInfo;
          Package.Scripts:=Packager.Scripts;

          UpdaterPackage:=TDCLUpdaterPackage.Create(GetDBConnector);
          UpdResult:=UpdaterPackage.Update(Package, True);
          FreeAndNil(Package);
          FreeAndNil(UpdaterPackage);

          if UpdResult=pusDone then
          begin
            DeleteFile(FileName);
          end;
        end;
      end;
    end;
    FreeAndNil(Packager);
  end;

begin
  retval:=FindFirst(PackagePath+'*'+PackagesFileExt, faAnyFile, SRec);
  While retval=0 Do
  Begin
    If (SRec.Name<>'.')and(SRec.Name<>'..') then
    begin
      If SRec.Attr<>faDirectory Then
      begin
        Update(PackagePath+SRec.Name);
      end;
    end;
    retval:=FindNext(SRec);
  end;
end;

constructor TDCLMain.Create;
var
  FDCLConfig: TDCLConfig;
  Params: TStringList;
begin
  GPT.NoParamsTable:=False;
  {$IFDEF IBALL}
  GPT.IBAll:=True;
  {$ELSE}
  GPT.IBAll:=False;
  {$ENDIF}
  GPT.DebugMesseges:=False;
  GPT.OneCopy:=0;
  GPT.ExitCnf:=False;
  GPT.UseMessages:=True;
  GPT.DialogsSettings:=True;
  GPT.Port:=0;
  {$IFDEF ZEOS}
  GPT.DBType:=DefaultDBType;
  {$ENDIF}
  GPT.OfficeFormat:=ofMSO;
  GPT.OfficeDocumentFormat:=odfMSO2007;

  GPT.TimeFormat:=DefaultTimeFormat;
  GPT.DateFormat:=DefaultDateFormat;
  GPT.DateSeparator:=DefaultDateSeparator;
  GPT.TimeSeparator:=DefaultTimeSeparator;

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
  If GPT.OneCopy=1 Then
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

  {$IFDEF MSWINDOWS}
  If GPT.OneCopy=2 Then
  begin
    CreateMutex(nil, True, PChar(MemFileName+GPT.BaseID));
    If GetLastError=ERROR_ALREADY_EXISTS Then
    begin
      ShowErrorMessage(1, GetDCLMessageString(msAppRunning));
      Halt;
    end;
  end;
  {$ENDIF}

  FPackages:=TList<TPackageInfo>.Create;
  FScripts:=TList<TDCLScriptItem>.Create;

  GPT.TimeStampFormat:=GPT.DateFormat+' '+GPT.TimeFormat;
{$IFDEF MSWINDOWS}
  SysUtils.GetFormatSettings;
{$ENDIF}

  FormatSettings.TimeSeparator:=GPT.TimeSeparator;
  FormatSettings.DateSeparator:=GPT.DateSeparator;
  FormatSettings.ShortDateFormat:=GPT.DateFormat;
  FormatSettings.LongTimeFormat:=GPT.TimeFormat;

  FormatSettings.ThousandSeparator:=GPT.ThousandSeparator;
  FormatSettings.DecimalSeparator:=GPT.DecimalSeparator;
end;

destructor TDCLMain.Destroy;
begin
  KillerDog.Enabled:=False;
  CloseAllDialogs;
  if Assigned(FDCLMenu) then
    FreeAndNil(FDCLMenu);
  inherited Destroy;
end;

procedure TDCLMain.CloseAllDialogs;
var
  ff: TForm;
begin
  FBusyMode:=True;
  For ff in FForms do
  Begin
    If Assigned(ff) and ((ff as TDCLForm).CloseAction=fcaNone) then
    begin
      CloseForm(ff);
      ReleaseForm(ff);
    end;
  End;
  FBusyMode:=False;
end;

procedure TDCLMain.Update;
begin
  if GPT.AccessLevel>=ulUpdater then
  begin
    if not DirectoryExists(AppConfigDir+'Updates') then
      ForceDirectories(AppConfigDir+'Updates');

    UpdateFromPackages(AppConfigDir+'Updates'+PathDelim);
  end;
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

procedure TDCLMain.OpenDialog(DialogName: String; Host: Boolean);
var
  Command: TDCLCommand;
begin
  Command:=TDCLCommand.Create(Self, Self, '', nil, nil);
  Command.OpenDialog(DialogName);
end;

procedure TDCLMain.RunCommandScript(CommandName: String);
var
  Command: TDCLCommand;
begin
  Command:=TDCLCommand.Create(Self, Self, '', nil, nil);
  Command.RunCommandScript(CommandName);
end;

procedure TDCLMain.About;
var
  About: TAboutForm;
begin
  About:=TAboutForm.Create(Application, Self);
  About.ShowModal;
  About.Release;
end;

procedure TDCLMain.ExitApp;
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

