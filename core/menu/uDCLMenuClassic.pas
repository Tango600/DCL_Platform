unit uDCLMenuClassic;
{$I DefineType.pas}

interface

uses
  Classes, SysUtils, Forms, Menus, ComCtrls, Controls, LCLClasses,
  Generics.Collections,
  uDCLConst, uIDCLMain, uDCLAbstractMenu, uDCLDBAwareTypes, uDCLBaseMenu;

type
  { TDCLMenuClassic }

  TDCLMenuClassic = class(TDCLBaseMenu)
  private
    procedure CreateMenuControl(var Query: TDCLSimplyQuery; Item: TMenuConstructionItem; ParentControl: TLCLComponent);
  protected
    procedure CreateMenuControls(var Query: TDCLSimplyQuery; Items: TList<TMenuConstructionItem>; ParentControl: TLCLComponent); override;
  public
    constructor Create(const Main: IDCLMain; MainForm: TForm); overload;
    destructor Destroy; override;
  end;

implementation

uses
  uDCLGlobalVariables;

{ TDCLMenuClassic }

procedure TDCLMenuClassic.CreateMenuControl(var Query: TDCLSimplyQuery;
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

procedure TDCLMenuClassic.CreateMenuControls(var Query: TDCLSimplyQuery;
  Items: TList<TMenuConstructionItem>; ParentControl: TLCLComponent);
var
  ci: TMenuConstructionItem;
begin
  for ci in Items do
  begin
    CreateMenuControl(Query, ci, ParentControl);
  end;
end;

constructor TDCLMenuClassic.Create(const Main: IDCLMain; MainForm: TForm);
begin
  inherited Create(Main, MainForm);

  {$IFnDEF ALLOWNODCL}
  if TestDCLTable then
  {$ENDIF}
    CreateMenu(LocalQuery, FMainMenu, 0);

  CreateAboutItem;
end;

destructor TDCLMenuClassic.Destroy;
begin
  inherited Destroy;
end;

end.

