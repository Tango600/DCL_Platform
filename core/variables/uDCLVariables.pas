unit uDCLVariables;
{$mode Delphi}

interface

uses
  Classes, SysUtils, Generics.Collections,
  uDCLConst, uDCLData;

type

  { TVariables }

  TVariables=class
  private
    FVariables: TList<TVariable>;

    function Find(const Namespace, VariableName: String): TVariable;

    function GetVariableByName(const Namespace, VariableName: String): String; overload;
    procedure SetVariableByName(const Namespace, VariableName, Value: String);
  public
    constructor Create;

    function Exists(NameSpace, VariableName: String): Boolean;
    procedure NewVariable(const NameSpace, VariableName, Value: String);
    procedure NewVariableWithTest(const Namespace, VariableName: String);
    procedure FreeVariable(const Namespace, VariableName: String);

    property Variables[Const Namespace, VariableName: String]: String read GetVariableByName
      write SetVariableByName;

    property VariablesList: TList<TVariable> read FVariables;
  end;


implementation

function CompareVariable(Variable: TVariable; Namespace, VariableName: String): Boolean;
begin
  Result:=(LowerCase(Namespace)=LowerCase(Variable.NameSpace)) and (LowerCase(Variable.Name)=LowerCase(Trim(VariableName)));
end;

{ TVariables }

constructor TVariables.Create;
begin
  inherited Create;
  FVariables:=TList<TVariable>.Create;
end;

function TVariables.Exists(NameSpace, VariableName: String): Boolean;
begin
  Result:=Assigned(Find(Namespace, VariableName));
end;

procedure TVariables.NewVariable(const NameSpace, VariableName, Value: String);
var
  v: TVariable;
begin
  If not Exists(Namespace, VariableName) Then
  begin
    v:=TVariable.Create;
    v.NameSpace:=Trim(Namespace);
    v.Name:=Trim(VariableName);
    v.Value:=Value;
    FVariables.Add(v);
  end
  Else
  begin
    SetVariableByName(Namespace, VariableName, Value);
  end;
end;

procedure TVariables.NewVariableWithTest(const Namespace, VariableName: String);
var
  v: TVariable;
begin
  If not Exists(Namespace, VariableName) Then
  begin
    v:=TVariable.Create;
    v.NameSpace:=Trim(Namespace);
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

function TVariables.Find(const Namespace, VariableName: String): TVariable;
var
  i: TVariable;
begin
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

    For i in FVariables do
    begin
      If CompareVariable(i, '', VariableName) Then
      begin
        Result:=i;
        Exit;
      end;
    end;
  end;
end;

function TVariables.GetVariableByName(const Namespace, VariableName: String
  ): String;
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

procedure TVariables.SetVariableByName(const Namespace, VariableName, Value: String);
var
  v: TVariable;
begin
  If VariableName<>'' Then
  begin
    v:=Find(Namespace, VariableName);
    if Assigned(v) then
    begin
      v.Value:=Value;
    end;
  end;
end;

end.

