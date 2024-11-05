unit uDCLGrid;
{$I DefineType.pas}

interface

uses
{$IFDEF MSWINDOWS}
  Windows,
{$ENDIF}
  Classes, SysUtils, Controls, Forms, DB, Generics.Collections, ToolWin,
  ComCtrls, StdCtrls, ExtCtrls, Graphics, DBCtrls, DBGrids, Grids,
  CheckLst, Menus, ClipBrd, DBExtCtrls, LCLType, variants,
  uDCLData, uDCLTypes, uDCLConst, uDCLVariables, uStringParams, uIDCLMain,
  uDCLDBConnector, uDCLQuery, uDCLMeasurements, uDBUtils, uDCLMultiLang,
  uDCLCommandButton, uDCLField, uDCLMessages, uDCLImages, cMediaFieldGroup,
  uDCLBaseLayoutManger, uDCLHorizontalFieldLayoutManger, uVariableNamespace,
  uDCLDBAwareTypes, uIDCLCommand, uIDCLGrid, uIDCLForm, uDBControlsTypes,
  uDCLVerticalFieldLayoutManger;

type
  TStructureField=class
    FieldName: String;
  end;

  TSortField=class
    FieldName: String;
    Order: TSortOrder;
  end;

  { TDCLGrid }

  TDCLGrid=class(TInterfacedObject, IDCLGrid)
  private
    FIDCLMain: IDCLMain;
    FParentControl: TWinControl;
    FBasePanel: TPanel;
    FNameSpace: TVariableNamespace;
    FDependField, FMasterDataField, FMasterValueVariableName, FSummFieldsSet,
      FNavigButtonsExpr, FSeed, FDialogName: String;
    FForm: IDCLForm;
    FDBGrid: TDBGrid;
    FFieldsCount, FToolPanelHeight, FFilterPanelHeight,
    FToolButtonsCount, FCurrentTablePartIndex, FFilterLeft: Integer;
    FToolsPanel: TPanel;
    FNavig: TDBNavigator;
    FindFields: TStringList;
    FMainPanel: TPanel;
    FFieldsPanel: TScrollBox;
    FindGrid: TStringGrid;
    FButtonPanel:  TDCLButtonPanel;
    FButtonFlowPanel: TFlowPanel;
    FFiltersPanel: TDCLFilterPanel;
    FDBConnector: TDCLDBConnector;
    FQuery: TDCLQuery;
    FQueryes: TDictionary<TQueryType, TDCLQueryStore>;
    FData, FExtData, FSumData: TDataSource;
    FButtons: TList<TDCLCommandButton>;
    FDataControlType: TDataControlType;
    FGridStyle: TGridStyle;
    FReadFieldsMode, FMultiSelectMode, FReadOnly, FDataReadOnly, FNavigatorVisible,
      FFlatNavig, FNoDataField, FNoButtonPanel, FindProcess, FPrintTool, CloseButton: Boolean;
    FTableParts, FLookupTables: TList<IDCLGrid>;
    FDCLFields: TList<TDCLField>;
    FCurrentField: TDCLField;
    FFieldParsingMode: TFieldParsingMode;
    FToolBar: TToolBar;
    FToolBarSplitter, FToolBarButtonPrint, FToolBarButtonStruct, FToolBarButtonFind: TToolButton;
    PartSplitter: TSplitter;
    FTablePartsPages: TPageControl;
    FFilters: TList<TDBFilter>;
    FCalendars: TList<TDCLCalendar>;
    FOrdersFields: TList<TSortField>;
    FOrderByFields, FNotOrderByFields: TStringList;
    FSumQuery: TDCLDialogQuery;
    FSummGrid: TDBGrid;
    FEvents: TList<TDCLEvent>;
    FNotAllowedOperations: TList<TNotAllowedOperation>;
    FBrushColors: TList<TBrushColor>;
    FStructureList: TCheckListBox;
    PopupGridMenu: TPopupMenu;
    FLocalBookmark: TBookmark;
    FFieldLayout: TDCLBaseLayoutManger<TDCLField>;

    procedure OnNavigClick(Sender: TObject; Button: TDBNavButtonType);

    function GetDependField: String;
    procedure SetDependField(Value: String);

    function GetMasterDataField: String;
    procedure SetMasterDataField(Value: String);

    function GetMasterValueVariableName: String;
    procedure SetMasterValueVariableName(Value: String);

    Function GetUserLevel: TUserLevelsType;

    procedure ParseButton(ScrLine: String; const Grid: IDCLGrid);

    function FindDCLFieldByName(FieldName: String): TDCLField;
    function GetFieldsCount: Integer;

    procedure OpenQuery(QText: String);
    procedure SetNewQuery(Data: TDataSource);

    procedure TranslateVal(var Params: String; CheckParams: Boolean);

    function GetFlatNavigator: Boolean;
    procedure SetFlatNavigator(Value: Boolean);
    function GetNavigatorVisible: Boolean;
    procedure SetNavigatorVisible(Value: Boolean);
    procedure ClickNavigator(Sender: TObject; Button: TNavigateBtn);

    procedure SetDataStatus(Status: TDataStatus);
    procedure UpdateAllControls;

    procedure SetQueryEvents(Query: TDCLQuery);
    procedure ParseEvents(ScrStr: String; const Grid: IDCLGrid);
    procedure ExecEvents(EventType: TEventsEnum);

    // DataEvents
    procedure AfterInsert(Data: TDataSet);
    procedure ScrollDB(Data: TDataSet);
    procedure AfterOpen(Data: TDataSet);
    procedure AfterEdit(Data: TDataSet);
    procedure AfterPost(Data: TDataSet);
    procedure AfterCancel(Data: TDataSet);

    procedure BeforeOpen(Data: TDataSet);
    procedure BeforeScroll(Data: TDataSet);
    procedure BeforeEdit(Data: TDataSet);
    procedure BeforePost(Data: TDataSet);

    procedure OnDelete(Data: TDataSet);
    // End DataEvents

    function GetQuery: TDCLQuery;
    function GetData: TDataSource;
    function GetTableParts: TList<IDCLGrid>;

    function GetReadOnly: Boolean;
    procedure SetReadOnly(Value: Boolean);

    procedure FindProc;
    procedure StartFind;
    procedure ApplyFind;
    procedure Find(Sender: TObject);
    procedure FindGridOnSelectCell(Sender: TObject; aCol, aRow: Integer;
      var CanSelect: Boolean);

    procedure Print(Sender: TObject);

    function GetSortField(const FieldName: String): TSortField;

    procedure GridDblClick(Sender: TObject);
    procedure GridColumnClick(Column: TColumn);
    procedure GridKeyPress(Sender: TObject; var UTF8Key: TUTF8Char);
    procedure Grid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure RefreshGridColumns;

    function SortDB(var SQL: String): String;
    procedure ReDrawColumns;

    function GetEdits: TList<TDCLEdit>;

    procedure AddColumn(Field: TDCLField);
    procedure ParseFields(ScrLine: String);
    procedure AddAstericsFields;

    procedure CreateToolPanel;
    procedure OnToolPanelResize(Sender: TObject);
    procedure AdjustToolPanel;

    procedure CreateFilterPanel;
    procedure AdjustFilterPanel(Height: Integer);

    procedure OnResizeFilterPanel(Sender: TObject);
    procedure OnGridResize(Sender: TObject);

    procedure AddDropBox(Field: TDCLField; Scr: String);
    procedure DropListOnSelectItem(Sender: TObject);

    procedure AddDBDateEdit(Field: TDCLField);

    procedure AddMediaFieldGroup(Field: TDCLField; GroupType: TGroupType);

    procedure AddDBEdit(Field: TDCLField);
    procedure DBEditClick(Sender: TObject);

    procedure ClickCommandButton(Sender: TObject);

    function AddTablePartObject(Title: String; Data: TDataSource; Style: TGridStyle): TDCLGrid;
    procedure AddTablePart(Line: String);
    procedure ChangePartTabPage(Sender: TObject);

    procedure AddContextButton(Field: TDCLField; Scr: String);
    procedure ContextFieldButtonsClick(Sender: TObject);

    procedure AddFieldBox(Field: TDCLField; FieldBoxType: TFieldBoxType; Scr: String);
    procedure FieldBoxOnClick(Sender: TObject);
    procedure FieldBoxOnEdit(Sender: TObject);
    procedure FieldBoxKeyPress(Sender: TObject; var Key: Char);

    procedure AddLookUp(Field: TDCLField; Scr: String);
    procedure LookupOnClick(Sender: TObject);

    procedure AddLookupTable(Field: TDCLField; Scr: String);

    procedure AddCalendar(ScrLine: String);
    procedure CalendarOnChange(Sender: TObject);

    procedure AddCheckBox(Field: TDCLField; Scr: String);
    procedure AddSimplyCheckBox(Field: TDCLField; Scr: String);
    procedure AddDBCheckBox(Field: TDCLField; Scr: String);
    procedure CheckOnClick(Sender: TObject);

    function GetSummQuery: String;
    procedure AddSumGrid(ScrLine: String);

    procedure AddDateBox(Field: TDCLField; Scr: String);
    procedure OnChangeDateBox(Sender: TObject);

    function ParseCommonFilter(ScrLine: String): TDBFilter;
    procedure ParseDBFilter(const Filter: TDBFilter; const Grid: TDCLGrid);
    procedure ParseContextFilter(const Filter: TDBFilter; const Grid: TDCLGrid);
    procedure ParseComboFilter(const Filter: TDBFilter; const Grid: TDCLGrid);
    procedure OnFilterNotCheckClick(Sender: TObject);
    procedure ExecFilter(Sender: TObject);
    procedure OnContextFilter(Sender: TObject; var Key: Word; Shift: TShiftState);

    function QueryBuilder: String;
    function GetConditionsFromFindGrid: String;
    function GetConditionsFromFilters: String;

    procedure Choose;

    procedure SetMultiSelect(Value: Boolean);
    function GetMultiSelectMode: Boolean;

    procedure SetGridStyle(Value: TGridStyle);
    function GetGridStyle: TGridStyle;

    function GetControlType: TDataControlType;

    function GetCurrentTablePart: IDCLGrid;

    function GetSQLFromStorage: String;

    procedure ClearNotAllowedOperations;
    procedure ExcludeNotAllowedOperation(Operation: TNotAllowedOperation);
    procedure AddNotAllowedOperation(Operation: TNotAllowedOperation);
    function FindNotAllowedOperation(Operation: TNotAllowedOperation): Boolean;

    procedure AddBrushColor(const Line: String);
    procedure GridDrawDataCell(Sender: TObject; Const Rect: TRect; DataCol: Integer;
      Column: TColumn; State: TGridDrawState);

    function GetFieldSetting(var List: TList<TGridFieldSetting>; FieldName: String): TGridFieldSetting;

    function CalculateSeed: String;
    function GetGridSeed: String;

    procedure SetNoDataField(Value: Boolean);
    function GetNoDataField: Boolean;

    procedure SetPrintTool(Value: Boolean);
    function GetPrintTool: Boolean;

    procedure Structure(Sender: TObject);
    function IsGridColumnExists(FieldName: String): Boolean;

    procedure AddPopupItem(Caption: String; Action: TPopupMenuAction; AChortCutKey: String; PictType: TPicturesTypes);
    procedure AddPopupSeparator;
    procedure OnPopupMenuClick(Sender: TObject);
    procedure PopupMenuOnPopup(Sender: TObject);

    procedure SetTempFilter;
    procedure DeleteTempFilter;

    function GetSelectedRows: TBookmarkList;
    function LoadDBGridFieldsPos: TList<TGridFieldSetting>;
    procedure GetDBGridFieldsPos(var Settings: TStringList);

    procedure Undo;
    procedure PCopy;
    procedure Cut;
    procedure Paste;

    procedure AddField(Field: TDCLField);

    function GetComponent: TWinControl;
    procedure Show;
    procedure Open;
    procedure Close;
    procedure CloseComponent;
    procedure ReFreshData;

    procedure ExecScriptLine(ScrStr: String);
    procedure Prepeare;

    procedure SetSQL(SQL: String);
    procedure SetNavigatorButtonsSet(ButtonsExpr: String);
    procedure ParseNavigatorButtons(ButtonsExpr: String);

    procedure AddButton(Button: TDCLCommandButton);
    procedure AddFilter(Filter: TDBFilter);

    procedure AddEvent(EventType: TEventsEnum; ScriptName: String);

    function CheckEdits: Boolean;
    procedure NotifyEditFieldError(Field: TDCLField);

    procedure ResetFieldsSettings;
  public
    constructor Create(const IDCLMain: IDCLMain; const NameSpace: TVariableNamespace; const Form: IDCLForm; const ParentControl: TWinControl;
      SurfType: TDataControlType; const Query: TDCLQuery; const Data: TDataSource); overload;
    destructor Destroy; override;
  end;

  { TLookupTable }

  TLookupTable=class(TPanel)
  private
    FGrid: IDCLGrid;
  public
    constructor Create(const IDCLMain: IDCLMain; NameSpace: TVariableNamespace; const Form: IDCLForm;
      ParentControl: TWinControl; Data: TDataSource); overload;
    destructor Destroy; override;

    property DCLGrid: IDCLGrid read FGrid;
  end;

implementation

uses
  EditBtn, LCLProc, uRunProgram, uReturnFormValue, cMyFilterCombo, StrUtils,
  uDCLValuesParser, uSQLParser, uDCLUtils, uSystemUtils, LazUTF8, uDCLException,
  uPrintBase, uDCLGlobalVariables, uDCLMD5, uExpressionParser, uDCLCommand,
  uConvertEx, uStringUtils;

{ TLookupTable }

constructor TLookupTable.Create(const IDCLMain: IDCLMain; NameSpace: TVariableNamespace;
  const Form: IDCLForm; ParentControl: TWinControl; Data: TDataSource);
begin
  inherited Create(ParentControl);
  Self.Parent:=ParentControl;

  FGrid:=TDCLGrid.Create(IDCLMain, NameSpace, Form, Self, dctLookupGrid, nil, Data);
end;

destructor TLookupTable.Destroy;
begin
  FGrid:=nil;
  inherited Destroy;
end;

{ TDCLGrid }

procedure TDCLGrid.OnNavigClick(Sender: TObject; Button: TDBNavButtonType);
begin
  if Button=nbRefresh then
  begin
    ReFreshData;
  end;
end;

function TDCLGrid.GetDependField: String;
begin
  Result:=FDependField;
end;

procedure TDCLGrid.SetDependField(Value: String);
begin
  FDependField:=Value;
end;

function TDCLGrid.GetMasterDataField: String;
begin
  Result:=FMasterDataField;
end;

procedure TDCLGrid.SetMasterDataField(Value: String);
begin
  FMasterDataField:=Value;
end;

function TDCLGrid.GetMasterValueVariableName: String;
begin
  Result:=FMasterValueVariableName;
end;

procedure TDCLGrid.SetMasterValueVariableName(Value: String);
begin
  FMasterValueVariableName:=Value;
end;

function TDCLGrid.GetUserLevel: TUserLevelsType;
begin
  Result:=FForm.RightsLevel;
end;

procedure TDCLGrid.ParseButton(ScrLine: String; const Grid: IDCLGrid);
var
  ButtonParams: TDCLCommandButton;
  flg: Boolean;
  tmpS: String;
  v1: Integer;
  DigitType: TIsDigitType;

  Function FindDisableAction(const Action: String): Boolean;
  Var
    iI: Byte;
  Begin
    Result:=False;
    For iI:=1 To ToolCommandsCount Do
      If LowerCase(ToolButtonsCmd[iI])=LowerCase(Action) Then
      Begin
        Result:=True;
        Break;
      End;
  End;

begin
  If not FindDisableAction(LowerCase(FindParam('action=', ScrLine))) then
  begin
    flg:=True;
    tmpS:=FindParam('AccessLevel=', ScrLine);
    If tmpS<>'' Then
    begin
      flg:=False;
      DigitType:=GetStringDataType(tmpS);
      Case DigitType of
        idDigit: flg:=TranslateDigitToUserLevel(StrToIntEx(FindParam('AccessLevel=', ScrLine)))<=GetUserLevel;
        idUserLevel: flg:=TranslateDigitToUserLevel(FindParam('AccessLevel=', ScrLine))<=GetUserLevel;
      end;
    end;

    If flg Then
    begin
      ButtonParams:=TDCLCommandButton.Create(FDBConnector);
      ButtonParams.Caption:=InitCap(FindParam('label=', ScrLine));
      If FindParam('_Default=', ScrLine)='1' Then
        ButtonParams.Default:=True;

      If FindParam('_Cancel=', ScrLine)='1' Then
        ButtonParams.Cancel:=True;

      If FindParam('Host=', ScrLine)='1' then
        ButtonParams.Host:=True;

      ButtonParams.Hint:=InitCap(FindParam('hint=', ScrLine));

      tmpS:=FindParam('Action=', ScrLine);
      If tmpS<>'' Then
      begin
        ButtonParams.Command:=tmpS+';';
        ButtonParams.Pict:=FindParam('Action=', ScrLine);
      end
      Else
      begin
        If PosEx('CommandName=', ScrLine)<>0 Then
          ButtonParams.Command:=FindParam('commandname=', ScrLine);

        ButtonParams.Pict:=FindParam('Pict=', ScrLine);
      end;

      ButtonParams.ForEach:=FindParam('ForEach=', ScrLine)='1';
      if ButtonParams.ForEach then
        ButtonParams.ExecAfter:=FindParam('ExecAfter=', ScrLine);

      If PosEx('bold', FindParam('FontStyle=', ScrLine))<>0 Then
        ButtonParams.FontStyle:=ButtonParams.FontStyle+[fsBold];
      If PosEx('italic', FindParam('FontStyle=', ScrLine))<>0 Then
        ButtonParams.FontStyle:=ButtonParams.FontStyle+[fsItalic];
      If PosEx('underline', FindParam('FontStyle=', ScrLine))<>0 Then
        ButtonParams.FontStyle:=ButtonParams.FontStyle+[fsUnderLine];

      flg:=FindParam('AutoSize=', ScrLine)='1';
      if flg then
        ButtonParams.Width:=-1
      else
      begin
        tmpS:=FindParam('Width=', ScrLine);
        If tmpS<>'' then
        begin
          v1:=StrToIntEx(tmpS);
          If (v1>30) and (not flg) then
            ButtonParams.Width:=v1
          else
            ButtonParams.Width:=-1;
        end
        else
        begin
            ButtonParams.Width:=ButtonWidth;
        end;
      end;

      Grid.AddButton(ButtonParams);
    end;
  end;
end;

function TDCLGrid.FindDCLFieldByName(FieldName: String): TDCLField;
var
  f: TDCLField;
begin
  Result:=nil;
  for f in FDCLFields do
  begin
    if f.FieldName.ToLower=FieldName.ToLower then
    begin
      Result:=f;
      break;
    end;
  end;
end;

function TDCLGrid.GetFieldsCount: Integer;
begin
  if Assigned(FDCLFields) then
    Result:=FDCLFields.Count
  else
    Result:=0;
end;

procedure TDCLGrid.OpenQuery(QText: String);
begin
  if (QText<>'') and (QText.Length>11) then
  begin
    FQuery.Close;
    FQuery.SQL.Clear;
    TranslateVal(QText, False);
    FQuery.SQL.Append(QText);

    try
      FQuery.Open;
    Except
      on E: Exception do
      begin
        raise TDCLException.Create(-1100, E.Message);
      end;
    end;
  end;
end;

procedure TDCLGrid.TranslateVal(var Params: String; CheckParams: Boolean);
var
  Parser: TDCLValuseParser;
begin
  Parser:=TDCLValuseParser.Create(FNameSpace.CurrentNamespace, GetUserLevel, FIDCLMain.Variables);
  Parser.ReplaceAllVariables(FNameSpace.CurrentNamespace, Params, FQuery);
  if CheckParams then
    Parser.RePlaseParams(Params, FQuery);
  Parser.RePlaceProc(Params, FQuery);
end;

function TDCLGrid.GetFlatNavigator: Boolean;
begin
  Result:=FFlatNavig;
end;

procedure TDCLGrid.SetFlatNavigator(Value: Boolean);
begin
  FFlatNavig:=Value;
end;

function TDCLGrid.GetNavigatorVisible: Boolean;
begin
  Result:=FNavigatorVisible;
end;

procedure TDCLGrid.SetNavigatorVisible(Value: Boolean);
begin
  FNavigatorVisible:=Value;
end;

procedure TDCLGrid.SetQueryEvents(Query: TDCLQuery);
begin
  Query.AfterInsert:=AfterInsert;
  Query.AfterScroll:=ScrollDB;
  Query.AfterEdit:=AfterEdit;
  Query.AfterPost:=AfterPost;
  Query.AfterCancel:=AfterCancel;
  Query.AfterDelete:=OnDelete;
  Query.AfterOpen:=AfterOpen;

  Query.BeforeOpen:=BeforeOpen;
  Query.BeforeScroll:=BeforeScroll;
  Query.BeforePost:=BeforePost;
  Query.BeforeEdit:=BeforeEdit;
end;

procedure TDCLGrid.ClickNavigator(Sender: TObject; Button: TNavigateBtn);
begin
  If Button=nbRefresh Then
    ReFreshData;
end;

procedure TDCLGrid.SetDataStatus(Status: TDataStatus);
begin
  if Status=dssChanged then
  begin
    FForm.SetDBStatus(GetDCLMessageString(msModified));
    //BaseChanged:=True;
  end;
  if Status=dssSaved then
  begin
    FForm.SetDBStatus('');
    //BaseChanged:=False;
  end;
end;

procedure TDCLGrid.UpdateAllControls;
var
  Edit: TDCLField;
  S: String;
begin
  For Edit in FDCLFields do
  begin
    if Assigned(Edit.DCLEditComponent) and Assigned(Edit.DCLEditComponent.Control) then
    begin
      if Edit.DCLEditComponent.Control is TEdit then
      begin
        If (Edit.DCLEditComponent.EditType in [fbtOutBox, fbtEditBox]) and not Edit.NoDataField Then
        begin
          If FieldExists(FQuery, Edit.FieldName) Then
            (Edit.DCLEditComponent.Control as TEdit).Text:=TrimRight(FQuery.FieldByName(Edit.FieldName).AsString);
        end;
      end;

      if Edit.DCLEditComponent.Control is TCheckBox then
      begin
        If (not Edit.NoDataField) and FieldExists(FQuery, Edit.FieldName) Then
        begin
          S:=TrimRight(FQuery.FieldByName(Edit.FieldName).AsString);
          If (S='0') or (S='') Then
            (Edit.DCLEditComponent.Control as TCheckBox).Checked:=False;
          If S='1' Then
            (Edit.DCLEditComponent.Control as TCheckBox).Checked:=True;
        end;
      end;

      if Edit.DCLEditComponent.Control is TDateTimePicker then
      If (not Edit.NoDataField) and FieldExists(FQuery, Edit.FieldName) then
      begin
        (Edit.DCLEditComponent.Control as TDateTimePicker).Date:=FQuery.FieldByName(Edit.FieldName).AsDateTime;
      end;

      if Edit.DCLEditComponent.Control is TComboBox then
        If (not Edit.NoDataField) and FieldExists(FQuery, Edit.FieldName) Then
        begin
          If GetStringDataType(FQuery.FieldByName(Edit.FieldName).AsString)=idDigit then
            (Edit.DCLEditComponent.Control as TComboBox).ItemIndex:=FQuery.FieldByName(Edit.FieldName).AsInteger
          Else
            (Edit.DCLEditComponent.Control as TComboBox).ItemIndex:=(Edit.DCLEditComponent.Control as TComboBox).Items.IndexOf(FQuery.FieldByName(Edit.FieldName).AsString);
        end;
    end;
  end;
end;

procedure TDCLGrid.AfterInsert(Data: TDataSet);
begin
  If GetUserLevel<ulWrite Then
    Data.Cancel
  Else
  begin
    If (FDependField<>'') and Assigned(Data.FindField(FDependField)) then
    Begin
      if not FNoDataField then
      begin
        If FMasterDataField<>'' Then
        begin
          Data.FieldByName(FDependField).AsString:=Data.DataSource.DataSet.FieldByName
            (FMasterDataField).AsString;
        end;
      end
      else
      begin
        if FMasterValueVariableName<>'' then
        begin
          Data.FieldByName(FDependField).AsString:=FIDCLMain.Variables[FNamespace.CurrentNamespace, FMasterValueVariableName];
        end;
      end;
    End;

    ExecEvents(evtInsert);

    SetDataStatus(dssChanged);
  end;

  UpdateAllControls;
end;

procedure TDCLGrid.ScrollDB(Data: TDataSet);
begin
  ExecEvents(evtScroll);
  if FDataControlType=dctMainGrid then
    if Assigned(FQuery) and FQuery.Active then
      FForm.SetRecordsStatus(FQuery.RecNo, FQuery.RecordCount);

  UpdateAllControls;
end;

function TDCLGrid.GetControlType: TDataControlType;
begin
  Result:=FDataControlType;
end;

procedure TDCLGrid.AfterOpen(Data: TDataSet);
begin
  if Assigned(FSumQuery) then
  begin
    FSumQuery.Close;
    FSumQuery.SQL.Text:=GetSummQuery;
    FSumQuery.Open;
  end;

  ExecEvents(evtAfterOpen);
end;

procedure TDCLGrid.AfterEdit(Data: TDataSet);
begin
  If GetUserLevel<ulWrite Then
    Data.Cancel;

  UpdateAllControls;
end;

procedure TDCLGrid.AfterPost(Data: TDataSet);
begin
  ExecEvents(evtAfterPost);
  ReFreshData;
  FIDCLMain.NotifyForms(fnaRefresh);
  UpdateAllControls;
  SetDataStatus(dssSaved);
end;

procedure TDCLGrid.AfterCancel(Data: TDataSet);
begin
  SetDataStatus(dssSaved);
  ExecEvents(evtCancel);
end;

procedure TDCLGrid.BeforeOpen(Data: TDataSet);
var
  c: TDCLCalendar;
  p: TParam;
begin
  for c in FCalendars do
  begin
    if c.ParamName<>'' then
    begin
      p:=FQuery.ParamByName(c.ParamName);
      if Assigned(p) then
      begin
        p.AsDate:=c.Value;
      end;
    end;
  end;
end;

procedure TDCLGrid.BeforeScroll(Data: TDataSet);
begin

end;

procedure TDCLGrid.BeforeEdit(Data: TDataSet);
begin

end;

procedure TDCLGrid.BeforePost(Data: TDataSet);
begin
  if CheckEdits then
  begin
    ExecEvents(evtBeforePost);
    UpdateAllControls;
  end;
end;

procedure TDCLGrid.OnDelete(Data: TDataSet);
begin
  ExecEvents(evtDelete);
  UpdateAllControls;
end;

function TDCLGrid.GetQuery: TDCLQuery;
begin
  Result:=FQuery;
end;

function TDCLGrid.GetData: TDataSource;
begin
  Result:=FData;
end;

function TDCLGrid.GetTableParts: TList<IDCLGrid>;
begin
  Result:=FTableParts;
end;

function TDCLGrid.GetReadOnly: Boolean;
begin
  Result:=FReadOnly;
end;

procedure TDCLGrid.SetReadOnly(Value: Boolean);
begin
  FReadOnly:=Value;
end;

procedure TDCLGrid.FindProc;
begin
  if not FindProcess then
    StartFind
  else
    ApplyFind;
end;

procedure TDCLGrid.StartFind;
var
  ColCaptions: TStringList;
  i, StrIndex: Integer;
begin
  if not FindProcess then
  begin
    FindProcess:=True;

    ColCaptions:=TStringList.Create;
    if not Assigned(FindGrid) then
    begin
      FindFields:=TStringList.Create;

      FindGrid:=TStringGrid.Create(FMainPanel);
      FindGrid.Parent:=FMainPanel;
      FindGrid.Align:=alBottom;
      FindGrid.DefaultColWidth:=IndicatorWidth;
      FindGrid.OnSelectCell:=FindGridOnSelectCell;

      FindGrid.FixedCols:=1;
      if Assigned(FDBGrid) then
      begin
        StrIndex:=0;
        FindGrid.RowCount:=1;
        FindGrid.FixedRows:=0;
        FindGrid.Height:=FindGrid.RowHeights[0]+AddFindGridPanelHeight;
      end
      else
      begin
        StrIndex:=1;
        FindGrid.RowCount:=2;
        FindGrid.FixedRows:=1;
        FindGrid.Height:=FindGrid.RowHeights[0]+FindGrid.RowHeights[1]+AddFindGridPanelHeight;
      end;

      FindGrid.Options:=[goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect,
        goColSizing, goEditing, goTabs];
      FindGrid.Cells[0, StrIndex]:='?';
    end;

    FindFields.Clear;
    ColCaptions.Clear;
    if Assigned(FDBGrid) then
    begin
      FindGrid.ColCount:=FDBGrid.Columns.Count+1;
      for i:=1 to FindGrid.ColCount-1 do
      begin
        FindGrid.ColWidths[i]:=FDBGrid.Columns[i-1].Width;
        FindFields.Append(FDBGrid.Columns[i-1].FieldName);
      end;
    end
    else
    begin
      FindGrid.ColCount:=FDCLFields.Count+1;
      ColCaptions.Append('-');
      for i:=1 to FDCLFields.Count do
      begin
        ColCaptions.Append(FDCLFields[i-1].Caption);
        FindFields.Append(FDCLFields[i-1].FieldName);
      end;

      for i:=1 to FindGrid.ColCount-1 do
      begin
        FindGrid.ColWidths[i]:=FilterWidth;
      end;
      FindGrid.Rows[0]:=ColCaptions;
    end;

    FindGrid.Show;
  end
end;

procedure TDCLGrid.ApplyFind;
begin
  if FindProcess then
  begin
    FindProcess:=False;
    FindGrid.Hide;
  end;

  OpenQuery(QueryBuilder);
end;

procedure TDCLGrid.Find(Sender: TObject);
begin
  FindProc;
end;

procedure TDCLGrid.FindGridOnSelectCell(Sender: TObject; aCol, aRow: Integer;
  var CanSelect: Boolean);
begin
  If Assigned(FDBGrid) then
    FDBGrid.SelectedIndex:=aCol-1;
end;

procedure TDCLGrid.Print(Sender: TObject);
const
  tmpFileName='table.tmp';
var
  Print: TPrintBase;
begin
  Print:=TPrintBase.Create(FQuery);
  Print.Print(FDBGrid, FForm.Caption);
  Print.Save(GPT.AppConfigDir+tmpFileName);

  if GPT.Viewer<>'' then
    Run('"'+GPT.Viewer+'"', '"'+GPT.AppConfigDir+tmpFileName+'"', False)
  else
    OpenFile(GPT.AppConfigDir+tmpFileName);
end;

function TDCLGrid.GetSortField(const FieldName: String): TSortField;
var
  FF: TSortField;
begin
  Result:=nil;
  for FF in FOrdersFields do
  begin
    if LowerCase(FF.FieldName)=LowerCase(FieldName) then
    begin
      Result:=FF;
      break;
    end;
  end;
end;

procedure TDCLGrid.ExecEvents(EventType: TEventsEnum);
var
  Event: TDCLEvent;
  CommandObj: IDCLCommand;
  IsExist: Boolean;
begin
  IsExist:=False;
  for Event in FEvents do
  begin
    if Event.EventType=EventType then
    begin
      IsExist:=True;
      break;
    end;
  end;

  if IsExist then
  begin
    CommandObj:=TDCLCommand.Create(FIDCLMain, FNameSpace, FForm, Self);
    for Event in FEvents do
    begin
      if Event.EventType=EventType then
      begin
        IsExist:=CommandObj.RunCommandScript(Event.ScriptName);
        if not IsExist then
        begin
          CommandObj.RunCommand(Event.ScriptName+';');
        end;
      end;
    end;
  end;
end;

procedure TDCLGrid.GridDblClick(Sender: TObject);
begin
  ExecEvents(evtLineDblClick);
end;

procedure TDCLGrid.GridColumnClick(Column: TColumn);
var
  SortIt: Boolean;
  tmpSQL, OrderBy, FieldName: String;

  procedure RemoveField(const FieldName: String);
  begin
    FOrdersFields.Remove(GetSortField(FieldName));
  end;

  function ContainsField(const FieldName: String): Boolean;
  begin
    Result:=Assigned(GetSortField(FieldName));
  end;

  procedure TurnOrder(var Column: TColumn);
  var
    FF: TSortField;
  begin
    FF:=GetSortField(Column.FieldName);
    if Assigned(FF) then
    begin
      case FF.Order of
      soAsc: FF.Order:=soDesc;
      soDesc, soNone: FF.Order:=soAsc;
      end;
    end;
  end;

  procedure AddField(var Column: TColumn);
  var
    FF: TSortField;
  begin
    FF:=GetSortField(Column.FieldName);
    if not Assigned(FF) then
    begin
      FF:=TSortField.Create;
      FF.FieldName:=LowerCase(Column.FieldName);
      FF.Order:=soAsc;
      FOrdersFields.Add(FF);
    end;
  end;

begin
  SortIt:=True;
  If FOrderByFields.Count>0 Then
  begin
    SortIt:=False;
    For FieldName in FOrderByFields do
      If LowerCase(Column.FieldName)=LowerCase(FieldName) Then
      begin
        SortIt:=True;
        break;
      end;
  end;

  If SortIt and (FNotOrderByFields.Count>0) Then
  begin
    For FieldName in FNotOrderByFields do
      If LowerCase(Column.FieldName)=LowerCase(FieldName) Then
      begin
        SortIt:=False;
        break;
      end;
  end;

  If SortIt Then
  begin
    If KeyState(VK_SHIFT) then
    begin
      //Снять
      RemoveField(Column.FieldName);
    end
    else
    begin
      If KeyState(VK_CONTROL) then
      begin
        //Добавить
        if not ContainsField(Column.FieldName) then
        begin
          AddField(Column);
        end;
      end
      else
      begin
        //Если не отсортировано, сбросить всё
        if not ContainsField(Column.FieldName) then
        begin
          FOrdersFields.Clear;

          AddField(Column);
        end
        else
        begin
          //иначе, обратить
          TurnOrder(Column);
        end;
      end;
    end;

    tmpSQL:=FQuery.SQL.Text;
    OrderBy:=SortDB(tmpSQL);
    tmpSQL:=tmpSQL+OrderBy;

    OpenQuery(tmpSQL);

    ReDrawColumns;
  end;
end;

procedure TDCLGrid.GridKeyPress(Sender: TObject; var UTF8Key: TUTF8Char);
var
  col: Integer;
begin
  col:=(Sender as TDBGrid).SelectedColumn.Index+1;
  if FReadOnly then
  begin
    if UTF8Key>=#32 then
    begin
      if not FindProcess then
      begin
        FindProc;
        (Sender as TDBGrid).SetFocus;
        (Sender as TDBGrid).SelectedIndex:=col-1;
        if GetSimplyFieldType(FQuery.FieldByName(FindFields[col-1]).DataType)=sftString then
          FindGrid.Cells[col, 0]:='%';
      end;

      if FindProcess then
        FindGrid.Cells[col, 0]:=FindGrid.Cells[col, 0]+UTF8Key;
    end;
  end;
end;

procedure TDCLGrid.Grid1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  col: Integer;
begin
  if FReadOnly then
  begin
    col:=(Sender as TDBGrid).SelectedColumn.Index+1;
    if Key=13 then
    begin
      if GetSimplyFieldType(FQuery.FieldByName(FindFields[col-1]).DataType)=sftString then
        FindGrid.Cells[col, 0]:=FindGrid.Cells[col, 0]+'%';
      FindProc;
      (Sender as TDBGrid).SetFocus;
      Key:=0;
    end;

    if Key=46 then
    begin
      if Assigned(FindGrid) and (FindGrid.Cells[col, 0]<>'') then
      begin
        if not FindProcess then
          FindProc;
        (Sender as TDBGrid).SetFocus;
        (Sender as TDBGrid).SelectedIndex:=col;
        FindProc;
        Key:=0;
      end;
    end;

    if Key=8 then
    begin
      if FindProcess then
      begin
        if FindGrid.Cells[col, 0]<>'' then
          FindGrid.Cells[col, 0]:=UTF8Copy(FindGrid.Cells[col, 0], 1, UTF8Length(FindGrid.Cells[col, 0])-1);
        Key:=0;
      end;
    end;
  end;
end;

procedure TDCLGrid.RefreshGridColumns;
var
  F: TDBFilter;
  SF: TSortField;
  i: Integer;
  Column: TColumn;
begin
  for i:=0 to FDBGrid.Columns.Count-1 do
  begin
    Column:=FDBGrid.Columns[i];
    SF:=GetSortField(FDBGrid.Columns[i].FieldName);

    if Assigned(SF) then
    begin
      case SF.Order of
      soNone: Column.Title.ImageIndex:=-1;
      soAsc: Column.Title.ImageIndex:=FIDCLMain.GetImageIndex(ptDownArrow);
      soDesc: Column.Title.ImageIndex:=FIDCLMain.GetImageIndex(ptUpArrow);
      end;
    end
    else
      Column.Title.ImageIndex:=-1;
  end;

  for F in FFilters do
  begin
    if F.FilterType=ftTempFilter then
    begin
      Column:=nil;
      for i:=0 to FDBGrid.Columns.Count-1 do
      begin
        if LowerCase(F.Field)=LowerCase(FDBGrid.Columns[i].FieldName) then
        begin
          Column:=FDBGrid.Columns[i];
          break;
        end;
      end;

      if Assigned(Column) then
      begin
        Column.Title.ImageIndex:=FIDCLMain.GetImageIndex(ptGridFilter);
      end;
      //break;
    end;
  end;
end;

function TDCLGrid.SortDB(var SQL: String): String;
var
  OrderBy: String;
  OrderField: TSortField;
  Parser: TSQLParser;
begin
  Result:='';
  if FOrdersFields.Count>0 then
  begin
    Parser:=TSQLParser.Create;
    Parser.ExcludeOrderBy(SQL);

    OrderBy:='';
    for OrderField in FOrdersFields do
    begin
      if OrderField.Order=soNone then
        Continue;

      OrderBy:=OrderBy+OrderField.FieldName;

      if OrderField.Order=soDesc then
        OrderBy:=OrderBy+' desc';

      OrderBy:=OrderBy+', '
    end;

    Result:=' order by '+Copy(OrderBy, 1, Length(OrderBy)-2);
  end
  else
  begin
    Parser.ExcludeOrderBy(SQL);
    Result:='';
  end;
end;

procedure TDCLGrid.ReDrawColumns;
var
  Column: TColumn;
  i: Integer;

  function ContainsField(const FieldName: String): Boolean;
  var
    FF: TSortField;
  begin
    Result:=False;
    for FF in FOrdersFields do
    begin
      if LowerCase(FF.FieldName)=LowerCase(FieldName) then
      begin
        Result:=True;
        break;
      end;
    end;
  end;
begin
  for i:=1 to FDBGrid.Columns.Count do
  begin
    Column:=FDBGrid.Columns[i-1];
    if ContainsField(Column.FieldName) then
    begin
      Column.Title.Font.Style:=[fsBold];
    end
    else
    begin
      Column.Title.Font.Style:=Column.Title.Font.Style-[fsBold];
    end
  end;
  RefreshGridColumns;
end;

function TDCLGrid.GetEdits: TList<TDCLEdit>;
var
  f: TDCLField;
begin
  Result:=TList<TDCLEdit>.Create;
  for f in FDCLFields do
  begin
    if Assigned(f.DCLEditComponent) and Assigned(f.DCLEditComponent.Control) and
      (f.DCLEditComponent.Control is TEdit) then
    begin
      Result.Add(f.DCLEditComponent);
    end;
  end;
end;

procedure TDCLGrid.AddColumn(Field: TDCLField);
var
  Col: TColumn;
begin
  If Assigned(FDBGrid) Then
  begin
    Col:=FDBGrid.Columns.Add;
    Col.FieldName:=Field.FieldName;
    Col.Title.Caption:=Field.Caption;
    If Col.Width>ColumnsLongerThis Then
      Col.Width:=DefaultColumnSize;

    If Field.Width<>0 Then
      Col.Width:=Field.Width;

    Col.ReadOnly:=Field.ReadOnly;

    case Field.DataFieldType of
      dftLogic: begin
        Col.ButtonStyle:=cbsCheckboxColumn;
        if Field.CheckValue<>'' then
          Col.ValueChecked:=Field.CheckValue;
        if Field.UnCheckValue<>'' then
          Col.ValueUnchecked:=Field.UnCheckValue;
      end;
    end;
  end;
end;

procedure TDCLGrid.CreateToolPanel;
begin
  if not Assigned(FToolsPanel) then
  begin
    FToolsPanel:=TPanel.Create(FMainPanel);
    FToolsPanel.Parent:=FMainPanel;
  end;
  FToolsPanel.Align:=alTop;
end;

procedure TDCLGrid.OnToolPanelResize(Sender: TObject);
begin
  (Sender as TWinControl).Height:=FToolPanelHeight+FFilterPanelHeight;
end;

procedure TDCLGrid.CreateFilterPanel;
begin
  CreateToolPanel;
  if not Assigned(FFiltersPanel) then
  begin
    FFiltersPanel:=TScrollBox.Create(FToolsPanel);
    FFiltersPanel.Parent:=FToolsPanel;
    FFiltersPanel.Align:=alClient;
    FFiltersPanel.ClientHeight:=20;
    FFiltersPanel.OnResize:=OnResizeFilterPanel;
    FFiltersPanel.VertScrollBar.Visible:=False;
  end;
end;

procedure TDCLGrid.AdjustFilterPanel(Height: Integer);
begin
  if FFilterPanelHeight<Height then
    FFilterPanelHeight:=Height;
end;

procedure TDCLGrid.AdjustToolPanel;
begin
  if Assigned(FToolsPanel) then
  begin
    FToolsPanel.Height:=FToolPanelHeight+FFilterPanelHeight;
  end;
end;

procedure TDCLGrid.ParseFields(ScrLine: String);
var
  p, l: Integer;
  FieldNameCapt, S, tmpStr: String;
begin
  TranslateVal(ScrLine, True);
  p:=0;
  l:=Length(ScrLine);
  case FFieldParsingMode of
  fpmNone: ;
  fpmCaption:
  begin
    FCurrentField:=TDCLField.Create;
    p:=Pos('\', ScrLine);
    if p=0 then
      p:=Pos(';', ScrLine);
    if p=0 then
      FieldNameCapt:=ScrLine
    else
      FieldNameCapt:=LeftStr(ScrLine, p-1);

    FCurrentField.ComponentName:=FindParam('ComponentName=', ScrLine);

    FCurrentField.Caption:=FieldNameCapt;
    if FindParam('Width=', ScrLine)<>'' then
      FCurrentField.Width:=StrToIntEx(FindParam('Width=', ScrLine));

    If FindParam('Height=', ScrLine)<>'' Then
    begin
      FCurrentField.Height:=StrToIntEx(FindParam('Height=', ScrLine));
    end;

    FCurrentField.Value:=FindParam('_Value=', ScrLine);
    FCurrentField.SQL:=FindParam('SQL=', ScrLine);

    S:=FindParam('MaxLength=', ScrLine);
    If S<>'' Then
      FCurrentField.MaxLength:=StrToIntEx(Trim(S));

    If FindParam('Disabled=', ScrLine)='1' then
      FCurrentField.Enabled:=False;

    If FindParam('NoDataField=', ScrLine)='1' Then
    Begin
      FCurrentField.NoDataField:=True;
    End;

    if FindParam('FullName=', ScrLine)<>'' then
    begin
      FCurrentField.FullFieldName:=FindParam('FullName=', ScrLine);
    end;

    FCurrentField.RequireValue:=FindParam('RequireValue=', ScrLine)='1';
    FCurrentField.Hint:=FindParam('Hint=', ScrLine);

    FCurrentField.ReadOnly:=FindParam('ReadOnly=', ScrLine)='1';

    S:=RightStr(ScrLine, l-p);

    FCurrentField.Hint:=FindParam('Hint=', S);

    tmpStr:=FindParam('VariableName=', S);
    If tmpStr<>'' Then
      FCurrentField.Variable:=tmpStr;

    If PosEx('HidePassword;', S)<>0 Then
      FCurrentField.PasswordChar:=MaskPassChar
    Else
      FCurrentField.PasswordChar:=#0;

    S:=FindParam('Format=', ScrLine);
    if S<>'' then
    begin
      If LowerCase(S)='float' Then
      begin
        FCurrentField.FieldTypeFormat:=fftFloat;
      end;
      if LowerCase(S)='digit' then
      begin
        FCurrentField.FieldTypeFormat:=fftDigit;
      end;
      if LowerCase(S)='trim' then
      begin
        FCurrentField.FieldTypeFormat:=fftTrim;
      end;
    end;

    If FindParam('CharCase=', ScrLine)<>'' then
    begin
      if FindParam('CharCase=', ScrLine).ToLower='lowercase' then
        FCurrentField.CharCase:=ecLowerCase
      else
        if FindParam('CharCase=', ScrLine).ToLower='uppercase' then
          FCurrentField.CharCase:=ecUppercase;
    end;

    FCurrentField.CheckState:=0;
    If PosEx('_OnCheck;', ScrLine)<>0 Then
      FCurrentField.CheckState:=1;
    If PosEx('_OffCheck;', ScrLine)<>0 Then
      FCurrentField.CheckState:=-1;

    FCurrentField.FirstFieldsLine:=S;
    if FGridStyle in TDataGrid then
    begin

    end;
  end;

  fpmField:begin
    p:=Pos('\', ScrLine);
    if p=0 then
      p:=Pos(';', ScrLine);
    if p=0 then
      FieldNameCapt:=ScrLine
    else
      FieldNameCapt:=LeftStr(ScrLine, p-1);

    FDCLFields.Add(FCurrentField);

    If PosEx('As_Logic;', ScrLine)<>0 Then
    begin
      FCurrentField.DataFieldType:=dftLogic;
      TmpStr:=Trim(FindParam('ValueChecked=', ScrLine));
      If TmpStr<>'' Then
        FCurrentField.CheckValue:=TmpStr;
      TmpStr:=Trim(FindParam('ValueUnChecked=', ScrLine));
      If TmpStr<>'' Then
        FCurrentField.UnCheckValue:=TmpStr;
    end;

    If PosEx('As_Graphic;', ScrLine)<>0 Then
    begin
      FCurrentField.DataFieldType:=dftGrafic;
    end;

    If PosEx('As_Date;', ScrLine)<>0 Then
    begin
      FCurrentField.DataFieldType:=dftDateTime;
    end;

    If PosEx('As_Memo;', ScrLine)<>0 Then
    begin
      FCurrentField.DataFieldType:=dftMemo;
    end;

    If PosEx('As_RichText;', ScrLine)<>0 Then
    begin
      FCurrentField.DataFieldType:=dftRichText;
    end;

    If PosEx('As_Float;', ScrLine)<>0 Then
    begin
      FCurrentField.DataFieldType:=dftFloat;
    end;

    FCurrentField.FieldName:=FieldNameCapt;

    if FGridStyle in TDataFields then
    begin
      If IsLexem('DateBox=', FCurrentField.FirstFieldsLine) Then
      begin
        AddDateBox(FCurrentField, FCurrentField.FirstFieldsLine);
      end;

      If IsLexem('InputBox=', FCurrentField.FirstFieldsLine) then
      begin
        AddFieldBox(FCurrentField, fbtInputBox, FCurrentField.FirstFieldsLine);
      end;

      If IsLexem('OutBox=', FCurrentField.FirstFieldsLine) then
      begin
        AddFieldBox(FCurrentField, fbtOutBox, FCurrentField.FirstFieldsLine);
      end;

      If IsLexem('EditBox=', FCurrentField.FirstFieldsLine) then
      begin
        AddFieldBox(FCurrentField, fbtEditBox, FCurrentField.FirstFieldsLine);
      end;

      If IsLexem('Lookup=', FCurrentField.FirstFieldsLine) Then
      begin
        AddLookUp(FCurrentField, FCurrentField.FirstFieldsLine);
      end;

      If IsLexem('LookupTable=', FCurrentField.FirstFieldsLine) Then
      begin
        AddLookupTable(FCurrentField, FCurrentField.FirstFieldsLine);
      end;

      If (not FCurrentField.NoDataField) and (PosEx('DBCheckBox=', FCurrentField.FirstFieldsLine)<>0) Then
      begin
        AddDBCheckBox(FCurrentField, FCurrentField.FirstFieldsLine);
      end
      Else If PosEx('SimplyCheckBox=', FCurrentField.FirstFieldsLine)<>0 Then
      begin
        AddSimplyCheckBox(FCurrentField, FCurrentField.FirstFieldsLine);
      end
      Else If PosEx('CheckBox=', FCurrentField.FirstFieldsLine)<>0 Then
      begin
        AddCheckBox(FCurrentField, FCurrentField.FirstFieldsLine);
      end;

      if PosEx('ContextButton=', FCurrentField.FirstFieldsLine)<>0 then
        AddContextButton(FCurrentField, FCurrentField.FirstFieldsLine);
    end;

    If IsLexem('DropListBox=', FCurrentField.FirstFieldsLine) Then
    begin
      AddDropBox(FCurrentField, FCurrentField.FirstFieldsLine);
    end;
  end;
  end;

  if FFieldParsingMode=fpmCaption then
    FFieldParsingMode:=fpmField
  else
    if FFieldParsingMode=fpmField then
      FFieldParsingMode:=fpmCaption;
end;

procedure TDCLGrid.AddAstericsFields;
var
  DBField: TField;
begin
  if Assigned(FQuery) and FQuery.Active then
  begin
    for DBField in FQuery.Fields do
    begin
      FCurrentField:=TDCLField.Create;
      FCurrentField.FieldName:=DBField.FieldName;
      FCurrentField.Caption:=NormalizeCase(DBField.FieldName);

      FDCLFields.Add(FCurrentField);
    end;
  end;
end;

procedure TDCLGrid.OnResizeFilterPanel(Sender: TObject);
begin
  if Assigned(Sender) then
  begin
    if (Sender as TScrollBox).HorzScrollBar.IsScrollBarVisible then
      FToolsPanel.Height:=FToolPanelHeight+FFilterPanelHeight+ScrollHeight
    else
      FToolsPanel.Height:=FToolPanelHeight+FFilterPanelHeight;
  end;
end;

procedure TDCLGrid.AddDropBox(Field: TDCLField; Scr: String);
var
  ShadowQuery: TDCLDialogQuery;
  TmpStr, tmpStr1: String;
  DropList: TComboBox;
  v1, v2: Integer;
begin
  If FGridStyle in TDataGrid Then
  begin
    Field.DCLEditComponent:=TDCLEdit.Create;
  end;
  If FGridStyle in TDataFields Then
  begin
    DropList:=TComboBox.Create(FFieldsPanel);
    DropList.Parent:=FFieldsPanel;
    DropList.DropDownCount:=DropDownRows;
    DropList.OnSelect:=DropListOnSelectItem;
    If DropList.Hint<>'' Then
    begin
      DropList.ShowHint:=True;
      DropList.Hint:=Field.Hint;
      DropList.TextHint:=Field.Hint;
    end;

    Field.DCLEditComponent:=TDCLEdit.Create;
    Field.DCLEditComponent.Control:=DropList;

    DropList.Clear;

    If Field.Variable<>'' Then
    begin
      FIDCLMain.Variables.NewVariableWithTest(FNamespace, Field.Variable);
    end;

    If Field.SQL<>'' Then
    begin
      ShadowQuery:=TDCLDialogQuery.Create(Self.GetComponent);
      ShadowQuery.Name:='DropBoxQ_'+IntToStr(UpTime);
      FDBConnector.SetConnector(ShadowQuery);

      ShadowQuery.SQL.Text:=Field.SQL;
      try
        ShadowQuery.Open;

        While Not ShadowQuery.Eof do
        begin
          TmpStr:=Trim(ShadowQuery.Fields[0].AsString);
          If TmpStr='' Then
            TmpStr:='';
          DropList.Items.Append(TmpStr);

          ShadowQuery.Next;
        end;
        ShadowQuery.Close;
        FreeAndNil(ShadowQuery);
      Except
        on E: Exception do
        begin
          raise TDCLException.Create( - 1107, E.Message);
        end;
      end;
    end;

    If Field.Width>0 Then
      DropList.Width:=Field.Width
    Else
      DropList.Width:=EditWidth;

    TmpStr:=FindParam('List=', Scr);
    v2:=ParamsCount(TmpStr);
    For v1:=1 to v2 do
    begin
      tmpStr1:=GetParam(TmpStr, v1);
      If tmpStr1='' Then
        tmpStr1:=' ';
      DropList.Items.Append(tmpStr1);
    end;

    Field.UseIndex:=FindParam('UseIndex=', Scr)='1';

    If (not Field.NoDataField) and FQuery.Active then
    begin
      If FindParam('SetIndexValue=', Scr)='1' Then
      begin
        DropList.ItemIndex:=FQuery.FieldByName(Field.FieldName).AsInteger;
      end;
    end
    Else
      DropList.ItemIndex:=StrToIntEx(FindParam('SetIndexValue=', Scr));
  end;
end;

procedure TDCLGrid.DropListOnSelectItem(Sender: TObject);
var
  ItemIndex: Integer;
  ItemName: String;
  Field, f: TDCLField;
begin
  Field:=nil;
  for f in FDCLFields do
  begin
    if Assigned(f.DCLEditComponent) and Assigned(f.DCLEditComponent.Control) then
    if f.DCLEditComponent.Control=Sender then
    begin
      Field:=f;
      break;
    end;
  end;

  if Assigned(Field) then
  begin
    ItemIndex:=(Sender as TCustomComboBox).ItemIndex;
    ItemName:=(Sender as TCustomComboBox).Items[ItemIndex];

    If (not Field.NoDataField) and FQuery.Active then
    begin
      if FieldExists(FQuery, Field.FieldName) then
      begin
        if Field.UseIndex then
        begin
          If (FQuery.FieldByName(Field.FieldName).AsInteger<>ItemIndex) and FQuery.CanModify Then
          begin
            If not (FQuery.State in dsEditModes) Then
              FQuery.Edit;

            If FQuery.State in dsEditModes Then
              FQuery.FieldByName(Field.FieldName).AsInteger:=ItemIndex;
          end;
        end
        else
        begin
          If not DCLStringEquals(FQuery.FieldByName(Field.FieldName).AsString, ItemName) and FQuery.CanModify Then
          begin
            If not (FQuery.State in dsEditModes) Then
              FQuery.Edit;

            If FQuery.State in dsEditModes Then
              FQuery.FieldByName(Field.FieldName).AsString:=ItemName;
          end;
        end;
      end;
    end;

    If Field.Variable<>'' Then
      if Field.UseIndex then
        FIDCLMain.Variables[FNamespace.CurrentNamespace, Field.Variable]:=IntToStr(ItemIndex)
      else
        FIDCLMain.Variables[FNamespace.CurrentNamespace, Field.Variable]:=ItemName;
  end;
end;

procedure TDCLGrid.AddDBDateEdit(Field: TDCLField);
var
  DateEdit: TDBDate;
begin
  Field.DCLEditComponent:=TDCLEdit.Create;

  DateEdit:=TDBDate.Create(FFieldsPanel);
  DateEdit.Parent:=FFieldsPanel;
  if Field.Width>0 then
    DateEdit.Width:=Field.Width;
  DateEdit.DataSource:=FData;
  DateEdit.DataField:=Field.FieldName;
  DateEdit.DateOrder:=doNone;
  case FQuery.FieldByName(Field.FieldName).DataType of
  ftDate: DateEdit.DateFormat:=GPT.DateFormat;
  ftDateTime: DateEdit.DateFormat:=GPT.TimeStampFormat;  // глюк, не работает !!!!
  end;
  DateEdit.ReadOnly:=Field.ReadOnly;
  DateEdit.Enabled:=Field.Enabled;
  DateEdit.Hint:=Field.Hint;
  if Field.Hint<>'' then
    DateEdit.ShowHint:=True;

  Field.DCLEditComponent.Control:=DateEdit;
end;

procedure TDCLGrid.AddMediaFieldGroup(Field: TDCLField; GroupType: TGroupType);
var
  MediaField: TMediaFieldGroup;
begin
  MediaField:=TMediaFieldGroup.Create(FFieldsPanel, FData, Field, GroupType,
    FIDCLMain.GetImageIndexes, FIDCLMain.GetImageList);

  Field.DCLEditComponent:=TDCLEdit.Create;
  Field.DCLEditComponent.Control:=MediaField;
end;

procedure TDCLGrid.AddDBEdit(Field: TDCLField);
var
  DBEdit: TDBEdit;
begin
  if FieldExists(FQuery, Field.FieldName) then
  begin
    DBEdit:=TDBEdit.Create(FFieldsPanel);
    DBEdit.Parent:=FFieldsPanel;
    if Field.Width>0 then
      DBEdit.Width:=Field.Width;
    DBEdit.DataField:=Field.FieldName;
    DBEdit.DataSource:=FData;
    DBEdit.Hint:=Field.Hint;
    DBEdit.TextHint:=Field.Hint;
    if Field.Hint<>'' then
      DBEdit.ShowHint:=True;
    DBEdit.CharCase:=Field.CharCase;
    DBEdit.PasswordChar:=Field.PasswordChar;
    DBEdit.OnClick:=DBEditClick;
    DBEdit.Enabled:=Field.Enabled;

    If Field.PasswordChar<>#0 Then
      DBEdit.Tag:=1;

    DBEdit.ReadOnly:=Field.ReadOnly;

    Field.DCLEditComponent:=TDCLEdit.Create;
    Field.DCLEditComponent.Control:=DBEdit;
  end;
end;

procedure TDCLGrid.DBEditClick(Sender: TObject);
var
  Edit: TDBEdit;
begin
  Edit:=Sender as TDBEdit;
  If Edit.PasswordChar=MaskPassChar Then
  begin
    If KeyState(VK_CONTROL) Then
      Edit.PasswordChar:=#0;
  end
  Else If Edit.Tag=1 Then
    If Edit.PasswordChar=#0 Then
    begin
      Edit.PasswordChar:=MaskPassChar;
    end;
end;

procedure TDCLGrid.SetNewQuery(Data: TDataSource);
begin
  FQuery:=TDCLQuery.Create(Self.GetComponent);
  FDBConnector.SetConnector(FQuery);
  SetQueryEvents(FQuery);

  FData.DataSet:=FQuery;
  if Assigned(Data) then
    FQuery.DataSource:=Data;
end;

procedure TDCLGrid.ClickCommandButton(Sender: TObject);
var
  CommandObj: IDCLCommand;
  DCLCommand, c: TDCLCommandButton;
  ns: TVariableNamespace;
  Bookmark: TBookmark;
begin
  for c in FButtons do
  begin
    if Assigned(c.Button) then
    begin
      if c.Button=Sender as TDCLDialogButton then
      begin
        DCLCommand:=c;
        break;
      end;
    end;
  end;

  if Assigned(DCLCommand) then
  begin
    ns:=FNameSpace;
    if DCLCommand.CloseButton then
    begin
      FForm.Close;
    end
    else if DCLCommand.ChoiceButton then
    begin
      Choose;
      FForm.ModalResult:=mrOk;
    end
    else if DCLCommand.ForEach then
    begin
      if CheckEdits then
      begin
        if (FGridStyle in TDataGrid) and FMultiSelectMode then
        begin
          for Bookmark in FDBGrid.SelectedRows do
          begin
            if Assigned(Bookmark) then
            begin
              FQuery.GoToBookmark(Bookmark);

              if DCLCommand.Host then
              begin
                ns:=TVariableNamespace.Create(FNameSpace.CurrentNamespace, GetGUIDString);
                FIDCLMain.Variables.RegisterNamespace(ns);
              end;

              CommandObj:=TDCLCommand.Create(FIDCLMain, ns, FForm, Self);
              CommandObj.DisableAutoRefresh:=True;
              CommandObj.SelectRunType(DCLCommand.Command);
            end;
          end;
        end;

        if DCLCommand.ExecAfter<>'' then
        begin
          if DCLCommand.Host then
          begin
            ns:=TVariableNamespace.Create(FNameSpace.CurrentNamespace, GetGUIDString);
            FIDCLMain.Variables.RegisterNamespace(ns);
          end;

          CommandObj:=TDCLCommand.Create(FIDCLMain, ns, FForm, Self);
          CommandObj.SelectRunType(DCLCommand.ExecAfter);
        end;

        ReFreshData;
      end;
    end
    else
    begin
      if CheckEdits then
      begin
        if DCLCommand.Host then
        begin
          ns:=TVariableNamespace.Create(FNameSpace.CurrentNamespace, GetGUIDString);
          FIDCLMain.Variables.RegisterNamespace(ns);
        end;

        CommandObj:=TDCLCommand.Create(FIDCLMain, ns, FForm, Self);
        CommandObj.SelectRunType(DCLCommand.Command);
      end;
    end;
  end;
end;

function TDCLGrid.AddTablePartObject(Title: String; Data: TDataSource; Style: TGridStyle): TDCLGrid;
var
  FTablePartsTabs: TTabSheet;
  grid: TDCLGrid;
  pc: Integer;
begin
  If Not Assigned(FTablePartsPages) Then
  begin
    FTablePartsPages:=TPageControl.Create(FMainPanel);
    FTablePartsPages.Parent:=FMainPanel;
    FTablePartsPages.Height:=TablePartHeight;
    FTablePartsPages.OnChange:=ChangePartTabPage;
    FTablePartsPages.Tag:=2;
    if not GPT.DisableColorScheme and (GPT.TablePartColor<>NoColorValue) then
      FTablePartsPages.Color:=GPT.TablePartColor;
  end;

  pc:=FTablePartsPages.PageCount;
  FTablePartsTabs:=TTabSheet.Create(FTablePartsPages);
  FTablePartsTabs.Parent:=FTablePartsPages;
  FTablePartsTabs.Name:='TablePart_'+IntToStr(pc+1);
  FTablePartsTabs.PageControl:=FTablePartsPages;
  if not GPT.DisableColorScheme and (GPT.TablePartColor<>NoColorValue) then
    FTablePartsTabs.Color:=GPT.TablePartColor;

  If Title='' Then
    FTablePartsTabs.Caption:=GetDCLMessageString(msPage)+' '+IntToStr(pc+1)
  Else
    FTablePartsTabs.Caption:=InitCap(Title);

  grid:=TDCLGrid.Create(FIDCLMain, FNameSpace, FForm, FTablePartsTabs, dctTablePart, nil, Data);
  grid.SetGridStyle(Style);
  grid.SetPrintTool(FPrintTool);
  FCurrentTablePartIndex:=FTableParts.Add(grid);
  Result:=grid;
end;

procedure TDCLGrid.AddTablePart(Line: String);
var
  tmpStyle: TGridStyle;
  tSQL, S, S2, S3, ButtonsSet: String;
  i, v1, v2, p1, p2: Integer;
  FFieldColumn: TDCLField;
begin
  tSQL:=FindParam('SQL=', Line);
  if tSQL<>'' then
  begin
    TranslateVal(Line, True);

    tmpStyle:=gsGrid;
    S:=FindParam('Style=', Line);
    If S='0' Then
      tmpStyle:=gsFields;
    If S='1' Then
      tmpStyle:=gsFieldsHorizontal;
    If S='2' Then
      tmpStyle:=gsGrid;

    AddTablePartObject(FindParam('Title=', Line), FData, tmpStyle);

    if (FindParam('UpdateTable=', Line)<>'') and (FindParam('KeyFields=', Line)<>'') then
      FTableParts[FCurrentTablePartIndex].Query.SetUpdateSQL
        (FindParam('UpdateTable=', Line), FindParam('KeyFields=', Line));

    FTableParts[FCurrentTablePartIndex].SetSQL(tSQL);
    FTableParts[FCurrentTablePartIndex].NoDataField:=FindParam('NoDataField=', Line)='1';
    FTableParts[FCurrentTablePartIndex].PrintTool:=FPrintTool;
    FTableParts[FCurrentTablePartIndex].MultiSelect:=FindParam('MultiSelect=', Line)='1';

    If FindParam('DependField=', Line)<>'' Then
    begin
      FTableParts[FCurrentTablePartIndex].DependField:=FindParam('DependField=', Line);
    end;

    FTableParts[FCurrentTablePartIndex].Query.Open;

    If FindParam('MasterDataField=', Line)<>'' then
    begin
      FTableParts[FCurrentTablePartIndex].MasterDataField:=FindParam('MasterDataField=', Line);
    end;

    If FindParam('VariableName=', Line)<>'' then
    begin
      FTableParts[FCurrentTablePartIndex].MasterValueVariableName:=FindParam('VariableName=', Line);
    end;

    If FindParam('Navigator=', Line)='1' then
    begin
      FTableParts[FCurrentTablePartIndex].NavigatorVisible:=True;
      FTableParts[FCurrentTablePartIndex].FlatNavigator:=Self.GetFlatNavigator;

      ButtonsSet:=FindParam('NavigatorButtons=', Line);
      If ButtonsSet='' then
        ButtonsSet:=DefaultNavigButtonsSet;

      If ButtonsSet<>'' then
      begin
        FTableParts[FCurrentTablePartIndex].SetNavigatorButtonsSet(ButtonsSet);
      end;
    end;

    S:=Trim(FindParam('ReadOnly=', Line));
    If StrToIntEx(S)=1 then
    begin
      FTableParts[FCurrentTablePartIndex].ExecScriptLine('ReadOnly=1');
    end;

    S:=FindParam('Columns=', Line);
    If S<>'' Then
    begin
      v1:=ParamsCount(S);
      For i:=1 to v1 do
      begin
        S2:=GetParam(S, i);
        p2:=Pos('/', S2);
        if p2=0 then
          p2:=Pos('=', S2);
        if p2<>0 then
          S3:=Copy(S2, 1, p2-1);
        v2:=0;
        p1:=Pos('=', S3);
        If p1<>0 Then
        begin
          v2:=StrToIntEx(CopyCut(S3, p1+1, Length(S3)));
          Delete(S3, p1, Length(S3));
        end;

        FFieldColumn:=TDCLField.Create;
        FFieldColumn.FieldName:=S3;
        FFieldColumn.Caption:=Copy(S2, p2+1, Length(S2)-1);
        FFieldColumn.Width:=v2;

        FTableParts[FCurrentTablePartIndex].AddField(FFieldColumn);
      end;
    end;
  end;
end;

procedure TDCLGrid.ChangePartTabPage(Sender: TObject);
var
  i, j: Integer;
  tab: TTabSheet;
  c: TControl;
  g: IDCLGrid;
begin
  tab:=(Sender as TPageControl).ActivePage;
  if Assigned(tab) then
  begin
    if tab.ControlCount>0 then
    begin
      for i:=0 to tab.ControlCount-1 do
      begin
        c:=tab.Controls[i];
        for j:=0 to FTableParts.Count-1 do
        begin
          g:=FTableParts[j];
          if g.GetComponent=c then
          begin
            FCurrentTablePartIndex:=j;
            break;
          end;
        end;
      end;
    end;
  end;
end;

procedure TDCLGrid.AddContextButton(Field: TDCLField; Scr: String);
var
  CommandName: String;
  ContextButton: TContextFieldButton;
begin
  ContextButton:=TContextFieldButton.Create;
  ContextButton.Button:=TDialogSpeedButton.Create(FFieldsPanel);
  ContextButton.Button.Parent:=FFieldsPanel;
  ContextButton.Button.Width:=GetValueButtonGeom;
  ContextButton.Button.Height:=GetValueButtonGeom;
  ContextButton.Button.Caption:='...';
  ContextButton.Button.Hint:=Field.Hint;
  ContextButton.Button.ShowHint:=True;
  ContextButton.Button.OnClick:=ContextFieldButtonsClick;

  CommandName:=FindParam('CommandName=', Scr);
  if CommandName<>'' then
  begin
    ContextButton.Command:=CommandName;
  end;

  if FindParam('ButtonHint=', Scr)<>'' then
  begin
    ContextButton.Button.Hint:=FindParam('ButtonHint=', Scr);
  end;

  Field.ContextButtons.Add(ContextButton);
end;

procedure TDCLGrid.ContextFieldButtonsClick(Sender: TObject);
var
  f: TDCLField;
  b, Button: TContextFieldButton;
  flg: Boolean;
  Command: IDCLCommand;
begin
  flg:=False;
  for f in FDCLFields do
  begin
    if flg then
      break;
    if f.ContextButtons.Count>0 then
    begin
      for b in f.ContextButtons do
      begin
        if b.Button=Sender then
        begin
          Button:=b;
          flg:=True;
          break;
        end;
      end;
    end;
  end;

  if Assigned(Button) then
  begin
    Command:=TDCLCommand.Create(FIDCLMain, FNameSpace, FForm, Self);
    Command.SelectRunType(Button.Command);
  end;
end;

procedure TDCLGrid.AddFieldBox(Field: TDCLField; FieldBoxType: TFieldBoxType; Scr: String);
var
  Edit: TEdit;
  S, FieldName: String;
  NeedValue: Integer;
  ShadowQuery: TDCLDialogQuery;
begin
  Field.DCLEditComponent:=TDCLEdit.Create;

  TranslateVal(Scr, True);

  Edit:=TEdit.Create(FFieldsPanel);
  Edit.Parent:=FFieldsPanel;

  Field.DCLEditComponent.Control:=Edit;

  Edit.Name:=Field.ComponentName;

  If Field.Hint<>'' Then
  begin
    Edit.ShowHint:=True;
    Edit.Hint:=Field.Hint;
    Edit.TextHint:=Field.Hint;
  end;

  Edit.PasswordChar:=Field.PasswordChar;

  if Field.CharCase<>ecNormal then
  begin
    Edit.CharCase:=Field.CharCase;
  end;

  Edit.ReadOnly:=Field.ReadOnly;
  Edit.OnClick:=FieldBoxOnClick;

  If Field.Width>0 Then
    Edit.Width:=Field.Width
  Else
    Edit.Width:=EditWidth;

  If FieldBoxType<>fbtOutBox then
  begin
    if Field.FieldTypeFormat<>fftNone then
    begin
      Edit.OnKeyPress:=FieldBoxKeyPress;
    end;
  end
  Else
    Edit.ReadOnly:=True;

  Field.DCLEditComponent.EditType:=FieldBoxType;
  Edit.Text:='';
  Edit.OnChange:=FieldBoxOnEdit;

  Edit.MaxLength:=Field.MaxLength;

  NeedValue:=0;
  If Field.Value<>'' Then
    NeedValue:=1
  Else
  Begin
    NeedValue:=3;
  End;

  If FindParam('_ValueNotInput=', Scr)<>'' Then
  Begin
    S:=FindParam('_ValueNotInput=', Scr);

    if S<>'' then
    begin
      Field.NotInputValue:=S;
      S:='';
    end;
  End;

  If FindParam('_ValueIfEmpty=', Scr)<>'' Then
  Begin
    S:=FindParam('_ValueIfEmpty=', Scr);

    if S<>'' then
    begin
      NeedValue:=6;
    end;
  End;

  if not Field.NoDataField then
  begin
    If FQuery.Active Then
    Begin
      If FindParam('_ValueIfNull=', Scr)<>'' Then
      Begin
        If FieldExists(FQuery, Field.FieldName) Then
          if FQuery.FieldByName(Field.FieldName).IsNull then
            NeedValue:=4;
      End;
      If FindParam('_ValueIfNotNull=', Scr)<>'' Then
      Begin
        If FieldExists(FQuery, Field.FieldName) Then
          if not FQuery.FieldByName(Field.FieldName).IsNull then
            NeedValue:=5;
      End;
    End;
  end;

  If Field.SQL<>'' Then
    NeedValue:=2;

  S:='';
  Case NeedValue of
  0:
  if not Field.NoDataField then
  If FQuery.Active Then
    If FieldExists(FQuery, Field.FieldName) Then
      S:=TrimRight(FQuery.FieldByName(Field.FieldName).AsString);
  1:
  begin
    S:=Field.Value;
  end;
  6:
  begin
    S:=FindParam('_ValueIfEmpty=', Scr);
  end;
  2:
  begin
    ShadowQuery:=TDCLDialogQuery.Create(Self.GetComponent);
    FDBConnector.SetConnector(ShadowQuery);
    ShadowQuery.SQL.Text:=Field.SQL;
    ShadowQuery.Open;
    If FindParam('ReturnField=', Scr)<>'' Then
      FieldName:=FindParam('ReturnField=', Scr)
    Else
      FieldName:=ShadowQuery.Fields[0].FieldName;
    DeleteNonPrintSimb(FieldName);
    If FieldExists(ShadowQuery, FieldName) Then
      S:=TrimRight(ShadowQuery.FieldByName(FieldName).AsString)
    Else
      S:='';
    ShadowQuery.Close;
    FreeAndNil(ShadowQuery);
  end;
  3:
  S:='';
  4:begin
    S:=FindParam('_ValueIfNull=', Scr);
  end;
  5:begin
    S:=FindParam('_ValueIfNotNull=', Scr);
  end;
  end;

  If Field.Variable<>'' Then
  begin
    FIDCLMain.Variables.NewVariableWithTest(FNamespace, Field.Variable);
    FIDCLMain.Variables[FNamespace.CurrentNamespace, Field.Variable]:=S;
  end;
  Edit.Text:=S;
end;

procedure TDCLGrid.FieldBoxOnClick(Sender: TObject);
var
  Edit: TEdit;
  Field, f: TDCLField;
begin
  Field:=nil;
  for f in FDCLFields do
  begin
    if Assigned(f.DCLEditComponent) and Assigned(f.DCLEditComponent.Control) then
    if f.DCLEditComponent.Control=Sender then
    begin
      Field:=f;
      break;
    end;
  end;

  if Assigned(Field) then
  begin
    Edit:=Sender as TEdit;
    If Edit.PasswordChar=Field.PasswordChar Then
    begin
      If KeyState(VK_CONTROL) Then
        Edit.PasswordChar:=#0;
    end
    Else If Field.PasswordChar<>#0 Then
      If Edit.PasswordChar=#0 Then
      begin
        Edit.PasswordChar:=Field.PasswordChar;
      end;
  end;
end;

procedure TDCLGrid.FieldBoxOnEdit(Sender: TObject);
var
  inFormat: Boolean;
  EdText: String;
  Field, f: TDCLField;
begin
  Field:=nil;
  for f in FDCLFields do
  begin
    if Assigned(f.DCLEditComponent) and Assigned(f.DCLEditComponent.Control) then
    if f.DCLEditComponent.Control=Sender then
    begin
      Field:=f;
      break;
    end;
  end;

  if Assigned(Field) then
  begin
    EdText:=(Sender as TEdit).Text;

    {If Edit.EditsToFloat Then
    begin
      ch:=False;
      l:=Length(EdText);
      For k:=1 to l do
        If EdText[k]=FloatDelimiterFrom Then
        begin
          EdText[k]:=FloatDelimiterTo;
          ch:=True;
        end;
      If ch Then
        Edit.Edit.Text:=EdText;
    end;}

    inFormat:=True;
    case Field.FieldTypeFormat of
    fftDigit:begin
      if not IsDigits(EdText) then
      begin
        inFormat:=False;
      end;
      end;
      fftTrim:Begin
        EdText:=Trim(EdText);
        (Field.DCLEditComponent.Control as TEdit).Text:=EdText;
      End;
    end;

    if inFormat then
    // Update variables
      FIDCLMain.Variables[FNamespace.CurrentNamespace, Field.Variable]:=EdText;
  end;
end;

procedure TDCLGrid.FieldBoxKeyPress(Sender: TObject; var Key: Char);
var
  Text:String;
  Field, f: TDCLField;
begin
  Field:=nil;
  for f in FDCLFields do
  begin
    if Assigned(f.DCLEditComponent) and Assigned(f.DCLEditComponent.Control) then
    if f.DCLEditComponent.Control=Sender then
    begin
      Field:=f;
      break;
    end;
  end;

  if Assigned(Field) then
  begin
    Text:=(Sender as TEdit).Text;

    case Field.FieldTypeFormat of
    fftFloat:
    begin
      If Key=FloatDelimiterFrom Then
        Key:=FloatDelimiterTo;
      If (Key='/') or (Key='?') or (Key='<') then
        Key:=FloatDelimiterTo;
      If (Key='б') or (Key='Б') or (Key='ю') or (Key='Ю') then
        Key:=FloatDelimiterTo;

      Case Key of
      // разрешаем ввод цифр
      '0'..'9':Key:=Key;
      // разрешаем ввод всего, что похоже на десятичный разделитель
      '.', ',':
      Begin
        // запрещаем ввод более 1 десятичного разделителя
        If Pos(FloatDelimiterTo, Text)=0 then
          Key:=FloatDelimiterTo
        Else key:=#0;
      End;
      '-':
      Begin
        // запрещаем ввод более 1 минуса
        If (Pos('-', Text)=0) then
          Key:='-'
        Else key:=#0;
      End;
      // разрешаем использование клавиш BackSpace и Delete
      #8:Key:=Key;
      // "гасим" все прочие клавиши
      Else key:=#0;
      End;
    end;
    fftDigit:begin
      Case Key of
      // разрешаем ввод цифр
      '0'..'9':Key:=Key;
      // разрешаем ввод всего, что похоже на десятичный разделитель
      '-':
      Begin
        // запрещаем ввод более 1 минуса
        If (Pos('-', Text)=0) then
          Key:='-'
        Else key:=#0;
      End;
      // разрешаем использование клавиш BackSpace и Delete
      #8:Key:=Key;
      // "гасим" все прочие клавиши
      Else key:=#0;
      End;
    end;
    end;
  end;
end;

procedure TDCLGrid.AddLookUp(Field: TDCLField; Scr: String);
var
  NoDataField: Boolean;
  TempStr: String;
  DBLookupControl: TDBLookupComboBox;
begin
  Field.LookupData:=TDCLLookup.Create;
  TempStr:=Field.SQL;
  If Field.SQL<>'' Then
  begin
    Field.LookupData.LookupQuery:=TDCLDialogQuery.Create(Self.GetComponent);
    FDBConnector.SetConnector(Field.LookupData.LookupQuery);
    TranslateVal(TempStr, False);
    Field.LookupData.LookupQuery.SQL.Text:=TempStr;
    try
      Field.LookupData.LookupQuery.Open;
      Field.LookupData.LookupQuery.Last;
      Field.LookupData.LookupQuery.First;
    Except
      on E: Exception do
      begin
        raise TDCLException.Create( - 1115, E.Message);
      end;
    end;
    Field.LookupData.LookupDS:=TDataSource.Create(Self.GetComponent);
    Field.LookupData.LookupDS.DataSet:=Field.LookupData.LookupQuery;
  end
  Else
  begin
    ShowErrorMessage( - 3000, 'No SQL statement!');
  end;

  DBLookupControl:=TDBLookupComboBox.Create(FFieldsPanel);
  DBLookupControl.Parent:=FFieldsPanel;
  DBLookupControl.Style:=csDropDownList;
  DBLookupControl.DropDownRows:=DropDownRows;
  DBLookupControl.ShowHint:=True;
  DBLookupControl.Hint:=Field.Hint;
  {$IFDEF FPC}
  DBLookupControl.OnSelect:=LookupOnClick;
  {$ELSE}
  DBLookupControl.OnClick:=LookupOnClick;
  {$ENDIF}

  Field.DCLEditComponent:=TDCLEdit.Create;
  Field.DCLEditComponent.Control:=DBLookupControl;

  If Assigned(FQuery) and FQuery.Active Then
  begin
    If not Field.NoDataField Then
    begin
      If FieldExists(FQuery, Field.FieldName) Then
      begin
        //If Not FForm.Showing Then FForm.Show;
        NoDataField:=False;
        DBLookupControl.DataSource:=FData;
        DBLookupControl.DataField:=Field.FieldName;
      end
      Else
        NoDataField:=True;
    end
    Else
      NoDataField:=True;
  end
  Else
    NoDataField:=True;

  DBLookupControl.ReadOnly:=Field.ReadOnly;
  DBLookupControl.Enabled:=Field.Enabled;
  DBLookupControl.ListSource:=Field.LookupData.LookupDS;
  If Field.Width>0 Then
    DBLookupControl.Width:=Field.Width
  Else
    DBLookupControl.Width:=EditWidth;

  Field.Height:=DBLookupControl.Height;

  If Field.Variable<>'' Then
  begin
    FIDCLMain.Variables.NewVariableWithTest(FNamespace, Field.Variable);
  end;

  DBLookupControl.KeyField:=FindParam('Key=', Scr);
  DBLookupControl.ListField:=FindParam('List=', Scr);

  TempStr:=FindParam('ModifyingEdit=', Scr);
  If TempStr<>'' Then
    Field.LookupData.ModifyEdit:=GetParam(TempStr, 1);

  If (NoDataField) Then
    Field.LookupData.LookupQuery.First;

  If Field.Value<>'' Then
  begin
    DBLookupControl.KeyValue:=Field.Value;
    If (Not NoDataField) and FQuery.CanModify Then
    begin
      If (Not (FQuery.State in dsEditModes))and FQuery.Active and(Not NoDataField) Then
        FQuery.Edit;
      FData.DataSet.FieldByName(Field.FieldName).AsInteger:=StrToIntEx(Field.Value);
    end;
  end;
end;

procedure TDCLGrid.LookupOnClick(Sender: TObject);
var
  tmpSQL1: String;
  f, DCLLookup: TDCLField;
begin
  DCLLookup:=nil;
  for f in FDCLFields do
  begin
    if Assigned(f.LookupData) and Assigned(f.DCLEditComponent) and (f.DCLEditComponent.Control=(Sender as TDBLookupComboBox)) then
    begin
      DCLLookup:=f;
      break;
    end;
  end;

  if Assigned(DCLLookup) then
  begin
    If DCLLookup.LookupData.ModifyEdit<>'' then
    begin
      for f in FDCLFields do
      begin
        if Assigned(f.DCLEditComponent) and (f.DCLEditComponent.Control=(Sender as TEdit)) and
          DCLStringEquals(f.DCLEditComponent.Control.Name, DCLLookup.LookupData.ModifyEdit) then
        begin
          tmpSQL1:=(DCLLookup.DCLEditComponent.Control as TDBLookupComboBox).KeyValue;
          (f.DCLEditComponent.Control as TEdit).Text:=tmpSQL1;

          break;
        end;
      end;
    end;

    if DCLLookup.Variable<>'' then
    begin
      tmpSQL1:=(DCLLookup.DCLEditComponent.Control as TDBLookupComboBox).KeyValue;
      FIDCLMain.Variables[FNamespace.CurrentNamespace, DCLLookup.Variable]:=tmpSQL1;
    end;
  end;
end;

procedure TDCLGrid.AddFilter(Filter: TDBFilter);
var
  I, FTop: Integer;
  S: String;
  Item: TComboFilterItem;
begin
  CreateFilterPanel;
  FTop:=FilterLabelTop;

  Filter.FilterLabel:=TDialogLabel.Create(FFiltersPanel);
  Filter.FilterLabel.Parent:=FFiltersPanel;
  Filter.FilterLabel.Top:=FilterLabelTop;
  Filter.FilterLabel.Left:=FFilterLeft;
  Filter.FilterLabel.Caption:=InitCap(Filter.Caption);
  if not GPT.DisableColorScheme and (GPT.MainColor<>NoColorValue) then
    Filter.FilterLabel.Font.Color:=NegativeColor(GPT.MainColor);
  Inc(FTop, Filter.FilterLabel.Height+LabelTopInterval);

  case Filter.FilterType of
    ftNone: begin
      //
    end;
    ftDBFilter: begin
      Filter.CaseC:=False;
      Filter.NotLike:=True;
      Filter.FilterString:='';

      Filter.FilterQuery:=TDCLDialogQuery.Create(Self.GetComponent);
      FDBConnector.SetConnector(Filter.FilterQuery);
      Filter.FilterData:=TDataSource.Create(Self.GetComponent);
      Filter.FilterData.DataSet:=Filter.FilterQuery;
      Filter.FilterQuery.SQL.Text:=Filter.SQL;

      try
        Filter.FilterQuery.Open;
        Filter.FilterQuery.Last;
        Filter.FilterQuery.First;
      Except
        on E: Exception do
        begin
          raise TDCLException.Create( - 1116, E.Message);
        end;
      end;

      Filter.Control:=TDCLDBLookupCombo.Create(FFiltersPanel);
      Filter.Control.Parent:=FFiltersPanel;
      (Filter.Control as TDCLDBLookupCombo).Style:=csDropDownList;
      Filter.Control.Top:=FTop;
      Inc(FTop, NotCheckTopStep);  // Filter.Control.Height+CompenentTopStep);

      Filter.Control.Left:=FFilterLeft;
      (Filter.Control as TDCLDBLookupCombo).ListField:=Filter.ListField;
      (Filter.Control as TDCLDBLookupCombo).KeyField:=Filter.KeyField;

      If Filter.VarName<>'' Then
        FIDCLMain.Variables[FNamespace.CurrentNamespace, Filter.VarName]:=
          TrimRight(Filter.FilterQuery.FieldByName((Filter.Control as TDCLDBLookupCombo).KeyField).AsString);

      (Filter.Control as TDCLDBLookupCombo).ListSource:=Filter.FilterData;
      Filter.FilterKey:=(Filter.Control as TDCLDBLookupCombo).KeyField;

      Filter.Control.Width:=Filter.Width;

      (Filter.Control as TDCLDBLookupCombo).OnSelect:=ExecFilter;

      if TDCLDBLookupCombo=TDBMyLookupCombo then
      begin
        (Filter.Control as TDCLDBLookupCombo).FilterResetValue:=FilterResetValue;
        (Filter.Control as TDCLDBLookupCombo).AddResetValue:=True;
        (Filter.Control as TDCLDBLookupCombo).Partial:=Filter.Contains;
      end;

      If Filter.KeyValue<>'' Then
      begin
        try
          (Filter.Control as TDCLDBLookupCombo).KeyValue:=Filter.KeyValue;
          ExecFilter((Filter.Control as TDCLDBLookupCombo));
        Except
          //
        end;
      end
      Else
      begin
        try
          (Filter.Control as TDCLDBLookupCombo).KeyValue:=FilterResetValue;
        Except
          //
        end;
      end;
    end;

    ftContextFilter: begin
      Filter.Control:=TEdit.Create(FFiltersPanel);
      Filter.Control.Parent:=FFiltersPanel;

      If Filter.FilterName<>'' Then
        Filter.Control.Name:=Filter.FilterName;

      (Filter.Control as TEdit).Text:='';
      Filter.Control.Top:=FTop;
      Inc(FTop, Filter.Control.Height+CompenentTopStep);

      Filter.Control.Left:=FFilterLeft;
      Filter.Control.Width:=Filter.Width;
      (Filter.Control as TEdit).OnKeyUp:=OnContextFilter;
    end;

    ftComboFilter: begin
      Filter.CaseC:=False;
      Filter.NotLike:=True;
      Filter.FilterString:='';

      if Filter.ListField<>'' then
      begin
        Filter.Control:=TComboBox.Create(FFiltersPanel);
        (Filter.Control as TComboBox).Style:=TComboBoxStyle.csDropDownList;
        (Filter.Control as TComboBox).DropDownCount:=DropDownRows;
        Filter.Control.Parent:=FFiltersPanel;
        Filter.Control.Left:=FFilterLeft;
        Filter.Control.Top:=FTop;
        Filter.Control.Width:=Filter.Width;
        Inc(FTop, NotCheckTopStep);  // Filter.Control.Height+CompenentTopStep);

        for I:=1 to ParamsCount(Filter.ListField) do
        begin
          S:=GetParam(Filter.ListField, i);

          Item:=TComboFilterItem.Create;
          Item.Value:=Copy(S, Pos('/', S)+1, Length(S));
          Item.Key:=Copy(S, 1, Pos('/', S)-1);

          (Filter.Control as TComboBox).AddItem(Copy(S, Pos('/', S)+1, Length(S)), Item);
        end;
        (Filter.Control as TComboBox).ItemIndex:=0;
    {$IFDEF FPC}
        (Filter.Control as TComboBox).OnSelect:=ExecFilter;
    {$ELSE}
        (Filter.Control as TComboBox).OnClick:=ExecFilter;
    {$ENDIF}
      end;

      If Filter.KeyValue<>'' Then
      begin
        for I:=1 to (Filter.Control as TComboBox).Items.Count do
        begin
          if ((Filter.Control as TComboBox).Items.Objects[i-1] as TComboFilterItem).Key=Filter.KeyValue then
          begin
            (Filter.Control as TComboBox).ItemIndex:=i-1;
            break;
          end;
        end;
        ExecFilter((Filter.Control as TComboBox));
      end;
    end;
  end;

  if Filter.Field<>'' then
  begin
    Filter.NotCheck:=TCheckBox.Create(FFiltersPanel);
    Filter.NotCheck.Parent:=FFiltersPanel;
    Filter.NotCheck.Top:=FTop;
    Filter.NotCheck.Left:=FFilterLeft;
    Filter.NotCheck.Caption:='';
    Filter.NotCheck.Width:=CheckWidth;
    Filter.NotCheck.OnClick:=OnFilterNotCheckClick;

    Filter.NotCheckLabel:=TDialogLabel.Create(FFiltersPanel);
    Filter.NotCheckLabel.Parent:=FFiltersPanel;
    Filter.NotCheckLabel.Top:=FTop;
    Filter.NotCheckLabel.Left:=CheckWidth+FFilterLeft;
    if Filter.Width>80 then
      Filter.NotCheckLabel.Caption:=GetDCLMessageString(msNotFilter)
    else
      Filter.NotCheckLabel.Caption:=UTF8Copy(GetDCLMessageString(msNotFilter), 1, 3)+'.';

    if not GPT.DisableColorScheme and (GPT.MainColor<>NoColorValue) then
      Filter.NotCheckLabel.Font.Color:=NegativeColor(GPT.MainColor);

    Inc(FTop, Filter.NotCheck.Height);
  end;
  Inc(FTop, CompenentTopStep);

  Inc(FFilterLeft, FieldsStepLeft+Filter.Width);
  AdjustFilterPanel(FTop);

  FFilters.Add(Filter);
end;

procedure TDCLGrid.AddCalendar(ScrLine: String);
var
  Calendar: TDCLCalendar;
  tmpS: String;
  FTop: Integer;
begin
  CreateFilterPanel;
  FTop:=FilterLabelTop;

  Calendar:=TDCLCalendar.Create;
  Calendar.Caption:=FindParam('Label=', ScrLine);

  if FindParam('ParamName=', ScrLine)<>'' then
    Calendar.ParamName:=FindParam('ParamName=', ScrLine)
  else
    Calendar.Variable:=FindParam('VariableName=', ScrLine);

  tmpS:=FindParam('DefaultValue=', ScrLine);
  If tmpS<>'' Then
    Calendar.Value:=StrToDate(tmpS)
  Else
    Calendar.Value:=Date;

  tmpS:=FindParam('ReOpen=', ScrLine);
  If tmpS<>'' Then
    Calendar.ReOpen:=True
  Else
    Calendar.ReOpen:=False;

  Calendar.LabelField:=TDialogLabel.Create(FFiltersPanel);
  Calendar.LabelField.Parent:=FFiltersPanel;
  Calendar.LabelField.Top:=FilterLabelTop;
  Calendar.LabelField.Left:=FFilterLeft;
  Calendar.LabelField.Caption:=InitCap(Calendar.Caption);
  if not GPT.DisableColorScheme and (GPT.MainColor<>NoColorValue) then
    Calendar.LabelField.Font.Color:=NegativeColor(GPT.MainColor);
  Inc(FTop, Calendar.LabelField.Height+LabelTopInterval);

  Calendar.Control:=TDateTimePicker.Create(FFiltersPanel);
  Calendar.Control.Parent:=FFiltersPanel;
  Calendar.Control.DateFormat:=GPT.DateFormat;

  Calendar.Control.Top:=FTop;
  Inc(FTop, Calendar.Control.Height+CompenentTopStep);
  Calendar.Control.Left:=FFilterLeft;

  Calendar.Control.Date:=Calendar.Value;
  If Calendar.Variable<>'' Then
    FIDCLMain.Variables.NewVariable(FNamespace, Calendar.Variable, DateToStr(Calendar.Control.Date));

  Calendar.Control.OnChange:=CalendarOnChange;
  Inc(FFilterLeft, FieldsStepLeft+Calendar.Control.Width);
  AdjustFilterPanel(Ftop);

  FCalendars.Add(Calendar);
end;

procedure TDCLGrid.CalendarOnChange(Sender: TObject);
var
  c, Calendar: TDCLCalendar;
begin
  Calendar:=nil;
  for c in FCalendars do
  begin
    if c.Control=(Sender as TDateTimePicker) then
    begin
      Calendar:=c;
      break;
    end;
  end;

  if Assigned(Calendar) then
  begin
    Calendar.Value:=(Sender as TDateTimePicker).Date;
    if (Calendar.ParamName<>'') and Assigned(FQuery.ParamByName(Calendar.ParamName)) then
      FQuery.ParamByName(Calendar.ParamName).AsDate:=Calendar.Value
    else if Calendar.Variable<>'' then
      FIDCLMain.Variables[FNamespace.CurrentNamespace, Calendar.Variable]:=DateToStr(Calendar.Value);

    If Calendar.ReOpen Then
    begin
      OpenQuery(QueryBuilder);
    end;
  end;
end;

procedure TDCLGrid.AddCheckBox(Field: TDCLField; Scr: String);
begin
  If (not Field.NoDataField) and FQuery.Active and FieldExists(FQuery, Field.FieldName) Then
    AddDBCheckBox(Field, Scr)
  Else
    AddSimplyCheckBox(Field, Scr);
end;

procedure TDCLGrid.AddSimplyCheckBox(Field: TDCLField; Scr: String);
var
  CheckBox: TCheckBox;
begin
  CheckBox:=TCheckbox.Create(FFieldsPanel);
  CheckBox.Parent:=FFieldsPanel;
  CheckBox.Caption:='';

  Field.DCLEditComponent:=TDCLEdit.Create;
  Field.DCLEditComponent.Control:=CheckBox;

  If Field.Hint<>'' Then
  begin
    CheckBox.ShowHint:=True;
    CheckBox.Hint:=Field.Hint;
  end;

  If Field.Variable<>'' Then
  begin
    FIDCLMain.Variables.NewVariableWithTest(FNamespace, Field.Variable);
  end
  Else
  begin
    FIDCLMain.Variables.NewVariableWithTest(FNamespace, 'CheckBox_'+Field.FieldName);
    Field.Variable:='CheckBox_'+Field.FieldName;
  end;

  if Field.CheckState<>0 then
  begin
    CheckBox.Checked:=Field.CheckState=1;
  end;
  CheckBox.Checked:=Field.Value='1';

  CheckBox.OnClick:=CheckOnClick;
  CheckBox.Width:=CheckWidth;

  Case CheckBox.Checked of
  True:
  FIDCLMain.Variables[FNamespace.CurrentNamespace, Field.Variable]:='1';
  False:
  FIDCLMain.Variables[FNamespace.CurrentNamespace, Field.Variable]:='0';
  end;
end;

procedure TDCLGrid.AddDBCheckBox(Field: TDCLField; Scr: String);
var
  DBCheckBox: TDBCheckBox;
begin
  DBCheckBox:=TDBCheckBox.Create(FFieldsPanel);
  DBCheckBox.Parent:=FFieldsPanel;
  DBCheckBox.Width:=CheckWidth;
  DBCheckBox.ShowHint:=True;
  DBCheckBox.Hint:=Field.Hint;
  DBCheckBox.Caption:='';
  DBCheckBox.ReadOnly:=Field.ReadOnly;

  DBCheckBox.DataSource:=FData;
  DBCheckBox.DataField:=Field.FieldName;

  If Field.CheckValue<>'' Then
    DBCheckBox.ValueChecked:=Field.CheckValue;
  If Field.UnCheckValue<>'' Then
    DBCheckBox.ValueUnchecked:=Field.UnCheckValue;

  if Field.CheckState<>0 then
    DBCheckBox.Checked:=Field.CheckState=1;

  DBCheckBox.Checked:=Field.Value='1';

  Field.DCLEditComponent:=TDCLEdit.Create;
  Field.DCLEditComponent.Control:=DBCheckBox;
end;

procedure TDCLGrid.CheckOnClick(Sender: TObject);
var
  Field, f: TDCLField;
begin
  Field:=nil;
  for f in FDCLFields do
  begin
    if Assigned(f.DCLEditComponent) and Assigned(f.DCLEditComponent.Control) then
    if f.DCLEditComponent.Control=Sender then
    begin
      Field:=f;
      break;
    end;
  end;

  if Assigned(Field) then
  begin
    If FIDCLMain.Variables.Exists(FNamespace.CurrentNamespace, Field.Variable) then
    begin
      Case (Sender as TCheckbox).Checked of
      True:
      FIDCLMain.Variables[FNamespace.CurrentNamespace, Field.Variable]:='1';
      False:
      FIDCLMain.Variables[FNamespace.CurrentNamespace, Field.Variable]:='0';
      end;
    end;
  end;
end;

function TDCLGrid.GetSummQuery: String;
var
  SQL: String;
  Parser: TSQLParser;
begin
  If Assigned(FQuery) Then
  begin
    SQL:=FQuery.SQL.Text;
    If SQL<>'' Then
    begin
      Parser:=TSQLParser.Create;
      Parser.ExcludeOrderBy(SQL);
      Parser.ExcludeGroupBy(SQL);

      Result:=Parser.ReplaseSQLFields(SQL, FSummFieldsSet);
    end
    Else
      Result:='';
  end
  Else
    Result:='';
end;

procedure TDCLGrid.AddSumGrid(ScrLine: String);
var
  ColumnsStr, KeyField, FieldName, FieldWidthStr: String;
  FieldWidth, ParamCounts, v2: Integer;
begin
  FSumQuery:=TDCLDialogQuery.Create(Self.GetComponent);
  FSummFieldsSet:=FindParam('SummQuery=', ScrLine);
  FSumQuery.SQL.Text:=GetSummQuery;
  FDBConnector.SetConnector(FSumQuery);
  FSumData:=TDataSource.Create(Self.GetComponent);
  FSumData.DataSet:=FSumQuery;
  FSumQuery.Open;

  FSummGrid:=TDBGrid.Create(FMainPanel);
  FSummGrid.Align:=alBottom;
  FSummGrid.Height:=SummGridHeight;
  FSummGrid.Name:='SumGrid';
  FSummGrid.Parent:=FMainPanel;
  FSummGrid.Options:=[dgColLines];
  FSummGrid.DataSource:=FSumData;
  FSummGrid.ScrollBars:=ssNone;

  ColumnsStr:=FindParam('Columns=', ScrLine);
  If ColumnsStr<>'' Then
  begin
    FSummGrid.Columns.Clear;
    ParamCounts:=ParamsCount(ColumnsStr);
    For v2:=1 to ParamCounts do
    begin
      FieldWidth:=0;
      KeyField:=GetParam(ColumnsStr, v2);
      FieldName:=Copy(KeyField, 1, Pos('/', KeyField)-1);
      FieldWidthStr:=Copy(KeyField, Pos('/', KeyField)+1, Length(KeyField));
      if FieldWidthStr<>'' then
        FieldWidth:=StrToIntEx(FieldWidthStr);
      If FieldExists(FSumQuery, FieldName) Then
      begin
        FSummGrid.Columns.Add.FieldName:=FieldName;
        if FieldWidth>0 then
          FSummGrid.Columns[v2-1].Width:=FieldWidth;
      end
      Else
      begin
        FSummGrid.Columns.Add;
        if FieldWidth>0 then
          FSummGrid.Width:=FieldWidth;
      end;
    end;
  end;
end;

procedure TDCLGrid.AddDateBox(Field: TDCLField; Scr: String);
var
  NeedValue: Integer;
  DateBox: TDateTimePicker;
  S, KeyField: String;
  ShadowQuery: TDCLDialogQuery;
begin
  DateBox:=TDateTimePicker.Create(FFieldsPanel);
  DateBox.Parent:=FFieldsPanel;
  DateBox.DateFormat:=GPT.DateFormat;

  Field.DCLEditComponent:=TDCLEdit.Create;
  Field.DCLEditComponent.Control:=DateBox;

  DateBox.Name:=Field.ComponentName;

  If Field.Hint<>'' Then
  begin
    DateBox.ShowHint:=True;
    DateBox.Hint:=Field.Hint;
  end;

  DateBox.Date:=Date;
  DateBox.OnChange:=OnChangeDateBox;

  DateBox.Enabled:=Field.Enabled;

  If Field.Width>0 Then
    DateBox.Width:=Field.Width;

  NeedValue:=0;
  If Field.Value<>'' then
    NeedValue:=1;
  If Field.SQL<>'' then
    NeedValue:=2;

  if not Field.NoDataField then
  begin
    If FQuery.Active Then
    Begin
      If FindParam('_ValueIfNull=', Scr)<>'' Then
      Begin
        If FieldExists(FQuery, Field.FieldName) Then
          if FQuery.FieldByName(Field.FieldName).IsNull then
            NeedValue:=4;
      End;
    End;
  end;

  S:='';
  Case NeedValue of
  0:
  If FQuery.Active Then
  begin
    If FieldExists(FQuery, Field.FieldName) Then
      S:=TrimRight(FQuery.FieldByName(Field.FieldName).AsString);
  end
  Else
    S:=DateToStr(Date);
  1:
  begin
    S:=Field.Value;
  end;
  2:
  begin
    ShadowQuery:=TDCLDialogQuery.Create(Self.GetComponent);
    FDBConnector.SetConnector(ShadowQuery);
    ShadowQuery.SQL.Text:=Field.SQL;
    ShadowQuery.Open;
    If FindParam('ReturnField=', Scr)<>'' Then
      KeyField:=FindParam('ReturnField=', Scr)
    Else
      KeyField:=ShadowQuery.Fields[0].FieldName;

    DeleteNonPrintSimb(KeyField);
    If FieldExists(ShadowQuery, KeyField) Then
      S:=TrimRight(ShadowQuery.FieldByName(KeyField).AsString)
    Else
      S:=DateToStr(Date);
    ShadowQuery.Close;
    FreeAndNil(ShadowQuery);
  end;
  4:begin
    S:=FindParam('_ValueIfNull', Scr);
  end;
  end;

  If Field.Variable<>'' Then
  begin
    FIDCLMain.Variables.NewVariable(FNamespace, Field.Variable, S);
  end
  Else
  begin
    FIDCLMain.Variables.NewVariable(FNamespace, 'DateBox_'+Field.FieldName, S);
    Field.Variable:='DateBox_'+Field.FieldName;
  end;

  If S<>'' then
  begin
    DateBox.Date:=StrToDate(S);
    OnChangeDateBox(DateBox);
  end;
end;

procedure TDCLGrid.OnChangeDateBox(Sender: TObject);
var
  f, Field: TDCLField;
  Value: String;
begin
  Field:=nil;
  for f in FDCLFields do
  begin
    if Assigned(f.DCLEditComponent) and (f.DCLEditComponent.Control=Sender) then
    begin
      Field:=f;
      break;
    end;
  end;

  if Assigned(Field) then
  begin
    // Update variables
    Value:=DateToStr((f.DCLEditComponent.Control as TDateTimePicker).Date);
    FIDCLMain.Variables[FNamespace.CurrentNamespace, Field.Variable]:=Value;

    If not Field.ReadOnly then
    begin
      if not Field.NoDataField then
      Begin
        If FQuery.Active then
        begin
          If FieldExists(FQuery, Field.FieldName) then
          begin
            if FQuery.CanModify then
            begin
              FQuery.Edit;
              FQuery.FieldByName(Field.FieldName).AsString:=Value;
            end;
          end;
        end;
      End;
    end;
  end;
end;

function TDCLGrid.ParseCommonFilter(ScrLine: String): TDBFilter;
var
  FFilter: TDBFilter;
  tmpS: String;
  v1: Integer;
begin
  FFilter:=TDBFilter.Create;
  FFilter.SQL:=FindParam('SQL=', ScrLine);
  If FFilter.SQL='' Then
    FFilter.SQL:=FindParam('DBFilterQuery=', ScrLine);

  FFilter.FilterType:=ftNone;

  FFilter.Caption:=FindParam('Label=', ScrLine);
  FFilter.Field:=FindParam('FilterField=', ScrLine);
  FFilter.ListField:=FindParam('List=', ScrLine);
  FFilter.KeyField:=FindParam('Key=', ScrLine);
  FFilter.Between:=FindParam('Between=', ScrLine)='1';

  v1:=FilterWidth;
  If FindParam('Width=', ScrLine)<>'' then
    v1:=StrToIntEx(Trim(FindParam('Width=', ScrLine)));
  FFilter.Width:=v1;

  If FindParam('MaxLength=', ScrLine)<>'' Then
  begin
    FFilter.MaxLength:=StrToIntEx(Trim(FindParam('MaxLength=', ScrLine)));
  end;

  FFilter.VarName:=FindParam('VariableName=', ScrLine);
  FFilter.KeyValue:=FindParam('KeyValue=', ScrLine);

  tmpS:=FindParam('WaitForEnter=', ScrLine);
  If tmpS='1' Then
  begin
    FFilter.WaitForKey:=13;
  end;

  tmpS:=FindParam('FilterMode=', ScrLine);
  If tmpS<>'' Then
  begin
    If PosEx('Case', tmpS)<>0 Then
      FFilter.CaseC:=True;

    If PosEx('NotLike', tmpS)<>0 Then
      FFilter.NotLike:=True;

    If PosEx('Partial', tmpS)<>0 Then
      FFilter.Contains:=True;
  end;

  If PosEx('ComponentName=', ScrLine)<>0 Then
    FFilter.FilterName:=FindParam('ComponentName=', ScrLine);

  FFilter.KeyValue:=FindParam('_Value=', ScrLine);
  Result:=FFilter;
end;

procedure TDCLGrid.ParseDBFilter(const Filter: TDBFilter; const Grid: TDCLGrid);
begin
  If Filter.SQL<>'' Then
  begin
    Filter.FilterType:=ftDBFilter;
    If Filter.VarName<>'' Then
    begin
      FIDCLMain.Variables.NewVariable(FNamespace, Filter.VarName, '');
    end;
    Grid.AddFilter(Filter);
  end;
end;

procedure TDCLGrid.ParseContextFilter(const Filter: TDBFilter; const Grid: TDCLGrid);
begin
  Filter.FilterType:=ftContextFilter;
  If Filter.VarName<>'' Then
  begin
    FIDCLMain.Variables.NewVariable(FNamespace, Filter.VarName, '');
  end;
  Grid.AddFilter(Filter);
end;

procedure TDCLGrid.ParseComboFilter(const Filter: TDBFilter; const Grid: TDCLGrid);
begin
  Filter.FilterType:=ftComboFilter;
  If Filter.VarName<>'' Then
  begin
    FIDCLMain.Variables.NewVariable(FNamespace, Filter.VarName, '');
  end;
  Grid.AddFilter(Filter);
end;

procedure TDCLGrid.OnFilterNotCheckClick(Sender: TObject);
var
  f, Filter: TDBFilter;
begin
  Filter:=nil;
  for f in FFilters do
  begin
    if Assigned(f.NotCheck) and (f.NotCheck=Sender) then
    begin
      Filter:=f;
      break;
    end;
  end;

  if Assigned(Filter) then
  begin
    Filter.NotFilter:=(Sender as TCheckBox).Checked;
    OpenQuery(QueryBuilder);
  end;
end;

procedure TDCLGrid.ExecFilter(Sender: TObject);
var
  f, Filter: TDBFilter;
  cbx: TComboBox;
begin
  Filter:=nil;
  for f in FFilters do
  begin
    if Assigned(f.Control) and (f.Control=Sender) then
    begin
      Filter:=f;
      break;
    end;
  end;

  if Assigned(Filter) then
  begin
    case Filter.FilterType of
    ftDBFilter: begin
      Filter.FilterString:=TrimRight((Sender as TDCLDBLookupCombo).KeyValue);
    end;
    ftComboFilter: begin
      cbx:=Sender as TComboBox;
      if cbx.ItemIndex<>-1 then
        Filter.FilterString:=(cbx.Items.Objects[cbx.ItemIndex] as TComboFilterItem).Key;
    end;
    end;
    if Filter.VarName<>'' then
      FIDCLMain.Variables[FNameSpace.CurrentNamespace, Filter.VarName]:=Filter.FilterString;

    OpenQuery(QueryBuilder);
  end;
end;

procedure TDCLGrid.OnContextFilter(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  f, Filter: TDBFilter;
  ExeplStr: String;
begin
  Filter:=nil;
  for f in FFilters do
  begin
    if Assigned(f.Control) and (f.Control=Sender) then
    begin
      Filter:=f;
      break;
    end;
  end;

  if Assigned(Filter) then
  begin
    ExeplStr:=(Sender as TEdit).Text;

    If FQuery.Active and FieldExists(FQuery, Filter.Field) then
    Begin
      If not CheckStrFmtType(ExeplStr, GetSimplyFieldType(Filter.Field, FQuery)) then
      Begin
        ExeplStr:='';
      End;
      Filter.FilterString:=ExeplStr;
    End;

    if Filter.VarName<>'' then
      FIDCLMain.Variables[FNamespace.CurrentNamespace, Filter.VarName]:=TrimRight(ExeplStr);

    If Filter.WaitForKey<>0 Then
    begin
      If Key=Filter.WaitForKey Then
        OpenQuery(QueryBuilder);
    end
    else
      OpenQuery(QueryBuilder);
  end;
end;

function TDCLGrid.QueryBuilder: String;
var
  SQL, OrderBy, GroupBy, AddWhere: String;
  Parser: TSQLParser;
begin
  Result:='';
  SQL:=GetSQLFromStorage;
  if SQL<>'' then
  begin
    Parser:=TSQLParser.Create;
    AddWhere:=Parser.ConcatSQLWhere(GetConditionsFromFindGrid, GetConditionsFromFilters);

    OrderBy:=SortDB(SQL);
    GroupBy:=Parser.ExcludeGroupBy(SQL);

    Result:=Parser.ConcatWhereToSQL(SQL, AddWhere)+' '+GroupBy+' '+OrderBy;
  end;
end;

function TDCLGrid.GetConditionsFromFindGrid: String;
var
  i, StrIndex: Integer;
  Parser: TSQLParser;
  Cond: String;
begin
  Result:='';
  if Assigned(FindGrid) then
  begin
    Parser:=TSQLParser.Create;

    StrIndex:=1;
    if Assigned(FDBGrid) then
      StrIndex:=0;

    for i:=1 to FindGrid.ColCount-1 do
    begin
      Cond:=Parser.GetFindGridCondition(FQuery, FindGrid.Cells[i, StrIndex], FindFields[i-1]);
      Result:=Parser.ConcatSQLWhere(Result, Cond);
    end;
    Result:=Result+' ';
  end
  else
    Result:='';
end;

function TDCLGrid.GetConditionsFromFilters: String;
var
  Filter, LastFilter: TDBFilter;
  Parser: TSQLParser;
  Cond: String;
begin
  Result:='';
  LastFilter:=nil;
  Parser:=TSQLParser.Create;
  for Filter in FFilters do
  begin
    Cond:=Parser.GetFilterCondition(FQuery, Filter, LastFilter);
    Result:=Parser.ConcatSQLWhere(Result, Cond);
    LastFilter:=Filter;
  end;
  Result:=Result+' ';
end;

procedure TDCLGrid.AddLookupTable(Field: TDCLField; Scr: String);
var
  TempStr, TmpStr, FieldName: String;
  v1, v2, v3: Integer;
  FFieldColumn: TDCLField;
  LookupTable: TLookupTable;
begin
  LookupTable:=TLookupTable.Create(FIDCLMain, FNameSpace, FForm, FFieldsPanel,
    FData);

  if Field.Width>0 then
    LookupTable.Width:=Field.Width
  else
    LookupTable.Width:=EditWidth;

  if Field.Height>0 then
    LookupTable.Height:=Field.Height
  else
    LookupTable.Height:=LookupTableHeight;

  LookupTable.DCLGrid.SetSQL(Field.SQL);
  if Field.SQL<>'' then
    LookupTable.DCLGrid.Query.Open;

  If PosEx('Navigator=', Scr)<>0 then
  begin
    LookupTable.DCLGrid.NavigatorVisible:=FindParam('Navigator=', Scr)='1';
    LookupTable.DCLGrid.FlatNavigator:=FindParam('Flat=', Scr)='1';

    LookupTable.DCLGrid.SetNavigatorButtonsSet(FindParam('NavigatorButtons=', Scr));
  end;

  LookupTable.DCLGrid.ReadOnly:=Field.ReadOnly;
  LookupTable.DCLGrid.DependField:=FindParam('DependField=', Scr);
  LookupTable.DCLGrid.SetNoDataField(Field.NoDataField);

  LookupTable.DCLGrid.MasterValueVariableName:=Field.Variable;

  if not Field.NoDataField then
  If FQuery.Active then
    If LookupTable.DCLGrid.MasterDataField='' then
      if FieldExists(FQuery, LookupTable.DCLGrid.MasterDataField) then
        LookupTable.DCLGrid.MasterDataField:=Field.FieldName;

  TempStr:=FindParam('Columns=', Scr);
  If TempStr<>'' Then
  begin
    v1:=ParamsCount(TempStr);
    For v2:=1 to v1 do
    begin
      v3:=0;
      TmpStr:=GetParam(TempStr, v2);
      FieldName:=Copy(TmpStr, 1, Pos('/', TmpStr)-1);
      if Pos('=', FieldName)<>0 then
      begin
        v3:=StrToIntEx(Copy(FieldName, Pos('=', FieldName)+1, Length(FieldName)));
        FieldName:=Copy(FieldName, 1, Pos('=', FieldName)-1);
      end;

      FFieldColumn:=TDCLField.Create;
      If FieldExists(LookupTable.DCLGrid.Query, FieldName) Then
      begin
        FFieldColumn.FieldName:=FieldName;
        FFieldColumn.Caption:=Copy(TmpStr, Pos('/', TmpStr)+1, Length(TmpStr)-1);
        if v3>10 then
          FFieldColumn.Width:=v3;
      end
      Else
      begin
        FFieldColumn.Caption:=GetDCLMessageString(msNoField)+FieldName;
      end;

      LookupTable.DCLGrid.AddField(FFieldColumn);
    end;
    LookupTable.DCLGrid.Prepeare;

    Field.DCLEditComponent:=TDCLEdit.Create;
    Field.DCLEditComponent.Control:=LookupTable;
  end;
end;

procedure TDCLGrid.ReFreshData;
var
  tpc: IDCLGrid;
begin
  If FQuery.Active Then
  Begin
    If FQuery.State in dsEditModes Then
      FQuery.Post;

    For tpc in FTableParts do
    begin
      tpc.Close;
    end;
    Close;
  End;

  Open;
  For tpc in FTableParts do
  begin
    tpc.Open;
  end;
end;

procedure TDCLGrid.Choose;
var
  ReturnValueParams: TReturnValueParams;
  ReturnValue: TReturnFormValue;
  ValueItem: TGetValueItem;
  Bookmark: TBookmark;
  CommandObj: IDCLCommand;
begin
  if Assigned(FForm.ReturnValueParams) then
  begin
    ReturnValueParams:=FForm.ReturnValueParams;
    if Assigned(FQuery) and FQuery.Active and FieldExists(FQuery, ReturnValueParams.KeyField) and
      ((ReturnValueParams.ValueField='') or FieldExists(FQuery, ReturnValueParams.ValueField)) then
    begin
      ReturnValue:=TReturnFormValue.Create;
      ReturnValue.KeyModifyField:=ReturnValueParams.KeyModifyField;
      ReturnValue.ValueModifyField:=ReturnValueParams.ValueModifyField;
      ReturnValue.KeyEditName:=ReturnValueParams.KeyEditName;
      ReturnValue.ValueEditName:=ReturnValueParams.ValueEditName;
      ReturnValue.KeyVar:=ReturnValueParams.KeyVar;
      ReturnValue.ValueVar:=ReturnValueParams.ValueVar;
      ReturnValue.BatchScript:=ReturnValueParams.BatchScript;
      ReturnValue.FinishScript:=ReturnValueParams.FinishScript;
      ReturnValue.Multiselect:=ReturnValueParams.Multiselect;

      if ReturnValueParams.InitScript<>'' then
      begin
        CommandObj:=TDCLCommand.Create(FIDCLMain, FNameSpace, FForm, Self);
        CommandObj.RunCommandScript(ReturnValueParams.InitScript);
      end;

      ReturnValue.Values:=TList<TGetValueItem>.Create;
      if Assigned(FDBGrid) and FMultiSelectMode and (FDBGrid.SelectedRows.Count>0) then
      begin
        for Bookmark in FDBGrid.SelectedRows do
        begin
          FQuery.GoToBookmark(TBookmark(Bookmark));
          ValueItem:=TGetValueItem.Create;
          ValueItem.Key:=FQuery.FieldByName(ReturnValueParams.KeyField).AsString;
          if ReturnValueParams.ValueField<>'' then
            ValueItem.Value:=FQuery.FieldByName(ReturnValueParams.ValueField).AsString;

          ReturnValue.Values.Add(ValueItem);
        end;
      end
      else
      begin
        ValueItem:=TGetValueItem.Create;
        ValueItem.Key:=FQuery.FieldByName(ReturnValueParams.KeyField).AsString;
        if ReturnValueParams.ValueField<>'' then
          ValueItem.Value:=FQuery.FieldByName(ReturnValueParams.ValueField).AsString;

        ReturnValue.Values.Add(ValueItem);
      end;
      FForm.GetValueProc(ReturnValue);

      if ReturnValueParams.Mode=cmChooseAndClose then
      begin
        FForm.Close;
      end;
    end;
  end;
end;

procedure TDCLGrid.SetMultiSelect(Value: Boolean);
begin
  FMultiSelectMode:=Value;
end;

function TDCLGrid.GetMultiSelectMode: Boolean;
begin
  Result:=FMultiSelectMode;
end;

procedure TDCLGrid.SetGridStyle(Value: TGridStyle);
begin
  FGridStyle:=Value;
end;

function TDCLGrid.GetGridStyle: TGridStyle;
begin
  Result:=FGridStyle;
end;

function TDCLGrid.GetCurrentTablePart: IDCLGrid;
begin
  Result:=nil;
  if (FCurrentTablePartIndex>=0) and (FTableParts.Count>FCurrentTablePartIndex) then
    Result:=FTableParts[FCurrentTablePartIndex];
end;

function TDCLGrid.GetSQLFromStorage: String;
begin
  Result:='';
  if FQueryes.ContainsKey(qtMain) then
    Result:=FQueryes[qtMain].QueryStr;
end;

procedure TDCLGrid.ParseEvents(ScrStr: String; const Grid: IDCLGrid);
var
  S: String;
begin
  if Assigned(Grid) then
  begin
    If PosEx('BeforePost=', ScrStr)<>0 then
    begin
      S:=FindParam('BeforePost=', ScrStr);
      Grid.AddEvent(evtBeforePost, S);
    end;

    If PosEx('AfterPost=', ScrStr)<>0 then
    begin
      S:=FindParam('AfterPost=', ScrStr);
      Grid.AddEvent(evtAfterPost, S);
    end;

    If PosEx('AfterInsert=', ScrStr)<>0 then
    begin
      S:=FindParam('AfterInsert=', ScrStr);
      Grid.AddEvent(evtInsert, S);
    end;

    If PosEx('Delete=', ScrStr)<>0 then
    begin
      S:=FindParam('Delete=', ScrStr);
      Grid.AddEvent(evtDelete, S);
    end;

    If PosEx('Cancel=', ScrStr)<>0 then
    begin
      S:=FindParam('Cancel=', ScrStr);
      Grid.AddEvent(evtCancel, S);
    end;

    If PosEx('Close=', ScrStr)<>0 then
    begin
      S:=FindParam('Close=', ScrStr);
      Grid.AddEvent(evtClose, S);
    end;

    If PosEx('Scroll=', ScrStr)<>0 then
    begin
      S:=FindParam('Scroll=', ScrStr);
      Grid.AddEvent(evtScroll, S);
    end;

    If PosEx('LineDblClick=', ScrStr)<>0 then
    begin
      S:=FindParam('LineDblClick=', ScrStr);
      Grid.AddEvent(evtLineDblClick, S);
    end;
  end;
end;

procedure TDCLGrid.ClearNotAllowedOperations;
begin
  FNotAllowedOperations.Clear;
end;

procedure TDCLGrid.ExcludeNotAllowedOperation(Operation: TNotAllowedOperation);
var
  O: TNotAllowedOperation;
begin
  for O in FNotAllowedOperations do
  begin
    if O=Operation then
    begin
      FNotAllowedOperations.Remove(O);
      break;
    end;
  end;
end;

procedure TDCLGrid.AddNotAllowedOperation(Operation: TNotAllowedOperation);
begin
  if not FindNotAllowedOperation(Operation) then
    FNotAllowedOperations.Add(Operation);
end;

function TDCLGrid.FindNotAllowedOperation(Operation: TNotAllowedOperation
  ): Boolean;
var
  O: TNotAllowedOperation;
begin
  Result:=False;
  for O in FNotAllowedOperations do
  begin
    if O=Operation then
    begin
      Result:=True;
      break;
    end;
  end;
end;

procedure TDCLGrid.AddBrushColor(const Line: String);
var
  BrushColor: TBrushColor;
  Color: String;
begin
  if not GPT.DisableColors then
  begin
    BrushColor:=TBrushColor.Create;
    Color:=FindParam('Color=', Line);

    Case GetStringDataType(Color) of
    idDigit:
    BrushColor.Color:=IntToColor(StrToIntEx(Color));
    idHex:
    BrushColor.Color:=IntToColor(Hex2Dec(Color));
    idColor:
    BrushColor.Color:=StringToColor(Color);
    end;

    BrushColor.ConditionValue:=FindParam('Condition=', Line);

    FBrushColors.Add(BrushColor);
  end;
end;

procedure TDCLGrid.GridDrawDataCell(Sender: TObject; const Rect: TRect;
  DataCol: Integer; Column: TColumn; State: TGridDrawState);
var
  flg: Boolean;
  RowTextColor: TColor;
  Brush, B: TBrushColor;
  Expressions: TList<TCondition>;
  CondItem: TCondition;
begin
  flg:=False;
  if not GPT.DisableColors and Assigned(FQuery) and FQuery.Active and (FBrushColors.Count>0) then
  begin
    Brush:=nil;
    for B in FBrushColors do
    begin
      if B.ConditionValue<>'' then
      begin
        Expressions:=LogicalParser(B.ConditionValue);

        for CondItem in Expressions do
        begin
          if FieldExists(FQuery, CondItem.FieldNameLeft) then
          begin
            CondItem.FieldNameLeft:=FQuery.FieldByName(CondItem.FieldNameLeft).AsString;
          end;
        end;

        if CalcLogicalExpression(Expressions) then
        begin
          flg:=True;
          Brush:=B;
          break;
        end;
      end;
    end;

    if flg and Assigned(Brush) then
    begin
      RowTextColor:=NegativeColor(Brush.Color);
      TDBGrid(Sender).Canvas.Brush.Color:=Brush.Color;
      TDBGrid(Sender).Canvas.Font.Color:=RowTextColor;

      With (Sender as TDBGrid).Canvas do
      begin
        FillRect(Rect);
      end;
      TDBGrid(Sender).DefaultDrawColumnCell(Rect, DataCol, Column, State);
    end;
  end;
end;

function TDCLGrid.GetFieldSetting(var List: TList<TGridFieldSetting>; FieldName: String): TGridFieldSetting;
var
  Item: TGridFieldSetting;
begin
  Result:=nil;
  for Item in List do
  begin
    if Item.FieldName=FieldName.ToUpper then
    begin
      Result:=Item;
      break;
    end;
  end;
end;

function TDCLGrid.CalculateSeed: String;
var
  Fields: TSortedList<String>;
  FN: TField;
  S, F, Se: String;
begin
  Result:='';

  Fields:=TSortedList<String>.Create;
  Fields.Duplicates:=dupIgnore;
  if Assigned(FQuery) and FQuery.Active then
  begin
    for FN in FQuery.Fields do
    begin
      S:=OnlyLitters(FN.FieldName).ToLowerInvariant;
      if S<>'' then
      begin
        if not Fields.Contains(S) then
          Fields.Add(S);
      end;
    end;
  end;
  Fields.Sort;

  Se:='';
  for F in Fields do
  begin
    Se:=Se+F;
  end;
  Result:=MD5String(Se);
end;

function TDCLGrid.GetGridSeed: String;
begin
  if FSeed='' then
    FSeed:=CalculateSeed;
  Result:=FSeed;
end;

procedure TDCLGrid.SetNoDataField(Value: Boolean);
begin
  FNoDataField:=Value;
end;

function TDCLGrid.GetNoDataField: Boolean;
begin
  Result:=FNoDataField;
end;

procedure TDCLGrid.SetPrintTool(Value: Boolean);
begin
  FPrintTool:=Value;
end;

function TDCLGrid.GetPrintTool: Boolean;
begin
  Result:=FPrintTool;
end;

procedure TDCLGrid.Structure(Sender: TObject);
var
  F: TDCLField;
  SF: TStructureField;
  i, c: Integer;
begin
  if Assigned(FDBGrid) then
  begin
    if not Assigned(FStructureList) then
    begin
      FStructureList:=TCheckListBox.Create(FMainPanel);
      FStructureList.Parent:=FMainPanel;
      FStructureList.Align:=alRight;
      FStructureList.Width:=FMainPanel.Width div 3;

      for F in FDCLFields do
      begin
        SF:=TStructureField.Create;
        SF.FieldName:=F.FieldName;

        FStructureList.AddItem(F.Caption+'\'+F.FieldName.ToUpper, SF);
        FStructureList.Checked[FStructureList.Count-1]:=IsGridColumnExists(F.FieldName);
      end;
    end
    else
    begin
      for F in FDCLFields do
      begin
        for i:=1 to FStructureList.Count do
        begin
          SF:=FStructureList.Items.Objects[i-1] as TStructureField;
          if SF.FieldName.ToLower.Equals(F.FieldName.ToLower) then
          begin
            if FStructureList.Checked[i-1] and not IsGridColumnExists(F.FieldName) then
            begin
              AddColumn(F);
            end
            else
            begin
              if not FStructureList.Checked[i-1] and IsGridColumnExists(F.FieldName) then
              begin
                for c:=1 to FDBGrid.Columns.Count do
                begin
                  if FDBGrid.Columns[c-1].FieldName.ToLower.Equals(F.FieldName.ToLower) then
                  begin
                    FDBGrid.Columns[c-1].Free;
                    break;
                  end;
                end;
              end;
            end;
            break;
          end;
        end;
      end;

      FStructureList.Clear;
      FreeAndNil(FStructureList);
    end;
  end;
end;

function TDCLGrid.IsGridColumnExists(FieldName: String): Boolean;
var
  i: Integer;
begin
  Result:=False;
  for i:=1 to FDBGrid.Columns.Count do
  begin
    if FDBGrid.Columns[i-1].FieldName.ToLower.Equals(FieldName.ToLower) then
    begin
      Result:=True;
      break;
    end;
  end;
end;

procedure TDCLGrid.AddPopupItem(Caption: String; Action: TPopupMenuAction;
  AChortCutKey: String; PictType: TPicturesTypes);
var
  ItemMenu: TMenuItem;
begin
  ItemMenu:=TMenuItem.Create(PopupGridMenu);
  ItemMenu.Tag:=Ord(Action);
  ItemMenu.Caption:=Caption;
  ItemMenu.ShortCut:=TextToShortCut(AChortCutKey);
  ItemMenu.OnClick:=OnPopupMenuClick;
  ItemMenu.ImageIndex:=FIDCLMain.GetImageIndex(PictType);

  PopupGridMenu.Items.Add(ItemMenu);
end;

procedure TDCLGrid.AddPopupSeparator;
var
  ItemMenu: TMenuItem;
begin
  ItemMenu:=TMenuItem.Create(PopupGridMenu);
  ItemMenu.Caption:='-';
  PopupGridMenu.Items.Add(ItemMenu);
end;

procedure TDCLGrid.OnPopupMenuClick(Sender: TObject);
var
  t: Integer;
begin
  t:=(Sender as TComponent).Tag;
  case TPopupMenuAction(t) of
    pmaCopy: PCopy;
    pmaCut: Cut;
    pmaPaste: Paste;
    pmaUndo: Undo;
    pmaFindCurrCell: SetTempFilter;
    pmaDelTempFilter: DeleteTempFilter;
    pmaClearFind: begin
      if Assigned(FindGrid) then
      begin
        for t:=1 to FindGrid.ColCount-1 do
        begin
          FindGrid.Cells[t, FindGrid.RowCount-1]:='';
        end;

        ApplyFind;
      end;
    end;
  end;
end;

procedure TDCLGrid.PopupMenuOnPopup(Sender: TObject);
var
  I: TMenuItem;
  F: TDBFilter;
  h: Boolean;
begin
  h:=False;
  for F in FFilters do
  begin
    if F.FilterType=ftTempFilter then
    begin
      h:=True;
      break;
    end;
  end;

  for I in PopupGridMenu.Items do
  begin
    if I.Tag=Ord(pmaDelTempFilter) then
    begin
      I.Visible:=h;
      break;
    end;
  end;
end;

procedure TDCLGrid.SetTempFilter;
var
  F, TempFilter: TDBFilter;
begin
  TempFilter:=nil;
  for F in FFilters do
  begin
    if F.FilterType=ftTempFilter then
    begin
      TempFilter:=F;
      break;
    end;
  end;

  if not Assigned(TempFilter) then
  begin
    TempFilter:=TDBFilter.Create;
    TempFilter.FilterType:=ftTempFilter;
    TempFilter.NotLike:=True;
    TempFilter.CaseC:=True;
    TempFilter.Contains:=False;
    FFilters.Add(TempFilter);
  end;

  if Assigned(TempFilter) then
  begin
    if FGridStyle=gsGrid then
    begin
      TempFilter.Field:=FDBGrid.SelectedColumn.FieldName;
      TempFilter.FilterString:=FDBGrid.SelectedColumn.Field.AsString;

      OpenQuery(QueryBuilder);
      RefreshGridColumns;
    end;
  end;
end;

procedure TDCLGrid.DeleteTempFilter;
var
  F: TDBFilter;
  flg: Boolean;
begin
  flg:=False;
  for F in FFilters do
  begin
    if F.FilterType=ftTempFilter then
    begin
      flg:=True;
      FFilters.Remove(F);
    end;
  end;
  if flg then
    OpenQuery(QueryBuilder);

  RefreshGridColumns;
end;

function TDCLGrid.GetSelectedRows: TBookmarkList;
begin
  Result:=nil;
  if Assigned(FDBGrid) then
  begin
    Result:=FDBGrid.SelectedRows;
  end;
end;

procedure TDCLGrid.Undo;
begin
  if Assigned(FDBGrid) then
  begin
    if Assigned(FData) and
      Assigned(FData.DataSet) then
        FData.DataSet.Cancel;
  end;
  {$IFDEF MSWINDOWS}
  SendMessage(GetFocus, WM_UNDO, 0, 0);
  {$ENDIF}
end;

procedure TDCLGrid.PCopy;
begin
  if Assigned(FDBGrid) then
    Clipboard.AsText:=FDBGrid.SelectedField.AsString;
end;

procedure TDCLGrid.Cut;
begin
  if Assigned(FDBGrid) then
  begin
    Clipboard.AsText:=FDBGrid.SelectedField.AsString;
    FDBGrid.SelectedField.Clear;
  end;
end;

procedure TDCLGrid.Paste;
begin
  if Assigned(FDBGrid) then
    FDBGrid.SelectedField.AsString:=Clipboard.AsText;
end;

constructor TDCLGrid.Create(const IDCLMain: IDCLMain; const NameSpace: TVariableNamespace; const Form: IDCLForm; const ParentControl: TWinControl;
  SurfType: TDataControlType; const Query: TDCLQuery; const Data: TDataSource);
var
  ChooseButton: TDCLCommandButton;
begin
  inherited Create;
  FParentControl:=ParentControl;
  FIDCLMain:=IDCLMain;

  FBasePanel:=TPanel.Create(ParentControl);
  FBasePanel.Parent:=ParentControl;
  FBasePanel.Align:=alClient;

  FMainPanel:=TPanel.Create(FBasePanel);
  FMainPanel.Parent:=FBasePanel;
  FMainPanel.Align:=alClient;

  FForm:=Form;

  FDialogName:=Form.DialogName;
  FDBConnector:=IDCLMain.GetDBConnector;
  FNameSpace:=NameSpace;

  FButtons:=TList<TDCLCommandButton>.Create;

  CloseButton:=SurfType=dctMainGrid;

  if Assigned(FForm.ReturnValueParams) then
  begin
    ChooseButton:=TDCLCommandButton.Create(FDBConnector);
    ChooseButton.ChoiceButton:=True;
    ChooseButton.Caption:=GetDCLMessageString(msChoose);
    ChooseButton.Default:=True;

    FButtons.Add(ChooseButton);
  end;

  FTableParts:=TList<IDCLGrid>.Create;
  FLookupTables:=TList<IDCLGrid>.Create;
  FDCLFields:=TList<TDCLField>.Create;
  FFilters:=TList<TDBFilter>.Create;
  FCalendars:=TList<TDCLCalendar>.Create;
  FEvents:=TList<TDCLEvent>.Create;
  FNotAllowedOperations:=TList<TNotAllowedOperation>.Create;
  FBrushColors:=TList<TBrushColor>.Create;

  FOrderByFields:=TStringList.Create;
  FNotOrderByFields:=TStringList.Create;
  FordersFields:=TList<TSortField>.Create;

  FFieldParsingMode:=fpmNone;
  FDataControlType:=SurfType;
  FReadFieldsMode:=False;
  FToolButtonsCount:=0;
  FFieldsCount:=-1;
  FReadFieldsMode:=False;
  FNoButtonPanel:=False;
  FNavigatorVisible:=False;
  FFlatNavig:=False;
  FPrintTool:=False;
  FGridStyle:=gsGrid;
  FCurrentTablePartIndex:=0;

  FMultiSelectMode:=False;
  FFilterLeft:=BeginStepLeft;

  FQueryes:=TDictionary<TQueryType, TDCLQueryStore>.Create;

  CreateToolPanel;

  FExtData:=Data;

  if Assigned(Query) then
    FQuery:=Query;

  FData:=TDataSource.Create(Self.GetComponent);
  if Assigned(Query) then
    FData.DataSet:=Query;
end;

destructor TDCLGrid.Destroy;
var
  FieldsPos: TStringList;
  ConfigPath, Seed: String;
  i: Integer;
begin
  If Assigned(FQuery) Then
  begin
    If FQuery.Active and (FQuery.State in dsEditModes) Then
      If ShowErrorMessage(Ord(mbtConfirmation),
        GetDCLMessageString(msSaveEditingsQ))=1 Then
      begin
        try
          FQuery.Post;
        Except
          //
        end;
      end
      Else
      begin
        try
          FQuery.Cancel;
        Except
          //
        end;
      end;
  end;

  if not GPT.DisableFieldsList then
  if (GetGridStyle=gsGrid) and Assigned(FDBGrid) then
  begin
    ConfigPath:=GPT.AppConfigDir+FormConfigDir+PathDelim+'Base_'+GPT.BaseID+PathDelim+'Forms'+PathDelim+FDialogName+PathDelim+'Grids'+PathDelim;
    if not DirectoryExists(ConfigPath) then
      ForceDirectories(ConfigPath);

    Seed:=GetGridSeed;
    FieldsPos:=TStringList.Create;
    GetDBGridFieldsPos(FieldsPos);

    try
      if FieldsPos.Count>0 then
        FieldsPos.SaveToFile(ConfigPath+Seed+'.ini', TEncoding.UTF8);
    except
    end;

    FreeAndNil(FieldsPos);
  end;
  FreeAndNil(FDCLFields);
  FreeAndNil(FFilters);
  for i:=1 to FTableParts.Count do
  begin
    FTableParts[i-1]:=nil;
  end;
  for i:=1 to FLookupTables.Count do
  begin
    FLookupTables[i-1]:=nil;
  end;
  FreeAndNil(FTableParts);
  FreeAndNil(FLookupTables);
  FForm:=nil;

  inherited Destroy;
end;

procedure TDCLGrid.AddField(Field: TDCLField);
begin
  FDCLFields.Add(Field);
end;

function TDCLGrid.GetComponent: TWinControl;
begin
  Result:=FBasePanel;
end;

procedure TDCLGrid.Show;
begin
  if Assigned(FBasePanel) then
    FBasePanel.Show;
end;

procedure TDCLGrid.Open;
begin
  If Length(FQuery.SQL.Text)>11 Then
  Try
    FQuery.Open;
  Except
    on E: Exception do
    begin
      raise TDCLException.Create(-1100, E.Message);
    end;
  End;

  {$IFnDEF NODSBOOKMARKS}
  If Assigned(FLocalBookmark) Then
    try
      if Length(FLocalBookmark)>0 then
      If FQuery.Active then
      If FQuery.BookmarkValid(FLocalBookmark) then
      If FQuery.RecordCount>0 then
        FQuery.Bookmark:=FLocalBookmark;
    finally
      FQuery.FreeBookmark(FLocalBookmark);
    end;
  {$ELSE}
  If Assigned(FLocalBookmark) Then
    FQuery.GotoKeyBookmark(FLocalBookmark);
  {$ENDIF}
end;

procedure TDCLGrid.Close;
begin
  If FQuery.Active Then
  begin
    If FQuery.State in dsEditModes Then
      FQuery.Post;
    {$IFnDEF NODSBOOKMARKS}
    FLocalBookmark:=FQuery.Bookmark;
    {$ELSE}
    FLocalBookmark:=FQuery.GetKeyBookmark;
    {$ENDIF}
    FQuery.Close;
  end;
end;

procedure TDCLGrid.CloseComponent;
begin
  ExecEvents(evtClose);
end;

procedure TDCLGrid.OnGridResize(Sender: TObject);
begin
  if Assigned(FToolBar) and (FToolButtonsCount>0) then
  begin
    FToolBar.ButtonWidth:=((FToolBar.ClientWidth-(ToolBarButtonSpliterWidth * (FToolButtonsCount-1))) div FToolButtonsCount)-FToolButtonsCount-1;
  end;
end;

procedure TDCLGrid.ExecScriptLine(ScrStr: String);
var
  tmpS, tmpS2, tmpSQL: String;
  i: Integer;
  QType: TDCLQueryStore;
begin
  if (FFieldsCount=-1) and FReadFieldsMode then
  begin
    if ScrStr='*' then
    begin
      AddAstericsFields;
    end
    else
    begin
      FFieldsCount:=StrToIntEx(ScrStr);
      FFieldParsingMode:=fpmCaption;
    end;

    Exit;
  end;

  if (FFieldsCount<>-1) and FReadFieldsMode then
  begin
    if FGridStyle in TDataFields then
    begin
      if not Assigned(FFieldsPanel) then
      begin
        FFieldsPanel:=TScrollBox.Create(FMainPanel);
        FFieldsPanel.Parent:=FMainPanel;
      end;
    end;

    ParseFields(ScrStr);

    if FDCLFields.Count>=FFieldsCount then
    begin
      FReadFieldsMode:=False;
      FFieldParsingMode:=fpmNone;
    end;

    Exit;
  end;

  if IsLexem('CommandButton=', ScrStr) then
  begin
    TranslateVal(ScrStr, True);
    ParseButton(ScrStr, Self);
  end;

  if IsLexem('TablePartToolButton=', ScrStr) then
  begin
    TranslateVal(ScrStr, True);
    ParseButton(ScrStr, GetCurrentTablePart);
  end;

  if IsLexem('Query=', ScrStr) then
  begin
    tmpSQL:=FindParam('Query=', ScrStr);
    if tmpSQL<>'' then
    begin
      SetNewQuery(FExtData);

      QType:=TDCLQueryStore.Create;
      QType.QueryStr:=tmpSQL;
      QType.QueryType:=qtMain;
      FQueryes.Add(qtMain, QType);

      TranslateVal(tmpSQL, False);
      FQuery.SQL.Text:=tmpSQL;
      try
        FQuery.Open;
      except
        on E: Exception do
          raise TDCLException.Create(-1000, E.Message);
      end;
    end;
  end;

  If IsLexem('UpdateTable=', ScrStr) then
  begin
    TranslateVal(ScrStr, False);
    tmpS:=FindParam('UpdateTable=', ScrStr);
    tmpS2:=FindParam('KeyFields=', ScrStr);
    If Assigned(FQuery) then
      FQuery.SetUpdateSQL(tmpS, tmpS2);
  end;

  if IsLexem('ReadOnly=', ScrStr) then
  begin
    TranslateVal(ScrStr, True);
    FReadOnly:=FindParam('ReadOnly=', ScrStr)='1';
  end;

  if IsLexem('ReadOnlyData=', ScrStr) then
  begin
    TranslateVal(ScrStr, True);
    FDataReadOnly:=FindParam('ReadOnlyData=', ScrStr)='1';
  end;

  if IsLexem('DataReadOnly=', ScrStr) then
  begin
    TranslateVal(ScrStr, True);
    FDataReadOnly:=FindParam('DataReadOnly=', ScrStr)='1';
  end;

  if IsLexem('Style=', ScrStr) then
  begin
    TranslateVal(ScrStr, True);
    tmpS:=FindParam('Style=', ScrStr);
    If tmpS='0' Then
      FGridStyle:=gsFields;
    If tmpS='1' Then
      FGridStyle:=gsFieldsHorizontal;
    If tmpS='2' Then
      FGridStyle:=gsGrid;
  end;

  If IsLexem('MultiSelect=', ScrStr) then
  begin
    FMultiSelectMode:=True;
  end;

  if IsLexem('OrderByFields=', ScrStr) then
  begin
    TranslateVal(ScrStr, True);
    for i:=1 to ParamsCount(FindParam('OrderByFields=', ScrStr)) do
    begin
      FOrderByFields.Append(GetParam(ScrStr, i));
    end;
  end;

  if IsLexem('NoOrderByFields=', ScrStr) then
  begin
    TranslateVal(ScrStr, True);
    for i:=1 to ParamsCount(FindParam('NoOrderByFields=', ScrStr)) do
    begin
      FNotOrderByFields.Append(GetParam(ScrStr, i));
    end;
  end;

  if IsLexem('Navigator=', ScrStr) then
  begin
    TranslateVal(ScrStr, True);
    FNavigatorVisible:=FindParam('Navigator=', ScrStr)='1';
    FFlatNavig:=FindParam('Flat=', ScrStr)='1';
    FNavigButtonsExpr:=FindParam('Buttons=', ScrStr);
  end;

  if IsLexem('TablePart=', ScrStr) then
  begin
    TranslateVal(ScrStr, False);
    AddTablePart(ScrStr);
  end;

  if IsLexem('DBFilter=', ScrStr) then
  begin
    TranslateVal(ScrStr, True);
    ParseDBFilter(ParseCommonFilter(ScrStr), Self);
  end;

  If IsLexem('ContextFilter=', ScrStr) then
  begin
    TranslateVal(ScrStr, True);
    ParseContextFilter(ParseCommonFilter(ScrStr), Self);
  end;

  If IsLexem('ComboFilter=', ScrStr) Then
  begin
    TranslateVal(ScrStr, True);
    ParseComboFilter(ParseCommonFilter(ScrStr), Self);
  end;

  If IsLexem('SummQuery=', ScrStr) Then
  begin
    TranslateVal(ScrStr, False);
    AddSumGrid(ScrStr);
  end;

  if IsLexem('Calendar=', ScrStr) then
  begin
    TranslateVal(ScrStr, True);
    AddCalendar(ScrStr);
  end;

  if IsLexem('Color=', ScrStr) then
  begin
    TranslateVal(ScrStr, False);
    AddBrushColor(ScrStr);
  end;

  If IsLexem('NoButtonsPanel;', ScrStr) then
  begin
    FNoButtonPanel:=True;
  end;

  If IsLexem('NoCloseButton;', ScrStr) then
  begin
    CloseButton:=False;
  end;

  If IsLexem('PrintTool;', ScrStr) then
  begin
    FPrintTool:=True;
  end;

  If IsLexem('AddNotAllowOperation=', ScrStr) then
  begin
    TranslateVal(ScrStr, True);
    tmpS:=FindParam('AddNotAllowOperation=', ScrStr);
    If PosEx('Insert', tmpS)<>0 then
      AddNotAllowedOperation(dsoInsert);
    If PosEx('Delete', tmpS)<>0 then
      AddNotAllowedOperation(dsoDelete);
    If PosEx('Edit', tmpS)<>0 then
      AddNotAllowedOperation(dsoEdit);
  end;

  If IsLexem('Events=', ScrStr) then
  begin
    ParseEvents(ScrStr, Self);
  end;

  If IsLexem('PartEvents=', ScrStr) then
  begin
    ParseEvents(ScrStr, GetCurrentTablePart);
  end;

  if IsLexem('[Fields]', ScrStr) then
  begin
    FReadFieldsMode:=True;
  end;
end;

procedure TDCLGrid.Prepeare;
var
  DCLField: TDCLField;
  Grid: IDCLGrid;
  btc: TDCLCommandButton;
  FieldsPos: TList<TGridFieldSetting>;
  FieldPos: TGridFieldSetting;
  ButtonClose: TDCLCommandButton;
begin
  CreateToolPanel;

  if CloseButton and (FDataControlType=dctMainGrid) then
  begin
    ButtonClose:=TDCLCommandButton.Create(FDBConnector);
    ButtonClose.Caption:=GetDCLMessageString(msClose);
    ButtonClose.CloseButton:=True;
    //ButtonClose.Pict:='esc';
    ButtonClose.Cancel:=True;
    FButtons.Insert(0, ButtonClose);
  end;

  if not Assigned(FToolBar) then
  begin
    FToolButtonsCount:=0;
    FToolBar:=TToolBar.Create(FToolsPanel);
    FToolBar.Parent:=FToolsPanel;
    FToolBar.Images:=FIDCLMain.GetImageList;
    FToolBar.OnResize:=OnGridResize;
    FToolBar.Height:=ToolButtonPanelHeight;
    FToolBar.ButtonHeight:=ToolButtonHeight;
    FToolBar.Flat:=ToolButtonsFlat;
    FToolBar.EdgeBorders:=[ebLeft, ebTop, ebRight];
    if not GPT.DisableColorScheme then
    begin
      if FDataControlType in [dctMainGrid] then
      begin
        if GPT.MainColor<>NoColorValue then
          FToolBar.Color:=GPT.MainColor;
      end
      else
      begin
        if GPT.TablePartColor<>NoColorValue then
          FToolBar.Color:=GPT.TablePartColor;
      end;
    end;
  end;

  if not Assigned(FNavig) then
  begin
    if FNavigatorVisible then
    begin
      FNavig:=TDBNavigator.Create(FToolsPanel);
      FNavig.Parent:=FToolsPanel;
      FNavig.Align:=alBottom;
      FNavig.DataSource:=FData;
      FNavig.OnClick:=OnNavigClick;

      Inc(FToolPanelHeight, FNavig.Height);

      ParseNavigatorButtons(FNavigButtonsExpr);

      FNavig.Flat:=FFlatNavig;
    end;
  end;
  if Assigned(FNavig) then
  begin
    If FindNotAllowedOperation(dsoDelete) Then
      FNavig.VisibleButtons:=FNavig.VisibleButtons-[nbDelete];
    If FindNotAllowedOperation(dsoInsert) Then
    begin
      FNavig.VisibleButtons:=FNavig.VisibleButtons-[nbInsert];
      FNavig.VisibleButtons:=FNavig.VisibleButtons-[nbPost];
      FNavig.VisibleButtons:=FNavig.VisibleButtons-[nbCancel];
    end;
    If FindNotAllowedOperation(dsoEdit) Then
    begin
      FNavig.VisibleButtons:=FNavig.VisibleButtons-[nbEdit];
      FNavig.VisibleButtons:=FNavig.VisibleButtons-[nbPost];
      FNavig.VisibleButtons:=FNavig.VisibleButtons-[nbCancel];
    end;
  end;

  if (not FNoButtonPanel) and not (FDataControlType in [dctLookupGrid]) then
  begin
    if not Assigned(FButtonPanel) then
    begin
      FButtonPanel:=TDCLButtonPanel.Create(Self.GetComponent);
      FButtonPanel.Parent:=GetComponent;
      FButtonPanel.AutoSize:=True;

      FButtonFlowPanel:=TFlowPanel.Create(FButtonPanel);
      FButtonFlowPanel.Parent:=FButtonPanel;
      FButtonFlowPanel.Align:=alClient;
      FButtonFlowPanel.AutoSize:=True;
    end;
    if FDataControlType=dctMainGrid then
      FButtonPanel.Align:=alBottom
    else
      FButtonPanel.Align:=alTop;

    if FButtons.Count>0 then
    begin
      for btc in FButtons do
      begin
        btc.CreateControl(FButtonFlowPanel, ClickCommandButton);
      end;
    end
    else
      FButtonPanel.Hide;
  end;

  if FQueryes.Count>0 then
  begin
    FToolBarButtonFind:=TToolButton.Create(FToolBar);
    FToolBarButtonFind.Parent:=FToolBar;
    FToolBarButtonFind.ImageIndex:=FIDCLMain.GetImageIndex(ptFind);
    FToolBarButtonFind.OnClick:=Find;
    Inc(FToolButtonsCount);
  end;

  if FDataReadOnly then
  begin
    FReadOnly:=True;
    {$IFDEF READONLYPROPERTY}
    if not FQuery.Active then
      FQuery.ReadOnly:=True;
    {$ELSE}
    AddNotAllowedOperation(dsoInsert);
    AddNotAllowedOperation(dsoDelete);
    AddNotAllowedOperation(dsoEdit);
    {$ENDIF}
  end;

  if FGridStyle in TDataFields then
  begin
    FFieldsPanel.Align:=alClient;

    case FGridStyle of
    gsFields: FFieldLayout:=TDCLVerticalFieldLayoutManger<TDCLField>.Create(FFieldsPanel, FDCLFields);
    gsFieldsHorizontal: FFieldLayout:=TDCLHorizontalFieldLayoutManger<TDCLField>.Create(FFieldsPanel, FDCLFields);
    end;
    FFieldLayout.InitMeasurements;

    for DCLField in FDCLFields do
    begin
      DCLField.FLabel:=TDialogLabel.Create(FFieldsPanel);
      DCLField.FLabel.Parent:=FFieldsPanel;
      DCLField.FLabel.Caption:=DCLField.Caption;
      if not GPT.DisableColorScheme and (GPT.MainColor<>NoColorValue) then
        DCLField.FLabel.Font.Color:=NegativeColor(GPT.MainColor);

      if not Assigned(DCLField.DCLEditComponent) and FQuery.Active then
      begin
        if FieldExists(FQuery, DCLField.FieldName) then
        begin
          FieldWidth(DCLField, FQuery.FieldByName(DCLField.FieldName).DataType);
          case FQuery.FieldByName(DCLField.FieldName).DataType of
            ftMemo, ftFmtMemo, ftBlob: begin
              If DCLField.DataFieldType=dftRichText Then
                AddMediaFieldGroup(DCLField, gtRichText)
              Else
                AddMediaFieldGroup(DCLField, gtMemo);
            end;
            ftGraphic, ftDBaseOle, ftParadoxOle, ftTypedBinary: begin
              AddMediaFieldGroup(DCLField, gtGrafic);
            end;
            ftDate: begin
              AddDBDateEdit(DCLField);
            end;
            {ftDateTime: begin
              AddDBDateEdit(DCLField);  // глюк, не работает отображение времени !!!
            end;}
            ftBoolean: begin
              AddDBCheckBox(DCLField, '');
            end
            else
              AddDBEdit(DCLField);
          end;
        end;
      end;
    end;
  end;

  if FGridStyle in TDataGrid then
  begin
    if not Assigned(FDBGrid) then
    begin
      if FDCLFields.Count>1 then
      begin
        if FToolButtonsCount>0 then
        begin
          FToolBarSplitter:=TToolButton.Create(FToolBar);
          FToolBarSplitter.Parent:=FToolBar;
          FToolBarSplitter.Style:=tbsSeparator;
          FToolBarSplitter.Width:=ToolBarButtonSpliterWidth;
        end;

        FToolBarButtonStruct:=TToolButton.Create(FToolBar);
        FToolBarButtonStruct.Parent:=FToolBar;
        FToolBarButtonStruct.ImageIndex:=FIDCLMain.GetImageIndex(ptStructure);
        FToolBarButtonStruct.OnClick:=Structure;
        Inc(FToolButtonsCount);
      end;

      if Assigned(FQuery) then
      begin
        if FPrintTool then
        begin
          if FToolButtonsCount>0 then
          begin
            FToolBarSplitter:=TToolButton.Create(FToolBar);
            FToolBarSplitter.Parent:=FToolBar;
            FToolBarSplitter.Style:=tbsSeparator;
            FToolBarSplitter.Width:=ToolBarButtonSpliterWidth;
          end;

          FToolBarButtonPrint:=TToolButton.Create(FToolBar);
          FToolBarButtonPrint.Parent:=FToolBar;
          FToolBarButtonPrint.ImageIndex:=FIDCLMain.GetImageIndex(ptPrint);
          FToolBarButtonPrint.OnClick:=Print;
          Inc(FToolButtonsCount);
        end;
      end;

      FDBGrid:=TDBGrid.Create(FMainPanel);
      FDBGrid.Parent:=FMainPanel;
      if FMultiSelectMode then
      begin
        FDBGrid.Options:=FDBGrid.Options+[dgMultiSelect];
      end;
      if FReadOnly then
      begin
        //FDBGrid.Options:=FDBGrid.Options+[dgRowSelect];
        FDBGrid.Options:=FDBGrid.Options-[dgEditing];
        FDBGrid.Options:=FDBGrid.Options+[dgDisableDelete];
        FDBGrid.Options:=FDBGrid.Options+[dgDisableInsert];
      end;

      FDBGrid.DataSource:=FData;
      if FBrushColors.Count=0 then
      begin
        if GPT.DisableColorScheme or (GPT.GridAlternateColor=NoColorValue) then
          FDBGrid.AlternateColor:=GridAlternateColor
        else
          FDBGrid.AlternateColor:=GPT.GridAlternateColor;
      end;
      FDBGrid.TitleImageList:=FIDCLMain.GetImageList;
      FDBGrid.OnDblClick:=GridDblClick;
      FDBGrid.OnTitleClick:=GridColumnClick;
      FDBGrid.OnUTF8KeyPress:=GridKeyPress;
      FDBGrid.OnKeyDown:=Grid1KeyDown;
      if not GPT.DisableColorScheme and (GPT.GridColor<>NoColorValue) then
        FDBGrid.Color:=GPT.GridColor;

      PopupGridMenu:=TPopupMenu.Create(FDBGrid);
      PopupGridMenu.Parent:=FDBGrid;
      PopupGridMenu.Images:=FIDCLMain.GetImageList;
      PopupGridMenu.OnPopup:=PopupMenuOnPopup;

      FDBGrid.PopupMenu:=PopupGridMenu;
      FDBGrid.OnDrawColumnCell:=GridDrawDataCell;

      AddPopupItem(GetDCLMessageString(msFindCurrCell), pmaFindCurrCell, 'Alt+F', ptFindCurrCell);
      AddPopupItem(GetDCLMessageString(msDeleteTempFilter), pmaDelTempFilter, 'Alt+D', ptClearAllFind);

      AddPopupSeparator;
      AddPopupItem(GetDCLMessageString(msClearAllFind), pmaClearFind, 'Alt+C', ptClearAllFind);

      AddPopupSeparator;

      AddPopupItem(GetDCLMessageString(msCopy), pmaCopy, 'Ctrl+C', ptCopy);

      if not FReadOnly then
      begin
        AddPopupItem(GetDCLMessageString(msCut), pmaCut, 'Ctrl+X', ptCut);
        AddPopupItem(GetDCLMessageString(msPast), pmaPaste, 'Ctrl+V', ptPaste);

        AddPopupSeparator;

        AddPopupItem(GetDCLMessageString(msCancel), pmaUndo, 'Ctrl+Z', ptUndo);
      end;

      if FDataControlType=dctLookupGrid then
      begin
        If Assigned(FNavig) Then
        begin
          FNavig.VisibleButtons:=FNavig.VisibleButtons-[nbPrior];
          FNavig.VisibleButtons:=FNavig.VisibleButtons-[nbNext];
        end;
      end;
    end;

    FDBGrid.Columns.Clear;

    FieldsPos:=LoadDBGridFieldsPos;
    if FieldsPos.Count>0 then
    begin
      for FieldPos in FieldsPos do
      begin
        DCLField:=FindDCLFieldByName(FieldPos.FieldName);
        if Assigned(DCLField) then
        begin
          DCLField.Width:=FieldPos.Width;
          AddColumn(DCLField);
        end;
      end;
    end
    else
    begin
      for DCLField in FDCLFields do
      begin
        AddColumn(DCLField);
      end;
    end;
  end;

  if FToolButtonsCount>0 then
    Inc(FToolPanelHeight, ToolButtonPanelHeight);

  if FTableParts.Count>0 then
  begin
    FTablePartsPages.Align:=alBottom;

    PartSplitter:=TSplitter.Create(FMainPanel);
    PartSplitter.Parent:=FMainPanel;
    PartSplitter.Align:=alBottom;

    FCurrentTablePartIndex:=0;
  end;

  if Assigned(FDBGrid) then
  begin
    FDBGrid.Align:=alClient;
  end;

  FSeed:=CalculateSeed;
  if Assigned(FQuery) then
    FQuery.NotAllowOperations:=FNotAllowedOperations;

  AdjustToolPanel;

  for Grid in FLookupTables do
  begin
    Grid.Prepeare;
  end;

  for Grid in FTableParts do
  begin
    Grid.Prepeare;
  end;
end;

procedure TDCLGrid.SetSQL(SQL: String);
var
  QType: TDCLQueryStore;
begin
  TranslateVal(SQL, False);

  if SQL<>'' then
  begin
    SetNewQuery(FExtData);
    if FQuery.Active then
      FQuery.Close;

    FQuery.SQL.Text:=SQL;

    QType:=TDCLQueryStore.Create;
    QType.QueryStr:=SQL;
    QType.QueryType:=qtMain;
    FQueryes.Add(qtMain, QType);
  end;
end;

procedure TDCLGrid.SetNavigatorButtonsSet(ButtonsExpr: String);
begin
  FNavigButtonsExpr:=ButtonsExpr;
end;

procedure TDCLGrid.ParseNavigatorButtons(ButtonsExpr: String);
var
  i: TDBNavButtonType;
  AllowEdit, HideNavig: Boolean;
  b: TNavButtonsSet;
  NavigVisiButtonsVar: Array [TDBNavButtonType] of TNavButtonsSet;

function IsButton(BurronName, ButtonsSet: String): Boolean;
begin
  Result:=(PosEx(BurronName, ButtonsSet)<>0) or (ButtonsSet='');
end;
begin
  if Assigned(FNavig) then
  begin
    AllowEdit:=False;
    if Assigned(FQuery) then
    begin
      AllowEdit:=FQuery.Active and FQuery.CanModify;
    end;

    For i:=Low(TDBNavButtonType) to High(TDBNavButtonType) do
      NavigVisiButtonsVar[i]:=[];

    If IsButton('first', ButtonsExpr) Then
      NavigVisiButtonsVar[nbFirst]:=[nbFirst];
    If IsButton('last', ButtonsExpr) Then
      NavigVisiButtonsVar[nbLast]:=[nbLast];

    If GetUserLevel>ulReadOnly Then
    if AllowEdit then
    begin
      if not FindNotAllowedOperation(dsoInsert) then
      If IsButton('insert', ButtonsExpr) Then
        NavigVisiButtonsVar[nbInsert]:=[nbInsert];

      if not FindNotAllowedOperation(dsoDelete) then
      If IsButton('delete', ButtonsExpr) Then
        NavigVisiButtonsVar[nbDelete]:=[nbDelete];

      if not FindNotAllowedOperation(dsoEdit) then
      If IsButton('edit', ButtonsExpr) Then
        NavigVisiButtonsVar[nbEdit]:=[nbEdit];

      if FNotAllowedOperations.Count=0 then
      begin
        If IsButton('post', ButtonsExpr) Then
          NavigVisiButtonsVar[nbPost]:=[nbPost];
        If IsButton('cancel', ButtonsExpr) Then
          NavigVisiButtonsVar[nbCancel]:=[nbCancel];
      end;
    end;
    If IsButton('refresh', ButtonsExpr) Then
      NavigVisiButtonsVar[nbRefresh]:=[nbRefresh];

    HideNavig:=True;
    for b in NavigVisiButtonsVar do
      if b<>[] then
      begin
        HideNavig:=False;
        Break;
      end;

    if not HideNavig then
    begin
      FNavig.VisibleButtons:=[];
      for b in NavigVisiButtonsVar do
      begin
        if b<>[] then
        begin
          FNavig.VisibleButtons:=FNavig.VisibleButtons+b;
        end;
      end;
    end
    else
    begin
      Dec(FToolPanelHeight, FNavig.Height);
      FNavig.Hide;
    end;
  end;
end;

procedure TDCLGrid.AddButton(Button: TDCLCommandButton);
begin
  if Assigned(Button) then
  begin
    FButtons.Add(Button);
    FNoButtonPanel:=False;
  end;
end;

procedure TDCLGrid.AddEvent(EventType: TEventsEnum; ScriptName: String);
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

function TDCLGrid.CheckEdits: Boolean;
var
  e: TDCLField;
begin
  Result:=True;
  if FGridStyle<>gsGrid then
  begin
    for e in FDCLFields do
    begin
      if e.RequireValue and (e.NotInputValue='') and not e.ReadOnly and e.Enabled then
      begin
        if Assigned(e.DCLEditComponent) and Assigned(e.DCLEditComponent.Control) then
        begin
          if (e.DCLEditComponent.Control is TDateTimePicker) and ((e.DCLEditComponent.Control as TDateTimePicker).Text='') then
          begin
            Result:=False;
          end;
          if (e.DCLEditComponent.Control is TDBDate) and ((e.DCLEditComponent.Control as TDateTimePicker).Text='') then
          begin
            Result:=False;
          end;
          if (e.DCLEditComponent.Control is TDBEdit) and ((e.DCLEditComponent.Control as TDBEdit).Text='') then
          begin
            Result:=False;
          end;
          if (e.DCLEditComponent.Control is TEdit) and ((e.DCLEditComponent.Control as TEdit).Text='') then
          begin
            Result:=False;
          end;
          if (e.DCLEditComponent.Control is TDBLookupComboBox) and VarIsNull((e.DCLEditComponent.Control as TDBLookupComboBox).KeyValue) then
          begin
            Result:=False;
          end;
          if (e.DCLEditComponent.Control is TComboBox) and ((e.DCLEditComponent.Control as TComboBox).ItemIndex=-1) then
          begin
            Result:=False;
          end;

          if not Result then
          begin
            NotifyEditFieldError(e);
            break;
          end;
        end;
      end;
    end;
  end;
end;

procedure TDCLGrid.NotifyEditFieldError(Field: TDCLField);
begin
  ShowErrorMessage(-11000, ' : '+Field.Caption);
end;

procedure TDCLGrid.GetDBGridFieldsPos(var Settings: TStringList);
var
  i: Integer;
  C: TColumn;
begin
  if Assigned(Settings) and not GPT.DisableFieldsList then
  begin
    if (GetGridStyle=gsGrid) and Assigned(FDBGrid) and Assigned(FDBGrid.Columns) then
    begin
      for i:=1 to FDBGrid.Columns.Count do
      begin
        C:=FDBGrid.Columns[i-1];
        Settings.Add(C.FieldName.ToUpper+'\'+IntToStr(C.Width));
      end;
    end;
  end;
end;

function TDCLGrid.LoadDBGridFieldsPos: TList<TGridFieldSetting>;
var
  Item: TGridFieldSetting;
  ConfigPath, S: String;
  SplitterPos, i: Integer;
  FieldsPos: TStringList;
begin
  Result:=TList<TGridFieldSetting>.Create;

  if Assigned(FDBGrid) and (GetGridStyle=gsGrid) and not GPT.DisableFieldsList then
  begin
    S:=GetGridSeed;
    ConfigPath:=GPT.AppConfigDir+FormConfigDir+PathDelim+'Base_'+GPT.BaseID+PathDelim+'Forms'+PathDelim+FDialogName+PathDelim+'Grids'+PathDelim;
    if DirectoryExists(ConfigPath) and FileExists(ConfigPath+S+'.ini') then
    begin
      FieldsPos:=TStringList.Create;
      FieldsPos.LoadFromFile(ConfigPath+S+'.ini', TEncoding.UTF8);
      if FieldsPos.Count>0 then
      begin
        for i:=1 to FieldsPos.Count do
        begin
          S:=FieldsPos[i-1];
          if S='' then Continue;

          Item:=TGridFieldSetting.Create;
          Item.Index:=i-1;
          Item.Width:=0;
          SplitterPos:=Pos('\', S);
          if SplitterPos=0 then
            Item.FieldName:=S
          else
          begin
            Item.FieldName:=S.Substring(0, SplitterPos-1);
            Item.Width:=StrToInt(S.Substring(SplitterPos));
          end;
          Result.Add(Item);
        end;
      end;

      FreeAndNil(FieldsPos);
    end;
  end;
end;

procedure TDCLGrid.ResetFieldsSettings;
var
  DCLField: TDCLField;
  Grid: IDCLGrid;
begin
  if Assigned(FDBGrid) then
  begin
    FDBGrid.Columns.Clear;
    for DCLField in FDCLFields do
    begin
      AddColumn(DCLField);
    end;

    for Grid in FLookupTables do
    begin
      Grid.ResetFieldsSettings;
    end;

    for Grid in FTableParts do
    begin
      Grid.ResetFieldsSettings;
    end;
  end;
end;

end.

