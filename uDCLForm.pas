unit uDCLForm;
{$I DefineType.pas}

interface

uses
  Classes, SysUtils, Forms, DB, Generics.Collections,
  Controls, ComCtrls, Graphics, Menus,
  uDCLData, uDCLTypes, uDCLConst, uDCLGrid, uStringParams, uDCLQuery, uIDCLMain,
  uDCLMeasurements, uDCLDBConnector, uDCLUtils, uDCLVariables, uDCLMultiLang,
  uDCLImages, uIGetValue;

type

  { TDCLForm }

  TDCLForm=class(TForm)
  private
    FReject, FFirstPage, FormCanClose, FCloseQuery: Boolean;
    FIDCLMain: IDCLMain;
    FDBConnector: TDCLDBConnector;
    FFormCloseStatus: TDCLFormCloseAction;
    FNameSpace, FDialogName, CloseQueryText: String;
    FVariables: TVariables;
    FForms: TList<TForm>;
    FParentForm: TDCLForm;
    FRetValueProc: IGetValue;
    FOPL: TStringList;
    FormBar: TToolBar;
    TB: TFormPanelButton;
    FGrids: TList<TDCLGrid>;
    FFormMenu: TMainMenu;
    FMainItemMenu: TMenuItem;

    FParentPanel: TWinControl;
    FPages: TPageControl;
    FTab: TTabSheet;
    FCurrentGrid: TDCLGrid;
    FStatusBar: TStatusBar;
    FReturnValue: TReturnFormValue;
    FEvents: TList<TDCLEvent>;
    FReturnValueParams: TReturnValueParams;
    FUserLevel: TUserLevelsType;

    FIsSingle: Boolean;

    procedure ToolButtonClick(Sender: TObject);

    procedure PageChange(Sender: TObject);

    procedure AddMainPage(Query: TDCLQuery; Data: TDataSource);
    function AddGrid(ParentControl: TWinControl; SurfType: TDataControlType; Query: TDCLQuery;
      Data: TDataSource): TDCLGrid;

    function FindMenuItem(aItems: TMenuItem): TMenuItem;
    procedure AddMainItem(Caption: String; Action: TNotifyEvent);
    procedure AddSubItem(Caption: String; Pict: TPicturesTypes; Action: TNotifyEvent);
    procedure AddCloseFormItem;
    procedure AddSplitter;

    procedure ResetFieldsSettings(Sender: TObject);
    procedure CloseDialogCommand(Sender: TObject);

    procedure TranslateVal(var Params: String; CheckParams: Boolean);

    procedure FormShow(Sender: TObject);
    procedure OnActivateForm(Sender: TObject);
    procedure OnFormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure OnFormCloseQuery(Sender: TObject; var CanClose: Boolean);

    procedure SetRecordsStatus(Str: String); overload;

    procedure ParseEvents(ScrStr: String);
    procedure AddEvent(EventType: TEventsEnum; ScriptName: String);

    procedure SaveFormPos;
  public
    constructor Create(IDCLMain: IDCLMain; DialogName, NameSpace: String; ParentForm: TDCLForm;
      OPL: TStringList;
      Query: TDCLQuery; Data: TDataSource; RetValueProc: IGetValue;
      ReturnValueParams: TReturnValueParams=nil; Modal: Boolean=False); overload;
    destructor Destroy; override;

    procedure RefreshForm;

    procedure SetRecordsStatus(RecNo, RecordCount: LongInt); overload;
    procedure SetDBStatus(Str: String);

    procedure SetInfoStatus(Str: String);
    procedure AddInfoStatus(Str: String; Width: Integer);
    procedure SetStatusNum(Str: String; Num, Width: Integer);
    procedure DeleteStatus(Num: Integer);
    procedure DeleteAllStatus;

    property CloseAction: TDCLFormCloseAction read FFormCloseStatus;
    property Grids: TList<TDCLGrid> read FGrids;
    property CurrentGrid: TDCLGrid read FCurrentGrid;
    property DialogName: String read FDialogName;
    property IsSingle: Boolean read FIsSingle;
    property ReturnValue: TReturnFormValue read FReturnValue write FReturnValue;
    property ReturnValueParams: TReturnValueParams read FReturnValueParams write FReturnValueParams;
    property RetValueMethod: IGetValue read FRetValueProc;
    property ParentForm: TDCLForm read FParentForm;
    property Reject: Boolean read FReject;
    property RightsLevel: TUserLevelsType read FUserLevel;
  end;

implementation

uses
  uDCLCommand, uDCLValuesParser, uDCLMessages, uDCLGlobalVariables, IniFiles;

{ TDCLForm }

procedure TDCLForm.ToolButtonClick(Sender: TObject);
begin
  If WindowState=wsMinimized Then
    WindowState:=wsNormal;
  Show;
  BringToFront;
end;

procedure TDCLForm.PageChange(Sender: TObject);
var
  tab: TTabSheet;
  i: Integer;
  c: TControl;
begin
  tab:=(Sender as TPageControl).ActivePage;
  if Assigned(tab) then
  begin
    if tab.ControlCount>0 then
    begin
      for i:=1 to tab.ControlCount do
      begin
        c:=tab.Controls[i-1];
        if c is TDCLGrid then
        begin
          FCurrentGrid:=c as TDCLGrid;
          break;
        end;
      end;
    end;
  end;
end;

procedure TDCLForm.AddMainPage(Query: TDCLQuery; Data: TDataSource);
var
  pc: Integer;
begin
  If Not Assigned(FPages) Then
  begin
    FPages:=TPageControl.Create(Self);
    FPages.Parent:=Self;
    FPages.Name:='Pages_'+FDialogName;
    FPages.Align:=alClient;
    FPages.OnChange:=PageChange;
    FPages.ShowTabs:=False;
  end
  Else
  begin
    FPages.ShowTabs:=True;
  end;

  pc:=FPages.PageCount;
  FTab:=TTabSheet.Create(FPages);
  FTab.Parent:=FPages;
  FTab.Caption:=GetDCLMessageString(msPage)+' '+IntToStr(pc+1);
  FTab.Name:='Page_'+IntToStr(pc+1);
  FTab.PageControl:=FPages;

  FPages.ActivePage.Align:=alClient;
  FParentPanel:=FTab.PageControl.Pages[pc];

  FCurrentGrid:=AddGrid(FParentPanel, dctMainGrid, Query, Data);

  FPages.ActivePage:=FPages.Pages[pc];
  FPages.ActivePageIndex:=pc;
end;

function TDCLForm.AddGrid(ParentControl: TWinControl; SurfType: TDataControlType;
  Query: TDCLQuery; Data: TDataSource): TDCLGrid;
var
  grid: TDCLGrid;
begin
  grid:=TDCLGrid.Create(FIDCLMain, FNameSpace, Self, ParentControl, SurfType, Query, Data);
  FGrids.Add(grid);
  Result:=grid;
end;

function TDCLForm.FindMenuItem(aItems: TMenuItem): TMenuItem;
begin

end;

procedure TDCLForm.AddMainItem(Caption: String; Action: TNotifyEvent);
begin
  FMainItemMenu:=TMenuItem.Create(FFormMenu);
  FMainItemMenu.Bitmap:=DrawBMPButton(ptTools);
  FMainItemMenu.Caption:=Caption;
  FMainItemMenu.OnClick:=Action;
  FFormMenu.Items.Add(FMainItemMenu);
end;

procedure TDCLForm.AddSubItem(Caption: String; Pict: TPicturesTypes; Action: TNotifyEvent);
var
  ItemMenu, ToItem: TMenuItem;
begin
  ToItem:=FMainItemMenu;

  if Assigned(ToItem) then
  begin
    ItemMenu:=TMenuItem.Create(ToItem);
    ItemMenu.Bitmap:=DrawBMPButton(Pict);
    ItemMenu.Caption:=Caption;
    ItemMenu.OnClick:=Action;
    ToItem.OnClick:=nil;
    ToItem.Insert(ToItem.Count, ItemMenu);
  end;
end;

procedure TDCLForm.AddCloseFormItem;
var
  ItemMenu, ToItem: TMenuItem;
begin
  ToItem:=FMainItemMenu;

  if Assigned(ToItem) then
  begin
    ItemMenu:=TMenuItem.Create(ToItem);
    ItemMenu.Caption:=GetDCLMessageString(msClose);
    ItemMenu.OnClick:=CloseDialogCommand;
    ItemMenu.Bitmap:=DrawBMPButton(ptEsc);
    ItemMenu.ShortCut:=TShortCut(27);  // TextToShortCut('Esc');

    ToItem.OnClick:=nil;
    ToItem.Insert(ToItem.Count, ItemMenu);
  end;
end;

procedure TDCLForm.AddSplitter;
var
  ItemMenu, ToItem: TMenuItem;
begin
  ToItem:=FMainItemMenu;

  if Assigned(ToItem) then
  begin
    ItemMenu:=TMenuItem.Create(ToItem);
    ItemMenu.Caption:='-';
    ToItem.OnClick:=nil;
    ToItem.Insert(ToItem.Count, ItemMenu);
  end;
end;

procedure TDCLForm.ResetFieldsSettings(Sender: TObject);
begin
  If ShowErrorMessage(10, GetDCLMessageString(msResetFieldsSettingsQ))=1 Then
  begin
    if Assigned(FCurrentGrid) then
      FCurrentGrid.ResetFieldsSettings;
  end;
end;

procedure TDCLForm.CloseDialogCommand(Sender: TObject);
begin
  if FormCanClose then
    Close;
end;

procedure TDCLForm.TranslateVal(var Params: String; CheckParams: Boolean);
var
  Parser: TDCLValuseParser;
begin
  Parser:=TDCLValuseParser.Create(FNameSpace, FVariables);
  if Assigned(FCurrentGrid) then
    Parser.RePlaseVariables(FNameSpace, Params, FCurrentGrid.Query)
  else
    Parser.RePlaseVariables(FNameSpace, Params, nil);
  if CheckParams then
  if Assigned(FCurrentGrid) then
    Parser.RePlaseParams(Params, FCurrentGrid.Query);
end;

procedure TDCLForm.FormShow(Sender: TObject);
var
  ConfigPath, Section: String;
  Settings: TIniFile;
begin
  if GPT.DialogsSettings then
  begin
    ConfigPath:=AppConfigDir+FormConfigDir+'Base_'+GPT.BaseID+PathDelim+'Forms'+PathDelim+FDialogName+PathDelim;
    if DirectoryExists(ConfigPath) and FileExists(ConfigPath+'Settings.ini') then
    begin
      Section:='Position';
      if Self.FormStyle=fsMDIChild then
        Section:=Section+'MDI';

      Settings:=TIniFile.Create(ConfigPath+'Settings.ini', TEncoding.UTF8);
      Self.Top:=Settings.ReadInteger(Section, 'Top', Self.Top);
      Self.Left:=Settings.ReadInteger(Section, 'Left', Self.Left);
      Self.Height:=Settings.ReadInteger(Section, 'Height', Self.Height);
      Self.Width:=Settings.ReadInteger(Section, 'Width', Self.Width);

      FreeAndNil(Settings);
    end;
  end;
end;

procedure TDCLForm.OnFormClose(Sender: TObject; var CloseAction: TCloseAction);
var
  Grid: TDCLGrid;
  F: TForm;
begin
  for F in FForms do
  begin
    if (F as TDCLForm).ParentForm=Self then
      F.Close;
  end;

  for Grid in FGrids do
  begin
    Grid.CloseComponent;
  end;

  SaveFormPos;
  FFormCloseStatus:=fcaRelease;
end;

procedure TDCLForm.OnFormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
  S:String;
  DlgRes:Integer;
begin
  If FCloseQuery then
  Begin
    S:=CloseQueryText;
    if S='' then
      S:=GetDCLMessageString(msClose);
    DlgRes:=ShowErrorMessage(10, S);
    CanClose:=DlgRes=1;
    FormCanClose:=CanClose;
  End;
end;

procedure TDCLForm.SetRecordsStatus(Str: String);
begin
  FStatusBar.Panels[StatusRecords].Text:=Str;
end;

procedure TDCLForm.SetRecordsStatus(RecNo, RecordCount: LongInt);
begin
  if RecordCount>0 then
    SetRecordsStatus(IntToStr(RecNo)+'/'+IntToStr(RecordCount))
  else
    SetRecordsStatus(IntToStr(RecNo));
end;

constructor TDCLForm.Create(IDCLMain: IDCLMain; DialogName, NameSpace: String; ParentForm: TDCLForm;
  OPL: TStringList;
  Query: TDCLQuery; Data: TDataSource; RetValueProc: IGetValue;
  ReturnValueParams: TReturnValueParams=nil; Modal: Boolean=False);
var
  Command: TDCLCommand;
  SrcLine, tmpS, tmpS1: String;
  ff: TForm;
  g: TDCLGrid;
  OnTop: Boolean;
  FieldsCount: Integer;
  UserLevelLocal: TUserLevelsType;
begin
  inherited Create(Application);
  FIDCLMain:=IDCLMain;
  FormCanClose:=True;
  Self.OnActivate:=OnActivateForm;
  Self.OnShow:=FormShow;
  Self.OnClose:=OnFormClose;
  Self.OnCloseQuery:=OnFormCloseQuery;
  FForms:=FIDCLMain.GetForms;
  FDialogName:=DialogName;
  FDBConnector:=FIDCLMain.GetDBConnector;
  FFirstPage:=True;
  FReturnValueParams:=ReturnValueParams;
  FParentForm:=ParentForm;
  FRetValueProc:=RetValueProc;
  FUserLevel:=GPT.AccessLevel;
  FCloseQuery:=False;
  CloseQueryText:='';

  FReject:=False;
  For ff in FForms do
  begin
    If Assigned(ff) Then
      If (ff as TDCLForm).IsSingle and ((ff as TDCLForm).DialogName=DialogName) Then
      begin
        FReject:=True;
        Exit;
        break;
      end;
  end;

  For ff in FForms do
  begin
    If Assigned(ff) Then
      If (ff as TDCLForm).FormStyle=fsStayOnTop Then
      begin
        OnTop:=True;
        break;
      end;
  end;

  FNameSpace:=NameSpace;
  FVariables:=FIDCLMain.GetVariables;
  FOPL:=OPL;
  FGrids:=TList<TDCLGrid>.Create;
  FEvents:=TList<TDCLEvent>.Create;

  Height:=DefaultFormHeight;
  Width:=DefaultFormWidth;
  Position:=poScreenCenter;
  FIsSingle:=False;

  {$IFNDEF EMBEDDED}
  If Assigned(Application.MainForm) and not Modal then
    If Application.MainForm.FormStyle=fsMDIForm Then
      FormStyle:=fsMDIChild;
  {$ENDIF}

  FFormMenu:=TMainMenu.Create(Self);

  AddMainItem(InitCap(GetDCLMessageString(msSettings)), nil);
  AddSubItem(GetDCLMessageString(msResetFieldsSettings), ptNone, ResetFieldsSettings);

  AddSplitter;
  AddCloseFormItem;

  if ShowFormPanel then
  begin
    FormBar:=Application.MainForm.FindComponent(ToolPanelName) as TToolBar;
    if Assigned(FormBar) then
    begin
      TB:=TFormPanelButton.Create(Self);
      TB.Parent:=FormBar;
      TB.Alignment:=taLeftJustify;
      TB.Height:=FormPanelButtonHeight;
      TB.OnClick:=ToolButtonClick;
      TB.Constraints.MinWidth:=100;
      TB.Constraints.MaxWidth:=FormPanelButtonWidth;
      TB.Tag:=Tag;
      TB.Margin:=PanelButtonTextRight;
      TB.Glyph:=DrawBMPButton(ptFormDotNew);
      TB.Font.Style:=[fsItalic];
      TB.AutoSize:=True;
    end;
  end;

  FStatusBar:=TStatusBar.Create(Self);
  FStatusBar.SimplePanel:=False;
  FStatusBar.Parent:=Self;
  FStatusBar.Panels.Add;
  FStatusBar.Panels.Add;
  FStatusBar.Panels.Add;
  FStatusBar.Panels[0].Width:=100;
  FStatusBar.Panels[1].Width:=80;

  AddMainPage(Query, Data);

  if Assigned(OPL) then
  begin
    Command:=TDCLCommand.Create(FIDCLMain, FNameSpace, Self, FCurrentGrid);
    if Assigned(ReturnValueParams) and ReturnValueParams.Multiselect then
      FCurrentGrid.MultiSelect:=True;

    Show;
    for SrcLine in OPL do
    begin
      if Pos('//', SrcLine.Trim)=1 then
        Continue;

      If IsLexem('UserAccessRaight=', SrcLine) then
      begin
        tmpS:=SrcLine;
        TranslateVal(tmpS, True);
        tmpS:=FindParam('UserAccessRaight=', tmpS);
        Case GetStringDataType(tmpS) of
        idDigit:
        UserLevelLocal:=TranslateDigitToUserLevel(StrToIntEx(FindParam('UserAccessRaight=', SrcLine)));
        idUserLevel:
        UserLevelLocal:=TranslateDigitToUserLevel(FindParam('UserAccessRaight=', SrcLine));
        end;
        If UserLevelLocal>FUserLevel Then
        begin
          ShowErrorMessage(0, GetDCLMessageString(msNotAllowOpenForm));
          ExitCode:=1;
          Exit;
        end;
      end;

      if IsLexem('[Page]', SrcLine) then
      begin
        if not FFirstPage then
          AddMainPage(Query, Data);
        FFirstPage:=False;
      end;

      if IsLexem('Title=', SrcLine) then
      begin
        tmpS:=SrcLine;
        TranslateVal(tmpS, True);
        tmpS:=FindParam('Title=', tmpS);
        FPages.ActivePage.Caption:=tmpS;
      end;

      If IsLexem('CloseQuery=', SrcLine) then
      begin
        CloseQueryText:=FindParam('CloseQuery=', SrcLine);
        FCloseQuery:=True;
      end;

      if IsLexem('Caption=', SrcLine) then
      begin
        tmpS:=SrcLine;
        TranslateVal(tmpS, True);
        tmpS1:=FindParam('Caption=', tmpS);
        if Assigned(TB) then
          TB.Caption:=tmpS1;
        if GPT.MainFormCaption<>'' then
          tmpS1:=tmpS1+' \'+Trim(GPT.MainFormCaption)+'\';

        Self.Caption:=tmpS1;
      end;

      If IsLexem('OnTop=', SrcLine) then
      begin
        tmpS:=SrcLine;
        TranslateVal(tmpS, True);
        tmpS:=FindParam('OnTop=', tmpS);
        OnTop:=tmpS='1';
      end;

      If IsLexem('Single;', SrcLine) then
      begin
        FIsSingle:=True;
      end;

      if IsLexem('Events=', SrcLine) then
      begin
        ParseEvents(SrcLine);
      end;

      Command.RunCommand(SrcLine);
      if Assigned(FCurrentGrid) then
      begin
        FCurrentGrid.ExecScriptLine(SrcLine);
      end;
    end;
  end;

  FieldsCount:=0;
  for g in FGrids do
  begin
    g.Prepeare;
    if (FieldsCount<g.FieldsCount) and (g.Style<>gsGrid) then
      FieldsCount:=g.FieldsCount;
  end;
  if FieldsCount>0 then
  begin
    Self.Height:=(56*8)+110;
    Self.Width:=((FieldsCount div 8)+1)*280;
  end;

  {$IFNDEF NOONTOP}
  If OnTop then  // Мешает отладки
    FormStyle:=fsStayOnTop;
  {$ENDIF}
  if not Assigned(FReturnValueParams) and not Modal then
  begin
    Self.Show;
  end;
end;

destructor TDCLForm.Destroy;
begin
  FRetValueProc:=nil;
  inherited Destroy;
end;

procedure TDCLForm.RefreshForm;
var
  Grid: TDCLGrid;
begin
  for Grid in FGrids do
  begin
    Grid.ReFreshData;
  end;
end;

procedure TDCLForm.OnActivateForm(Sender: TObject);
var
  i: Byte;
  TB1: TFormPanelButton;
  ff: TForm;
begin
  If ShowFormPanel and Assigned(FormBar) Then
  begin
    if FormBar.ControlCount>0 then
    begin
      For ff in FForms do
      begin
        If Assigned(ff) Then
        begin
          TB1:=nil;
          for i:=1 to FormBar.ControlCount do
          begin
            if FormBar.Controls[i-1].Owner=ff then
            begin
              TB1:=FormBar.Controls[i-1] as TFormPanelButton;
              break;
            end;
          end;

          If Assigned(TB1) Then
          begin
            If ff=Screen.ActiveForm Then
            begin
              TB1.Glyph:=DrawBMPButton(ptFormDotActive);
              TB1.Font.Style:=[fsBold];
            end
            Else
            begin
              TB1.Glyph:=DrawBMPButton(ptFormDotInActive);
              TB1.Font.Style:=[];
            end
          end;
        end;
      end;
    end;
  end;
end;

procedure TDCLForm.SetInfoStatus(Str: String);
begin
  FStatusBar.Panels[StatusInfo].Text:=Str;
end;

procedure TDCLForm.AddInfoStatus(Str: String; Width: Integer);
var
  Panel: TStatusPanel;
begin
  Panel:=FStatusBar.Panels.Add;
  Panel.Text:=Str;
  if Width>10 then
    Panel.Width:=Width;
end;

procedure TDCLForm.SetStatusNum(Str: String; Num, Width: Integer);
begin
  if Num=-1 then
  begin
    FStatusBar.Panels[FStatusBar.Panels.Count-1].Text:=Str;
  end
  else
  if (Num>0) and (FStatusBar.Panels.Count>Num) then
  begin
    FStatusBar.Panels[Num+StatusInfo].Text:=Str;

    if Width>10 then
      FStatusBar.Panels[Num+StatusInfo].Width:=Width;
  end;
end;

procedure TDCLForm.DeleteStatus(Num: Integer);
begin
  if Num=-1 then
  begin
    FStatusBar.Panels.Delete(FStatusBar.Panels.Count-1);
  end
  else
  if (Num<FStatusBar.Panels.Count) and (Num>0) then
  begin
    FStatusBar.Panels.Delete(Num+StatusInfo);
  end;
end;

procedure TDCLForm.DeleteAllStatus;
begin
  if FStatusBar.Panels.Count>StatusInfo+1 then
  begin
    repeat
      FStatusBar.Panels.Delete(FStatusBar.Panels.Count-1);
    until FStatusBar.Panels.Count<=StatusInfo+1;
  end;
end;

procedure TDCLForm.SetDBStatus(Str: String);
begin
  FStatusBar.Panels[StatusDB].Text:=Str;
end;

procedure TDCLForm.ParseEvents(ScrStr: String);
var
  S: String;
begin
  If PosEx('Close=', ScrStr)<>0 Then
  begin
    S:=FindParam('Close=', ScrStr);
    //AddEvent(evtClose, S);
  end;
end;

procedure TDCLForm.AddEvent(EventType: TEventsEnum; ScriptName: String);
var
  Event: TDCLEvent;
begin
  if ScriptName<>'' then
  begin
    Event:=TDCLEvent.Create;
    Event.EventType:=EventType;
    Event.ScriptName:=ScriptName;
    FEvents.Add(Event);
  end;
end;

procedure TDCLForm.SaveFormPos;
var
  ConfigPath, Section: String;
  Settings: TIniFile;
begin
  if GPT.DialogsSettings and (Self.WindowState=wsNormal) then
  begin
    ConfigPath:=AppConfigDir+FormConfigDir+'Base_'+GPT.BaseID+PathDelim+'Forms'+PathDelim+FDialogName+PathDelim;
    if not DirectoryExists(ConfigPath) then
      ForceDirectories(ConfigPath);

    Section:='Position';
    if Self.FormStyle=fsMDIChild then
      Section:=Section+'MDI';

    Settings:=TIniFile.Create(ConfigPath+'Settings.ini', TEncoding.UTF8);
    Settings.WriteInteger(Section, 'Top', Self.Top);
    Settings.WriteInteger(Section, 'Left', Self.Left);
    Settings.WriteInteger(Section, 'Height', Self.Height);
    Settings.WriteInteger(Section, 'Width', Self.Width);

    FreeAndNil(Settings);
  end;
end;

end.

