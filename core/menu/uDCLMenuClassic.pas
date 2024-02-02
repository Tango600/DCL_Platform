unit uDCLMenuClassic;
{$mode Delphi}

interface

uses
  Classes, SysUtils, Forms, Menus, ComCtrls, Controls, fgl, LCLClasses,
  uDCLConst, uIDCLMain, uDCLDBAwareTypes, uDCLBaseMenu, uDBUtils;

type
  { TDCLMenuClassic }

  TDCLMenuClassic=class(TDCLBaseMenu)
  private
    procedure CreateMenuControl(var Query: TDCLSimlyQuery; Item: TMenuConstructionItem; ParentControl: TLCLComponent);
  protected
    procedure CreateMenuControls(var Query: TDCLSimlyQuery; Items: TFPGObjectList<TMenuConstructionItem>; ParentControl: TLCLComponent); override;
  public
    constructor Create(Main: IDCLMain; MainForm: TForm); overload;
    destructor Destroy; override;
  end;

implementation

uses
  uDCLGlobalVariables, uDCLDBStructure;

{ TDCLMenuClassic }

procedure TDCLMenuClassic.CreateMenuControl(var Query: TDCLSimlyQuery;
  Item: TMenuConstructionItem; ParentControl: TLCLComponent);
var
  ItemMenu: TMenuItem;
begin
  ItemMenu:=TMenuItem.Create(ParentControl);
  ItemMenu.Caption:=Item.Title;
  if ParentControl is TMainMenu then
    (ParentControl as TMainMenu).Items.Add(ItemMenu)
  else
    (ParentControl as TMenuItem).Add(ItemMenu);

  if Item.Command='' then
  begin
    CreateMenu(Query, ItemMenu, Item.Id);
  end
  else
  begin
    ItemMenu.Tag:=Item.Id;
    ItemMenu.OnClick:=ClickMenu;
  end;
end;

procedure TDCLMenuClassic.CreateMenuControls(var Query: TDCLSimlyQuery;
  Items: TFPGObjectList<TMenuConstructionItem>; ParentControl: TLCLComponent);
var
  ci: TMenuConstructionItem;
begin
  for ci in Items do
  begin
    CreateMenuControl(Query, ci, ParentControl);
  end;
end;

constructor TDCLMenuClassic.Create(Main: IDCLMain; MainForm: TForm);
begin
  inherited Create(Main, MainForm);

  if TableExists(Main.GetDBConnector, DCLTable) then
    CreateMenu(LocalQuery, FMainMenu, 0);

  CreateAboutItem;
end;

destructor TDCLMenuClassic.Destroy;
begin
  inherited Destroy;
end;

end.

