unit uDCLGrid;
{$I DefineType.pas}

interface

uses
  Classes, SysUtils, Controls, Forms, DB, Generics.Collections, ToolWin,
  ComCtrls, StdCtrls, ExtCtrls, Graphics, DBCtrls, DBGrids, Grids,
  DBExtCtrls, CheckLst, Menus, ClipBrd,
  uDCLData, uDCLTypes, uDCLConst, uDCLVariables, uStringParams,
  uDCLDBConnector, uDCLQuery, uDCLMeasurements, uDBUtils, uDCLMultiLang,
  uDCLCommandButton, uDCLField, uDCLMessages, uDCLImages, cNoScrollBarDBGrid,
  cMediaFieldGroup, uDCLBaseLayoutManger, uDCLButtonLayoutManger,
  uDCLVerticalFieldLayoutManger, uDCLHorizontalFieldLayoutManger;

type
  TGridFieldSetting=class
    FieldName: String;
    Index, Width: Integer;
  end;

  TStructureField=class
    FieldName: String;
  end;

  TSortField=class
    FieldName: String;
    Order: TSortOrder;
  end;

  { TDCLGrid }

  TDCLGrid=class(TWinControl)
  private
    FNameSpace, FDependField, FMasterDataField, FMasterValueVariableName,
      FSummFieldsSet, FNavigatorExpr, FSeed, FDialogName: String;
    FForms: TList<TForm>;
    FForm: TForm;
    FVariables: TVariables;
    FDBGrid: TDBGrid;
    FFieldsCount, FToolPanelHeight, FFilterPanelHeight: Integer;
    FToolsPanel: TPanel;
    FFilterLeft: Integer;
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
    FReadFieldsMode, FMultiSelectMode, FReadOnly, FDataReadOnly,
      FNoDataField, FNoButtonPanel, FindProcess: Boolean;
    FTableParts, FLookupTables: TList<TDCLGrid>;
    FCurrentTablePart: TDCLGrid;
    FDCLFields: TList<TDCLField>;
    FCurrentField: TDCLField;
    FFieldParsingMode: TFieldParsingMode;
    FToolBar: TToolBar;
    FToolButtonsCount: Integer;
    FToolBarSplitter, FToolBarButtonPrint, FToolBarButtonStruct, FToolBarButtonFind: TToolButton;
    PartSplitter: TSplitter;
    FTablePartsPages: TPageControl;
    FTablePartsTabs: TTabSheet;
    FImages: TImageList;
    FFilters: TList<TDBFilter>;
    FCalendars: TList<TDCLCalendar>;
    FPicturesIndexes: TDictionary<TPicturesTypes, Integer>;
    FOrdersFields: TList<TSortField>;
    FOrderByFields, FNotOrderByFields: TStringList;
    FSumQuery: TDCLDialogQuery;
    FSummGrid: TNoScrollBarDBGrid;
    FEvents: TList<TDCLEvent>;
    FNotAllowedOperations: TList<TNotAllowedOperation>;
    FStructureList: TCheckListBox;
    PopupGridMenu: TPopupMenu;

    FButtonLayout: TDCLButtonLayoutManger<TDCLCommandButton>;
    FFieldLayout: TDCLBaseLayoutManger<TDCLField>;

    FUserLevel: TUserLevelsType;

    function FindDCLFieldByName(FieldName: String): TDCLField;

    function GetFieldsCount: Integer;

    procedure CreateImageList;

    procedure OpenQuery(QText: String);

    procedure TranslateVal(var Params: String; CheckParams: Boolean);

    procedure SetQueryEvents(Query: TDCLQuery);

    procedure ClickNavigator(Sender: TObject; Button: TNavigateBtn);

    procedure SetDataStatus(Status: TDataStatus);
    procedure UpdateAllControls;
    // DataEvents
    procedure AfterInsert(Data: TDataSet);
    procedure ScrollDB(Data: TDataSet);
    procedure AfterOpen(Data: TDataSet);
    procedure AfterEdit(Data: TDataSet);
    procedure AfterPost(Data: TDataSet);
    procedure AfterCancel(Data: TDataSet);

    procedure BeforeScroll(Data: TDataSet);
    procedure BeforeEdit(Data: TDataSet);
    procedure BeforePost(Data: TDataSet);

    procedure OnDelete(Data: TDataSet);
    // End DataEvents

    procedure Find(Sender: TObject);
    procedure FindGridOnSelectCell(Sender: TObject; aCol, aRow: Integer;
      var CanSelect: Boolean);

    procedure Print(Sender: TObject);

    procedure ExecEvents(EventType: TEventsEnum);

    procedure GridDblClick(Sender: TObject);
    procedure GridColumnClick(Column: TColumn);

    function SortDB(var SQL: String): String;
    procedure ReDrawColumns;

    function GetEdits: TList<TDCLEdit>;

    procedure AddColumn(Field: TDCLField);
    procedure ParseFields(ScrLine: String);

    procedure CreateToolPanel;
    procedure OnToolPanelResize(Sender: TObject);
    procedure AdjustToolPanel;

    procedure CreateFilterPanel;
    procedure AdjustFilterPanel(Height: Integer);

    procedure OnResizeFilterPanel(Sender: TObject);
    procedure OnResizeButtonFlowPanel(Sender: TObject);

    procedure AddDropBox(Field: TDCLField; Scr: String);
    procedure DropListOnSelectItem(Sender: TObject);

    procedure AddDBDateEdit(Field: TDCLField);

    procedure AddMediaFieldGroup(Field: TDCLField; GroupType: TGroupType);

    procedure AddDBEdit(Field: TDCLField);
    procedure DBEditClick(Sender: TObject);

    procedure OnGridResize(Sender: TObject);

    procedure SetNewQuery(Data: TDataSource);

    procedure ClickCommandButton(Sender: TObject);

    function AddTablePart(Title: String; Data: TDataSource; Style: TGridStyle): TDCLGrid;
    procedure ChangePartTabPage(Sender: TObject);

    procedure AddContextButton(Field: TDCLField; Scr: String);
    procedure ContextFieldButtonsClick(Sender: TObject);

    procedure AddFieldBox(Field: TDCLField; FieldBoxType: TFieldBoxType; Scr: String);
    procedure FieldBoxOnClick(Sender: TObject);
    procedure FieldBoxOnEdit(Sender: TObject);
    procedure FieldBoxKeyPress(Sender: TObject; var Key: Char);

    procedure AddLookUp(Field: TDCLField; Scr: String);
    procedure LookupOnClick(Sender: TObject);
    procedure LookupDBScroll(Data: TDataSet);

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

    procedure AddFilter(Filter: TDBFilter);
    procedure OnFilterNotCheckClick(Sender: TObject);
    procedure ExecFilter(Sender: TObject);
    procedure OnContextFilter(Sender: TObject; var Key: Word; Shift: TShiftState);

    function QueryBuilder: String;
    function GetConditionsFromFindGrid: String;
    function GetConditionsFromFilters: String;

    procedure AddLookupTable(Field: TDCLField; Scr: String);

    procedure Choose;

    procedure SetMultiSelect(Value: Boolean);

    function GetSQLFromStorage: String;

    procedure ParseEvents(ScrStr: String);

    procedure ClearNotAllowedOperations;
    procedure ExcludeNotAllowedOperation(Operation: TNotAllowedOperation);
    procedure AddNotAllowedOperation(Operation: TNotAllowedOperation);
    function FindNotAllowedOperation(Operation: TNotAllowedOperation): Boolean;

    function GetFieldSetting(var List: TList<TGridFieldSetting>; FieldName: String): TGridFieldSetting;

    function CalculateSeed: String;
    function GetGridSeed: String;

    procedure Structure(Sender: TObject);
    function IsGridColumnExists(FieldName: String): Boolean;

    procedure AddPopupItem(Caption: String; Action: TPopupMenuAction; AChortCutKey: String; PictType: TPicturesTypes);
    procedure AddPopupSeparator;
    procedure OnPopupMenuClick(Sender: TObject);

    procedure Undo;
    procedure PCopy;
    procedure Cut;
    procedure Paste;
  public
    constructor Create(NameSpace: String; Forms: TList<TForm>; Form: TForm; ParentControl: TWinControl; Variables: TVariables; SurfType: TDataControlType;
      DBConnector: TDCLDBConnector; Query: TDCLQuery; Data: TDataSource); overload;
    destructor Destroy; override;

    procedure AddField(Field: TDCLField);

    procedure Open;
    procedure Close;
    procedure CloseComponent;
    procedure ReFreshData;

    procedure ExecScriptLine(ScrStr: String);
    procedure Prepeare;

    procedure SetSQL(SQL: String);
    procedure SetNavigatorButtonsSet(ButtonsExpr: String);

    procedure AddButton(Button: TDCLCommandButton);

    procedure AddEvent(EventType: TEventsEnum; ScriptName: String);

    function CheckEdits: Boolean;
    procedure NotifyEditFieldError(Field: TDCLField);

    procedure GetDBGridFieldsPos(var Settings: TStringList);
    function LoadDBGridFieldsPos: TList<TGridFieldSetting>;

    procedure ResetFieldsSettings;

    property Query: TDCLQuery read FQuery;
    property Data: TDataSource read FData;
    property Edits: TList<TDCLEdit> read GetEdits;
    property FieldsCount: Integer read GetFieldsCount;
    property TableParts: TList<TDCLGrid> read FTableParts;
    property CurrentTablePart: TDCLGrid read FCurrentTablePart;
    property Style: TGridStyle read FGridStyle write FGridStyle;
    property ReadOnly: Boolean read FReadOnly write FReadOnly;
    property DependField: String read FDependField write FDependField;
    property MasterDataField: String read FMasterDataField write FMasterDataField;
    property MasterValueVariableName: String read FMasterValueVariableName write FMasterValueVariableName;
    property NoDataField: Boolean read FNoDataField write FNoDataField;
    property MultiSelect: Boolean read FMultiSelectMode write SetMultiSelect;
    property RightsLevel: TUserLevelsType read FUserLevel;
    property Seed: String read GetGridSeed;
  end;

  { TLookupTable }

  TLookupTable=class(TPanel)
  private
    FGrid: TDCLGrid;
  public
    constructor Create(NameSpace: String; Forms: TList<TForm>; Form: TForm; Parent: TWinControl; Variables: TVariables;
      DBConnector: TDCLDBConnector; Query: TDCLQuery; Data: TDataSource); overload;

    property DCLGrid: TDCLGrid read FGrid;
  end;

implementation

uses
  EditBtn,
  {$IFDEF MSWINDOWS}
  Windows,
  {$ENDIF}
  {$IFDEF FPC}
  LCLProc, lcltype,
  {$ENDIF}
  uDCLCommand, uDCLValuesParser, uSQLParser, uDCLUtils, uSystemUtils, uDCLForm,
  uPrintBase, uDCLGlobalVariables, uDCLMD5;

{ TLookupTable }

constructor TLookupTable.Create(NameSpace: String; Forms: TList<TForm>;
  Form: TForm; Parent: TWinControl; Variables: TVariables;
  DBConnector: TDCLDBConnector; Query: TDCLQuery; Data: TDataSource);
begin
  inherited Create(Parent);
  Self.Parent:=Parent;

  FGrid:=TDCLGrid.Create(NameSpace, Forms, Form, Self, Variables, dctLookupGrid,
    DBConnector, Query, Data);
end;

{ TDCLGrid }

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

procedure TDCLGrid.CreateImageList;
begin
  FPicturesIndexes:=TDictionary<TPicturesTypes, Integer>.Create;

  FImages:=TImageList.Create(Self);

  FPicturesIndexes.Add(ptFind, FImages.Add(DrawBMPButton(ptFind), nil));
  FPicturesIndexes.Add(ptStructure, FImages.Add(DrawBMPButton(ptStructure), nil));
  FPicturesIndexes.Add(ptPrint, FImages.Add(DrawBMPButton(ptPrint), nil));

  FPicturesIndexes.Add(ptDownArrow, FImages.Add(DrawBMPButton(ptDownArrow), nil));
  FPicturesIndexes.Add(ptUpArrow, FImages.Add(DrawBMPButton(ptUpArrow), nil));
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
      ShowErrorMessage( - 1100, 'SQL='+QText);
    end;
  end;
end;

procedure TDCLGrid.TranslateVal(var Params: String; CheckParams: Boolean);
var
  Factor: Integer;
  Parser: TDCLValuseParser;
begin
  Parser:=TDCLValuseParser.Create(FNameSpace, FVariables);
  Parser.RePlaseVariables(FNameSpace, Params, FQuery);
  if CheckParams then
    Parser.RePlaseParams(Params, FQuery);
  Factor:=0;
  Parser.RePlaceProc(Params, Factor, FQuery);
end;

procedure TDCLGrid.SetQueryEvents(Query: TDCLQuery);
begin
  Query.AfterInsert:=AfterInsert;
  Query.AfterScroll:=ScrollDB;
  Query.AfterEdit:=AfterEdit;
  Query.AfterPost:=AfterPost;
  Query.AfterCancel:=AfterCancel;
  Query.AfterDelete:=OnDelete;

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
    (FForm as TDCLForm).SetDBStatus(GetDCLMessageString(msModified));
    //BaseChanged:=True;
  end;
  if Status=dssSaved then
  begin
    (FForm as TDCLForm).SetDBStatus('');
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
          If FieldExists(Edit.FieldName, FQuery) Then
            (Edit.DCLEditComponent.Control as TEdit).Text:=TrimRight(FQuery.FieldByName(Edit.FieldName).AsString);
        end;
      end;

      if Edit.DCLEditComponent.Control is TCheckBox then
      begin
        If (not Edit.NoDataField) and FieldExists(Edit.FieldName, FQuery) Then
        begin
          S:=TrimRight(FQuery.FieldByName(Edit.FieldName).AsString);
          If (S='0') or (S='') Then
            (Edit.DCLEditComponent.Control as TCheckBox).Checked:=False;
          If S='1' Then
            (Edit.DCLEditComponent.Control as TCheckBox).Checked:=True;
        end;
      end;

      if Edit.DCLEditComponent.Control is DateTimePicker then
      If (not Edit.NoDataField) and FieldExists(Edit.FieldName, FQuery) then
      begin
        (Edit.DCLEditComponent.Control as DateTimePicker).Date:=FQuery.FieldByName(Edit.FieldName).AsDateTime;
      end;

      if Edit.DCLEditComponent.Control is TComboBox then
        If (not Edit.NoDataField) and FieldExists(Edit.FieldName, FQuery) Then
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
  If FUserLevel<ulWrite Then
    Data.Cancel
  Else
  begin
    If FDependField<>'' Then
    Begin
      if not FNoDataField then
      begin
        If FMasterDataField<>'' Then
        begin
          Data.FieldByName(FDependField).AsString:=FQuery.FieldByName
            (FMasterDataField).AsString;
        end;
      end
      else
      begin
        if MasterValueVariableName<>'' then
        begin
          Data.FieldByName(DependField).AsString:=FVariables.Variables[FNamespace, FMasterValueVariableName];
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
  if Assigned(FQuery) and FQuery.Active then
    (FForm as TDCLForm).SetRecordsStatus(FQuery.RecNo, FQuery.RecordCount);

  UpdateAllControls;
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
  If FUserLevel<ulWrite Then
    Data.Cancel;

  UpdateAllControls;
end;

procedure TDCLGrid.AfterPost(Data: TDataSet);
begin
  ExecEvents(evtAfterPost);
  ReFreshData;
  FormsNotifier.NotifyForms(fnaRefresh);
  UpdateAllControls;
  SetDataStatus(dssSaved);
end;

procedure TDCLGrid.AfterCancel(Data: TDataSet);
begin
  SetDataStatus(dssSaved);
  ExecEvents(evtCancel);
end;

procedure TDCLGrid.BeforeScroll(Data: TDataSet);
begin

end;

procedure TDCLGrid.BeforeEdit(Data: TDataSet);
begin

end;

procedure TDCLGrid.BeforePost(Data: TDataSet);
begin

end;

procedure TDCLGrid.OnDelete(Data: TDataSet);
begin
  ExecEvents(evtDelete);
  UpdateAllControls;
end;

procedure TDCLGrid.Find(Sender: TObject);
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
      FindGrid.DefaultRowHeight:=17;
      FindGrid.DefaultColWidth:=IndicatorWidth;
      FindGrid.OnSelectCell:=FindGridOnSelectCell;

      FindGrid.FixedCols:=1;
      if Assigned(FDBGrid) then
      begin
        StrIndex:=0;
        FindGrid.RowCount:=1;
        FindGrid.FixedRows:=0;
        FindGrid.Height:=45;
      end
      else
      begin
        StrIndex:=1;
        FindGrid.RowCount:=2;
        FindGrid.FixedRows:=1;
        FindGrid.Height:=65;
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
  else
  begin
    FindProcess:=False;
    FindGrid.Hide;

    OpenQuery(QueryBuilder);
  end;
end;

procedure TDCLGrid.FindGridOnSelectCell(Sender: TObject; aCol, aRow: Integer;
  var CanSelect: Boolean);
begin
  If Assigned(FDBGrid) then
    FDBGrid.SelectedIndex:=aCol-1;
end;

procedure TDCLGrid.Print(Sender: TObject);
var
  Print: TPrintBase;
begin
  Print:=TPrintBase.Create(FQuery);
  Print.Print(FDBGrid, FForm.Caption);
  Print.Save(AppConfigDir+'table.tmp');
end;

procedure TDCLGrid.ExecEvents(EventType: TEventsEnum);
var
  Event: TDCLEvent;
  CommandObj: TDCLCommand;
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
    CommandObj:=TDCLCommand.Create(FDBConnector, FNameSpace, FForms, FForm, Self, FVariables);
    for Event in FEvents do
    begin
      if Event.EventType=EventType then
      begin
        IsExist:=CommandObj.RunCommandScript(Event.ScriptName);
        if not IsExist then
        begin
          CommandObj.RunCommand(Event.ScriptName);
          FreeAndNil(CommandObj);
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
  i: Integer;

  function GetField(FieldName: String): TSortField;
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

  procedure RemoveField(FieldName: String);
  begin
    FOrdersFields.Remove(GetField(FieldName));
  end;

  function ContainsField(FieldName: String): Boolean;
  begin
    Result:=Assigned(GetField(FieldName));
  end;

  procedure TurnOrder(var Column: TColumn);
  var
    SortOrder: TSortOrder;
    FF: TSortField;
  begin
    FF:=GetField(Column.FieldName);
    if Assigned(FF) then
    begin
      SortOrder:=FF.Order;
      if SortOrder=soDesc then
      begin
        Column.Title.ImageIndex:=FPicturesIndexes[ptUpArrow];
        FF.Order:=soAsc;
      end
      else
      begin
        Column.Title.ImageIndex:=FPicturesIndexes[ptDownArrow];
        FF.Order:=soDesc;
      end;
    end;
  end;

  procedure AddField(var Column: TColumn);
  var
    FF: TSortField;
  begin
    FF:=GetField(Column.FieldName);
    if not Assigned(FF) then
    begin
      Column.Title.ImageIndex:=FPicturesIndexes[ptUpArrow];

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
      Column.Title.ImageIndex:=-1;
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
          for i:=0 to FDBGrid.Columns.Count-1 do
          begin
            FDBGrid.Columns[i].Title.ImageIndex:=-1;
          end;

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
    Result:=Parser.ExcludeOrderBy(SQL);
  end;
end;

procedure TDCLGrid.ReDrawColumns;
var
  Column: TColumn;
  i: Integer;

  function ContainsField(FieldName: String): Boolean;
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

    FCurrentField.Caption:=FieldNameCapt;
    if FindParam('Width=', ScrLine)<>'' then
      FCurrentField.Width:=StrToIntEx(FindParam('Width=', ScrLine));

    If FindParam('Height=', ScrLine)<>'' Then
    begin
      FCurrentField.Height:=StrToIntEx(FindParam('Height=', ScrLine));
    end;

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

    If PosEx('As_Logic;', ScrLine)<>0 Then
    begin
      FCurrentField.FType:=ftBoolean;
      TmpStr:=Trim(FindParam('ValueChecked=', ScrLine));
      If TmpStr<>'' Then
        FCurrentField.CheckValue:=TmpStr;
      TmpStr:=Trim(FindParam('ValueUnChecked=', ScrLine));
      If TmpStr<>'' Then
        FCurrentField.UnCheckValue:=TmpStr;
    end;

    If PosEx('As_Graphic;', ScrLine)<>0 Then
    begin
      FCurrentField.FType:=ftGraphic;
    end;

    If PosEx('As_Date;', ScrLine)<>0 Then
    begin
      FCurrentField.FType:=ftDate;
    end;

    If PosEx('As_Memo;', ScrLine)<>0 Then
    begin
      FCurrentField.FType:=ftMemo;
    end;

    If PosEx('As_RichText;', ScrLine)<>0 Then
    begin
      FCurrentField.DataFieldType:=dftRichText;
      FCurrentField.FType:=ftFmtMemo;
    end;

    If PosEx('As_Float;', ScrLine)<>0 Then
    begin
      FCurrentField.FType:=ftFloat;
    end;

    FCurrentField.FirstFieldsLine:=S;
    if FGridStyle in TDataGrid then
    begin

    end;
  end;

  fpmField:begin
    p:=Pos(';', ScrLine);
    if p=0 then
      p:=Pos('\', ScrLine);
    if p=0 then
      FieldNameCapt:=ScrLine
    else
      FieldNameCapt:=LeftStr(ScrLine, p-1);

    FCurrentField.FieldName:=FieldNameCapt;

    If FieldExists(FCurrentField.FieldName, Query) Then
      FCurrentField.FType:=Query.FieldByName(FCurrentField.FieldName).DataType
    Else
      FCurrentField.FType:=ftString;

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

    FDCLFields.Add(FCurrentField);
  end;
  end;

  if FFieldParsingMode=fpmCaption then
    FFieldParsingMode:=fpmField
  else
    if FFieldParsingMode=fpmField then
      FFieldParsingMode:=fpmCaption;
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

procedure TDCLGrid.OnResizeButtonFlowPanel(Sender: TObject);
begin
end;

procedure TDCLGrid.AddDropBox(Field: TDCLField; Scr: String);
var
  ShadowQuery: TDCLDialogQuery;
  TmpStr, tmpStr1, tmpSQL1: String;
  DropList: TComboBox;
  v1, v2: Integer;
begin
  If FQuery.Active and (FGridStyle in TDataGrid) Then
  begin
    TmpStr:=FindParam('List=', Scr);
    {If TmpStr<>'' Then
    begin
      //Show;
      v2:=ParamsCount(TmpStr);
      For v1:=1 to v2 do
      begin
        tmpStr1:=SortParams(TmpStr, v1);
        If tmpStr1='' Then
          tmpStr1:='';
        FGrid.Columns[FGrid.Columns.Count-1].PickList.Append(tmpStr1);
      end;
    end;

    tmpSQL1:=FindParam('SQL=', Scr);
    If tmpSQL1<>'' Then
    begin
      ShadowQuery:=TDCLDialogQuery.Create(nil);
      ShadowQuery.Name:='GroupBoxQ_'+IntToStr(UpTime);
      FDCLLogOn.SetDBName(ShadowQuery);

      TranslateVal(tmpSQL1);
      ShadowQuery.SQL.Text:=tmpSQL1;
      try
        ShadowQuery.Open;

        While Not ShadowQuery.Eof do
        begin
          If Trim(ShadowQuery.Fields[0].AsString)<>'' Then
            FGrid.Columns[FGrid.Columns.Count-1].PickList.Append
              (Trim(ShadowQuery.Fields[0].AsString))
          Else
            FGrid.Columns[FGrid.Columns.Count-1].PickList.Append(' ');
          ShadowQuery.Next;
        end;
        ShadowQuery.Close;
        FreeAndNil(ShadowQuery);
      Except
        ShowErrorMessage( - 1107, 'SQL='+tmpSQL1);
      end;
    end; }
  end;

  If FGridStyle in TDataFields Then
  begin
    DropList:=TComboBox.Create(FFieldsPanel);
    DropList.Parent:=FFieldsPanel;

    DropList.OnSelect:=DropListOnSelectItem;

    DropList.Clear;

    If FindParam('VariableName=', Scr)<>'' Then
    begin
      tmpStr1:=FindParam('VariableName=', Scr);
      Field.Variable:=tmpStr1;
      FVariables.NewVariableWithTest(FNamespace, tmpStr1);
    end;

    tmpSQL1:=FindParam('SQL=', Scr);
    If tmpSQL1<>'' Then
    begin
      ShadowQuery:=TDCLDialogQuery.Create(nil);
      ShadowQuery.Name:='DropBoxQ_'+IntToStr(UpTime);
      FDBConnector.SetConnector(ShadowQuery);

      ShadowQuery.SQL.Text:=tmpSQL1;
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
        ShowErrorMessage( - 1107, 'SQL='+tmpSQL1);
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

    If FQuery.Active Then
    begin
      If FindParam('SetIndexValue=', Scr)='1' Then
      begin
        DropList.ItemIndex:=FQuery.FieldByName(Field.FieldName).AsInteger;
      end;
    end
    Else
      DropList.ItemIndex:=StrToIntEx(FindParam('SetIndexValue=', Scr));

    Field.DCLEditComponent:=TDCLEdit.Create;
    Field.DCLEditComponent.Control:=DropList;
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

    If FQuery.Active Then
    begin
      if FieldExists(Field.FieldName, FQuery) then
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
          If not DCLCompareString(FQuery.FieldByName(Field.FieldName).AsString, ItemName) and FQuery.CanModify Then
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
        FVariables.Variables[FNamespace, Field.Variable]:=IntToStr(ItemIndex)
      else
        FVariables.Variables[FNamespace, Field.Variable]:=ItemName;
  end;
end;

procedure TDCLGrid.AddDBDateEdit(Field: TDCLField);
var
  DateEdit: TDBDateEdit;
begin
  Field.DCLEditComponent:=TDCLEdit.Create;

  DateEdit:=TDBDateEdit.Create(FFieldsPanel);
  DateEdit.Parent:=FFieldsPanel;
  if Field.Width>0 then
    DateEdit.Width:=Field.Width;
  DateEdit.DataSource:=FData;
  DateEdit.DataField:=Field.FieldName;
  DateEdit.ReadOnly:=Field.ReadOnly;
  DateEdit.Hint:=Field.Hint;
  if Field.Hint<>'' then
    DateEdit.ShowHint:=True;

  Field.DCLEditComponent.Control:=DateEdit;
end;

procedure TDCLGrid.AddMediaFieldGroup(Field: TDCLField; GroupType: TGroupType);
var
  MediaField: TMediaFieldGroup;
begin
  MediaField:=TMediaFieldGroup.Create(FFieldsPanel, FData, Field, GroupType);

  Field.DCLEditComponent:=TDCLEdit.Create;
  Field.DCLEditComponent.Control:=MediaField;
end;

procedure TDCLGrid.AddDBEdit(Field: TDCLField);
begin
  if FieldExist(FQuery, Field.FieldName) then
  begin
    Field.DCLEditComponent:=TDCLEdit.Create;

    Field.DCLEditComponent.Control:=TDBEdit.Create(FFieldsPanel);
    Field.DCLEditComponent.Control.Parent:=FFieldsPanel;
    if Field.Width>0 then
      Field.DCLEditComponent.Control.Width:=Field.Width;
    (Field.DCLEditComponent.Control as TDBEdit).DataField:=Field.FieldName;
    (Field.DCLEditComponent.Control as TDBEdit).DataSource:=FData;
    (Field.DCLEditComponent.Control as TDBEdit).Hint:=Field.Hint;
    if Field.Hint<>'' then
      (Field.DCLEditComponent.Control as TDBEdit).ShowHint:=True;
    (Field.DCLEditComponent.Control as TDBEdit).CharCase:=Field.CharCase;
    (Field.DCLEditComponent.Control as TDBEdit).PasswordChar:=Field.PasswordChar;
    (Field.DCLEditComponent.Control as TDBEdit).OnClick:=DBEditClick;
    If Field.PasswordChar<>#0 Then
      Field.DCLEditComponent.Control.Tag:=1;

    (Field.DCLEditComponent.Control as TDBEdit).ReadOnly:=Field.ReadOnly;
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
  FQuery:=TDCLQuery.Create(Self);
  FDBConnector.SetConnector(FQuery);
  SetQueryEvents(FQuery);

  FData.DataSet:=FQuery;
  if Assigned(Data) then
    FQuery.DataSource:=Data;
end;

procedure TDCLGrid.ClickCommandButton(Sender: TObject);
var
  CommandObj: TDCLCommand;
  DCLCommand, c: TDCLCommandButton;
  guid: TGUID;
  ns: String;
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
    if DCLCommand.ChoiceButton then
    begin
      Choose;
      FForm.ModalResult:=mrOk;
    end
    else if DCLCommand.ForEach then
    begin
      if (FGridStyle in TDataGrid) and FMultiSelectMode then
      begin
        for Bookmark in FDBGrid.SelectedRows do
        begin
          FQuery.GoToBookmark(TBookmark(Bookmark));

          ns:=FNameSpace;
          if DCLCommand.Host then
          begin
            CreateGUID(guid);
            ns:=GUIDToString(guid);
          end;

          CommandObj:=TDCLCommand.Create(FDBConnector, ns, FForms, FForm, Self, FVariables);
          CommandObj.SelectRunType(DCLCommand.Command);
        end;
      end;
    end
    else
    begin
      ns:=FNameSpace;
      if DCLCommand.Host then
      begin
        CreateGUID(guid);
        ns:=GUIDToString(guid);
      end;

      CommandObj:=TDCLCommand.Create(FDBConnector, ns, FForms, FForm, Self, FVariables);
      CommandObj.SelectRunType(DCLCommand.Command);
    end;
  end;
end;

function TDCLGrid.AddTablePart(Title: String; Data: TDataSource; Style: TGridStyle): TDCLGrid;
var
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
  end;

  pc:=FTablePartsPages.PageCount;
  FTablePartsTabs:=TTabSheet.Create(FTablePartsPages);
  FTablePartsTabs.Parent:=FTablePartsPages;
  FTablePartsTabs.Name:='TablePart_'+IntToStr(pc+1);
  FTablePartsTabs.PageControl:=FTablePartsPages;

  If Title='' Then
    FTablePartsTabs.Caption:=GetDCLMessageString(msPage)+' '+IntToStr(pc+1)
  Else
    FTablePartsTabs.Caption:=InitCap(Title);

  grid:=TDCLGrid.Create(FNameSpace, FForms, FForm, FTablePartsTabs, FVariables, dctTablePart, FDBConnector, nil, Data);
  FCurrentTablePart:=grid;
  grid.Style:=Style;
  FTableParts.Add(grid);
  Result:=grid;
end;

procedure TDCLGrid.ChangePartTabPage(Sender: TObject);
var
  i: Integer;
  tab: TTabSheet;
  c: TControl;
begin
  tab:=(Sender as TPageControl).ActivePage;
  if Assigned(tab) then
  begin
    if tab.ControlCount>0 then
    begin
      for i:=0 to tab.ControlCount-1 do
      begin
        c:=tab.Controls[i];
        if c is TDCLGrid then
        begin
          FCurrentTablePart:=c as TDCLGrid;
          break;
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

  Field.ContextButtons.Add(ContextButton);
end;

procedure TDCLGrid.ContextFieldButtonsClick(Sender: TObject);
var
  f: TDCLField;
  b, Button: TContextFieldButton;
  flg: Boolean;
  Command: TDCLCommand;
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
    Command:=TDCLCommand.Create(FDBConnector, FNameSpace, FForms, FForm, Self, FVariables);
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

  If FindParam('ComponentName=', Scr)<>'' Then
    Edit.Name:=FindParam('ComponentName=', Scr);

  If Field.Hint<>'' Then
  begin
    Edit.ShowHint:=True;
    Edit.Hint:=Field.Hint;
  end;

  Edit.PasswordChar:=Field.PasswordChar;

  Edit.CharCase:=Field.CharCase;

  Edit.ReadOnly:=Field.ReadOnly;
  Edit.OnClick:=FieldBoxOnClick;

  If Field.Width>0 Then
    Edit.Width:=Field.Width
  Else
    Edit.Width:=EditWidth;

  If FieldBoxType<>fbtOutBox Then
  begin
    S:=FindParam('Format=', Scr);
    if S<>'' then
    begin
      Edit.OnKeyPress:=FieldBoxKeyPress;
      If LowerCase(S)='float' Then
      begin
        Field.FieldTypeFormat:=fftFloat;
      end;
      if LowerCase(S)='digit' then
      begin
        Field.FieldTypeFormat:=fftDigit;
      end;
      if LowerCase(S)='trim' then
      begin
        Field.FieldTypeFormat:=fftTrim;
      end;
    end;
  end
  Else
    Edit.ReadOnly:=True;

  Field.DCLEditComponent.EditType:=FieldBoxType;
  If FindParam('Disabled=', Scr)='1' Then
    Edit.Enabled:=False;
  Edit.Text:='';
  Edit.OnChange:=FieldBoxOnEdit;

  S:=FindParam('MaxLength=', Scr);
  If S<>'' Then
    Edit.MaxLength:=StrToIntEx(Trim(S));

  NeedValue:=0;
  If PosEx('_Value=', Scr)<>0 Then
  Begin
    If FindParam('_Value=', Scr)<>'' Then
      NeedValue:=1
    Else
    Begin
      NeedValue:=3;
    End;
  End;

  Field.RequireValue:=FindParam('RequirValue=', Scr)='1';

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
        If FieldExists(Field.FieldName, FQuery) Then
          if FQuery.FieldByName(Field.FieldName).IsNull then
            NeedValue:=4;
      End;
      If FindParam('_ValueIfNotNull=', Scr)<>'' Then
      Begin
        If FieldExists(Field.FieldName, FQuery) Then
          if not FQuery.FieldByName(Field.FieldName).IsNull then
            NeedValue:=5;
      End;
    End;
  end;

  If FindParam('SQL=', Scr)<>'' Then
    NeedValue:=2;

  S:='';
  Case NeedValue of
  0:
  if not Field.NoDataField then
  If FQuery.Active Then
    If FieldExists(Field.FieldName, FQuery) Then
      S:=TrimRight(FQuery.FieldByName(Field.FieldName).AsString);
  1:
  begin
    S:=FindParam('_Value=', Scr);
  end;
  6:
  begin
    S:=FindParam('_ValueIfEmpty=', Scr);
  end;
  2:
  begin
    ShadowQuery:=TDCLDialogQuery.Create(Self);
    FDBConnector.SetConnector(ShadowQuery);
    S:=FindParam('SQL=', Scr);
    ShadowQuery.SQL.Text:=S;
    ShadowQuery.Open;
    If FindParam('ReturnField=', Scr)<>'' Then
      FieldName:=FindParam('ReturnField=', Scr)
    Else
      FieldName:=ShadowQuery.Fields[0].FieldName;
    DeleteNonPrintSimb(FieldName);
    If FieldExists(FieldName, ShadowQuery) Then
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

  If FindParam('VariableName=', Scr)<>'' Then
  begin
    FieldName:=FindParam('VariableName=', Scr);

    FVariables.NewVariableWithTest(FNamespace, FieldName);

    Field.Variable:=FieldName;
    FVariables.Variables[FNamespace, FieldName]:=S;
  end;
  Edit.Text:=S;

  Field.DCLEditComponent.Control:=Edit;
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
      FVariables.Variables[FNamespace, Field.Variable]:=EdText;
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
  TempStr:=FindParam('SQL=', Scr);
  If TempStr<>'' Then
  begin
    Field.LookupData.LookupQuery:=TDCLDialogQuery.Create(Self);
    FDBConnector.SetConnector(Field.LookupData.LookupQuery);
    TranslateVal(TempStr, False);
    Field.LookupData.LookupQuery.SQL.Text:=TempStr;
    try
      Field.LookupData.LookupQuery.Open;
      Field.LookupData.LookupQuery.Last;
      Field.LookupData.LookupQuery.First;
    Except
      ShowErrorMessage( - 1115, 'SQL='+TempStr);
    end;
    Field.LookupData.LookupData:=TDataSource.Create(Self);
    Field.LookupData.LookupData.DataSet:=Field.LookupData.LookupQuery;
  end
  Else
  begin
    ShowErrorMessage( - 3000, '');
  end;

  DBLookupControl:=TDBLookupComboBox.Create(FFieldsPanel);
  DBLookupControl.Parent:=FFieldsPanel;
  DBLookupControl.DropDownRows:=20;

  DBLookupControl.ShowHint:=True;
  DBLookupControl.Hint:=Field.Hint;

  If FQuery.Active Then
  begin
    If not Field.NoDataField Then
    begin
      If FieldExists(Field.FieldName, FQuery) Then
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
  DBLookupControl.ListSource:=Field.LookupData.LookupData;
  If Field.Width>0 Then
    DBLookupControl.Width:=Field.Width
  Else
    DBLookupControl.Width:=EditWidth;

  Field.Height:=DBLookupControl.Height;

  TempStr:=FindParam('VariableName=', Scr);
  If TempStr<>'' Then
  begin
    FVariables.NewVariableWithTest(FNamespace, TempStr);
    Field.LookupData.LookupToVar:=TempStr;
  end;

  DBLookupControl.KeyField:=FindParam('Key=', Scr);
  DBLookupControl.ListField:=FindParam('List=', Scr);

  TempStr:=FindParam('ModifyingEdit=', Scr);
  If TempStr<>'' Then
    Field.LookupData.ModifyEdit:=GetParam(TempStr, 1);

  TempStr:=FindParam('KeyValue=', Scr);

  If (NoDataField) Then
    Field.LookupData.LookupQuery.First;
  If TempStr<>'' Then
  begin
    TranslateVal(TempStr, False);
    //If (Not FForm.Showing) and (Not NoDataField) Then
      //FForm.Show;
    DBLookupControl.KeyValue:=TempStr;
    If (Not NoDataField) and Query.CanModify Then
    begin
      If (Not (FQuery.State in dsEditModes))and FQuery.Active and(Not NoDataField) Then
        Query.Edit;
      FData.DataSet.FieldByName(Field.FieldName).AsInteger:=StrToIntEx(TempStr);
    end;
  end;
  //LookupOnClick(DBLookupControl);

  Field.LookupData.LookupQuery.AfterScroll:=LookupDBScroll;

  {$IFDEF FPC}
  DBLookupControl.OnSelect:=LookupOnClick;
  {$ELSE}
  DBLookupControl.OnClick:=LookupOnClick;
  {$ENDIF}
  Field.DCLEditComponent:=TDCLEdit.Create;
  Field.DCLEditComponent.Control:=DBLookupControl;
end;

procedure TDCLGrid.LookupOnClick(Sender: TObject);
var
  KeyFiled, ListField, tmpSQL1: String;
  f, DCLLookup, ModifyEdit: TDCLField;
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
    If DCLLookup.LookupData.ModifyEdit<>'' Then
    begin
      ListField:=(Sender as TDBLookupComboBox).ListField;

      tmpSQL1:=TrimRight(DCLLookup.LookupData.LookupQuery.FieldByName(ListField).AsString);

      ModifyEdit:=nil;
      for f in FDCLFields do
      begin
        if Assigned(f.DCLEditComponent) and (f.DCLEditComponent.Control=(Sender as TEdit)) and
          DCLCompareString(f.DCLEditComponent.Control.Name, DCLLookup.LookupData.ModifyEdit) then
        begin
          ModifyEdit:=f;
          break;
        end;
      end;

      (ModifyEdit.DCLEditComponent.Control as TEdit).Text:=tmpSQL1;
    end;

    if DCLLookup.LookupData.LookupToVar<>'' then
    begin
      KeyFiled:=(Sender as TDBLookupComboBox).KeyField;

      FVariables.Variables[FNamespace, DCLLookup.LookupData.LookupToVar]:=
        TrimRight(DCLLookup.LookupData.LookupQuery.FieldByName(KeyFiled).AsString);
    end;
  end;
end;

procedure TDCLGrid.LookupDBScroll(Data: TDataSet);
var
  Look: TDBLookupComboBox;
  l, DCLLookup: TDCLField;
begin
  DCLLookup:=nil;
  for l in FDCLFields do
  begin
    if Assigned(l.LookupData) and (l.LookupData.LookupQuery=Data) then
    begin
      DCLLookup:=l;
      break;
    end;
  end;

  if Assigned(DCLLookup) then
  begin
    Look:=DCLLookup.DCLEditComponent.Control as TDBLookupComboBox;
    if not DCLLookup.NoDataField then
    begin
      FVariables.Variables[FNamespace, DCLLookup.Variable]:=
        TrimRight(DCLLookup.LookupData.LookupQuery.FieldByName(Look.KeyField).AsString);
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
  Inc(FTop, Filter.FilterLabel.Height+LabelTopInterval);

  case Filter.FilterType of
    ftNone: begin
      //
    end;
    ftDBFilter: begin
      Filter.CaseC:=False;
      Filter.NotLike:=True;
      Filter.FilterString:='';

      Filter.FilterQuery:=TDCLDialogQuery.Create(nil);
      FDBConnector.SetConnector(Filter.FilterQuery);
      Filter.FilterData:=TDataSource.Create(nil);
      Filter.FilterData.DataSet:=Filter.FilterQuery;
      Filter.FilterQuery.SQL.Text:=Filter.SQL;

      try
        Filter.FilterQuery.Open;
        Filter.FilterQuery.Last;
        Filter.FilterQuery.First;
      Except
        ShowErrorMessage( - 1116, 'SQL='+Filter.SQL);
      end;

      Filter.Control:=TDBLookupComboBox.Create(FFiltersPanel);
      Filter.Control.Parent:=FFiltersPanel;
      Filter.Control.Top:=FTop;
      Inc(FTop, Filter.Control.Height+CompenentTopStep);

      Filter.Control.Left:=FFilterLeft;
      (Filter.Control as TDBLookupComboBox).ListField:=Filter.ListField;
      (Filter.Control as TDBLookupComboBox).KeyField:=Filter.KeyField;

      If Filter.VarName<>'' Then
        FVariables.Variables[FNamespace, Filter.VarName]:=
          TrimRight(Filter.FilterQuery.FieldByName((Filter.Control as TDBLookupComboBox).KeyField).AsString);

      (Filter.Control as TDBLookupComboBox).ListSource:=Filter.FilterData;
      Filter.FilterKey:=(Filter.Control as TDBLookupComboBox).KeyField;
      (Filter.Control as TDBLookupComboBox).ListField:=Filter.ListField+';'+Filter.KeyField;

      Filter.Control.Width:=Filter.Width;

  {$IFDEF FPC}
      (Filter.Control as TDBLookupComboBox).OnSelect:=ExecFilter;
  {$ELSE}
      (Filter.Control as TDBLookupComboBox).OnClick:=ExecFilter;
  {$ENDIF}

      If Filter.KeyValue<>'' Then
      begin
        try
          (Filter.Control as TDBLookupComboBox).KeyValue:=Filter.KeyValue;
          ExecFilter((Filter.Control as TDBLookupComboBox));
        Except
          //
        end;
      end
      Else
      begin
        try
          (Filter.Control as TDBLookupComboBox).KeyValue:='-1';
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
        Filter.Control.Parent:=FFiltersPanel;
        Filter.Control.Left:=FFilterLeft;
        Filter.Control.Top:=FTop;
        Inc(FTop, Filter.Control.Height+CompenentTopStep);

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
    Filter.NotCheck.Width:=Filter.Width;
    Filter.NotCheck.Caption:=GetDCLMessageString(msNotFilter);
    Filter.NotCheck.OnClick:=OnFilterNotCheckClick;
    Inc(FTop, Filter.NotCheck.Height+CompenentTopStep);
  end;

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
  Inc(FTop, Calendar.LabelField.Height+LabelTopInterval);

  Calendar.Control:=DateTimePicker.Create(FFiltersPanel);
  Calendar.Control.Parent:=FFiltersPanel;
  Calendar.Control.DateOrder:=doDMY;
  Calendar.Control.DateFormat:=GPT.DateFormat;

  Calendar.Control.Top:=FTop;
  Inc(FTop, Calendar.Control.Height+CompenentTopStep);
  Calendar.Control.Left:=FFilterLeft;

  Calendar.Control.Date:=Calendar.Value;
  If Calendar.Variable<>'' Then
    FVariables.NewVariable(FNamespace, Calendar.Variable, DateToStr(Calendar.Control.Date));

  Calendar.Control.OnChange:=CalendarOnChange;
  Inc(FFilterLeft, FieldsStepLeft+Calendar.Control.Width);
  AdjustFilterPanel(Ftop);

  FCalendars.Add(Calendar);
end;

procedure TDCLGrid.CalendarOnChange(Sender: TObject);
var
  c, Calendar: TDCLCalendar;
  EdDate: String;
begin
  Calendar:=nil;
  for c in FCalendars do
  begin
    if c.Control=(Sender as DateTimePicker) then
    begin
      Calendar:=c;
      break;
    end;
  end;

  if Assigned(Calendar) then
  begin
    EdDate:=DateToStr((Sender as DateTimePicker).Date);
    FVariables.Variables[FNamespace, Calendar.Variable]:=EdDate;

    If Calendar.ReOpen Then
    begin
      OpenQuery(QueryBuilder);
    end;
  end;
end;

procedure TDCLGrid.AddCheckBox(Field: TDCLField; Scr: String);
begin
  If (not Field.NoDataField) and FQuery.Active and FieldExists(Field.FieldName, FQuery) Then
    AddDBCheckBox(Field, Scr)
  Else
    AddSimplyCheckBox(Field, Scr);
end;

procedure TDCLGrid.AddSimplyCheckBox(Field: TDCLField; Scr: String);
var
  Value1: String;
  State: Boolean;
  CheckBox: TCheckBox;
begin
  CheckBox:=TCheckbox.Create(FFieldsPanel);
  CheckBox.Parent:=FFieldsPanel;

  CheckBox.Caption:='';

  If Field.Hint<>'' Then
  begin
    CheckBox.ShowHint:=True;
    CheckBox.Hint:=Field.Hint;
  end;

  State:=False;
  If Field.Variable<>'' Then
  begin
    FVariables.NewVariableWithTest(FNamespace, Field.Variable);
  end
  Else
  begin
    FVariables.NewVariableWithTest(FNamespace, 'CheckBox_'+Field.FieldName);
    Field.Variable:='CheckBox_'+Field.FieldName;
  end;

  Value1:=FindParam('_Value=', Scr);
  if Value1<>'' then
  begin
    state:=Value1='1';
  end;

  CheckBox.Checked:=state;

  If PosEx('_OnCheck;', Scr)<>0 Then
    CheckBox.Checked:=True;
  If PosEx('_OffCheck;', Scr)<>0 Then
    CheckBox.Checked:=False;

  CheckBox.OnClick:=CheckOnClick;
  CheckBox.Width:=CheckWidth;

  Case CheckBox.Checked of
  True:
  FVariables.Variables[FNamespace, Field.Variable]:='1';
  False:
  FVariables.Variables[FNamespace, Field.Variable]:='0';
  end;

  Field.DCLEditComponent:=TDCLEdit.Create;
  Field.DCLEditComponent.Control:=CheckBox;
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

  If PosEx('_OnCheck;', Scr)<>0 Then
    DBCheckBox.Checked:=True;
  If PosEx('_OffCheck;', Scr)<>0 Then
    DBCheckBox.Checked:=False;

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
    If FVariables.Exists(FNamespace, Field.Variable) then
    begin
      Case (Sender as TCheckbox).Checked of
      True:
      FVariables.Variables[FNamespace, Field.Variable]:='1';
      False:
      FVariables.Variables[FNamespace, Field.Variable]:='0';
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
  FSumQuery:=TDCLDialogQuery.Create(Self);
  FSummFieldsSet:=FindParam('SummQuery=', ScrLine);
  FSumQuery.SQL.Text:=GetSummQuery;
  FDBConnector.SetConnector(FSumQuery);
  FSumData:=TDataSource.Create(Self);
  FSumData.DataSet:=FSumQuery;
  FSumQuery.Open;

  FSummGrid:=TNoScrollBarDBGrid.Create(FMainPanel);
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
      If FieldExists(FieldName, FSumQuery) Then
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
  DateBox: DateTimePicker;
  S, KeyField: String;
  ShadowQuery: TDCLDialogQuery;
begin
  DateBox:=DateTimePicker.Create(FFieldsPanel);
  DateBox.Parent:=FFieldsPanel;
  DateBox.DateOrder:=doDMY;
  DateBox.DateFormat:=GPT.DateFormat;

  If FindParam('ComponentName=', Scr)<>'' Then
    DateBox.Name:=FindParam('ComponentName=', Scr);

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
  If FindParam('_Value=', Scr)<>'' then
    NeedValue:=1;
  If FindParam('SQL=', Scr)<>'' then
    NeedValue:=2;

  if not Field.NoDataField then
  begin
    If FQuery.Active Then
    Begin
      If FindParam('_ValueIfNull=', Scr)<>'' Then
      Begin
        If FieldExists(Field.FieldName, FQuery) Then
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
    If FieldExists(Field.FieldName, FQuery) Then
      S:=TrimRight(FQuery.FieldByName(Field.FieldName).AsString);
  end
  Else
    S:=DateToStr(Date);
  1:
  begin
    S:=FindParam('_Value=', Scr);
  end;
  2:
  begin
    ShadowQuery:=TDCLDialogQuery.Create(Self);
    FDBConnector.SetConnector(ShadowQuery);
    S:=FindParam('SQL=', Scr);
    ShadowQuery.SQL.Text:=S;
    ShadowQuery.Open;
    If FindParam('ReturnField=', Scr)<>'' Then
      KeyField:=FindParam('ReturnField=', Scr)
    Else
      KeyField:=ShadowQuery.Fields[0].FieldName;

    DeleteNonPrintSimb(KeyField);
    If FieldExists(KeyField, ShadowQuery) Then
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

  If FindParam('VariableName=', Scr)<>'' Then
  begin
    FVariables.NewVariable(FNamespace, FindParam('VariableName=', Scr), S);
    KeyField:=FindParam('VariableName=', Scr);
  end
  Else
  begin
    FVariables.NewVariable(FNamespace, 'DateBox_'+Field.FieldName, S);
    KeyField:='DateBox_'+Field.FieldName;
  end;

  Field.Variable:=KeyField;
  If S<>'' then
    DateBox.Date:=StrToDate(S);

  Field.DCLEditComponent:=TDCLEdit.Create;
  Field.DCLEditComponent.Control:=DateBox;
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
    Value:=DateToStr((f.DCLEditComponent.Control as DateTimePicker).Date);
    FVariables.Variables[FNamespace, Field.Variable]:=Value;

    If not Field.ReadOnly then
    begin
      if not Field.NoDataField then
      Begin
        If FQuery.Active then
        begin
          If FieldExists(Field.FieldName, FQuery) then
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
      Filter.FilterString:=TrimRight((Sender as TDBLookupComboBox).KeyValue);
    end;
    ftComboFilter: begin
      cbx:=Sender as TComboBox;
      if cbx.ItemIndex<>-1 then
        Filter.FilterString:=(cbx.Items.Objects[cbx.ItemIndex] as TComboFilterItem).Key;
    end;
    end;
    if Filter.VarName<>'' then
      FVariables.Variables[FNameSpace, Filter.VarName]:=Filter.FilterString;

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

    If FQuery.Active and FieldExists(Filter.Field, FQuery) then
    Begin
      If not CheckStrFmtType(ExeplStr, GetSimplyFieldType(Filter.Field, FQuery)) then
      Begin
        ExeplStr:='';
      End;
    End;
    Filter.FilterString:=ExeplStr;

    if Filter.VarName<>'' then
      FVariables.Variables[FNamespace, Filter.VarName]:=TrimRight(ExeplStr);

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
  LookupTable:=TLookupTable.Create(FNameSpace, FForms, FForm, FFieldsPanel, FVariables,
  FDBConnector, nil, FData);

  if Field.Width>0 then
    LookupTable.Width:=Field.Width
  else
    LookupTable.Width:=EditWidth;

  if Field.Height>0 then
    LookupTable.Height:=Field.Height
  else
    LookupTable.Height:=LookupTableHeight;

  TempStr:=FindParam('SQL=', Scr);
  TranslateVal(TempStr, False);
  LookupTable.DCLGrid.SetSQL(TempStr);
  if TempStr<>'' then
    LookupTable.DCLGrid.Query.Open;

  LookupTable.DCLGrid.ReadOnly:=Field.ReadOnly;
  LookupTable.DCLGrid.DependField:=FindParam('DependField=', Scr);
  LookupTable.DCLGrid.NoDataField:=Field.NoDataField;

  LookupTable.DCLGrid.MasterValueVariableName:=FindParam('VariableName=', Scr);

  if not Field.NoDataField then
  If FQuery.Active then
    If LookupTable.DCLGrid.MasterDataField='' then
      if FieldExists(LookupTable.DCLGrid.MasterDataField, FQuery) then
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
      If FieldExists(FieldName, LookupTable.DCLGrid.Query) Then
      begin
        FFieldColumn.FType:=LookupTable.DCLGrid.Query.FieldByName(FieldName).DataType;
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
  tpc: TDCLGrid;
  FLocalBookmark: TBookmark;
begin
  If FQuery.Active Then
  Begin
    If FQuery.State in dsEditModes Then
      FQuery.Post;

    {$IFnDEF NODSBOOKMARKS}
    FLocalBookmark:=FQuery.Bookmark;
    {$ELSE}
    FLocalBookmark:=FQuery.GetKeyBookmark;
    {$ENDIF}
    For tpc in FTableParts do
    begin
      tpc.Close;
    end;
    Close;
  End;

  Open;
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
begin
  if Assigned((FForm as TDCLForm).ReturnValueParams) then
  begin
    ReturnValueParams:=(FForm as TDCLForm).ReturnValueParams;
    if Assigned(FQuery) and FQuery.Active and FieldExists(ReturnValueParams.KeyField, FQuery) and
      FieldExists(ReturnValueParams.ValueField, FQuery) then
    begin
      ReturnValue:=TReturnFormValue.Create;
      ReturnValue.DestinationForm:=FForm;
      ReturnValue.KeyModifyField:=ReturnValueParams.KeyModifyField;
      ReturnValue.ValueModifyField:=ReturnValueParams.ValueModifyField;
      ReturnValue.KeyEditName:=ReturnValueParams.KeyEditName;
      ReturnValue.ValueEditName:=ReturnValueParams.ValueEditName;
      ReturnValue.KeyVar:=ReturnValueParams.KeyVar;
      ReturnValue.ValueVar:=ReturnValueParams.ValueVar;
      ReturnValue.BatchScript:=ReturnValueParams.BatchScript;
      ReturnValue.Multiselect:=ReturnValueParams.Multiselect;

      ReturnValue.Values:=TList<TGetValueItem>.Create;
      if Assigned(FDBGrid) and FMultiSelectMode and FDBGrid.HasMultiSelection then
      begin
        for Bookmark in FDBGrid.SelectedRows do
        begin
          FQuery.GoToBookmark(TBookmark(Bookmark));
          ValueItem:=TGetValueItem.Create;
          ValueItem.Key:=FQuery.FieldByName(ReturnValueParams.KeyField).AsString;
          ValueItem.Value:=FQuery.FieldByName(ReturnValueParams.ValueField).AsString;

          ReturnValue.Values.Add(ValueItem);
        end;
      end
      else
      begin
        ValueItem:=TGetValueItem.Create;
        ValueItem.Key:=FQuery.FieldByName(ReturnValueParams.KeyField).AsString;
        ValueItem.Value:=FQuery.FieldByName(ReturnValueParams.ValueField).AsString;

        ReturnValue.Values.Add(ValueItem);
      end;
      (FForm as TDCLForm).ReturnValue:=ReturnValue;

      if Assigned((FForm as TDCLForm).RetValueMethod) then
        (FForm as TDCLForm).RetValueMethod(ReturnValue);

      if ReturnValueParams.Modal then
        FForm.ModalResult:=mrOk
      else
        FForm.Close;
    end;
  end;
end;

procedure TDCLGrid.SetMultiSelect(Value: Boolean);
begin
  FMultiSelectMode:=Value;
end;

function TDCLGrid.GetSQLFromStorage: String;
begin
  Result:='';
  if FQueryes.ContainsKey(qtMain) then
    Result:=FQueryes[qtMain].QueryStr;
end;

procedure TDCLGrid.ParseEvents(ScrStr: String);
var
  S: String;
begin
  If PosEx('AfterPost=', ScrStr)<>0 Then
  begin
    S:=FindParam('AfterPost=', ScrStr);
    AddEvent(evtAfterPost, S);
  end;

  If PosEx('Cancel=', ScrStr)<>0 Then
  begin
    S:=FindParam('Cancel=', ScrStr);
    AddEvent(evtCancel, S);
  end;

  If PosEx('Close=', ScrStr)<>0 Then
  begin
    S:=FindParam('Close=', ScrStr);
    AddEvent(evtClose, S);
  end;

  If PosEx('Scroll=', ScrStr)<>0 Then
  begin
    S:=FindParam('Scroll=', ScrStr);
    AddEvent(evtScroll, S);
  end;

  If PosEx('LineDblClick=', ScrStr)<>0 Then
  begin
    S:=FindParam('LineDblClick=', ScrStr);
    AddEvent(evtLineDblClick, S);
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
      S:=OnlyLitters(FN.FieldName);
      if S<>'' then
        Fields.Add(S.ToLowerInvariant);
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

  ItemMenu.Bitmap.Assign(DrawBMPButton(PictType));
  ItemMenu.Bitmap.TransparentColor:=clWhite;
  ItemMenu.Bitmap.TransparentMode:=tmAuto;

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
    pmaClearFind: begin
      if Assigned(FindGrid) then
      begin
        for t:=1 to FindGrid.ColCount-1 do
        begin
          FindGrid.Cells[t, FindGrid.RowCount-1]:='';
        end;
      end;
    end;
  end;
end;

procedure TDCLGrid.Undo;
begin
  if Assigned(FDBGrid) and Assigned(FData) and
    Assigned(FData.DataSet) then
      FData.DataSet.Cancel;
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

constructor TDCLGrid.Create(NameSpace: String; Forms: TList<TForm>; Form: TForm; ParentControl: TWinControl; Variables: TVariables; SurfType: TDataControlType;
  DBConnector: TDCLDBConnector; Query: TDCLQuery; Data: TDataSource);
var
  ChooseButton, ButtonClose: TDCLCommandButton;
begin
  inherited Create(ParentControl);
  Self.Parent:=ParentControl;

  FUserLevel:=(Form as TDCLForm).RightsLevel;

  FMainPanel:=TPanel.Create(Self);
  FMainPanel.Parent:=Parent;

  FForm:=Form;
  FForms:=Forms;

  FDialogName:=(Form as TDCLForm).DialogName;
  FDBConnector:=DBConnector;
  FNameSpace:=NameSpace;
  FVariables:=Variables;

  FButtons:=TList<TDCLCommandButton>.Create;

  if CloseButton and (SurfType=dctMainGrid) then
  begin
    ButtonClose:=TDCLCommandButton.Create(FDBConnector);
    ButtonClose.Caption:=GetDCLMessageString(msClose);
    ButtonClose.Command:='Close;';
    //ButtonClose.Pict:='esc';
    ButtonClose.Cancel:=True;
    FButtons.Add(ButtonClose);
  end;

  if Assigned((FForm as TDCLForm).ReturnValueParams) then
  begin
    ChooseButton:=TDCLCommandButton.Create(FDBConnector);
    ChooseButton.ChoiceButton:=True;
    ChooseButton.Caption:=GetDCLMessageString(msChoose);
    ChooseButton.Default:=True;

    FButtons.Add(ChooseButton);
  end;

  FTableParts:=TList<TDCLGrid>.Create;
  FLookupTables:=TList<TDCLGrid>.Create;
  FDCLFields:=TList<TDCLField>.Create;
  FFilters:=TList<TDBFilter>.Create;
  FCalendars:=TList<TDCLCalendar>.Create;
  FEvents:=TList<TDCLEvent>.Create;
  FNotAllowedOperations:=TList<TNotAllowedOperation>.Create;

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
  FGridStyle:=gsGrid;

  FMultiSelectMode:=False;
  FFilterLeft:=BeginStepLeft;

  FQueryes:=TDictionary<TQueryType, TDCLQueryStore>.Create;

  CreateToolPanel;

  CreateImageList;

  FExtData:=Data;

  if Assigned(Query) then
    FQuery:=Query;

  FData:=TDataSource.Create(Self);
  if Assigned(Query) then
    FData.DataSet:=Query;
end;

destructor TDCLGrid.Destroy;
var
  FieldsPos: TStringList;
  ConfigPath, Seed: String;
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
  if (Style=gsGrid) and Assigned(FDBGrid) then
  begin
    ConfigPath:=AppConfigDir+FormConfigDir+'Base_'+GPT.BaseID+PathDelim+'Forms'+PathDelim+FDialogName+PathDelim+'Grids'+PathDelim;
    if not DirectoryExists(ConfigPath) then
      ForceDirectories(ConfigPath);

    Seed:=GetGridSeed;
    FieldsPos:=TStringList.Create;
    GetDBGridFieldsPos(FieldsPos);

    if FieldsPos.Count>0 then
      FieldsPos.SaveToFile(ConfigPath+Seed+'.ini', TEncoding.UTF8);

    FreeAndNil(FieldsPos);
  end;
  inherited Destroy;
end;

procedure TDCLGrid.AddField(Field: TDCLField);
begin
  FDCLFields.Add(Field);
end;

procedure TDCLGrid.Open;
begin
  If Length(FQuery.SQL.Text)>11 Then
  Try
    FQuery.Open;
  Except
    ShowErrorMessage( - 1100, 'SQL='+FQuery.SQL.Text);
  End;
end;

procedure TDCLGrid.Close;
begin
  If FQuery.Active Then
  begin
    If FQuery.State in dsEditModes Then
      FQuery.Post;
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
    FToolBar.ButtonWidth:=((FToolBar.ClientWidth-(ToolBarButtonSpliterWidth * (FToolButtonsCount-1))) div FToolButtonsCount)-FToolButtonsCount;
  end;
end;

procedure TDCLGrid.ExecScriptLine(ScrStr: String);
var
  ButtonParams: TDCLCommandButton;
  tmpS, tmpS2, tmpS3, tmpSQL: String;
  flg: Boolean;
  FFilter: TDBFilter;
  IsDigitType: TIsDigitType;
  v1, v2, i: Integer;
  FFieldColumn: TDCLField;
  tmpStyle: TGridStyle;
  QType: TDCLQueryStore;
begin
  if (FFieldsCount=-1) and FReadFieldsMode then
  begin
    if ScrStr='*' then
    begin

    end
    else
    begin
      FFieldsCount:=StrToIntEx(ScrStr);
    end;
    FFieldParsingMode:=fpmCaption;

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

    If Not FindDisableAction(LowerCase(FindParam('action=', ScrStr))) Then
    begin
      flg:=True;
      tmpS:=FindParam('AccessLevel=', ScrStr);
      If tmpS<>'' Then
      begin
        flg:=False;
        IsDigitType:=GetStringDataType(tmpS);
        Case IsDigitType of
          idDigit: flg:=TranslateDigitToUserLevel(StrToIntEx(FindParam('AccessLevel=', ScrStr)))<=FUserLevel;
          idString: flg:=TranslateDigitToUserLevel(FindParam('AccessLevel=', ScrStr))<=FUserLevel;
        end;
      end;

      If flg Then
      begin
        ButtonParams:=TDCLCommandButton.Create(FDBConnector);
        ButtonParams.Caption:=InitCap(FindParam('label=', ScrStr));
        If FindParam('_Default=', ScrStr)='1' Then
          ButtonParams.Default:=True;

        If FindParam('_Cancel=', ScrStr)='1' Then
          ButtonParams.Cancel:=True;

        If FindParam('Host=', ScrStr)='1' then
          ButtonParams.Host:=True;

        ButtonParams.Hint:=InitCap(FindParam('hint=', ScrStr));

        tmpS:=FindParam('Action=', ScrStr);
        If tmpS<>'' Then
        begin
          ButtonParams.Command:=tmpS;
          ButtonParams.Pict:=FindParam('Action=', ScrStr);
        end
        Else
        begin
          If PosEx('CommandName=', ScrStr)<>0 Then
            ButtonParams.Command:=FindParam('commandname=', ScrStr);

          ButtonParams.Pict:=FindParam('Pict=', ScrStr);
        end;

        ButtonParams.ForEach:=FindParam('ForEach=', ScrStr)='1';

        If PosEx('bold', FindParam('FontStyle=', ScrStr))<>0 Then
          ButtonParams.FontStyle:=ButtonParams.FontStyle+[fsBold];
        If PosEx('italic', FindParam('FontStyle=', ScrStr))<>0 Then
          ButtonParams.FontStyle:=ButtonParams.FontStyle+[fsItalic];
        If PosEx('underline', FindParam('FontStyle=', ScrStr))<>0 Then
          ButtonParams.FontStyle:=ButtonParams.FontStyle+[fsUnderLine];

        tmpS:=FindParam('Width=', ScrStr);
        If tmpS<>'' then
        begin
          v1:=StrToIntEx(tmpS);
          If v1>30 then
            ButtonParams.Width:=v1
          else
            ButtonParams.Width:=-1;
        end
        Else
          ButtonParams.Width:=ButtonWidth;

        FNoButtonPanel:=False;
        FButtons.Add(ButtonParams);
      end;
    end;
  end;

  if IsLexem('TablePartToolButton=', ScrStr) then
  begin
    TranslateVal(ScrStr, True);

    If Not FindDisableAction(FindParam('action=', ScrStr)) Then
    begin
      flg:=True;
      tmpS:=FindParam('AccessLevel=', ScrStr);
      If tmpS<>'' Then
      begin
        flg:=False;
        IsDigitType:=GetStringDataType(tmpS);
        Case IsDigitType of
        idDigit:
          If TranslateDigitToUserLevel(StrToIntEx(FindParam('AccessLevel=', ScrStr)))<=FUserLevel Then
            flg:=True;
        idString:
          If TranslateDigitToUserLevel(FindParam('AccessLevel=', ScrStr))<=FUserLevel Then
            flg:=True;
        end;
      end;

      If flg Then
      begin
        ButtonParams:=TDCLCommandButton.Create(FDBConnector);
        ButtonParams.Caption:=InitCap(FindParam('label=', ScrStr));
        If FindParam('_Default=', ScrStr)='1' Then
          ButtonParams.Default:=True;

        If FindParam('_Cancel=', ScrStr)='1' Then
          ButtonParams.Cancel:=True;

        If FindParam('Host=', ScrStr)='1' then
          ButtonParams.Host:=True;

        ButtonParams.Hint:=InitCap(FindParam('hint=', ScrStr));

        tmpS:=FindParam('Action=', ScrStr);
        If tmpS<>'' Then
        begin
          ButtonParams.Command:=tmpS;
          ButtonParams.Pict:=FindParam('action=', ScrStr);
        end
        Else
        begin
          If PosEx('CommandName=', ScrStr)<>0 Then
            ButtonParams.Command:=FindParam('commandname=', ScrStr);

          ButtonParams.Pict:=FindParam('Pict=', ScrStr);
        end;

        If PosEx('bold', FindParam('FontStyle=', ScrStr))<>0 Then
          ButtonParams.FontStyle:=ButtonParams.FontStyle+[fsBold];
        If PosEx('italic', FindParam('FontStyle=', ScrStr))<>0 Then
          ButtonParams.FontStyle:=ButtonParams.FontStyle+[fsItalic];
        If PosEx('underline', FindParam('FontStyle=', ScrStr))<>0 Then
          ButtonParams.FontStyle:=ButtonParams.FontStyle+[fsUnderLine];

        tmpS:=FindParam('Width=', ScrStr);
        If tmpS<>'' Then
        begin
          v1:=StrToIntEx(tmpS);
          If v1>4 Then
            ButtonParams.Width:=v1;
        end
        Else
          ButtonParams.Width:=ButtonWidth;

        CurrentTablePart.AddButton(ButtonParams);
      end;
    end;
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
      FQuery.Open;
    end;
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

  If IsLexem('MultiSelect=', ScrStr) Then
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
    FNavigatorExpr:=ScrStr;
  end;

  if IsLexem('TablePart=', ScrStr) then
  begin
    TranslateVal(ScrStr, False);
    tmpSQL:=FindParam('SQL=', ScrStr);
    if tmpSQL<>'' then
    begin
      TranslateVal(ScrStr, True);

      tmpStyle:=gsGrid;
      tmpS:=FindParam('Style=', ScrStr);
      If tmpS='0' Then
        tmpStyle:=gsFields;
      If tmpS='1' Then
        tmpStyle:=gsFieldsHorizontal;
      If tmpS='2' Then
        tmpStyle:=gsGrid;

      AddTablePart(FindParam('Title=', ScrStr), FData, tmpStyle);

      if (FindParam('UpdateTable=', ScrStr)<>'') and (FindParam('KeyFields=', ScrStr)<>'') then
        FCurrentTablePart.Query.SetUpdateSQL
          (FindParam('UpdateTable=', ScrStr), FindParam('KeyFields=', ScrStr));

      FCurrentTablePart.SetSQL(tmpSQL);

      if FQuery.Active then
        FCurrentTablePart.Query.open;

      If FindParam('DependField=', ScrStr)<>'' Then
      begin
        FCurrentTablePart.DependField:=FindParam('DependField=', ScrStr);
      end;

      If FindParam('MasterDataField=', ScrStr)<>'' Then
      begin
        FCurrentTablePart.MasterDataField:=FindParam('MasterDataField=', ScrStr);
      end;

      FCurrentTablePart.NoDataField:=FindParam('NoDataField=', ScrStr)='1';
      If FindParam('VariableName=', ScrStr)<>'' Then
      begin
        FCurrentTablePart.MasterValueVariableName:=FindParam('VariableName=', ScrStr);
      end;

      If FindParam('Navigator=', ScrStr)='1' Then
      begin
        FCurrentTablePart.ExecScriptLine('Navigator=1');
      end;

      If FindParam('NavigatorButtons=', ScrStr)='' Then
        ScrStr:=ScrStr+';NavigatorButtons='+DefaultNavigButtonsSet+';';

      If PosEx('NavigatorButtons=', ScrStr)<>0 Then
      begin
        FCurrentTablePart.SetNavigatorButtonsSet(FindParam('NavigatorButtons=', ScrStr));
      end;

      tmpS:=Trim(FindParam('ReadOnly=', ScrStr));
      If StrToIntEx(tmpS)=1 Then
      begin
        FCurrentTablePart.ExecScriptLine('ReadOnly=1');
      end;

      tmpS:=FindParam('Columns=', ScrStr);
      If tmpS<>'' Then
      begin
        v1:=ParamsCount(tmpS);
        For i:=1 to v1 do
        begin
          tmpS2:=GetParam(tmpS, i);
          tmpS3:=Copy(tmpS2, 1, Pos('/', tmpS2)-1);
          v2:=0;
          If Pos('=', tmpS3)<>0 Then
          begin
            v2:=StrToIntEx(CopyCut(tmpS3, Pos('=', tmpS3)+1, Length(tmpS3)));
            Delete(tmpS3, PosEx('=', tmpS3), Length(tmpS3));
          end;

          FFieldColumn:=TDCLField.Create;
          FFieldColumn.FieldName:=tmpS3;
          FFieldColumn.Caption:=Copy(tmpS2, Pos('/', tmpS2)+1, Length(tmpS2)-1);
          FFieldColumn.Width:=v2;

          FCurrentTablePart.AddField(FFieldColumn);
        end;
      end;
    end;
  end;

  if IsLexem('DBFilter=', ScrStr) then
  begin
    FFilter:=TDBFilter.Create;
    TranslateVal(ScrStr, True);
    FFilter.SQL:=FindParam('SQL=', ScrStr);
    If FFilter.SQL='' Then
      FFilter.SQL:=FindParam('DBFilterQuery=', ScrStr);
    If FFilter.SQL<>'' Then
    begin
      FFilter.FilterType:=ftDBFilter;

      FFilter.Caption:=FindParam('Label=', ScrStr);
      FFilter.Field:=FindParam('FilterField=', ScrStr);
      FFilter.ListField:=FindParam('List=', ScrStr);
      FFilter.KeyField:=FindParam('Key=', ScrStr);
      FFilter.Between:=FindParam('Between=', ScrStr)='1';

      v1:=FilterWidth;
      If FindParam('Width=', ScrStr)<>'' Then
        v1:=StrToIntEx(Trim(FindParam('Width=', ScrStr)));
      FFilter.Width:=v1;

      If FindParam('VariableName=', ScrStr)<>'' Then
      begin
        FFilter.VarName:=FindParam('VariableName=', ScrStr);
        FVariables.NewVariableWithTest(FNamespace, FFilter.VarName);
      end;

      tmpS:=FindParam('KeyValue=', ScrStr);
      If tmpS<>'' Then
      begin
        FFilter.KeyValue:=tmpS;
      end;

      AddFilter(FFilter);
    end;
  end;

  If IsLexem('ContextFilter=', ScrStr) Then
  begin
    FFilter:=TDBFilter.Create;
    TranslateVal(ScrStr, True);
    FFilter.FilterType:=ftContextFilter;
    FFilter.Caption:=FindParam('Label=', ScrStr);
    FFilter.Field:=FindParam('FilterField=', ScrStr);
    FFilter.Between:=FindParam('Between=', ScrStr)='1';

    v1:=FilterWidth;
    If FindParam('Width=', ScrStr)<>'' Then
      v1:=StrToIntEx(Trim(FindParam('Width=', ScrStr)));
    FFilter.Width:=v1;

    If FindParam('VariableName=', ScrStr)<>'' Then
    begin
      FFilter.VarName:=FindParam('VariableName=', ScrStr);
      FVariables.NewVariableWithTest(FNamespace, FFilter.VarName);
    end;

    If FindParam('MaxLength=', ScrStr)<>'' Then
    begin
      FFilter.MaxLength:=StrToIntEx(Trim(FindParam('MaxLength=', ScrStr)));
    end;

    tmpS:=FindParam('WaitForEnter=', ScrStr);
    If tmpS='1' Then
    begin
      FFilter.WaitForKey:=13;
    end;

    tmpS:=FindParam('FilterMode=', ScrStr);
    If tmpS<>'' Then
    begin
      If PosEx('Case', tmpS)<>0 Then
        FFilter.CaseC:=True;

      If PosEx('NotLike', tmpS)<>0 Then
        FFilter.NotLike:=True;

      If PosEx('Partial', tmpS)<>0 Then
        FFilter.Partial:=True;
    end;

    If PosEx('ComponentName=', ScrStr)<>0 Then
      FFilter.FilterName:=FindParam('ComponentName=', ScrStr);

    FFilter.KeyValue:=FindParam('_Value=', ScrStr);

    AddFilter(FFilter);
  end;

  If IsLexem('ComboFilter=', ScrStr) Then
  begin
    FFilter:=TDBFilter.Create;
    TranslateVal(ScrStr, True);
    FFilter.FilterType:=ftComboFilter;

    FFilter.Caption:=FindParam('Label=', ScrStr);
    FFilter.Field:=FindParam('FilterField=', ScrStr);
    FFilter.ListField:=FindParam('List=', ScrStr);
    FFilter.Between:=FindParam('Between=', ScrStr)='1';

    v1:=FilterWidth;
    If FindParam('Width=', ScrStr)<>'' Then
      v1:=StrToIntEx(Trim(FindParam('Width=', ScrStr)));
    FFilter.Width:=v1;

    If FindParam('VariableName=', ScrStr)<>'' Then
    begin
      FFilter.VarName:=FindParam('VariableName=', ScrStr);
      FVariables.NewVariableWithTest(FNamespace, FFilter.VarName);
    end;

    tmpS:=FindParam('KeyValue=', ScrStr);
    If tmpS<>'' Then
    begin
      FFilter.KeyValue:=tmpS;
    end;

    AddFilter(FFilter);
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

  If IsLexem('NoButtonsPanel;', ScrStr) then
  begin
    FNoButtonPanel:=True;
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
    ParseEvents(ScrStr);
  end;

  if IsLexem('[Fields]', ScrStr) then
  begin
    FReadFieldsMode:=True;
  end;
end;

procedure TDCLGrid.Prepeare;
var
  DCLField: TDCLField;
  Grid: TDCLGrid;
  btc: TDCLCommandButton;
  tmpS: String;
  FieldsPos: TList<TGridFieldSetting>;
  FieldPos: TGridFieldSetting;
begin
  CreateToolPanel;

  if not Assigned(FToolBar) then
  begin
    FToolButtonsCount:=0;
    FToolBar:=TToolBar.Create(FToolsPanel);
    FToolBar.Parent:=FToolsPanel;
    FToolBar.Images:=FImages;
    FToolBar.OnResize:=OnGridResize;
    FToolBar.Height:=ToolButtonPanelHeight;
    FToolBar.ButtonHeight:=ToolButtonHeight;
    FToolBar.Flat:=ToolButtonsFlat;
    FToolBar.EdgeBorders:=[ebLeft, ebTop, ebRight]; //, ebBottom];
  end;

  if not Assigned(FNavig) then
  begin
    tmpS:=FNavigatorExpr;
    if tmpS<>'0' then
    begin
      CreateToolPanel;

      FNavig:=TDBNavigator.Create(FToolsPanel);
      FNavig.Parent:=FToolsPanel;
      FNavig.Align:=alBottom;
      FNavig.DataSource:=FData;

      Inc(FToolPanelHeight, FNavig.Height);

      SetNavigatorButtonsSet(FindParam('buttons=', FNavigatorExpr));

      If FindParam('Flat=', FNavigatorExpr)<>'' Then
      begin
        tmpS:=FindParam('Flat=', FNavigatorExpr);
        If tmpS='1' Then
          FNavig.Flat:=True;
      end;
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
      FButtonPanel:=TDCLButtonPanel.Create(Self);
      FButtonPanel.Parent:=Parent;
      //FButtonPanel.Height:=ButtonPanelHeight;

      FButtonFlowPanel:=TFlowPanel.Create(FButtonPanel);
      FButtonFlowPanel.Parent:=FButtonPanel;
      FButtonFlowPanel.Align:=alClient;
      FButtonFlowPanel.AutoSize:=True;
      FButtonFlowPanel.Constraints.MaxHeight:=((ButtonHeight+ButtonsInterval)*3)+ButtonsTop;

      FButtonLayout:=TDCLButtonLayoutManger<TDCLCommandButton>.Create(FButtonPanel, FButtons);
      FButtonLayout.InitMeasurements;
    end;
    if FDataControlType=dctMainGrid then
      FButtonPanel.Align:=alBottom
    else
      FButtonPanel.Align:=alTop;

    FButtonFlowPanel.OnResize:=OnResizeButtonFlowPanel;
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
    FToolBarButtonFind.ImageIndex:=FPicturesIndexes[ptFind];
    FToolBarButtonFind.OnClick:=Find;
    Inc(FToolButtonsCount);
  end;

  if FDataReadOnly then
  begin
    FReadOnly:=True;
    {$IFDEF READONLYPROPERTY}
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

      if not Assigned(DCLField.DCLEditComponent) and FQuery.Active then
      begin
        if FieldExists(DCLField.FieldName, FQuery) then
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
            ftDate, ftDateTime: begin
              AddDBDateEdit(DCLField);
            end;
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
        FToolBarButtonStruct.ImageIndex:=FPicturesIndexes[ptStructure];
        FToolBarButtonStruct.OnClick:=Structure;
        Inc(FToolButtonsCount);
      end;

      if Assigned(FQuery) then
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
        FToolBarButtonPrint.ImageIndex:=FPicturesIndexes[ptPrint];
        FToolBarButtonPrint.OnClick:=Print;
        Inc(FToolButtonsCount);
      end;

      FDBGrid:=TDBGrid.Create(FMainPanel);
      FDBGrid.Parent:=FMainPanel;
      if FMultiSelectMode then
      begin
        FDBGrid.Options:=FDBGrid.Options+[dgMultiSelect];
      end;
      if FReadOnly then
        FDBGrid.Options:=FDBGrid.Options-[dgEditing];

      FDBGrid.DataSource:=FData;
      {$IFDEF FPC}
      FDBGrid.AlternateColor:=GridAlternateColor;
      {$ENDIF}
      FDBGrid.OnDblClick:=GridDblClick;
      FDBGrid.OnTitleClick:=GridColumnClick;
      FDBGrid.TitleImageList:=FImages;

      PopupGridMenu:=TPopupMenu.Create(FDBGrid);
      PopupGridMenu.Parent:=FDBGrid;
      FDBGrid.PopupMenu:=PopupGridMenu;

      AddPopupItem(GetDCLMessageString(msFindCurrCell), pmaFindCurrCell, 'Alt+F', ptNone);
      AddPopupItem(GetDCLMessageString(msClearAllFind), pmaClearFind, 'Alt+C', ptNone);

      AddPopupSeparator;

      AddPopupItem(GetDCLMessageString(msCopy), pmaCopy, 'Ctrl+C', ptCopy);

      if not FReadOnly then
      begin
        AddPopupItem(GetDCLMessageString(msCut), pmaCut, 'Ctrl+X', ptCut);
        AddPopupItem(GetDCLMessageString(msPast), pmaPaste, 'Ctrl+V', ptPaste);

        AddPopupSeparator;

        AddPopupItem(GetDCLMessageString(msCancel), pmaUndo, 'Ctrl+U', ptUndo);
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
  end;

  if Assigned(FDBGrid) then
  begin
    FDBGrid.Align:=alClient;
  end;

  FSeed:=CalculateSeed;
  If Assigned(FQuery) then
    FQuery.NotAllowOperations:=FNotAllowedOperations.ToArray;

  FMainPanel.Align:=alClient;

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
var
  i: Integer;
  AllowEdit, HideNavig: Boolean;
  b: TNavButtonsSet;
  NavigVisiButtonsVar: Array [1..12] Of TNavButtonsSet;
begin
  if Assigned(FNavig) then
  begin
    AllowEdit:=False;
    if Assigned(FQuery) then
    begin
      AllowEdit:=FQuery.Active and FQuery.CanModify;
    end;

    For i:=1 to Length(NavigVisiButtonsVar) do
      NavigVisiButtonsVar[i]:=[];

    If PosEx('first', ButtonsExpr)<>0 Then
      NavigVisiButtonsVar[1]:=[nbFirst];
    If PosEx('last', ButtonsExpr)<>0 Then
      NavigVisiButtonsVar[4]:=[nbLast];

    If FUserLevel>ulReadOnly Then
    if AllowEdit then
    begin
      if not FindNotAllowedOperation(dsoInsert) then
      If PosEx('insert', ButtonsExpr)<>0 Then
        NavigVisiButtonsVar[5]:=[nbInsert];

      if not FindNotAllowedOperation(dsoDelete) then
      If PosEx('delete', ButtonsExpr)<>0 Then
        NavigVisiButtonsVar[6]:=[nbDelete];

      if not FindNotAllowedOperation(dsoEdit) then
      If PosEx('edit', ButtonsExpr)<>0 Then
        NavigVisiButtonsVar[7]:=[nbEdit];

      If PosEx('post', ButtonsExpr)<>0 Then
        NavigVisiButtonsVar[8]:=[nbPost];
      If PosEx('cancel', ButtonsExpr)<>0 Then
        NavigVisiButtonsVar[9]:=[nbCancel];
    end;
    If PosEx('refresh', ButtonsExpr)<>0 Then
      NavigVisiButtonsVar[10]:=[nbRefresh];

    HideNavig:=True;
    for b in NavigVisiButtonsVar do
      if b<>[] then
      begin
        HideNavig:=False;
        Break;
      end;

    if not HideNavig then
      FNavig.VisibleButtons:=NavigVisiButtonsVar[1]+NavigVisiButtonsVar[2]+
        NavigVisiButtonsVar[3]+NavigVisiButtonsVar[4]+NavigVisiButtonsVar[5]+
        NavigVisiButtonsVar[6]+NavigVisiButtonsVar[7]+NavigVisiButtonsVar[8]+
        NavigVisiButtonsVar[9]+NavigVisiButtonsVar[10]
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
    FButtons.Add(Button);
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
  for e in FDCLFields do
  begin
    if e.RequireValue and (e.NotInputValue='') then
    begin
      if Assigned(e.DCLEditComponent) and Assigned(e.DCLEditComponent.Control) then
      begin
        if (e.DCLEditComponent.Control is TEdit) and ((e.DCLEditComponent.Control as TEdit).Text='') then
        begin
          Result:=False;
          NotifyEditFieldError(e);
        end;
        if (e.DCLEditComponent.Control is TDBLookupComboBox) and ((e.DCLEditComponent.Control as TDBLookupComboBox).KeyValue='') then
        begin
          Result:=False;
          NotifyEditFieldError(e);
        end;
        if (e.DCLEditComponent.Control is TComboBox) and ((e.DCLEditComponent.Control as TComboBox).ItemIndex=-1) then
        begin
          Result:=False;
          NotifyEditFieldError(e);
        end;
      end;
    end;
  end;
end;

procedure TDCLGrid.NotifyEditFieldError(Field: TDCLField);
begin
  ////
end;

procedure TDCLGrid.GetDBGridFieldsPos(var Settings: TStringList);
var
  i: Integer;
  C: TColumn;
begin
  if Assigned(Settings) and not GPT.DisableFieldsList then
  begin
    if (Style=gsGrid) and Assigned(FDBGrid) then
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

  if Assigned(FDBGrid) and (Style=gsGrid) and not GPT.DisableFieldsList then
  begin
    S:=GetGridSeed;
    ConfigPath:=AppConfigDir+FormConfigDir+'Base_'+GPT.BaseID+PathDelim+'Forms'+PathDelim+FDialogName+PathDelim+'Grids'+PathDelim;
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
begin
  if Assigned(FDBGrid) then
  begin
    FDBGrid.Columns.Clear;
    for DCLField in FDCLFields do
    begin
      AddColumn(DCLField);
    end;
  end;
end;

end.

