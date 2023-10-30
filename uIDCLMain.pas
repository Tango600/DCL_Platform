unit uIDCLMain;

interface

uses
  Forms, Classes, Generics.Collections, Controls,
  uDCLConst, uDCLVariables, uDCLDBConnector, uDCLImages, uDCLScriptsPackage;

type
  IDCLMain=interface
    function GetDBConnector: TDCLDBConnector;
    function GetForms: TList<TForm>;
    procedure CloseAllDialogs;
    procedure CreateMenu(MainForm: TForm);

    function GetVariables: TVariables;

    function GetScriptText(ScriptName: String): TStringList;
    procedure OpenDialog(DialogName: String);
    procedure RunCommand(CommandName: String);
    function GetLoadedScripts: TList<TDCLScriptItem>;

    procedure NotifyForms(Action: TFormsNotifyAction);
    procedure NotifyForm(Form: TForm; Action: TFormsNotifyAction);

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
