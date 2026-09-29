unit uDCLAbstractMenu;
{$I DefineType.pas}

interface

uses
  Classes, SysUtils, Generics.Collections, Generics.Defaults,
  uDCLConst, uDCLDBConnector, uIDCLMain, uDCLDBAwareTypes, uDCLDBStructure;

type
  TMenuConstructionItem=class
    Id, Parent: Integer;
    Command, Title: String;
  end;

  { TComparerMenuItem }

  TComparerMenuItem = class(TInterfacedObject, IComparer<TMenuConstructionItem>)
    function Compare(const Left, Right: TMenuConstructionItem): Integer; overload;
  end;

  { TDCLAbstractMenu }

  TDCLAbstractMenu=class(TComponent)
  private
    FMenuTitle: String;
    NoDCLTable: Boolean;

    function GetMenuCommandById(Ident: Integer): String;
  protected
    FMain: IDCLMain;
    FDBConnector: TDCLDBConnector;
    LocalQuery: TDCLSimplyQuery;
  public
    constructor Create(const Main: IDCLMain); overload;
    destructor Destroy; override;

    procedure About(Sender: TObject);

    procedure RunMenu(const Ident: Integer);
    function ExistItemByIdent(var List: TList<TMenuConstructionItem>; Id: Integer): Boolean;

    property MenuTitle: String read FMenuTitle;
  end;

implementation

uses
  uDCLGlobalVariables, uDCLQueryUtils, uDCLData, uDBUtils;

{ TDCLMenu }

procedure TDCLAbstractMenu.About;
begin
  FMain.About;
end;

function TDCLAbstractMenu.GetMenuCommandById(Ident: Integer): String;
var
  i: TDCLScript;
begin
  Result:='';
  i:=FMain.GetScriptByIdent(Ident, False);
  if Assigned(i) then
  begin
    if i.Command<>'' then
    begin
      Result:=I.Command;
    end;
  end;
end;

procedure TDCLAbstractMenu.RunMenu(const Ident: Integer);
var
  p: Integer;
  DialogName: String;
  Host: Boolean;
  Scr: TStringList;
begin
  if Ident>0 then
  begin
    Host:=False;
    DialogName:=GetMenuCommandById(Ident);
    p:=Pos(';', DialogName);
    if p<>0 then
    begin
      Host:=DialogName.Substring(p+1).ToLower.IndexOf('host=1')<>0;
      DialogName:=DialogName.Substring(0, p-1);
    end;
    Scr:=FMain.GetScriptText(DialogName);
    if (Scr.Count>0) and (Pos('script type=command', Scr[0].ToLower)<>0) then
      FMain.RunCommandScript(DialogName)
    else
      FMain.OpenDialog(DialogName, Host);
  end
  else
  begin
    if Ident=-999 then
      About(nil);
  end;
end;

function TDCLAbstractMenu.ExistItemByIdent(var List: TList<TMenuConstructionItem>; Id: Integer): Boolean;
var
  I: TMenuConstructionItem;
begin
  Result:=False;
  for I in List do
  begin
    if I.Id=Id then
    begin
      Result:=True;
      break;
    end;
  end;
end;

function TComparerMenuItem.Compare(const Left, Right: TMenuConstructionItem): Integer;
begin
  if Left.Id<Right.Id then
    Result:=-1
  else if Left.Id>Right.Id then
    Result:=1
  else if Left.Id=Right.Id then
    Result:=0;
end;

constructor TDCLAbstractMenu.Create(const Main: IDCLMain);
begin
  NoDCLTable:=False;
  FMain:=Main;
  FDBConnector:=Main.GetDBConnector;

  LocalQuery:=TDCLSimplyQuery.Create(Self);
  FDBConnector.SetConnector(LocalQuery);

  {$IFDEF ALLOWNODCL}
  if not FMain.TestScriptTable then
    NoDCLTable:=True;
  {$ENDIF}

  FMenuTitle:='';
  if not NoDCLTable then
  begin
    LocalQuery.SQL.Text:=GetRolesQueryText(IdentifyField+'=0', '');
    LocalQuery.Open;
    LocalQuery.First;
    FMenuTitle:=LocalQuery.FieldByName(DCLNameField).AsString;
    LocalQuery.Close;

    LocalQuery.SQL.Text:=GetRolesQueryText(IdentifyField+' between 20051 and 20100', GPT.UserID);
    LocalQuery.Open;
    while not LocalQuery.EOF do
    begin
      FMenuTitle:=FMenuTitle+' '+TrimRight(LocalQuery.FieldByName(DCLNameField).AsString);
      LocalQuery.Next;
    end;
    LocalQuery.Close;
  end;
end;

destructor TDCLAbstractMenu.Destroy;
begin
  FMain:=nil;
  inherited Destroy;
end;

end.

