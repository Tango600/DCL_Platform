unit uDCLAbstractMenu;
{$mode Delphi}

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
  protected
    FMain: IDCLMain;
    FDBConnector: TDCLDBConnector;
    iComp: IComparer<TMenuConstructionItem>;
    LocalQuery: TDCLSimplyQuery;
    FMenuTitle: String;
  public
    constructor Create(const Main: IDCLMain); overload;
    destructor Destroy; override;

    procedure About;
    procedure InitActions;
    procedure CloseActions;

    function GetMenuCommandById(Ident: Integer): String;

    procedure RunMenu(const Ident: Integer);
    function ExistItemByIdent(var List: TList<TMenuConstructionItem>; Id: Integer): Boolean;

    procedure RunFromPackage(IdentFrom, IdentTo: Integer);
    procedure RunFromScripts(IdentFrom, IdentTo: Integer);

    property MenuTitle: String read FMenuTitle;
  end;

implementation

uses
  uDCLGlobalVariables, uDCLQueryUtils, uDCLScriptsPackage;

{ TDCLMenu }

procedure TDCLAbstractMenu.About;
begin
  FMain.About;
end;

procedure TDCLAbstractMenu.InitActions;
begin
  RunFromPackage(40001, 40100);
  RunFromScripts(40001, 40100);
end;

procedure TDCLAbstractMenu.CloseActions;
begin
  RunFromPackage(40101, 40200);
  RunFromScripts(40101, 40200);
end;

function TDCLAbstractMenu.GetMenuCommandById(Ident: Integer): String;
var
  I: TDCLScriptItem;
begin
  for I in FMain.GetLoadedScripts do
  begin
    if (Ident>0) and (I.Ident=Ident) then
    begin
      if I.Command<>'' then
      begin
        Result:=I.Command;
        Exit;
      end;
    end;
  end;

  LocalQuery.SQL.Text:=GetRolesQueryText(IdentifyField+'='+IntToStr(Ident), GPT.UserID);
  LocalQuery.Open;
  LocalQuery.First;
  Result:=LocalQuery.FieldByName(CommandField).AsString;
  LocalQuery.Close;
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
      About;
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

procedure TDCLAbstractMenu.RunFromPackage(IdentFrom, IdentTo: Integer);
var
  I: TDCLScriptItem;
  Scr: TStringList;
begin
  for I in FMain.GetLoadedScripts do
  begin
    if (I.Ident>=IdentFrom) and (I.Ident<=IdentTo) then
    begin
      if Assigned(I.ScriptText) then
      begin
        Scr:=TStringList.Create;
        I.ScriptText.Position:=0;
        Scr.LoadFromStream(I.ScriptText);

        FMain.RunCommandScript(Scr.Text);
      end;
    end;
  end;
end;

procedure TDCLAbstractMenu.RunFromScripts(IdentFrom, IdentTo: Integer);
begin
  LocalQuery.SQL.Text:=GetRolesQueryText(IdentifyField+' between '+IntToStr(IdentFrom)+' and '+IntToStr(IdentTo), GPT.UserID);
  LocalQuery.Open;
  while not LocalQuery.EOF do
  begin
    FMain.RunCommandScript(LocalQuery.FieldByName(DCLNameField).AsString);
    LocalQuery.Next;
  end;
  LocalQuery.Close;
end;

constructor TDCLAbstractMenu.Create(const Main: IDCLMain);
begin
  FMain:=Main;
  FDBConnector:=Main.GetDBConnector;
  iComp:=TComparerMenuItem.Create;

  LocalQuery:=TDCLSimplyQuery.Create(Self);
  FDBConnector.SetConnector(LocalQuery);

  InitActions;

  LocalQuery.SQL.Text:=GetOutRolesQueryText(IdentifyField+'=0');
  LocalQuery.Open;
  LocalQuery.First;
  FMenuTitle:=LocalQuery.FieldByName(DCLNameField).AsString;
  LocalQuery.Close;

  LocalQuery.SQL.Text:=GetRolesQueryText(IdentifyField+' between 20051 and 20100', GPT.UserID);
  LocalQuery.Open;
  while not LocalQuery.EOF do
  begin
    FMenuTitle:=FMenuTitle+TrimRight(LocalQuery.FieldByName(DCLNameField).AsString);
    LocalQuery.Next;
  end;
  LocalQuery.Close;
end;

destructor TDCLAbstractMenu.Destroy;
begin
  CloseActions;
  inherited Destroy;
end;

end.

