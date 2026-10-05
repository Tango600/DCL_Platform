unit uDCLImages;
{$I DefineType.pas}

interface

uses
  Classes, SysUtils, Graphics,
  uBitReader, uBuffWriter, uLZW, uDCLResources;

type
  TPicturesTypes=(ptNone, pt0x0, ptEsc, ptFind, ptPrint, ptStructure, ptFormDotNew,
    ptUndo, ptFormDotActive, ptFormDotInactive, ptCut, ptCopy, ptAppend, ptLoad,
    ptSave, ptFindCurrCell, ptClearAllFind, ptClear, ptPaste,
    ptLogo_small, ptLogo, ptTools, ptDownArrow, ptUpArrow, ptGridFilter,
    ptNew);

Function DrawBMPButton(Const BMPType: TPicturesTypes): TBitmap;
function GetIcon: TIcon;

implementation

const
  PAGSignatureSize=3;
  PAGSignature=$474150;

function GetIcon: TIcon;
Var
  Marker: Cardinal;
  br: TBitReader;
  buw: TBuffWriter;
  MS, BS: TStream;
Begin
  MS:=TMemoryStream.Create;
  MS.Write(DCLRunIcon, Length(DCLRunIcon));

  If MS.Size>0 Then
  Begin
    Marker:=0;
    MS.Position:=0;
    MS.Read(Marker, PAGSignatureSize);

    If Marker=PAGSignature Then // PAG Signature
    Begin
      // Compressed BMP/
      BS:=TMemoryStream.Create;

      br:=TBitReader.Create(MS, 1024);
      buw:=TBuffWriter.Create(BS, 1020);

      DecompressProc(br, buw);

      br.Free;
      buw.Free;

      BS.Position:=0;
      MS.Create;
      MS.CopyFrom(BS, BS.Size);
      FreeAndNil(BS);
    End;

    Result:=TIcon.Create;
    MS.Position:=0;
    Result.LoadFromStream(MS);
  End
  Else
    Result:=TIcon.Create;

  FreeAndNil(MS);
End;

Function DrawBMPButton(Const BMPType: TPicturesTypes): TBitmap;
Var
  Marker: Cardinal;
  br: TBitReader;
  buw: TBuffWriter;
  MS, BS: TStream;
Begin
  Result:=nil;
  if BMPType=ptNone then
    Exit;

  if BMPType=pt0x0 then
  begin
    Result:=TBitmap.Create;
    Exit;
  end;

  MS:=TMemoryStream.Create;
  If BMPType=ptFind Then
    MS.Write(FindBMP, Length(FindBMP));
  If BMPType=ptGridFilter then
    MS.Write(GridFilter, Length(GridFilter));
  If BMPType=ptFindCurrCell Then
    MS.Write(FindCurrCellBMP, Length(FindCurrCellBMP));
  If BMPType=ptClearAllFind Then
    MS.Write(ClearAllFind, Length(ClearAllFind));
  If BMPType=ptPrint Then
    MS.Write(PrintBMP, Length(PrintBMP));
  If BMPType=ptStructure Then
    MS.Write(StructBMP, Length(StructBMP));
  If BMPType=ptEsc Then
    MS.Write(Esc, Length(Esc));
  If BMPType=ptLoad Then
    MS.Write(Bitmap_Load, Length(Bitmap_Load));
  If BMPType=ptSave Then
    MS.Write(Bitmap_Save, Length(Bitmap_Save));
  If BMPType=ptClear Then
    MS.Write(Bitmap_Clear, Length(Bitmap_Clear));
  If BMPType=ptFormDotNew Then
    MS.Write(FormDotNew, Length(FormDotNew));
  If BMPType=ptFormDotActive Then
    MS.Write(FormDotActive, Length(FormDotActive));
  If BMPType=ptFormDotInactive Then
    MS.Write(FormDotInactive, Length(FormDotInactive));

  If BMPType=ptCut Then
    MS.Write(Bitmap_Cut, Length(Bitmap_Cut));
  If BMPType=ptCopy Then
    MS.Write(Bitmap_Copy, Length(Bitmap_Copy));
  If BMPType=ptPaste Then
    MS.Write(Bitmap_Paste, Length(Bitmap_Paste));
  If BMPType=ptUndo Then
    MS.Write(Bitmap_Undo, Length(Bitmap_Undo));

  If BMPType=ptDownArrow Then
    MS.Write(DownArrow, Length(DownArrow));
  If BMPType=ptUpArrow Then
    MS.Write(UpArrow, Length(UpArrow));

  If (BMPType=ptNew) or (BMPType=ptAppend) Then
    MS.Write(Bitmap_New, Length(Bitmap_New));

  If BMPType=ptTools Then
    MS.Write(Tools, Length(Tools));

  If BMPType=ptLogo Then
    MS.Write(DCLbmp, Length(DCLbmp));

  If MS.Size>0 then
  Begin
    Marker:=0;
    MS.Position:=0;
    MS.Read(Marker, PAGSignatureSize);

    If Marker=PAGSignature then  // 80, 65, 71
    Begin
      // Compressed BMP/
      BS:=TMemoryStream.Create;

      br:=TBitReader.Create(MS, 1024);
      buw:=TBuffWriter.Create(BS, 1020);

      DecompressProc(br, buw);

      br.Free;
      buw.Free;

      BS.Position:=0;
      MS.Free;
      MS:=TMemoryStream.Create;
      MS.CopyFrom(BS, BS.Size);
      FreeAndNil(BS);
    End;

    Result:=TBitmap.Create;
    MS.Position:=0;
    Result.LoadFromStream(MS);
    Result.TransparentColor:=Result.Canvas.Pixels[0, 0];
    Result.TransparentMode:=tmFixed;
    Result.Transparent:=True;
  End
  Else
    Result:=TBitmap.Create;

  FreeAndNil(MS);
End;

end.

