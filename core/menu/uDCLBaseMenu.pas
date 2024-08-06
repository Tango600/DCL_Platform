unit uDCLBaseMenu;
{$mode Delphi}

interface

uses
  Classes, SysUtils, Forms, Menus, ComCtrls, Controls, ExtCtrls, Buttons,
  LCLClasses, Generics.Collections, Generics.Defaults,
  uDCLConst, uDCLDBConnector, uDCLMeasurements, uIDCLMain,
  uDCLDBAwareTypes, uDCLDBStructure;

type
  TMenuConstructionItem=class
    Id, Parent: Integer;
    Command, Title: String;
  end;

  TComparerMenuItem = class(TInterfacedObject, IComparer<TMenuConstructionItem>)
    function Compare(const Left, Right: TMenuConstructionItem): Integer; overload;
  end;

  { TDCLBaseMenu }

  TDCLBaseMenu=class(TComponent)
  private
    FMain: IDCLMain;
    FMainForm: TForm;
    FDBConnector: TDCLDBConnector;
    FormBar: TToolBar;
    FImages: TImageList;
  protected
    FMainMenu: TMainMenu;
    LocalQuery: TDCLSimplyQuery;
    procedure CreateMenuControls(var Query: TDCLSimplyQuery; Items: TList<TMenuConstructionItem>; ParentControl: TLCLComponent); virtual; abstract;
  published
    procedure InitActions;
    procedure CloseActions;

    function GetMenuCommandById(Ident: Integer): String;

    procedure ClickMenu(Sender: TObject);
    function ExistItemByIdent(var List: TList<TMenuConstructionItem>; Id: Integer): Boolean;

    procedure CreateMenu(var Query: TDCLSimplyQuery; ParentControl: TLCLComponent; ParentID: Integer);

    procedure RunFromPackage(IdentFrom, IdentTo: Integer);
    procedure RunFromScripts(IdentFrom, IdentTo: Integer);
  public
    constructor Create(Main: IDCLMain; MainForm: TForm); overload;
    destructor Destroy; override;

    procedure About;
    procedure CreateAboutItem;
  end;

implementation

uses
  uDCLGlobalVariables, uDCLQueryUtils, uDCLImages, uDCLScriptsPackage;

{ TDCLMenu }

procedure TDCLBaseMenu.About;
begin
  FMain.About;
end;

procedure TDCLBaseMenu.InitActions;
begin
  RunFromPackage(40001, 40100);
  RunFromScripts(40001, 40100);
end;

procedure TDCLBaseMenu.CloseActions;
begin
  RunFromPackage(40101, 40200);
  RunFromScripts(40101, 40200);
end;

function TDCLBaseMenu.GetMenuCommandById(Ident: Integer): String;
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

procedure TDCLBaseMenu.ClickMenu(Sender: TObject);
var
  IdentID, p: Integer;
  DialogName: String;
  Host: Boolean;
  Scr: TStringList;
begin
  IdentID:=(Sender as TComponent).Tag;
  if IdentID>0 then
  begin
    Host:=False;
    DialogName:=GetMenuCommandById(IdentID);
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
    if IdentID=-999 then
      About;
  end;
end;

function TDCLBaseMenu.ExistItemByIdent(var List: TList<TMenuConstructionItem>; Id: Integer): Boolean;
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

procedure TDCLBaseMenu.CreateMenu(var Query: TDCLSimplyQuery; ParentControl: TLCLComponent; ParentID: Integer);
var
  I: TDCLScriptItem;
  ci: TMenuConstructionItem;
  ConstructionItems: TList<TMenuConstructionItem>;
  ParentWhere: String;
  iComp: IComparer<TMenuConstructionItem>;
begin
  iComp:=TComparerMenuItem.Create;
  ConstructionItems:=TList<TMenuConstructionItem>.Create(iComp);
  for I in FMain.GetLoadedScripts do
  begin
    if (I.Ident>=1) and (I.Ident<=20000) then
    if ((ParentID=0) and (I.Parent=0)) or (I.Parent=ParentID) then
    begin
      ci:=TMenuConstructionItem.Create;
      ci.Id:=I.Ident;
      ci.Title:=I.ScriptName;
      ci.Command:=I.Command;
      ConstructionItems.Add(ci);
    end;
  end;

  if ParentID=0 then
    ParentWhere:=' is null'
  else
    ParentWhere:=' = '+IntToStr(ParentID);

  Query.SQL.Text:=GetRolesQueryText(IdentifyField+' between 1 and 20000 and '+ParentField+ParentWhere, GPT.UserID);

  Query.Open;
  while not Query.EOF do
  begin
    if not ExistItemByIdent(ConstructionItems, Query.FieldByName(IdentifyField).AsInteger) then
    begin
      ci:=TMenuConstructionItem.Create;
      ci.Id:=Query.FieldByName(IdentifyField).AsInteger;
      ci.Parent:=Query.FieldByName(ParentField).AsInteger;
      ci.Title:=Query.FieldByName(DCLNameField).AsString;
      ci.Command:=Query.FieldByName(CommandField).AsString;
      ConstructionItems.Add(ci);
    end;

    Query.Next;
  end;
  Query.Close;

  ConstructionItems.Sort(iComp);

  CreateMenuControls(Query, ConstructionItems, ParentControl);
end;

procedure TDCLBaseMenu.RunFromPackage(IdentFrom, IdentTo: Integer);
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

procedure TDCLBaseMenu.RunFromScripts(IdentFrom, IdentTo: Integer);
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

constructor TDCLBaseMenu.Create(Main: IDCLMain; MainForm: TForm);
var
  S: String;
begin
  FMain:=Main;
  FMainForm:=MainForm;
  FDBConnector:=Main.GetDBConnector;

  LocalQuery:=TDCLSimplyQuery.Create(Self);
  FDBConnector.SetConnector(LocalQuery);

  FImages:=TImageList.Create(Self);
  FImages.Add(DrawBMPButton(ptFormDotNew), nil);
  FImages.Add(DrawBMPButton(ptFormDotActive), nil);
  FImages.Add(DrawBMPButton(ptFormDotInActive), nil);

  If ShowFormPanel and Not Assigned(FormBar) Then
  begin
    FormBar:=TToolBar.Create(FMainForm);
    FormBar.Parent:=FMainForm;
    FormBar.AutoSize:=True;
    FormBar.Name:=ToolPanelName;
    FormBar.ShowCaptions:=True;
    FormBar.Height:=FormPanelHeight;
    FormBar.ButtonWidth:=FormPanelButtonWidth;
    FormBar.Images:=FImages;
    FormBar.Show;
  end;

  InitActions;
  FMainMenu:=TMainMenu.Create(MainForm);

  LocalQuery.SQL.Text:=GetOutRolesQueryText(IdentifyField+'=0');
  LocalQuery.Open;
  LocalQuery.First;
  S:=LocalQuery.FieldByName(DCLNameField).AsString;
  FMainForm.Caption:=S;
  LocalQuery.Close;

  S:=FMainForm.Caption;
  LocalQuery.SQL.Text:=GetRolesQueryText(IdentifyField+' between 20051 and 20100', GPT.UserID);
  LocalQuery.Open;
  while not LocalQuery.EOF do
  begin
    S:=S+TrimRight(LocalQuery.FieldByName(DCLNameField).AsString);
    LocalQuery.Next;
  end;
  LocalQuery.Close;

  FMainForm.Caption:=S;

  if GPT.MainFormCaption<>'' then
    S:=S+' \'+Trim(GPT.MainFormCaption)+'\';

  FMainForm.Caption:=S;
end;

destructor TDCLBaseMenu.Destroy;
begin
  CloseActions;
  inherited Destroy;
end;

procedure TDCLBaseMenu.CreateAboutItem;
var
  ItemMenu: TMenuItem;
begin
  ItemMenu:=TMenuItem.Create(FMainMenu);
  ItemMenu.Tag:=-999;
  ItemMenu.Caption:='О...';
  ItemMenu.OnClick:=ClickMenu;
  FMainMenu.Items.Add(ItemMenu);
end;

end.

