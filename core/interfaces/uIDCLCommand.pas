unit uIDCLCommand;
{$mode Delphi}

interface

uses
  Classes, SysUtils;

type
  IDCLCommand = interface
    function RunCommandScript(constref CommandName: String): Boolean;
    procedure RunCommand(Command: String);
    procedure SelectRunType(const Command: String);

    procedure About;

    function GetDisableAutoRefresh: Boolean;
    procedure SetDisableAutoRefresh(Value: Boolean);

    property DisableAutoRefresh: Boolean read GetDisableAutoRefresh write SetDisableAutoRefresh;
  end;

implementation

end.

