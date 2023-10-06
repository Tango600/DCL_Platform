unit uIDCLMain;
{$I DefineType.pas}

interface

uses
  Forms, Generics.Collections,
  uDCLVariables, uDCLDBConnector;

type
  IDCLMain=interface
    function GetDBConnector: TDCLDBConnector;
    function GetForms: TList<TForm>;
    procedure CloseAllDialogs;
    procedure CreateMenu(MainForm: TForm);

    function GetVariables: TVariables;

    procedure OpenDialog(DialogName: String);
    procedure RunCommand(CommandName: String);
    procedure About;

    procedure Exit;
  end;

implementation

end.
