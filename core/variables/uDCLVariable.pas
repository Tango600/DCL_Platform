unit uDCLVariable;
{$mode Delphi}

interface

uses
  uVariableNamespace;

type
  TVariable=class
    NameSpace: TVariableNamespace;
    Name: String;
    Value: String;
  End;

implementation

end.

