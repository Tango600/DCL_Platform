unit uDCLCommand;
{$I DefineType.pas}

interface

uses
  Classes, SysUtils, Generics.Collections, Forms, Controls, StdCtrls, DB, Dialogs,
  uDCLData, uDCLTypes, uDCLConst, uDCLGrid, uDCLForm, uDCLVariables, uIDCLMain,
  uDCLUtils, uStringParams, uDCLDBConnector, uDCLDBStructure, uDBUtils,
  uDCLValuesParser, uIGetValue;

type

  { TDCLCommand }

  TDCLCommand=class(TComponent, IGetValue)
  private
    FIDCLMain: IDCLMain;
    FDBConnector: TDCLDBConnector;
    FForms: TList<TForm>;
    FDCLForm: TDCLForm;
    FDCLGrid: TDCLGrid;
    FNameSpace: String;
    FVariables: TVariables;
    FParser: TDCLValuseParser;
    FUserLevelLocal: TUserLevelsType;

    procedure TranslateVals(var S: String); overload;
    procedure TranslateVals(var S: String; Query: TDCLDialogQuery); overload;
    procedure SetValue(S: String);

    procedure ExecSQLCommand(SQLCommand: String);

    function GetRaights: TUserLevelsType;
    procedure RunTextReport(ScrLine: String; Query: TDCLDialogQuery; Grid: TDCLGrid);

    procedure DialogCommand(ScrStr: String);
    function CreateForm(NameSpace, DialogName: String; NoContext: Boolean;
      ParentForm: TDCLForm; Grid: TDCLGrid;
      ReturnValueParams: TReturnValueParams; Modal: Boolean): TDCLForm;
  public
    constructor Create(IDCLMain: IDCLMain; NameSpace: String; DCLForm: TForm;
      DCLGrid: TDCLGrid); overload;

    procedure OpenDialog(DialogName: String);
    function RunCommandScript(CommandName: String): Boolean;
    procedure RunCommand(Command: String);
    procedure SelectRunType(Command: String);

    procedure About;

    procedure GetValueProc(ReturnValue: TReturnFormValue);
  end;

implementation

uses
{$IFDEF MSWINDOWS}
  uSheetOfficeReportSelector, uTextOfficeReportSelector,
{$ENDIF}
  fAbout, uDCLGlobalVariables, uDCLConfigTable, uDCLDataStorage,
  uRunProgram, uDCLMessages, uDCLMultiLang, uSQLUtils, uSystemUtils,
  {$IFDEF TRANSACTIONDB}
  uDCLDBTransaction,
  {$ENDIF}
  uDCLTextReport, uExpressionParser;

{ TDCLCommand }

procedure TDCLCommand.TranslateVals(var S: String);
var
  Factor: Integer;
begin
  FParser.SetConnector(FDBConnector);
  if Assigned(FDCLGrid) and Assigned(FDCLGrid.Query) then
  begin
    FParser.RePlaseParams(S, FDCLGrid.Query);
    FParser.RePlaseVariables(FNameSpace, S, FDCLGrid.Query);
    FParser.RePlaceProc(S, Factor, FDCLGrid.Query);
  end
  else
  begin
    FParser.RePlaseVariables(FNameSpace, S, nil);
    FParser.RePlaceProc(S, Factor, nil);
  end;
end;

procedure TDCLCommand.TranslateVals(var S: String; Query: TDCLDialogQuery);
var
  Factor: Integer;
begin
  FParser:=TDCLValuseParser.Create(FNameSpace, FVariables);
  FParser.RePlaseParams(S, Query);
  FParser.RePlaseVariables(FNameSpace, S, Query);
  FParser.RePlaceProc(S, Factor, Query);
end;

constructor TDCLCommand.Create(IDCLMain: IDCLMain; NameSpace: String;
  DCLForm: TForm; DCLGrid: TDCLGrid);
begin
  FIDCLMain:=IDCLMain;
  FDBConnector:=FIDCLMain.GetDBConnector;
  FForms:=FIDCLMain.GetForms;
  if Assigned(DCLForm) then
    FDCLForm:=(DCLForm as TDCLForm);
  FDCLGrid:=DCLGrid;
  FUserLevelLocal:=GPT.AccessLevel;
  if Assigned(DCLGrid) then
    FUserLevelLocal:=DCLGrid.RightsLevel;
  FNameSpace:=NameSpace;
  FVariables:=FIDCLMain.GetVariables;

  FParser:=TDCLValuseParser.Create(FNameSpace, FVariables);
end;

procedure TDCLCommand.OpenDialog(DialogName: String);
begin
  CreateForm(FNameSpace, DialogName, True, nil, nil, nil, False);
end;

function TDCLCommand.RunCommandScript(CommandName: String): Boolean;
var
  DCLQuery: TDCLDialogQuery;
  Empty: Boolean;
  Script: String;
  DCL: TStringList;
  LineNum: Integer;

  procedure Run(IfFlag, Skeep: Boolean);
  const
    WhiteSpace=[' ',#9,#10,#13];
  var
    IfResult, Flg, Skp: Boolean;
    posI, posI2: Integer;
    Line, IfCondition: String;
  begin
    Flg:=IfFlag;
    Skp:=Skeep;
    IfResult:=IfFlag;
    while DCL.Count>LineNum+1 do
    begin
      Inc(LineNum);
      Line:=DCL[LineNum];

      if Line='' then
        Continue;
      if Pos('//', TrimLeft(Line))=1 then
        Continue;

      if IsLexem('Else', Line) then
      begin
        if not Skp then
          IfResult:=not IfResult;
        Continue;
      end;

      if IsLexem('EndIf', Line) then
      begin
        Exit;
      end;

      if Assigned(FDCLGrid) and Assigned(FDCLGrid.Query) then
        TranslateVals(Line, FDCLGrid.Query)
      else
        TranslateVals(Line);

      if IsLexem('if ', Line) and (PosEx(' then', Line)>2) then
      begin
        if not Flg then
        begin
          Run(False, True);
          Continue;
        end;

        Line:=TrimLeft(Line);

        posI:=Pos('(', Line);
        posI2:=Pos(')', Line);

        if (posI=0) and (posI2=0) then
        begin
          posI:=1;
          While (posI<=Length(Line)) and not charinset(Line[posI], WhiteSpace) do
            Inc(posI);

          While (posI<=Length(Line)) and charinset(Line[posI], WhiteSpace) do
            Inc(posI);

          IfCondition:=Copy(Line, posI, Length(Line)-8).Trim
        end
        else
          IfCondition:=Copy(Line, posI+1, Pos(')', Line)-posI-1).Trim;

        IfResult:=ParseLogicalExpression(IfCondition);

        Run(IfResult, False);

        IfResult:=True;
        Continue;
      end;

      if (not IfResult) or Skp then
        Continue;

      if IsLexem('break;', Line) then
      begin
        LineNum:=DCL.Count;
        break;
      end;

      RunCommand(Line);
    end;
  end;

begin
  Result:=False;
  DCLQuery:=TDCLDialogQuery.Create(Self);
  FDBConnector.SetConnector(DCLQuery);

  DCLQuery.SQL.Text:='select * from '+DCLTable+' where lower('+DCLNameField+')=lower(:COMMAND)';
  DCLQuery.ParamByName('COMMAND').AsString:=CommandName;
  DCLQuery.Open;
  Empty:=DCLQuery.IsEmpty;
  Script:=DCLQuery.FieldByName(ScriptField).AsString;
  DCLQuery.Close;

  if not Empty then
  begin
    DCL:=TStringList.Create;
    DCL.Text:=Script;
    if DCL.Count>0 then
    begin
      LineNum:=-1;
      Run(True, False);
      Result:=True;
    end;
  end;
end;

procedure TDCLCommand.SetValue(S: String);
var
  tmp1, tmp2, VarName, SQLText, ReturnField, KeyField: String;
  sv_v2, v2: Integer;
  Grid, PartGrid: TDCLGrid;
  DCLQuery: TDCLDialogQuery;
  {$IFDEF TRANSACTIONDB}
  tmp_Transaction:TTransaction;
  {$ENDIF}
  Form: TForm;
  Edit: TDCLEdit;
begin
  tmp2:=FindParam('SetValue=', S);
  If (PosEx('ReturnQuery=', S)=0) and (PosEx('SQL=', S)=0) Then
  begin
    TranslateVals(tmp2);

    If Assigned(FDCLForm) Then
    begin
      KeyField:=Trim(FindParam('TablePart=', S));
      If KeyField<>'' Then
      begin
        v2:=StrToIntEx(KeyField)-1;
        If v2>=0 Then
        begin
          PartGrid:=FDCLForm.CurrentGrid.TableParts[v2];
          If Assigned(PartGrid) Then
            If PartGrid.Query.Active Then
              TranslateVals(tmp2, PartGrid.Query);
        end;
      end;
    end
    Else
      TranslateVals(tmp2);

    sv_v2:=Pos('=', tmp2)-1;
    If sv_v2<=0 Then
      sv_v2:=Length(tmp2);
    VarName:=Copy(LowerCase(tmp2), 1, sv_v2);
    If FVariables.Exists(FNameSpace, VarName) Then
      If Pos('=', tmp2)<>0 Then
      begin
        sv_v2:=Pos('=', tmp2)-1;
        Delete(tmp2, 1, sv_v2+1);

        KeyField:=Trim(FindParam('TablePart=', S));
        If KeyField<>'' Then
        begin
          v2:=StrToIntEx(KeyField)-1;
          If v2>=0 Then
          begin
            PartGrid:=FDCLForm.CurrentGrid.TableParts[v2];
            If Assigned(PartGrid) Then
              If PartGrid.Query.Active Then
                TranslateVals(tmp2, PartGrid.Query);
          end;
        end
        Else
          TranslateVals(tmp2);

        TranslateVals(tmp2);
        FVariables.Variables[FNameSpace, VarName]:=tmp2;
      end
      Else
        FVariables.Variables[FNameSpace, VarName]:='';
  end;

  If (PosEx('ReturnQuery=', S)<>0)or(PosEx('SQL=', S)<>0) Then
  begin
    SQLText:=FindParam('ReturnQuery=', S);
    If SQLText='' Then
      SQLText:=FindParam('SQL=', S);
    TranslateVals(SQLText);
    If SQLText<>'' Then
    begin
      DCLQuery:=TDCLDialogQuery.Create(Self);
      FDBConnector.SetConnector(DCLQuery);

      {$IFDEF TRANSACTIONDB}
      tmp_Transaction:=TDCLDBTransaction.Create(FDBConnector, trtWrite);
      DCLQuery.Transaction:=tmp_Transaction;
      tmp_Transaction.StartTransaction;
      {$ENDIF}

      DCLQuery.SQL.Text:=SQLText;
      Screen.Cursor:=crSQLWait;
      try
        DCLQuery.Open;
      Except
        Screen.Cursor:=crDefault;
        //ShowErrorMessage( - 1105, 'SQL='+SQLText);
      end;
      Screen.Cursor:=crDefault;

      ReturnField:=DCLQuery.Fields[0].FieldName;

      tmp2:=FindParam('SetValue=', S);
      sv_v2:=Pos('=', tmp2)-1;
      If sv_v2<=0 Then
        sv_v2:=Length(tmp2);
      tmp1:=Copy(LowerCase(tmp2), 1, sv_v2);

      tmp2:=TrimRight(DCLQuery.FieldByName(ReturnField).AsString);
      TranslateVals(tmp2);
      DCLQuery.Close;

      FVariables.NewVariable(FNamespace, tmp1, tmp2);

      {$IFDEF TRANSACTIONDB}
      tmp_Transaction.Commit;
      FreeAndNil(tmp_Transaction);
      {$ENDIF}
      FreeAndNil(DCLQuery);
    end;
  end;

  For Form in FForms do
  begin
    If Assigned(Form) Then
    begin
      For Grid in (Form as TDCLForm).Grids do
      begin
        If Assigned(Grid) Then
        begin
          If Assigned(Grid.Edits) Then
          begin
            For Edit in Grid.Edits do
            begin
              if FVariables.Exists(FNamespace, Edit.Variable) then
              begin
                Case Edit.EditType of
                fbtOutBox, fbtEditBox:
                (Edit.Control as TEdit).Text:=
                  FVariables.Variables[FNamespace, Edit.Variable];
                end;
              end;
            end;
          end;

          For PartGrid in Grid.TableParts do
          begin
            For Edit in PartGrid.Edits do
            begin
              if FVariables.Exists(FNamespace, Edit.Variable) then
              begin
                Case Edit.EditType of
                fbtOutBox, fbtEditBox:
                  (Edit.Control as TEdit).Text:=
                    FVariables.Variables[FNamespace, Edit.Variable];
                end;
              end;
            end;
          end;
        end;
      end;
    end;
  end;
end;

procedure TDCLCommand.ExecSQLCommand(SQLCommand: String);
var
  ADOCommand: TCommandQuery;
  {$IFDEF TRANSACTIONDB}
  tmp_Transaction:TTransaction;
  {$ENDIF}
begin
  If GetRaights>ulWrite then
  begin
    ADOCommand:=TCommandQuery.Create(Self);
    If GPT.DebugOn Then
    begin
      //DebugProc('ExecSQLCommand: '+SQLCommand);
      //DebugProc('-=EndSQL command=-');
      //DebugProc(SQLCommand);
      If GPT.DebugMesseges Then
        ShowMessage(SQLCommand);
    end;
    //If FDCLLogOn.SQLMon.TrraceStatus Then
      //FDCLLogOn.SQLMon.AddSQLText(SQLCommand);

    {$IFDEF ADO}
    ADOCommand.CommandType:=cmdText;
    ADOCommand.CommandText:=SQLCommand;
    ADOCommand.Connection:=FDBConnector;
    {$ELSE}
    ADOCommand.SQL.Text:=SQLCommand;
    FDBConnector.SetConnector(TDCLDialogQuery(ADOCommand));
    {$ENDIF}
    {$IFDEF TRANSACTIONDB}
    tmp_Transaction:=TDCLDBTransaction.Create(FDBConnector, trtWrite);
    ADOCommand.Transaction:=tmp_Transaction;
    tmp_Transaction.StartTransaction;
    {$ENDIF}

    try
      If not IsReturningQuery(SQLCommand) then
        {$IFDEF ADO}
        ADOCommand.Execute
        {$ELSE}
        ADOCommand.ExecSQL
        {$ENDIF}
      else
        {$IFDEF ADO}
        ADOCommand.Execute;
        {$ELSE}
        ADOCommand.Open;
        {$ENDIF}
    Except
      On ex: Exception do
        ShowErrorMessage( - 1110, 'SQL='+SQLCommand+' / '+ex.Message);
    end;
    {$IFDEF TRANSACTIONDB}
    tmp_Transaction.Commit;
    FreeAndNil(tmp_Transaction);
    {$ENDIF}

    FreeAndNil(ADOCommand);

    if Assigned(FDCLForm) then
      FormsNotifier.NotifyForm(FDCLForm, fnaRefresh)
    else
      FormsNotifier.NotifyForms(fnaRefresh);
  end;
end;

function TDCLCommand.GetRaights: TUserLevelsType;
begin
  Result:=FUserLevelLocal;
end;

procedure TDCLCommand.RunTextReport(ScrLine: String; Query: TDCLDialogQuery; Grid: TDCLGrid);
var
  tmpDCL: TStringList;
  tmpS, tmpS1: String;
  v1, RepIdParams, RecCount: Integer;
  DCLQuery: TDCLSimlyQuery;
  TextReport: TDCLTextReport;
begin
  tmpDCL:=TStringList.Create;
  DCLQuery:=TDCLSimlyQuery.Create(Self);
  FDBConnector.SetConnector(DCLQuery);

  RepIdParams:=0;
  tmpS:=FindParam('FromFile=', ScrLine);
  If tmpS='' Then
  begin
    tmpS1:=FindParam('ReportName=', ScrLine);
    TranslateVals(tmpS1, Query);
    DCLQuery.Close;
    DCLQuery.SQL.Text:='select Count(*) from '+DCLTable+' where lower('+
      DCLNameField+')=lower(:RepName)';
    DCLQuery.ParamByName('RepName').AsString:=tmpS1;
    DCLQuery.Open;
    RecCount:=DCLQuery.Fields[0].AsInteger;
    DCLQuery.Close;
    If RecCount=1 Then
    begin
      DCLQuery.SQL.Text:='select * from '+DCLTable+' where lower('+
        DCLNameField+')=lower(:RepName)';
      DCLQuery.ParamByName('RepName').AsString:=tmpS1;
      DCLQuery.Open;
      tmpDCL.Text:=DCLQuery.FieldByName(ScriptField).AsString;
      RepIdParams:=DCLQuery.FieldByName(IdentifyField).AsInteger;
      DCLQuery.Close;
    end;
  end
  Else
  begin
    If Not IsFullPAth(tmpS) Then
      tmpS:=IncludeTrailingPathDelimiter(AppConfigDir)+tmpS;
    If FileExists(tmpS) Then
      tmpDCL.LoadFromFile(tmpS);
  end;
  tmpS1:=FindParam('QueryMode=', ScrLine);
  v1:=0;
  If LowerCase(tmpS1)='bkmode' Then
    v1:=1;
  If LowerCase(tmpS1)='main' Then
    v1:=0;
  If LowerCase(tmpS1)='isolate' Then
    v1:=2;

  TextReport:=TDCLTextReport.Create(FNameSpace, FDBConnector, Query, Grid, FVariables, tmpDCL, RepIdParams);

  Case v1 of
  0:
    If Assigned(FDCLForm) Then
      TextReport.InitReport(nqmFromGrid);
  1:
    If Assigned(FDCLForm) Then
      TextReport.InitReport(nqmNew);
  2:
    TextReport.InitReport(nqmNew);
  end;

  If Assigned(TextReport) then
  begin
    tmpS:=Trim(FindParam('FileName=', ScrLine));
    TranslateVals(tmpS, Query);

    v1:=StrToIntEx(Trim(FindParam('ViewMode=', ScrLine)));
    TextReport.OpenReport(tmpS, TReportViewMode(v1));
    tmpS:=TextReport.SaveReport(tmpS);

    tmpS1:=FindParam('NoPrint=', ScrLine);
    TranslateVals(tmpS1, Query);
    If TReportViewMode(v1-1)=rvmMultitRecordReport Then
      tmpS1:='1';
    If tmpS1<>'1' Then
      If FindParam('Viewer=', ScrLine)<>'' Then
        Run('"'+FindParam('Viewer=', ScrLine)+'"', tmpS1, False)
      Else
        Run('"'+GPT.Viewer+'"', tmpS1, False);

    TextReport.CloseReport('Report.txt');
  end;
  FreeAndNil(tmpDCL);
  FreeAndNil(DCLQuery);
end;

procedure TDCLCommand.RunCommand(Command: String);
var
  tmpS, tmpS1, tmpS2, tmpS3, tmpS4: String;
  i, v1, v2: Integer;
  Wait, Flg1, Flg2: Boolean;
  tmpDCLForm: TDCLForm;
  {$IFDEF MSWINDOWS}
  SheetReportSelector: TSheetOfficeReportSelector;
  TextOfficeReportSelector: TTextOfficeReportSelector;
  {$ENDIF}
  OpenDialog: TOpenDialog;
  SaveDialog: TSaveDialog;
  Parser: TDCLValuseParser;
  DCLEdit: TDCLEdit;
  DCLConfig: TDCLConfigTable;
  DataStorage: TDCLDataStorage;
begin
  if IsLexem('Exit;', Command) then
  begin
    Sleep(100);
    Application.MainForm.Close;
  end;

  If IsLexem('About;', Command) or IsLexem('Version;', Command) Then
  begin
    About;
  end;

  TranslateVals(Command);

  If IsLexem('SetValueSeparator=', Command) then
  begin
    GPT.GetValueSeparator:=FindParam('SetValueSeparator=', Command);
  end;

  If IsLexem('ExecCommand=', Command) then
  begin
    tmpS:=FindParam('ExecCommand=', Command);
    RunCommandScript(tmpS);
  end;

  If IsLexem('ApplicationTitle=', Command) then
  begin
    tmpS:=FindParam('ApplicationTitle=', Command);
    Application.Title:=tmpS;
  end;

  If IsLexem('SetMainFormCaption=', Command) then
  begin
    tmpS:=FindParam('SetMainFormCaption=', Command);
    Application.MainForm.Caption:=tmpS;
  end;

  If IsLexem('OpenFileDialog=', Command) then
  begin
    tmpS:=FindParam('OpenFileDialog=', Command);
    tmpS1:=FindParam('Ext=', Command);
    OpenDialog:=TOpenDialog.Create(nil);
    If tmpS1<>'' Then
      OpenDialog.DefaultExt:=tmpS1;
    If OpenDialog.Execute Then
      FVariables.Variables[FNameSpace, tmpS]:=OpenDialog.FileName
    Else
      FVariables.Variables[FNameSpace, tmpS]:='';
    FreeAndNil(OpenDialog);
  end;

  If IsLexem('SaveFileDialog=', Command) then
  begin
    tmpS:=FindParam('SaveFileDialog=', Command);
    tmpS1:=FindParam('Ext=', Command);
    SaveDialog:=TSaveDialog.Create(nil);
    SaveDialog.FileName:=FindParam('FileName=', Command);
    If tmpS1<>'' Then
      SaveDialog.DefaultExt:=tmpS1;
    If SaveDialog.Execute Then
      FVariables.Variables[FNameSpace, tmpS]:=SaveDialog.FileName
    Else
      FVariables.Variables[FNameSpace, tmpS]:='';
    FreeAndNil(SaveDialog);
  end;

  If IsLexem('Report=', Command) then
  begin
    RunTextReport(Command, FDCLGrid.Query, FDCLGrid);
  end;

  if IsLexem('ReadConfig=', Command) then
  begin
    tmpS:=FindParam('ReadConfig=', Command);
    tmpS2:=FindParam('VariableName=', Command);

    DCLConfig:=TDCLConfigTable.Create(FDBConnector);
    tmpS3:=DCLConfig.ReadConfig(tmpS, '');
    FVariables.NewVariable(FNameSpace, tmpS2, tmpS3);
    FreeAndNil(DCLConfig);
  end;

  if IsLexem('WriteConfig=', Command) then
  begin
    tmpS:=FindParam('WriteConfig=', Command);
    tmpS2:=FindParam('Value=', Command);

    DCLConfig:=TDCLConfigTable.Create(FDBConnector);
    DCLConfig.WriteConfig(tmpS, tmpS2, '');
    FreeAndNil(DCLConfig);
  end;

  if IsLexem('Message=', Command) then
  begin
    tmpS:=FindParam('message=', Command);
    tmpS3:=FindParam('Flags=', Command);
    If tmpS3<>'' Then
    begin
      tmpS2:=FindParam('VariableName=', Command);
      FVariables.NewVariableWithTest(FNamespace, tmpS2);

      If LowerCase(tmpS3)='yesno' Then
      begin
        If ShowErrorMessage(10, tmpS)=1 Then
          FVariables.Variables[FNamespace, tmpS2]:='1'
        Else
          FVariables.Variables[FNamespace, tmpS2]:='0';
      end
      Else If LowerCase(tmpS3)='input' Then
      begin
        tmpS3:=FindParam('DefaultValue=', Command);
        FVariables.Variables[FNamespace, tmpS2]:=InputBox(tmpS, '', tmpS3);
      end;
    end
    Else
      ShowErrorMessage(9, tmpS);
  end;

  if IsLexem('Declare=', Command) then
  begin
    tmpS:=Trim(FindParam('declare=', Command));
    For v1:=1 to ParamsCount(tmpS) do
    begin
      tmpS1:=GetParam(tmpS, v1);
      v2:=PosEx('=', tmpS1);
      If v2=0 Then
        FVariables.NewVariable(FNamespace, tmpS1, '')
      Else
      begin
        tmpS2:=Trim(Copy(tmpS1, 1, v2-1));
        tmpS3:=Copy(tmpS1, v2+1, Length(tmpS1)-v2);
        if Assigned(FDCLGrid) then
          TranslateVals(tmpS3, FDCLGrid.Query)
        else
          TranslateVals(tmpS3);

        FVariables.NewVariable(FNamespace, tmpS2, tmpS3);
      end;
    end;
  end;

  if IsLexem('Dispose=', Command) then
  begin
    tmpS:=FindParam('dispose=', Command);
    For v1:=1 to ParamsCount(tmpS) do
      FVariables.FreeVariable(FNamespace, GetParam(tmpS, v1));
  end;

  if IsLexem('SetValue=', Command) then
  begin
    SetValue(Command);
  end;

  If IsLexem('ExecQuery=', Command) then
  begin
    if Assigned(FDCLGrid) and Assigned(FDCLGrid.Query) and FDCLGrid.Query.Active then
      if FDCLGrid.Query.State in dsEditModes then
        FDCLGrid.Query.Cancel;
    tmpS:=FindParam('ExecQuery=', Command);
    ExecSQLCommand(tmpS);
  end;

  if IsLexem('Dialog=', Command) then
  begin
    DialogCommand(Command);
  end;

  If IsLexem('CloseDialog;', Command) or IsLexem('Close;', Command) Then
  begin
    If Assigned(FDCLForm) Then
    Begin
      tmpDCLForm:=FDCLForm.ParentForm;
      FDCLForm.CloseAction:=fcaClose;
      FDCLForm:=tmpDCLForm;
    End;
  end;

  If IsLexem('Execute=', Command) then
  begin
    SetCurrentDir(Path);
    tmpS:=FindParam('execute=', Command);

    tmpS1:=FindParam('WorkDir=', Command);
    If tmpS1='' Then
      tmpS1:=Path;

    If Not DirectoryExists(tmpS1) Then
      SetCurrentDir(Path)
    Else
      SetCurrentDir(tmpS1);

    try
      Wait:=FindParam('Wait=', Command)='1';
      Run(tmpS, '', Wait);
    Except
      ShowErrorMessage( - 8000, tmpS1+tmpS);
    end;
  end;

  If IsLexem('OpenDocument=', Command) then
  begin
    tmpS:=FindParam('OpenDocument=', Command);
    OpenFile(tmpS);
  end;

  If IsLexem('OpenFolder=', Command) then
  begin
    tmpS:=FindParam('OpenFolder=', Command);
    OpenDir(tmpS);
  end;

  If IsLexem('GetFromDB=', Command) then
  begin
    Flg2:=FindParam('ByID=', Command)='1';
    tmpS:=FindParam('FileName=', Command);
    tmpS1:=FindParam('GetFromDB=', Command);

    If not IsFullPath(tmpS) then
      tmpS:=IncludeTrailingPathDelimiter(AppConfigDir)+tmpS;
    DataStorage:=TDCLDataStorage.Create(FDBConnector);
    if Flg2 then
      DataStorage.SaveToFile(tmpS, tmpS1, ftByIndex)
    else
      DataStorage.SaveToFile(tmpS, tmpS1, ftByName);
    FreeAndNil(DataStorage);
  end;

  If GetRaights>=ulWrite then
  begin
    If IsLexem('PutToDB=', Command) then
    begin
      tmpS:=FindParam('FileName=', Command);
      tmpS1:=FindParam('PutToDB=', Command);
      Flg1:=FindParam('Compress=', Command)='1';
      Flg2:=FindParam('ByID=', Command)='1';

      If not IsFullPath(tmpS) then
        tmpS:=IncludeTrailingPathDelimiter(AppConfigDir)+tmpS;
      If FileExists(tmpS) then
      begin
        DataStorage:=TDCLDataStorage.Create(FDBConnector);
        if Flg2 then
          DataStorage.StoreFromFile(tmpS, tmpS1, ftByIndex, Flg1)
        else
          DataStorage.StoreFromFile(tmpS, tmpS1, ftByName, Flg1);
        FreeAndNil(DataStorage);
      end
      Else
        ShowErrorMessage( - 8001, tmpS);
    end;

    If IsLexem('ClearData=', Command) then
    begin
      Flg2:=FindParam('ByID=', Command)='1';
      tmpS:=FindParam('ClearData=', Command);
      DataStorage:=TDCLDataStorage.Create(FDBConnector);
      if Flg2 then
        DataStorage.ClearData(tmpS, ftByIndex)
      else
        DataStorage.ClearData(tmpS, ftByName);
      FreeAndNil(DataStorage);
    end;

    If IsLexem('DeleteData=', Command) then
    begin
      tmpS:=FindParam('DeleteData=', Command);
      Flg2:=FindParam('ByID=', Command)='1';

      DataStorage:=TDCLDataStorage.Create(FDBConnector);
      if Flg2 then
        DataStorage.DeleteData(tmpS, ftByIndex)
      else
        DataStorage.DeleteData(tmpS, ftByName);
      FreeAndNil(DataStorage);
    end;

    If IsLexem('CompressData=', Command) then
    begin
      tmpS:=FindParam('CompressData=', Command);
      Flg2:=FindParam('ByID=', Command)='1';

      DataStorage:=TDCLDataStorage.Create(FDBConnector);
      if Flg2 then
        DataStorage.CompressData(tmpS, ftByIndex)
      else
        DataStorage.CompressData(tmpS, ftByName);
      FreeAndNil(DataStorage);
    end;

    If IsLexem('DeCompressData=', Command) then
    begin
      Flg2:=FindParam('ByID=', Command)='1';
      tmpS:=FindParam('DeCompressData=', Command);

      DataStorage:=TDCLDataStorage.Create(FDBConnector);
      if Flg2 then
        DataStorage.DeCompressData(tmpS, ftByIndex)
      else
        DataStorage.DeCompressData(tmpS, ftByName);
      FreeAndNil(DataStorage);
    end;

    If IsLexem('MD5Data=', Command) then
    begin
      Flg2:=FindParam('ByID=', Command)='1';
      tmpS:=FindParam('MD5Data=', Command);
      tmpS1:=FindParam('VariableName=', Command);

      DataStorage:=TDCLDataStorage.Create(FDBConnector);
      if Flg2 then
        FVariables.NewVariable(FNamespace, tmpS1, DataStorage.MD5(tmpS, ftByIndex))
      else
        FVariables.NewVariable(FNamespace, tmpS1, DataStorage.MD5(tmpS, ftByName));
    end;
  end;

  {$IFDEF MSWINDOWS}
  If IsLexem('ReportOfficeSheet=', Command) then
  begin
    Parser:=TDCLValuseParser.Create(FNameSpace, FVariables);

    SheetReportSelector:=TSheetOfficeReportSelector.Create(Command, FDBConnector, Parser);
    if Assigned(FDCLGrid) and Assigned(FDCLGrid.Query) and (FDCLGrid.Query.SQL.Text<>'') then
      SheetReportSelector.SetSQL(FDCLGrid.Query.SQL.Text);

    SheetReportSelector.Run;
    FreeAndNil(Parser);
  end;

  If IsLexem('ReportOfficeText=', Command) then
  begin
    Parser:=TDCLValuseParser.Create(FNameSpace, FVariables);

    TextOfficeReportSelector:=TTextOfficeReportSelector.Create(Command, FDBConnector, Parser);
    if Assigned(FDCLGrid) and Assigned(FDCLGrid.Query) and (FDCLGrid.Query.SQL.Text<>'') then
      TextOfficeReportSelector.SetSQL(FDCLGrid.Query.SQL.Text);

    TextOfficeReportSelector.Run;
    FreeAndNil(Parser);
  end;
  {$ENDIF}

  If Assigned(FDCLForm) Then
  begin
    {$IFNDEF NOONTOP}
    If IsLexem('OnTop=', Command) then
    begin
      if (Trim(FindParam('OnTop=', Command))='1') and (FDCLForm.FormStyle=fsNormal) then
          FDCLForm.FormStyle:=fsStayOnTop
      else
        FDCLForm.FormStyle:=fsNormal;
    end;
    {$ENDIF}

    If IsLexem('CurrentPage=', Command) then
    begin
      tmpS:=Trim(FindParam('CurrentPage=', Command));
      If tmpS<>'' Then
      begin
        If tmpS='-1' then
          v1:=FDCLForm.Grids.Count-1
        Else
          v1:=StrToIntEx(tmpS)-1;
        If Assigned(FDCLForm.Grids[v1]) Then
          FDCLForm.Grids[v1].Show;
      end;
    end;

    If IsLexem('CurrentTablePart=', Command) then
    begin
      tmpS:=Trim(FindParam('CurrentTablePart=', Command));
      If tmpS<>'' Then
      begin
        If tmpS='-1' then
          v1:=FDCLForm.CurrentGrid.TableParts.Count-1
        Else
          v1:=StrToIntEx(tmpS)-1;
        If Assigned(FDCLForm.CurrentGrid.TableParts[v1]) then
          FDCLForm.CurrentGrid.TableParts[v1].Show;
      end;
    end;

    If IsLexem('Status=', Command) then
    begin
      TmpS:=FindParam('Status=', Command);
      FDCLForm.SetInfoStatus(tmpS);
    end;

    If IsLexem('AddStatus=', Command) then
    begin
      TmpS:=FindParam('AddStatus=', Command);
      v1:=0;
      If FindParam('Width=', Command)<>'' then
        v1:=StrToIntEx(FindParam('Width=', Command));

      FDCLForm.AddInfoStatus(tmpS, v1);
    end;

    If IsLexem('SetStatusText=', Command) then
    begin
      v1:=0;
      tmpS:=FindParam('Status=', Command);
      If tmpS<>'' Then
      begin
        If LowerCase(tmpS)='last' Then
          v1:=0
        Else
          v1:=StrToIntEx(Trim(FindParam('Status=', Command)))
      end;

      tmpS:=FindParam('SetStatusText=', Command);
      v2:= - 1;
      If FindParam('Width=', Command)<>'' then
        v2:=StrToIntEx(Trim(FindParam('Width=', Command)));
      FDCLForm.SetStatusNum(tmpS, v1-1, v2);
    end;

    if IsLexem('DeleteStatus=', Command) then
    begin
      tmpS:=FindParam('DeleteStatus=', Command);
      v1:=0;
      If tmpS<>'' then
      begin
        If LowerCase(tmpS)='last' then
          v1:=-1
        else
          v1:=StrToIntEx(Trim(tmpS));
      end;

      FDCLForm.DeleteStatus(v1);
    end;

    If IsLexem('DeleteAllStatus;', Command) then
    begin
      FDCLForm.DeleteAllStatus;
    end;

    If IsLexem('SetFormCaption=', Command) then
    begin
      tmpS:=FindParam('SetFormCaption=', Command);
      FDCLForm.Caption:=tmpS;
    end;
  end;

  if Assigned(FDCLGrid) and Assigned(FDCLGrid.Query) and FDCLGrid.Query.Active then
  begin
    If IsLexem('Refresh;', Command) then
    begin
      FDCLGrid.ReFreshData;
    end;

    If IsLexem('ReOpen;', Command) then
    begin
      FDCLGrid.ReFreshData;
    end;

    if IsLexem('First;', Command) then
    begin
      FDCLGrid.Query.First;
    end;

    if IsLexem('Last;', Command) then
    begin
      FDCLGrid.Query.Last;
    end;

    if IsLexem('Prior;', Command) then
    begin
      FDCLGrid.Query.Prior;
    end;

    if IsLexem('Next;', Command) then
    begin
      FDCLGrid.Query.Next;
    end;

    if IsLexem('Cancel;', Command) then
    begin
      if FDCLGrid.Query.State in dsEditModes then
        FDCLGrid.Query.Cancel;
    end;

    If IsLexem('GotoKey=', Command) then
    begin
      tmpS:=FindParam('KeyField=', Command);
      tmpS1:=FindParam('GotoKey=', Command);
      FDCLGrid.Query.Locate(tmpS, tmpS1, [loCaseInsensitive]);
    end;

    If IsLexem('EditByName=', Command) then
    begin
      tmpS:=FindParam('EditByName=', Command);
      tmpS1:=Copy(tmpS, 1, Pos('.', tmpS)-1);
      tmpS2:=Copy(tmpS, Pos('.', tmpS)+1, Length(tmpS));

      for DCLEdit in FDCLGrid.Edits do
      begin
        If Assigned(DCLEdit.Control) Then
        begin
          If FDCLForm.Showing Then
          if LowerCase(DCLEdit.Control.Name)=LowerCase(tmpS1) then
          begin
            If LowerCase(tmpS2)='setfocus' Then
              (DCLEdit.Control as TEdit).SetFocus;
            If LowerCase(tmpS2)='clear' Then
              (DCLEdit.Control as TEdit).Clear;
            If LowerCase(tmpS2)='show' Then
              (DCLEdit.Control as TEdit).Show;
            If LowerCase(tmpS2)='hide' Then
              (DCLEdit.Control as TEdit).Hide;
            If LowerCase(tmpS2)='enabled' Then
              (DCLEdit.Control as TEdit).Enabled:=True;
            If LowerCase(tmpS2)='disabled' Then
              (DCLEdit.Control as TEdit).Enabled:=False;
            If LowerCase(tmpS2)='select' Then
              (DCLEdit.Control as TEdit).SelectAll;
            If LowerCase(tmpS2)='settext' then
            begin
              If PosEx('_Value=', Command)<>0 then
              begin
                tmpS:=FindParam('_Value=', Command);
                (DCLEdit.Control as TEdit).Text:=tmpS;
              end;
            end;

            break;
          end;
        end;
      end;
    end;

    If GetRaights>=ulWrite Then
    begin
      if IsLexem('Post;', Command) then
      begin
        if FDCLGrid.Query.CanModify and (FDCLGrid.Query.State in dsEditModes) then
          FDCLGrid.Query.Post;
      end;

      if IsLexem('Append;', Command) then
      begin
        if FDCLGrid.Query.CanModify then
        if not (FDCLGrid.Query.State in dsEditModes) then
          FDCLGrid.Query.Append;
      end;

      if IsLexem('Insert;', Command) then
      begin
        if FDCLGrid.Query.CanModify then
        if not (FDCLGrid.Query.State in dsEditModes) then
          FDCLGrid.Query.Insert;
      end;

      if IsLexem('Edit;', Command) then
      begin
        if FDCLGrid.Query.CanModify then
        if not (FDCLGrid.Query.State in dsEditModes) then
          FDCLGrid.Query.Edit;
      end;

      If IsLexem('Delete;', Command) then
      begin
        if FDCLGrid.Query.CanModify then
          FDCLGrid.Query.Delete;
      end;

      If IsLexem('DeleteConf;', Command) then
      begin
        if FDCLGrid.Query.CanModify then
          If ShowErrorMessage(10, GetDCLMessageString(msDeleteRecordQ))=1 then
            FDCLGrid.Query.Delete;
      end;

      If IsLexem('SetFieldValue=', Command) then
      begin
        tmpS:=FindParam('SetFieldValue=', Command);
        tmpS1:=Trim(FindParam('TablePartNum=', Command));
        Flg1:=FindParam('Post=', Command)='1';

        If tmpS<>'' then
        begin
          for i:=1 to ParamsCount(tmpS) do
          begin
            tmpS3:=GetParam(tmpS, i);
            v1:=Pos('=', tmpS3);

            if v1<>0 then
            begin
              tmpS4:=tmpS3.Substring(1, v1-1);
              tmpS2:=tmpS3.Substring(v1+1);

              If tmpS4<>'' then
              begin
                v1:=StrToIntEx(tmpS1)-1;
                If (v1>=0) and (FDCLGrid.TableParts.Count>v1) and Assigned(FDCLGrid.TableParts[v1]) then
                begin
                  If not (FDCLGrid.TableParts[v1].Query.State in dsEditModes) then
                    FDCLGrid.TableParts[v1].Query.Edit;
                  FDCLGrid.TableParts[v1].Query.FieldByName(tmpS4).AsString:=tmpS;

                  if Flg1 then
                    FDCLGrid.TableParts[v1].Query.Post;
                end;
              end
              else
              begin
                If not (FDCLGrid.Query.State in dsEditModes) then
                  FDCLGrid.Query.Edit;
                FDCLGrid.Query.FieldByName(tmpS4).AsString:=tmpS;
                if Flg1 then
                  FDCLGrid.TableParts[v1].Query.Post;
              end;
            end;
          end;
        end;
      end;
    end;
  end;


  if Assigned(FDCLGrid) and Assigned(FDCLGrid.CurrentTablePart) and FDCLGrid.CurrentTablePart.Query.Active then
  begin
    If GetRaights>=ulWrite Then
    begin
      If IsLexem('Refresh_part;', Command) then
      begin
        FDCLGrid.CurrentTablePart.ReFreshData;
      end;
    
      If IsLexem('Insert_part;', Command) then
      begin
        FDCLGrid.CurrentTablePart.Query.Insert;
      end;

      If IsLexem('Append_part;', Command) then
      begin
        FDCLGrid.CurrentTablePart.Query.Append;
      end;

      If IsLexem('Post_part;', Command) then
      begin
        FDCLGrid.CurrentTablePart.Query.Post;
      end;

      If IsLexem('Delete_part;', Command) then
      begin
        FDCLGrid.CurrentTablePart.Query.Delete;
      end;

      If IsLexem('DeleteConf_part;', Command) then
      begin
        If ShowErrorMessage(10, GetDCLMessageString(msDeleteRecordQ))=1 then
          FDCLGrid.CurrentTablePart.Query.Delete;
      end;

      If IsLexem('Edit_part;', Command) then
      begin
        FDCLGrid.CurrentTablePart.Query.Edit;
      end;
    end;

    If IsLexem('Next_part;', Command) then
    begin
      FDCLGrid.CurrentTablePart.Query.Next;
    end;

    If IsLexem('Prior_part;', Command) then
    begin
      FDCLGrid.CurrentTablePart.Query.Prior;
    end;

    If IsLexem('First_part;', Command) then
    begin
      FDCLGrid.CurrentTablePart.Query.First;
    end;

    If IsLexem('Last_part;', Command) then
    begin
      FDCLGrid.CurrentTablePart.Query.Last;
    end;
  end;
end;

procedure TDCLCommand.SelectRunType(Command: String);
var
  DCLQuery: TDCLDialogQuery;
  Empty: Boolean;
  Script: String;
  DCL: TStringList;
begin
  DCLQuery:=TDCLDialogQuery.Create(Self);
  FDBConnector.SetConnector(DCLQuery);

  DCLQuery.SQL.Text:='select * from '+DCLTable+' where lower('+DCLNameField+')=lower(:COMMAND)';
  DCLQuery.ParamByName('COMMAND').AsString:=Command;
  DCLQuery.Open;
  Empty:=DCLQuery.IsEmpty;
  if not Empty then
    Script:=DCLQuery.FieldByName(ScriptField).AsString;
  DCLQuery.Close;
  FreeAndNil(DCLQuery);

  if Empty then
  begin
    RunCommand(Command+';');
  end
  else
  begin
    DCL:=TStringList.Create;
    DCL.Text:=Script;
    if DCL.Count>0 then
    begin
      RunCommandScript(Command);
    end
  end;
end;

procedure TDCLCommand.About;
var
  About: TAboutForm;
begin
  About:=TAboutForm.Create(Self, FDBConnector);
  About.ShowModal;
  About.Release;
end;

function TDCLCommand.CreateForm(NameSpace, DialogName: String; NoContext: Boolean;
  ParentForm: TDCLForm; Grid: TDCLGrid; ReturnValueParams: TReturnValueParams;
  Modal: Boolean): TDCLForm;
var
  DCLQuery: TDCLDialogQuery;
  Empty: Boolean;
  Script: String;
  DCL: TStringList;
  lForm: TDCLForm;
begin
  DCLQuery:=TDCLDialogQuery.Create(Self);
  FDBConnector.SetConnector(DCLQuery);

  DCLQuery.SQL.Text:='select * from '+DCLTable+' where lower('+DCLNameField+')=lower(:COMMAND)';
  DCLQuery.ParamByName('COMMAND').AsString:=DialogName;
  DCLQuery.Open;
  Empty:=DCLQuery.IsEmpty;
  if not Empty then
    Script:=DCLQuery.FieldByName(ScriptField).AsString;
  DCLQuery.Close;

  Result:=nil;
  if not Empty then
  begin
    DCL:=TStringList.Create;
    DCL.Text:=Script;
    if DCL.Count>0 then
    begin
      if NoContext then
        lForm:=TDCLForm.Create(FIDCLMain, DialogName, NameSpace, ParentForm, DCL,
          nil, nil, Self, ReturnValueParams, Modal)
      else
        lForm:=TDCLForm.Create(FIDCLMain, DialogName, NameSpace, ParentForm, DCL,
          Grid.Query, Grid.Data, Self, ReturnValueParams, Modal);

      if not lForm.Reject then
      begin
        FForms.Add(lForm);
        Result:=lForm;
      end
      else
      begin
        lForm.Release;
        FreeAndNil(lForm);
      end;
    end;
    FreeAndNil(DCL);
  end;
end;

procedure TDCLCommand.DialogCommand(ScrStr: String);
var
  TmpStr, DialogName: String;
  ModalOpen, NoContext: Boolean;
  v1, ModalResult: Integer;
  ReturnValueParams: TReturnValueParams;
  lDCLForm: TDCLForm;
begin
  DialogName:=FindParam('Dialog=', ScrStr);
  ModalOpen:=FindParam('ModalOpen=', ScrStr)='1';
  ReturnValueParams:=nil;
  //If FindParam('Choose=', ScrStr)='1' then
  If FindParam('ChooseMode=', ScrStr)<>'' then
  begin
    ReturnValueParams:=TReturnValueParams.Create(FindParam('KeyField=', ScrStr),
      FindParam('ValueField=', ScrStr), FindParam('KeyEditName=', ScrStr), FindParam('ValueEditName=', ScrStr),
      FindParam('KeyModifyField=', ScrStr), FindParam('ValueModifyField=', ScrStr),
      FindParam('KeyVariable=', ScrStr), FindParam('ValueVariable=', ScrStr),
      FindParam('BatchScript=', ScrStr), FindParam('MultiSelect=', ScrStr)='1');

    ModalOpen:=FindParam('BatchScript=', ScrStr)='1';
  end;
  NoContext:=FindParam('NoContext=', ScrStr)='1';

  TmpStr:=Trim(FindParam('TablePart=', ScrStr));
  If TmpStr<>'' Then
  begin
    If Assigned(FDCLForm) then
    Begin
      v1:=StrToIntEx(TmpStr)-1;
      If Assigned(FDCLForm.CurrentGrid.TableParts[v1]) Then
        lDCLForm:=CreateForm(FNameSpace, DialogName, NoContext, FDCLForm,
          FDCLForm.CurrentGrid.TableParts[v1], ReturnValueParams, ModalOpen);
    End;
  end
  Else
    lDCLForm:=CreateForm(FNameSpace, DialogName, NoContext, FDCLForm, FDCLGrid,
      ReturnValueParams, ModalOpen);

  If Assigned(lDCLForm) Then
  begin
    if ModalOpen then
    begin
      if lDCLForm.Showing then
        lDCLForm.Hide;
      ModalResult:=lDCLForm.ShowModal;

      If (ModalResult=mrOK) and Assigned(lDCLForm.ReturnValue) and (lDCLForm.ReturnValue.Values.Count>0) Then
      begin
        GetValueProc(lDCLForm.ReturnValue);
      end;
    end;
    FDCLForm:=lDCLForm;
  end;
end;

procedure TDCLCommand.GetValueProc(ReturnValue: TReturnFormValue);
var
  ReturnValueItem: TGetValueItem;
  Edit: TDCLEdit;
  lDCLForm: TDCLForm;
begin
  If Assigned(ReturnValue) and (ReturnValue.Values.Count>0) Then
  begin
    lDCLForm:=(ReturnValue.DestinationForm as TDCLForm).ParentForm;

    for ReturnValueItem in ReturnValue.Values do
    begin
      If FieldExists(ReturnValue.KeyModifyField, lDCLForm.CurrentGrid.Query) Then
      begin
        If lDCLForm.CurrentGrid.Query.Active then
        begin
          if lDCLForm.CurrentGrid.Query.CanModify then
          begin
            if not (lDCLForm.CurrentGrid.Query.State in dsEditModes) then
              lDCLForm.CurrentGrid.Query.Edit;
            lDCLForm.CurrentGrid.Query.FieldByName(ReturnValue.KeyModifyField).AsString:=ReturnValueItem.Key;
          end;
        end;
      end;

      If FieldExists(ReturnValue.ValueModifyField, lDCLForm.CurrentGrid.Query) Then
      begin
        If lDCLForm.CurrentGrid.Query.Active Then
        begin
          If lDCLForm.CurrentGrid.Query.CanModify Then
          begin
            if not (lDCLForm.CurrentGrid.Query.State in dsEditModes) then
              lDCLForm.CurrentGrid.Query.Edit;
            lDCLForm.CurrentGrid.Query.FieldByName(ReturnValue.ValueModifyField).AsString:=ReturnValueItem.Value;
          end;
        end;
      end;

      If ReturnValue.KeyEditName<>'' Then
      begin
        For Edit in lDCLForm.CurrentGrid.Edits do
        begin
          If DCLCompareString(ReturnValue.KeyEditName, Edit.Control.Name) Then
          begin
            (Edit.Control as TEdit).Text:=ReturnValueItem.Key;
            break;
          end;
        end;
      end;

      If ReturnValue.ValueEditName<>'' Then
      begin
        For Edit in lDCLForm.CurrentGrid.Edits do
        begin
          If DCLCompareString(ReturnValue.ValueEditName, Edit.Control.Name) Then
          begin
            (Edit.Control as TEdit).Text:=ReturnValueItem.Value;
            break;
          end;
        end;
      end;

      if ReturnValue.KeyVar<>'' then
      begin
        FVariables.NewVariableWithTest(FNamespace, ReturnValue.KeyVar);
        FVariables.Variables[FNamespace, ReturnValue.KeyVar]:=ReturnValueItem.Key;
      end;

      if ReturnValue.ValueVar<>'' then
      begin
        FVariables.NewVariableWithTest(FNamespace, ReturnValue.ValueVar);
        FVariables.Variables[FNamespace, ReturnValue.ValueVar]:=ReturnValueItem.Value;
      end;

      if ReturnValue.BatchScript<>'' then
      begin
        RunCommandScript(ReturnValue.BatchScript);
      end;
    end;

    FDCLForm:=lDCLForm;
  end;
end;

end.

