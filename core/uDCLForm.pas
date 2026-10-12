unit uDCLForm;
{$I DefineType.pas}

interface

uses
  Classes, SysUtils, Forms, DB, Generics.Collections, Controls, ComCtrls,
  Graphics, Menus,
  uDCLData, uDCLTypes, uDCLConst, uStringParams, uDCLQuery, uIDCLMain,
  uDCLMeasurements, uDCLDBConnector, uDCLUtils, uDCLVariables, uDCLMultiLang,
  uIDCLCommand, uReturnFormValue, uIDCLForm, uIDCLGrid, uDCLImages,
  uDCLValuesParser, uVariableNamespace;

type

  { TDCLForm }

  TDCLForm=class(TInterfacedObject, IDCLForm)
  private
    FForm: TForm;
    FReject, FCloseQuery, FIsSingle: Boolean;
    FIDCLMain: IDCLMain;
    FDBConnector: TDCLDBConnector;
    FNameSpace: TVariableNamespace;
    FDialogName, CloseQueryText: String;
    FVariables: TVariables;
    FParentForm: IDCLForm;
    FOPL: TStringList;
    FormBar: TToolBar;
    TB: TFormPanelButton;
    FGrids: TList<IDCLGrid>;
    FFormMenu: TMainMenu;
    FMainItemMenu: TMenuItem;

    FParentPanel: TWinControl;
    FPages: TPageControl;
    FTab: TTabSheet;
    FStatusBar: TStatusBar;
    FReturnValueParams: TReturnValueParams;
    FUserLevel: TUserLevelsType;
    FStackLevel, FCurrentGridIndex: Integer;
    FParser: TDCLValuseParser;

    //region TForm
    procedure SetWindowState(Value : TWindowState);
    function GetWindowState: TWindowState;
    function GetShowing: Boolean;
    function GetCapt: String;
    procedure SetCapt(const Value: String);
    function GetModalResult: TModalResult;
    procedure SetModalResult(Value: TModalResult);
    function GetFormStyle: TFormStyle;
    procedure SetFormStyle(Value: TFormStyle);
    //end region

    function GetStackLevel: Integer;
    procedure SetStackLevel(Value: Integer);
    function GetIsSingle: Boolean;

    function GetGrids: TList<IDCLGrid>;
    function IsReject: Boolean;
    function GetUserLevel: TUserLevelsType;

    function GetParentDialog: IDCLForm;
    procedure ToolButtonClick(Sender: TObject);

    procedure PageChange(Sender: TObject);

    function AddMainPage(const Query: TDCLQuery; const Data: TDataSource): IDCLGrid;
    function AddGrid(const ParentControl: TWinControl; SurfType: TDataControlType;
      const Query: TDCLQuery; const Data: TDataSource): IDCLGrid;

    procedure AddMainItem(const Caption: String; Action: TNotifyEvent);
    procedure AddSubItem(const Caption: String; Pict: TPicturesTypes; Action: TNotifyEvent);
    procedure AddCloseFormItem;
    procedure AddSplitter;

    procedure SetReturnValueParams(Value: TReturnValueParams);
    function GetReturnValueParams: TReturnValueParams;

    procedure ResetFieldsSettings(Sender: TObject);
    procedure CloseDialogCommand(Sender: TObject);

    procedure TranslateVal(var Params: String; const Grid: IDCLGrid; CheckParams: Boolean);

    procedure FormShow(Sender: TObject);
    procedure OnActivateForm(Sender: TObject);
    procedure OnFormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure OnFormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure OnDestroyForm(Sender: TObject);

    procedure SetRecordsStatus(const Str: String); overload;

    function GetCurrentGrid: IDCLGrid;
    function GetDialogName: String;
    procedure SaveFormPos;

    function GetForm: TForm;

    procedure ForceClose;
    procedure RefreshForm;

    procedure SetRecordsStatus(RecNo, RecordCount: LongInt); overload;
    procedure SetDBStatus(Str: String);

    procedure SetInfoStatus(const Str: String);
    procedure AddInfoStatus(const Str: String; Width: Integer);
    procedure SetStatusNum(const Str: String; Num, Width: Integer);
    procedure DeleteStatus(Num: Integer);
    procedure DeleteAllStatus;

    procedure GetValueProc(Value: TReturnFormValue);

    //region TForm
    procedure Hide;
    procedure Show;
    procedure ShowOnTop;
    function ShowModal: Integer;
    procedure SetFocus;
    procedure Close;

    property WindowState: TWindowState read GetWindowState write SetWindowState
                                   default wsNormal;
    property FormStyle: TFormStyle read GetFormStyle write SetFormStyle default fsNormal;
    property Caption: String read GetCapt write SetCapt;
    //end region
  public
    constructor Create(const IDCLMain: IDCLMain; const DialogName: String; const NameSpace: TVariableNamespace; const ParentForm: IDCLForm;
      OPL: TStringList; UserLevel: TUserLevelsType;
      const Query: TDCLQuery; const Data: TDataSource;
      ReturnValueParams: TReturnValueParams=nil; Modal: Boolean=False); overload;
    destructor Destroy; override;
  end;

implementation

uses
  IniFiles,
  uDCLCommand, uDCLGrid, uDCLMessages, uDCLGlobalVariables, uDetectDataType,
  uConvertEx, uStringUtils;

{ TDCLForm }

procedure TDCLForm.SetWindowState(Value: TWindowState);
begin
  FForm.WindowState:=Value;
end;

function TDCLForm.GetWindowState: TWindowState;
begin
  Result:=FForm.WindowState;
end;

function TDCLForm.GetShowing: Boolean;
begin
  Result:=FForm.Showing;
end;

function TDCLForm.GetCapt: String;
begin
  Result:=FForm.Caption;
end;

procedure TDCLForm.SetCapt(const Value: String);
begin
  FForm.Caption:=Value;
end;

function TDCLForm.GetModalResult: TModalResult;
begin
  Result:=FForm.ModalResult;
end;

procedure TDCLForm.SetModalResult(Value: TModalResult);
begin
  FForm.ModalResult:=Value;
end;

function TDCLForm.GetFormStyle: TFormStyle;
begin
  Result:=FForm.FormStyle;
end;

procedure TDCLForm.SetFormStyle(Value: TFormStyle);
begin
  FForm.FormStyle:=Value;
end;

function TDCLForm.GetStackLevel: Integer;
begin
  Result:=FStackLevel;
end;

procedure TDCLForm.SetStackLevel(Value: Integer);
begin
  FStackLevel:=Value;
end;

function TDCLForm.GetIsSingle: Boolean;
begin
  Result:=FIsSingle;
end;

function TDCLForm.GetGrids: TList<IDCLGrid>;
begin
  Result:=FGrids;
end;

function TDCLForm.IsReject: Boolean;
begin
  Result:=FReject;
end;

function TDCLForm.GetUserLevel: TUserLevelsType;
begin
  Result:=FUserLevel;
end;

function TDCLForm.GetParentDialog: IDCLForm;
begin
  Result:=FParentForm;
end;

procedure TDCLForm.ToolButtonClick(Sender: TObject);
begin
  If WindowState=wsMinimized Then
    WindowState:=wsNormal;
  Show;
  FForm.BringToFront;
end;

procedure TDCLForm.PageChange(Sender: TObject);
var
  tab: TTabSheet;
  i, j: Integer;
  c: TControl;
  g: IDCLGrid;
begin
  tab:=(Sender as TPageControl).ActivePage;
  if Assigned(tab) then
  begin
    if tab.ControlCount>0 then
    begin
      for i:=1 to tab.ControlCount do
      begin
        c:=tab.Controls[i-1];
        for j:=0 to FGrids.Count-1 do
        begin
          g:=FGrids[j];
          if g.GetComponent=c then
          begin
            FCurrentGridIndex:=j;
            break;
          end;
        end;
      end;
    end;
  end;
end;

function TDCLForm.AddMainPage(const Query: TDCLQuery; const Data: TDataSource): IDCLGrid;
var
  pc: Integer;
begin
  If Not Assigned(FPages) Then
  begin
    FPages:=TPageControl.Create(FForm);
    FPages.Parent:=FForm;
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

  FPages.ActivePage.Align:=alClient;
  FParentPanel:=FTab;

  Result:=AddGrid(FParentPanel, dctMainGrid, Query, Data);

  FPages.ActivePage:=FTab;
end;

function TDCLForm.AddGrid(const ParentControl: TWinControl; SurfType: TDataControlType;
  const Query: TDCLQuery; const Data: TDataSource): IDCLGrid;
var
  grid: IDCLGrid;
begin
  grid:=TDCLGrid.Create(FIDCLMain, FNameSpace, Self, ParentControl, SurfType, Query, Data);
  FGrids.Add(grid);
  Result:=grid;
end;

procedure TDCLForm.AddMainItem(const Caption: String; Action: TNotifyEvent);
begin
  FMainItemMenu:=TMenuItem.Create(FFormMenu);
  FMainItemMenu.ImageIndex:=FIDCLMain.GetImageIndex(ptTools);
  FMainItemMenu.Caption:=Caption;
  FMainItemMenu.OnClick:=Action;
  FFormMenu.Items.Add(FMainItemMenu);
end;

procedure TDCLForm.AddSubItem(const Caption: String; Pict: TPicturesTypes; Action: TNotifyEvent);
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
    ItemMenu.ShortCut:=TShortCut(27);

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

procedure TDCLForm.SetReturnValueParams(Value: TReturnValueParams);
begin
  FReturnValueParams:=Value;
end;

function TDCLForm.GetReturnValueParams: TReturnValueParams;
begin
  Result:=FReturnValueParams;
end;

procedure TDCLForm.ResetFieldsSettings(Sender: TObject);
begin
  If ShowErrorMessage(10, GetDCLMessageString(msResetFieldsSettingsQ))=1 Then
  begin
    if FGrids.Count>FCurrentGridIndex+1 then
    if Assigned(FGrids[FCurrentGridIndex]) then
      FGrids[FCurrentGridIndex].ResetFieldsSettings;
  end;
end;

procedure TDCLForm.CloseDialogCommand(Sender: TObject);
begin
  Close;
end;

procedure TDCLForm.TranslateVal(var Params: String; const Grid: IDCLGrid; CheckParams: Boolean);
begin
  if Assigned(Grid) then
    FParser.ReplaceAllVariables(FNameSpace.CurrentNamespace, Params, Grid.Query)
  else
    FParser.ReplaceAllVariables(FNameSpace.CurrentNamespace, Params, nil);
  if CheckParams then
  if Assigned(Grid) then
    FParser.RePlaseParams(Params, Grid.Query);
end;

procedure TDCLForm.FormShow(Sender: TObject);
var
  ConfigPath, Section: String;
  Settings: TIniFile;
begin
  If GPT.KioskMode then
  begin
    WindowState:=wsMaximized;
    FForm.BorderIcons:=[biSystemMenu];
  end;

  if GPT.DialogsSettings and not GPT.KioskMode then
  begin
    ConfigPath:=GPT.AppConfigDir+FormConfigDir+PathDelim+'Base_'+GPT.BaseID+PathDelim+'Forms'+PathDelim+FDialogName+PathDelim;
    if DirectoryExists(ConfigPath) and FileExists(ConfigPath+'Settings.ini') then
    begin
      Section:='Position';
      if Self.FormStyle=fsMDIChild then
        Section:=Section+'MDI';
      if Assigned(FReturnValueParams) then
        Section:=Section+'Choose';

      Settings:=TIniFile.Create(ConfigPath+'Settings.ini', TEncoding.UTF8);
      FForm.Top:=Settings.ReadInteger(Section, 'Top', FForm.Top);
      FForm.Left:=Settings.ReadInteger(Section, 'Left', FForm.Left);
      FForm.Height:=Settings.ReadInteger(Section, 'Height', FForm.Height);
      FForm.Width:=Settings.ReadInteger(Section, 'Width', FForm.Width);
      FreeAndNil(Settings);
    end;
  end;
end;

procedure TDCLForm.OnFormClose(Sender: TObject; var CloseAction: TCloseAction);
var
  Grid: IDCLGrid;
  F: IDCLForm;
begin
  for Grid in FGrids do
  begin
    Grid.CloseComponent;
  end;

  for F in FIDCLMain.GetForms do
  begin
    if (F.ParentDialog as TDCLForm)=Self then
      F.ForceClose;
  end;

  SaveFormPos;

  CloseAction:=caFree;
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
  End
  Else
    CanClose:=True;
end;

procedure TDCLForm.OnDestroyForm(Sender: TObject);
var
  i: Integer;
begin
  if Assigned(FGrids) then
  begin
    for i:=1 to FGrids.Count do
    begin
      FGrids[i-1]:=nil;
    end;
    FreeAndNil(FGrids);
  end;

  if Assigned(FIDCLMain) then
    FIDCLMain.ReleaseForm(Self);
end;

procedure TDCLForm.SetRecordsStatus(const Str: String);
begin
  FStatusBar.Panels[StatusRecords].Text:=Str;
end;

function TDCLForm.GetCurrentGrid: IDCLGrid;
begin
  Result:=FGrids[FCurrentGridIndex];
end;

function TDCLForm.GetDialogName: String;
begin
  Result:=FDialogName;
end;

procedure TDCLForm.SetRecordsStatus(RecNo, RecordCount: LongInt);
begin
  if RecordCount>0 then
    SetRecordsStatus(IntToStr(RecNo)+'/'+IntToStr(RecordCount))
  else
    SetRecordsStatus(IntToStr(RecNo));
end;

constructor TDCLForm.Create(const IDCLMain: IDCLMain; const DialogName: String; const NameSpace: TVariableNamespace; const ParentForm: IDCLForm;
  OPL: TStringList; UserLevel: TUserLevelsType;
  const Query: TDCLQuery; const Data: TDataSource;
  ReturnValueParams: TReturnValueParams=nil; Modal: Boolean=False);
var
  Command: IDCLCommand;
  SrcLine, tmpS, tmpS1: String;
  ff: IDCLForm;
  g: IDCLGrid;
  {$IFNDEF NOONTOP}
  OnTop: Boolean;
  {$ENDIF}
  FirstPage: Boolean;
  FieldsCount: Integer;
  UserLevelLocal: TUserLevelsType;
  FCurrentGrid: IDCLGrid;
begin
  inherited Create;
  FIDCLMain:=IDCLMain;

  FForm:=TForm.Create(Application);
  FForm.OnActivate:=OnActivateForm;
  FForm.OnShow:=FormShow;
  FForm.OnClose:=OnFormClose;
  FForm.OnCloseQuery:=OnFormCloseQuery;
  FForm.OnDestroy:=OnDestroyForm;
  if not GPT.DisableColorScheme and (GPT.MainColor<>NoColorValue) then
    FForm.Color:=GPT.MainColor;
  FDialogName:=DialogName;
  FDBConnector:=FIDCLMain.GetDBConnector;
  FReturnValueParams:=ReturnValueParams;
  FParentForm:=ParentForm;
  FUserLevel:=UserLevel;
  FCloseQuery:=False;
  CloseQueryText:='';
  FCurrentGridIndex:=0;

  FReject:=False;
  For ff in FIDCLMain.GetForms do
  begin
    If Assigned(ff) Then
      If ff.IsSingle and (ff.DialogName=DialogName) Then
      begin
        FReject:=True;
        Exit;
        break;
      end;
  end;

  For ff in FIDCLMain.GetForms do
  begin
    If Assigned(ff) Then
      If ff.FormStyle=fsStayOnTop Then
      begin
        {$IFNDEF NOONTOP}
        OnTop:=True;
        {$ENDIF}
        break;
      end;
  end;

  FNameSpace:=NameSpace;
  FVariables:=FIDCLMain.Variables;
  FParser:=TDCLValuseParser.Create(FNameSpace.CurrentNamespace, FUserLevel, FVariables);
  FParser.SetConnector(FDBConnector);
  FOPL:=OPL;
  FGrids:=TList<IDCLGrid>.Create;

  FForm.Height:=DefaultFormHeight;
  FForm.Width:=DefaultFormWidth;
  FForm.Position:=poScreenCenter;
  FIsSingle:=False;

  {$IFNDEF EMBEDDED}
  If Assigned(Application.MainForm) and not Modal then
    If Application.MainForm.FormStyle=fsMDIForm Then
      FormStyle:=fsMDIChild;
  {$ENDIF}

  FFormMenu:=TMainMenu.Create(FForm);
  FFormMenu.Images:=FIDCLMain.GetImageList;

  AddMainItem(InitCap(GetDCLMessageString(msSettings)), nil);
  AddSubItem(GetDCLMessageString(msResetFieldsSettings), ptNone, ResetFieldsSettings);

  AddSplitter;
  AddCloseFormItem;

  if ShowFormPanel then
  begin
    FormBar:=Application.MainForm.FindComponent(ToolPanelName) as TToolBar;
    if Assigned(FormBar) then
    begin
      TB:=TFormPanelButton.Create(FForm);
      TB.Parent:=FormBar;
      TB.Images:=FormBar.Images;
      TB.Alignment:=taLeftJustify;
      TB.Height:=FormPanelButtonHeight;
      TB.OnClick:=ToolButtonClick;
      TB.Constraints.MinWidth:=100;
      TB.Constraints.MaxWidth:=FormPanelButtonWidth;
      TB.Constraints.MinHeight:=FormPanelButtonHeight;
      TB.Constraints.MaxHeight:=FormPanelButtonHeight;
      TB.Tag:=FForm.Tag;
      TB.Margin:=PanelButtonTextRight;
      TB.ImageIndex:=NewDialogImage;
      TB.Font.Style:=[fsItalic];
      TB.AutoSize:=True;
    end;
  end;

  FStatusBar:=TStatusBar.Create(FForm);
  FStatusBar.SimplePanel:=False;
  FStatusBar.Parent:=FForm;
  FStatusBar.Panels.Add;
  FStatusBar.Panels.Add;
  FStatusBar.Panels.Add;
  FStatusBar.Panels[0].Width:=100;
  FStatusBar.Panels[1].Width:=80;

  FirstPage:=True;
  FCurrentGrid:=AddMainPage(Query, Data);

  if Assigned(OPL) then
  begin
    Command:=TDCLCommand.Create(FIDCLMain, FNameSpace, Self, FCurrentGrid);
    if Assigned(ReturnValueParams) and ReturnValueParams.Multiselect then
      FCurrentGrid.MultiSelect:=True;

    ///Show;
    for SrcLine in OPL do
    begin
      if (Pos('//', SrcLine.Trim)=1) or (SrcLine='') then
        Continue;

      If IsLexem('SetAccessLevel=', SrcLine) then
      begin
        tmpS:=SrcLine;
        TranslateVal(tmpS, FCurrentGrid, True);
        tmpS:=FindParam('SetAccessLevel=', tmpS);

        if IsUserLevel(tmpS) then
          FUserLevel:=TranslateStrToUserLevel(tmpS)
        else
        if IsDigit(tmpS) then
          FUserLevel:=TranslateDigitToUserLevel(StrToIntEx(tmpS));
      end;

      If IsLexem('UserAccessRaight=', SrcLine) then
      begin
        tmpS:=SrcLine;
        TranslateVal(tmpS, FCurrentGrid, True);
        tmpS:=FindParam('UserAccessRaight=', tmpS);

        if IsUserLevel(tmpS) then
          UserLevelLocal:=TranslateStrToUserLevel(tmpS)
        else
        if IsDigit(tmpS) then
          UserLevelLocal:=TranslateDigitToUserLevel(StrToIntEx(tmpS));

        If UserLevelLocal>FUserLevel Then
        begin
          ShowErrorMessage(0, GetDCLMessageString(msNotAllowOpenForm));
          FReject:=True;
          Exit;
        end;
      end;

      if IsLexem('[Page]', SrcLine) then
      begin
        if not FirstPage then
          FCurrentGrid:=AddMainPage(FCurrentGrid.Query, FCurrentGrid.Data);
        FirstPage:=False;
      end;

      if IsLexem('Title=', SrcLine) then
      begin
        tmpS:=SrcLine;
        TranslateVal(tmpS, FCurrentGrid, True);
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
        TranslateVal(tmpS, FCurrentGrid, True);
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
        TranslateVal(tmpS, FCurrentGrid, True);
        tmpS:=FindParam('OnTop=', tmpS);
        {$IFNDEF NOONTOP}
        OnTop:=tmpS='1';
        {$ENDIF}
      end;

      If IsLexem('Single;', SrcLine) then
      begin
        FIsSingle:=True;
      end;

      Command.RunCommand(SrcLine);
      if Assigned(FCurrentGrid) then
      begin
        FCurrentGrid.ExecScriptLine(SrcLine);
      end;
    end;
    Command:=nil;
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
    FForm.Height:=(56*8)+110;
    FForm.Width:=((FieldsCount div 8)+1)*(EditWidth+FieldsStepLeft*3);
  end;

  {$IFNDEF NOONTOP}
  If OnTop then  // Мешает отладке
    FormStyle:=fsStayOnTop;
  {$ENDIF}
  if not Modal then
  begin
    Show;
  end;
end;

destructor TDCLForm.Destroy;
begin
  FreeAndNil(FParser);
  FParentForm:=nil;
  FParentPanel:=nil;
  FIDCLMain:=nil;
  inherited Destroy;
end;

function TDCLForm.GetForm: TForm;
begin
  Result:=FForm;
end;

procedure TDCLForm.RefreshForm;
var
  Grid: IDCLGrid;
begin
  for Grid in FGrids do
  begin
    Grid.ReFreshData;
  end;
end;

procedure TDCLForm.OnActivateForm(Sender: TObject);
var
  i: Integer;
  TB: TFormPanelButton;
  ff: IDCLForm;
begin
  If ShowFormPanel and Assigned(FormBar) Then
  begin
    if FormBar.ControlCount>0 then
    begin
      For ff in FIDCLMain.GetForms do
      begin
        If Assigned(ff) Then
        begin
          TB:=nil;
          for i:=1 to FormBar.ControlCount do
          begin
            if FormBar.Controls[i-1].Owner=ff.GetForm then
            begin
              TB:=FormBar.Controls[i-1] as TFormPanelButton;
              break;
            end;
          end;

          If Assigned(TB) Then
          begin
            If Screen.ActiveForm=ff.GetForm Then
            begin
              TB.ImageIndex:=ActiveDialogImage;
              TB.Font.Style:=[fsBold];
            end
            Else
            begin
              TB.ImageIndex:=InActiveDialogImage;
              TB.Font.Style:=[];
            end;
          end;
        end;
      end;
    end;
  end;
end;

procedure TDCLForm.SetInfoStatus(const Str: String);
begin
  FStatusBar.Panels[StatusInfo].Text:=Str;
end;

procedure TDCLForm.AddInfoStatus(const Str: String; Width: Integer);
var
  Panel: TStatusPanel;
begin
  Panel:=FStatusBar.Panels.Add;
  Panel.Text:=Str;
  if Width>10 then
    Panel.Width:=Width;
end;

procedure TDCLForm.SetStatusNum(const Str: String; Num, Width: Integer);
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
  while FStatusBar.Panels.Count>StatusInfo+1 do
    FStatusBar.Panels.Delete(FStatusBar.Panels.Count-1);
end;

procedure TDCLForm.GetValueProc(Value: TReturnFormValue);
begin
  if Assigned(Self.GetParentDialog) and Assigned(Value) then
    FIDCLMain.GetValueProc(FNameSpace, Self.GetParentDialog, Value);
end;

procedure TDCLForm.Hide;
begin
  FForm.Hide;
end;

procedure TDCLForm.Show;
begin
  FForm.Show;
end;

procedure TDCLForm.ShowOnTop;
begin
  FForm.ShowOnTop;
end;

function TDCLForm.ShowModal: Integer;
begin
  Result:=FForm.ShowModal;
end;

procedure TDCLForm.SetFocus;
begin
  FForm.SetFocus;
end;

procedure TDCLForm.Close;
begin
  FForm.Close;
end;

procedure TDCLForm.SetDBStatus(Str: String);
begin
  FStatusBar.Panels[StatusDB].Text:=Str;
end;

procedure TDCLForm.SaveFormPos;
var
  ConfigPath, Section: String;
  Settings: TIniFile;
begin
  if GPT.DialogsSettings and (Self.WindowState=wsNormal) then
  begin
    ConfigPath:=GPT.AppConfigDir+FormConfigDir+PathDelim+'Base_'+GPT.BaseID+PathDelim+'Forms'+PathDelim+FDialogName+PathDelim;
    if not DirectoryExists(ConfigPath) then
      ForceDirectories(ConfigPath);

    Section:='Position';
    if Self.FormStyle=fsMDIChild then
      Section:=Section+'MDI';
    if Assigned(FReturnValueParams) then
      Section:=Section+'Choose';

    try
      Settings:=TIniFile.Create(ConfigPath+'Settings.ini', TEncoding.UTF8);
      Settings.WriteInteger(Section, 'Top', FForm.Top);
      Settings.WriteInteger(Section, 'Left', FForm.Left);
      Settings.WriteInteger(Section, 'Height', FForm.Height);
      Settings.WriteInteger(Section, 'Width', FForm.Width);
    finally
      FreeAndNil(Settings);
    end;
  end;
end;

procedure TDCLForm.ForceClose;
begin
  FCloseQuery:=False;
  Close;
end;

end.

