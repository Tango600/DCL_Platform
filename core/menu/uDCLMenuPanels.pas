unit uDCLMenuPanels;
{$mode Delphi}

interface

uses
  Classes, SysUtils, Forms, Menus, ComCtrls, Controls, ExtCtrls, Buttons,
  LCLClasses, Generics.Collections, //System.UItypes,
  uIDCLMain, uDCLAbstractMenu, uDCLBaseMenu, uDCLDBAwareTypes;

type
  { TDCLMenuPanels }

  TDCLMenuPanels=class(TDCLBaseMenu)
  private

  protected
    procedure CreateMenuControls(var Query: TDCLSimplyQuery; Items: TList<TMenuConstructionItem>; ParentControl: TLCLComponent); override;
  public
    constructor Create(const Main: IDCLMain; MainForm: TForm); overload;
    destructor Destroy; override;
  end;

implementation

uses
  uDCLGlobalVariables, uDCLMeasurements;

{ TDCLMenuPanels }

procedure TDCLMenuPanels.CreateMenuControls(var Query: TDCLSimplyQuery;
  Items: TList<TMenuConstructionItem>; ParentControl: TLCLComponent);
var
  FTablePartsTabs: TTabSheet;
  FButtonFlowPanel: TFlowPanel;
  FMenuButton: TSpeedButton;
  FMenuPartsPages: TPageControl;
  FBevel: TBevel;
  ci: TMenuConstructionItem;
  it: Byte;
begin
  FMenuPartsPages:=nil;
  FButtonFlowPanel:=nil;
  FTablePartsTabs:=nil;
  for ci in Items do
  begin
    if (ci.Command='') and (ci.Title<>'-') then
    begin
      if not Assigned(FMenuPartsPages) then
      begin
        FMenuPartsPages:=TPageControl.Create(ParentControl as TWinControl);
        FMenuPartsPages.Parent:=ParentControl as TWinControl;
        FMenuPartsPages.AutoSize:=True;
        if ParentControl is TForm then
          FMenuPartsPages.Align:=alClient
        else
          FMenuPartsPages.Align:=alTop;
      end;

      FTablePartsTabs:=TTabSheet.Create(FMenuPartsPages);
      FTablePartsTabs.Parent:=FMenuPartsPages;
      FTablePartsTabs.PageControl:=FMenuPartsPages;
      FTablePartsTabs.Caption:=ci.Title;

      CreateMenu(Query, FTablePartsTabs, ci.Id);
    end
    else
    begin
      if Assigned(FMenuPartsPages) then
      begin
        FMenuPartsPages.Align:=alTop;
        FMenuPartsPages.Height:=200;
      end;

      if not Assigned(FButtonFlowPanel) then
      begin
        FButtonFlowPanel:=TFlowPanel.Create(ParentControl as TWinControl);
        FButtonFlowPanel.Parent:=ParentControl as TWinControl;
        FButtonFlowPanel.Name:='MenuFlow';
        FButtonFlowPanel.Caption:='';
        FButtonFlowPanel.Color:=$F0FBFF;
        FButtonFlowPanel.Align:=alClient;
        FButtonFlowPanel.FlowStyle:=fsTopBottomLeftRight;
        FButtonFlowPanel.BevelInner:=bvLowered;
      end;

      if ci.Title<>'-' then
      begin
        FMenuButton:=TSpeedButton.Create(FButtonFlowPanel);
        FMenuButton.Parent:=FButtonFlowPanel;
        FMenuButton.Caption:=ci.Title;
        FMenuButton.Flat:=True;
        FMenuButton.Width:=PanelMenuButtonWidth;
        FMenuButton.Tag:=ci.Id;
        //FMenuButton.AutoSize:=True;
        FMenuButton.OnClick:=ClickMenu;
        it:=0;
      end
      else
      begin
        if it=0 then
        begin
          FBevel:=TBevel.Create(FButtonFlowPanel);
          FBevel.Parent:=FButtonFlowPanel;
          FBevel.Shape:=bsBottomLine;
          FBevel.BorderSpacing.Left:=10;
          FBevel.BorderSpacing.Right:=10;
          FBevel.Width:=PanelMenuButtonWidth-20;
          FBevel.Height:=10;
        end;
        it:=1;
      end;
    end;
  end;
end;

constructor TDCLMenuPanels.Create(const Main: IDCLMain; MainForm: TForm);
begin
  inherited Create(Main, MainForm);
  CreateAboutItem;
  CreateMenu(LocalQuery, MainForm, 0);
end;

destructor TDCLMenuPanels.Destroy;
begin
  inherited Destroy;
end;

end.

