unit uIDCLMain;
{$I DefineType.pas}

interface

uses
  Forms,
  uDCLForm, uDCLVariables;

type
  IDCLMain=interface
    procedure CloseAllDialogs;
    procedure CreateMenu(MainForm: TForm);

    function CreateForm(DialogName: String): TDCLForm;

    function GetVariables: TVariables;

    procedure OpenDialog(NameSpace, DialogName: String);
    procedure RunCommand(CommandName: String);
    procedure About;

    procedure Exit;
  end;

implementation

end.
