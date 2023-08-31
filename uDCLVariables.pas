unit uDCLVariables;
{$I DefineType.pas}

interface

uses
  Classes, SysUtils, Generics.Collections,
  uDCLConst, uDCLData, uDCLTypes;

type

  { TVariables }

  TVariables=class
  private
    FVariables: TList<TVariable>;

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

{ TVariables }

constructor TVariables.Create;
begin
  inherited Create;
  FVariables:=TList<TVariable>.Create;
end;

function TVariables.Exists(NameSpace, VariableName: String): Boolean;
var
  i: TVariable;
begin
  Result:=False;
  If VariableName<>'' Then
  begin
    For i in FVariables do
    begin
      If (LowerCase(Namespace)=LowerCase(i.NameSpace)) and (LowerCase(i.Name)=LowerCase(Trim(VariableName))) Then
      begin
        Result:=True;
        break;
      end;
    end;
  end;
end;

procedure TVariables.NewVariable(const NameSpace, VariableName, Value: String);
var
  v: TVariable;
begin
  if VariableName<>'' then
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
end;

procedure TVariables.NewVariableWithTest(const Namespace, VariableName: String);
var
  v: TVariable;
begin
  if VariableName<>'' then
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
end;

procedure TVariables.FreeVariable(const Namespace, VariableName: String);
var
  i: TVariable;
begin
  If VariableName<>'' Then
  begin
    For i in FVariables do
    begin
      If (LowerCase(Namespace)=LowerCase(i.NameSpace)) and (LowerCase(i.Name)=LowerCase(Trim(VariableName))) Then
      begin
        FVariables.Remove(i);
        break;
      end;
    end;
  end;
end;

function TVariables.GetVariableByName(const Namespace, VariableName: String
  ): String;
var
  i: TVariable;
begin
  Result:='';
  If VariableName<>'' Then
  begin
    For i in FVariables do
    begin
      If (LowerCase(Namespace)=LowerCase(i.NameSpace)) and (LowerCase(i.Name)=LowerCase(Trim(VariableName))) Then
      begin
        Result:=i.Value;
        break;
      end;
    end;
  end;
end;

procedure TVariables.SetVariableByName(const Namespace, VariableName, Value: String);
var
  v, i: TVariable;
begin
  If VariableName<>'' Then
  begin
    v:=nil;
    For i in FVariables do
    begin
      If (LowerCase(Namespace)=LowerCase(i.NameSpace)) and (LowerCase(i.Name)=LowerCase(Trim(VariableName))) Then
      begin
        v:=i;
        break;
      end;
    end;

    if Assigned(v) then
    begin
      v.Value:=Value;
    end;
  end;
end;

end.

