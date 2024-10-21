unit uVariableNamespace;
{$mode Delphi}

interface

type

  { TVariableNamespace }

  TVariableNamespace = class
  private
    FRootNamespace, FCurrentNamespace: String;
  public
    constructor Create(const RootNamespace, CurrentNamespace: String); overload;
    function IsEqual(const Instance: TVariableNamespace): Boolean;

    property RootNamespace: String read FRootNamespace;
    property CurrentNamespace: String read FCurrentNamespace;
  end;

implementation

{ TVariableNamespace }

constructor TVariableNamespace.Create(const RootNamespace,
  CurrentNamespace: String);
begin
  FRootNamespace:=RootNamespace;
  FCurrentNamespace:=CurrentNamespace;
end;

function TVariableNamespace.IsEqual(const Instance: TVariableNamespace): Boolean;
begin
  Result:=(FRootNamespace=Instance.RootNamespace) and (FCurrentNamespace=Instance.CurrentNamespace);
end;

end.

