unit uDCLMenu;
{$mode Delphi}

interface

uses
  Classes, SysUtils, Forms, Menus, ComCtrls,
  uDCLConst, uDCLData, uDCLDBConnector, uDBUtils,
  uDCLMeasurements, uDCLTypes, uDCLDBStructure;

type

  { TDCLMenu }

  TDCLMenu=class(TComponent)
  private
    FMainMenu: TMainMenu;
    FMainForm: TForm;
    FDBConnector: TDBConnector;
    LocalQuery: TDCLDialogQuery;
    FormBar: TToolBar;
    FUserID, FRoleID: Integer;
    findItemFlg: TMenuItem;
    FOpenDialogMethod: TOpenDialogMethod;


    function GetMenuCommandById(Ident: Integer): String;

    procedure FindMenuItem(TagID: Integer; aItems: TMenuItem);
    procedure ClickMenu(Sender: TObject);

    function GetRolesQueryText(Where: String): String;
    procedure AddMainItem(Id: Integer; Capt: String);
    procedure AddSubItem(Id, ParentItemId: Integer; Capt: String);
  public
    constructor Create(MainForm: TForm; DBConnector: TDCLDBConnector); overload;

    procedure About;
    procedure CreateAboutItem;

    property OpenDialogMethod: TOpenDialogMethod read FOpenDialogMethod write FOpenDialogMethod;
  end;

implementation

{ TDCLMenu }

procedure TDCLMenu.About;
begin

end;

function TDCLMenu.GetMenuCommandById(Ident: Integer): String;
begin
  LocalQuery.SQL.Text:=GetRolesQueryText(IdentifyField+'='+IntToStr(Ident));
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
    FOpenDialogMethod('', DialogName);
  end
  else
  begin
    if IdentID=-999 then
      About;
  end;
end;

function TDCLMenu.GetRolesQueryText(Where: String): String;
begin
  Result:='select * from '+DCLTable+' where '+Where+' order by '+IdentifyField;
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

constructor TDCLMenu.Create(MainForm: TForm; DBConnector: TDCLDBConnector);
begin
  FMainForm:=MainForm;
  FDBConnector:=DBConnector;

  LocalQuery:=TDCLDialogQuery.Create(Self);
  DBConnector.SetConnector(LocalQuery);

  FMainMenu:=TMainMenu.Create(FMainForm);
  {$IFDEF DELPHI}
  FMainMenu.AutoHotkeys:=maManual;
  {$ENDIF}
  if not TableExist(FDBConnector, DCLTable) then
  begin
    CreateAboutItem;
    Exit;
  end;

  If ShowFormPanel and Not Assigned(FormBar) Then
  begin
    FormBar:=TToolBar.Create(FMainForm);
    FormBar.Parent:=FMainForm;
    FormBar.Name:='FormBar';
    FormBar.ShowCaptions:=True;
    FormBar.Height:=FormPanelHeight;
    FormBar.ButtonHeight:=FormPanelButtonHeight;
    FormBar.ButtonWidth:=FormPanelButtonWidth;
    FormBar.Show;
  end;

  LocalQuery.SQL.Text:=GetRolesQueryText(IdentifyField+'=0');
  LocalQuery.Open;
  LocalQuery.First;
  FMainForm.Caption:=LocalQuery.FieldByName(DCLNameField).AsString;
  LocalQuery.Close;

  LocalQuery.SQL.Text:=GetRolesQueryText(IdentifyField+' between 1 and 1000');
  LocalQuery.Open;
  while not LocalQuery.EOF do
  begin
    AddMainItem(LocalQuery.FieldByName(IdentifyField).AsInteger, LocalQuery.FieldByName(DCLNameField).AsString);

    LocalQuery.Next;
  end;
  LocalQuery.Close;

  LocalQuery.SQL.Text:=GetRolesQueryText(IdentifyField+' between 1001 and 10000');
  LocalQuery.Open;
  while not LocalQuery.EOF do
  begin
    AddSubItem(LocalQuery.FieldByName(IdentifyField).AsInteger, LocalQuery.FieldByName(ParentField).AsInteger, LocalQuery.FieldByName(DCLNameField).AsString);

    LocalQuery.Next;
  end;
  LocalQuery.Close;

  LocalQuery.SQL.Text:=GetRolesQueryText(IdentifyField+' between 10001 and 16000');
  LocalQuery.Open;
  while not LocalQuery.EOF do
  begin
    AddSubItem(LocalQuery.FieldByName(IdentifyField).AsInteger, LocalQuery.FieldByName(ParentField).AsInteger, LocalQuery.FieldByName(DCLNameField).AsString);

    LocalQuery.Next;
  end;
  LocalQuery.Close;

  LocalQuery.SQL.Text:=GetRolesQueryText(IdentifyField+' between 16001 and 19000');
  LocalQuery.Open;
  while not LocalQuery.EOF do
  begin
    AddSubItem(LocalQuery.FieldByName(IdentifyField).AsInteger, LocalQuery.FieldByName(ParentField).AsInteger, LocalQuery.FieldByName(DCLNameField).AsString);

    LocalQuery.Next;
  end;
  LocalQuery.Close;
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

