unit uDCLOfficeTextReport;
{$mode Delphi}

interface

uses
  Classes, SysUtils, ComObj, Variants, Graphics,
  uDCLConst, uDCLTypes, uDCLData, uDCLBaseOfficeReport, uDCLDBConnector,
  uDCLValuesParser;

type

  { TDCLOfficeTextReport }

  TDCLOfficeTextReport=class(TDCLBaseOfficeReport)
  private
    OO, Desktop, Document, VariantArray: Variant;
    MsWord: OleVariant;
  public
    procedure Word(ParamStr: String; Save, Close: Boolean);
    procedure Writer(ParamStr: String; Save, Close: Boolean);
  end;

implementation

uses
  DB,
  {$IFDEF MSWINDOWS}
    uDCLOfficeUtils,
  {$ENDIF}
  uSystemUtils, uDCLUtils, uDCLMessages, uDCLGlobalVariables,
  uStringParams, uDBUtils, uRunProgram, SumProps;

{ TDCLOfficeTextReport }

procedure TDCLOfficeTextReport.Word(ParamStr: String; Save, Close: Boolean);
var
  StV: OleVariant;
  SQLStr, FileName, OutFileName, Ext, TemplateExt, LayotStr, LayotItem, BookmarckName: String;
  Layout: TStringList;
  DocNum: Cardinal;
  BookmarckNum, LayotCount, FontSize: Integer;

  ToWrite, BookmarkFromLayot, OneDoc, Hide: Boolean;
  FontStyleRec: TFontStyleRec;
  DCLQuery: TDCLDialogQuery;
begin
  Ext:='docx';
  TemplateExt:='dotx';

  Hide:=Save and Close;

  if FindParam('TemplateName=', ParamStr)<>'' then
  begin
    FileName:=GetTemplateFile(FindParam('TemplateName=', ParamStr),
      FindParam('Template=', ParamStr), Ext);
  end;

  FileName:=FindParam('Template=', ParamStr);
  If not IsFullPath(FileName) then
    FileName:=AppConfigDir+FileName;

  BookmarkFromLayot:=False;
  If NoFileExt(FileName) then
  begin
    OfficeDocumentFormat:=odfOO;
    if FileExists(FileName+'.'+TemplateExt) then
    begin
      OfficeDocumentFormat:=odfMSO2007;
      FileName:=FileName+'.'+TemplateExt;
    end
    else
    begin
      if FileExists(FileName+'.'+Ext) then
      begin
        OfficeDocumentFormat:=odfMSO2007;
        FileName:=FileName+'.'+Ext;
      end;
    end;
  end
  else
  begin
    OfficeDocumentFormat:=GetDocumentType(FileName);
  end;

  OneDoc:=FindParam('OneDoc=', ParamStr)='1';

  OutFileName:=FindParam('FileName=', ParamStr);
  if not IsFullPath(OutFileName) then
    OutFileName:=AppConfigDir+OutFileName;

  Layout:=TStringList.Create;
  If FileExists(FileName) Then
  begin
    LayotStr:=FindParam('Layot=', ParamStr);
    If LayotStr<>'' Then
    begin
      Layout.Clear;
      LayotCount:=ParamsCount(LayotStr);
      For BookmarckNum:=1 to ParamsCount(LayotStr) do
      begin
        BookmarkFromLayot:=True;
        LayotItem:=GetParam(LayotStr, BookmarckNum);

        Layout.Append(LayotItem);
      end;
    end;

    SQLStr:=FindParam('SQL=', ParamStr);
    If (SQLStr='') and (FExtSQL<>'') Then
      SQLStr:=FExtSQL;

    DCLQuery:=TDCLDialogQuery.Create(Self);
    FDCLConnector.SetConnector(DCLQuery);
    DCLQuery.SQL.Text:=SQLStr;
    try
      DCLQuery.Open;
    Except
      ShowErrorMessage( - 1104, 'SQL='+SQLStr);
    end;
    DCLQuery.First;

    DocNum:=1;
    While Not DCLQuery.Eof do
    begin
      WordRun(MsWord, GPT.WordOLEExtension);
      WordOpen(MsWord, FileName);
      if Hide then
        MsWord.Visible:=False;

      If (Not BookmarkFromLayot)and(LayotCount=0) Then
        LayotCount:=MsWord.ActiveDocument.BookMarks.Count;

      For BookmarckNum:=0 to LayotCount-1 do
      begin
        ToWrite:=False;
        FontSize:=0;

        FontStyleRec.Bold:=0;
        FontStyleRec.italic:=0;
        FontStyleRec.Undeline:=0;
        FontStyleRec.Center:=False;
        FontStyleRec.StrikeThrough:=0;

        If BookmarkFromLayot Then
        begin
          LayotItem:=Layout[BookmarckNum];
          BookmarckName:=ExtractSection(LayotItem);
          LayotStr:=ExtractSection(LayotItem);
          If PosEx('B', LayotStr)<>0 Then
            FontStyleRec.Bold:=1;
          If PosEx('I', LayotStr)<>0 Then
            FontStyleRec.italic:=1;
          If PosEx('U', LayotStr)<>0 Then
            FontStyleRec.Undeline:=1;
          If PosEx('C', LayotStr)<>0 Then
            FontStyleRec.Center:=True;
          If PosEx('S', LayotStr)<>0 Then
            FontStyleRec.StrikeThrough:=1;

          LayotStr:=ExtractSection(LayotItem);
          If LayotStr<>'' Then
            FontSize:=StrToIntEx(LayotStr);

          LayotStr:=ExtractSection(LayotItem);
          If LayotStr<>'' Then
            ToWrite:=PosEx('W', LayotStr)<>0;
        end
        Else
          BookmarckName:=MsWord.ActiveDocument.BookMarks.Item(BookmarckNum+1).Name;

        StV:='';
        If FieldExists(BookmarckName, DCLQuery) Then
        begin
          If ToWrite Then
            StV:=MoneyToString(DCLQuery.FieldByName(BookmarckName).AsCurrency, True, False)
          Else
            StV:=Trim(DCLQuery.FieldByName(BookmarckName).AsString);
        end
        else
        begin
          StV:='<>';
        end;

        WordInsert(MsWord, BookmarckName, StV, FontStyleRec.Bold, FontStyleRec.italic,
          FontStyleRec.StrikeThrough, FontStyleRec.Undeline, FontSize, FontStyleRec.Center);
      end;
      if not Hide then
        MsWord.Visible:=True;

      If Save Then
      begin
        if not OneDoc then
          StV:=AddToFileName(OutFileName, '_'+IntToStr(DocNum))
        else
          StV:=OutFileName;
        ForceDirectories(ExtractFilePath(StV));
        MsWord.ActiveDocument.SaveAs(StV, EmptyParam, EmptyParam, EmptyParam, EmptyParam,
          EmptyParam, EmptyParam, EmptyParam, EmptyParam, EmptyParam, EmptyParam, EmptyParam,
          EmptyParam, EmptyParam, EmptyParam, EmptyParam);
      end;

      If Close then
      Begin
        CloseDocument(MsWord);
        WordClose(MsWord);
      End;

      DCLQuery.Next;
    end;
    end
    Else
      ShowErrorMessage( - 5004, FileName);

  FreeAndNil(Layout);
end;

procedure TDCLOfficeTextReport.Writer(ParamStr: String; Save, Close: Boolean);
var
  TextPointer, CursorPointer, BookmarksSupplier, BookMark: Variant;
  BookmarckNum, LayotCount, FontSize, lastBookmarks: Word;
  DocNum: Cardinal;
  SQLStr, FileName, OutFileName, Ext, TemplateExt, InsStr, BookMarkName, LayotStr, LayotItem: String;
  Layot: TStringList;
  DCLQuery: TDCLDialogQuery;

  ToPDF, ToHTML, ToWrite, BookmarkFromLayot: Boolean;
  FontStyleRec: TFontStyleRec;
begin
  Ext:='odt';
  TemplateExt:='ott';
  Layot:=TStringList.Create;

  if FindParam('TemplateName=', ParamStr)<>'' then
  begin
    FileName:=GetTemplateFile(FindParam('TemplateName=', ParamStr),
      FindParam('Template=', ParamStr), Ext);
  end;

  FileName:=FindParam('Template=', ParamStr);
  If not IsFullPath(FileName) then
    FileName:=AppConfigDir+FileName;

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
  if not IsFullPath(OutFileName) then
    OutFileName:=AppConfigDir+OutFileName;

  If FileExists(FileName) Then
  begin
    LayotStr:=FindParam('Layot=', ParamStr);
    If LayotStr<>'' Then
    begin
      Layot.Clear;
      LayotCount:=ParamsCount(LayotStr);
      For BookmarckNum:=1 to ParamsCount(LayotStr) do
      begin
        BookmarkFromLayot:=True;
        LayotItem:=GetParam(LayotStr, BookmarckNum);

        Layot.Append(LayotItem);
      end;
    end;

    DCLQuery:=TDCLDialogQuery.Create(Self);
    DCLQuery.Name:='OfficeReport_'+IntToStr(UpTime);
    FDCLConnector.SetConnector(DCLQuery);
    try
      If VarIsEmpty(OO) Then
        OO:=CreateOleObject('com.sun.star.ServiceManager');

      Desktop:=OO.CreateInstance('com.sun.star.frame.Desktop');
      VariantArray:=VarArrayCreate([0, 1], varVariant);
      Case OfficeDocumentFormat of
      odfMSO2007:
      VariantArray[0]:=MakePropertyValue(OO, 'FilterName', 'MS Word 2007');
      odfMSO97:
      VariantArray[0]:=MakePropertyValue(OO, 'FilterName', 'MS Word 97');
      odfOO, odfPossible:
      VariantArray[0]:=MakePropertyValue(OO, 'FilterName', 'writer8');
      end;
    Except
      Document:=Unassigned;
      Desktop:=Unassigned;
      OO:=Unassigned;
      ShowErrorMessage( - 6002, '');
      Exit;
    end;

    If PosEx('ToPDF=1', ParamStr)<>0 Then
      ToPDF:=True
    Else
      ToPDF:=False;

    If PosEx('ToHTML=1', ParamStr)<>0 Then
      ToHTML:=True
    Else
      ToHTML:=False;

    SQLStr:=FindParam('SQL=', ParamStr);
    If (SQLStr='') and (FExtSQL<>'') Then
      SQLStr:=FExtSQL;

    DCLQuery.Close;
    DCLQuery.SQL.Clear;
    DCLQuery.SQL.Text:=SQLStr;
    try
      DCLQuery.Open;
    Except
      ShowErrorMessage( - 1104, 'SQL='+SQLStr);
    end;
    DCLQuery.First;

    DocNum:=1;
    While Not DCLQuery.Eof do
    begin
      Try
        Document:=Desktop.LoadComponentFromURL(FileNameToURL(FileName), '_blank', 0, VariantArray);
        OOSetVisible(Document, False);
        TextPointer:=Document.GetText;
      Except
        Document:=Unassigned;
        Desktop:=Unassigned;
        OO:=Unassigned;
        ShowErrorMessage( - 6003, '');
        Exit;
      End;
      CursorPointer:=TextPointer.CreateTextCursor;

      BookmarksSupplier:=Document.getBookmarks;
      If (Not BookmarkFromLayot)and(LayotCount=0) Then
        LayotCount:=BookmarksSupplier.Count;

      For BookmarckNum:=0 to LayotCount-1 do
      begin
        try
          FontSize:=0;
          BookmarksSupplier:=Document.getBookmarks;
          CursorPointer:=TextPointer.CreateTextCursor;

          lastBookmarks:=BookmarksSupplier.Count;

          if lastBookmarks=0 then break;

          If BookmarkFromLayot Then
          begin
            ToWrite:=False;

            FontStyleRec.Bold:=0;
            FontStyleRec.italic:=0;
            FontStyleRec.Undeline:=0;
            FontStyleRec.Center:=False;
            FontStyleRec.StrikeThrough:=0;

            LayotItem:=Layot[BookmarckNum];
            BookMarkName:=ExtractSection(LayotItem);
            LayotStr:=ExtractSection(LayotItem);
            If PosEx('B', LayotStr)<>0 Then
              FontStyleRec.Bold:=1;
            If PosEx('I', LayotStr)<>0 Then
              FontStyleRec.italic:=1;
            If PosEx('U', LayotStr)<>0 Then
              FontStyleRec.Undeline:=1;
            If PosEx('C', LayotStr)<>0 Then
              FontStyleRec.Center:=True;
            If PosEx('S', LayotStr)<>0 Then
              FontStyleRec.StrikeThrough:=1;

            LayotStr:=ExtractSection(LayotItem);
            If LayotStr<>'' Then
              FontSize:=StrToIntEx(LayotStr);

            LayotStr:=ExtractSection(LayotItem);
            If LayotStr<>'' Then
              If PosEx('W', LayotStr)<>0 Then
                ToWrite:=True
              Else
                ToWrite:=False;
          end
          Else
            BookMarkName:=BookmarksSupplier.getByIndex(BookmarckNum).getName;

          If FieldExists(BookMarkName, DCLQuery) Then
          begin
            BookMark:=BookmarksSupplier.getByIndex(BookmarckNum).getAnchor;
            If ToWrite Then
              InsStr:=MoneyToString(DCLQuery.FieldByName(BookMarkName).AsCurrency, True, False)
            Else
              InsStr:=Trim(DCLQuery.FieldByName(BookMarkName).AsString);

            CursorPointer.GotoRange(BookMark.GetStart, False);
            If FontStyleRec.italic=1 Then
              CursorPointer.setPropertyValue('CharPosture', Ord(fsItalic));
            If FontStyleRec.Bold=1 Then
              CursorPointer.setPropertyValue('CharWeight', Ord(fsBold));
            If FontStyleRec.StrikeThrough=1 Then
              CursorPointer.setPropertyValue('CharStrikeout', Ord(fsStrikeout));
            If FontStyleRec.Undeline=1 Then
              CursorPointer.setPropertyValue('CharUnderline', Ord(fsUnderLine));
            If FontSize<>0 Then
              CursorPointer.setPropertyValue('CharHeight', FontSize);

            CursorPointer.setString(InsStr);
          end;
        Except
          OOSetVisible(Document, True);
          ShowErrorMessage( - 5005, '');
        end;
        //break;
      end;

      If ToPDF Then
        OOExportToFormat(Document, AddToFileName(OutFileName, '_'+IntToStr(DocNum)), 'pdf');

      If ToHTML Then
        OOExportToFormat(Document, AddToFileName(OutFileName, '_'+IntToStr(DocNum)), 'html');

      OOSetVisible(Document, True);
      If Save Then
      begin
        ForceDirectories(ExtractFilePath(OutFileName));
        Case OfficeDocumentFormat of
        odfMSO97:
        begin
          FileName:=FakeFileExt(OutFileName, 'doc');
          VariantArray[0]:=MakePropertyValue(OO, 'FilterName', 'MS Word 97');
        end;
        odfMSO2007:
        begin
          FileName:=FakeFileExt(OutFileName, 'docx');
          VariantArray[0]:=MakePropertyValue(OO, 'FilterName', 'MS Word 2007');
        end;
        odfOO, odfPossible:
        begin
          FileName:=FakeFileExt(OutFileName, 'odt');
          VariantArray[0]:=MakePropertyValue(OO, 'FilterName', 'writer8');
        end;
        end;

        VariantArray[1]:=MakePropertyValue(OO, 'Overwrite', True);

        Document.StoreToURL(FileNameToURL(AddToFileName(FileName, '_'+IntToStr(DocNum))),
          VariantArray);
      end;

      If Close then
      Begin
        Document.Close(True);
        Document:=Unassigned;
      End;

      If ToPDF Then
        OpenFile(FakeFileExt(AddToFileName(OutFileName, '_'+IntToStr(DocNum)), 'pdf'));

      If ToHTML Then
        OpenFile(FakeFileExt(AddToFileName(OutFileName, '_'+IntToStr(DocNum)), 'html'));

      inc(DocNum);
      DCLQuery.Next;
    end;
    DCLQuery.Close;

    FreeAndNil(Layot);
  end
  Else
    ShowErrorMessage( - 5006, FileName);
end;

end.

