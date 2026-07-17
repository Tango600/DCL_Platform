unit uIDCLForm;
{$mode delphi}

interface

uses
  Forms, Classes, Generics.Collections, Controls,
  uIDCLGrid, uDCLData, uReturnFormValue, uDCLConst;

type
  IDCLForm=interface
    procedure ForceClose;
    procedure RefreshForm;
    function GetForm: TForm;

    procedure SetRecordsStatus(RecNo, RecordCount: LongInt); overload;
    procedure SetDBStatus(Str: String);

    procedure SetInfoStatus(const Str: String);
    procedure AddInfoStatus(const Str: String; Width: Integer);
    procedure SetStatusNum(const Str: String; Num, Width: Integer);
    procedure DeleteStatus(Num: Integer);
    procedure DeleteAllStatus;

    function GetCurrentGrid: IDCLGrid;
    function GetStackLevel: Integer;
    procedure SetStackLevel(Value: Integer);
    function GetDialogName: String;
    function GetGrids: TList<IDCLGrid>;
    function GetParentDialog: IDCLForm;
    function IsReject: Boolean;
    function GetUserLevel: TUserLevelsType;
    procedure SetReturnValueParams(Value: TReturnValueParams);
    function GetReturnValueParams: TReturnValueParams;
    procedure GetValueProc(Value: TReturnFormValue);
    function GetIsSingle: Boolean;

    function GetCapt: String;
    procedure SetCapt(const Value: String);

    property Grids: TList<IDCLGrid> read GetGrids;
    property CurrentGrid: IDCLGrid read GetCurrentGrid;
    property DialogName: String read GetDialogName;
    property IsSingle: Boolean read GetIsSingle;
    property ReturnValueParams: TReturnValueParams read GetReturnValueParams write SetReturnValueParams;
    property ParentDialog: IDCLForm read GetParentDialog;
    property Reject: Boolean read IsReject;
    property RightsLevel: TUserLevelsType read GetUserLevel;
    property StackLevel: Integer read GetStackLevel write SetStackLevel;

    //region TForm
    procedure SetWindowState(Value : TWindowState);
    function GetWindowState: TWindowState;
    function GetModalResult: TModalResult;
    procedure SetModalResult(Value: TModalResult);
    function GetFormStyle: TFormStyle;
    procedure SetFormStyle(Value: TFormStyle);
    function GetShowing: Boolean;

    procedure Hide;
    procedure Show;
    procedure ShowOnTop;
    function ShowModal: Integer;
    procedure SetFocus; override;
    procedure Close;

    property WindowState: TWindowState read GetWindowState write SetWindowState default wsNormal;
    property FormStyle: TFormStyle read GetFormStyle write SetFormStyle default fsNormal;
    property Showing: Boolean read GetShowing;
    property Caption: String read GetCapt write SetCapt;
    property ModalResult: TModalResult read GetModalResult write SetModalResult;
    //end region
  end;

implementation

end.
