unit uDCLCommandButton;
{$mode Delphi}

interface

uses
  Classes, SysUtils, Controls, Graphics,
  uDCLTypes, uDCLDBConnector;

type

  { TDCLCommandButton }

  TDCLCommandButton=class
  private
    FButton: TDCLDialogButton;
    FDBConnector: TDCLDBConnector;
  public
    Caption, Hint, Command, Pict: String;
    ChoiceButton, Default, Cancel, ForEach, Host: Boolean;
    FontStyle: TFontStyles;
    Width: Integer;

    constructor Create(DBConnector: TDCLDBConnector);

    procedure CreateControl(Parent: TWinControl; OnClick: TNotifyEvent);

    property Button: TDCLDialogButton read FButton;
  end;

implementation

uses
  uDCLConst, uDCLDataStorage, uDCLMeasurements;

{ TDCLCommandButton }

constructor TDCLCommandButton.Create(DBConnector: TDCLDBConnector);
begin
  FDBConnector:=DBConnector;
end;

procedure TDCLCommandButton.CreateControl(Parent: TWinControl; OnClick: TNotifyEvent);
var
  BinStore: TDCLDataStorage;
  MS: TMemoryStream;
  BM: TBitmap;
begin
  if not Assigned(FButton) then
  begin
    FButton:=TDCLDialogButton.Create(Parent);
    FButton.Parent:=Parent;
    FButton.Caption:=Caption;
    FButton.Hint:=Hint;
    FButton.ShowHint:=True;
    FButton.Font.Style:=FontStyle;
    if Width>0 then
      FButton.Width:=Width
    else
      FButton.Width:=ButtonWidth;
    FButton.Height:=ButtonHeight;
    FButton.Default:=Default;
    FButton.Cancel:=Cancel;
    FButton.OnClick:=OnClick;

    FButton.BorderSpacing.Around:=ButtonsInterval div 2;

    If FontStyle=[fsBold] Then
      FButton.Font.Style:=FButton.Font.Style+[fsBold];
    If FontStyle=[fsItalic] Then
      FButton.Font.Style:=FButton.Font.Style+[fsItalic];
    If FontStyle=[fsUnderLine] Then
      FButton.Font.Style:=FButton.Font.Style+[fsUnderLine];

    FButton.Glyph.Transparent:=True;

    If Pict<>'' Then
    begin
      BinStore:=TDCLDataStorage.Create(FDBConnector);
      MS:=BinStore.GetData(Pict, ftByName);
      If MS.Size>0 Then
      begin
        BM:=TBitmap.Create;
        MS.Position:=0;
        BM.LoadFromStream(MS);
        FButton.Glyph.TransparentMode:=tmFixed;
        FButton.Glyph.TransparentColor:=BM.Canvas.Pixels[0, 0];
        FButton.Glyph.Assign(BM);
        FButton.Glyph.Transparent:=True;
        MS.Free;
      end;
    end;
  end;
end;

end.

