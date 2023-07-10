unit uDCLMain;
{$I DefineType.pas}

interface

uses
  Classes, SysUtils, Generics.Collections, Forms, ExtCtrls,
  uDCLTypes, uDCLForm, uDCLVariables, uDCLDBConnector, uDCLData, uDCLMenu,
  uDCLFormsNotifier, uDCLConst;

type

  { TDCLMain }

  TDCLMain=class(TComponent)
  private
    FMainForm: TForm;
    FForms: TList<TForm>;
    FVariables: TVariables;
    FDBConnector: TDCLDBConnector;
    FDCLMenu: TDCLMenu;
    LocalQuery: TDCLDialogQuery;
    KillerDog: TTimer;
    FBusyMode: Boolean;

    procedure KillerForms(Sender: TObject);
    function GetDialogScript(DialogName: String): String;
    procedure CloseForm(Form: TDCLForm);

    procedure WriteBaseID;
    function ReadBaseID: String;
  public
    constructor Create; overload;

    procedure CreateMenu(MainForm: TForm);

    function CreateForm(DialogName: String): TDCLForm;

    procedure OpenDialog(NameSpace, DialogName: String);
    procedure RunCommand(CommandName: String);

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
  uDCLConfig, uDCLCommand, uDCLDBStructure, uDCLMultiLang,
  uDCLGlobalVariables, uDCLUtils;

{ TDCLMain }

function TDCLMain.IsNeedLogin: Boolean;
begin
  Result:=True;

  LocalQuery.SQL.Text:='select * from '+UsersTable;
  LocalQuery.Open;
  Result:=not LocalQuery.IsEmpty;
  LocalQuery.Close;

  if (GPT.DCLUserName<>'') and (GPT.EnterPass<>'') then
  begin
    LocalQuery.SQL.Text:='select * from '+UsersTable+' where lower('+UserNameField+')=lower(:USER)';
    LocalQuery.ParamByName('USER').AsString:=GPT.DCLUserName;
    LocalQuery.Open;
    Result:=not ((GPT.EnterPass=LocalQuery.FieldByName(UserPassField).AsString) and not LocalQuery.IsEmpty);
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
  LocalQuery.SQL.Text:='select count(*) from '+GPTTableName+' where '+GPT.UpperString+
    GPTNameField+GPT.UpperStringEnd+'='+GPT.UpperString+GPT.StringTypeChar+'BaseUID'+
    GPT.StringTypeChar+GPT.UpperStringEnd;
  LocalQuery.Open;
  IsEmpty:=LocalQuery.Fields[0].AsInteger=0;
  LocalQuery.Close;

  If IsEmpty Then
  begin
    If CreateGUID(guid)=0 then
    Begin
      sGuid:=GUIDToString(guid);
      sGuid:=sGuid.Replace('-', '').Replace('{', '').Replace('}', '');
      GPT.BaseID:=sGuid;
      LocalQuery.SQL.Text:='insert into '+GPTTableName+'('+GPTNameField+', '+
        GPTValueField+') values('+GPT.StringTypeChar+'BaseUID'+GPT.StringTypeChar+', '+
        GPT.StringTypeChar+sGuid+GPT.StringTypeChar+')';
      LocalQuery.ExecSQL;
    End;
  end;
end;

function TDCLMain.ReadBaseID: String;
begin
  LocalQuery.SQL.Text:='select * from '+GPTTableName+' where '+GPT.UpperString+
    GPTNameField+GPT.UpperStringEnd+'='+GPT.UpperString+GPT.StringTypeChar+'BaseUID'+
    GPT.StringTypeChar+GPT.UpperStringEnd;
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

constructor TDCLMain.Create;
var
  FDCLConfig: TDCLConfig;
begin
  {$IFDEF ADO}
  CoInitialize(nil);
  {$ENDIF}
  inherited Create(Application);

  InitGetAppConfigDir;
  FDCLConfig:=TDCLConfig.Create;
  FVariables:=TVariables.Create;
  FForms:=TList<TForm>.Create;

  FormsNotifier:=TDCLFormsNotifier.Create(FForms);

  FDCLConfig.GetParamsStructure;

  Path:=ExtractFilePath(Application.ExeName);
  SetCurrentDir(Path);
  InitLangEnv;

  LoadLangRes(LangName, Path);

  FDBConnector:=TDCLDBConnector.Create(GPT);
  FDCLConfig.DBConnector:=FDBConnector;

  LocalQuery:=TDCLDialogQuery.Create(Self);
  FDBConnector.SetConnector(LocalQuery);

  KillerDog:=TTimer.Create(Self);
  KillerDog.Interval:=KillerTimerInterval;
  KillerDog.OnTimer:=KillerForms;
  KillerDog.Enabled:=True;

  ReadBaseID;

  GPT.TimeFormat:=DefaultTimeFormat;
  GPT.DateFormat:=DefaultDateFormat;
  GPT.DateSeparator:=DefaultDateSeparator;
  GPT.TimeSeparator:=DefaultTimeSeparator;
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

procedure TDCLMain.CreateMenu(MainForm: TForm);
begin
  FMainForm:=MainForm;

  FDCLMenu:=TDCLMenu.Create(FMainForm, FDBConnector);
  FDCLMenu.OpenDialogMethod:=OpenDialog;
end;

function TDCLMain.CreateForm(DialogName: String): TDCLForm;
begin
  Result:=nil;
end;

procedure TDCLMain.OpenDialog(NameSpace, DialogName: String);
var
  lForm: TDCLForm;
  t: TStringList;
begin
  t:=TStringList.Create;
  t.Text:=GetDialogScript(DialogName);
  if t.Text<>'' then
  begin
    lForm:=TDCLForm.Create(DialogName, NameSpace, nil, FVariables, FForms, t, FDBConnector, nil, nil);
    if not lForm.Reject then
      FForms.Add(lForm);
  end;
  FreeAndNil(t);
end;

procedure TDCLMain.RunCommand(CommandName: String);
var
  Command: TDCLCommand;
begin
  Command:=TDCLCommand.Create(FDBConnector, '', FForms, nil, nil, FVariables);
  Command.RunCommandScript(CommandName);
end;

end.

