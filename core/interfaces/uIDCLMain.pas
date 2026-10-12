unit uIDCLMain;

interface

uses
  Forms, Classes, Generics.Collections, Controls,
  uDCLConst, uIDCLForm, uIDCLGrid, uDCLVariables, uDCLDBConnector, uDCLImages,
  uDCLData, uDCLScriptsPackage, uReturnFormValue, uIDCLProtectionEngine,
  uVariableNamespace;

type

  { IDCLMain }

  IDCLMain=interface
    function GetDBConnector: TDCLDBConnector;
    function GetForms: TList<IDCLForm>;
    procedure CloseAllDialogs;
    function Start: Boolean;
    procedure RunInterface(MainForm: TForm);
    function GetUsersList: TStringList;
    function CheckPassword(const Login, Password: String): Boolean;
    procedure SetPassword(const Login, Password: String);

    function GetVariables: TVariables;

    function GetScriptText(const ScriptName: String): TStringList;
    function GetScript(const ScriptName: String): TDCLScript;
    function GetScriptByIdent(Ident: Integer; OutRoles: Boolean): TDCLScript;
    procedure RunScript(IdentFrom, IdentTo: Integer);
    procedure OpenDialog(const DialogName: String);
    procedure RunCommandScript(const CommandName: String);
    function GetLoadedScripts: TList<TDCLScriptItem>;
    function GetPackages: TList<TPackageInfo>;

    procedure NotifyForms(Action: TFormsNotifyAction);
    procedure NotifyForm(const Form: IDCLForm; Action: TFormsNotifyAction);

    function CreateDialog(const NameSpace: TVariableNamespace; const DialogName: String; NoContext: Boolean;
      const ParentForm: IDCLForm; const Grid: IDCLGrid; UserLevel: TUserLevelsType;
      ReturnValueParams: TReturnValueParams; Modal: Boolean): IDCLForm;
    function CloseForm(const Form: IDCLForm; Force: Boolean): IDCLForm;
    procedure ReleaseForm(const Form: IDCLForm);
    procedure GetValueProc(const NameSpace: TVariableNamespace; const Form: IDCLForm; ReturnValue: TReturnFormValue);

    procedure About;
    procedure ExitApp;
    function GetImageList: TImageList;
    function GetImageIndex(PictureType: TPicturesTypes): Integer;
    function GetImageIndexes: TDictionary<TPicturesTypes, Integer>;
    function TestScriptTable: Boolean;

    procedure LoadPackageFromFile(const FileName: String; Run: Boolean);
    procedure ClearScriptPool;

    procedure Finalize;

    function GetProtectionEngine: IDCLProtectionEngine;

    property Variables: TVariables read GetVariables;
  end;

implementation

end.
