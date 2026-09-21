unit uDCLTextReport;
{$mode Delphi}

interface

uses
  Classes, SysUtils, Controls, Forms, ComCtrls, StdCtrls, Buttons, ExtCtrls,
  DBCtrls, DB, Generics.Collections, LazUTF8, LazFileUtils,
  uDCLDBAwareTypes, uDCLConst, uIDCLMain, uDCLData, uDCLDBConnector, uIDCLGrid,
  uDCLTypes, uDCLVariables, uVariableNamespace;

type

  { TDCLTextReport }

  TDCLTextReport=class
  private
    FDCLMain: IDCLMain;
    FNameSpace: TVariableNamespace;
    FDBConnector: TDCLDBConnector;
    FDialogRes: TModalResult;
    FDCLGrid: IDCLGrid;
    FScrypt: TStringList;
    FParamsSetID: Integer;
    FMode: TNewQueryMode;
    FSaved: Boolean;
    FVariables: TVariables;
    GlobalSQL, Template, RepParams, HeadLine, Body, Report, Futer, InitSkrypts,
      EndSkrypts: TStringList;
    FReportQuery: TDCLDialogQuery;
    FVarsToControls: TList<String>;

    procedure GrabValListOnChange(Sender: TObject);
    procedure GrabValOnEdit(Sender: TObject);
    procedure ValComboOnChange(Sender: TObject);
    procedure GrabDateOnChange(Sender: TObject);

    procedure RePlaseVariables(var VarsSet: String);
    procedure ReplaseRepParams(var ReplaseText: TStringList);
    function TranslateRepParams(ParamName: String): String;
  public
    constructor Create(const NameSpace: TVariableNamespace; DCLMain: IDCLMain;
      DCLGrid: IDCLGrid; Scrypt: TStringList; ParamsSetID: Integer);

    procedure InitReport(Mode: TNewQueryMode);

    procedure PrintReport;

    procedure OpenReport(FileName: String; ViewMode: TReportViewMode);
    function SaveReport(FileName: String): String;
    procedure CloseReport(FileName: String);
  end;

implementation

uses
  uDCLMultiLang, uDCLDBStructure, uStringParams, uStringUtils,
  uDCLMeasurements, uDCLQueryUtils, uDCLGlobalVariables, uDCLValuesParser,
  uDCLException, uConvertEx;

const
  EditTopStep=23;

Function PosEx(const SubStr, S: String): Cardinal;
begin
  Result:=UTF8Pos(UTF8LowerString(SubStr), UTF8LowerString(S));
end;

function UTF8CharAt(S: String; Index: Integer): String;
begin
  Result:=UTF8Copy(S, Index, 1);
end;

{ TDCLTextReport }

procedure DeleteInString(var S: String; Index, Count: LongInt);
var
  T, t1: LongInt;
begin
  T:=Index;
  t1:=T;
  While (UTF8CharAt(S, T)<>#10)and(T<=UTF8Length(S))and(T-t1<=Count-1) do
  begin
    inc(T);
  end;
  UTF8Delete(S, Index, T-t1);
end;

procedure FillCopy(Source: String; var Dest: String; Start, FillLength, ReplaceLen: Cardinal;
  Align: String);
var
  T, t1: Cardinal;
  tmpL: String;
begin
  tmpL:=Source;
  t1:=UTF8Length(Source);
  If PosEx('I', Align)<>0 Then
    DeleteInString(Dest, Start, FillLength)
  else
  begin
    DeleteInString(Dest, Start, ReplaceLen);
    If PosEx('L', Align)<>0 Then
      If FillLength>t1 Then
        For T:=UTF8Length(tmpL)+1 to FillLength do
          tmpL:=tmpL+' ';
    If PosEx('R', Align)<>0 Then
      If FillLength>t1 Then
        For T:=UTF8Length(tmpL)+1 to FillLength do
          tmpL:=' '+tmpL;
    If PosEx('M', Align)<>0 Then
    begin
      If FillLength>t1 Then
      begin
        For T:=1 to (FillLength div 2)-(t1 div 2) do
          tmpL:=' '+tmpL;
        For T:=(FillLength div 2)-(t1 div 2)+t1+1 to FillLength do
          tmpL:=tmpL+' ';
      end;
    end;
  end;

  UTF8Insert(UTF8Copy(tmpL, 1, FillLength), Dest, Start);
end;

procedure TDCLTextReport.GrabValListOnChange(Sender: TObject);
begin
  If FVarsToControls.Count>(Sender as TComboBox).Tag Then
    FVariables.Variables[FNamespace.CurrentNamespace, FVarsToControls[(Sender as TComboBox).Tag]]:=
      (Sender as TComboBox).Text;
end;

procedure TDCLTextReport.GrabValOnEdit(Sender: TObject);
begin
  If FVarsToControls.Count>(Sender as TEdit).Tag Then
    FVariables.Variables[FNamespace.CurrentNamespace, FVarsToControls[(Sender as TEdit).Tag]]:=(Sender as TEdit).Text;
end;

procedure TDCLTextReport.ValComboOnChange(Sender: TObject);
var
  Val: String;
begin
  If FVarsToControls.Count>(Sender as TDBLookupComboBox).Tag Then
  begin
    If (Sender as TDBLookupComboBox).KeyValue=Unassigned Then  // null
      Val:=''
    Else
      Val:=(Sender as TDBLookupComboBox).KeyValue;

    FVariables.Variables[FNamespace.CurrentNamespace, FVarsToControls[(Sender as TDBLookupComboBox).Tag]]:=Val;
  end;
end;

procedure TDCLTextReport.GrabDateOnChange(Sender: TObject);
begin
  If FVarsToControls.Count>(Sender as TDateTimePicker).Tag Then
    FVariables.Variables[FNamespace.CurrentNamespace, FVarsToControls[(Sender as TDateTimePicker).Tag]]:=
      DateToStr((Sender as TDateTimePicker).Date);
end;

procedure TDCLTextReport.RePlaseVariables(var VarsSet: String);
var
  Parser: TDCLValuseParser;
begin
  Parser:=TDCLValuseParser.Create(FNameSpace.CurrentNamespace, ulUndefined, FVariables);
  Parser.TranslateVals(VarsSet, nil, False);
end;

procedure TDCLTextReport.ReplaseRepParams(var ReplaseText: TStringList);
var
  ParamValue, TmpStr, BodyText: String;
  InsMode:Boolean;
  ParamFill, ParamLen, CuteLen, k, k1, k3, DopLength, StringsCounter, StringNum, StartSel: Integer;
begin
  BodyText:=ReplaseText.Text;
  RePlaseVariables(BodyText);
  StringNum:=0;
  If (RepParams.Count div 2)>0 Then
  begin
    For StringsCounter:=0 to (RepParams.Count div 2)-1 do
    begin
      InsMode:=False;
      StartSel:=PosEx(RepParams[StringNum], BodyText);
      While StartSel<>0 do
      begin
        If StartSel<>0 Then
          ParamValue:=TranslateRepParams(RepParams[StringNum]);

        k:=StartSel+UTF8Length(RepParams[StringNum]);
        k1:=k;
        ParamFill:=0;
        DopLength:=0;
        If BodyText<>'' Then
          If UTF8CharAt(BodyText, k)='(' Then
          begin
            While UTF8CharAt(BodyText, k)<>')' do
              inc(k);
            TmpStr:=UTF8Copy(BodyText, k1+1, k-k1-1);
            ParamFill:=StrToIntEx(TmpStr);
            ParamLen:=ParamFill;
            DopLength:=k-k1+1;
          end
          else
            ParamLen:=UTF8Length(ParamValue);

        If StartSel<>0 Then
          If ParamFill=0 Then
            ParamFill:=UTF8Length(ParamValue);
        If ParamFill>UTF8Length(ParamValue) then
        Begin
          ParamFill:=ParamFill-UTF8Length(ParamValue);
        End;

        If PosEx('i', TmpStr)<>0 Then
        begin
          InsMode:=True;
          UTF8Delete(BodyText, StartSel, UTF8Length(RepParams[StringNum])+DopLength);
          CuteLen:=UTF8Length(RepParams[StringNum])+DopLength;
        end
        Else
        begin
          If PosEx('r', TmpStr)<>0 Then
          begin
            If ParamFill>0 Then
              For k:=1 to ParamFill do
                ParamValue:=' '+ParamValue;
          end
          Else If PosEx('m', TmpStr)<>0 Then
          begin
            If ParamFill>0 Then
            begin
              k3:=UTF8Length(ParamValue);
              For k:=1 to (ParamFill div 2)-(k3 div 2) do
                ParamValue:=' '+ParamValue;
              For k:=(ParamFill div 2)-(k3 div 2)+k3+1 to ParamFill do
                ParamValue:=ParamValue+' ';
            end;
          end
          Else
          begin
            If ParamFill>0 Then
              For k:=1 to ParamFill do
                ParamValue:=ParamValue+' ';
          end;
          UTF8Delete(BodyText, StartSel, UTF8Length(RepParams[StringNum])+DopLength);
        end;

        If not InsMode then
          UTF8Insert(UTF8Copy(ParamValue, 1, ParamLen), BodyText, StartSel)
        Else
        Begin
          If CuteLen>=ParamFill then
          Begin
            For k:=1 to CuteLen-ParamFill do
              ParamValue:=ParamValue+' ';
            UTF8Insert(ParamValue, BodyText, StartSel);
          End
          Else
          Begin
            DeleteInString(BodyText, StartSel, ParamFill-CuteLen);
            UTF8Insert(ParamValue, BodyText, StartSel);
          End;
        End;
        StartSel:=PosEx(RepParams[StringNum], BodyText);
      end;

      Inc(StringNum, 2);
    end;
  end;

  ReplaseText.Text:=BodyText;
end;

function TDCLTextReport.TranslateRepParams(ParamName: String): String;
var
  ParamNum: Integer;
  ResultString, ReturnField, tmpSQL1: String;
  ParamsQuery: TDCLSimplyQuery;
  F: TField;
begin
  ParamNum:=0;
  While (UpperCase(RepParams[ParamNum])<>UpperCase(Trim(ParamName)))and
    (ParamNum+1<>RepParams.Count) do
    inc(ParamNum);
  If FindParam('SQL=', RepParams[ParamNum+1])<>'' Then
  begin
    ParamsQuery:=TDCLSimplyQuery.Create(nil);
    FDBConnector.SetConnector(ParamsQuery);
    tmpSQL1:=FindParam('SQL=', RepParams[ParamNum+1]);
    RePlaseVariables(tmpSQL1);
    ParamsQuery.SQL.Text:=tmpSQL1;
    try
      ParamsQuery.Open;
      {If GPT.DebugOn Then
        DebugProc('Report param SQL query: '+tmpSQL1);}
    Except
      on E: Exception do
      begin
        raise TDCLException.Create( - 1109, E.Message);
      end;
    end;

    ReturnField:=FindParam('ReturnField=', RepParams[ParamNum+1]);
    DeleteNonPrintSimb(ReturnField);
    ResultString:='';
    If ReturnField='' Then
    begin
      While Not ParamsQuery.Eof do
      begin
        tmpSQL1:='';
        For F in ParamsQuery.Fields do
        begin
          tmpSQL1:=tmpSQL1+TrimRight(F.AsString);
        end;

        ResultString:=ResultString+tmpSQL1+LineEnding;
        ParamsQuery.Next;
      end;
    end
    Else
    begin
      While Not ParamsQuery.Eof do
      begin
        ResultString:=ResultString+TrimRight(ParamsQuery.FieldByName(ReturnField).AsString)+LineEnding;
        ParamsQuery.Next;
      end;
    end;

    ResultString:=UTF8Copy(ResultString, 1, UTF8Length(ResultString)-1);
    RePlaseVariables(ResultString);

    ParamsQuery.Close;
    FreeAndNil(ParamsQuery);
  end
  Else
  begin
    ResultString:=FindParam('ReturnValue=', RepParams[ParamNum+1]);
    DeleteNonPrintSimb(ResultString);
    RePlaseVariables(ResultString);
  end;
  Result:=ResultString;
end;

constructor TDCLTextReport.Create(const NameSpace: TVariableNamespace; DCLMain: IDCLMain;
      DCLGrid: IDCLGrid; Scrypt: TStringList; ParamsSetID: Integer);
begin
  FNameSpace:=NameSpace;
  FDCLMain:=DCLMain;
  FDBConnector:=DCLMain.GetDBConnector;
  FDCLGrid:=DCLGrid;
  FScrypt:=Scrypt;
  FParamsSetID:=ParamsSetID;
  FVariables:=DCLMain.Variables;
  FVarsToControls:=TList<String>.Create;
end;

procedure TDCLTextReport.InitReport(Mode: TNewQueryMode);
var
  RepParamsSet: TDCLDialogQuery;
  NewNew, GrabFormYes: Boolean;
  GrabValueEdit: TEdit;
  GrabDBLookupCombo: TDBLookupComboBox;
  GrabQuery: TDCLDialogQuery;
  GrabValueList: TComboBox;
  GrabDS: TDataSource;
  BtOk, BtCancel: TButton;
  ParamsCountList, ElementsTop: Word;
  GrabLabel: TDialogLabel;
  GrabDate: TDateTimePicker;
  LocalVar1, LocalVar2, RecCount: Word;
  tmpSQL, tmpSQL1: String;
  GrabValueForm: TForm;

  procedure CreateGrabForm;
  begin
    If Not GrabFormYes Then
    begin
      GrabFormYes:=True;
      FDialogRes:=mrCancel;
      GrabValueForm:=TForm.Create(nil);
      GrabValueForm.Position:=poScreenCenter;
      GrabValueForm.BorderStyle:=bsSingle;
      GrabValueForm.BorderIcons:=[biSystemMenu, biMinimize];
      GrabValueForm.Caption:=GetDCLMessageString(msInputVulues);
    end;
  end;

begin
  FSaved:=True;
  Body:=TStringList.Create;
  Report:=TStringList.Create;
  RepParams:=TStringList.Create;
  HeadLine:=TStringList.Create;
  Futer:=TStringList.Create;
  Template:=TStringList.Create;
  GlobalSQL:=TStringList.Create;
  InitSkrypts:=TStringList.Create;
  EndSkrypts:=TStringList.Create;

  FMode:=Mode;
  FDialogRes:=mrOk;
  GrabFormYes:=False;

  InitSkrypts:=CopyStringsBlock('[INIT REP]', '[END INIT]', FScrypt);
  GlobalSQL:=CopyStringsBlock('[GLOBALQUERY]', '[END GLOBALQUERY]', FScrypt);
  RepParams:=CopyStringsBlock('[PARAMS]', '[END PARAMS]', FScrypt);
  HeadLine:=CopyStringsBlock('[HEADLINE]', '[END HEADLINE]', FScrypt);
  Template:=CopyStringsBlock('[BODY]', '[END BODY]', FScrypt);
  Futer:=CopyStringsBlock('[FUTER]', '[END FUTER]', FScrypt);
  EndSkrypts:=CopyStringsBlock('[CLOSE REP]', '[END CLOSE]', FScrypt);

  // ParamsSet
  If FParamsSetID<>0 Then
  begin
    RepParamsSet:=TDCLDialogQuery.Create(nil);
    FDBConnector.SetConnector(RepParamsSet);
    RepParamsSet.SQL.Text:=GetRolesQueryText(' s.'+ParentField+'='+
        IntToStr(FParamsSetID), GPT.UserID);
    RepParamsSet.Open;
    RecCount:=RepParamsSet.Fields[0].AsInteger;
    If RecCount>0 Then
    begin
      RepParamsSet.Close;
      RepParamsSet.SQL.Text:=GetRolesQueryText(' s.'+ParentField+'='+
          IntToStr(FParamsSetID), GPT.UserID);
      RepParamsSet.Open;

      While Not RepParamsSet.Eof do
      begin
        RepParams.Append(Trim(RepParamsSet.FieldByName(DCLNameField).AsString));
        RepParams.Append(Trim(RepParamsSet.FieldByName(ScriptField).AsString));
        RepParamsSet.Next;
      end;
    end;
    RepParamsSet.Close;
    FreeAndNil(RepParamsSet);
  end;

  ElementsTop:=BeginStepTop;
  If InitSkrypts.Count>0 Then
    For LocalVar1:=0 to InitSkrypts.Count-1 do
    begin
      If PosEx('DeclareVariable=', InitSkrypts[LocalVar1])<>0 Then
      begin
        FVariables.NewVariableWithTest(FNamespace, FindParam('DeclareVariable=', InitSkrypts[LocalVar1]));
      end;

      If PosEx('GrabValueList=', InitSkrypts[LocalVar1])<>0 Then
      begin
        CreateGrabForm;
        GrabLabel:=TLabel.Create(GrabValueForm);
        GrabLabel.Parent:=GrabValueForm;
        GrabLabel.Name:='GrabLabel_'+IntToStr(LocalVar1);
        GrabLabel.Top:=ElementsTop-14;
        GrabLabel.Left:=8;
        tmpSQL:=FindParam('Label=', InitSkrypts[LocalVar1]);
        If tmpSQL<>'' Then
          GrabLabel.Caption:=tmpSQL
        Else
          GrabLabel.Caption:=FindParam('GrabValueList=', InitSkrypts[LocalVar1]);

        tmpSQL:=FindParam('GrabValueList=', InitSkrypts[LocalVar1]);
        FVariables.NewVariableWithTest(FNamespace, tmpSQL);
        GrabValueList:=TComboBox.Create(GrabValueForm);
        GrabValueList.Parent:=GrabValueForm;
        GrabValueList.Name:='GrabValList_'+IntToStr(LocalVar1);
        GrabValueList.Text:='';
        GrabValueList.Tag:=FVarsToControls.Add(tmpSQL);

        tmpSQL:=FindParam('ListValues=', InitSkrypts[LocalVar1]);
        ParamsCountList:=ParamsCount(tmpSQL);
        For LocalVar2:=1 to ParamsCountList do
          GrabValueList.Items.Append(GetParam(tmpSQL, LocalVar2));

        GrabValueList.Top:=ElementsTop;
        GrabValueList.Left:=8;
        GrabValueList.Width:=GrabComponentsWidth;
        GrabValueList.OnChange:=GrabValListOnChange;
        tmpSQL:=Trim(FindParam('DefaultValue=', InitSkrypts[LocalVar1]));
        If tmpSQL<>'' Then
          GrabValueList.Text:=tmpSQL;
        inc(ElementsTop, EditTopStep);
      end;

      If PosEx('GrabValue=', InitSkrypts[LocalVar1])<>0 Then
      begin
        CreateGrabForm;
        GrabLabel:=TDialogLabel.Create(GrabValueForm);
        GrabLabel.Parent:=GrabValueForm;
        GrabLabel.Name:='GrabLabel_'+IntToStr(LocalVar1);
        GrabLabel.Top:=ElementsTop-14;
        GrabLabel.Left:=8;
        tmpSQL:=FindParam('Label=', InitSkrypts[LocalVar1]);
        If tmpSQL<>'' Then
          GrabLabel.Caption:=tmpSQL
        Else
          GrabLabel.Caption:=FindParam('GrabValue=', InitSkrypts[LocalVar1]);

        tmpSQL:=FindParam('GrabValue=', InitSkrypts[LocalVar1]);
        GrabValueEdit:=TEdit.Create(GrabValueForm);
        GrabValueEdit.Parent:=GrabValueForm;
        GrabValueEdit.Name:='GrabValEdit'+IntToStr(LocalVar1);
        GrabValueEdit.Text:='';
        GrabValueEdit.Tag:=FVarsToControls.Add(tmpSQL);
        GrabValueEdit.OnChange:=GrabValOnEdit;
        tmpSQL:=Trim(FindParam('Long=', InitSkrypts[LocalVar1]));
        If tmpSQL<>'' Then
          GrabValueEdit.MaxLength:=StrToIntEx(tmpSQL);

        tmpSQL:=Trim(FindParam('DefaultValue=', InitSkrypts[LocalVar1]));
        If tmpSQL<>'' Then
          GrabValueEdit.Text:=tmpSQL;

        GrabValueEdit.Top:=ElementsTop;
        GrabValueEdit.Left:=8;
        GrabValueEdit.Width:=GrabComponentsWidth;

        Inc(ElementsTop, EditTopStep);
      end;

      If PosEx('GrabValueFromBase=', InitSkrypts[LocalVar1])<>0 Then
      begin
        CreateGrabForm;
        GrabLabel:=TDialogLabel.Create(GrabValueForm);
        GrabLabel.Parent:=GrabValueForm;
        GrabLabel.Name:='GrabLabel_'+IntToStr(LocalVar1);
        GrabLabel.Left:=8;
        GrabLabel.Top:=ElementsTop-14;
        tmpSQL:=FindParam('Label=', InitSkrypts[LocalVar1]);
        If tmpSQL<>'' Then
          GrabLabel.Caption:=tmpSQL
        Else
          GrabLabel.Caption:=FindParam('GrabValueFromBase=', InitSkrypts[LocalVar1]);

        tmpSQL:=FindParam('GrabValCombo=', InitSkrypts[LocalVar1]);
        GrabDBLookupCombo:=TDBLookupComboBox.Create(GrabValueForm);
        GrabDBLookupCombo.Parent:=GrabValueForm;
        GrabDBLookupCombo.Name:='GrabValCombo'+IntToStr(LocalVar1);
        GrabDBLookupCombo.Top:=ElementsTop;
        GrabDBLookupCombo.Left:=8;
        GrabDBLookupCombo.Width:=GrabComponentsWidth;
        GrabDBLookupCombo.Tag:=FVarsToControls.Add(tmpSQL);

        GrabQuery:=TDCLDialogQuery.Create(nil);
        tmpSQL1:=FindParam('SQL=', InitSkrypts[LocalVar1]);
        GrabQuery.SQL.Text:=tmpSQL1;
        FDBConnector.SetConnector(GrabQuery);
        try
          GrabQuery.Open;
          GrabQuery.Last;
          GrabQuery.First;
          GrabDS:=TDataSource.Create(nil);
          GrabDS.DataSet:=GrabQuery;
          GrabDBLookupCombo.ListSource:=GrabDS;
          GrabDBLookupCombo.ListField:=GrabQuery.Fields[0].FieldName;
          If GrabQuery.FieldCount=1 Then
            GrabDBLookupCombo.KeyField:=GrabQuery.Fields[0].FieldName
          Else
            GrabDBLookupCombo.KeyField:=GrabQuery.Fields[1].FieldName;

{$IFDEF FPC}
          GrabDBLookupCombo.OnSelect:=ValComboOnChange;
{$ELSE}
          GrabDBLookupCombo.OnClick:=ValComboOnChange;
{$ENDIF}
        Except
          on E: Exception do
          begin
            raise TDCLException.Create( - 1108, E.Message);
          end;
        end;

        inc(ElementsTop, EditTopStep);
      end;

      If PosEx('GrabDate=', InitSkrypts[LocalVar1])<>0 Then
      begin
        CreateGrabForm;
        GrabLabel:=TDialogLabel.Create(GrabValueForm);
        GrabLabel.Parent:=GrabValueForm;
        GrabLabel.Name:='GrabLabel_'+IntToStr(LocalVar1);
        GrabLabel.Left:=8;
        GrabLabel.Top:=ElementsTop-14;
        tmpSQL:=FindParam('Label=', InitSkrypts[LocalVar1]);
        If tmpSQL<>'' Then
          GrabLabel.Caption:=tmpSQL
        Else
          GrabLabel.Caption:=FindParam('GrabDate=', InitSkrypts[LocalVar1]);

        tmpSQL:=FindParam('GrabDate=', InitSkrypts[LocalVar1]);
        GrabDate:=TDateTimePicker.Create(GrabValueForm);
        GrabDate.Parent:=GrabValueForm;
        GrabDate.Name:='GrabDate'+IntToStr(LocalVar1);
        GrabDate.Date:=Date;
        GrabDate.Top:=ElementsTop;
        GrabDate.Left:=8;
        GrabDate.Width:=GrabComponentsWidth;
        GrabDate.Tag:=FVarsToControls.Add(tmpSQL);
        FVariables.NewVariable(FNamespace, FindParam('GrabDate=', InitSkrypts[LocalVar1]),
          DateToStr(GrabDate.Date));

        tmpSQL:=Trim(FindParam('DefaultValue=', InitSkrypts[LocalVar1]));
        If tmpSQL<>'' Then
          GrabDate.Date:=StrToDate(tmpSQL);

        GrabDate.OnChange:=GrabDateOnChange;
        inc(ElementsTop, EditTopStep);
      end;
    end;

  If GrabFormYes Then
  begin
    GrabValueForm.ClientHeight:=ElementsTop+BeginStepTop+50;
    BtOk:=TButton.Create(GrabValueForm);
    BtOk.Parent:=GrabValueForm;
    BtOk.Tag:=0;
    BtOk.Caption:='OK';
    BtOk.Default:=True;
    BtOk.ModalResult:=mrOk;

    BtCancel:=TButton.Create(GrabValueForm);
    BtCancel.Parent:=GrabValueForm;
    BtCancel.Tag:=1;
    BtCancel.Caption:='Cancel';
    BtCancel.Cancel:=True;
    BtCancel.ModalResult:=mrCancel;

    BtOk.Top:=GrabValueForm.ClientHeight-35;
    BtCancel.Top:=GrabValueForm.ClientHeight-35;
    BtOk.Left:=10;
    BtCancel.Left:=95;
    GrabValueForm.ShowModal;
  end;

  If GrabFormYes Then
  begin
    GrabValueForm.Release;
    GrabValueForm:=nil;
  end;

  If FDialogRes=mrCancel Then
    Exit;

  GrabFormYes:=False;

  NewNew:=False;
  If FMode=nqmNew Then
  begin
    NewNew:=True
  end
  Else
    NewNew:=Not Assigned(FDCLGrid);

  If NewNew Then
  begin
    FReportQuery:=TDCLSimplyQuery.Create(nil);
    FDBConnector.SetConnector(FReportQuery);
  end
  else
    FReportQuery:=FDCLGrid.Query;

  If NewNew and (GlobalSQL.Count>0) Then
  begin
    tmpSQL:=GlobalSQL.Text;
    FReportQuery.Close;
    FReportQuery.SQL.Text:=tmpSQL;

    Screen.Cursor:=crSQLWait;
    try
      FReportQuery.Open;
      {If GPT.DebugOn Then
        DebugProc('Report SQL query: '+tmpSQL);}
    Except
      on E: Exception do
      begin
        raise TDCLException.Create( - 1106, E.Message);
      end;
    end;
    Screen.Cursor:=crDefault;
  end;
end;

procedure TDCLTextReport.PrintReport;
var
  Value, BodyText, LastField: String;
  StartPos, LengthParam: Cardinal;
  StartSel, DelLen: Integer;
  Parser: TDCLValuseParser;
  Alig: String;
  Field, Field2: TField;
begin
  If FDialogRes=mrCancel Then
    Exit;
  FSaved:=False;
  BodyText:=Template.Text;

  If Not FReportQuery.IsEmpty Then
  begin
    For Field in FReportQuery.Fields do
    begin
      StartSel:=PosEx(ParamPrefix+Field.FieldName, BodyText);
      While StartSel<>0 do
      begin
        Alig:='L';
        If StartSel<>0 Then
        begin
          LengthParam:=0;
          LastField:='';
          for Field2 in FReportQuery.Fields do
          begin
            if (LengthParam<UTF8Length(Field2.FieldName)) and (PosEx(ParamPrefix+Field2.FieldName, BodyText)<>0) then
            begin
              StartSel:=PosEx(ParamPrefix+Field2.FieldName, BodyText);
              LastField:=Field2.FieldName;
              LengthParam:=UTF8Length(Field2.FieldName);
            end;
          end;

          Value:=TrimRight(FReportQuery.FieldByName(LastField).AsString);

          If UTF8CharAt(BodyText, StartSel+LengthParam+1)='(' Then
          begin
            StartPos:=StartSel+LengthParam+1;
            While UTF8CharAt(BodyText, StartPos)<>')' do
              inc(StartPos);
            Alig:=UTF8Copy(BodyText, StartSel+LengthParam+2, StartPos-(StartSel+LengthParam+2));
            LengthParam:=StrToIntEx(Alig);
            If PosEx('R', Alig)=0 Then
              If PosEx('M', Alig)=0 Then
                If PosEx('L', Alig)=0 Then
                  If PosEx('I', Alig)=0 Then
                    Alig:='L';

            DelLen:=StartPos-StartSel+1;

            If LengthParam=0 Then
              LengthParam:=UTF8Length(Value);
          end
          Else
          begin
            DelLen:=LengthParam+UTF8Length(ParamPrefix);
            LengthParam:=UTF8Length(Value);
          end;

          FillCopy(Value, BodyText, StartSel, LengthParam, DelLen, Alig);

          StartSel:=PosEx(ParamPrefix+Field.FieldName, BodyText);
        end;
      end;
    end;
    BodyText:=UTF8Copy(BodyText, 1, UTF8Length(BodyText)-UTF8Length(LineEnding));
  end
  Else
    BodyText:='';

  Parser:=TDCLValuseParser.Create(FNameSpace.CurrentNamespace, ulUndefined, FVariables);
  Parser.RePlaceProc(BodyText, nil);
  Body.Append(BodyText);
end;

procedure TDCLTextReport.OpenReport(FileName: String; ViewMode: TReportViewMode);
// 0-Normal 1 Record;  1-All Records;  2-Bookmarks; 3-All records (Num)
var
  BookMark: TBookmark;
  Nubers: Integer;
begin
  If FDialogRes=mrCancel Then
    Exit;
  If Not FReportQuery.IsEmpty Then
  begin
    Case ViewMode of
    rvmOneRecord:
    PrintReport;
    rvmAllDS:
    begin
      FReportQuery.First;
      While Not FReportQuery.Eof do
      begin
        PrintReport;
        FReportQuery.Next;
      end;
    end;
    rvmGrid:
    begin
      If Assigned(FDCLGrid) and (FDCLGrid.Style in TDataGrid) and
        Assigned(FDCLGrid.SelectedRows) and
        (FDCLGrid.SelectedRows.Count>0) Then
      begin
        For BookMark in FDCLGrid.SelectedRows do
        begin
          FReportQuery.GoToBookmark(BookMark);
          PrintReport;
        end;
      end
      Else
        PrintReport;
    end;
    rvmMultitRecordReport:
    begin
      If FileName='' Then
        FileName:='Report';
      FReportQuery.First;
      Nubers:=1;
      While Not FReportQuery.Eof do
      begin
        PrintReport;
        SaveReport(FileName+'-'+IntToStr(Nubers)+'.txt');
        inc(Nubers);
        FReportQuery.Next;
      end;
    end;
    rvmBookmarcks:
    begin
      If Assigned(FDCLGrid) and (FDCLGrid.Style in TDataGrid) and
        Assigned(FDCLGrid.SelectedRows) and
        (FDCLGrid.SelectedRows.Count>0) Then
      begin
        Nubers:=1;
        For BookMark in FDCLGrid.SelectedRows do
        begin
          FReportQuery.GoToBookmark(BookMark);
          PrintReport;
          SaveReport(FileName+'-'+IntToStr(Nubers)+'.txt');
          inc(Nubers);
        end;
      end;
    end;
    end;
  end
  Else
    PrintReport;

  ReplaseRepParams(HeadLine);
  ReplaseRepParams(Futer);
end;

function TDCLTextReport.SaveReport(FileName: String): String;
var
  i: Integer;
begin
  If FDialogRes=mrCancel Then
    Exit;

  Report.AddStrings(HeadLine);
  Report.AddStrings(Body);
  Report.AddStrings(Futer);

  If FileName='' Then
    FileName:='Report.txt';
  If Not FilenameIsAbsolute(FileName) Then
    FileName:=IncludeTrailingPathDelimiter(GPT.AppConfigDir)+FileName;

  RePlaseVariables(FileName);

  i:=UTF8Length(FileName);
  While i<>0 do
  begin
    If (FileName[i]='"')or(FileName[i]=CrossDelim)or(FileName[i]='*')or(FileName[i]='?')or
      (FileName[i]='>')or(FileName[i]='<') Then
      UTF8Delete(FileName, i, 1);
    Dec(i);
  end;

  Report.SaveToFile(FileName, TEncoding.UTF8);
  Result:=FileName;
  FSaved:=True;

  Body.Clear;
  Report.Clear;
end;

procedure TDCLTextReport.CloseReport(FileName: String);
var
  S: String;
begin
  If EndSkrypts.Count>0 Then
    For S in EndSkrypts do
    begin
      If PosEx('DisposeVariable=', S)<>0 Then
        FVariables.FreeVariable(FNamespace.CurrentNamespace, FindParam('DisposeVariable=', S));
    end;

  If Not FSaved Then
    SaveReport(FileName);

  FreeAndNil(Body);
  FreeAndNil(Report);
  FreeAndNil(RepParams);
  FreeAndNil(HeadLine);
  FreeAndNil(Futer);
  FreeAndNil(Template);
  FreeAndNil(GlobalSQL);
  FreeAndNil(EndSkrypts);
  FreeAndNil(InitSkrypts);
end;

end.
