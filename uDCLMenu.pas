unit uDCLMenu;
{$I DefineType.pas}

interface

uses
  Classes, SysUtils, Forms, Menus, ComCtrls, Controls,
  uDCLConst, uDCLDBConnector, uDBUtils, uDCLMeasurements, uDCLTypes,
  uDCLDBStructure, uIDCLMain;

type

  { TDCLMenu }

  TDCLMenu=class(TComponent)
  private
    FMain: IDCLMain;
    FMainMenu: TMainMenu;
    FMainForm: TForm;
    FDBConnector: TDCLDBConnector;
    LocalQuery: TDCLSimlyQuery;
    FormBar: TToolBar;
    findItemFlg: TMenuItem;
    FImages: TImageList;

    procedure InitActions;
    procedure CloseActions;

    function GetMenuCommandById(Ident: Integer): String;

    procedure FindMenuItem(TagID: Integer; aItems: TMenuItem);
    procedure ClickMenu(Sender: TObject);

    procedure AddMainItem(Id: Integer; Capt: String);
    procedure AddSubItem(Id, ParentItemId: Integer; Capt: String);

    procedure CreateMenuItems(var Query: TDCLSimlyQuery; ValueFrom, ValueTo: Integer; UserID: String);
    procedure CreateSumMenuItems(var Query: TDCLSimlyQuery; ValueFrom, ValueTo: Integer; UserID: String);
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
  LocalQuery.SQL.Text:=GetRolesQueryText(IdentifyField+' between 40001 and 40100', GPT.UserID);
  LocalQuery.Open;
  while not LocalQuery.EOF do
  begin
    FMain.RunCommand(LocalQuery.FieldByName(DCLNameField).AsString);

    LocalQuery.Next;
  end;
  LocalQuery.Close;
end;

procedure TDCLMenu.CloseActions;
begin
  LocalQuery.SQL.Text:=GetRolesQueryText(IdentifyField+' between 40101 and 40200', GPT.UserID);
  LocalQuery.Open;
  while not LocalQuery.EOF do
  begin
    FMain.RunCommand(LocalQuery.FieldByName(DCLNameField).AsString);

    LocalQuery.Next;
  end;
  LocalQuery.Close;
end;

function TDCLMenu.GetMenuCommandById(Ident: Integer): String;
var
  I: TDCLScriptItem;
begin
  for I in FMain.GetLoadedScripts do
  begin
    if (I.Ident>0) and (I.Ident=Ident) then
    begin
      if Assigned(I.ScriptText) then
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

procedure TDCLMenu.FindMenuItem(TagID: Integer; aItems: TMenuItem);
var
  I: TMenuItem;
begin
  for I in aItems do
  begin
    if I.Tag=TagID then
    begin
      findItemFlg:=I;
      Exit;
    end
    else
    begin
      FindMenuItem(TagID, I);
    end;
  end;
end;

procedure TDCLMenu.ClickMenu(Sender: TObject);
var
  IdentID: Integer;
  DialogName: String;
begin
  IdentID:=(Sender as TComponent).Tag;
  if IdentID>0 then
  begin
    DialogName:=GetMenuCommandById(IdentID);
    FMain.OpenDialog(DialogName);
  end
  else
  begin
    if IdentID=-999 then
      About;
  end;
end;

procedure TDCLMenu.AddMainItem(Id: Integer; Capt: String);
var
  ItemMenu: TMenuItem;
begin
  ItemMenu:=TMenuItem.Create(FMainMenu);
  ItemMenu.Tag:=Id;
  ItemMenu.Caption:=Capt;
  ItemMenu.OnClick:=ClickMenu;
  FMainMenu.Items.Add(ItemMenu);
end;

procedure TDCLMenu.AddSubItem(Id, ParentItemId: Integer; Capt: String);
var
  ItemMenu: TMenuItem;
begin
  findItemFlg:=nil;
  FindMenuItem(ParentItemId, FMainMenu.Items);

  if Assigned(findItemFlg) then
  begin
    ItemMenu:=TMenuItem.Create(findItemFlg);
    ItemMenu.Tag:=Id;
    ItemMenu.Caption:=Capt;
    ItemMenu.OnClick:=ClickMenu;
    findItemFlg.OnClick:=nil;
    findItemFlg.Insert(findItemFlg.Count, ItemMenu);
  end;
end;

procedure TDCLMenu.CreateMenuItems(var Query: TDCLSimlyQuery; ValueFrom, ValueTo: Integer; UserID: String);
var
  I: TDCLScriptItem;
begin
  for I in FMain.GetLoadedScripts do
  begin
    if (I.Ident>=ValueFrom) and (I.Ident<=ValueTo) then
    begin
      AddMainItem(I.Ident, I.ScriptName);
    end;
  end;

  Query.SQL.Text:=GetRolesQueryText(IdentifyField+' between '+IntToStr(ValueFrom)+' and '+IntToStr(ValueTo), UserID);
  Query.Open;
  while not Query.EOF do
  begin
    AddMainItem(Query.FieldByName(IdentifyField).AsInteger, Query.FieldByName(DCLNameField).AsString);

    Query.Next;
  end;
  Query.Close;
end;

procedure TDCLMenu.CreateSumMenuItems(var Query: TDCLSimlyQuery; ValueFrom,
  ValueTo: Integer; UserID: String);
var
  I: TDCLScriptItem;
begin
  for I in FMain.GetLoadedScripts do
  begin
    if (I.Ident>=ValueFrom) and (I.Ident<=ValueTo) then
    begin
      AddSubItem(I.Ident, I.Parent, I.ScriptName);
    end;
  end;

  Query.SQL.Text:=GetRolesQueryText(IdentifyField+' between '+IntToStr(ValueFrom)+' and '+IntToStr(ValueTo), UserID);
  Query.Open;
  while not Query.EOF do
  begin
    AddSubItem(Query.FieldByName(IdentifyField).AsInteger, Query.FieldByName(ParentField).AsInteger, Query.FieldByName(DCLNameField).AsString);

    Query.Next;
  end;
  Query.Close;
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
  if not TableExist(FDBConnector, DCLTable) then
  begin
    CreateAboutItem;
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
    FormBar.Name:=ToolPanelName;
    FormBar.ShowCaptions:=True;
    FormBar.Height:=FormPanelHeight;
    FormBar.ButtonWidth:=FormPanelButtonWidth;
    FormBar.Images:=FImages;
    FormBar.Show;
  end;

  InitActions;

  LocalQuery.SQL.Text:=GetRolesQueryText(IdentifyField+'=0', GPT.UserID);
  LocalQuery.Open;
  LocalQuery.First;
  S:=LocalQuery.FieldByName(DCLNameField).AsString;
  FMainForm.Caption:=S;
  LocalQuery.Close;

  CreateMenuItems(LocalQuery, 1, 1000, GPT.UserID);

  CreateSumMenuItems(LocalQuery, 1001, 10000, GPT.UserID);
  CreateSumMenuItems(LocalQuery, 10001, 16000, GPT.UserID);
  CreateSumMenuItems(LocalQuery, 16001, 19000, GPT.UserID);

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
  findItemFlg:=nil;
  FindMenuItem(-999, FMainMenu.Items);

  if not Assigned(findItemFlg) then
  begin
    AddMainItem(-999, 'О ...');
  end;
end;

end.

