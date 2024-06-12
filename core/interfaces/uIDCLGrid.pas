unit uIDCLGrid;
{$mode delphi}

interface

uses
  Classes, Generics.Collections, Controls, DB, DBGrids,
  uDCLConst, uDCLData, uDCLField, uDCLCommandButton, uDCLQuery;

type
  IDCLGrid=interface
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

    procedure ResetFieldsSettings;

    function GetQuery: TDCLQuery;
    function GetData: TDataSource;
    function GetReadOnly: Boolean;
    procedure SetReadOnly(Value: Boolean);
    function GetTableParts: TList<IDCLGrid>;
    function GetEdits: TList<TDCLEdit>;
    procedure SetMultiSelect(Value: Boolean);
    function GetMultiSelectMode: Boolean;
    function GetFieldsCount: Integer;
    procedure SetGridStyle(Value: TGridStyle);
    function GetGridStyle: TGridStyle;
    function GetControlType: TDataControlType;
    Function GetUserLevel: TUserLevelsType;
    function GetCurrentTablePart: IDCLGrid;
    procedure SetNoDataField(Value: Boolean);
    function GetNoDataField: Boolean;
    procedure SetPrintTool(Value: Boolean);
    function GetPrintTool: Boolean;
    function GetDependField: String;
    procedure SetDependField(Value: String);
    function GetMasterDataField: String;
    procedure SetMasterDataField(Value: String);
    function GetMasterValueVariableName: String;
    procedure SetMasterValueVariableName(Value: String);
    function GetNavigatorVisible: Boolean;
    procedure SetNavigatorVisible(Value: Boolean);
    function GetFlatNavigator: Boolean;
    procedure SetFlatNavigator(Value: Boolean);
    function GetSelectedRows: TBookmarkList;
    procedure Show;
    function GetComponent: TWinControl;

    property Query: TDCLQuery read GetQuery;
    property Data: TDataSource read GetData;
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly;
    property TableParts: TList<IDCLGrid> read GetTableParts;
    property Edits: TList<TDCLEdit> read GetEdits;
    property FieldsCount: Integer read GetFieldsCount;
    property CurrentTablePart: IDCLGrid read GetCurrentTablePart;
    property Style: TGridStyle read GetGridStyle write SetGridStyle;
    property ControlType: TDataControlType read GetControlType;
    property DependField: String read GetDependField write SetDependField;
    property MasterDataField: String read GetMasterDataField write SetMasterDataField;
    property MasterValueVariableName: String read GetMasterValueVariableName write SetMasterValueVariableName;
    property NoDataField: Boolean read GetNoDataField write SetNoDataField;
    property MultiSelect: Boolean read GetMultiSelectMode write SetMultiSelect;
    property RightsLevel: TUserLevelsType read GetUserLevel;
    property PrintTool: Boolean read GetPrintTool write SetPrintTool;
    property NavigatorVisible: Boolean read GetNavigatorVisible write SetNavigatorVisible;
    property FlatNavigator: Boolean read GetFlatNavigator write SetFlatNavigator;
    property SelectedRows: TBookmarkList read GetSelectedRows;
  end;

implementation

end.
