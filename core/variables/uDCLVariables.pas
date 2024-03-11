unit uDCLVariables;
{$mode Delphi}

interface

uses
  Classes, SysUtils, Generics.Collections,
  uDCLVariable, uVariableNamespace;

type

  { TVariables }

  TVariables=class
  private
    FVariables: TList<TVariable>;
    FNamespaces: TList<TVariableNamespace>;

    function Find(const Namespace, VariableName: String): TVariable;

    function GetVariableByName(const Namespace, VariableName: String): String; overload;
    procedure SetVariableByName(const Namespace, VariableName: String;
      AValue: String);
    function GetNames: TList<String>;
  public
    constructor Create;

    function Exists(const NameSpace, VariableName: String): Boolean;
    procedure NewVariable(const NameSpace: TVariableNamespace; const VariableName, Value: String);
    procedure NewVariableWithTest(const Namespace: TVariableNamespace; const VariableName: String);
    procedure FreeVariable(const Namespace, VariableName: String);
    procedure RegisterNamespace(Value: TVariableNamespace);

    property Variables[Const Namespace, VariableName: String]: String read GetVariableByName
      write SetVariableByName;
    property VariableNamesList: TList<String> read GetNames;
  end;


implementation

function CompareVariable(Variable: TVariable; const Namespace, VariableName: String): Boolean;
begin
  Result:=(LowerCase(Namespace)=LowerCase(Variable.NameSpace.CurrentNamespace)) and (LowerCase(Variable.Name)=LowerCase(Trim(VariableName)));
end;

{ TVariables }

constructor TVariables.Create;
begin
  inherited Create;
  FVariables:=TList<TVariable>.Create;
  FNamespaces:=TList<TVariableNamespace>.Create;
end;

function TVariables.Exists(const NameSpace, VariableName: String): Boolean;
begin
  Result:=Assigned(Find(Namespace, VariableName));
end;

procedure TVariables.NewVariable(const NameSpace: TVariableNamespace; const VariableName, Value: String);
var
  v: TVariable;
begin
  If not Exists(Namespace.CurrentNamespace, VariableName) Then
  begin
    RegisterNamespace(Namespace);
    v:=TVariable.Create;
    v.NameSpace:=Namespace;
    v.Name:=Trim(VariableName);
    v.Value:=Value;
    FVariables.Add(v);
  end
  Else
  begin
    SetVariableByName(Namespace.CurrentNamespace, VariableName, Value);
  end;
end;

procedure TVariables.NewVariableWithTest(const Namespace: TVariableNamespace; const VariableName: String);
var
  v: TVariable;
begin
  If not Exists(Namespace.CurrentNamespace, VariableName) Then
  begin
    RegisterNamespace(Namespace);
    v:=TVariable.Create;
    v.NameSpace:=Namespace;
    v.Name:=Trim(VariableName);
    v.Value:='';
    FVariables.Add(v);
  end;
end;

procedure TVariables.FreeVariable(const Namespace, VariableName: String);
var
  v: TVariable;
begin
  v:=Find(Namespace, VariableName);
  If Assigned(v) Then
  begin
    FVariables.Remove(v);
  end;
end;

procedure TVariables.RegisterNamespace(Value: TVariableNamespace);
var
  v: TVariableNamespace;
begin
  for v in FNamespaces do
  begin
    if Value.IsEqual(v) then
      Exit;
  end;

  FNamespaces.Add(Value);
end;

function TVariables.Find(const Namespace, VariableName: String): TVariable;
var
  i: TVariable;
  ns, n: TVariableNamespace;
begin
  ns:=nil;
  Result:=nil;
  If VariableName<>'' Then
  begin
    For i in FVariables do
    begin
      If CompareVariable(i, Namespace, VariableName) Then
      begin
        Result:=i;
        Exit;
      end;
    end;

    if not Assigned(Result) then
    begin
      For n in FNamespaces do
      begin
        if n.CurrentNamespace=Namespace then
        begin
          ns:=n;
          break;
        end;
      end;

      if Assigned(ns) and (ns.CurrentNamespace<>ns.RootNamespace) then
      begin
        Result:=Find(ns.RootNamespace, VariableName);
      end;
    end;
  end;
end;

function TVariables.GetVariableByName(const Namespace, VariableName: String): String;
var
  v: TVariable;
begin
  Result:='';
  If VariableName<>'' Then
  begin
    v:=Find(Namespace, VariableName);
    If Assigned(v) Then
    begin
      Result:=v.Value;
    end;
  end;
end;

procedure TVariables.SetVariableByName(const Namespace, VariableName: String;
  AValue: String);
var
  v: TVariable;
begin
  If VariableName<>'' Then
  begin
    v:=Find(Namespace, VariableName);
    if Assigned(v) then
    begin
      v.Value:=AValue;
    end;
  end;
end;

function TVariables.GetNames: TList<String>;
var
  v: TVariable;
begin
  Result:=TList<String>.Create;
  for v in FVariables do
    Result.Add(v.Name);
end;

end.

