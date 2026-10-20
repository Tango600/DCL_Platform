unit uDCLException;
{$mode Delphi}

interface

uses
  SysUtils;

type

  { EDCLException }

  EDCLException = class(Exception)
  public
    constructor Create(ErrorCode: Integer; AddText: String='');
  end;

implementation

{ EDCLException }

constructor EDCLException.Create(ErrorCode: Integer; AddText: String);
begin
  inherited Create(AddText);
  HelpContext:=ErrorCode;
end;

end.

