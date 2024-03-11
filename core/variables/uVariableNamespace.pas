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

end.

