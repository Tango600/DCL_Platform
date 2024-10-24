unit uKeyData;
{$mode Delphi}

interface

type

  { TKeyData }

  TKeyData = class
  private
    function Validate: Boolean;
  public
    KeyType: String;
    AllDays, RemainDays: Integer;

    constructor Create;

    property IsValid: Boolean read Validate;
  end;

implementation

{ TKeyData }

function TKeyData.Validate: Boolean;
begin
  if RemainDays=0 then
    Result:=False
  else
    Result:=True;
end;

constructor TKeyData.Create;
begin
  inherited Create;

  AllDays:=0;
  RemainDays:=0;
end;

end.

