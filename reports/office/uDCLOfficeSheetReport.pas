unit uDCLOfficeSheetReport;
{$mode Delphi}

interface

uses
  Classes, SysUtils, ComObj, Variants, Windows, DB, LazFileUtils,
  uDCLConst, uDCLDBAwareTypes, uDCLData, uDCLDBConnector, uDCLBaseOfficeReport,
  uDCLValuesParser;

type

  { TDCLOfficeSheetReport }

  TDCLOfficeSheetReport=class(TDCLBaseOfficeReport)
  private
    OO, NF, Loc, Sheets, Sheet, Cell, Range, Desktop, Document, VariantArray: Variant;
    FExcel, WBk: OleVariant;
  public
    procedure Calc(ParamStr: String; Save, Close: Boolean);
    procedure Excel(ParamStr: String; Save, Close: Boolean);
  end;

implementation

uses
  uSystemUtils, uDCLOfficeUtils, uDCLMessages, uSQLUtils,
  uStringParams, uRunProgram, uDCLGlobalVariables, uDCLException, uStringUtils;

{ TDCLOfficeSheetReport }

procedure TDCLOfficeSheetReport.Calc(ParamStr: String; Save, Close: Boolean);
var
  SQLStr, Fields, FileName, OutFileName, ColorStr, Ext, TemplateExt: String;
  ToPDF, ToHTML, EnableRowChColor, EnableColChColor, Any: Boolean;
  v1: Byte;
  RecRepNum: Cardinal;
  StartRow, StartCol, RowRColor, RowBColor, RowGColor, ColRColor, ColBColor, ColGColor: Integer;
  DCLQuery: TDCLDialogQuery;
begin
  Ext:='ods';
  TemplateExt:='ots';

  if FindParam('TemplateName=', ParamStr)<>'' then
  begin
    FileName:=GetTemplateFile(FindParam('TemplateName=', ParamStr),
      FindParam('Template=', ParamStr), Ext);
  end;

  FileName:=FindParam('Template=', ParamStr);
  If not FilenameIsAbsolute(FileName) then
    FileName:=GPT.AppConfigDir+FileName;
  If NoFileExt(FileName) then
  begin
    OfficeDocumentFormat:=odfOO;
    if FileExists(FileName+'.'+TemplateExt) then
    begin
      OfficeDocumentFormat:=odfOO;
      FileName:=FileName+'.'+TemplateExt;
    end
    else
    begin
      if FileExists(FileName+'.'+Ext) then
      begin
        OfficeDocumentFormat:=odfOO;
        FileName:=FileName+'.'+Ext;
      end;
    end;
  end
  else
  begin
    OfficeDocumentFormat:=GetDocumentType(FileName);
  end;

  OutFileName:=FindParam('FileName=', ParamStr);
  if not FilenameIsAbsolute(OutFileName) then
    OutFileName:=GPT.AppConfigDir+OutFileName;

  If FileExists(FileName) then
  begin
    try
      OO:=CreateOleObject('com.sun.star.ServiceManager');
      Desktop:=OO.CreateInstance('com.sun.star.frame.Desktop');
      VariantArray:=VarArrayCreate([0, 0], varVariant);
      Case OfficeDocumentFormat of
      odfMSO2007:
      VariantArray[0]:=MakePropertyValue(OO, 'FilterName', 'MS Excel 2007');
      odfMSO97:
      VariantArray[0]:=MakePropertyValue(OO, 'FilterName', 'MS Excel 97');
      odfOO, odfPossible:
      VariantArray[0]:=MakePropertyValue(OO, 'FilterName', 'calc8');
      end;
    Except
      Sheets:=Unassigned;
      Sheet:=Unassigned;
      Document:=Unassigned;
      Desktop:=Unassigned;
      OO:=Unassigned;
      ShowErrorMessage( - 6001, '');
      Exit;
    end;
    Try
      Document:=Desktop.LoadComponentFromURL(FileNameToURL(FileName), '_blank', 0, VariantArray);
      OOSetVisible(Document, False);
      Sheets:=Document.GetSheets;
      Sheet:=Sheets.getByIndex(0);
    Except
      Sheets:=Unassigned;
      Sheet:=Unassigned;
      Document:=Unassigned;
      Desktop:=Unassigned;
      OO:=Unassigned;
      ShowErrorMessage( - 6003, '');
      Exit;
    End;

    try
      Range:=Sheet.getCellRangeByName('DATA');
      StartRow:=Range.RangeAddress.StartRow;
      StartCol:=Range.RangeAddress.StartColumn;
    Except
      OOSetVisible(Document, True);
      Document.Close(False);
      Sheets:=Unassigned;
      Sheet:=Unassigned;
      Document:=Unassigned;
      Desktop:=Unassigned;
      OO:=Unassigned;
      ShowErrorMessage( - 5002, '');
      Exit;
    end;

    NF:=Document.GetNumberFormats;
    Loc:=OO.Bridge_GetStruct('com.sun.star.lang.Locale');

    SQLStr:=FindParam('SQL=', ParamStr);
    If (SQLStr='') and (FExtSQL<>'') Then
      SQLStr:=FExtSQL;

    Fields:=FindParam('FieldsSet=', ParamStr);

    if Fields<>'' then
    begin
      SQLStr:=ReplaceSQLFields(SQLStr, Fields);
    end;

    FValuseParser.TranslateVals(SQLStr, nil, False);

    DCLQuery:=TDCLDialogQuery.Create(Self);
    FDCLConnector.SetConnector(DCLQuery);

    DCLQuery.SQL.Text:=SQLStr;
    try
      DCLQuery.Open;
    Except
      on E: Exception do
      begin
        OOSetVisible(Document, True);
        raise TDCLException.Create( - 1104, E.Message);
      end;
    end;
    DCLQuery.First;

    If PosEx('ToPDF=1', ParamStr)<>0 Then
      ToPDF:=True
    Else
      ToPDF:=False;

    If PosEx('ToHTML=1', ParamStr)<>0 Then
      ToHTML:=True
    Else
      ToHTML:=False;

    EnableRowChColor:=False;
    ColorStr:=FindParam('AlternationRowBackColor=', ParamStr);
    If ColorStr<>'' Then
    begin
      RowRColor:=StrToInt(Copy(ColorStr, 1, 2));
      RowBColor:=StrToInt(Copy(ColorStr, 3, 2));
      RowGColor:=StrToInt(Copy(ColorStr, 5, 2));
      EnableRowChColor:=True;
    end;

    EnableColChColor:=False;
    ColorStr:=FindParam('AlternationColBackColor=', ParamStr);
    If ColorStr<>'' Then
    begin
      ColRColor:=StrToInt(Copy(ColorStr, 1, 2));
      ColBColor:=StrToInt(Copy(ColorStr, 3, 2));
      ColGColor:=StrToInt(Copy(ColorStr, 5, 2));
      EnableColChColor:=True;
    end;

    Any:=False;
    RecRepNum:=1;
    While Not DCLQuery.Eof do
    begin
      For v1:=0 to DCLQuery.FieldCount-1 do
      begin
        SQLStr:=TrimRight(DCLQuery.Fields[v1].AsString);
        InsertTextByXY(Sheet, Cell, SQLStr, RecRepNum+StartRow-1,
          v1+1+StartCol-1);

        case DCLQuery.Fields[v1].DataType of
        ftString, ftMemo, ftFmtMemo, ftWideString, ftFixedWideChar,
          ftWideMemo:begin
          SetFormulaByXY(Loc, NF, Sheet, Cell, '@', RecRepNum+StartRow-1, v1+1+StartCol-1);
        end;
        ftSmallint, ftInteger, ftWord, ftAutoInc, ftLargeint, ftVariant, ftBCD
          {$IFnDEF FPC},ftLongWord, ftShortint, ftByte{$ENDIF}:begin
          SetFormulaByXY(Loc, NF, Sheet, Cell, '# ##0', RecRepNum+StartRow-1, v1+1+StartCol-1);
        end;
        ftFloat {$IFnDEF FPC}, ftExtended, ftSingle{$ENDIF}:begin
          SetFormulaByXY(Loc, NF, Sheet, Cell, '@', RecRepNum+StartRow-1, v1+1+StartCol-1);
        end;
        ftCurrency:begin
          SetFormulaByXY(Loc, NF, Sheet, Cell, '# ##0,00', RecRepNum+StartRow-1, v1+1+StartCol-1);
        end;
        ftDate:begin
          SetFormulaByXY(Loc, NF, Sheet, Cell, 'DD.MM.YY', RecRepNum+StartRow-1, v1+1+StartCol-1);
        end;
        ftTime:begin
          SetFormulaByXY(Loc, NF, Sheet, Cell, 'HH:MM:SS', RecRepNum+StartRow-1, v1+1+StartCol-1);
        end;
        ftDateTime, ftTimeStamp{$IFnDEF FPC}, ftOraTimeStamp{$ENDIF}:begin
          SetFormulaByXY(Loc, NF, Sheet, Cell, 'DD.MM.YYYY HH:MM:SS', RecRepNum+StartRow-1, v1+1+StartCol-1);
        end;
        Else
          SetFormulaByXY(Loc, NF, Sheet, Cell, '@', RecRepNum+StartRow-1, v1+1+StartCol-1);
        end;

        If EnableRowChColor Then
          If RecRepNum Mod 2=0 Then
            Cell.cellBackColor:=(RowRColor or(RowGColor Shl 8)or(RowBColor Shl 16));
        If EnableColChColor Then
          If v1 Mod 2=0 Then
            Cell.cellBackColor:=(ColRColor or(ColGColor Shl 8)or(ColBColor Shl 16));
      end;
      inc(RecRepNum);
      Any:=True;
      DCLQuery.Next;
    end;
    DCLQuery.Close;

    FileName:=AddToFileName(FileName, '_Report');
    If ToPDF Then
      OOExportToFormat(Document, OutFileName, 'pdf');

    If ToHTML Then
      OOExportToFormat(Document, OutFileName, 'html');

    FileName:=ChangeFileExt(OutFileName, '.'+Ext);
    OOSetVisible(Document, True);
    If Save Then
    begin
      Case OfficeDocumentFormat of
      odfMSO97:
      begin
        VariantArray[0]:=MakePropertyValue(OO, 'FilterName', 'MS Excel 97');
      end;
      odfMSO2007:
      begin
        VariantArray[0]:=MakePropertyValue(OO, 'FilterName', 'MS Excel 2007');
      end;
      odfOO, odfPossible:
      begin
        VariantArray[0]:=MakePropertyValue(OO, 'FilterName', 'calc8');
      end;
      end;

      Document.StoreAsURL(FileNameToURL(FileName), VariantArray);
    end;

    If Close Then
    Begin
      Document.Close(True);
      Document:=Unassigned;
    End;

    Sheets:=Unassigned;
    Sheet:=Unassigned;

    if Any then
    begin
      If ToPDF Then
        OpenFile(ChangeFileExt(FileName, '.pdf'));

      If ToHTML Then
        OpenFile(ChangeFileExt(FileName, '.html'));
    end;
  end
  Else
    ShowErrorMessage( - 5007, FileName);
end;

procedure TDCLOfficeSheetReport.Excel(ParamStr: String; Save, Close: Boolean);
var
  SQLStr, FileName, OutFileName, ColorStr, Ext, TemplateExt, Fields, sv: String;
  EnableRowChColor, EnableColChColor, Hide, IsDate: Boolean;
  RecRepNum, v1: Word;
  RowRColor, RowBColor, RowGColor, ColRColor, ColBColor, ColGColor: Integer;
  DCLQuery: TDCLDialogQuery;
  FillStrategy: TSheetFillStrategy;
  ReportDate: TDate;
  ReportTime: TTime;
  ReportDateTime: TDateTime;
begin
  Ext:='xls';
  TemplateExt:='xlt';
  Hide:=Save and Close;

  if FindParam('TemplateName=', ParamStr)<>'' then
  begin
    FileName:=GetTemplateFile(FindParam('TemplateName=', ParamStr),
      FindParam('Template=', ParamStr), 'xlsx');
  end;

  FillStrategy:=sfsInsert;
  if FindParam('FillStrategy=', ParamStr)<>'' then
  begin
    if LowerCase(FindParam('FillStrategy=', ParamStr))='insert' then
    begin
      //FillStrategy:=sfsInsert;
    end else
    if LowerCase(FindParam('FillStrategy=', ParamStr))='replace' then
    begin
      FillStrategy:=sfsReplace;
    end;
  end;

  FileName:=FindParam('Template=', ParamStr);
  If not FilenameIsAbsolute(FileName) then
    FileName:=GPT.AppConfigDir+FileName;
  If NoFileExt(FileName) then
  begin
    if FileExists(FileName+'.'+TemplateExt) then
    begin
      FileName:=FileName+'.'+TemplateExt;
    end
    else
    begin
      if FileExists(FileName+'.'+TemplateExt+'x') then
      begin
        TemplateExt:=TemplateExt+'x';
        FileName:=FileName+'.'+TemplateExt;
      end
      else
      begin
        if FileExists(FileName+'.'+Ext) then
        begin
          FileName:=FileName+'.'+Ext;
        end
        else
        begin
          if FileExists(FileName+'.'+Ext+'x') then
          begin
            Ext:=Ext+'x';
            FileName:=FileName+'.'+Ext;
          end;
        end;
      end;
    end;
  end;

  OutFileName:=AddToFileName(FileName, '_Report');
  if FindParam('FileName=', ParamStr)<>'' then
  begin
    OutFileName:=FindParam('FileName=', ParamStr);
  end;

  if not FilenameIsAbsolute(OutFileName) then
    OutFileName:=GPT.AppConfigDir+OutFileName;

  If FileExists(FileName) Then
  begin
    try
      FExcel:=CreateOleObject('Excel.Application'+GPT.ExcelOLEExtension);
      FExcel.Visible:=False;
      WBk:=FExcel.WorkBooks.Add(FileName);
    Except
      ShowErrorMessage( - 6000, '');
      Exit;
    end;
    try
      FExcel.Sheets[1].Range['DATA'].Select;
    Except
      ShowErrorMessage( - 5002, '');
      FExcel.Visible:=True;
      Exit;
    end;

    SQLStr:=FindParam('SQL=', ParamStr);
    If (SQLStr='') and (FExtSQL<>'') Then
      SQLStr:=FExtSQL;

    Fields:=FindParam('FieldsSet=', ParamStr);

    if Fields<>'' then
    begin
      SQLStr:=ReplaceSQLFields(SQLStr, Fields);
    end;

    FValuseParser.TranslateVals(SQLStr, nil, False);

    DCLQuery:=TDCLDialogQuery.Create(Self);
    FDCLConnector.SetConnector(DCLQuery);

    DCLQuery.SQL.Text:=SQLStr;
    try
      DCLQuery.Open;
    Except
      on E: Exception do
      begin
        FExcel.Visible:=True;
        raise TDCLException.Create( - 1104, E.Message);
      end;
    end;
    DCLQuery.First;

    EnableRowChColor:=False;
    ColorStr:=FindParam('AlternationRowBackColor=', ParamStr);
    If ColorStr<>'' Then
    begin
      RowRColor:=StrToInt(Copy(ColorStr, 1, 2));
      RowBColor:=StrToInt(Copy(ColorStr, 3, 2));
      RowGColor:=StrToInt(Copy(ColorStr, 5, 2));
      EnableRowChColor:=True;
    end;

    EnableColChColor:=False;
    ColorStr:=FindParam('AlternationColBackColor=', ParamStr);
    If ColorStr<>'' Then
    begin
      ColRColor:=StrToInt(Copy(ColorStr, 1, 2));
      ColBColor:=StrToInt(Copy(ColorStr, 3, 2));
      ColGColor:=StrToInt(Copy(ColorStr, 5, 2));
      EnableColChColor:=True;
    end;

    RecRepNum:=0;
    case FillStrategy of
      sfsInsert:RecRepNum:=0;
      sfsReplace:RecRepNum:=1;
    end;
    While Not DCLQuery.Eof do
    begin
      if FillStrategy=sfsInsert then
        FExcel.Sheets[1].Range['DATA'].EntireRow.Insert;

      For v1:=0 to DCLQuery.FieldCount-1 do
      begin
        IsDate:=False;
        case DCLQuery.Fields[v1].DataType of
        ftString, ftMemo, ftFmtMemo, ftWideString, ftFixedWideChar,
          ftWideMemo:begin
          FExcel.Sheets[1].Range['DATA'].Cells.Item[RecRepNum, v1+1].NumberFormat:=String(Chr(64));
        end;
        ftSmallint, ftInteger, ftWord, ftAutoInc, ftLargeint, ftVariant, ftBCD
          {$IFnDEF FPC},ftLongWord, ftShortint, ftByte{$ENDIF}:begin
          FExcel.Sheets[1].Range['DATA'].Cells.Item[RecRepNum, v1+1].NumberFormat:=String(Chr(35));
        end;
        ftFloat{$IFnDEF FPC}, ftExtended, ftSingle{$ENDIF}:begin
          FExcel.Sheets[1].Range['DATA'].Cells.Item[RecRepNum, v1+1].NumberFormat:=String(Chr(64));
        end;
        ftCurrency:begin
          FExcel.Sheets[1].Range['DATA'].Cells.Item[RecRepNum, v1+1].NumberFormat:=AnsiString('# ##0.00');
        end;
        ftDate:begin
          FExcel.Sheets[1].Range['DATA'].Cells.Item[RecRepNum, v1+1].NumberFormat:=UTF8Decode('ДД.ММ.ГГГГ');
          ReportDate:=DCLQuery.Fields[v1].AsDateTime;
          FExcel.Sheets[1].Range['DATA'].Cells.Item[RecRepNum, v1+1].Value:=ReportDate;
          IsDate:=True;
        end;
        ftTime:begin
          FExcel.Sheets[1].Range['DATA'].Cells.Item[RecRepNum, v1+1].NumberFormat:=UTF8Decode('ЧЧ:мм:сс');
          ReportTime:=DCLQuery.Fields[v1].AsDateTime;
          FExcel.Sheets[1].Range['DATA'].Cells.Item[RecRepNum, v1+1].Value:=ReportTime;
          IsDate:=True;
        end;
        ftDateTime, ftTimeStamp{$IFnDEF FPC}, ftOraTimeStamp{$ENDIF}:begin
          FExcel.Sheets[1].Range['DATA'].Cells.Item[RecRepNum, v1+1].NumberFormat:=UTF8Decode('ДД.ММ.ГГГГ ЧЧ:мм:сс');
          ReportDateTime:=DCLQuery.Fields[v1].AsDateTime;
          FExcel.Sheets[1].Range['DATA'].Cells.Item[RecRepNum, v1+1].Value:=ReportDateTime;
          IsDate:=True;
        end;
        Else
          FExcel.Sheets[1].Range['DATA'].Cells.Item[RecRepNum, v1+1].NumberFormat:='';
        end;

        sv:=UTF8Decode(Trim(DCLQuery.Fields[v1].AsString));
        If Not IsDate Then
          FExcel.Sheets[1].Range['DATA'].Cells.Item[RecRepNum, v1+1].Value:=sv;

        If EnableRowChColor Then
          If RecRepNum Mod 2=0 Then
            FExcel.Sheets[1].Range['DATA'].Cells.Item[RecRepNum, v1+1].Interior.Color:=
              RGB(RowRColor, RowGColor, RowBColor);
        If EnableColChColor Then
          If v1 Mod 2=0 Then
            FExcel.Sheets[1].Range['DATA'].Cells.Item[RecRepNum, v1+1].Interior.Color:=
              RGB(ColRColor, ColGColor, ColBColor);
      end;
      if FillStrategy=sfsReplace then
        inc(RecRepNum);
      DCLQuery.Next;
    end;
    DCLQuery.Close;
    if not Hide then
      FExcel.Visible:=True;

    If Save Then
    begin
      ForceDirectories(ExtractFilePath(OutFileName));
      ExcelSave(FExcel, OutFileName);
    end;

    if Close then
      ExcelQuit(FExcel);
  end
  Else
    ShowErrorMessage( - 5004, FileName);
end;

end.

