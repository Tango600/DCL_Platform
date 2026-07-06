unit uDCLNotifier;
{$mode Delphi}

interface

uses
  Classes, SysUtils, ExtCtrls,
  uDCLConst, uDCLDBAwareTypes, uDCLDBConnector, uDCLGlobalConfigTable, fMessageForm,
  uDCLGlobalVariables, uIDCLMain;

type

  { TDCLNotifier }

  TDCLNotifier=class(TComponent)
  private
    FDCLMain: IDCLMain;
    FDCLConnector: TDCLDBConnector;
    Timer: TTimer;
    ShadowQuery, ShadowQuery2: TDCLSimplyQuery;
    ExitFlag: Boolean;
    MessageForm: TMessageForm;
    TimeToExit: TDateTime;

    procedure OnTick(Sender: TObject);
    procedure MessageToUser(Text: String);
    function TestNotifierTable: Boolean;
  public
    constructor Create(const DCLMain: IDCLMain); overload;
    destructor Destroy; override;
  end;

implementation

uses
  uDCLDBStructure, uRunProgram, uDCLMultiLang, uDBUtils;

{ TDCLNotifier }

procedure TDCLNotifier.OnTick(Sender: TObject);
var
  NotifyText: String;
  Id: Integer;
  Action: TNotifyActionsType;
  TaskTime: TDateTime;

  function GetNotifyAction(NA: Byte): TNotifyActionsType;
  begin
    Case NA of
      0..Ord(High(TNotifyActionsType)): Result:=TNotifyActionsType(NA);
    Else
      Result:=naDone;
    end;
  end;
begin
  If not GPT.UseMessages then
    Exit;

  if ExitFlag then
  begin
    If TimeToExit<=Now Then
    begin
      FDCLMain.ExitApp;
    end;
  end;

  If GPT.UserID<>'' then
  begin
    ShadowQuery.SQL.Text:='select NOTIFY_ACTION, NOTIFY_TIME, NOTIFY_ID, NOTIFY_TEXT from '+
      NotifycationsTable+' where USER_ID='+GPT.UserID+' and NOTIFY_STATE<>0 '+
      'order by NOTIFY_TIME, NOTIFY_ACTION';
  end
  else
  begin
    ShadowQuery.SQL.Text:='select NOTIFY_ACTION, NOTIFY_TIME, NOTIFY_ID, NOTIFY_TEXT from '+
      NotifycationsTable+' where NOTIFY_STATE<>0 '+
      'order by NOTIFY_TIME, NOTIFY_ACTION';
  end;

  try
    ShadowQuery.Open;
    Timer.Enabled:=True;
  Except
    GPT.UseMessages:=False;
    Timer.Enabled:=False;
  end;

  ShadowQuery.First;
  while not ShadowQuery.Eof do
  begin
    TaskTime:=ShadowQuery.FieldByName('NOTIFY_TIME').AsDateTime;

    if TaskTime<=Now then
    begin
      NotifyText:=Trim(ShadowQuery.FieldByName('NOTIFY_TEXT').AsString);
      Id:=ShadowQuery.FieldByName('NOTIFY_ID').AsInteger;
      Action:=GetNotifyAction(ShadowQuery.FieldByName('NOTIFY_ACTION').AsInteger);

      case Action of
      naScriptRun: begin
        FDCLMain.RunCommandScript(NotifyText);
      end;
      naExec, naExecAndWait: begin
        Run(NotifyText, '', Action=naExecAndWait);
      end;
      naMessage: begin
        MessageToUser(NotifyText);
      end;
      naExitToTime: begin
        if not ExitFlag then
        begin
          MessageToUser(Format(GetDCLMessageString(msTimeToExit), [ExitTime]));
          ExitFlag:=True;
          TimeToExit:=Time+(ExitTime*1000);
        end;
      end;
      end;

      try
        ShadowQuery2.Params.Clear;
        ShadowQuery2.SQL.Text:='update '+NotifycationsTable+' '+
          'set NOTIFY_STATE=0 '+
          'where NOTIFY_ID=:ID';
        ShadowQuery2.ParamByName('ID').AsInteger:=Id;
        ShadowQuery2.ExecSQL;
      except
        ///
      end;
      break;
    end;

    ShadowQuery.Next;
  end;
  ShadowQuery.Close;
end;

procedure TDCLNotifier.MessageToUser(Text: String);
begin
  If GPT.UserID<>'' then
    MessageForm:=TMessageForm.Create(GPT.DCLLongUserName, Text)
  else
    MessageForm:=TMessageForm.Create('<'+GetDCLMessageString(msToAll)+'>', Text);

  MessageForm.Show;
end;

function TDCLNotifier.TestNotifierTable: Boolean;
begin
  Result:=FDCLConnector.Connected and TableExists(FDCLConnector, NotifycationsTable);
end;

constructor TDCLNotifier.Create(const DCLMain: IDCLMain);
begin
  FDCLMain:=DCLMain;
  FDCLConnector:=FDCLMain.GetDBConnector;

  ExitFlag:=False;
  TimeToExit:=0;

  ShadowQuery:=TDCLSimplyQuery.Create(Self);
  FDCLConnector.SetConnector(ShadowQuery);

  ShadowQuery2:=TDCLSimplyQuery.Create(Self);
  FDCLConnector.SetConnector(ShadowQuery2);

  if TestNotifierTable then
  begin
    Timer:=TTimer.Create(Self);
    Timer.Interval:=IntervalTimeNotify;
    Timer.OnTimer:=OnTick;

    OnTick(Timer);
  end;
end;

destructor TDCLNotifier.Destroy;
begin
  FDCLMain:=nil;
  inherited Destroy;
end;

end.

