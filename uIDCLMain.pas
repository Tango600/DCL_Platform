unit uIDCLMain;
{$I DefineType.pas}

interface

uses
  Forms,
  uDCLVariables;

type
  IDCLMain=interface
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
