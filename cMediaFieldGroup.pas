unit cMediaFieldGroup;
{$I DefineType.pas}

interface

uses
  Classes, SysUtils, Controls, ComCtrls, StdCtrls, ExtCtrls, DB, DBCtrls,
  Buttons, Dialogs, ExtDlgs, Graphics, {$IFnDEF FPC}JPEG, {$ENDIF}
  uDCLTypes, uDCLConst, uDCLMeasurements, uDCLData, uDCLField, uLZW, uDCLImages,
  uDCLMultiLang, uDCLMessages, uStringParams, uDCLUtils;

type

  { TMediaFieldGroup }

  TMediaFieldGroup=class(TPanel)
  private
    FData: TDataSource;
    FFieldName, FFileName: String;
    FIsCompressed, FReadOnly: Boolean;
    ButtonPanel: TPanel;
    MemoField: TDBMemo;
    GraficField: TDBImage;
    RichField: {$IFnDEF FPC}TDBRichEdit; {$ELSE}TDBMemo; {$ENDIF}
    FGraphicFileType: TGraficFileType;
    FGroupType: TGroupType;
    LoadButton, SaveButton, ClearButton: TSpeedButton;
    OpenPictureDialog: TOpenPictureDialog;
    SavePictureDialog: TSavePictureDialog;
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;


    procedure OnDBImageRead(Sender: TObject; S: TStream; var GraphExt: String);
    procedure OnDBImageWrite(Sender: TObject; S: TStream; GraphExt : string);
  public
    constructor Create(Parent: TWinControl; Data: TDataSource; Field: TDCLField;
      GroupType: TGroupType); overload;

    procedure Load(Sender: TObject);
    procedure Save(Sender: TObject);
    procedure Clear(Sender: TObject);

    procedure SaveData(FileName: String);
    procedure LoadData(FileName: String);

    property IsCompressed: Boolean read FIsCompressed write FIsCompressed;
  end;

implementation

{ TMediaFieldGroup }

procedure TMediaFieldGroup.OnDBImageRead(Sender: TObject; S: TStream;
  var GraphExt: String);
var
  Signature: Array of Byte;
  Source, Dest: TStream;
  Marker: Cardinal;
begin
  SetLength(Signature, 10);
  S.Read(Signature[0], 10);
  S.Position:=0;
  Marker:=0;
  S.Read(Marker, PAGSignatureSize);
  S.Position:=0;

  FIsCompressed:=False;
  If Marker=PAGSignature Then
  // (Signature[0]=$50) and (Signature[1]=$41) and (Signature[2]=$47) then
  begin
    FIsCompressed:=True;
    S.Position:=PAGSignatureSize;
    Source:=TMemoryStream.Create;
    Source.CopyFrom(S, S.Size-3);
    Dest:=TMemoryStream.Create;
    DecompressProc(Source, Dest);
    Dest.Position:=0;
    S.Position:=0;
    S.CopyFrom(Dest, Dest.Size);
    S.Position:=0;
    S.Read(Signature[0], 10);
    S.Position:=0;
    Source.Free;
    Dest.Free;
  end;

  If (Signature[0]=66)and(Signature[1]=77) Then
  begin
    GraphExt:='bmp';
    FGraphicFileType:=gftBMP;
  end
  Else If (Signature[0]=$FF)and(Signature[1]=$D8) Then
  begin
    GraphExt:='jpg';
    FGraphicFileType:=gftJPEG;
  end
  Else If (Signature[0]=$89)and(Signature[1]=$50)and(Signature[2]=$4E)and(Signature[3]=$47)and
    (Signature[4]=$0D)and(Signature[5]=$0A)and(Signature[6]=$1A)and(Signature[7]=$0A) Then
  begin
    GraphExt:='png';
    FGraphicFileType:=gftPNG;
  end
  Else If (Signature[0]=$47)and(Signature[1]=$49)and(Signature[2]=$46)and(Signature[3]=$38) Then
  begin
    GraphExt:='gif';
    FGraphicFileType:=gftGIF;
  end
  Else If ((Signature[0]=$49)and(Signature[1]=$49)and(Signature[2]=$2A)and(Signature[3]=$00))or
    ((Signature[4]=$4D)and(Signature[5]=$4D)and(Signature[6]=$00)and(Signature[7]=$2A)) Then
  begin
    GraphExt:='tiff';
    FGraphicFileType:=gftTIFF;
  end
  Else If (Signature[0]=$00)and(Signature[1]=$00)and((Signature[2]=$01)or(Signature[2]=$02))and
    (Signature[3]=$00)and(Signature[4]>=1) Then
  begin
    GraphExt:='ico';
    FGraphicFileType:=gftIcon;
  end
  Else
  begin
    GraphExt:='Unk';
    FGraphicFileType:=gftOther;
  end;
end;

procedure TMediaFieldGroup.OnDBImageWrite(Sender: TObject; S: TStream;
  GraphExt: string);
begin
  if FIsCompressed then
  begin

  end;
end;

constructor TMediaFieldGroup.Create(Parent: TWinControl; Data: TDataSource;
  Field: TDCLField; GroupType: TGroupType);
begin
  inherited Create(Parent);
  Self.Parent:=Parent;

  If Field.Height>0 Then
    Height:=Field.Height
  Else
    Height:=GroupHeight;

  If Field.Width>0 Then
    Width:=Field.Width
  else
    Width:=MemoWidth;

  FGroupType:=GroupType;
  FData:=Data;
  FFieldName:=Field.FieldName;
  FReadOnly:=Field.ReadOnly;

  ButtonPanel:=TPanel.Create(Self);
  ButtonPanel.Parent:=Self;
  ButtonPanel.BevelInner:=bvLowered;
  ButtonPanel.Align:=alTop;
  ButtonPanel.Height:=GroupButtonPanelHeight;

  Case GroupType of
  gtGrafic:
  begin
    FGraphicFileType:=gftJPEG;
    GraficField:=TDBImage.Create(Self);
    GraficField.Parent:=Self;
    GraficField.DataSource:=FData;
{$IFDEF FPC}
    GraficField.Caption:='';
    GraficField.OnDBImageRead:=OnDBImageRead;
{$ENDIF}
    GraficField.DataField:=FFieldName;
    GraficField.Align:=alClient;
    GraficField.Stretch:=False;
    GraficField.ReadOnly:=FReadOnly;
    If Field.Hint<>'' Then
    begin
      GraficField.Hint:=Field.Hint;
      GraficField.ShowHint:=True;
    end;
  end;
  gtRichText:
  begin
    RichField:={$IFnDEF FPC}TDBRichEdit{$ELSE}TDBMemo{$ENDIF}.Create(Self);
    RichField.Parent:=Self;
    RichField.Align:=alClient;
    RichField.ScrollBars:=ssBoth;
    RichField.DataSource:=FData;
    RichField.DataField:=FFieldName;
    RichField.ReadOnly:=FReadOnly;
    If Field.Hint<>'' Then
    begin
      RichField.Hint:=Field.Hint;
      RichField.ShowHint:=True;
    end;
  end;
  gtMemo:
  begin
    MemoField:=TDBMemo.Create(Self);
    MemoField.Parent:=Self;
    MemoField.Align:=alClient;
    MemoField.ScrollBars:=ssBoth;
    MemoField.DataSource:=FData;
{$IFDEF FPC}
    MemoField.Caption:='';
{$ENDIF}
    MemoField.DataField:=FFieldName;
    MemoField.ReadOnly:=FReadOnly;
    If Field.Hint<>'' Then
    begin
      MemoField.Hint:=Field.Hint;
      MemoField.ShowHint:=True;
    end;
  end;
  end;

  If not FReadOnly Then
  begin
    LoadButton:=TSpeedButton.Create(ButtonPanel);
    LoadButton.Parent:=ButtonPanel;
    LoadButton.Left:=BeginStepLeft+40;
    LoadButton.Top:=GroupToolButtonTop;
    LoadButton.Width:=25;
    LoadButton.Height:=GroupToolButtonHeight;
    LoadButton.Hint:=GetDCLMessageString(msLoad);
    LoadButton.ShowHint:=True;
    LoadButton.OnClick:=Load;
    LoadButton.Glyph.Assign(DrawBMPButton(ptLoad));

    ClearButton:=TSpeedButton.Create(ButtonPanel);
    ClearButton.Parent:=ButtonPanel;
    ClearButton.Left:=BeginStepLeft+80;
    ClearButton.Top:=GroupToolButtonTop;
    ClearButton.Width:=25;
    ClearButton.Height:=GroupToolButtonHeight;
    ClearButton.Hint:=GetDCLMessageString(msClear);
    ClearButton.ShowHint:=True;
    ClearButton.OnClick:=Clear;
    ClearButton.Glyph.Assign(DrawBMPButton(ptClear));
  end;

  SaveButton:=TSpeedButton.Create(ButtonPanel);
  SaveButton.Parent:=ButtonPanel;
  SaveButton.Left:=BeginStepLeft;
  SaveButton.Top:=GroupToolButtonTop;
  SaveButton.Width:=25;
  SaveButton.Height:=GroupToolButtonHeight;
  SaveButton.Hint:=GetDCLMessageString(msSave);
  SaveButton.ShowHint:=True;
  SaveButton.OnClick:=Save;
  SaveButton.Glyph.Assign(DrawBMPButton(ptSave));
end;

procedure TMediaFieldGroup.Load(Sender: TObject);
begin
  Case FGroupType of
  gtGrafic:
  begin
    OpenPictureDialog:=TOpenPictureDialog.Create(Self);
    OpenPictureDialog.DefaultExt:='jpg';
    OpenPictureDialog.Filter:=GraphicFilter(TGraphic);
    If OpenPictureDialog.Execute Then
      LoadData(OpenPictureDialog.FileName);

    FreeAndNil(OpenPictureDialog);
  end;
  gtMemo, gtRichText:
  begin
    OpenDialog:=TOpenDialog.Create(nil);
    Case FGroupType of
    gtMemo:
    begin
      OpenDialog.DefaultExt:='txt';
      OpenDialog.Filter:=GetDCLMessageString(msText)+' (*.txt)|*.txt|'+
          InitCap(GetDCLMessageString(msAll)+' (*.*)|*.*');
    end;
    gtRichText:
    begin
      OpenDialog.DefaultExt:='rtf';
      OpenDialog.Filter:=GetDCLMessageString(msFormated)+
          GetDCLMessageString(msText)+' (*.rtf)|*.rtf|'+InitCap(GetDCLMessageString(msAll)+
          ' (*.*)|*.*');
    end;
    end;
    If OpenDialog.Execute Then
      LoadData(OpenDialog.FileName);

    FreeAndNil(OpenDialog);
  end;
  end;
end;

procedure TMediaFieldGroup.Save(Sender: TObject);
begin
  Case FGroupType of
  gtGrafic:
  begin
    SavePictureDialog:=TSavePictureDialog.Create(Self);
    SavePictureDialog.Name:='SavePictureDialog1';
    SavePictureDialog.DefaultExt:=GetExtByType(FGraphicFileType);
    SavePictureDialog.Filter:=GraphicFilter(TGraphic);

    If SavePictureDialog.Execute Then
      SaveData(SavePictureDialog.FileName);

    FreeAndNil(SavePictureDialog);
  end;
  gtMemo, gtRichText:
  begin
    SaveDialog:=TSaveDialog.Create(nil);
    Case FGroupType of
    gtMemo:
    begin
      SaveDialog.DefaultExt:='txt';
      SaveDialog.Filter:=GetDCLMessageString(msText)+' (*.txt)|*.txt|'+
          InitCap(GetDCLMessageString(msAll)+' (*.*)|*.*');
    end;
    gtRichText:
    begin
      SaveDialog.DefaultExt:='rtf';
      SaveDialog.Filter:=GetDCLMessageString(msFormated)+
          GetDCLMessageString(msText)+' (*.rtf)|*.rtf|'+InitCap(GetDCLMessageString(msAll)+
          ' (*.*)|*.*');
    end;
    end;
    If SaveDialog.Execute Then
      SaveData(SaveDialog.FileName);
    FreeAndNil(SaveDialog);
  end;
  end;
end;

procedure TMediaFieldGroup.Clear(Sender: TObject);
begin
  if not FReadOnly then
  If ShowErrorMessage(10, GetDCLMessageString(msClearContentQ))=1 Then
  begin
    FData.Edit;
    FData.DataSet.FieldByName(FFieldName).Clear;
  end;
end;

procedure TMediaFieldGroup.SaveData(FileName: String);
var
  bmp: TBitmap;
  jpg: TJpegImage;
  MS: TMemoryStream;
  TS: TStringList;
begin
  FFileName:=FileName;
  Case GetGraficFileType(FileName) of
  gftJPEG:
  begin
    FIsCompressed:=False;
    MS:=TMemoryStream.Create;
    TBlobField(FData.DataSet.FieldByName(FFieldName)).SaveToStream(MS);
    MS.Seek(0, soFromBeginning);
    bmp:=TBitmap.Create;
    bmp.LoadFromStream(MS);
    jpg:=TJpegImage.Create;
    jpg.Assign(bmp);
    jpg.CompressionQuality:=JPEGCompressionQuality;
    jpg.SaveToFile(FileName);
    FreeAndNil(bmp);
    FreeAndNil(jpg);
  end;
  gftBMP, gftNone:
  If FData.DataSet.FieldByName(FFieldName).DataType in TBlobFields Then
    TBlobField(FData.DataSet.FieldByName(FFieldName)).SaveToFile(FileName)
  Else
  begin
    TS:=TStringList.Create;
    TS.Text:=FData.DataSet.FieldByName(FFieldName).AsString;
    TS.SaveToFile(FileName);
    FreeAndNil(TS);
  end;
  end;
end;

procedure TMediaFieldGroup.LoadData(FileName: String);
var
  bmp: TBitmap;
  jpg: TJpegImage;
  MS: TMemoryStream;
  TS: TStringList;
begin
  FData.Edit;
  Case GetGraficFileType(FileName) of
  gftJPEG:
  begin
    FIsCompressed:=False;
    jpg:=TJpegImage.Create;
    bmp:=TBitmap.Create;
    jpg.LoadFromFile(FileName);
    MS:=TMemoryStream.Create;
    bmp.Assign(jpg);
    bmp.SaveToStream(MS);
    TBlobField(FData.DataSet.FieldByName(FFieldName)).LoadFromStream(MS);
    FreeAndNil(jpg);
    FreeAndNil(bmp);
    FreeAndNil(MS);
  end;
  gftBMP, gftNone:
  begin
    If FData.DataSet.FieldByName(FFieldName).DataType in TBlobFields Then
      TBlobField(FData.DataSet.FieldByName(FFieldName)).LoadFromFile(FileName)
    Else
    begin
      TS:=TStringList.Create;
      TS.LoadFromFile(FileName);
      FData.DataSet.FieldByName(FFieldName).AsString:=TS.Text;
      FreeAndNil(TS);
    end;
  end;
  end;
end;

end.

