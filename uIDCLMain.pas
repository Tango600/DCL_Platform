unit uIDCLMain;
{$mode Delphi}

interface

uses
  Classes, SysUtils, Forms,
  uDCLForm, uDCLVariables;

type
  IDCLMain=interface
    procedure CreateMenu(MainForm: TForm);

    function CreateForm(DialogName: String): TDCLForm;

    function GetVariables: TVariables;

    procedure OpenDialog(NameSpace, DialogName: String);
    procedure RunCommand(CommandName: String);
    procedure About;
  end;

implementation

end.

