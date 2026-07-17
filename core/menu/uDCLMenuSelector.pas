unit uDCLMenuSelector;
{$mode Delphi}

interface

uses
  Classes, SysUtils, Forms,
  uDCLConst, uIDCLMain, uDCLBaseMenu, uDCLMenuClassic, uDCLMenuPanels;

type
  { TDCLMenuSelector }

  TDCLMenuSelector=class(TComponent)
  private
    FDCLMenu: TDCLBaseMenu;
  public
    constructor Create(const Main: IDCLMain; const MainForm: TForm; const MenuType: TMenuType); overload;
    destructor Destroy; override;
  end;

implementation

{ TDCLMenu }

constructor TDCLMenuSelector.Create(const Main: IDCLMain; const MainForm: TForm; const MenuType: TMenuType);
begin
  case MenuType of
  mtClassic: FDCLMenu:=TDCLMenuClassic.Create(Main, MainForm);
  mtPanels: FDCLMenu:=TDCLMenuPanels.Create(Main, MainForm);
  end;
end;

destructor TDCLMenuSelector.Destroy;
begin
  if Assigned(FDCLMenu) then
    FreeAndNil(FDCLMenu);
  inherited Destroy;
end;

end.

