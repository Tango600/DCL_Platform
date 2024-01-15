unit uDCLForm;
{$I DefineType.pas}

interface

uses
  Classes, SysUtils, Forms, DB, Generics.Collections, Controls, ComCtrls,
  Graphics, Menus,
  uDCLData, uDCLTypes, uDCLConst, uStringParams, uDCLQuery, uIDCLMain,
  uDCLMeasurements, uDCLDBConnector, uDCLUtils, uDCLVariables, uDCLMultiLang,
  uIDCLCommand, uReturnFormValue, uIDCLForm, uIDCLGrid, uDCLImages;

type

  { TDCLForm }

  TDCLForm=class(TInterfacedObject, IDCLForm)
  private
    FForm: TForm;
    FReject, FFirstPage, FormCanClose, FCloseQuery: Boolean;
    FIDCLMain: IDCLMain;
    FDBConnector: TDCLDBConnector;
    FNameSpace, FDialogName, CloseQueryText: String;
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
    FCurrentGrid: IDCLGrid;
    FStatusBar: TStatusBar;
    FReturnValueParams: TReturnValueParams;
    FUserLevel: TUserLevelsType;
    FIsSingle: Boolean;
    FStackLevel: Integer;

    //region TForm
    procedure SetWindowState(Value : TWindowState);
    function GetWindowState: TWindowState;
    function GetShowing: Boolean;
    function GetCapt: String;
    procedure SetCapt(Value: String);
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

    procedure AddMainPage(const Query: TDCLQuery; const Data: TDataSource);
    function AddGrid(const ParentControl: TWinControl; SurfType: TDataControlType;
      const Query: TDCLQuery; const Data: TDataSource): IDCLGrid;

    procedure AddMainItem(Caption: String; Action: TNotifyEvent);
    procedure AddSubItem(Caption: String; Pict: TPicturesTypes; Action: TNotifyEvent);
    procedure AddCloseFormItem;
    procedure AddSplitter;

    procedure SetReturnValueParams(Value: TReturnValueParams);
    function GetReturnValueParams: TReturnValueParams;

    procedure ResetFieldsSettings(Sender: TObject);
    procedure CloseDialogCommand(Sender: TObject);

    procedure TranslateVal(var Params: String; CheckParams: Boolean);

    procedure FormShow(Sender: TObject);
    procedure OnActivateForm(Sender: TObject);
    procedure OnFormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure OnFormCloseQuery(Sender: TObject; var CanClose: Boolean);

    procedure SetRecordsStatus(Str: String); overload;

    function GetCurrentGrid: IDCLGrid;
    function GetDialogName: String;
    procedure SaveFormPos;
  public
    constructor Create(const IDCLMain: IDCLMain; DialogName, NameSpace: String; const ParentForm: IDCLForm;
      OPL: TStringList; UserLevel: TUserLevelsType;
      const Query: TDCLQuery; const Data: TDataSource;
      ReturnValueParams: TReturnValueParams=nil; Modal: Boolean=False); overload;
    destructor Destroy; override;

    function GetForm: TForm;

    procedure ForceClose;
    procedure RefreshForm;

    procedure SetRecordsStatus(RecNo, RecordCount: LongInt); overload;
    procedure SetDBStatus(Str: String);

    procedure SetInfoStatus(Str: String);
    procedure AddInfoStatus(Str: String; Width: Integer);
    procedure SetStatusNum(Str: String; Num, Width: Integer);
    procedure DeleteStatus(Num: Integer);
    procedure DeleteAllStatus;

    procedure GetValueProc(Value: TReturnFormValue);

    property Grids: TList<IDCLGrid> read GetGrids;
    property CurrentGrid: IDCLGrid read GetCurrentGrid;
    property DialogName: String read GetDialogName;
    property IsSingle: Boolean read GetIsSingle;
    property ReturnValueParams: TReturnValueParams read GetReturnValueParams write SetReturnValueParams;
    property ParentDialog: IDCLForm read GetParentDialog;
    property Reject: Boolean read IsReject;
    property RightsLevel: TUserLevelsType read GetUserLevel;
    property StackLevel: Integer read GetStackLevel write SetStackLevel;
  public
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
  end;

implementation

uses
  IniFiles,
  uDCLCommand, uDCLGrid, uDCLValuesParser, uDCLMessages, uDCLGlobalVariables;

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

procedure TDCLForm.SetCapt(Value: String);
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
  i: Integer;
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
        for g in FGrids do
        begin
          if g.GetComponent=c then
          begin
            FCurrentGrid:=g;
            break;
          end;
        end;
      end;
    end;
  end;
end;

procedure TDCLForm.AddMainPage(const Query: TDCLQuery; const Data: TDataSource);
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
  //FTab.PageControl:=FPages;

  FPages.ActivePage.Align:=alClient;
  FParentPanel:=FTab.PageControl.Pages[pc];

  FCurrentGrid:=AddGrid(FParentPanel, dctMainGrid, Query, Data);

  FPages.ActivePage:=FPages.Pages[pc];
  FPages.ActivePageIndex:=pc;
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

procedure TDCLForm.AddMainItem(Caption: String; Action: TNotifyEvent);
begin
  FMainItemMenu:=TMenuItem.Create(FFormMenu);
  FMainItemMenu.ImageIndex:=FIDCLMain.GetImageIndex(ptTools);
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
  Parser:=TDCLValuseParser.Create(FNameSpace, FUserLevel, FVariables);
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
  for F in FIDCLMain.GetForms do
  begin
    if (F.ParentDialog as TDCLForm)=Self then
      F.ForceClose;
  end;

  for Grid in FGrids do
  begin
    Grid.CloseComponent;
  end;

  SaveFormPos;
  FIDCLMain.ReleaseForm(Self);
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

function TDCLForm.GetCurrentGrid: IDCLGrid;
begin
  Result:=FCurrentGrid;
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

constructor TDCLForm.Create(const IDCLMain: IDCLMain; DialogName, NameSpace: String; const ParentForm: IDCLForm;
  OPL: TStringList; UserLevel: TUserLevelsType;
  const Query: TDCLQuery; const Data: TDataSource;
  ReturnValueParams: TReturnValueParams=nil; Modal: Boolean=False);
var
  Command: IDCLCommand;
  SrcLine, tmpS, tmpS1: String;
  ff: IDCLForm;
  g: IDCLGrid;
  OnTop: Boolean;
  FieldsCount: Integer;
  UserLevelLocal: TUserLevelsType;
begin
  inherited Create;
  FIDCLMain:=IDCLMain;

  FForm:=TForm.Create(Application);
  FForm.OnActivate:=OnActivateForm;
  FForm.OnShow:=FormShow;
  FForm.OnClose:=OnFormClose;
  FForm.OnCloseQuery:=OnFormCloseQuery;
  FDialogName:=DialogName;
  FDBConnector:=FIDCLMain.GetDBConnector;
  FFirstPage:=True;
  FReturnValueParams:=ReturnValueParams;
  FParentForm:=ParentForm;
  FUserLevel:=UserLevel;
  FCloseQuery:=False;
  CloseQueryText:='';
  FormCanClose:=True;

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
        OnTop:=True;
        break;
      end;
  end;

  FNameSpace:=NameSpace;
  FVariables:=FIDCLMain.GetVariables;
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

  AddMainPage(Query, Data);

  if Assigned(OPL) then
  begin
    Command:=TDCLCommand.Create(FIDCLMain, FNameSpace, Self, FCurrentGrid);
    if Assigned(ReturnValueParams) and ReturnValueParams.Multiselect then
      FCurrentGrid.MultiSelect:=True;

    ///Show;
    for SrcLine in OPL do
    begin
      if Pos('//', SrcLine.Trim)=1 then
        Continue;

      If IsLexem('SetAccessLevel=', SrcLine) then
      begin
        tmpS:=SrcLine;
        TranslateVal(tmpS, True);
        tmpS:=FindParam('SetAccessLevel=', tmpS);
        Case GetStringDataType(tmpS) of
        idDigit:
        FUserLevel:=TranslateDigitToUserLevel(StrToIntEx(tmpS));
        idUserLevel:
        FUserLevel:=TranslateDigitToUserLevel(tmpS);
        end;
      end;

      If IsLexem('UserAccessRaight=', SrcLine) then
      begin
        tmpS:=SrcLine;
        TranslateVal(tmpS, True);
        tmpS:=FindParam('UserAccessRaight=', tmpS);
        Case GetStringDataType(tmpS) of
        idDigit:
        UserLevelLocal:=TranslateDigitToUserLevel(StrToIntEx(tmpS));
        idUserLevel:
        UserLevelLocal:=TranslateDigitToUserLevel(tmpS);
        end;
        If UserLevelLocal>FUserLevel Then
        begin
          ShowErrorMessage(0, GetDCLMessageString(msNotAllowOpenForm));
          FReject:=True;
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
    FForm.Height:=(56*8)+110;
    FForm.Width:=((FieldsCount div 8)+1)*280;
  end;

  {$IFNDEF NOONTOP}
  If OnTop then  // Мешает отладки
    FormStyle:=fsStayOnTop;
  {$ENDIF}
  if not Assigned(FReturnValueParams) and not Modal then
  begin
    Show;
  end;
end;

destructor TDCLForm.Destroy;
var
  i: Integer;
begin
  for i:=1 to FGrids.Count do
  begin
    FGrids[i-1]:=nil;
  end;
  FreeAndNil(FGrids);
  FParentForm:=nil;
  FParentPanel:=nil;
  FCurrentGrid:=nil;
  FForm.Release;
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

procedure TDCLForm.GetValueProc(Value: TReturnFormValue);
begin
  if Assigned(Self.ParentDialog) and Assigned(Value) then
    FIDCLMain.GetValueProc(FNameSpace, Self.ParentDialog, Value);
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
  FForm.Release;
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
    ConfigPath:=AppConfigDir+FormConfigDir+'Base_'+GPT.BaseID+PathDelim+'Forms'+PathDelim+FDialogName+PathDelim;
    if not DirectoryExists(ConfigPath) then
      ForceDirectories(ConfigPath);

    Section:='Position';
    if Self.FormStyle=fsMDIChild then
      Section:=Section+'MDI';
    if Assigned(FReturnValueParams) then
      Section:=Section+'Choose';

    Settings:=TIniFile.Create(ConfigPath+'Settings.ini', TEncoding.UTF8);
    Settings.WriteInteger(Section, 'Top', FForm.Top);
    Settings.WriteInteger(Section, 'Left', FForm.Left);
    Settings.WriteInteger(Section, 'Height', FForm.Height);
    Settings.WriteInteger(Section, 'Width', FForm.Width);
    FreeAndNil(Settings);
  end;
end;

procedure TDCLForm.ForceClose;
begin
  FCloseQuery:=False;
  Close;
end;

end.

