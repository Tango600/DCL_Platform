unit uDCLMenu;
{$mode Delphi}

interface

uses
  Classes, SysUtils, Forms, Menus, ComCtrls, Controls, fgl, ExtCtrls, Buttons,
  uDCLConst, uDCLDBConnector, uDBUtils, uDCLMeasurements, uIDCLMain,
  uDCLDBAwareTypes, uDCLDBStructure;

type
  TMenuConstructionItem=class
    Id, Parent: Integer;
    Command, Title: String;
  end;

  { TDCLMenu }

  TDCLMenu=class(TComponent)
  private
    FMain: IDCLMain;
    FMainMenu: TMainMenu;
    FMainForm: TForm;
    FDBConnector: TDCLDBConnector;
    LocalQuery: TDCLSimlyQuery;
    FormBar: TToolBar;
    FImages: TImageList;

    procedure InitActions;
    procedure CloseActions;

    function GetMenuCommandById(Ident: Integer): String;

    procedure ClickMenu(Sender: TObject);
    function ExistItemByIdent(var List: TFPGObjectList<TMenuConstructionItem>; Id: Integer): Boolean;

    procedure CreateMenu(var Query: TDCLSimlyQuery; ParentControl: TWinControl; ParentID: Integer);
    procedure CreateMenuControls(var Query: TDCLSimlyQuery; Items: TFPGObjectList<TMenuConstructionItem>; ParentControl: TWinControl);

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

procedure TDCLMenu.About;
begin
  FMain.About;
end;

procedure TDCLMenu.InitActions;
begin
  RunFromPackage(40001, 40100);
  RunFromScripts(40001, 40100);
end;

procedure TDCLMenu.CloseActions;
begin
  RunFromPackage(40101, 40200);
  RunFromScripts(40101, 40200);
end;

function TDCLMenu.GetMenuCommandById(Ident: Integer): String;
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

procedure TDCLMenu.ClickMenu(Sender: TObject);
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

function TDCLMenu.ExistItemByIdent(var List: TFPGObjectList<TMenuConstructionItem>; Id: Integer): Boolean;
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

function CompareTopItems(const Item1, Item2: TMenuConstructionItem): Integer;
begin
  if Item1.Id<Item2.Id then
    Result:=-1
  else if Item1.Id>Item2.Id then
    Result:=1
  else if Item1.Id=Item2.Id then
    Result:=0;
end;

procedure TDCLMenu.CreateMenu(var Query: TDCLSimlyQuery; ParentControl: TWinControl; ParentID: Integer);
var
  I: TDCLScriptItem;
  ci: TMenuConstructionItem;
  ConstructionItems: TFPGObjectList<TMenuConstructionItem>;
  ParentWhere: String;
begin
  ConstructionItems:=TFPGObjectList<TMenuConstructionItem>.Create;
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

  ConstructionItems.Sort(CompareTopItems);

  CreateMenuControls(Query, ConstructionItems, ParentControl);
end;

procedure TDCLMenu.CreateMenuControls(var Query: TDCLSimlyQuery; Items:
  TFPGObjectList<TMenuConstructionItem>; ParentControl: TWinControl);
var
  FTablePartsTabs: TTabSheet;
  FButtonFlowPanel: TFlowPanel;
  FMenuButton: TSpeedButton;
  FMenuPartsPages: TPageControl;
  ci: TMenuConstructionItem;
begin
  FMenuPartsPages:=nil;
  FButtonFlowPanel:=nil;
  for ci in Items do
  begin
    if ci.Title<>'-' then
    begin
      if ci.Command='' then
      begin
        if Assigned(FButtonFlowPanel) then
        begin
          FButtonFlowPanel.Align:=alBottom;
          FButtonFlowPanel.Height:=250;
        end;

        if not Assigned(FMenuPartsPages) then
        begin
          FMenuPartsPages:=TPageControl.Create(ParentControl);
          FMenuPartsPages.Parent:=ParentControl;
          FMenuPartsPages.Align:=alClient;
        end;

        FTablePartsTabs:=TTabSheet.Create(FMenuPartsPages);
        FTablePartsTabs.Parent:=FMenuPartsPages;
        FTablePartsTabs.PageControl:=FMenuPartsPages;
        FTablePartsTabs.Caption:=ci.Title;

        CreateMenu(Query, FTablePartsTabs, ci.Id);
      end
      else
      begin
        if not Assigned(FButtonFlowPanel) then
        begin
          FButtonFlowPanel:=TFlowPanel.Create(ParentControl);
          FButtonFlowPanel.Parent:=ParentControl;
          FButtonFlowPanel.Name:='MenuFlow';
          FButtonFlowPanel.Caption:='';
          FButtonFlowPanel.Align:=alClient;
          FButtonFlowPanel.FlowStyle:=fsTopBottomLeftRight;
        end;

        if Assigned(FMenuPartsPages) then
        begin
          FMenuPartsPages.Align:=alTop;
          FMenuPartsPages.Height:=200;
        end;

        FMenuButton:=TSpeedButton.Create(FButtonFlowPanel);
        FMenuButton.Parent:=FButtonFlowPanel;
        FMenuButton.Caption:=ci.Title;
        FMenuButton.Flat:=True;
        FMenuButton.Width:=200;
        FMenuButton.Tag:=ci.Id;
        //FMenuButton.AutoSize:=True;
        FMenuButton.OnClick:=ClickMenu;
      end;
    end;
  end;
end;

procedure TDCLMenu.RunFromPackage(IdentFrom, IdentTo: Integer);
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

procedure TDCLMenu.RunFromScripts(IdentFrom, IdentTo: Integer);
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

constructor TDCLMenu.Create(Main: IDCLMain; MainForm: TForm);
var
  S: String;
begin
  FMain:=Main;
  FMainForm:=MainForm;
  FDBConnector:=Main.GetDBConnector;

  LocalQuery:=TDCLSimlyQuery.Create(Self);
  FDBConnector.SetConnector(LocalQuery);

  FMainMenu:=TMainMenu.Create(FMainForm);
  CreateAboutItem;
  if not TableExist(FDBConnector, DCLTable) then
  begin
    Exit;
  end;

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

  LocalQuery.SQL.Text:=GetOutRolesQueryText(IdentifyField+'=0');
  LocalQuery.Open;
  LocalQuery.First;
  S:=LocalQuery.FieldByName(DCLNameField).AsString;
  FMainForm.Caption:=S;
  LocalQuery.Close;

  CreateMenu(LocalQuery, FMainForm, 0);

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

destructor TDCLMenu.Destroy;
begin
  CloseActions;
  inherited Destroy;
  FMain:=nil;
end;

procedure TDCLMenu.CreateAboutItem;
begin
  {findItemFlg:=nil;
  FindMenuItem(-999, FMainMenu.Items);

  if not Assigned(findItemFlg) then
  begin
    AddMainItem(-999, 'О ...');
  end;}
end;

end.

