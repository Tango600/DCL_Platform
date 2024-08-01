unit cMyDBLookupCombo;
{$mode delphi}

interface

uses
  Classes, DB, Controls, LCLType, StdCtrls, SysUtils, Variants,
  Generics.Collections;

type
  TDBLookupItem = class
    Key, Value: Variant;
  end;

  { TDBMyLookupCombo }

  TDBMyLookupCombo=class(TComboBox)
  private
    FDS: TDataSource;
    FKeyField, FListField: String;
    FShadowItems: TList<TDBLookupItem>;
    FValueObject: TDBLookupItem;
    FResetValue: Variant;
    FAddResetValue, FPartial, FInFilterMode: Boolean;

    procedure OnFocus(Sender: TObject);
    procedure KeyUp(Sender: TObject; var Key: Word; Shift: TShiftState); overload;
    procedure KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState); overload;
    procedure UpdateItems;
    procedure FilterItems(Exemple: String);
    procedure SetListData(Value: TDataSource);
    procedure SetKeyField(Value: String);
    procedure SetListField(Value: String);
    function GetKeyValue: Variant;
    procedure SetKeyValue(Value: Variant);
    function GetStyle: TComboBoxStyle;
    procedure SetStyle(Value: TComboBoxStyle); override;
    function GetAddResetValue: Boolean;
    procedure SetAddResetValue(Value: Boolean);
  protected
    procedure Select; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;

    property ListSource: TDataSource read FDS write SetListData;
    property KeyField: String read FKeyField write SetKeyField;
    property ListField: String read FListField write SetListField;
    property KeyValue: Variant read GetKeyValue write SetKeyValue;
    property Style: TComboBoxStyle read GetStyle write SetStyle default csDropDown;
    property FilterResetValue: Variant read FResetValue write FResetValue;
    property AddResetValue: Boolean read GetAddResetValue write SetAddResetValue;
    property Partial: Boolean read FPartial write FPartial;
  end;

implementation

uses
  LazUTF8;

{ TDBMyLookupCombo }

procedure TDBMyLookupCombo.OnFocus(Sender: TObject);
begin
  if not FInFilterMode and Assigned(FValueObject) and not VarIsEmpty(FResetValue) then
    if FValueObject.Key=FResetValue then
    begin
      Text:='';
    end;
end;

procedure TDBMyLookupCombo.KeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  i: TDBLookupItem;
begin
  if Self.Text<>'' then
    FilterItems(Self.Text);
  if (Self.Text='') and not VarIsEmpty(FResetValue) then
  begin
    for i in FShadowItems do
    begin
      if i.Key=FResetValue then
      begin
        FInFilterMode:=False;
        FValueObject:=i;
        Text:=i.Value;
        FilterItems('');
        if Assigned(OnSelect) then
          OnSelect(Self);

        Exit;
      end;
    end;
  end;
end;

procedure TDBMyLookupCombo.KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Self.Text='<>' then
    Self.Text:='';
end;

procedure TDBMyLookupCombo.UpdateItems;
var
  i: TDBLookupItem;
begin
  if Assigned(FDS) and Assigned(FDS.DataSet) and (FKeyField<>'') and (FListField<>'') then
  begin
    if not FDS.DataSet.Active then
      FDS.DataSet.Open;

    if Assigned(FDS.DataSet.FindField(FKeyField)) and Assigned(FDS.DataSet.FindField(FListField)) then
    begin
      FShadowItems.Clear;
      FDS.DataSet.First;
      while not FDS.DataSet.EOF do
      begin
        i:=TDBLookupItem.Create;
        i.Key:=FDS.DataSet.FieldByName(FKeyField).AsVariant;
        i.Value:=FDS.DataSet.FieldByName(FListField).AsVariant;
        FShadowItems.Add(i);

        FDS.DataSet.Next;
      end;
      FDS.DataSet.Close;
    end;
  end;
end;

procedure TDBMyLookupCombo.FilterItems(Exemple: String);
var
  i: TDBLookupItem;
  S: String;
  c: Integer;
begin
  c:=0;
  Items.Clear;
  for i in FShadowItems do
  begin
    s:=i.Value;
    if (Exemple='') or (not FPartial and UTF8LowerCase(s).StartsWith(UTF8LowerCase(Exemple))) or (FPartial and UTF8LowerCase(s).Contains(UTF8LowerCase(Exemple), True)) then
    begin
      if Exemple<>'' then
        FInFilterMode:=True;
      Self.AddItem(i.Value, i);
      Inc(c);
    end;
  end;

  if c=1 then
  begin
    Text:=(Items.Objects[0] as TDBLookupItem).Value;
    if Assigned(OnSelect) then
      OnSelect(Self);
  end;
end;

procedure TDBMyLookupCombo.SetListData(Value: TDataSource);
begin
  FDS:=Value;
  UpdateItems;
  FilterItems(Self.Text);
end;

procedure TDBMyLookupCombo.SetKeyField(Value: String);
begin
  FKeyField:=Value;
  UpdateItems;
  FilterItems(Self.Text);
end;

procedure TDBMyLookupCombo.SetListField(Value: String);
begin
  FListField:=Value;
  UpdateItems;
  FilterItems(Self.Text);
end;

function TDBMyLookupCombo.GetKeyValue: Variant;
begin
  if Self.ItemIndex<>-1 then
  begin
    FValueObject:=Self.Items.Objects[Self.ItemIndex] as TDBLookupItem;
  end;

  if Assigned(FValueObject) then
    Result:=FValueObject.Key;
end;

procedure TDBMyLookupCombo.SetKeyValue(Value: Variant);
var
  i, V: TDBLookupItem;
begin
  V:=nil;
  for i in FShadowItems do
  begin
    if i.Key=Value then
    begin
      V:=i;
      break;
    end;
  end;

  if Assigned(V) then
  begin
    FValueObject:=V;
    Text:=V.Value;
    if Assigned(OnSelect) then
      OnSelect(Self);
  end;
end;

function TDBMyLookupCombo.GetStyle: TComboBoxStyle;
begin
  Result:=csDropDown;
end;

procedure TDBMyLookupCombo.SetStyle(Value: TComboBoxStyle);
begin
  //stub
end;

function TDBMyLookupCombo.GetAddResetValue: Boolean;
var
  i: TDBLookupItem;
begin
  if VarIsEmpty(FResetValue) then
  begin
    Result:=FAddResetValue;
  end
  else
  begin
    Result:=False;
    for i in FShadowItems do
    begin
      if i.Key=FResetValue then
      begin
        Result:=True;
        Exit;
      end;
    end;
  end;
end;

procedure TDBMyLookupCombo.SetAddResetValue(Value: Boolean);
var
  i: TDBLookupItem;
begin
  for i in FShadowItems do
  begin
    if i.Key=FResetValue then
    begin
      if not Value then
        FShadowItems.Remove(i);
      Exit;
    end;
  end;

  FAddResetValue:=Value;
  if Value then
  begin
    i:=TDBLookupItem.Create;
    i.Key:=FResetValue;
    i.Value:='<>';
    FShadowItems.Insert(0, i);
    FilterItems('');
    FInFilterMode:=False;
  end;
end;

procedure TDBMyLookupCombo.Select;
begin
  inherited Select;
  FInFilterMode:=False;
end;

constructor TDBMyLookupCombo.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  FShadowItems:=TList<TDBLookupItem>.Create;
  OnKeyUp:=KeyUp;
  OnKeyDown:=KeyDown;
  OnEnter:=OnFocus;
end;

destructor TDBMyLookupCombo.Destroy;
begin
  FreeAndNil(FShadowItems);
  inherited Destroy;
end;

end.

