unit uDCLBaseMenu;
{$mode Delphi}

interface

uses
  Classes, SysUtils, Menus, Forms, ComCtrls, Controls, ExtCtrls, Buttons,
  uDCLAbstractMenu, LCLClasses, Generics.Collections, Generics.Defaults,
  uDCLConst, uDCLMeasurements, uIDCLMain,
  uDCLDBAwareTypes, uDCLDBStructure;

type
  { TDCLBaseMenu }

  TDCLBaseMenu=class(TDCLAbstractMenu)
  private
    FMainForm: TForm;
    FormBar: TToolBar;
    FImages: TImageList;
  protected
    FMainMenu: TMainMenu;
    procedure CreateMenuControls(var Query: TDCLSimplyQuery; Items: TList<TMenuConstructionItem>; ParentControl: TLCLComponent); virtual; abstract;
    procedure ClickMenu(Sender: TObject);

    procedure CreateMenu(var Query: TDCLSimplyQuery; ParentControl: TLCLComponent; ParentID: Integer);
  public
    constructor Create(const Main: IDCLMain; MainForm: TForm); overload;
    destructor Destroy; override;

    procedure CreateAboutItem;
  end;

implementation

uses
  uDCLGlobalVariables, uDCLQueryUtils, uDCLImages, uDCLScriptsPackage, uDBUtils;

{ TDCLMenu }

procedure TDCLBaseMenu.ClickMenu(Sender: TObject);
var
  IdentID: Integer;
begin
  IdentID:=(Sender as TComponent).Tag;
  RunMenu(IdentID);
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

  if TableExists(FMain.GetDBConnector, DCLTable) then
  begin
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
  end;

  ConstructionItems.Sort(iComp);

  CreateMenuControls(Query, ConstructionItems, ParentControl);
  iComp:=nil;
end;

constructor TDCLBaseMenu.Create(const Main: IDCLMain; MainForm: TForm);
var
  S: String;
begin
  inherited Create(Main);
  FMainForm:=MainForm;

  If ShowFormPanel and Not Assigned(FormBar) Then
  begin
    FormBar:=TToolBar.Create(FMainForm);
    FormBar.Parent:=FMainForm;
    FormBar.AutoSize:=True;
    FormBar.Name:=ToolPanelName;
    FormBar.ShowCaptions:=True;

    FImages:=TImageList.Create(FormBar);
    FImages.Add(DrawBMPButton(ptFormDotNew), nil);
    FImages.Add(DrawBMPButton(ptFormDotActive), nil);
    FImages.Add(DrawBMPButton(ptFormDotInActive), nil);

    FormBar.ButtonWidth:=FormPanelButtonWidth;
    FormBar.Images:=FImages;
    FormBar.Show;
  end;

  FMainMenu:=TMainMenu.Create(MainForm);

  S:=MenuTitle;
  if GPT.MainFormCaption<>'' then
    S:=S+' \'+Trim(GPT.MainFormCaption)+'\';

  FMainForm.Caption:=S;
end;

destructor TDCLBaseMenu.Destroy;
begin
  inherited Destroy;
end;

procedure TDCLBaseMenu.CreateAboutItem;
var
  ItemMenu: TMenuItem;
begin
  ItemMenu:=TMenuItem.Create(FMainMenu);
  ItemMenu.Tag:=-999;
  ItemMenu.Caption:='О...';
  ItemMenu.OnClick:=About;  // ClickMenu;
  FMainMenu.Items.Add(ItemMenu);
end;

end.

