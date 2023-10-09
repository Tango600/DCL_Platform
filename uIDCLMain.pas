unit uIDCLMain;
{$I DefineType.pas}

interface

uses
  Forms, Classes, Generics.Collections,
  uDCLConst, uDCLVariables, uDCLDBConnector;

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

    procedure NotifyForms(Action: TFormsNotifyAction);
    procedure NotifyForm(Form: TForm; Action: TFormsNotifyAction);

    procedure About;
    procedure Exit;

    procedure LoadScriptsFromFile(FileName: String; Run: Boolean);
    procedure ClearScriptPool;
  end;

implementation

end.
