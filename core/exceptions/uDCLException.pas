unit uDCLException;
{$mode Delphi}

interface

uses
  SysUtils;

type

  { TDCLException }

  TDCLException = class(Exception)
  public
    constructor Create(ErrorCode: Integer; AddText: String=''; ShowMessage: Boolean=True);
  end;

implementation

uses
  uDCLMessages;

{ TDCLException }

constructor TDCLException.Create(ErrorCode: Integer; AddText: String; ShowMessage: Boolean=True);
begin
  inherited Create(AddText);
  if ShowMessage then
  begin
    ShowErrorMessage(ErrorCode, AddText);
  end;
end;

end.

