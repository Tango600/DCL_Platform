unit uIDCLMain;

interface

uses
  Forms, Classes, Generics.Collections, Controls,
  uDCLConst, uIDCLForm, uIDCLGrid, uDCLVariables, uDCLDBConnector, uDCLImages,
  uDCLData, uDCLScriptsPackage, uReturnFormValue;

type
  IDCLMain=interface
    function GetDBConnector: TDCLDBConnector;
    function GetForms: TList<IDCLForm>;
    procedure CloseAllDialogs;
    procedure CreateMenu(MainForm: TForm);
    function IsNeedLogin: Boolean;

    function GetVariables: TVariables;

    function GetScriptText(ScriptName: String): TStringList;
    procedure OpenDialog(DialogName: String; Host: Boolean);
    procedure RunCommandScript(CommandName: String);
    function GetLoadedScripts: TList<TDCLScriptItem>;
    function GetPackages: TList<TPackageInfo>;

    procedure NotifyForms(Action: TFormsNotifyAction);
    procedure NotifyForm(Form: IDCLForm; Action: TFormsNotifyAction);

    function CreateDialog(NameSpace, DialogName: String; NoContext: Boolean;
      ParentForm: IDCLForm; Grid: IDCLGrid; UserLevel: TUserLevelsType;
      ReturnValueParams: TReturnValueParams; Modal: Boolean): IDCLForm;
    function CloseForm(Form: IDCLForm; Force: Boolean): IDCLForm;
    function CloseDialog(var Form: IDCLForm; Force: Boolean): Boolean;
    procedure ReleaseForm(const Form: IDCLForm);
    procedure GetValueProc(NameSpace: String; Form: IDCLForm; ReturnValue: TReturnFormValue);

    procedure Update;

    procedure About;
    procedure ExitApp;
    function GetImageList: TImageList;
    function GetImageIndex(PictureType: TPicturesTypes): Integer;
    function GetImageIndexes: TDictionary<TPicturesTypes, Integer>;

    procedure LoadPackageFromFile(FileName: String; Run: Boolean);
    procedure ClearScriptPool;
  end;

implementation

end.
