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
    constructor Create(const Main: IDCLMain; MainForm: TForm); overload;
    destructor Destroy; override;
  end;

implementation

uses
  uDCLGlobalVariables;

{ TDCLMenu }

constructor TDCLMenuSelector.Create(const Main: IDCLMain; MainForm: TForm);
begin
  case GPT.MenuType of
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

