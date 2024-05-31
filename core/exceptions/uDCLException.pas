unit uDCLException;
{$mode Delphi}

interface

uses
  SysUtils;

type

  { TDCLException }

  TDCLException = class(Exception)
  public
    constructor Create(ErrorCode: Integer; AddText: String='');
  end;

implementation

uses
  uDCLMultiLang;

{ TDCLException }

constructor TDCLException.Create(ErrorCode: Integer; AddText: String);
var
  MessageText: String;
begin
  MessageText:=GetDCLErrorString(ErrorCode, AddText);
  inherited Create(MessageText);
end;

end.

