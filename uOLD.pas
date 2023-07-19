unit uOLD;
{$I DefineType.pas}

interface

Uses
  SysUtils,
{$IFDEF MSWINDOWS}
  Windows, ComObj,
{$ENDIF}
{$IFDEF UNIX}
  cwstring, process, unix, lclintf, BaseUnix,
{$ENDIF}
{$IFNDEF FPC}
{$ENDIF}
  Messages, Variants, Classes, Graphics, Controls, Forms, ExtCtrls, ToolWin,
  Grids, DB, StdCtrls, ComCtrls, Dialogs, Buttons, ExtDlgs, Menus, ClipBrd,
  Generics.Collections,
{$IFnDEF FPC}
  Vcl.DBCtrls, Vcl.DBGrids,
{$ELSE}
  DBCtrls, DBGrids,
{$ENDIF}
  DateUtils, IniFiles,
{$IFNDEF NOFASTREPORTS}
  frxCross, frxClass, frxDBSet,
{$ENDIF}
{$IFDEF ADO}
  ActiveX, ADODB, ADOConst, ADOInt,
{$ENDIF}
{$IFDEF FPC}
  {$IFDEF IBX}
    IBDatabase, IBTable, IBCustomDataSet, IBHeader, IBSQL, IBQuery,
    IBXConst,
  {$ENDIF}
{$ELSE}
  {$IFDEF IBX}
    IBX.IBDatabase, IBX.IBTable, IBX.IBCustomDataSet, IBX.IBHeader, IBX.IBSQL, IBX.IBQuery,
    IBX.IBVisualConst, IBX.IBXConst,
  {$ENDIF}
{$ENDIF}
{$IFDEF ZEOS}
  ZDbcIntfs, // ZConnection, ZDataset, ZSqlUpdate,
{$ENDIF}
{$IFDEF SQLdbFamily}
  SQLDB, SQLDBLib,
{$ENDIF}
{$IFDEF FPC}
  FileUtil, LazUTF8, LConvEncoding, {$IFDEF ZVComponents}ZVDateTimePicker, {$ENDIF}
{$ENDIF}
{$IFNDEF FPC}
  JPEG,
{$ENDIF}
  uDCLDownloader, uDCLMD5,
  uDCLMessageForm, uDCLSQLMonitor, uDCLQuery, uLogging, uDCLSysUtils,
  uStringParams, uDCLData, uDCLConst, uDCLTypes;

Type
  TDCLCommand=class;
  TDCLGrid=class;
  TDCLForm=class;
  TLogOnForm=class;
  TDCLOfficeReport=class;
  TDCLTextReport=class;
  TDCLBinStore=class;
  TBinStore=class;
  TFieldGroup=class;
  TDCLMainMenu=class;
  TVariables=class;

  {$IFDEF SQLdbFamily}
  Params=TParams;
  {$ENDIF}
  {$IFDEF ADO}
  Params=TParameters;
  {$ENDIF}

  { TDCLLogOn }

  TDCLLogOn=class
  private
    FDBLogOn: TDBLogOn;
{$IFDEF FPC}{$IFDEF SQLdbFamily}
    FSQLDBLibraryLoader: TSQLDBLibraryLoader;
{$ENDIF}{$ENDIF}
{$IFDEF TRANSACTIONDB}
    IBTransaction: TTransaction;
{$ENDIF}
    FDCLMainMenu: TDCLMainMenu;
    FMainForm: TForm;
    RoleOK: TLogOnStatus;
    SQLMon: TDCLSQLMon;
    KillerDog: TTimer;
    FBusyMode: Boolean;

    FAccessLevel: TUserLevelsType;
    FForms: TList<TDCLForm>;
    ShadowQuery: TDCLDialogQuery;
    PassRetries: Byte;
    MessagesTimer: TTimer;
    MessageFormObject: TMessageFormObject;
    ExitFlag, FUserID: Integer;
    TimeToExit: Cardinal;
    DCLSession: TDCLSession;
    Timer1: TTimer;
    VirtualScripts:array of RVirtualScript;

    function AddVirtualScript(Scr:RVirtualScript):Integer;
    function FindVirtualScript(ScriptName:String):Integer;

    function GetFormsCount: Integer;
    function GetForm(Index: Integer): TDCLForm;
    function LoadScrText(ScrName: String): TStringList;

    procedure GetUserName(AUserName: String);
    function CheckPass(UserName, EnterPass, Password: String): Boolean;

    procedure WaitNotify(Sender: TObject);
    procedure LoggingUser(Login: Boolean);
    procedure RunInitSkripts;

    function GetConnected: Boolean;

    procedure KillerForms(Sender:TObject);
    Function GetBusyMode:Boolean;
  public
    RoleRaightsLevel: Word;
    Variables: TVariables;
    EvalFormula: String;
    NewLogOn: Boolean;

    constructor Create(DBLogOn: TDBLogOn);
    destructor Destroy; override;

    procedure About(Sender: TObject);
    function Login(UserName, Password: String; ShowForm: Boolean): TLogOnStatus;
    procedure Lock;
    procedure WriteBaseUID;
    function GetBaseUID:String;

{$IFDEF TRANSACTIONDB}
    function NewTransaction(RW:TTransactionType): TTransaction;
{$ENDIF}

    function GetVirtualScript(ScriptName: String):RVirtualScript;
    function GetVirtualScriptNum(Index:Integer):RVirtualScript;

    function ReadConfig(ConfigName, UserID: String): String;
    procedure WriteConfig(ConfigName, NewValue, UserID: String);
    function TableExists(TableName: String): Boolean;

    procedure InitActions(Sender: TObject);
    procedure RunCommand(CommandName: String);
    procedure CreateMenu(MainForm: TForm);
    function CreateForm(FormName: String; ParentForm, CallerForm: TDCLForm; Command:TDCLCommand; Query: TDCLDialogQuery;
      Data: TDataSource; ModalMode: Boolean; ReturnValueMode: TChooseMode;
      ReturnValueParams: TReturnValueParams=nil; Script:TStringList=nil): TDCLForm;
    procedure CloseForm(Form: TDCLForm);
    procedure CloseFormNum(FormNum: Integer);
    procedure CloseAllForms;

    procedure SetDBName(var Query: TDCLDialogQuery);

    procedure NotifyForms(Action: TFormsNotifyAction);

    procedure GetTableNames(var List: TStrings);

    procedure RePlaseVariables(const Namespace: String; var VariablesSet: String);
    procedure TranslateVal(const Namespace: String; var S: String);
    procedure ExecVBS(VBSScript: String);
    procedure ExecShellCommand(ShellCommandText: String);

    function GetRolesQueryText(QueryType: TSelectType; WhereStr: String): String;

    function GetConfigInfo: String;
    function GetConfigVersion: String;
    function GetFullRaight: Word;
    function GetSecKeyData(Data: TMemoryStream; UserName: String): String;
    procedure SignScriptFile(FileName, UserName: String);
    procedure ReSignScriptFile(FileName: String);
    procedure RunSkriptFromFile(FileName: String);
    procedure ExtractScriptFile(FileName: String);

    procedure WriteBaseUIDtoINI(FileName, SectionName:string);
    
    function ConnectDB: Integer;
    procedure Disconnect;
    procedure ReconnectDB;

    property FormsCount: Integer read GetFormsCount;
    property MainForm: TForm read FMainForm;
    property Forms: TList<TDCLForm> read FForms;
    property AccessLevel: TUserLevelsType read FAccessLevel;
    property Connected: Boolean read GetConnected;
    property IsBusy:Boolean read GetBusyMode write FBusyMode;
  end;

  TVariables=class
  private
    FVariables: TList<TVariable>;
    FDCLLogOn: TDCLLogOn;
    FDCLForm: TDCLForm;

    function GetVariableByName(Const Namespace, VariableName: String): String; overload;
    procedure SetVariableByName(Const Namespace, VariableName, Value: String); overload;
    function GetVariableByName(Const VariableName: String): String; overload;
    procedure SetVariableByName(Const VariableName, Value: String); overload;
    function GetAllVariables: TList<TVariable>;
  public
    constructor Create(var DCLLogOn: TDCLLogOn; DCLForm: TDCLForm);
    destructor Destroy; override;

    procedure NewVariable(Const Namespace, VariableName: String; Value: String);
    procedure NewVariableWithTest(Const Namespace, VariableName: String);
    procedure FreeVariable(Const Namespace, VariableName: String);
    function Exists(Const Namespace, VariableName: String): Boolean;
    procedure RePlaseVariables(const Namespace: String; var VariablesSet: String; Query: TDCLDialogQuery);

    property Variables[Const Namespace, VariableName: String]: String read GetVariableByName
      write SetVariableByName;
    property VariablesList: TList<TVariable> read GetAllVariables;
  end;

  TMainFormAction=class
    procedure CloseMainForm(Sender: TObject; var { %H- } Action: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  end;

  TNoScrollBarDBGrid=class(TDCLDBGrid)
  end;

  TToolGrid=TNoScrollBarDBGrid;

  { TDCLGrid }

  TDCLGrid=class(TWinControl)
  private
    FromForm: String;
    FGridPanel: TDCLMainPanel;
    FDCLLogOn: TDCLLogOn;
    FForm: TDBForm;
    FDCLForm: TDCLForm;
    FGrid: TDCLDBGrid;
    FQueryGlob: TDCLQuery;
    FData: TDataSource;
    FDisplayMode: TDataControlType;
    FMultiSelect, FShowed, RefreshLock: Boolean;
    PreviousColumnIndex: Integer;
    PopupGridMenu: TPopupMenu;
    ItemMenu, ToItem: TMenuItem;
    Navig: TDBNavigator;
    FindGrid: TStringGrid;
    PosBookCreated, FReadOnly, FindProcess, PagePanelCreated: Boolean;
    FUserLevelLocal: TUserLevelsType;
    FOptions: TDBGridOptions;
    LabelField: TDialogLabel;
    FOrientation: TOrientation;
    PartButtonLeft, PartButtonTop, ToolPanelElementLeft: Word;
    EditField: TDBEdit;
    ColumnsList, FieldsList: TListBox;
    Splitter1, Splitter2: TSplitter;
    FindFields: TStringList;
    PagePanel, ToolPanel, FieldPanel: TDialogPanel;
    FTablePartsPages: TPageControl;
    FTablePartsTabs: TTabSheet;
    FLocalBookmark: TBookmark;
    SummString: String;
    PartTabIndex: TDCLGrid;
    FTableParts: TList<TDCLGrid>;
    MaxStepFields: Integer;
    NotAllowedOperations: TOperationsTypes;
    RowColor, RowTextColor: TColor;
    SummGrid: TToolGrid;
    SumQuery: TDCLDialogQuery;
    SumData: TDataSource;
    RefreshTimer: TTimer;
    LastStateTimer, BaseChanged: Boolean;
    MediaFields: TList<TFieldGroup>;
    KeyMarks: TKeyBookmarks;
    ButtonPanel: TDialogPanel;
    ToolButtonPanel: TToolBarPanel;
    ToolButtonsCount: Byte;
    ToolButtonPanelButtons: Array [1..ToolCommandsCount] of TDialogSpeedButton;
    ToolCommands: Array [1..ToolCommandsCount] of String;

    DateBoxes: TList<TDCLDateBox>;
    CheckBoxes: TList<TDCLCheckBox>;
    DBCheckBoxes: TList<TDBCheckBox>;
    Lookups: TList<TDCLLookup>;
    ContextFieldButtons: TList<TContextFieldButton>;
    RollBars: TList<TRollBar>;
    BrushColors: TList<TBrushColor>;
    ContextLists: TList<TContextList>;
    DropBoxes: TList<TDropBox>;
    LookupTables: TList<TLookupTable>;

    Events: TList<TDCLEvent>;

    StructModify: TList<TStructureModify>;
    OrderByFields: TList<String>;
    LayoutParams: TDCLLayoutParams;

    procedure RePlaseVariables(var VariablesSet: String);

    function GetNamespace: String;
    procedure ToolButtonsOnClick(Sender: TObject);

    function AddTablePart(Parent: TWinControl; Data: TDataSource; Style:TDataControlType): TDCLGrid;
    function GetSummQuery: String;
    function QueryBuilder(QueryMode: Byte): String;
    function GetFingQuery: String;
    function FindRaightQuery: String;
    procedure ChangePartTabPage(Sender: TObject);
    function GetTablePartsCount:Integer;

    procedure ClickNavig(Sender: TObject; Button: TNavigateBtn);
    procedure SortDB(Column: TColumn);

    procedure AutorefreshTimer(Sender: TObject);
    procedure SetBookMark(Sender: TObject);
    procedure PosToBookMark(Sender: TObject);
    procedure DeleteMenuBookMark(BookMarkNum: Integer);

    procedure SaveDB;
    procedure CancelDB;

    // DataEvents
    procedure AfterInsert(Data: TDataSet);
    procedure ScrollDB(Data: TDataSet);
    procedure AfterOpen(Data: TDataSet);
    procedure AfterClose(Data: TDataSet);
    procedure AfterEdit(Data: TDataSet);
    procedure AfterPost(Data: TDataSet);
    procedure AfterCancel(Data: TDataSet);

    procedure BeforeScroll(Data: TDataSet);
    procedure BeforeOpen(Data: TDataSet);
    procedure BeforePost(Data: TDataSet);

    procedure OnDelete(Data: TDataSet);
    procedure AfterRefresh(Data: TDataSet);
    // End DataEvents
    procedure ExecEvents(EventType: TEventsEnum);

    procedure RePlaseParams(var Params: String);

    procedure SetDataStatus(Status: TDataStatus);
    function GetSQL: String;
    procedure SetSQL(SQL: String);

    function GetDisplayMode: TDataControlType;
    procedure SetDisplayMode(DisplayMode: TDataControlType);
    function GetFieldCount: Integer;
    function GetQuery: TDCLQuery;
    procedure SetQuery(Query: TDCLQuery);
    procedure SetReadOnly(Value: Boolean);
    function GetReadOnly: Boolean;
    procedure SetGridOptions(Options: TDBGridOptions);
    procedure IncXYPos(StepTop, StepLeft: Word; Field: TDCLField);

    procedure DBEditClick(Sender: TObject);
    procedure EditClick(Sender: TObject);
    procedure EditOnFloatData(Sender: TObject; var Key: Char);
    procedure EditOnEdit(Sender: TObject);
    procedure OnChangeDateBox(Sender: TObject);
    procedure CheckOnClick(Sender: TObject);
    procedure GridDblClick(Sender: TObject);
    procedure LookupOnClick(Sender: TObject);
    procedure LookupDBScroll(Data: TDataSet);
    procedure ContextFieldButtonsClick(Sender: TObject);
    procedure RollBarOnChange(Sender: TObject);
    procedure ContextListKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ContextListChange(Sender: TObject);
    procedure DropListOnSelectItem(Sender: TObject);

    function GetColumns: TDBGridColumns;
    procedure SetColumns(Cols: TDBGridColumns);

    // procedure SetRequiredFields;

    procedure DeleteList(Index: Word);
    procedure ColumnsManege(Sender: TObject);
    procedure FieldsManege(Sender: TObject);

    procedure ExecFilter(Sender: TObject);
    procedure ExecComboFilter(Sender: TObject);
    procedure OnContextFilter(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure CalendarOnChange(Sender: TObject);
    procedure OnNotCheckClick(Sender: TObject);

    function GetTablePart(Index: Integer): TDCLGrid;
    procedure SetTablePart(Index: Integer; Value: TDCLGrid);

    procedure AddPopupMenuItem(Caption, ItemName: String; Action: TNotifyEvent;
      AChortCutKey: String; Tag: Integer; PictType: String);
    procedure AddSubPopupItem(Caption, ItemName: String; Action: TNotifyEvent;
      ToMenu, Tag: Integer);
    procedure GridDrawDataCell(Sender: TObject; Const Rect: TRect; DataCol: Integer;
      Column: TColumn; State: TGridDrawState);
    procedure SetMultiselect(Value: Boolean);
    function GetMultiselect: Boolean;
    function GetFieldDataType(FieldName: String): TFieldType;

    property FQuery: TDCLQuery read GetQuery write SetQuery;

    function GetCurrentPart: TDCLGrid;
  public
    QueryName, DependField, MasterDataField, MasterValueVariableName: String;
    NoDataField: Boolean;
    TabType: TPageType;
    CurrentTabIndex, Tag: Integer;
    DataFields: TList<TDCLParamsDataField>;
    QuerysStore: Array of TDCLQueryStore;
    DBFilters: TList<TDBFilter>;
    Calendars: TList<TDCLCalendar>;
    Edits: TList<TDCLEdit>;
    PartSplitter: TSplitter;

    constructor Create(var Form: TDCLForm; Parent: TWinControl; SurfType: TDataControlType;
      Query: TDCLDialogQuery; Data: TDataSource);
    destructor Destroy; override;

    procedure CreateFields(FOPL: TStringList);

    procedure RefreshBookMarkMenu;
    procedure CreateBookMarkMenu(MenuList: TStringList);
    function SaveBookMarkMenu: TStringList;
    procedure DeleteAllBookmarks;

    procedure OpenQuery(QText: String);
    procedure Open;
    procedure Close;
    procedure Show;
    procedure AddColumn(Field: TDCLField);
    procedure CreatePartColumns;
    procedure AddField(Field: TDCLField);
    procedure SetSQLToStore(SQL: String; QueryType: TQueryType; Raight: TUserLevelsType);
    function GetSQLFromStore(QueryType: TQueryType): String;
    procedure ReFreshQuery;
    procedure SetNewQuery(Data: TDataSource);

    procedure Structure(Sender: TObject);
    procedure PFind(Sender: TObject);
    procedure PSetFind(Sender: TObject);
    procedure PClearAllFind(Sender: TObject);
    procedure Print(Sender: TObject);
    procedure PCopy(Sender: TObject);
    procedure PCut(Sender: TObject);
    procedure PPaste(Sender: TObject);
    procedure PUndo(Sender: TObject);

    procedure AddLabel(Field: TDCLField; Caption: String);
    procedure AddEdit(Field: TDCLField);
    procedure AddFieldBox(Field: TDCLField; FieldBoxType: TFieldBoxType; NamePrefix: String);
    procedure AddDateBox(Field: TDCLField);
    procedure AddSimplyCheckBox(Field: TDCLField);
    procedure AddCheckBox(Field: TDCLField);
    procedure AddDBCheckBox(Field: TDCLField);
    procedure AddLookUp(Field: TDCLField);
    procedure AddContextButton(Field: TDCLField);
    procedure AddRollBar(Field: TDCLField);
    procedure AddBrushColor(OPL: String);
    procedure AddContextList(Field: TDCLField);
    procedure AddDropBox(Field: TDCLField);
    procedure AddSumGrid(OPL: String);
    procedure AddLookupTable(Field: TDCLField);
    procedure AddMediaFieldGroup(Parent: TWinControl; Align: TAlign; GroupType: TGroupType;
      var Field: TDCLField);

    function AddPartPage(Caption: String; Data: TDataSource; Style:TDataControlType): TDCLGrid;
    procedure AddToolPanel;
    procedure AddDBFilter(Filter: TDBFilter);
    procedure AddCalendar(Calendar: TDCLCalendar);
    procedure AddToolPartButton(ButtonParam: TButtonParam);
    procedure ClearNotAllowedOperations;
    procedure ExcludeNotAllowedOperation(Operation: TNotAllowedOperations);
    procedure AddNotAllowedOperation(Operation: TNotAllowedOperations);
    function FindNotAllowedOperation(Operation: TNotAllowedOperations): Boolean;

    procedure TranslateVal(var Params: String);

    procedure AddEvent(Event: TDCLEvent);

    property SQL: String read GetSQL write SetSQL;
    property DisplayMode: TDataControlType read GetDisplayMode write SetDisplayMode;
    property DataSource: TDataSource read FData;
    property Query: TDCLQuery read GetQuery;
    property FieldCount: Integer read GetFieldCount;
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly;
    property Options: TDBGridOptions read FOptions write SetGridOptions;
    property Columns: TDBGridColumns read GetColumns write SetColumns;
    property GridPanel: TDCLMainPanel read FGridPanel write FGridPanel;
    property Grid: TDCLDBGrid read FGrid;
    property TableParts:TList<TDCLGrid> read FTableParts;
    property TablePartsCount:Integer read GetTablePartsCount;
    property CurrentPart: TDCLGrid read GetCurrentPart;
    property MultiSelect: Boolean read GetMultiselect write SetMultiselect;
  end;

  { TFieldGroup }

  TFieldGroup=class
  private
    FData: TDataSource;
    ThumbPanel, ButtonPanel: TPanel;
    FieldCaption: TLabel;
    MemoField: TDBMemo;
    GraficField: TDBImage;
    RichField: {$IFDEF DELPHI}TDBRichEdit; {$ELSE}TDBMemo; {$ENDIF}
    FieldName: String;
    FGraphicFileType: TGraficFileType;
    FGroupType: TGroupType;
    LoadButton, SaveButton, ClearButton: TSpeedButton;
    OpenPictureDialog: TOpenPictureDialog;
    SavePictureDialog: TSavePictureDialog;
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;

    procedure Load(Sender: TObject);
    procedure Save(Sender: TObject);
    procedure Clear(Sender: TObject);

    procedure SaveData(FileName: String);
    procedure LoadData(FileName: String);

    procedure OnDBImageRead(Sender: TObject; S: TStream; var GraphExt: String);
  public
    constructor Create(Parent: TWinControl; Data: TDataSource; Field: TDCLField; LayoutParams: TDCLLayoutParams; aAlign: TAlign;
      GroupType: TGroupType);
    destructor Destroy; override;
  end;

  TDCLCommandButton=class
  private
    Commands: TList<TDCLCommandItem>;
    FDCLForm: TDCLForm;
    FDCLLogOn: TDCLLogOn;

    procedure ExecCommand(Sender: TObject);
  public
    constructor Create(var DCLLogOn: TDCLLogOn; var DCLForm: TDCLForm);
    destructor Destroy; override;

    procedure AddCommand(Parent: TWinControl; ButtonParams: TButtonParam);
  end;

  { TDCLForm }

  TDCLForm=class(TComponent)
  private
    SingleMod: Boolean;
    FName, CloseQueryText, Namespace: String;
    FCloseAction: TDCLFormCloseAction;
    FParentForm, FCallerForm: TDCLForm;
    UserLevelLocal: TUserLevelsType;
    FOPL: TStringList;
    FFormNum, FormHeight, FormWidth: Integer;
    TB: TFormPanelButton;
    FNewPage, NoVisual, NoStdKeys, FieldsSettingsReseted, SettingsLoaded,
    NoCloseable, CloseQuery, FormCanClose: Boolean;
    FForm: TDBForm;
    FDCLLogOn: TDCLLogOn;
    FGrids: TList<TDCLGrid>;
    MainPanel: TDCLMainPanel;
    IncButtonPanelHeight: Word;
    ButtonLeft, ButtonTop: Integer;
    FPages: TPageControl;
    FTabs: TTabSheet;
    GridIndex: TDCLGrid;
    DataGlob: TDataSource;
    DBStatus: TStatusBar;
    GridPanel: TDialogPanel;
    ParentPanel: TWinControl;
    ItemMenu, ToItem: TMenuItem;
    Commands: TDCLCommandButton;
    FCommand: TDCLCommand;
    EventsClose: TDCLEvent;
    FRetunValue: TReturnFormValue;
    FReturningMode: TChooseMode;
    FReturnValueParams: TReturnValueParams;
    FFormMenu: TMainMenu;
    FSeed:Integer;

    function AddGrid(Parent: TWinControl; SurfType: TDataControlType; Query: TDCLDialogQuery;
      Data: TDataSource): TDCLGrid;
    procedure AddMainPage(Query: TDCLDialogQuery; Data: TDataSource);
    procedure ChangeTabPage(Sender: TObject);

    function GetMainQuery: TDCLQuery;
    function GetDataSource: TDataSource;
    function GetPartQuery: TDCLQuery;

    function GetParentForm: TDCLForm;
    procedure ResizeDBForm(Sender: TObject);

    function GetTable(Index: Integer): TDCLGrid;
    procedure SetTable(Index: Integer; Value: TDCLGrid);
    function GetTablesCount: Integer;
    procedure ActivateForm(Sender: TObject);

    procedure ToolButtonClick(Sender: TObject);

    procedure CloseForm(Sender: TObject; var { %H- } Action: TCloseAction);
    procedure OnCloseQuery(Sender: TObject; var CanClose: Boolean);

    procedure ExecCommand(CommandName: String);

    function GetQueryToRaights(S: String): String;

    function ReadBaseINI(IniType:TINIType):TStringList;
    procedure WriteBaseINI(IniType:TINIType; Params:TStringList);
    procedure DeleteBaseINI(IniType:TINIType; All:Boolean);

    procedure LoadFormPos;
    procedure LoadFormPosINI;
    procedure LoadFormPosBase;
    procedure LoadFormPosUni(DialogParams: TStringList);
    procedure SaveFormPos;
    procedure SaveFormPosINI;
    procedure SaveFormPosBase;
    function SaveFormPosUni: TStringList;

    procedure DeleteFormPos(All:Boolean);
    procedure DeleteFormPosBase(All:Boolean);
    procedure DeleteFormPosINI(All:Boolean);
    procedure DeleteAllFormPos;

    procedure SaveBookMarkMenu;
    procedure SaveBookmarkMenuINI;
    procedure SaveBookmarkMenuBase;

    procedure LoadBookmarkMenu;
    procedure LoadBookmarkMenuINI;
    procedure LoadBookmarkMenuBase;

    procedure CreateBookMarkMenuUni(MenuList: TStringList);
    function SaveBookMarkMenuUni: TStringList;

    procedure AddSubItem(Caption, ItemName, Pict: String; Level: Integer; Action: TNotifyEvent);
    procedure AddMainItem(Caption, ItemName, Pict: String; Action: TNotifyEvent);

    procedure ResetFieldsSettings(Sender: TObject);
    procedure ResetAllFieldsSettings(Sender: TObject);
    procedure DeleteAllBookmarks(Sender: TObject);
    procedure SaveFieldsSettings(Sender: TObject);

    procedure AddEvents(EventType: TEventsEnum; EventsSet: String);
  public
    LocalVariables: TVariables;
    OnTop, NotDestroyedDCLForm, ExitNoSave: Boolean;
    FDialogName: String;
    ExitCode: Byte;

    constructor Create(DialogName: String; var DCLLogOn: TDCLLogOn; ParentForm, CallerForm: TDCLForm;
      Command:TDCLCommand; OPL: TStringList; Query: TDCLDialogQuery; Data: TDataSource;
      Modal:Boolean=False; ReturnValueMode: TChooseMode=chmNone;
      ReturnValueParams: TReturnValueParams=nil);
    destructor Destroy; override;

    function GetNamespace: String;
    procedure CloseDialog;
    procedure Choose;
    function GetActive: Boolean;

    procedure RePlaseVariables(var VariablesSet: String);
    procedure RePlaseParams(var Params: String);
    procedure TranslateVal(var Params: String; CheckParams: Boolean);
    procedure SetDBStatus(StatusStr: String);
    procedure AddStatus(StatusStr: String; Width: Integer);
    procedure SetStatus(StatusStr: String; StatusNum, Width: Integer);
    procedure SetStatusWidth(StatusNum, Width: Integer);
    procedure DeleteStatus(StatusNum: Integer);
    procedure DeleteAllStatus;
    procedure SetRecNo;
    procedure SetTabIndex(Index: Integer);
    procedure RefreshForm;
    procedure CloseDatasets;
    procedure ResumeDatasets;
    procedure SetVariable(VarName, VValue: String);
    procedure GetChooseValue;
    function ChooseAndClose(Action: TChooseMode): TReturnFormValue;
    function GetPreviosForm:TDCLForm;

    property DialogName: String read FName write FName;
    property CurrentQuery: TDCLQuery read GetMainQuery;
    property DataSource: TDataSource read GetDataSource;
    property CurrentPartQuery: TDCLQuery read GetPartQuery;
    property Tables[Index: Integer]: TDCLGrid read GetTable write SetTable;
    property TablesCount: Integer read GetTablesCount;
    property CurrentGridIndex: TDCLGrid read GridIndex;
    property Form: TDBForm read FForm;
    property ParentForm: TDCLForm read FParentForm;
    property FormNum: Integer read FFormNum;
    property ReturnFormValue: TReturnFormValue read FRetunValue;
    property CloseAction: TDCLFormCloseAction read FCloseAction write FCloseAction;
    property IsSingle: Boolean read SingleMod write SingleMod;
    property FormSeed: Integer read FSeed;
  end;

  { TDCLCommand }

  TDCLCommand=class(TObject)
  private
    FCommandDCL, Spool: TStringList;
    FDCLForm: TDCLForm;
    RetVal: TReturnFormValue;
    FDCLLogOn: TDCLLogOn;
    DCLQuery, DCLQuery2: TDCLDialogQuery;
    Executed, StopFlag, Breaking: Boolean;
    TextReport: TDCLTextReport;
    OfficeReport: TDCLOfficeReport;
    BinStore: TBinStore;
    _Namespace, SpoolFileName: String;
    Downloader: TDownloader;

    procedure ExportData(Tagert: TSpoolType; Scr: String);
    procedure RePlaseVariabless(var Variables: String);
    procedure RePlaseParamss(var ParamsSet: String; Query: TDCLDialogQuery);
    procedure SetValue(S: String);
    function ExpressionParser(Expression: String): String;
    function GetRaightsByContext(InContext: Boolean): TUserLevelsType;
    procedure TranslateVals(var Params: String; Query: TDCLDialogQuery);
    procedure TranslateValContext(var Params: String);
    procedure RunSkriptFromFile(FileName: String);
    procedure ExtractScriptFile(FileName: String);
  public
    constructor Create(DCLForm: TDCLForm; var DCLLogOn: TDCLLogOn);
    destructor Destroy; override;

    procedure ExecSQLCommand(SQLCommand: String; InContext: Boolean);
    procedure SetVariable(VarName, VValue: String);

    procedure ExecCommand(Command: String; DCLForm: TDCLForm);
    procedure SetNamespace(const Namespace: String);
    function GetNamespace: String;
  end;

  { TDCLMainMenu }

  TDCLMainMenu=class(TObject)
  private
    ItemMenu, ToItem: TMenuItem;
    FDCLLogOn: TDCLLogOn;
    FMainForm: TForm;
    FMainMenu: TMainMenu;
    FForm: TForm;
    MainFormStatus: TStatusBar;
    FormBar: TToolBar;
    MainFormAction: TMainFormAction;

    procedure ExecCommand(Command: String);
    procedure AddMainItem(Caption, ItemName: String);
    procedure AddSubItem(Caption, ItemName: String; Level: Integer);
    procedure AddSubSubItem(Caption, ItemName: String; Level, Index: Integer);
    function FindMenuItemIndex(ItemName: String): Integer;
    function FindSubMenuItemIndex(ItemName: String; Level: Integer): Integer;
  public
    constructor Create(var DCLLogOn: TDCLLogOn; Form: TForm; Relogin: Boolean=False);
    destructor Destroy; override;

    procedure ClickMenu(Sender: TObject);
    procedure UpdateFormBar;

    procedure LockMenu;
    procedure UnLockMenu;
    procedure ChoseRunType(Command, DCLText, Name: String; Order: Byte);

    property MainForm: TForm read FMainForm;
  end;

  TLogOnForm=class(TObject)
  private
    RoleForm: TForm;
    Panel: TPanel;
    DCLLogo: TImage;
    RoleNameCombo: TComboBox;
    RoleNameEdit, RolePassEdit: TEdit;
    RoleLabel: TDialogLabel;
    RoleButtonOK, RoleButtonCancel, ChangePassButton: TDialogButton;
    RolesQuery1: TDCLDialogQuery;
    FDCLLogOn: TDCLLogOn;
    PressOK: TPassStatus;
    FEnterPassword, FUserName: String;
    ChangePassForm: TForm;
    OldPassEdit, NewPassEdit1, NewPassEdit2: TEdit;
    OkButton, CancelButton: TDialogButton;
    LabelPass: TDialogLabel;
    HashPassChk: TCheckbox;
    CountShowRole: Word;
    HashPass, FormCreated, NoShowRoleField: Boolean;

    procedure ChangePass(Sender: TObject);

    procedure OnShowForm(Sender: TObject);
    procedure OnCloseForm(Sender: TObject; var { %H- } Action: TCloseAction);
    procedure OnCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure OkButtonClick(Sender: TObject);
    procedure CancelButtonClick(Sender: TObject);
    procedure OkChangePass(Sender: TObject);
    procedure CancelChangePass(Sender: TObject);
    procedure OnSetHashPassword(Sender: TObject);

    procedure ShowChangePasswordForm;
    procedure ChangePassword(AUserID, NewPassword: String);
  public
    constructor Create(var DCLLogOn: TDCLLogOn; UserName: String; NoClose, Relogin: Boolean);
    destructor Destroy; override;

    procedure CreateForm(NoClose, Relogin: Boolean; UserName: String);
    procedure ShowForm;

    property EnterPass: String read FEnterPassword;
    property UserName: String read FUserName;
  end;

  TPrintBase=class(TObject)
    procedure Print(Grid: TDCLDBGrid; Query: TDCLDialogQuery; Caption: String);
  end;

  { TDCLTextReport }

  TDCLTextReport=class(TObject)
  private
    FReportQuery: TDCLDialogQuery;
    GrabValueForm: TForm;
    VarsToControls: Array of String;
    FSaved: Boolean;
    _NameSpace:String;

    procedure RePlaseVariables(var VarsSet: String);
    procedure GrabValListOnChange(Sender: TObject);
    procedure GrabDateOnChange(Sender: TObject);

    procedure GrabDialogButtonsOnClick(Sender: TObject);

    procedure ValComboOnChange(Sender: TObject);
    procedure GrabValOnEdit(Sender: TObject);

    function SetVarToControl(VarName: String): Integer;
  public
    InConsoleCodePage:Boolean;

    constructor InitReport(const NameSpace: String; DCLLogOn: TDCLLogOn; DCLGrid: TDCLGrid; OPL: TStringList;
      ParamsSet: Cardinal; Mode: TNewQueryMode);
    destructor Destroy; override;

    procedure CloseReport(FileName: String);

    procedure OpenReport(FileName: String; ViewMode: TReportViewMode);
    procedure PrintigReport;
    procedure ReplaseRepParams(var ReplaseText: TStringList);
    function TranslateRepParams(ParamName: String): String;
    function SaveReport(FileName: String): String;

    property DialogRes: TModalResult read FDialogRes;
  end;

  TDCLOfficeReport=class(TObject)
  private
    BinStor: TDCLBinStore;
    FDCLLogOn: TDCLLogOn;
    FDCLGrid: TDCLGrid;
    OO, NF, Loc, Sheets, Sheet, Cell, Range, Desktop, Document, VariantArray: Variant;
{$IFDEF MSWINDOWS}
    MsWord, Excel, WBk: OleVariant;
{$ENDIF}
  public
    OfficeDocumentFormat: TOfficeDocumentFormat;
    OfficeFormat: TOfficeFormat;

    constructor Create(DCLLogOn: TDCLLogOn; DCLGrid: TDCLGrid);
    destructor Destroy; override;

    procedure ReportOpenOfficeWriter(ParamStr: String; Save, Close: Boolean);
    procedure ReportOpenOfficeCalc(ParamStr: String; Save, Close: Boolean);
    procedure ReportWord(ParamStr: String; Save, Close: Boolean);
    procedure ReportExcel(ParamStr: String; Save, Close: Boolean);
  end;

  { TBaseBinStore }

  TBaseBinStore=class(TObject)
  private
    FErrorCode: Byte;
    FDCLLogOn: TDCLLogOn;
    DCLQuery: TDCLQuery;
    FTableName, FKeyField, FNameField, FDataField: String;
  public
    constructor Create(DCLLogOn: TDCLLogOn; TableName, KeyField, NameField, DataField: String);
    destructor Destroy; override;

    function GetData(DataName: String; FindType: TFindType): TMemoryStream;
    procedure SetData(DataName, Data: String; FindType: TFindType; Stream: TMemoryStream;
      Compress: Boolean);
    function IsDataExist(DataName: String; FindType: TFindType): Boolean;
    procedure DeleteData(DataName: String; FindType: TFindType);
    procedure ClearData(DataName: String; FindType: TFindType);

    procedure StoreFromFile(FileName, DataName, Data: String; FindType: TFindType;
      Compress: Boolean);
    procedure SaveToFile(FileName, DataName: String; FindType: TFindType);

    procedure CompressData(DataName, Data: String; FindType: TFindType);
    procedure DeCompressData(DataName, Data: String; FindType: TFindType);

    function MD5(DataName: String; FindType: TFindType): String;

    property ErrorCode: Byte read FErrorCode;
  end;

  { TBinStore }

  TBinStore=class(TBaseBinStore)
  private
    FFindType: TFindType;
  public
    constructor Create(DCLLogOn: TDCLLogOn; FindType: TFindType;
      TableName, KeyField, NameField, DataField: String);
    destructor Destroy; override;

    procedure StoreFromFile(FileName, DataName, Data: String; Compress: Boolean);
    procedure SaveToFile(FileName, DataName: String);

    function GetData(DataName: String): TMemoryStream;
    procedure SetData(DataName, Data: String; Stream: TMemoryStream; Compress: Boolean);
    function IsDataExist(DataName: String): Boolean;
    procedure DeleteData(DataName: String);
    procedure ClearData(DataName: String);

    procedure CompressData(DataName, Data: String);
    procedure DeCompressData(DataName, Data: String);

    function MD5(DataName: String): String;
  end;

  { TDCLBinStore }

  TDCLBinStore=class(TBinStore)
  private
    //
  public
    constructor Create(DCLLogOn: TDCLLogOn);
    destructor Destroy; override;

    function GetTemplateFile(Template, FileName, Ext: String): String;

    procedure StoreFromFile(FileName, DataName: String; Compress: Boolean);
    procedure SaveToFile(FileName, DataName: String);

    procedure DeleteData(DataName: String);
    procedure ClearData(DataName: String);

    procedure CompressData(DataName: String);
    procedure DeCompressData(DataName: String);

    function MD5(DataName: String): String;
  end;

{$IFDEF EMBEDDED}
  procedure InitDCL(DBLogOn: TDBLogOn);
{$ENDIF}
  procedure EndDCL;

{$IFNDEF FPC}
{$R units\dbgrids.res}
{$R units\dbctrls.res}
{$ENDIF}

var
  DCLMainLogOn: TDCLLogOn;
  Logger: TLogging;

implementation

Uses
  uDCLUtils, uDCLMultiLang, SumProps, uDCLDBUtils, uDCLOfficeUtils, uLZW;

{ TVariables }

procedure TVariables.SetVariableByName(Const Namespace, VariableName, Value: String) overload;
begin
end;

procedure TVariables.SetVariableByName(Const VariableName, Value: String) overload;
begin
end;

function TVariables.GetVariableByName(Const VariableName: String): String;
begin
end;

function TVariables.GetVariableByName(Const Namespace, VariableName: String): String overload;
begin
end;

constructor TVariables.Create(var DCLLogOn: TDCLLogOn; DCLForm: TDCLForm);
begin
end;

destructor TVariables.Destroy;
begin
end;


{ TLogOnForm }

procedure TLogOnForm.CancelButtonClick(Sender: TObject);
begin
end;

procedure TLogOnForm.CancelChangePass(Sender: TObject);
begin
end;

procedure TLogOnForm.ChangePass(Sender: TObject);
begin
end;

procedure TLogOnForm.ChangePassword(AUserID, NewPassword: String);
begin
end;

destructor TLogOnForm.Destroy;
begin
end;

constructor TLogOnForm.Create(var DCLLogOn: TDCLLogOn; UserName: String; NoClose, Relogin: Boolean);
begin
end;

procedure TLogOnForm.CreateForm(NoClose, Relogin: Boolean; UserName: String);
begin
end;

procedure TLogOnForm.OkButtonClick(Sender: TObject);
begin
end;

procedure TLogOnForm.OkChangePass(Sender: TObject);
begin
end;

procedure TLogOnForm.OnCloseForm(Sender: TObject; var Action: TCloseAction);
begin
end;

procedure TLogOnForm.OnCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
end;

procedure TLogOnForm.OnSetHashPassword(Sender: TObject);
begin
end;

procedure TLogOnForm.OnShowForm(Sender: TObject);
begin
end;

procedure TLogOnForm.ShowChangePasswordForm;
begin
end;

procedure TLogOnForm.ShowForm;
begin
end;

{ TDCLForm }

procedure TDCLForm.ActivateForm(Sender: TObject);
begin
end;

function TDCLForm.AddGrid(Parent: TWinControl; SurfType: TDataControlType; Query: TDCLDialogQuery;
  Data: TDataSource): TDCLGrid;
begin
end;

procedure TDCLGrid.AddNotAllowedOperation(Operation: TNotAllowedOperations);
begin
end;

procedure TDCLForm.AddMainPage(Query: TDCLDialogQuery; Data: TDataSource);
begin
end;

procedure TDCLForm.AddStatus(StatusStr: String; Width: Integer);
begin
end;

procedure TDCLForm.ChangeTabPage(Sender: TObject);
begin
end;

destructor TDCLForm.Destroy;
begin
end;

procedure TDCLForm.CloseForm(Sender: TObject; var Action: TCloseAction);
begin
end;

procedure TDCLForm.ExecCommand(CommandName: String);
begin
end;

function TDCLForm.GetQueryToRaights(S: String): String;
begin
end;

procedure TDCLForm.LoadFormPos;
begin
end;

procedure TDCLForm.LoadFormPosINI;
begin
end;

procedure TDCLForm.LoadFormPosBase;
begin
end;

procedure TDCLForm.LoadFormPosUni(DialogParams: TStringList);
begin
end;

procedure TDCLForm.OnCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
end;

procedure TDCLForm.SaveFormPos;
begin
end;

procedure TDCLForm.SaveFormPosINI;
begin
end;

procedure TDCLForm.SaveFormPosBase;
begin
end;

function TDCLForm.SaveFormPosUni: TStringList;
begin
end;

procedure TDCLForm.SaveBookMarkMenu;
begin
end;

procedure TDCLForm.SaveBookmarkMenuINI;
begin
end;

procedure TDCLForm.SaveBookmarkMenuBase;
begin
end;

procedure TDCLForm.LoadBookmarkMenu;
begin
end;

procedure TDCLForm.LoadBookmarkMenuINI;
begin
end;

procedure TDCLForm.LoadBookmarkMenuBase;
begin
end;

procedure TDCLForm.CreateBookMarkMenuUni(MenuList: TStringList);
begin
end;

function TDCLForm.SaveBookMarkMenuUni: TStringList;
begin
end;

procedure TDCLForm.AddSubItem(Caption, ItemName, Pict: String; Level: Integer;
  Action: TNotifyEvent);
begin
end;

procedure TDCLForm.AddMainItem(Caption, ItemName, Pict: String; Action: TNotifyEvent);
begin
end;

procedure TDCLForm.ResetAllFieldsSettings(Sender: TObject);
begin
  If ShowErrorMessage(10, GetDCLMessageString(msResetAllFieldsSettingsQ))=1 Then
  begin
    FieldsSettingsReseted:=True;
    DeleteAllFormPos;
  end;
end;

procedure TDCLForm.ResetFieldsSettings(Sender: TObject);
begin
  If ShowErrorMessage(10, GetDCLMessageString(msResetFieldsSettingsQ))=1 Then
  begin
    FieldsSettingsReseted:=True;
    DeleteFormPos(False);
  end;
end;

procedure TDCLForm.DeleteAllBookmarks(Sender: TObject);
begin
end;

procedure TDCLForm.DeleteAllFormPos;
begin
end;

procedure TDCLForm.SaveFieldsSettings(Sender: TObject);
begin
end;

procedure TDCLForm.AddEvents(EventType: TEventsEnum; EventsSet: String);
begin
end;

constructor TDCLForm.Create(DialogName: String; var DCLLogOn: TDCLLogOn; ParentForm, CallerForm: TDCLForm;
  Command:TDCLCommand; OPL: TStringList; Query: TDCLDialogQuery; Data: TDataSource;
  Modal:Boolean=False; ReturnValueMode: TChooseMode=chmNone;
  ReturnValueParams: TReturnValueParams=nil);
var
  ScrStr, TmpStr, tmpStr2, tmpSQL, tmpSQL1: String;
  DisplayMode, tmpStyle: TDataControlType;
  QCreated, ModalOpen: Boolean;
  OPLLinesCount, ScrStrNum, v1, v2, v3, v4, v5, aFormNum: Integer;
  IsDigitType: TIsDigitType;
  ShadowQuery: TDCLDialogQuery;
  FFilter: TDBFilter;
  Calendar: TDCLCalendar;
  UserLevel: TUserLevelsType;
  ButtonParams: TButtonParam;
  FField: TDCLField;
  FieldsOPL: TStringList;
  guid:TGUID;
  grid, PartGrid: TDCLGrid;

begin
  FDCLLogOn:=DCLLogOn;
  NoCloseable:=False;
  FormCanClose:=True;
  FCloseAction:=fcaNone;
  FCommand:=Command;
  FGrids:=TList<TDCLGrid>.Create;
  aFormNum:=FDCLLogOn.FormsCount;

  Namespace:='';
  if Assigned(CallerForm) then
    Namespace:=CallerForm.GetNamespace
  else if Assigned(ParentForm) then
    Namespace:=ParentForm.GetNamespace;

  if Assigned(Command) then
    Namespace:=Command.GetNamespace;

  FForm.DisableAlign;

  AddMainItem(InitCap(GetDCLMessageString(msSettings)), 'SettingsMenuItem',
    'Tools', nil);
  AddSubItem(GetDCLMessageString(msResetFieldsSettings), 'ResetFieldsSettings', '', 0, ResetFieldsSettings);
  AddSubItem(GetDCLMessageString(msResetAllFieldsSettings), 'ResetAllFieldsSettings', '', 0, ResetAllFieldsSettings);
  AddSubItem(GetDCLMessageString(msDeleteAllBookmarks), 'DeleteAllBookmarks', '', 0, DeleteAllBookmarks);

  AddSubItem('-', 'Splitter76113C76B41E4', '', 0, nil);
  AddSubItem(GetDCLMessageString(msSaveFieldsSettings), 'SaveFieldsSettings', '', 0, SaveFieldsSettings);

{$IFNDEF EMBEDDED}
  If Assigned(Application.MainForm) then
    If Application.MainForm.FormStyle=fsMDIForm Then
      FForm.FormStyle:=fsMDIChild;
{$ENDIF}
{$IFDEF MSWINDOWS}
  SetWindowLong(FForm.Handle, GWL_EXSTYLE, GetWindowLong(FForm.Handle, GWL_EXSTYLE)or
      WS_EX_APPWINDOW);
{$ENDIF}
{$IFDEF DCLDEBUG}
  FForm.Show;
{$ENDIF}


  If Length(FOPL.Text)>3 Then
  begin
    QCreated:=True;
    ScrStrNum:=0;
    OPLLinesCount:=FOPL.Count;
    GPT.CurrentRunningScrString:=0;

    While ScrStrNum<OPLLinesCount do
    begin
      ScrStr:=Trim(FOPL[ScrStrNum]);
      inc(GPT.CurrentRunningScrString);


      If PosEx('AutoRefresh;', ScrStr)=1 Then
      begin
        TranslateVal(ScrStr, True);
        GridIndex.RefreshTimer:=TTimer.Create(GridIndex);
        GridIndex.RefreshTimer.Interval:=AutoResfreshInterval;
        GridIndex.RefreshTimer.OnTimer:=GridIndex.AutorefreshTimer;
        GridIndex.RefreshTimer.Enabled:=True;
        GridIndex.LastStateTimer:=False;
      end;

      If PosEx('AutoRefresh=', ScrStr)=1 Then
      begin
        TranslateVal(ScrStr, True);
        tmpSQL:=ScrStr;
        RePlaseVariables(tmpSQL);
        FDCLLogOn.RePlaseVariables(Namespace, tmpSQL);
        v1:=StrToIntEx(FindParam('AutoRefresh=', tmpSQL))*1000;
        If v1>0 Then
        begin
          GridIndex.RefreshTimer:=TTimer.Create(GridIndex);
          GridIndex.RefreshTimer.Interval:=v1;
          GridIndex.RefreshTimer.OnTimer:=GridIndex.AutorefreshTimer;
          GridIndex.RefreshTimer.Enabled:=True;
          GridIndex.LastStateTimer:=False;
        end;
      end;


      If PosEx('QueryKeyField=', ScrStr)=1 Then
      begin
        TranslateVal(ScrStr, True);
        GridIndex.KeyMarks.KeyField:=FindParam('QueryKeyField=', ScrStr);
        GridIndex.KeyMarks.TitleField:=FindParam('TitleField=', ScrStr);
        If GridIndex.KeyMarks.TitleField='' Then
          GridIndex.KeyMarks.TitleField:=GridIndex.KeyMarks.KeyField;
      end;

      If PosEx('ExitNoSave=', ScrStr)=1 Then
      begin
        TranslateVal(ScrStr, True);
        tmpSQL:=FindParam('exitnosave=', ScrStr);
        If tmpSQL='1' Then
          ExitNoSave:=True;
      end;

      If PosEx('SetFieldValue=', ScrStr)=1 Then
      begin
        ExecCommand(ScrStr);
      end;

      If PosEx('SetMainFormCaption=', ScrStr)=1 Then
      begin
        ExecCommand(ScrStr);
      end;

      If PosEx('FormHeight=', ScrStr)=1 Then
      begin
        TranslateVal(ScrStr, True);
        FormHeight:=StrToIntEx(FindParam('FormHeight=', ScrStr));
        FForm.ClientHeight:=FormHeight;
      end;

      If PosEx('FormWidth=', ScrStr)=1 Then
      begin
        TranslateVal(ScrStr, True);
        FormWidth:=StrToIntEx(FindParam('FormWidth=', ScrStr));
        FForm.ClientWidth:=FormWidth;
      end;

      If PosEx('SeparateChar=', ScrStr)=1 Then
      begin
        GPT.StringTypeChar:=FindParam('SeparateChar=', ScrStr);
      end;

      If PosEx('SetValueSeparator=', ScrStr)=1 Then
      begin
        TranslateVal(ScrStr, True);
        GPT.GetValueSeparator:=FindParam('SetValueSeparator=', ScrStr);
      end;

      If PosEx('CloseQuery=', ScrStr)=1 Then
      begin
        CloseQueryText:=FindParam('CloseQuery=', ScrStr);
        CloseQuery:=True;
      end;


      If (PosEx('UniqueTable=', ScrStr)=1)or
        (PosSet('UpdateResync=,LockType=,CursorType=', ScrStr)=1)or(PosEx('UniqueTable=', ScrStr)=1)
        or(PosEx('UpdateQuery=', ScrStr)=1)or
        (PosSet('AutoApply=,CashBase=,Live=,ParamCheck=', ScrStr)<>0)or
        (PosEx('UpdateTable=', ScrStr)=1) Then
      begin
        TranslateVal(ScrStr, True);
        If Assigned(GridIndex.FQuery) Then
          GridIndex.FQuery.SetUpdateSQL(FindParam('UpdateTable=', ScrStr),
            FindParam('KeyFields=', ScrStr));
        // FillDatasetUpdateSQL(FGrids[GridIndex].FQuery, {$IFDEF UPDATESQLDB}FGrids[GridIndex].UpdateSQL,{$ENDIF} ScrStr, FGrids[GridIndex].FUserLevelLocal, FGrids[GridIndex]);
      end;



      If PosEx('GetFieldValue=', ScrStr)=1 Then
      begin
        ExecCommand(ScrStr);
      end;

      If PosEx('GetValue=', ScrStr)=1 Then
      begin
        ExecCommand(ScrStr);
      end;


      If PosEx('Caption=', ScrStr)=1 Then
      begin
        If GPT.MainFormCaption<>'' then
          FForm.Caption:=FForm.Caption+' \'+Trim(GPT.MainFormCaption)+'\';
      end;

      If PosEx('ApplicationTitle=', ScrStr)=1 Then
      begin
        TranslateVal(ScrStr, True);
        tmpSQL:=FindParam('ApplicationTitle=', ScrStr);
        Application.Title:=tmpSQL;
      end;

      If PosEx('Debug;', ScrStr)=1 Then
      begin
        GPT.DebugOn:=Not GPT.DebugOn;
      end;

      If PosEx('Events=', ScrStr)=1 Then
      begin
        TranslateVal(ScrStr, True);


        If PosEx('BeforePostEvents=', ScrStr)<>0 Then
        begin
          TmpStr:=FindParam('BeforePostEvents=', ScrStr);
          AddEvents(evtBeforePost, TmpStr);
        end;



        If PosEx('BeforeScrollEvents=', ScrStr)<>0 Then
        begin
          TmpStr:=FindParam('BeforeScrollEvents=', ScrStr);
          AddEvents(evtBeforeScroll, TmpStr);
        end;


        If PosEx('InsertEvents=', ScrStr)<>0 Then
        begin
          TmpStr:=FindParam('InsertEvents=', ScrStr);
          AddEvents(evtInsert, TmpStr);
        end;

        If PosEx('DeleteEvents=', ScrStr)<>0 Then
        begin
          TmpStr:=FindParam('DeleteEvents=', ScrStr);
          AddEvents(evtDelete, TmpStr);
        end;


        If PosEx('InsertPartEvents=', ScrStr)<>0 Then
        begin
          TmpStr:=FindParam('InsertPartEvents=', ScrStr);
          AddEvents(evtInsert, TmpStr);
        end;

        If PosEx('ScrollPartEvents=', ScrStr)<>0 Then
        begin
          TmpStr:=FindParam('ScrollPartEvents=', ScrStr);
          AddEvents(evtScrollPart, TmpStr);
        end;

        If PosEx('PostPartEvents=', ScrStr)<>0 Then
        begin
          TmpStr:=FindParam('PostPartEvents=', ScrStr);
          AddEvents(evtPostPart, TmpStr);
        end;
      end;



      If PosEx('Color=', ScrStr)=1 Then
      begin
        GridIndex.AddBrushColor(ScrStr);
      end;

      If PosEx('sqlmoon;', ScrStr)=1 Then
      begin
        FDCLLogOn.SQLMon.TrraceStatus:=Not FDCLLogOn.SQLMon.TrraceStatus;
      end;

      /// /========================================Fields========================================

      /// //////////////////////////////
      inc(ScrStrNum);
{$IFDEF DCLDEBUG2}
      Application.ProcessMessages;
      Sleep(1000);
{$ENDIF}
    end;

  end;
end;

procedure TDCLForm.DeleteAllStatus;
var
  i: Integer;
begin
  If DBStatus.Panels.Count>2 Then
    For i:=3 to DBStatus.Panels.Count do
      DeleteStatus(i-1);
end;

procedure TDCLForm.DeleteBaseINI(IniType: TINIType; All:Boolean);
begin
end;

procedure TDCLForm.DeleteFormPos(All:Boolean);
begin
end;

procedure TDCLForm.DeleteFormPosBase(All:Boolean);
begin
end;

procedure TDCLForm.DeleteFormPosINI(All:Boolean);
begin
end;

procedure TDCLForm.DeleteStatus(StatusNum: Integer);
begin
  If StatusNum<0 Then
    StatusNum:=DBStatus.Panels.Count-1;
  If Assigned(DBStatus) Then
    If (DBStatus.Panels.Count>StatusNum)and(StatusNum>1) Then
    begin
      DBStatus.Panels.Delete(StatusNum);
    end;
end;

function TDCLGrid.FindNotAllowedOperation(Operation: TNotAllowedOperations): Boolean;
begin
end;

function TDCLForm.GetActive: Boolean;
begin
end;

function TDCLForm.GetDataSource: TDataSource;
begin
end;

function TDCLForm.GetMainQuery: TDCLQuery;
begin
end;

function TDCLForm.GetParentForm: TDCLForm;
begin
end;

function TDCLForm.GetPartQuery: TDCLQuery;
begin
end;

function TDCLForm.GetPreviosForm: TDCLForm;
begin
end;

function TDCLForm.GetTable(Index: Integer): TDCLGrid;
begin
end;

function TDCLForm.GetTablesCount: Integer;
begin
end;

function TDCLForm.ReadBaseINI(IniType: TINIType):TStringList;
begin
end;

procedure TDCLForm.RefreshForm;
begin
end;

procedure TDCLForm.CloseDatasets;
begin
end;

function TDCLForm.GetNamespace: String;
begin
end;

procedure TDCLForm.CloseDialog;
begin
end;

procedure TDCLForm.ResumeDatasets;
begin
end;

procedure TDCLForm.RePlaseParams(var Params: String);
begin
end;

procedure TDCLForm.RePlaseVariables(var VariablesSet: String);
begin
end;

procedure TDCLForm.ResizeDBForm(Sender: TObject);
begin
end;

procedure TDCLForm.SetDBStatus(StatusStr: String);
begin
end;

procedure TDCLForm.SetRecNo;
begin
  If GetActive Then
    If Assigned(DBStatus) Then
    begin
      DBStatus.Panels[0].Text:=IntToStr(CurrentQuery.RecNo)+'/'+IntToStr(CurrentQuery.RecordCount);
    end;
end;

procedure TDCLForm.SetStatus(StatusStr: String; StatusNum, Width: Integer);
begin
end;

procedure TDCLForm.SetStatusWidth(StatusNum, Width: Integer);
begin
end;

procedure TDCLForm.SetTabIndex(Index: Integer);
begin
end;

procedure TDCLForm.SetTable(Index: Integer; Value: TDCLGrid);
begin
end;

procedure TDCLForm.SetVariable(VarName, VValue: String);
begin
end;

procedure TDCLForm.GetChooseValue;
begin
end;

procedure TDCLForm.Choose;
begin
end;

function TDCLForm.ChooseAndClose(Action: TChooseMode): TReturnFormValue;
begin
end;

procedure TDCLForm.ToolButtonClick(Sender: TObject);
begin
end;

procedure TDCLForm.TranslateVal(var Params: String; CheckParams: Boolean);
begin
end;

procedure TDCLForm.WriteBaseINI(IniType: TINIType; Params:TStringList);
begin
end;

{ TDCLCommand }

procedure TDCLCommand.SetVariable(VarName, VValue: String);
begin
end;

procedure TDCLCommand.TranslateVals(var Params: String; Query: TDCLDialogQuery);
begin
end;

procedure TDCLCommand.TranslateValContext(var Params: String);
begin
end;

constructor TDCLCommand.Create(DCLForm: TDCLForm; var DCLLogOn: TDCLLogOn);
begin
end;

destructor TDCLCommand.Destroy;
begin
end;

procedure TDCLCommand.SetNamespace(const Namespace: String);
begin
end;

function TDCLCommand.GetNamespace: String;
begin
end;

procedure TDCLCommand.ExecCommand(Command: String; DCLForm: TDCLForm);
var
  ModalOpen, InContext, Enything, EnythingElse, DownLoadCancel, DownloadProgress: Boolean;
  RecCount, ScriptStrings, RetPoint, v1, v2, v3, RepIdParams: Integer;
  ScrStr, TmpStr, tmpStr1, tmpStr2, tmpStr3, tmp1, tmp2, tmp3, tmp4, RepTable: String;
  OpenDialog: TOpenDialog;
  SaveDialog: TSaveDialog;
  tmpDCL: TStringList;
  tmpDCLForm:TDCLForm;
  nextLine:Boolean;
  localCommand: TDCLCommand;
  Edit: TDCLEdit;

  procedure GotoGoto(LabelName: String);
  var
    StringNum: Integer;
  begin
    For StringNum:=0 to FCommandDCL.Count-1 do
      If CompareString(FCommandDCL[StringNum], ':'+LabelName+';') Then
      begin
        ScriptStrings:=StringNum;
        break;
      end;
  end;

  procedure SetRetPoint;
  begin
    RetPoint:=ScriptStrings;
  end;

  procedure GetRetPoint;
  begin
    If RetPoint<> - 1 Then
    begin
      ScriptStrings:=RetPoint-1;
    end;
  end;

begin
  IfCounter:=0;
  If CompareString(Command, 'SQLMon_Clear') Then
  begin
    FDCLLogOn.SQLMon.Clear;
    Executed:=True;
  end;

  If CompareString(Command, 'SQLMon') Then
  begin
    FDCLLogOn.SQLMon.TrraceStatus:=Not FDCLLogOn.SQLMon.TrraceStatus;
    Executed:=True;
  end;

  If Not Executed Then
  begin

    StopFlag:=False;
    Breaking:=False;

    If FCommandDCL.Count<>0 Then
    begin
      GPT.CurrentRunningCmdString:=0;
      ScriptStrings:=0;
      RetPoint:= - 1;
      While ScriptStrings<FCommandDCL.Count do
      begin
        GPT.CurrentRunningCmdString:=ScriptStrings;

        ScrStr:=FCommandDCL[ScriptStrings];

        nextLine:=False;
        If Pos('//', ScrStr)=1 Then
        begin
          nextLine:=True;
        end;

        if not nextLine then
        begin
          TranslateValContext(ScrStr);

          If Not StopFlag Then
          begin
            If (PosEx('About;', ScrStr)=1)or(PosEx('Version;', ScrStr)=1) Then
            begin
              FDCLLogOn.About(nil);
            end;

            If PosEx('GetScreen=', ScrStr)=1 Then
            begin
              tmpStr1:=FindParam('Qlty=', ScrStr);
              TmpStr:=FindParam('FileName=', ScrStr);
              If TmpStr<>'' then
              begin
                If tmpStr1<>'' then
                  ConvertToJPEG(GetScreen, StrToIntDef(tmpStr1, JPEGCompressionQuality)).SaveToFile(TmpStr)
                Else
                  GetScreen.SaveToFile(TmpStr);
              end;
            end;

            If PosEx('ExtractScript;', ScrStr)=1 Then
            begin
              If FDCLLogOn.AccessLevel>=ulReadOnly Then
              begin
                OpenDialog:=TOpenDialog.Create(nil);
                OpenDialog.DefaultExt:=SignedScriptExt;
                OpenDialog.Filter:='DCL script files|*'+SignedScriptExt;
                If OpenDialog.Execute Then
                  ExtractScriptFile(OpenDialog.FileName);
                FreeAndNil(OpenDialog);
              end;
            end;

            If PosEx('ExtractScript=', ScrStr)=1 Then
            begin
              If FDCLLogOn.AccessLevel>=ulReadOnly Then
              begin
                tmp1:=FindParam('FileName=', ScrStr);
                ExtractScriptFile(tmp1);
              end;
            end;

            If PosEx('OpenScript;', ScrStr)=1 Then
            begin
              If FDCLLogOn.AccessLevel>=ulReadOnly Then
              begin
                OpenDialog:=TOpenDialog.Create(nil);
                OpenDialog.DefaultExt:=SignedScriptExt;
                OpenDialog.Filter:='DCL script files|*'+SignedScriptExt;
                If OpenDialog.Execute Then
                  RunSkriptFromFile(OpenDialog.FileName);
                FreeAndNil(OpenDialog);
              end;
            end;

            If PosEx('OpenScript=', ScrStr)=1 Then
            begin
              If FDCLLogOn.AccessLevel>=ulReadOnly Then
              begin
                tmp1:=FindParam('FileName=', ScrStr);
                RunSkriptFromFile(tmp1);
              end;
            end;

            If PosEx('SignScript;', ScrStr)=1 Then
            begin
              If FDCLLogOn.AccessLevel=ulDeveloper Then
              begin
                OpenDialog:=TOpenDialog.Create(nil);
                OpenDialog.DefaultExt:=TextScriptFileExt;
                OpenDialog.Filter:='DCL script text|*'+TextScriptFileExt;
                If OpenDialog.Execute Then
                  FDCLLogOn.SignScriptFile(OpenDialog.FileName, GPT.DCLUserName);
                FreeAndNil(OpenDialog);
              end;
            end;

            If PosEx('SignScript=', ScrStr)=1 Then
            begin
              If FDCLLogOn.AccessLevel=ulDeveloper Then
              begin
                tmp1:=FindParam('FileName=', ScrStr);
                FDCLLogOn.SignScriptFile(tmp1, GPT.DCLUserName);
              end;
            end;

            If PosEx('ReSignScript;', ScrStr)=1 Then
            begin
              If FDCLLogOn.AccessLevel=ulDeveloper Then
              begin
                OpenDialog:=TOpenDialog.Create(nil);
                OpenDialog.DefaultExt:=SignedScriptExt;
                OpenDialog.Filter:='DCL script files|*'+SignedScriptExt;
                If OpenDialog.Execute Then
                  FDCLLogOn.ReSignScriptFile(OpenDialog.FileName);
                FreeAndNil(OpenDialog);
              end;
            end;

            If PosEx('ReSignScript=', ScrStr)=1 Then
            begin
              If FDCLLogOn.AccessLevel=ulDeveloper Then
              begin
                tmp1:=FindParam('FileName=', ScrStr);
                FDCLLogOn.ReSignScriptFile(tmp1);
              end;
            end;

            If PosEx('SeparateChar=', ScrStr)=1 Then
            begin
              GPT.StringTypeChar:=FindParam('SeparateChar=', ScrStr);
            end;

            If PosEx('SetValueSeparator=', ScrStr)=1 Then
            begin
              GPT.GetValueSeparator:=FindParam('SetValueSeparator=', ScrStr);
            end;

            If PosEx('Export=', ScrStr)=1 Then
            begin
              TmpStr:=FindParam('Spool=', ScrStr);
              If TmpStr='' Then
                TmpStr:='0';
              If TmpStr='1' Then
              begin
                ExportData(stSpool, ScrStr);
                Spool.SaveToFile(SpoolFileName);
              end;
              If TmpStr='0' Then
                ExportData(stText, ScrStr);
            end;

            If PosEx('DialogByName=', ScrStr)=1 Then
            begin
              TmpStr:=FindParam('DialogByName=', ScrStr);
              tmpStr1:=Copy(TmpStr, 1, Pos('.', TmpStr)-1);
              tmpStr2:=Copy(TmpStr, Pos('.', TmpStr)+1, Length(TmpStr));
              Enything:=False;
              v2:= - 1;
              For v1:=1 to FDCLLogOn.FormsCount do
              begin
                If CompareString(FDCLLogOn.Forms[v1-1].DialogName, tmpStr1) Then
                begin
                  Enything:=True;
                  v2:=v1;
                  break;
                end;
              end;
              If Enything Then
              begin
                If CompareString(tmpStr2, 'hide') Then
                  FDCLLogOn.Forms[v2].FForm.Hide;
                If CompareString(tmpStr2, 'show') Then
                  FDCLLogOn.Forms[v2].FForm.Show;
                If CompareString(tmpStr2, 'close') Then
                Begin
                  If Assigned(FDCLLogOn.Forms[v2]) then
                  Begin
                    tmpDCLForm:=FDCLLogOn.Forms[v2].GetParentForm;
                    FDCLLogOn.Forms[v2].Free;
                    FDCLForm:=tmpDCLForm;
                  End;
                End;
                If CompareString(tmpStr2, 'refresh') Then
                begin
                  For v3:=1 to FDCLLogOn.Forms[v2].GetTablesCount do
                    FDCLLogOn.Forms[v2].Tables[v3-1].ReFreshQuery;
                end;
              end;
            end;

            If PosEx('NoCloseable=', ScrStr)=1 Then
            begin
              TmpStr:=FindParam('NoCloseable=', ScrStr);
              If Assigned(FDCLForm) Then
              Begin
                FDCLForm.NoCloseable:=Trim(TmpStr)='1';
              End;
            end;

  {$IFDEF DELPHI}
            If PosEx('ParamCheck=', ScrStr)=1 Then
            begin
              TmpStr:=FindParam('ParamCheck=', ScrStr);
              If TmpStr='1' Then
                FDCLForm.CurrentGridIndex.Query.ParamCheck:=True;
              If TmpStr='0' Then
                FDCLForm.CurrentGridIndex.Query.ParamCheck:=False;
            end;
  {$ENDIF}
            If PosEx('DisableParams=', ScrStr)=1 Then
            begin
              If FindParam('DisableParams=', ScrStr)='1' Then
                TransParams:=True;

              If FindParam('DisableParams=', ScrStr)='0' Then
                TransParams:=False;
            end;

  {$IFDEF DELPHI}
            If PosEx('FieldsList=', ScrStr)=1 Then
            begin
              tmp1:=FindParam('FieldsList=', ScrStr);
              If Not IsFullPAth(tmp1) Then
                tmp1:=IncludeTrailingPathDelimiter(AppConfigDir)+tmp1;

              FDCLForm.CurrentGridIndex.Query.FieldList.SaveToFile(tmp1);
            end;
  {$ENDIF}


            If PosEx('DownloadHTTP=', ScrStr)=1 Then
            begin
              TmpStr:=FindParam('DownloadHTTP=', ScrStr);
              tmpStr1:=FindParam('Path=', ScrStr);
              tmpStr2:=FindParam('FileName=', ScrStr);
              Downloader:=TDownloader.Create;

              If tmpStr1='' Then
              begin
                If tmpStr2='' Then
                  tmp1:=ExtractFileName(TmpStr)
                Else
                  tmp1:=tmpStr2;
              end
              Else
                TmpStr:=tmpStr1+ExtractFileName(TmpStr);

              If FindParam('Progress=', ScrStr)='1' Then
                DownloadProgress:=True
              Else
                DownloadProgress:=False;

              If FindParam('Cancel=', ScrStr)='1' Then
                DownLoadCancel:=True
              Else
                DownLoadCancel:=False;

              DownLoadProcess:=True;
              tmpStr2:=Trim(FindParam('Reset=', ScrStr));
              If tmpStr2='1' Then
                Downloader.DownLoadHTTP(TmpStr, tmp1, True, DownloadProgress, DownLoadCancel)
              Else
                Downloader.DownLoadHTTP(TmpStr, tmp1, False, DownloadProgress, DownLoadCancel);
              DownLoadProcess:=False;

              Sleep(100);
              Downloader.Free;
            end;

            If PosEx('Sleep=', ScrStr)=1 Then
            begin
              TmpStr:=FindParam('Sleep=', ScrStr);
              Sleep(StrToIntEx(TmpStr));
            end;

            If PosEx('Beep;', ScrStr)=1 Then
            begin
  {$IFDEF MSWINDOWS}
              Windows.Beep(500, 250)
  {$ELSE}
              Beep;
  {$ENDIF};
            end;

            If PosEx('Beep=', ScrStr)=1 Then
            begin
              TmpStr:=FindParam('Beep=', ScrStr);
              v1:=Pos(',', TmpStr);
              tmpStr1:=Copy(TmpStr, 1, v1-1);
              Delete(TmpStr, 1, v1);
              tmpStr2:=TmpStr;
  {$IFDEF MSWINDOWS}
              Windows.Beep(StrToIntEx(tmpStr1), StrToIntEx(tmpStr2));
  {$ELSE}
              Beep;
  {$ENDIF};
            end;

            If PosEx('ReOpen;', ScrStr)=1 Then
            begin
              If Assigned(FDCLForm) Then
                FDCLForm.RefreshForm;
            end;

            If PosEx('ReConnect;', ScrStr)=1 Then
            begin
              FDCLLogOn.ReconnectDB;
            end;

            If PosEx('Goto=', ScrStr)=1 Then
            begin
              TmpStr:=FindParam('Goto=', ScrStr);
              SetRetPoint;
              GotoGoto(TmpStr);
            end;

            If PosEx('Return;', ScrStr)=1 Then
            begin
              GetRetPoint;
            end;




            If PosEx('TablePartQuery=', ScrStr)=1 Then
            begin
              If Assigned(FDCLForm) Then
              begin
                v1:=0;
                TmpStr:=Trim(FindParam('TablePartNum=', ScrStr));
                If TmpStr<>'' Then
                  v1:=StrToIntEx(TmpStr)-1;

                TmpStr:=FindParam('TablePartQuery=', ScrStr);
                FDCLForm.CurrentGridIndex.TableParts[v1].SetSQLToStore(TmpStr, qtMain, ulUndefined);
                FDCLForm.TranslateVal(TmpStr, False);

                FDCLForm.CurrentGridIndex.TableParts[v1].Query.SQL.Text:=TmpStr;
                try
                  FDCLForm.CurrentGridIndex.TableParts[v1].Query.Open;
                Except
                  ShowErrorMessage( - 1201, 'SQL='+TmpStr);
                end;
              end;
            end;





            If PosEx('OpenFileDialog=', ScrStr)=1 Then
            begin
              tmp1:=FindParam('OpenFileDialog=', ScrStr);
              tmp2:=FindParam('Ext=', ScrStr);
              OpenDialog:=TOpenDialog.Create(nil);
              If tmp2<>'' Then
                OpenDialog.DefaultExt:=tmp2;
              If OpenDialog.Execute Then
                SetVariable(tmp1, OpenDialog.FileName)
              Else
                SetVariable(tmp1, '');
              FreeAndNil(OpenDialog);
            end;

            If PosEx('SaveFileDialog=', ScrStr)=1 Then
            begin
              tmp1:=FindParam('SaveFileDialog=', ScrStr);
              tmp2:=FindParam('Ext=', ScrStr);
              SaveDialog:=TSaveDialog.Create(nil);
              SaveDialog.FileName:=FindParam('FileName=', ScrStr);
              If tmp2<>'' Then
                SaveDialog.DefaultExt:=tmp2;
              If SaveDialog.Execute Then
                SetVariable(tmp1, SaveDialog.FileName)
              Else
                SetVariable(tmp1, '');
              FreeAndNil(SaveDialog);
            end;

            If PosEx('SetFieldValue=', ScrStr)=1 Then
            begin
              If GetRaightsByContext(InContext)>ulReadOnly Then
              begin
                TmpStr:=FindParam('SetFieldValue=', ScrStr);
                For v1:=1 to ParamsCount(TmpStr) do
                begin
                  tmpStr2:=SortParams(TmpStr, v1);
                  v2:=Pos('=', tmpStr2);
                  If v2<>0 Then
                  begin
                    tmp1:=Trim(Copy(tmpStr2, 1, v2-1));
                    tmp2:=Copy(tmpStr2, v2+1, Length(tmpStr2)-v2);
                    TranslateValContext(tmp2);
                    tmpStr3:=Trim(FindParam('TablePartNum=', ScrStr));
                    If GetRaightsByContext(InContext)>ulReadOnly Then
                      If tmpStr3<>'' Then
                      begin
                        v3:=StrToIntEx(tmpStr3)-1;
                        If Assigned(FDCLForm.CurrentGridIndex) Then
                          If Assigned(FDCLForm.CurrentGridIndex.TableParts[v3]) Then
                          begin
                            If Not (FDCLForm.CurrentGridIndex.TableParts[v3].Query.State
                                in dsEditModes) Then
                              FDCLForm.CurrentGridIndex.TableParts[v3].Query.Edit;
                            FDCLForm.CurrentGridIndex.TableParts[v3].Query.FieldByName(tmp1)
                              .AsString:=tmp2;
                          end;
                      end
                      Else
                      begin
                        If Not (FDCLForm.CurrentQuery.State in dsEditModes) Then
                          FDCLForm.CurrentQuery.Edit;
                        FDCLForm.CurrentQuery.FieldByName(tmp1).AsString:=tmp2;
                      end;
                  end;

                  If FindParam('Post=', ScrStr)='1' Then
                  begin
                    If GetRaightsByContext(InContext)>ulReadOnly Then
                      If Trim(FindParam('TablePartNum=', ScrStr))<>'' Then
                      begin
                        tmpStr3:=Trim(FindParam('TablePartNum=', ScrStr));
                        v2:=StrToIntEx(tmpStr3)-1;
                        If FDCLForm.CurrentGridIndex.TableParts[v2].Query.State in dsEditModes Then
                          FDCLForm.CurrentGridIndex.TableParts[v2].Query.Post;
                      end
                      Else
                      begin
                        If FDCLForm.CurrentQuery.State in dsEditModes Then
                          FDCLForm.CurrentQuery.Post;
                      end;
                  end;
                end;
              end;
            end;

            If PosEx('GetFieldValue=', ScrStr)=1 Then
            begin
              TmpStr:=FindParam('GetFieldValue=', ScrStr);
              For v1:=1 to ParamsCount(TmpStr) do
              begin
                tmpStr2:=SortParams(TmpStr, v1);
                v2:=Pos('=', tmpStr2);
                If v2<>0 Then
                begin
                  tmp1:=Trim(Copy(tmpStr2, 1, v2-1));
                  tmp2:=Copy(tmpStr2, v2+1, Length(tmpStr2)-v2);
                  v3:=Pos('.', tmp2);
                  If v3<>0 Then
                  begin
                    tmp3:=Trim(Copy(tmp2, 1, v3-1));
                    tmp4:=Copy(tmp2, v3+1, Length(tmp2)-v3);
                    tmp3:=FindParam('where=', ScrStr);
                    TranslateValContext(tmp3);
                    DCLQuery.Close;
                    DCLQuery.SQL.Text:='select '+tmp4+' from '+tmp3;
                    If tmp3<>'' Then
                      DCLQuery.SQL.Text:='select '+tmp4+' from '+tmp3+' where '+tmp3;
                    DCLQuery.Open;
                    FDCLLogOn.Variables.Variables[_Namespace, tmp1]:=TrimRight(DCLQuery.Fields[0].AsString);
                    DCLQuery.Close;
                  end
                  Else
                  begin
                    TmpStr:=Trim(FindParam('TablePartNum=', ScrStr));
                    If TmpStr<>'' Then
                    begin
                      v3:=StrToIntEx(TmpStr)-1;
                      If Assigned(FDCLForm.CurrentGridIndex.TableParts[v3]) Then
                        FDCLLogOn.Variables.Variables[_Namespace, tmp1]:=FDCLForm.CurrentGridIndex.TableParts[v3]
                          .Query.FieldByName(tmp1).AsString;
                    end
                    Else
                    begin
                      FDCLLogOn.Variables.Variables[_Namespace, tmp1]:=
                        TrimRight(FDCLForm.CurrentQuery.FieldByName(tmp2).AsString);
                    end;
                  end;
                end;
              end;
            end;



            If PosEx('PostClose;', ScrStr)=1 Then
            begin
              If Assigned(FDCLForm) Then
              begin
                If FDCLForm.CurrentQuery.State in dsEditModes Then
                  FDCLForm.CurrentQuery.Post;
                tmpDCLForm:=FDCLForm.GetParentForm;
                FDCLForm.CloseAction:=fcaClose;
                FDCLForm:=tmpDCLForm;
              end;
            end;

            If PosEx('CancelClose;', ScrStr)=1 Then
            begin
              If Assigned(FDCLForm) Then
              begin
                If FDCLForm.CurrentQuery.State in dsEditModes Then
                  FDCLForm.CurrentQuery.Cancel;
                tmpDCLForm:=FDCLForm.GetParentForm;
                FDCLForm.CloseAction:=fcaClose;
                FDCLForm:=tmpDCLForm;
              end;
            end;

            If PosEx('PostRefresh;', ScrStr)=1 Then
            begin
              If Assigned(FDCLForm) then
              Begin
                FDCLForm.CurrentQuery.Post;
                FDCLForm.CurrentGridIndex.ReFreshQuery;
              End;
            end;

            If PosEx('EvalFormula=', ScrStr)=1 Then
            begin
              tmp1:=FindParam('EvalFormula=', ScrStr);
              If Assigned(FDCLForm) then
                TranslateVals(tmp1, FDCLForm.CurrentQuery)
              Else
                TranslateVals(tmp1, nil);

              FDCLLogOn.EvalFormula:=Calculate(tmp1);
            end;



            If PosEx('Debug;', ScrStr)=1 Then
            begin
              GPT.DebugOn:=Not GPT.DebugOn;
            end;

            If PosEx('SetMainFormCaption=', ScrStr)=1 Then
            begin
              TmpStr:=FindParam('SetMainFormCaption=', ScrStr);
              TranslateValContext(TmpStr);
              Application.MainForm.Caption:=TmpStr;
            end;


            If PosEx('ApplicationTitle=', ScrStr)=1 Then
            begin
              TmpStr:=FindParam('ApplicationTitle=', ScrStr);
              TranslateValContext(TmpStr);
              Application.Title:=TmpStr;
            end;



            If PosEx('StatusWidth=', ScrStr)=1 Then
            begin
              TmpStr:=FindParam('StatusWidth=', ScrStr);
              If TmpStr<>'' Then
              begin
                If LowerCase(TmpStr)='last' Then
                  v1:=0
                Else
                  v1:=StrToIntEx(Trim(FindParam('StatusWidth=', ScrStr)))
              end
              Else
                v1:=0;

              v2:= - 1;
              If FindParam('Width=', ScrStr)<>'' Then
                v2:=StrToIntEx(Trim(FindParam('Width=', ScrStr)));
              If Assigned(FDCLForm) then
                FDCLForm.SetStatusWidth(v1-1, v2);
            end;

            If PosEx('DeleteStatus=', ScrStr)=1 Then
            begin
              TmpStr:=FindParam('DeleteStatus=', ScrStr);
              If TmpStr<>'' Then
              begin
                If LowerCase(TmpStr)='last' Then
                  v1:=0
                Else
                  v1:=StrToIntEx(Trim(FindParam('DeleteStatus=', ScrStr)));
              end
              Else
                v1:=0;

              If Assigned(FDCLForm) then
                FDCLForm.DeleteStatus(v1);
            end;

            If PosEx('DeleteAllStatus;', ScrStr)=1 Then
            begin
              If Assigned(FDCLForm) then
                FDCLForm.DeleteAllStatus;
            end;

            If PosEx('WriteConfig=', ScrStr)=1 Then
            begin
              tmp1:=FindParam('WriteConfig=', ScrStr);
              tmp3:=FindParam('UserID=', ScrStr);
              tmp2:=Copy(ScrStr, PosEx('_Value=', ScrStr), Length(ScrStr));
              Delete(tmp2, 1, 7);

              FDCLLogOn.WriteConfig(tmp1, tmp2, tmp3);
            end;


            If (PosEx('PutInDB=', ScrStr)=1)or(PosEx('PutToDB=', ScrStr)=1) Then
            begin
              If GetRaightsByContext(InContext)>ulReadOnly Then
              begin
                TmpStr:=FindParam('FileName=', ScrStr);
                tmpStr2:=FindParam('Compress=', ScrStr);

                If Not IsFullPAth(TmpStr) Then
                  TmpStr:=IncludeTrailingPathDelimiter(AppConfigDir)+TmpStr;
                If FileExists(TmpStr) Then
                begin
                  If Not Assigned(BinStore) Then
                    BinStore:=TBinStore.Create(FDCLLogOn, ftSQL, '', '', '',
                      FindParam('DataField=', ScrStr));
                  BinStore.StoreFromFile(TmpStr, FindParam('SQL=', ScrStr), '', tmpStr2='1');
                end
                Else
                  ShowErrorMessage( - 8001, TmpStr);
              end;
            end;

            If PosEx('GetFromDB=', ScrStr)=1 Then
            begin
              If GetRaightsByContext(InContext)>ulReadOnly Then
              begin
                TmpStr:=FindParam('FileName=', ScrStr);
                If Not IsFullPAth(TmpStr) Then
                  TmpStr:=IncludeTrailingPathDelimiter(AppConfigDir)+TmpStr;

                If Not Assigned(BinStore) Then
                  BinStore:=TBinStore.Create(FDCLLogOn, ftSQL, '', '', '',
                    FindParam('DataField=', ScrStr));

                BinStore.SaveToFile(TmpStr, FindParam('SQL=', ScrStr));
              end;
            end;

            If PosEx('ClearBLOB=', ScrStr)=1 Then
            begin
              If GetRaightsByContext(InContext)>ulReadOnly Then
              begin
                tmpStr1:=FindParam('ClearBLOB=', ScrStr);

                If Not Assigned(BinStore) Then
                  BinStore:=TBinStore.Create(FDCLLogOn, ftSQL, '', '', '',
                    FindParam('DataField=', ScrStr));

                BinStore.ClearData(FindParam('SQL=', ScrStr));
              end;
            end;

            If PosEx('DeleteBLOB=', ScrStr)=1 Then
            begin
              If GetRaightsByContext(InContext)>ulReadOnly Then
              begin
                tmpStr1:=FindParam('DeleteBLOB=', ScrStr);

                If Not Assigned(BinStore) Then
                  BinStore:=TBinStore.Create(FDCLLogOn, ftSQL, '', '', '',
                    FindParam('DataField=', ScrStr));

                BinStore.DeleteData(FindParam('SQL=', ScrStr));
              end;
            end;

            If PosEx('DecompressData=', ScrStr)=1 Then
            begin
              If Not Assigned(BinStore) Then
                BinStore:=TBinStore.Create(FDCLLogOn, ftSQL, '', '', '',
                  FindParam('DataField=', ScrStr));

              BinStore.DeCompressData(FindParam('SQL=', ScrStr), '');
            end;

            If PosEx('CompressData=', ScrStr)=1 Then
            begin
              If Not Assigned(BinStore) Then
                BinStore:=TBinStore.Create(FDCLLogOn, ftSQL, '', '', '',
                  FindParam('DataField=', ScrStr));

              BinStore.CompressData(FindParam('SQL=', ScrStr), '');
            end;

            If PosEx('MD5Data=', ScrStr)=1 Then
            begin
              tmpStr1:=FindParam('MD5Data=', ScrStr);

              If Not Assigned(BinStore) Then
                BinStore:=TBinStore.Create(FDCLLogOn, ftSQL, '', '', '',
                  FindParam('DataField=', ScrStr));
              FDCLLogOn.Variables.NewVariable(_Namespace, tmpStr1, BinStore.MD5(FindParam('SQL=', ScrStr)));
            end;

            If PosEx('SQLmon_Clear;', ScrStr)=1 Then
            begin
              FDCLLogOn.SQLMon.Clear;
            end;

            If PosEx('SQLMon;', ScrStr)=1 Then
            begin
              FDCLLogOn.SQLMon.TrraceStatus:=Not FDCLLogOn.SQLMon.TrraceStatus;
            end;

            If PosEx('OpenSpool=', ScrStr)=1 Then
            begin
              SpoolFileName:=FindParam('OpenSpool=', ScrStr);
              If Not IsFullPAth(SpoolFileName) Then
                SpoolFileName:=IncludeTrailingPathDelimiter(AppConfigDir)+SpoolFileName;

              If Not Assigned(Spool) Then
                Spool:=TStringList.Create;
            end;

            If PosEx('Spool=', ScrStr)=1 Then
            begin
              If Not Assigned(Spool) Then
                Spool:=TStringList.Create;
              If SpoolFileName='' Then
                SpoolFileName:='spool.txt';

              If Not IsFullPAth(SpoolFileName) Then
                SpoolFileName:=IncludeTrailingPathDelimiter(AppConfigDir)+SpoolFileName;

              TmpStr:=Copy(ScrStr, 7, Length(ScrStr)-6);
              Spool.Append(TmpStr);
              Spool.SaveToFile(SpoolFileName);
            end;

            If PosEx('Evalute=', ScrStr)=1 Then
            begin
              tmp1:=FindParam('Evalute=', ScrStr);

              tmp2:=FindParam('ResultVar=', ScrStr);
              If Not FDCLLogOn.Variables.Exists(_Namespace, tmp2) Then
                tmp2:='';
              If tmp2='' Then
                EvalResultScript:=RunScript(tmp1)
              Else
              begin
                SetVariable(tmp2, RunScript(tmp1));
              end;
            end;

            If PosEx('AddFunctions=', ScrStr)=1 Then
            begin
              tmpDCL:=TStringList.Create;

              TmpStr:=FindParam('AddFunctions=', ScrStr);
              DCLQuery.Close;
              DCLQuery.SQL.Text:='select Count(*) from '+GPT.DCLTable+' where '+GPT.UpperString+
                GPT.DCLNameField+GPT.UpperStringEnd+'='+GPT.UpperString+GPT.StringTypeChar+TmpStr+
                GPT.StringTypeChar+GPT.UpperStringEnd;
              DCLQuery.Open;
              RecCount:=DCLQuery.Fields[0].AsInteger;
              If RecCount=1 Then
              begin
                DCLQuery.Close;
                DCLQuery.SQL.Text:='select '+GPT.DCLTextField+' from '+GPT.DCLTable+' where '+
                  GPT.UpperString+GPT.DCLNameField+GPT.UpperStringEnd+'='+GPT.UpperString+
                  GPT.StringTypeChar+TmpStr+GPT.StringTypeChar+GPT.UpperStringEnd;
                DCLQuery.Open;
                TmpStr:=DCLQuery.FieldByName(GPT.DCLTextField).AsString;
                If Assigned(FDCLForm) then
                  TranslateVals(TmpStr, FDCLForm.CurrentGridIndex.FQuery);
                tmpDCL.Text:=TmpStr;
                AddCodeScript(tmpDCL);
              end;
              FreeAndNil(tmpDCL);
            end;

            If PosEx('ExecVBS=', ScrStr)=1 Then
            begin
              tmpDCL:=TStringList.Create;

              TmpStr:=FindParam('ExecVBS=', ScrStr);
              DCLQuery.Close;
              DCLQuery.SQL.Text:='select Count(*) from '+GPT.DCLTable+' where '+GPT.UpperString+
                GPT.DCLNameField+GPT.UpperStringEnd+'='+GPT.UpperString+GPT.StringTypeChar+TmpStr+
                GPT.StringTypeChar+GPT.UpperStringEnd;
              DCLQuery.Open;
              RecCount:=DCLQuery.Fields[0].AsInteger;
              If RecCount=1 Then
              begin
                DCLQuery.Close;
                DCLQuery.SQL.Text:='select '+GPT.DCLTextField+' from '+GPT.DCLTable+' where '+
                  GPT.UpperString+GPT.DCLNameField+GPT.UpperStringEnd+'='+GPT.UpperString+
                  GPT.StringTypeChar+TmpStr+GPT.StringTypeChar+GPT.UpperStringEnd;
                DCLQuery.Open;
                TmpStr:=DCLQuery.FieldByName(GPT.DCLTextField).AsString;
                If Assigned(FDCLForm) then
                  TranslateVals(TmpStr, FDCLForm.CurrentGridIndex.FQuery);
                ExecVBS(TmpStr);
              end;
              FreeAndNil(tmpDCL);
            end;

          end
          Else
          begin
          end;
        end;
        inc(ScriptStrings);
      end;
    end;
  end;

  DCLQuery.Close;
  FDCLLogOn.NotifyForms(fnaResumeAutoRefresh);
end;

procedure TDCLCommand.RunSkriptFromFile(FileName: String);
begin
end;

procedure TDCLCommand.ExecSQLCommand(SQLCommand: String; InContext: Boolean);
begin
end;

procedure TDCLCommand.ExportData(Tagert: TSpoolType; Scr: String);
var
  S1, S, Mode, FileName, tmp1, ExportTable, TableFields, BlobStr: String;
  T: TextFile;
  BlobPos: Cardinal;
  v1, v2: Word;
  MS: TMemoryStream;
  ExportingTable: TDCLDialogQuery;
  OpenDialog: TOpenDialog;

  procedure WriteSpool(var TT: Text; Spool: TStringList; S: String);
  begin
    If Tagert=stText Then
      WriteLn(TT, S)
    Else
      Spool.Append(S);
  end;

begin
  If Not Assigned(Spool) Then
    Spool:=TStringList.Create;

  ExportingTable:=TDCLDialogQuery.Create(nil);
  FDCLLogOn.SetDBName(ExportingTable);
  If FindParam('query=', Scr)<>'' Then
  begin
    tmp1:=FindParam('query=', Scr);
    ExportingTable.SQL.Text:=tmp1;
  end
  Else
    ExportingTable.SQL.Text:=FDCLForm.CurrentGridIndex.Query.SQL.Text;

  try
    ExportingTable.Open;
  Except
    ShowErrorMessage( - 1119, 'SQL='+ExportingTable.SQL.Text);
  end;

  If FindParam('filename=', Scr)='' Then
  begin
    OpenDialog:=TOpenDialog.Create(nil);
    If OpenDialog.Execute Then
      FileName:=OpenDialog.FileName
    Else
      FileName:='Table1';
    FreeAndNil(OpenDialog);
  end
  Else
    FileName:=FindParam('filename=', Scr);
  If Not IsFullPAth(FileName) Then
    FileName:=IncludeTrailingPathDelimiter(AppConfigDir)+FileName;

  tmp1:='';
  tmp1:=LowerCase(FindParam('target=', Scr));
  If tmp1='' Then
    tmp1:='sql';
  Mode:=LowerCase(LowerCase(FindParam('mode=', Scr)));
  If Mode='' Then
    Mode:='new';

  If LowerCase(tmp1)='oth' Then
  begin
    If PosEx('.OTH', FileName)=0 Then
      FileName:=FileName+'.OTH';
    If Tagert=stText Then
      AssignFile(T, FileName);

    If Mode='append' Then
    begin
      If Tagert=stText Then
        Append(T);
    end
    Else If Tagert=stText Then
      ReWrite(T);

    S:='[TABLE]';
    WriteSpool(T, Spool, S);
    S:=FindParam('table=', Scr);
    WriteSpool(T, Spool, S);
    S:='[FIELDS]';
    WriteSpool(T, Spool, S);
    For v1:=0 to ExportingTable.FieldCount-1 do
    begin
      S:=UpperCase(ExportingTable.Fields[v1].FieldName);
      WriteSpool(T, Spool, S);
    end;
    S:='[DATA]';
    WriteSpool(T, Spool, S);
    While Not ExportingTable.Eof do
    begin
      S:='';
      For v1:=0 to ExportingTable.FieldCount-1 do
      begin
        If (ExportingTable.Fields[v1].DataType<>ftMemo)or
          (ExportingTable.Fields[v1].DataType<>ftGraphic)or
          (ExportingTable.Fields[v1].DataType<>ftBlob) Then
        begin
          S1:=TrimRight(ExportingTable.Fields[v1].AsString);
          Case ExportingTable.Fields[v1].DataType of
          ftString:
          begin
            S:=S+GPT.StringTypeChar+S1+GPT.StringTypeChar+', ';
          end;
          ftDate, ftTime, ftDateTime, ftBCD, ftFloat, ftCurrency:
          begin
            If S1='' Then
              S:=S+S1+'null, '
            Else
              S:=S+GPT.StringTypeChar+S1+GPT.StringTypeChar+', ';
          end
        Else
        begin
          If S1='' Then
            S:=S+S1+'null, '
          Else
            S:=S+S1+', ';
        end;
          end;
        end;
        If v1=ExportingTable.FieldCount-1 Then
          Delete(S, Length(S)-1, 2);
      end;
      WriteSpool(T, Spool, S);
      ExportingTable.Next;
    end;
    S:='[ENDDATA]';
    WriteSpool(T, Spool, S);
    S:='END.';
    WriteSpool(T, Spool, S);

    If Tagert=stText Then
      CloseFile(T);
  end;

  If LowerCase(tmp1)='sql' Then
  begin
    If PosEx('.sql', FileName)=0 Then
      FileName:=FileName+'.sql';

    If Tagert=stText Then
      AssignFile(T, FileName);

    If Mode='append' Then
    begin
      If Tagert=stText Then
        Append(T);
    end
    Else If Tagert=stText Then
      ReWrite(T);

    If FindParam('table=', Scr)='' Then
    begin
      tmp1:=ExportingTable.SQL.Text;
      v2:=PosEx(' from ', tmp1)+5;
      tmp1:=Copy(ExportingTable.SQL.Text, v2, Length(ExportingTable.SQL.Text));
      tmp1:=TrimLeft(tmp1);
      tmp1:=Copy(tmp1, PosEx(' ', tmp1), Length(tmp1));
    end
    Else
      tmp1:=FindParam('table=', Scr);
    DeleteNonPrintSimb(tmp1);
    ExportTable:=tmp1;

    TableFields:='';
    BlobStr:='';
    For v1:=0 to ExportingTable.FieldCount-1 do
    begin
      TableFields:=TableFields+ExportingTable.Fields[v1].FieldName;
      If v1<>ExportingTable.FieldCount-1 Then
        TableFields:=TableFields+', ';
      If ExportingTable.Fields[v1].DataType in [ftMemo, ftBlob, ftGraphic] Then
      begin
        If BlobStr='' Then
          BlobStr:='SET BLOBFILE '''+FileName+'.lob'';';
      end;
    end;
    WriteSpool(T, Spool, BlobStr);

    MS:=TMemoryStream.Create;
    MS.Clear;
    MS.Seek(0, 0);
    BlobPos:=0;

    While Not ExportingTable.Eof do
    begin
      S:='insert into '+ExportTable+'('+TableFields+') values(';
      For v1:=0 to ExportingTable.FieldCount-1 do
      begin
        If ExportingTable.Fields[v1].DataType<>ftGraphic Then
        begin
          S1:=TrimRight(ExportingTable.Fields[v1].AsString);
          Case ExportingTable.Fields[v1].DataType of
          ftString:
          begin
            S:=S+GPT.StringTypeChar+S1+GPT.StringTypeChar+', ';
          end;
          ftDate, ftTime, ftDateTime, ftBCD, ftFloat, ftCurrency:
          begin
            If S1='' Then
              S:=S+S1+'null, '
            Else
              S:=S+GPT.StringTypeChar+S1+GPT.StringTypeChar+', ';
          end;
          ftSmallint, ftInteger, ftWord, ftBoolean, ftAutoInc:
          begin
            If S1='' Then
              S:=S+S1+'null, '
            Else
              S:=S+S1+', ';
          end;
          ftMemo, ftBlob, ftGraphic:
          begin
            If ExportingTable.Fields[v1].AsString<>'' Then
            begin
              (ExportingTable.Fields[v1] as TBlobField).SaveToStream(MS);
              S1:=':h'+IntToHex(BlobPos, 8)+'_'+IntToHex(ExportingTable.Fields[v1].Size, 8);
              inc(BlobPos, ExportingTable.Fields[v1].Size);
            end
            Else
              S1:='NULL';
            S:=S+S1;
          end;
          end;
        end;
        If v1<>ExportingTable.FieldCount-1 Then
          S:=S+', ';
      end;
      S:=S+');';
      WriteSpool(T, Spool, S);
      ExportingTable.Next;
    end;

    If MS.Size>0 Then
      MS.SaveToFile(FileName+'.lob');

    If Tagert=stText Then
      CloseFile(T);
  end;

  If SpoolFileName='' Then
    SpoolFileName:='spool.txt';

  If Not IsFullPAth(SpoolFileName) Then
    SpoolFileName:=IncludeTrailingPathDelimiter(AppConfigDir)+SpoolFileName;

  If Spool.Count>0 Then
    Spool.SaveToFile(SpoolFileName);
end;

function TDCLCommand.ExpressionParser(Expression: String): String;
begin

end;

procedure TDCLCommand.ExtractScriptFile(FileName: String);
begin
  FDCLLogOn.ExtractScriptFile(FileName);
end;

function TDCLCommand.GetRaightsByContext(InContext: Boolean): TUserLevelsType;
begin
end;

procedure TDCLCommand.RePlaseParamss(var ParamsSet: String; Query: TDCLDialogQuery);
begin
end;

procedure TDCLCommand.RePlaseVariabless(var Variables: String);
begin
end;

{ TDCLLogOn }

procedure TDCLLogOn.About(Sender: TObject);
begin
end;

function TDCLLogOn.AddVirtualScript(Scr: RVirtualScript):Integer;
begin
end;

function TDCLLogOn.CheckPass(UserName, EnterPass, Password: String): Boolean;
begin
end;

procedure TDCLLogOn.CloseAllForms;
begin
end;

procedure TDCLLogOn.CloseForm(Form: TDCLForm);
begin
end;

procedure TDCLLogOn.CloseFormNum(FormNum: Integer);
begin
end;

destructor TDCLLogOn.Destroy;
begin
end;

function TDCLLogOn.ConnectDB: Integer;
begin
end;

constructor TDCLLogOn.Create(DBLogOn: TDBLogOn);
begin
{$IFDEF ADO}
  FDBLogOn.KeepConnection:=True;
{$ENDIF}
end;

function TDCLLogOn.CreateForm(FormName: String; ParentForm, CallerForm: TDCLForm; Command:TDCLCommand; Query: TDCLDialogQuery;
  Data: TDataSource; ModalMode: Boolean; ReturnValueMode: TChooseMode;
  ReturnValueParams: TReturnValueParams=nil; Script:TStringList=nil): TDCLForm;
begin
end;

procedure TDCLLogOn.CreateMenu(MainForm: TForm);
begin
end;

procedure TDCLLogOn.Disconnect;
begin
  LoggingUser(False);
{$IFNDEF EMBEDDED}
  If FDBLogOn.Connected then
    FDBLogOn.Connected:=False;
{$ENDIF}  
end;

procedure TDCLLogOn.ReconnectDB;
begin
end;

procedure TDCLLogOn.ExecShellCommand(ShellCommandText: String);
var
  Bat: TStringList;
  sBAT: String;
begin
  Bat:=TStringList.Create;
  Bat.Text:=ShellCommandText;
  If Bat.Count>0 Then
  begin
    If PosEx('script type=ShellCommand', Bat[0])<>0 Then
      Bat.Delete(0);
  end;
  If Bat.Count>0 Then
  begin
{$IFDEF UNIX}
    Bat.Insert(0, '#/bin/sh');
{$ENDIF}
    sBAT:=Bat.Text;
    RePlaseVariables('', sBAT);
    Bat.Text:=sBAT;
    Bat.SaveToFile(IncludeTrailingPathDelimiter(AppConfigDir)+'$Batch$.bat');
{$IFDEF UNIX}
    fpChmod(IncludeTrailingPathDelimiter(AppConfigDir)+'$Batch$.bat', &777);
{$ENDIF}
    ExecAndWait(PChar(IncludeTrailingPathDelimiter(AppConfigDir)+'$Batch$.bat'), SW_SHOWNORMAL, True);
    If FileExists(IncludeTrailingPathDelimiter(AppConfigDir)+'$Batch$.bat') Then
      DeleteFile(PChar(IncludeTrailingPathDelimiter(AppConfigDir)+'$Batch$.bat'));
  end;

  FreeAndNil(Bat);
end;

procedure TDCLLogOn.ExecVBS(VBSScript: String);
var
  VBSText: TStringList;
  tmpVBSText: String;
begin
  VBSText:=TStringList.Create;
  VBSText.Text:=VBSScript;
  If VBSText.Count>0 Then
  begin
    If PosEx('script type=VBScript', VBSText[0])<>0 Then
      VBSText.Delete(0);
  end;
  If VBSText.Count>0 Then
  begin
    tmpVBSText:=VBSText.Text;
    RePlaseVariables('', tmpVBSText);
    ExecuteStatement(tmpVBSText);
  end;
  FreeAndNil(VBSText);
end;

procedure TDCLLogOn.ExtractScriptFile(FileName: String);
begin
end;

function TDCLLogOn.FindVirtualScript(ScriptName: String): Integer;
begin
end;

function TDCLLogOn.GetBaseUID: String;
begin
end;

function TDCLLogOn.GetBusyMode: Boolean;
begin
end;

function TDCLLogOn.GetConfigInfo: String;
var
  Q: TDCLDialogQuery;
begin
  If GetConnected then
  Begin
    Q:=TDCLDialogQuery.Create(nil);
    Q.Name:='GetConfInfo_'+IntToStr(UpTime);
    SetDBName(Q);
    Q.SQL.Text:='select '+GPT.DCLTextField+' from '+GPT.DCLTable+' where '+GPT.IdentifyField+'=60000';
    Q.Open;
    Result:=Q.Fields[0].AsString;
    Q.Close;

    FreeAndNil(Q);
  End;
end;

function TDCLLogOn.GetConfigVersion: String;
var
  Q: TDCLDialogQuery;
begin
  If GetConnected then
  Begin
    Q:=TDCLDialogQuery.Create(nil);
    Q.Name:='GetConfVer_'+IntToStr(UpTime);
    SetDBName(Q);
    Q.SQL.Text:='select '+GPT.DCLNameField+' from '+GPT.DCLTable+' where '+GPT.IdentifyField+'=60001';
    Q.Open;
    Result:=Q.Fields[0].AsString;
    Q.Close;

    FreeAndNil(Q);
  End;
end;

function TDCLLogOn.GetConnected: Boolean;
begin
end;

function TDCLLogOn.GetForm(Index: Integer): TDCLForm;
begin
end;

function TDCLLogOn.GetFormsCount: Integer;
begin
end;

function TDCLLogOn.GetFullRaight: Word;
begin
  Result:=RoleRaightsLevel*16+Ord(FAccessLevel);
end;

function TDCLLogOn.GetSecKeyData(Data: TMemoryStream; UserName: String): String;
begin
end;

function TDCLLogOn.GetVirtualScript(ScriptName: String): RVirtualScript;
begin
end;

function TDCLLogOn.GetVirtualScriptNum(Index: Integer): RVirtualScript;
begin
end;

procedure TDCLLogOn.SignScriptFile(FileName, UserName: String);
begin
end;

procedure TDCLLogOn.ReSignScriptFile(FileName: String);
begin
end;

procedure TDCLLogOn.RunSkriptFromFile(FileName: String);
begin
end;

procedure TDCLLogOn.GetTableNames(var List: TStrings);
begin
end;

function TDCLLogOn.GetRolesQueryText(QueryType: TSelectType; WhereStr: String): String;
begin
end;

function TDCLLogOn.LoadScrText(ScrName: String): TStringList;
begin
end;

procedure TDCLLogOn.Lock;
begin
end;

procedure TDCLLogOn.LoggingUser(Login: Boolean);
begin
end;

function TDCLLogOn.Login(UserName, Password: String; ShowForm: Boolean): TLogOnStatus;
begin

  GPT.UseMessages:=DCLMainLogOn.TableExists(GPT.NotifycationsTable);
  If GPT.UseMessages then
  Begin
    MessageFormObject:=TMessageFormObject.Create('', '');
    
    MessagesTimer:=TTimer.Create(nil);
    MessagesTimer.Interval:=IntervalTimeNotify;
    MessagesTimer.Enabled:=True;
    MessagesTimer.OnTimer:=WaitNotify;
    WaitNotify(nil);
  End;
end;

procedure TDCLLogOn.GetUserName(AUserName: String);
begin

end;

procedure TDCLLogOn.InitActions(Sender: TObject);
var
  MenuQuery: TDCLDialogQuery;
begin
  Timer1.Enabled:=False;
  FreeAndNil(Timer1);

  if Assigned(FDCLMainMenu) then
  begin
    FDCLMainMenu.LockMenu;

    MenuQuery:=TDCLDialogQuery.Create(nil);
    MenuQuery.Name:='Menu_'+IntToStr(UpTime);
    SetDBName(MenuQuery);

    MenuQuery.SQL.Text:=GetRolesQueryText(qtSelect, ' s.'+GPT.IdentifyField+
        ' between 40001 and 40100 order by s.'+GPT.IdentifyField);
    MenuQuery.Open;
    While Not MenuQuery.Eof do
    begin
      FDCLMainMenu.ChoseRunType(MenuQuery.FieldByName(GPT.CommandField).AsString,
        MenuQuery.FieldByName(GPT.DCLTextField).AsString, MenuQuery.FieldByName(GPT.DCLNameField)
          .AsString, 1);
      MenuQuery.Next;
    end;
    MenuQuery.Close;

    If FileExists(GPT.LaunchScrFile) then
    Begin
      RunSkriptFromFile(GPT.LaunchScrFile);
    End;
    GPT.LaunchScrFile:='';

    If GPT.LaunchForm<>'' then
    Begin
      MenuQuery.SQL.Text:=GetRolesQueryText(qtSelect, ' s.'+GPT.DCLNameField+
          '='+GPT.StringTypeChar+GPT.LaunchForm+GPT.StringTypeChar);
      MenuQuery.Open;
      If Not MenuQuery.Eof then
      begin
        FDCLMainMenu.ChoseRunType('', '',
          MenuQuery.FieldByName(GPT.DCLNameField).AsString, 0);
      end;
      MenuQuery.Close;
    End;

    FDCLMainMenu.UnLockMenu;

    FreeAndNil(MenuQuery);
  end;
end;

procedure TDCLLogOn.NotifyForms(Action: TFormsNotifyAction);
begin
end;

function TDCLLogOn.ReadConfig(ConfigName, UserID: String): String;
begin
end;

procedure TDCLLogOn.RePlaseVariables(const Namespace: String; var VariablesSet: String);
begin
end;

procedure TDCLLogOn.RunCommand(CommandName: String);
begin
end;

procedure TDCLLogOn.RunInitSkripts;
begin
  Timer1:=TTimer.Create(nil);
  Timer1.Interval:=IntervalTimeToInitScripts;
  Timer1.Enabled:=True;
  Timer1.OnTimer:=InitActions;
end;

procedure TDCLLogOn.SetDBName(var Query: TDCLDialogQuery);
begin
end;

procedure TDCLLogOn.TranslateVal(const Namespace: String; var S: String);
begin
end;

procedure TDCLLogOn.WaitNotify(Sender: TObject);
var
  ShadowQuery, ShadowQuery1: TDCLDialogQuery;
  NowTime, TaskTimeStr, NowTimeStr: String;
  NowTimeStruct, TaskTime: TDateTimeItem;
  RunTask: Boolean;

  function GetNotifyAction(NA: Byte): TNotifyActionsType;
  begin
    // naDone, naScriptRun, naMessage, naExecAndWait, naExec, naExitToTime
    Case NA of
    0..Ord(High(TNotifyActionsType)):
    Result:=TNotifyActionsType(NA);
  Else
  Result:=naDone;
    end;
  end;

  procedure MessageToUser(Text: String);
  begin
    If GPT.UserID<>'' Then
      MessageFormObject:=TMessageFormObject.Create(GPT.DCLLongUserName, Text)
    Else
      MessageFormObject:=TMessageFormObject.Create
        ('<'+GetDCLMessageString(msToAll)+'>', Text);
  end;

begin
  // 4 - Выход по дате.
  // 2,3 - Запуск приложения.
  // 1 - Сообщение.
  // 5 - Запуск скрипта.
{$IFNDEF NODCLMESSAGES}
  If Not GPT.UseMessages Then
    Exit;

  ShadowQuery:=TDCLDialogQuery.Create(nil);
  ShadowQuery.Name:='Wait_'+IntToStr(UpTime);
  SetDBName(ShadowQuery);

  ShadowQuery1:=TDCLDialogQuery.Create(nil);
  ShadowQuery1.Name:='Wait1_'+IntToStr(UpTime);
  SetDBName(ShadowQuery1);

  ShadowQuery.Close;
  If GPT.UserID<>'' Then
  begin
    ShadowQuery.SQL.Text:='select first 1 NOTIFY_ACTION, NOTIFY_TIME, NOTIFY_ID, NOTIFY_TEXT from '+
      GPT.NotifycationsTable+' where USER_ID='+GPT.UserID+' and NOTIFY_STATE<>'+IntToStr(Ord(naDone)
      )+' order by NOTIFY_TIME, NOTIFY_ACTION';
  end
  Else
  begin
    ShadowQuery.SQL.Text:='select first 1 NOTIFY_ACTION, NOTIFY_TIME, NOTIFY_ID, NOTIFY_TEXT from '+
      GPT.NotifycationsTable+' where NOTIFY_STATE<>'+IntToStr(Ord(naDone))+
      ' order by NOTIFY_TIME, NOTIFY_ACTION';
  end;

  If TableExists(GPT.NotifycationsTable) Then
  begin

    try
      ShadowQuery.Open;
      GPT.UseMessages:=True;
    Except
      GPT.UseMessages:=False;
      MessagesTimer.Enabled:=False;
    end;
  end
  Else
    GPT.UseMessages:=False;

  If Not GPT.UseMessages Then
    Exit;

  If ExitFlag>0 Then
    If TimeToExit<=UpTime Then
      Application.MainForm.Close;

  If ExitFlag>0 Then
    If TimeToExit+TimeToTerminate<=UpTime Then
      Application.Terminate;

  If GPT.UseMessages Then
  begin
    ShadowQuery.First;
    While Not ShadowQuery.Eof do
    begin
      NowTime:=DateToStr(Date)+' '+TimeToStr(SysUtils.Time);
      DecodeDate(StrToDateTime(NowTime), NowTimeStruct.Year, NowTimeStruct.Month,
        NowTimeStruct.Day);
      DecodeDate(StrToDateTime(Trim(ShadowQuery.FieldByName('NOTIFY_TIME').AsString)),
        TaskTime.Year, TaskTime.Month, TaskTime.Day);

      DecodeTime(StrToDateTime(NowTime), NowTimeStruct.Hour, NowTimeStruct.Min, NowTimeStruct.Sec,
        NowTimeStruct.mSec);
      DecodeTime(StrToDateTime(Trim(ShadowQuery.FieldByName('NOTIFY_TIME').AsString)),
        TaskTime.Hour, TaskTime.Min, TaskTime.Sec, TaskTime.mSec);

      NowTimeStr:=IntToStr(NowTimeStruct.Year)+LeadingZero(NowTimeStruct.Month)+
        LeadingZero(NowTimeStruct.Day)+LeadingZero(NowTimeStruct.Hour)+
        LeadingZero(NowTimeStruct.Min)+LeadingZero(NowTimeStruct.Sec);
      TaskTimeStr:=IntToStr(TaskTime.Year)+LeadingZero(TaskTime.Month)+LeadingZero(TaskTime.Day)+
        LeadingZero(TaskTime.Hour)+LeadingZero(TaskTime.Min)+LeadingZero(TaskTime.Sec);

      RunTask:=TaskTimeStr<=NowTimeStr;

      If RunTask Then
      begin
        Case GetNotifyAction(ShadowQuery.FieldByName('NOTIFY_ACTION').AsInteger) of
        naScriptRun:
        begin
          RunCommand(Trim(ShadowQuery.FieldByName('NOTIFY_TEXT').AsString));
        end;
        naExecAndWait:
        begin
          ExecAndWait(Trim(ShadowQuery.FieldByName('NOTIFY_TEXT').AsString), SW_SHOWNORMAL, True);
        end;
        naExec:
        begin
          ExecApp(ShadowQuery.FieldByName('NOTIFY_TEXT').AsString, '');
        end;
        naMessage:
        begin
          MessageToUser(Trim(ShadowQuery.FieldByName('NOTIFY_TEXT').AsString));
        end;
        naExitToTime:
        begin
          If ExitFlag=0 Then
          begin
            MessageToUser(Format(GetDCLMessageString(msTimeToExit), [ExitTime]));
            ExitFlag:=1;
            TimeToExit:=UpTime+(ExitTime*1000);
          end;
        end
        Else
          MessageToUser(Trim(ShadowQuery.FieldByName('NOTIFY_TEXT').AsString));
        end;

        ShadowQuery1.Close;

        try
          ShadowQuery1.SQL.Text:='update '+GPT.NotifycationsTable+' n set n.NOTIFY_STATE='+
            IntToStr(Ord(naDone))+' where n.NOTIFY_ID='+ShadowQuery.FieldByName('NOTIFY_ID').AsString+
            ' and n.NOTIFY_STATE<>'+IntToStr(Ord(naDone));
          ShadowQuery1.ExecSQL;
        finally
          ///
        end;
      end;

      ShadowQuery.Next;
    end;
  end;

  FreeAndNil(ShadowQuery);
  FreeAndNil(ShadowQuery1);
{$ENDIF}
end;

procedure TDCLLogOn.WriteBaseUID;
begin
end;

procedure TDCLLogOn.WriteBaseUIDtoINI(FileName, SectionName: string);
begin
end;

procedure TDCLLogOn.WriteConfig(ConfigName, NewValue, UserID: String);
begin
end;

procedure TDCLMainMenu.ExecCommand(Command: String);
begin
end;

procedure TDCLMainMenu.ChoseRunType(Command, DCLText, Name: String; Order: Byte);
var
  DCL: TStringList;
begin
  if not Assigned(FDCLLogOn) then
    Exit;

  If FDCLLogOn.RoleOK<>lsLogonOK Then
    Exit;
  DCL:=TStringList.Create;

  If (Trim(Command)<>'')and(Order<>0) Then
    ExecCommand(TrimRight(Command))
  Else
  begin
    DCL.Text:=DCLText;
    If (DCLText<>'') and (Order<>0) Then
    Begin
      If FindParam('script type=', LowerCase(DCL[0]))='command' Then
        ExecCommand(DCLText)
      Else
        If (Trim(Command)<>'') and (Order=1) Then
          ExecCommand(TrimRight(Command))
        Else
          ExecCommand(DCLText);

      If LowerCase(FindParam('script type=', LowerCase(DCL[0])))=LowerCase('ShellCommand') Then
        FDCLLogOn.ExecShellCommand(DCLText)
      Else If LowerCase(FindParam('script type=', LowerCase(DCL[0])))=LowerCase('VBScript') Then
        FDCLLogOn.ExecVBS(DCLText);
    End
    Else
      If Order=0 Then
      Begin
        If FindParam('script type=', LowerCase(DCL[0]))='command' Then
          ExecCommand(DCLText)
        Else
          FDCLLogOn.CreateForm(TrimRight(Name), nil, nil, nil, nil, nil, False, chmNone);
      End
      Else
        ExecCommand(DCLText);
  end;
  FreeAndNil(DCL);
end;

procedure TDCLMainMenu.ClickMenu(Sender: TObject);
begin
end;

destructor TDCLMainMenu.Destroy;
var
  MenuQuery: TDCLDialogQuery;
  RecCount: Integer;
begin
  MenuQuery:=TDCLDialogQuery.Create(nil);
  MenuQuery.Name:='DestroyMenu_'+IntToStr(UpTime);
  FDCLLogOn.SetDBName(MenuQuery);

  MenuQuery.SQL.Text:=FDCLLogOn.GetRolesQueryText(qtCount, ' s.'+GPT.IdentifyField+
      ' between 40101 and 40200');
  MenuQuery.Open;
  RecCount:=MenuQuery.Fields[0].AsInteger;

  If RecCount>0 Then
  begin
    MenuQuery.SQL.Text:=FDCLLogOn.GetRolesQueryText(qtSelect,
      ' s.'+GPT.IdentifyField+' between 40101 and 40200 order by s.'+GPT.IdentifyField);
    MenuQuery.Open;

    While Not MenuQuery.Eof do
    begin
      ChoseRunType(MenuQuery.FieldByName(GPT.CommandField).AsString,
        MenuQuery.FieldByName(GPT.DCLTextField).AsString, MenuQuery.FieldByName(GPT.DCLNameField)
          .AsString, 1);
      MenuQuery.Next;
    end;
  end;
  MenuQuery.Close;
  FreeAndNil(MenuQuery);

  If Assigned(MainFormStatus) Then
    FreeAndNil(MainFormStatus);
  If Assigned(FormBar) Then
    FreeAndNil(FormBar);
  If Assigned(FMainMenu) Then
    FreeAndNil(FMainMenu);
end;

constructor TDCLMainMenu.Create(var DCLLogOn: TDCLLogOn; Form: TForm; Relogin: Boolean=False);
Type
  TCompotableVersionNumbers=Array [1..4] of Word;
var
  RecCount, SubNum, v1: Integer;
  NewMainForm: Boolean;
  SubQuery, MenuQuery, DCLQuery: TDCLDialogQuery;
  tmpSQL, tmpSQL1: String;
begin
  FDCLLogOn:=DCLLogOn;
  MainFormAction:=TMainFormAction.Create;
  FMainForm:=FDCLLogOn.MainForm;
  FForm:=Form;

  NewMainForm:=Not Assigned(Form);
  If NewMainForm Then
  begin
    If FDCLLogOn.RoleOK<>lsLogonOK Then
      Exit;
    FDCLLogOn.FMainForm:=Form;

    Form:=TDBForm.Create(nil);
    Form.Name:='DCLMainForm';

    MainFormStatus:=TStatusBar.Create(Form);
    MainFormStatus.Name:='MainStatusPanel';
    MainFormStatus.Parent:=Form;
    MainFormStatus.SimplePanel:=False;
    Form.Left:=50;
    Form.Top:=50;
  end;

  Form.Tag:=999;

  If FDCLLogOn.RoleOK<>lsLogonOK Then
  begin
    CreateAboutItem(FMainMenu, FMainForm);
    Exit;
  end;

  If ConnectErrorCode=0 Then
  begin
    Form.OnClose:=MainFormAction.CloseMainForm;
    Form.OnCloseQuery:=MainFormAction.FormCloseQuery;

    If not FDCLLogOn.TableExists(GPT.DCLTable) then
    Begin
      CreateAboutItem(FMainMenu, FForm);
    End
    Else
    Begin
      MenuQuery.SQL.Text:=FDCLLogOn.GetRolesQueryText(qtCount,
        ' s.'+GPT.IdentifyField+' between 20001 and 20050');

      RecCount:=0;
      DebugProc('Selecting components(20001):');
      DebugProc('  Query: '+MenuQuery.SQL.Text);
      try
        DebugProc('  ... selected');
        MenuQuery.Open;
        RecCount:=MenuQuery.Fields[0].AsInteger;
        DebugProc('  ... OK');
      Except
        DebugProc('  ... Fail');
      end;

      If RecCount>0 Then
      begin
        MenuQuery.Close;
        MenuQuery.SQL.Text:=FDCLLogOn.GetRolesQueryText(qtSelect,
          ' s.'+GPT.IdentifyField+' between 20001 and 20050 order by s.'+GPT.IdentifyField);

        MenuQuery.Open;
        If Assigned(MainFormStatus) Then
          FreeAndNil(MainFormStatus);

        If Not Assigned(MainFormStatus) Then
        begin
          MainFormStatus:=TStatusBar.Create(Form);
          MainFormStatus.Name:='MainStatusPanel';
          MainFormStatus.Parent:=Form;
          MainFormStatus.SimplePanel:=False;
        end;
        While Not MenuQuery.Eof do
        begin
          If MenuQuery.FieldByName(GPT.DCLTextField).AsString<>'' Then
            tmpSQL:=MenuQuery.FieldByName(GPT.DCLTextField).AsString
          Else
            tmpSQL:=TrimRight(MenuQuery.FieldByName(GPT.DCLNameField).AsString);
          If PosEx('select', tmpSQL)<>0 Then
            If PosEx('from', tmpSQL)<>0 Then
            begin
              DCLQuery:=TDCLDialogQuery.Create(nil);
              DCLQuery.Name:='Menu20001_'+IntToStr(UpTime);
              FDCLLogOn.SetDBName(DCLQuery);
              FDCLLogOn.RePlaseVariables('', tmpSQL);
              DCLQuery.SQL.Text:=tmpSQL;
              DCLQuery.Open;
              tmpSQL:=TrimRight(DCLQuery.Fields[0].AsString);
              DCLQuery.Close;
              FreeAndNil(DCLQuery);
            end;
          If PosEx('ReturnValue=', tmpSQL)<>0 Then
          begin
            tmpSQL1:=FindParam('ReturnValue=', tmpSQL);
            DeleteNonPrintSimb(tmpSQL1);
            FDCLLogOn.RePlaseVariables('', tmpSQL1);
            tmpSQL:=tmpSQL1;
          end;

          MainFormStatus.Panels.Insert(MainFormStatus.Panels.Count);
          MainFormStatus.Panels[MainFormStatus.Panels.Count-1].Text:=tmpSQL;
          If MenuQuery.FieldByName(GPT.ParentFlgField).AsInteger<>0 Then
            MainFormStatus.Panels[MainFormStatus.Panels.Count-1].Width:=
              MenuQuery.FieldByName(GPT.ParentFlgField).AsInteger
          Else
            MainFormStatus.Panels[MainFormStatus.Panels.Count-1].Width:=Length(tmpSQL)*CharWidth;
          MenuQuery.Next;
        end;
      end;
      MenuQuery.Close;

      MenuQuery.SQL.Text:=FDCLLogOn.GetRolesQueryText(qtSelect, ' s.'+GPT.IdentifyField+'=0');
      MenuQuery.Open;
      tmpSQL:=TrimRight(MenuQuery.FieldByName(GPT.DCLNameField).AsString);
      FDCLLogOn.RePlaseVariables('', tmpSQL);
      tmpSQL:=tmpSQL+GPT.MainFormCaption;
      FForm.Caption:=tmpSQL;

      If NewMainForm Then
        FForm.Show;

      If RecCount>0 Then
      begin
      end
      Else
        CreateAboutItem(FMainMenu, FForm);


      MenuQuery.SQL.Text:=FDCLLogOn.GetRolesQueryText(qtCount,
        ' s.'+GPT.IdentifyField+' between 20051 and 20100');

      RecCount:=0;
      DebugProc('Selecting components(20051):');
      DebugProc('  Query: '+MenuQuery.SQL.Text);
      try
        DebugProc('  ... selected');
        MenuQuery.Open;
        RecCount:=MenuQuery.Fields[0].AsInteger;
        DebugProc('  ... OK');
      Except
        DebugProc('  ... Fail');
      end;
      MenuQuery.Close;

      If RecCount>0 Then
      begin
        MenuQuery.SQL.Text:=FDCLLogOn.GetRolesQueryText(qtSelect,
          ' s.'+GPT.IdentifyField+' between 20051 and 20100 order by s.'+GPT.IdentifyField);
        MenuQuery.Open;
        tmpSQL:='';
        tmpSQL1:='';
        While Not MenuQuery.Eof do
        begin
          If MenuQuery.FieldByName(GPT.DCLTextField).AsString<>'' Then
            tmpSQL:=MenuQuery.FieldByName(GPT.DCLTextField).AsString
          Else
            tmpSQL:=TrimRight(MenuQuery.FieldByName(GPT.DCLNameField).AsString);
          If PosEx('select', tmpSQL)<>0 Then
          begin
            If PosEx('from', tmpSQL)<>0 Then
            begin
              DCLQuery:=TDCLDialogQuery.Create(nil);
              DCLQuery.Name:='Menu20051_'+IntToStr(UpTime);
              DCLQuery.SQL.Text:=tmpSQL;
              FDCLLogOn.SetDBName(DCLQuery);
              DCLQuery.Open;
              tmpSQL1:=tmpSQL1+TrimRight(DCLQuery.Fields[0].AsString);
              DCLQuery.Close;
              FreeAndNil(DCLQuery);
            end;
          end
          Else
            tmpSQL1:=tmpSQL1+tmpSQL;
          MenuQuery.Next;
        end;
        Form.Caption:=Form.Caption+tmpSQL1;
      end;
      MenuQuery.Close;

      FDCLLogOn.RunInitSkripts;

      FreeAndNil(MenuQuery);
    end;
  End;
end;

procedure TDCLMainMenu.LockMenu;
begin
end;

procedure TDCLMainMenu.UnLockMenu;
begin
end;

{ TDCLGrid }

procedure TDCLGrid.AddBrushColor(OPL: String);
var
  v1, v2: Integer;
  BrushColor: TBrushColor;
  TmpStr, tmpStr2, BrushKey, Colors: String;
begin
  BrushKey:=FindParam('BrushKey=', OPL);
  Colors:=FindParam('Color=', OPL);

  For v1:=1 to ParamsCount(Colors) do
  begin
    BrushColor:=TBrushColor.Create;
    TmpStr:=SortParams(Colors, v1);
    v2:=Pos('=', TmpStr);
    tmpStr2:=Copy(TmpStr, v2+1, Length(TmpStr)-v2+1);
    Case GetStringDataType(tmpStr2) of
    idDigit:
    BrushColor.Color:=StrToIntEx(tmpStr2);
    idHex:
    BrushColor.Color:=HexToInt(tmpStr2);
    idColor:
    BrushColor.Color:=StringToColor(tmpStr2);
    end;
    BrushColor.Value:=Copy(TmpStr, 1, v2-1);
    BrushColor.Key:=BrushKey;

    BrushColors.Add(BrushColor);

    If Not FieldExists(BrushColor.Key, FQuery) Then
    begin
      DebugProc('//!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
      DebugProc('В предложении Color=, указанно несуществующее поле : '+BrushColor.Key);
      DebugProc(OPL);
      DebugProc('//!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
    end;
  end;
end;

procedure TDCLGrid.AddCalendar(Calendar: TDCLCalendar);
begin
end;

procedure TDCLGrid.AddSimplyCheckBox(Field: TDCLField);
begin
end;

procedure TDCLGrid.AddCheckBox(Field: TDCLField);
begin
end;

procedure TDCLGrid.AddContextButton(Field: TDCLField);
begin
end;

procedure TDCLGrid.AddContextList(Field: TDCLField);
begin
end;

procedure TDCLGrid.AddDateBox(Field: TDCLField);
begin
end;

procedure TDCLGrid.AddDBCheckBox(Field: TDCLField);
begin
end;

procedure TDCLGrid.AddDBFilter(Filter: TDBFilter);
begin
end;

procedure TDCLGrid.AddDropBox(Field: TDCLField);
begin
end;

procedure TDCLGrid.AddEdit(Field: TDCLField);
begin
end;

procedure TDCLGrid.AddField(Field: TDCLField);
begin
end;

procedure TDCLGrid.AddFieldBox(Field: TDCLField; FieldBoxType: TFieldBoxType; NamePrefix: String);
begin
end;

procedure TDCLGrid.AddLabel(Field: TDCLField; Caption: String);
begin
end;

procedure TDCLGrid.AddLookUp(Field: TDCLField);
begin
end;

procedure TDCLGrid.AddLookupTable(Field: TDCLField);
begin
end;

procedure TDCLGrid.AddMediaFieldGroup(Parent: TWinControl; Align: TAlign; GroupType: TGroupType;
  var Field: TDCLField);
begin
end;

function TDCLGrid.AddPartPage(Caption: String; Data: TDataSource; Style:TDataControlType): TDCLGrid;
begin
end;

procedure TDCLGrid.AddPopupMenuItem(Caption, ItemName: String; Action: TNotifyEvent;
  AChortCutKey: String; Tag: Integer; PictType: String);
begin
  ItemMenu:=TMenuItem.Create(PopupGridMenu);
  ItemMenu.Tag:=Tag;
  ItemMenu.Caption:=Caption;
  ItemMenu.Name:=ItemName;
  ItemMenu.OnClick:=Action;
  ItemMenu.Bitmap.Assign(DrawBMPButton(PictType));
  ItemMenu.Bitmap.TransparentColor:=clWhite;
  ItemMenu.Bitmap.TransparentMode:=tmAuto;

{$IFNDEF FPC}
  ItemMenu.ShortCut:=TextToShortCut(AChortCutKey);
{$ENDIF}
  PopupGridMenu.Items.Add(ItemMenu);
end;

procedure TDCLGrid.AddRollBar(Field: TDCLField);
begin
end;

procedure TDCLGrid.AddSubPopupItem(Caption, ItemName: String; Action: TNotifyEvent;
  ToMenu, Tag: Integer);
begin
end;

procedure TDCLGrid.AddSumGrid(OPL: String);
begin
end;

procedure TDCLGrid.AddToolPartButton(ButtonParam: TButtonParam);
begin
end;

procedure TDCLGrid.AfterCancel(Data: TDataSet);
begin
end;

procedure TDCLGrid.AfterClose(Data: TDataSet);
begin
  Screen.Cursor:=crDefault;
end;

procedure TDCLGrid.AfterEdit(Data: TDataSet);
begin
end;

procedure TDCLGrid.AfterInsert(Data: TDataSet);
begin
end;

procedure TDCLGrid.AfterOpen(Data: TDataSet);
begin
end;

procedure TDCLGrid.AfterPost(Data: TDataSet);
begin
end;

procedure TDCLGrid.AfterRefresh(Data: TDataSet);
begin
  FDCLForm.SetDBStatus('');
  BaseChanged:=False;
end;

procedure TDCLGrid.AutorefreshTimer(Sender: TObject);
begin
  If Not RefreshLock Then
  begin
    RefreshLock:=True;
    If FQuery.State in [dsBrowse] Then
      ReFreshQuery;
    RefreshLock:=False;
  end;
end;

procedure TDCLGrid.BeforeOpen(Data: TDataSet);
begin
  Screen.Cursor:=crSQLWait;
end;

procedure TDCLGrid.BeforePost(Data: TDataSet);
begin
end;

procedure TDCLGrid.BeforeScroll(Data: TDataSet);
begin
end;

procedure TDCLGrid.CalendarOnChange(Sender: TObject);
begin
end;

procedure TDCLGrid.CancelDB;
begin
  SetDataStatus(dssSaved);
end;

procedure TDCLGrid.ChangePartTabPage(Sender: TObject);
begin
end;

procedure TDCLGrid.CheckOnClick(Sender: TObject);
begin
end;

procedure TDCLGrid.ClearNotAllowedOperations;
begin
end;

procedure TDCLGrid.Close;
begin
end;

procedure TDCLGrid.ColumnsManege(Sender: TObject);
begin
end;

procedure TDCLGrid.ContextFieldButtonsClick(Sender: TObject);
begin
end;

procedure TDCLGrid.ContextListChange(Sender: TObject);
var
  ComboNum: Integer;
  Combo: TComboBox;
  tmpQuery: TDCLDialogQuery;
begin
  ComboNum:=(Sender as TComponent).Tag;
  Combo:=(Sender as TComboBox);
  If Trim(Combo.Text)<>'' Then
  begin
    tmpQuery:=TDCLDialogQuery.Create(nil);
    tmpQuery.Name:='tmpContextListQ_'+IntToStr(UpTime);
    FDCLLogOn.SetDBName(tmpQuery);

    If ContextLists[ComboNum].Table<>'' Then
      tmpQuery.SQL.Text:='select '+ContextLists[ComboNum].KeyField+' from '+ContextLists[ComboNum]
        .Table+' where '+ContextLists[ComboNum].Field+'='+GPT.StringTypeChar+Combo.Text+
        GPT.StringTypeChar
    Else
    begin
      If PosEx(' where ', ContextLists[ComboNum].SQL)<>0 Then
        tmpQuery.SQL.Text:=ContextLists[ComboNum].SQL+' and '+ContextLists[ComboNum].Field+'='+
          GPT.StringTypeChar+Combo.Text+GPT.StringTypeChar
      Else
        tmpQuery.SQL.Text:=ContextLists[ComboNum].SQL+' where '+ContextLists[ComboNum].Field+'='+
          GPT.StringTypeChar+Combo.Text+GPT.StringTypeChar;
    end;

    tmpQuery.Open;

    If Not tmpQuery.IsEmpty Then
    begin
      if not ContextLists[ComboNum].NoData and FQuery.CanModify then
      begin
        If (FQuery.State=dsBrowse) Then
          FQuery.Edit;
        FQuery.FieldByName(ContextLists[ComboNum].DataField).AsInteger:=
          tmpQuery.FieldByName(ContextLists[ComboNum].KeyField).AsInteger;
      end;
      if FDCLLogOn.Variables.Exists(GetNamespace, ContextLists[ComboNum].Variable) then
      begin
        FDCLLogOn.Variables.Variables[GetNamespace, ContextLists[ComboNum].Variable]:=tmpQuery.FieldByName(ContextLists[ComboNum].KeyField).AsString;
      end;
    end;
    tmpQuery.Close;
    FreeAndNil(tmpQuery);
  end;
end;

procedure TDCLGrid.ContextListKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  ComboNum: Integer;
  tmpQuery: TDCLDialogQuery;
  Combo: TComboBox;
begin
  ComboNum:=(Sender as TComponent).Tag;
  Combo:=(Sender as TComboBox);
  If (Key=13)and(Shift=[ssCtrl]) Then
    If Combo.Text<>'' Then
    begin
      tmpQuery:=TDCLDialogQuery.Create(nil);
      tmpQuery.Name:='ContextListKeyDown_'+IntToStr(UpTime);
      FDCLLogOn.SetDBName(tmpQuery);
      tmpQuery.SQL.Text:='select '+ContextLists[ComboNum].Field+', '+ContextLists[ComboNum].KeyField
        +' from '+ContextLists[ComboNum].Table+' where '+GPT.UpperString+ContextLists[ComboNum]
        .Field+GPT.UpperStringEnd+' like '+GPT.UpperString+GPT.StringTypeChar+'%'+Combo.Text+'%'+
        GPT.StringTypeChar+') ';
      tmpQuery.Open;
      tmpQuery.Last;
      tmpQuery.First;

      Combo.Items.Clear;

      If tmpQuery.RecordCount=1 Then
      begin
        if FieldExists(ContextLists[ComboNum].DataField, FQuery) then
        begin
          Combo.Text:=Trim(tmpQuery.FieldByName(ContextLists[ComboNum].Field).AsString);
          If (FQuery.Active and FQuery.CanModify and (FQuery.State=dsBrowse)) Then
          begin
            FQuery.Edit;
            FQuery.FieldByName(ContextLists[ComboNum].DataField).AsInteger:=
              tmpQuery.FieldByName(ContextLists[ComboNum].KeyField).AsInteger;
          end;
        end;
      end;
      While Not tmpQuery.Eof do
      begin
        If Trim(tmpQuery.FieldByName(ContextLists[ComboNum].Field).AsString)<>'' Then
          Combo.Items.Append(Trim(tmpQuery.FieldByName(ContextLists[ComboNum].Field).AsString));
        tmpQuery.Next;
      end;
      tmpQuery.Close;
      FreeAndNil(tmpQuery);

{$IFDEF MSWINDOWS}
      If SendMessage(Combo.Handle, CB_GETDROPPEDSTATE, 0, 0)<>1 Then
        SendMessage(Combo.Handle, CB_SHOWDROPDOWN, 1, 0);
{$ENDIF}
    end;
end;

constructor TDCLGrid.Create(var Form: TDCLForm; Parent: TWinControl; SurfType: TDataControlType;
  Query: TDCLDialogQuery; Data: TDataSource);
begin
end;

procedure TDCLGrid.CreateBookMarkMenu(MenuList: TStringList);
begin

  RefreshBookMarkMenu;
end;

function TDCLGrid.SaveBookMarkMenu: TStringList;
begin
end;

procedure TDCLGrid.DeleteAllBookmarks;
begin
end;

procedure TDCLGrid.CreatePartColumns;
begin
end;

procedure TDCLGrid.CreateFields(FOPL: TStringList);
begin

end;

procedure TDCLGrid.DBEditClick(Sender: TObject);
begin
end;

procedure TDCLGrid.DeleteList(Index: Word);
begin
end;

procedure TDCLGrid.DeleteMenuBookMark(BookMarkNum: Integer);
begin
end;

procedure TDCLGrid.DropListOnSelectItem(Sender: TObject);
begin
end;

procedure TDCLGrid.EditClick(Sender: TObject);
begin
end;

procedure TDCLGrid.EditOnEdit(Sender: TObject);
begin
end;

procedure TDCLGrid.EditOnFloatData(Sender: TObject; var Key: Char);
begin
end;

procedure TDCLGrid.ExcludeNotAllowedOperation(Operation: TNotAllowedOperations);
begin
end;

procedure TDCLGrid.ExecEvents(EventType: TEventsEnum);
begin
end;

procedure TDCLGrid.ExecFilter(Sender: TObject);
begin
end;

procedure TDCLGrid.ExecComboFilter(Sender: TObject);
begin
end;

procedure TDCLGrid.FieldsManege(Sender: TObject);
begin
end;

procedure TDCLGrid.PFind(Sender: TObject);
begin
end;

procedure TDCLGrid.PosToBookMark(Sender: TObject);
begin
end;

function TDCLGrid.FindRaightQuery(): String;
begin
end;

destructor TDCLGrid.Destroy;
begin
end;

procedure TDCLGrid.RefreshBookMarkMenu;
begin
end;

function TDCLGrid.GetColumns: TDBGridColumns;
begin
end;

function TDCLGrid.GetDisplayMode: TDataControlType;
begin
end;

function TDCLGrid.GetFieldCount: Integer;
begin
end;

function TDCLGrid.GetFieldDataType(FieldName: String): TFieldType;
begin
end;

function TDCLGrid.GetFingQuery: String;
begin
end;

function TDCLGrid.GetMultiselect: Boolean;
begin
end;

function TDCLGrid.GetQuery: TDCLQuery;
begin
end;

function TDCLGrid.GetReadOnly: Boolean;
begin
end;

function TDCLGrid.GetSQL: String;
begin
end;

function TDCLGrid.GetSQLFromStore(QueryType: TQueryType): String;
begin
end;

function TDCLGrid.GetSummQuery: String;
begin
end;

function TDCLGrid.GetCurrentPart: TDCLGrid;
begin
end;

function TDCLGrid.GetTablePart(Index: Integer): TDCLGrid;
begin
end;

function TDCLGrid.GetTablePartsCount: Integer;
begin
end;

procedure TDCLGrid.GridDblClick(Sender: TObject);
begin
  ExecEvents(evtLineDblClick);
end;

procedure TDCLGrid.GridDrawDataCell(Sender: TObject; Const Rect: TRect; DataCol: Integer;
  Column: TColumn; State: TGridDrawState);
var
  strTmp: String;
  bmp: TBitmap;
  flg: Boolean;
  BColor: TBrushColor;
begin
  With (Sender as TDCLDBGrid).Canvas do
  begin
    FillRect(Rect);
    If Column.Field is TGraphicField Then
    begin
      If GPT.ShowPicture Then
        try
          bmp:=TBitmap.Create;
          bmp.Assign(Column.Field);
          Draw(Rect.Left, Rect.Top, bmp);
        finally
          FreeAndNil(bmp);
        end;
    end
    Else
    begin
      flg:=False;
      RowColor:=clWhite;
      RowTextColor:=clBlack;

      For BColor in BrushColors do
        If FieldExists(BColor.Key, FQuery) Then
        begin
          strTmp:=BColor.Value;
          If Pos('<>', strTmp)<>0 Then
          begin
            Delete(strTmp, PosEx('<>', strTmp), 2);
            strTmp:=Trim(strTmp);
            If LowerCase(strTmp)<>
              LowerCase(Trim(FQuery.FieldByName(BColor.Key).AsString)) Then
            begin
              RowColor:=BColor.Color;
              RowTextColor:=clWhite;
              flg:=True;
            end;
          end
          Else
          begin
            If Pos('>', strTmp)<>0 Then
            begin
              Delete(strTmp, PosEx('>', strTmp), 1);
              strTmp:=Trim(strTmp);
              If LowerCase(strTmp)<
                LowerCase(Trim(FQuery.FieldByName(BColor.Key).AsString)) Then
              begin
                RowColor:=BColor.Color;
                RowTextColor:=clWhite;
                flg:=True;
              end;
            end
            Else
            begin
              If Pos('<', strTmp)<>0 Then
              begin
                Delete(strTmp, PosEx('<', strTmp), 1);
                strTmp:=Trim(strTmp);
                If LowerCase(strTmp)>
                  LowerCase(Trim(FQuery.FieldByName(BColor.Key).AsString)) Then
                begin
                  RowColor:=BColor.Color;
                  RowTextColor:=clWhite;
                  flg:=True;
                end;
              end
              Else
              begin
                If Pos('<=', strTmp)<>0 Then
                begin
                  Delete(strTmp, PosEx('<=', strTmp), 2);
                  strTmp:=Trim(strTmp);
                  If LowerCase(strTmp)<=
                    LowerCase(Trim(FQuery.FieldByName(BColor.Key)
                        .AsString)) Then
                  begin
                    RowColor:=BColor.Color;
                    RowTextColor:=clWhite;
                    flg:=True;
                  end;
                end
                Else If Pos('>=', strTmp)<>0 Then
                begin
                  Delete(strTmp, PosEx('>=', strTmp), 2);
                  strTmp:=Trim(strTmp);
                  If LowerCase(strTmp)>=
                    LowerCase(Trim(FQuery.FieldByName(BColor.Key)
                        .AsString)) Then
                  begin
                    RowColor:=BColor.Color;
                    RowTextColor:=clWhite;
                    flg:=True;
                  end;
                end
                Else
                begin
                  strTmp:=Trim(strTmp);
                  If LowerCase(strTmp)
                    =LowerCase(Trim(FQuery.FieldByName(BColor.Key)
                        .AsString)) Then
                  begin
                    RowColor:=BColor.Color;
                    RowTextColor:=clWhite;
                    flg:=True;
                  end;
                end;
              end;
            end;
          end;
        end;

      if flg then
      begin
        TDCLDBGrid(Sender).Canvas.Brush.Color:=RowColor;
        TDCLDBGrid(Sender).Canvas.Font.Color:=RowTextColor;
      end;
      TDCLDBGrid(Sender).DefaultDrawColumnCell(Rect, DataCol, Column, State);
    end;
  end;
end;

procedure TDCLGrid.IncXYPos(StepTop, StepLeft: Word; Field: TDCLField);
begin
end;

procedure TDCLGrid.LookupDBScroll(Data: TDataSet);
begin
end;

procedure TDCLGrid.LookupOnClick(Sender: TObject);
begin
end;

procedure TDCLGrid.OnChangeDateBox(Sender: TObject);
begin
end;

procedure TDCLGrid.OnContextFilter(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
end;

procedure TDCLGrid.OnDelete(Data: TDataSet);
begin
  SetDataStatus(dssChanged);
end;

procedure TDCLGrid.OnNotCheckClick(Sender: TObject);
begin
end;

procedure TDCLGrid.Open;
begin
end;

procedure TDCLGrid.OpenQuery(QText: String);
begin
end;

procedure TDCLGrid.PClearAllFind(Sender: TObject);
begin
end;

procedure TDCLGrid.PCopy(Sender: TObject);
begin
  if Assigned(FGrid) then
    Clipboard.AsText:=FGrid.SelectedField.AsString;
end;

procedure TDCLGrid.PCut(Sender: TObject);
begin
  if Assigned(FGrid) then
  begin
    Clipboard.AsText:=FGrid.SelectedField.AsString;
    FGrid.SelectedField.Clear;
  end;
end;

procedure TDCLGrid.PPaste(Sender: TObject);
begin
  if Assigned(FGrid) then
    FGrid.SelectedField.AsString:=Clipboard.AsText;
end;

procedure TDCLGrid.Print(Sender: TObject);
begin
end;

procedure TDCLGrid.PSetFind(Sender: TObject);
begin
end;

procedure TDCLGrid.PUndo(Sender: TObject);
begin
  if Assigned(FGrid) then
  if FGrid.DataSource<>nil then
    if FGrid.DataSource.DataSet<>nil then
      FGrid.DataSource.DataSet.Cancel;
{$IFDEF MSWINDOWS}
  SendMessage(GetFocus, WM_UNDO, 0, 0);
{$ENDIF}
end;

function TDCLGrid.QueryBuilder(QueryMode: Byte): String;
begin
end;

procedure TDCLGrid.ReFreshQuery;
begin
end;

procedure TDCLGrid.RePlaseParams(var Params: String);
begin
end;

procedure TDCLGrid.RollBarOnChange(Sender: TObject);
begin
end;

procedure TDCLGrid.SaveDB;
begin
end;

procedure TDCLGrid.ScrollDB(Data: TDataSet);
begin

  FDCLForm.SetRecNo;



end;

procedure TDCLGrid.SetBookMark(Sender: TObject);
begin
end;

procedure TDCLGrid.SetColumns(Cols: TDBGridColumns);
begin
end;

procedure TDCLGrid.SetDataStatus(Status: TDataStatus);
begin
  Case Status of
  dssChanged:
  begin
    If Assigned(FDCLForm.ParentForm) Then
    begin
      FDCLForm.ParentForm.SetDBStatus(GetDCLMessageString(msModified));
      BaseChanged:=True;
    end;

    FDCLForm.SetDBStatus(GetDCLMessageString(msModified));
    BaseChanged:=True;
  end;
  dssSaved:
  begin
    If Assigned(FDCLForm.ParentForm) Then
    begin
      FDCLForm.ParentForm.SetDBStatus('');
      BaseChanged:=False;
    end;

    FDCLForm.SetDBStatus('');
    BaseChanged:=False;
  end;
  end;
end;

procedure TDCLGrid.SetDisplayMode(DisplayMode: TDataControlType);
begin
end;

procedure TDCLGrid.SetGridOptions(Options: TDBGridOptions);
begin
end;

procedure TDCLGrid.SetMultiselect(Value: Boolean);
begin
end;

procedure TDCLGrid.SetNewQuery(Data: TDataSource);
begin
end;

procedure TDCLGrid.SetQuery(Query: TDCLQuery);
begin
end;

procedure TDCLGrid.SetReadOnly(Value: Boolean);
begin
end;

procedure TDCLGrid.SetSQL(SQL: String);
begin
end;

procedure TDCLGrid.SetSQLToStore(SQL: String; QueryType: TQueryType; Raight: TUserLevelsType);
begin
end;

procedure TDCLGrid.SetTablePart(Index: Integer; Value: TDCLGrid);
begin
end;

procedure TDCLGrid.Show;
var
  i1, ToolButtWidth, ActiveToolButtonsCount: Integer;
  TollButton: TDialogSpeedButton;

  procedure SetPopupMenuItems(WithStructure: Boolean);
  begin
    AddPopupMenuItem(GetDCLMessageString(msFind), 'Find', PFind, 'Ctrl+F',
      0, 'Find');
    If WithStructure Then
      AddPopupMenuItem(GetDCLMessageString(msFindCurrCell), 'FindCurrentCell', PSetFind, 'Alt+F',
        0, 'FindCurrCell');
    AddPopupMenuItem(GetDCLMessageString(msClearAllFind), 'ClearAllFind', PClearAllFind, 'Alt+C',
      0, 'ClearAllFind');
    AddPopupMenuItem('-', 'Separator4', nil, '', 0, '');
    AddPopupMenuItem(GetDCLMessageString(msPrint), 'Print', Print, 'Ctrl+P',
      0, 'Print');
    If WithStructure Then
      AddPopupMenuItem(GetDCLMessageString(msStructure), 'Structure', Structure,
        'Ctrl+S', 0, 'Structure');

    if Assigned(FGrid) then
    begin
      AddPopupMenuItem('-', 'Separator1', nil, '', 0, '');
      AddPopupMenuItem(GetDCLMessageString(msCopy), 'Copy', PCopy, 'Ctrl+C',
        0, 'Copy');
      if not FReadOnly then
      begin
        AddPopupMenuItem(GetDCLMessageString(msCut), 'Cut', PCut, 'Ctrl+X',
          0, 'Cut');
        AddPopupMenuItem(GetDCLMessageString(msPast), 'Paste', PPaste, 'Ctrl+V',
          0, 'Paste');
        AddPopupMenuItem('-', 'Separator2', nil, '', 0, '');
        AddPopupMenuItem(GetDCLMessageString(msCancel), 'Undo', PUndo, 'Ctrl+U',
          0, 'Undo');
      end;
    end;

    If (KeyMarks.KeyField<>'')and FieldExists(KeyMarks.KeyField, FQuery) Then
    begin
      AddPopupMenuItem('-', 'Separator3', nil, '', 0, '');
      AddPopupMenuItem(InitCap(GetDCLMessageString(msBookmark)), 'GetBookMark',
        SetBookMark, 'Ctrl+B', 0, 'BookMark');
    end;
  end;

begin
end;

procedure TDCLGrid.SortDB(Column: TColumn);
begin
end;

procedure TDCLGrid.Structure(Sender: TObject);
begin
end;

procedure TDCLGrid.RePlaseVariables(var VariablesSet: String);
begin
end;

function TDCLGrid.GetNamespace: String;
begin
end;

procedure TDCLGrid.ToolButtonsOnClick(Sender: TObject);
begin
end;

procedure TDCLGrid.TranslateVal(var Params: String);
begin
end;

procedure TDCLGrid.AddEvent(Event: TDCLEvent);
begin
end;

{ TDCLCommandButton }

procedure TDCLCommandButton.AddCommand(Parent: TWinControl; ButtonParams: TButtonParam);
begin
end;

constructor TDCLCommandButton.Create(var DCLLogOn: TDCLLogOn; var DCLForm: TDCLForm);
begin
end;

destructor TDCLCommandButton.Destroy;
begin
end;

procedure TDCLCommandButton.ExecCommand(Sender: TObject);
begin
end;

{ TMainFormAction }

procedure TMainFormAction.CloseMainForm(Sender: TObject; var Action: TCloseAction);
begin
  If Assigned(DCLMainLogOn) then
  Begin
    SaveMainFormPos(DCLMainLogOn, DCLMainLogOn.MainForm, MainFormName);

    EndDCL;
  End;
end;

procedure TMainFormAction.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose:=False;
  If (Not GPT.ExitCnf)and(Not DownLoadProcess) Then
    CanClose:=True;
  If (GPT.ExitCnf)and(Not DownLoadProcess) Then
    If ShowErrorMessage(10, GetDCLMessageString(msDoYouWontTerminateApplicationQ))=1 Then
      CanClose:=True;

  If DownLoadProcess Then
    If ShowErrorMessage(10, GetDCLMessageString(msDownloadInProgress)+'. '+
          GetDCLMessageString(msDoYouWontTerminateApplicationQ))=1 Then
      CanClose:=True;
end;

{ TPrintBase }

procedure TPrintBase.Print(Grid: TDCLDBGrid; Query: TDCLDialogQuery; Caption: String);
begin
end;

procedure TDCLOfficeReport.ReportOpenOfficeWriter(ParamStr: String; Save, Close: Boolean);
begin
end;

procedure TDCLOfficeReport.ReportOpenOfficeCalc(ParamStr: String; Save, Close: Boolean);
begin
end;

procedure TDCLOfficeReport.ReportWord(ParamStr: String; Save, Close: Boolean);
begin
end;

destructor TDCLOfficeReport.Destroy;
begin
end;

procedure TDCLOfficeReport.ReportExcel(ParamStr: String; Save, Close: Boolean);
begin
end;

// ==============================Reports===============================

procedure TDCLTextReport.GrabValOnEdit(Sender: TObject);
begin
end;

procedure TDCLTextReport.ValComboOnChange(Sender: TObject);
begin
end;

procedure TDCLTextReport.GrabDialogButtonsOnClick(Sender: TObject);
begin
end;

procedure TDCLTextReport.GrabDateOnChange(Sender: TObject);
begin
end;

procedure TDCLTextReport.GrabValListOnChange(Sender: TObject);
begin
end;

constructor TDCLTextReport.InitReport(const NameSpace: String; DCLLogOn: TDCLLogOn; DCLGrid: TDCLGrid; OPL: TStringList;
  ParamsSet: Cardinal; Mode: TNewQueryMode);
begin
end;

destructor TDCLTextReport.Destroy;
begin
end;

procedure TDCLTextReport.CloseReport(FileName: String);
begin
end;

function TDCLTextReport.SaveReport(FileName: String): String;
begin
end;

function TDCLTextReport.SetVarToControl(VarName: String): Integer;
begin
end;

function TDCLTextReport.TranslateRepParams(ParamName: String): String;
begin
end;

procedure TDCLTextReport.ReplaseRepParams(var ReplaseText: TStringList);
begin
end;

procedure TDCLTextReport.RePlaseVariables(var VarsSet: String);
begin
end;

procedure TDCLTextReport.PrintigReport;
begin
end;

procedure TDCLTextReport.OpenReport(FileName: String; ViewMode: TReportViewMode);
begin
end;
// =========================================Reports==============================

{ TDCLOfficeReport }

constructor TDCLOfficeReport.Create(DCLLogOn: TDCLLogOn; DCLGrid: TDCLGrid);
begin
end;

{ TDCLBinStore }

procedure TDCLBinStore.ClearData(DataName: String);
begin
end;

destructor TDCLBinStore.Destroy;
begin
end;

procedure TDCLBinStore.CompressData(DataName: String);
begin
end;

constructor TDCLBinStore.Create(DCLLogOn: TDCLLogOn);
begin
end;

procedure TDCLBinStore.DeCompressData(DataName: String);
begin
end;

function TDCLBinStore.MD5(DataName: String): String;
begin
end;

procedure TDCLBinStore.DeleteData(DataName: String);
begin
end;

function TDCLBinStore.GetTemplateFile(Template, FileName, Ext: String): String;
begin
end;

procedure TDCLBinStore.SaveToFile(FileName, DataName: String);
begin
end;

procedure TDCLBinStore.StoreFromFile(FileName, DataName: String; Compress: Boolean);
begin
end;

procedure DisconnectDB;
begin
end;

procedure EndDCL;
begin
  If Assigned(DCLMainLogOn) Then
  begin
    DCLMainLogOn.CloseAllForms;
    DisconnectDB;
    FreeAndNil(DCLMainLogOn);
  end;

{$IFDEF ADO}{$IFNDEF EMBEDDED}
  CoUninitialize;
{$ENDIF}{$ENDIF}
  If GPT.DebugOn and GPT.DebugMesseges Then
    ExecApp('"'+GPT.Viewer+'" "'+IncludeTrailingPathDelimiter(AppConfigDir)+'DebugApp.txt"', '');

  If Assigned(Logger) Then
    FreeAndNil(Logger);
end;

procedure InitDCL(DBLogOn: TDBLogOn);
var
  v1: Integer;
  ShowLogOnForm: Boolean;
  ParamsQuery, RolesQuery1: TDCLDialogQuery;
  Params: TStringList;
{$IFDEF MSWINDOWS}
  MemHnd: HWND;
{$ENDIF}
begin
  ShowFormPanel:=True;
  Path:=ExtractFilePath(Application.ExeName);
  SetCurrentDir(Path);
  InitLangEnv;

  InitGetAppConfigDir;
  DCLMainLogOn:=TDCLLogOn.Create(DBLogOn);
  DCLMainLogOn.RoleOK:=lsNotNeed;
  LoadLangRes(LangName, Path);

  For v1:=1 to ParamCount do
    If ParamStr(v1)='/debug' Then
      GPT.DebugOn:=True;
  DebugProc('DCL version : '+Version);
  ConnectErrorCode:=0;
  If GPT.IniFileName='' Then
    GPT.IniFileName:=Path+'DCL.ini';
  DebugProc('Find ini file: '+GPT.IniFileName);

  {$IFDEF IBALL}
  GPT.IBAll:=True;
  {$ELSE}
  GPT.IBAll:=False;
  {$ENDIF}
  GPT.OldStyle:=False;
  GPT.DebugMesseges:=False;
  GPT.OneCopy:=False;
  GPT.ExitCnf:=False;
  GPT.UseMessages:=True;
  ScriptRunCreated:=False;
  GPT.DebugOn:=False;
  GPT.DialogsSettings:=True;
  GPT.Port:=0;
  {$IFDEF ZEOS}
  GPT.DBType:=DefaultDBType;
  {$ENDIF}
  GPT.UserLogging:=False;
  GPT.UserLoggingHistory:=False;
  GPT.OfficeFormat:=ofMSO;
  GPT.OfficeDocumentFormat:=odfMSO2007;

  GPT.TimeFormat:=DefaultTimeFormat;
  GPT.DateFormat:=DefaultDateFormat;
  GPT.DateSeparator:=DefaultDateSeparator;
  GPT.TimeSeparator:=DefaultTimeSeparator;
{$IFDEF MSWINDOWS}
  SysUtils.GetFormatSettings;
{$ENDIF}
  Params:=TStringList.Create;

  If {$IFNDEF EMBEDDED}FileExists(GPT.IniFileName){$ELSE}True{$ENDIF} Then
  Begin
{$IFNDEF EMBEDDED}
    try
      DebugProc('Open ini file: '+GPT.IniFileName);
      Params.LoadFromFile(GPT.IniFileName);
      DebugProc('Open : OK');
    Except
      DebugProc('Open ini file : Fail');
    end;
{$ENDIF}
    GetParamsStructure(Params);

    LoadLangRes(LangName, Path);

    Logger:=TLogging.Create(IncludeTrailingPathDelimiter(AppConfigDir)+'DebugApp.txt', GPT.DebugOn);
    Logger.Active:=GPT.DebugOn;

    If GPT.StringTypeChar='' Then
      GPT.StringTypeChar:='''';

    If GPT.Viewer='' Then
{$IFDEF MSWINDOWS}
      GPT.Viewer:='notepad';
{$ELSE}
      GPT.Viewer:='pluma';
{$ENDIF}

    TransParams:=True;

    ConnectErrorCode:=DCLMainLogOn.ConnectDB;
    If ConnectErrorCode=0 Then
    begin
{$IFNDEF EMBEDDED}
      GPT.NoParamsTable:=Not DCLMainLogOn.TableExists(GPT.GPTTableName);
      If Not GPT.NoParamsTable Then
      begin
        ParamsQuery:=TDCLDialogQuery.Create(nil);
        ParamsQuery.Name:='InitDCLParams_'+IntToStr(UpTime);
        ParamsQuery.SQL.Text:='select '+GPT.GPTNameField+', '+GPT.GPTValueField+' from '+
          GPT.GPTTableName;
        DCLMainLogOn.SetDBName(ParamsQuery);
        try
          try
            ParamsQuery.Open;
          Except
            GPT.NoParamsTable:=False;
          end;
          ParamsQuery.First;
          Params.Clear;
          While Not ParamsQuery.Eof do
          begin
            Params.Insert(0, ParamsQuery.FieldByName(GPT.GPTNameField).AsString+'='+
                ParamsQuery.FieldByName(GPT.GPTValueField).AsString);
            ParamsQuery.Next;
          end;
          ParamsQuery.Close;
          FreeAndNil(ParamsQuery);
          GetParamsStructure(Params);
        Except
          GPT.NoParamsTable:=False;
        end;
      end;

      GPT.RolesMenuTable:=RolesMenuTable;
{$ENDIF}
      FreeAndNil(Params);

      DCLMainLogOn.WriteBaseUID;

      GPT.TimeStampFormat:=GPT.DateFormat+' '+GPT.TimeFormat;

{$IFDEF MSWINDOWS}
      If GPT.OneCopy Then
      begin
        MemHnd:=CreateFileMapping(HWND($FFFFFFFF), nil, PAGE_READWRITE, 0, 127, MemFileName);
        If GetLastError=ERROR_ALREADY_EXISTS Then
        begin
          CloseHandle(MemHnd);
          ShowErrorMessage(1, GetDCLMessageString(msAppRunning));
          Halt;
        end;
      end;
{$ENDIF}
      ShowLogOnForm:=False;
      If ShiftDown Then
      begin
        ShowLogOnForm:=True;
        // GPT.DCLUserName:='';
        GPT.EnterPass:='';
      end;

      DCLMainLogOn.SQLMon:=TDCLSQLMon.Create(IncludeTrailingPathDelimiter(AppConfigDir)+
          'SQLMon.txt');

      RolesQuery1:=TDCLDialogQuery.Create(nil);
      RolesQuery1.Name:='InitRolesQuery_'+IntToStr(UpTime);
      DCLMainLogOn.SetDBName(RolesQuery1);
{$IFNDEF EMBEDDED}
      GPT.NoUsersTable:=not DCLMainLogOn.TableExists(UsersTable);
      If not GPT.NoUsersTable then
      Begin
        RolesQuery1.SQL.Text:='select count(*) from '+UsersTable;

        try
          RolesQuery1.Open;
          GPT.DisableLogOnWithoutUser:=RolesQuery1.Fields[0].AsInteger>0;
          RolesQuery1.Close;
        Except
          GPT.DCLUserName:='';
          ShowLogOnForm:=False;
          DebugProc(GetDCLMessageString(msTable)+' '+GetDCLMessageString(msUsers)+' "'+UsersTable+
              '" '+GetDCLMessageString(msNotFoundM)+'.');
        end;
      End
      Else
        GPT.DisableLogOnWithoutUser:=False;
{$ELSE}
      GPT.DisableLogOnWithoutUser:=False;
{$ENDIF}
      If DCLMainLogOn.Login(GPT.DCLUserName, GPT.EnterPass, ShowLogOnForm)<>lsLogonOK Then
        DCLMainLogOn.RoleOK:=lsRejected;
      If DCLMainLogOn.RoleOK=lsNotNeed Then
        DCLMainLogOn.RoleOK:=lsLogonOK;
    end;
  End
  Else
  begin
    ShowErrorMessage(1, GetDCLMessageString(msConfigurationFileNotFound)+' . 0010');
    DebugProc('Bye, Configuration file not fund.');
    ConnectErrorCode:=100;
  end;
end;
{ TFieldGroup }

procedure TFieldGroup.Clear(Sender: TObject);
begin
end;

constructor TFieldGroup.Create(Parent: TWinControl; Data: TDataSource; Field: TDCLField;
  LayoutParams: TDCLLayoutParams; aAlign: TAlign; GroupType: TGroupType);
begin
end;

destructor TFieldGroup.Destroy;
begin
end;

procedure TFieldGroup.Load(Sender: TObject);
begin
end;

procedure TFieldGroup.LoadData(FileName: String);
begin
end;

procedure TFieldGroup.OnDBImageRead(Sender: TObject; S: TStream; var GraphExt: String);
begin
end;

procedure TFieldGroup.Save(Sender: TObject);
begin
end;

procedure TFieldGroup.SaveData(FileName: String);
begin end;

{ TBaseBinStore }

procedure TBaseBinStore.ClearData(DataName: String; FindType: TFindType);
begin
end;

destructor TBaseBinStore.Destroy;
begin
end;

procedure TBaseBinStore.CompressData(DataName, Data: String; FindType: TFindType);
begin end;

constructor TBaseBinStore.Create(DCLLogOn: TDCLLogOn; TableName, KeyField, NameField,
  DataField: String);
begin
end;

procedure TBaseBinStore.DeCompressData(DataName, Data: String; FindType: TFindType);
begin
end;

function TBaseBinStore.MD5(DataName: String; FindType: TFindType): String;
begin
end;

procedure TBaseBinStore.DeleteData(DataName: String; FindType: TFindType);
begin
end;

function TBaseBinStore.GetData(DataName: String; FindType: TFindType): TMemoryStream;
begin
end;

function TBaseBinStore.IsDataExist(DataName: String; FindType: TFindType): Boolean;
begin
end;

procedure TBaseBinStore.SaveToFile(FileName, DataName: String; FindType: TFindType);
begin
end;

procedure TBaseBinStore.SetData(DataName, Data: String; FindType: TFindType; Stream: TMemoryStream;
  Compress: Boolean);
begin
end;

procedure TBaseBinStore.StoreFromFile(FileName, DataName, Data: String; FindType: TFindType;
  Compress: Boolean);
begin end;

{ TBinStore }

procedure TBinStore.ClearData(DataName: String);
begin
end;

destructor TBinStore.Destroy;
begin
end;

procedure TBinStore.CompressData(DataName, Data: String);
begin
end;

constructor TBinStore.Create(DCLLogOn: TDCLLogOn; FindType: TFindType;
  TableName, KeyField, NameField, DataField: String);
begin
end;

procedure TBinStore.DeCompressData(DataName, Data: String);
begin
end;

function TBinStore.MD5(DataName: String): String;
begin
end;

procedure TBinStore.DeleteData(DataName: String);
begin
end;

function TBinStore.GetData(DataName: String): TMemoryStream;
begin
end;

function TBinStore.IsDataExist(DataName: String): Boolean;
begin
end;

procedure TBinStore.SaveToFile(FileName, DataName: String);
begin
end;

procedure TBinStore.SetData(DataName, Data: String; Stream: TMemoryStream; Compress: Boolean);
begin
end;

procedure TBinStore.StoreFromFile(FileName, DataName, Data: String; Compress: Boolean);
begin
end;

{$IFNDEF EMBEDDED}
Initialization

  InitDCL(nil);

// Finalization
// EndDCL;
{$ENDIF}

end.
