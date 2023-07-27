unit uDCLCommand;
{$I DefineType.pas}

interface

uses
  Classes, SysUtils, Generics.Collections, Forms, Controls, StdCtrls, DB, Dialogs,
  uDCLData, uDCLTypes, uDCLConst, uDCLGrid, uDCLForm, uDCLVariables,
  uDCLUtils, uStringParams, uDCLDBConnector, uDCLDBStructure, uDBUtils,
  uDCLValuesParser, uDCLFormsNotifier;

type

  { TDCLCommand }

  TDCLCommand=class(TComponent)
  private
    FDBConnector: TDCLDBConnector;
    FForms: TList<TForm>;
    FDCLForm: TDCLForm;
    FDCLGrid: TDCLGrid;
    FNameSpace: String;
    FVariables: TVariables;
    FParser: TDCLValuseParser;
    FFormsNotifier: TDCLFormsNotifier;
    FUserLevelLocal: TUserLevelsType;

    procedure TranslateVals(var S: String);
    procedure TranslateVals(var S: String; Query: TDCLDialogQuery); overload;
    procedure SetValue(S: String);

    procedure ExecSQLCommand(SQLCommand: String);

    function GetRaights: TUserLevelsType;
    procedure RunTextReport(ScrLine: String; Query: TDCLDialogQuery; Grid: TDCLGrid);
  public
    constructor Create(DBConnector: TDCLDBConnector; NameSpace: String; Forms: TList<TForm>;
      DCLForm: TForm; DCLGrid: TDCLGrid; Variables: TVariables); overload;

    function RunCommandScript(CommandName: String): Boolean;
    procedure RunCommand(Command: String);
    procedure SelectRunType(Command: String);

    function CreateForm(NameSpace, DialogName: String; NoContext: Boolean;
      ParentForm: TDCLForm; Grid: TDCLGrid;
      ReturnValueParams: TReturnValueParams; Modal: Boolean;
      RetValueProc: TGetValueProc): TDCLForm;

    function ReadConfig(ConfigName, UserId: String): String;
    procedure WriteConfig(ConfigName, NewValue, UserId: String);

    procedure DialogCommand(ScrStr: String);

    procedure RetValue(ReturnValue: TReturnFormValue);
  end;

implementation

uses
{$IFDEF MSWINDOWS}
  uSheetOfficeReportSelector, uTextOfficeReportSelector,
{$ENDIF}
  uDCLGlobalVariables,
  uRunProgram, uDCLMessages, uDCLMultiLang, uSQLUtils, uSystemUtils, uDCLMain,
  {$IFDEF TRANSACTIONDB}
  uDCLDBTransaction,
  {$ENDIF}
  uDCLTextReport;

{ TDCLCommand }

procedure TDCLCommand.TranslateVals(var S: String);
var
  Factor: Integer;
begin
  if Assigned(FDCLGrid) and Assigned(FDCLGrid.Query) then
  begin
    FParser.RePlaseParams(S, FDCLGrid.Query);
    FParser.RePlaseVariables(FNameSpace, S, FDCLGrid.Query);
    FParser.RePlaceProc(S, Factor, FDCLGrid.Query);
  end
  else
    FParser.RePlaseVariables(FNameSpace, S, nil);
end;

procedure TDCLCommand.TranslateVals(var S: String; Query: TDCLDialogQuery); overload;
var
  Factor: Integer;
begin
  FParser:=TDCLValuseParser.Create(FNameSpace, FVariables);
  FParser.RePlaseParams(S, Query);
  FParser.RePlaseVariables(FNameSpace, S, Query);
  FParser.RePlaceProc(S, Factor, Query);
end;

constructor TDCLCommand.Create(DBConnector: TDCLDBConnector; NameSpace: String; Forms: TList<TForm>;
  DCLForm: TForm; DCLGrid: TDCLGrid; Variables: TVariables);
begin
  FDBConnector:=DBConnector;
  FForms:=Forms;
  if Assigned(DCLForm) then
    FDCLForm:=(DCLForm as TDCLForm);
  FDCLGrid:=DCLGrid;
  FUserLevelLocal:=GPT.AccessLevel;
  if Assigned(DCLGrid) then
    FUserLevelLocal:=DCLGrid.RightsLevel;
  FNameSpace:=NameSpace;
  FVariables:=Variables;

  FParser:=TDCLValuseParser.Create(FNameSpace, FVariables);
end;

function TDCLCommand.RunCommandScript(CommandName: String): Boolean;
var
  DCLQuery: TDCLDialogQuery;
  Empty: Boolean;
  Script: String;
  DCL: TStringList;
  LineNum: Integer;

  procedure Run(IfFlag, Skeep: Boolean);
  var
    IfResult, Flg, Skp: Boolean;
    posI, posI2: Integer;
    c: Char;
    Sign: TSign;
    Line, IfCondition, SignStr, Expression1, Expression2: String;
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

        posI:=Pos('(', Line);
        posI2:=Pos(')', Line);

        if (posI=0) and (posI2=0) then
          IfCondition:=Copy(Line, posI, Length(Line)-8).Trim
        else
          IfCondition:=Copy(Line, posI+1, Pos(')', Line)-posI-1).Trim;

        SignStr:='';

        posI:=1;
        for c in IfCondition do
        begin
          if c in ['=', '<', '>'] then
          begin
            break;
          end;
          Inc(posI);
        end;

        Expression1:=Copy(IfCondition, 1, PosI-1);
        Delete(IfCondition, 1, PosI-1);

        posI:=1;
        for c in IfCondition do
        begin
          if not (c in ['=', '<', '>']) then
          begin
            break;
          end;
          Inc(posI);
        end;

        SignStr:=Copy(IfCondition, 1, posI-1);
        Delete(IfCondition, 1, PosI-1);

        Expression2:=IfCondition;

        Sign:=isND;
        if SignStr='=' then
          Sign:=isEq
        else
        if SignStr='<' then
          Sign:=isLe
        else
        if SignStr='>' then
          Sign:=isGt
        else
        if SignStr='>=' then
          Sign:=isGtEq
        else
        if SignStr='<=' then
          Sign:=isLeEq
        else
        if SignStr='<>' then
          Sign:=isNotEq;

        case Sign of
        isEq: IfResult:=LowerCase(Expression1)=LowerCase(Expression2);
        isNotEq: IfResult:=LowerCase(Expression1)<>LowerCase(Expression2);
        isLe: IfResult:=LowerCase(Expression1)<LowerCase(Expression2);
        isGt: IfResult:=LowerCase(Expression1)>LowerCase(Expression2);

        isLeEq: IfResult:=LowerCase(Expression1)<=LowerCase(Expression2);
        isGtEq: IfResult:=LowerCase(Expression1)>=LowerCase(Expression2);
        end;

        Run(IfResult, False);
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
      If Not IsReturningQuery(SQLCommand) Then
        {$IFDEF ADO}
        ADOCommand.Execute
        {$ELSE}
        ADOCommand.ExecSQL
        {$ENDIF}
      Else
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
    DCLQuery.SQL.Text:='select Count(*) from '+DCLTable+' where '+GPT.UpperString+
      DCLNameField+GPT.UpperStringEnd+'='+GPT.UpperString+GPT.StringTypeChar+tmpS1+
      GPT.StringTypeChar+GPT.UpperStringEnd;
    DCLQuery.Open;
    RecCount:=DCLQuery.Fields[0].AsInteger;
    If RecCount=1 Then
    begin
      DCLQuery.Close;
      DCLQuery.SQL.Text:='select * from '+DCLTable+' where '+GPT.UpperString+
        DCLNameField+GPT.UpperStringEnd+'='+GPT.UpperString+GPT.StringTypeChar+tmpS1+
        GPT.StringTypeChar+GPT.UpperStringEnd;
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
  tmpS, tmpS1, tmpS2, tmpS3: String;
  v1, v2: Integer;
  Wait: Boolean;
  tmpDCLForm: TDCLForm;
  {$IFDEF MSWINDOWS}
  SheetReportSelector: TSheetOfficeReportSelector;
  TextOfficeReportSelector: TTextOfficeReportSelector;
  {$ENDIF}
  Parser: TDCLValuseParser;
  DCLEdit: TDCLEdit;
begin
  TranslateVals(Command);

  If IsLexem('ExecCommand=', Command) then
  begin
    tmpS:=FindParam('ExecCommand=', Command);
    RunCommandScript(tmpS);
  end;

  if IsLexem('Exit;', Command) then
  begin
    Application.MainForm.Close;
  end;

  If IsLexem('Report=', Command) then
  begin
    RunTextReport(Command, FDCLGrid.Query, FDCLGrid);
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

    If IsLexem('SetStatusText=', Command) Then
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

    If IsLexem('SetFormCaption=', Command) Then
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
            If LowerCase(tmpS2)='settext' Then
            begin
              If PosEx('_Value=', Command)<>0 Then
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

    If GetRaights=ulWrite Then
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

      If IsLexem('Delete;', Command) Then
      begin
        if FDCLGrid.Query.CanModify then
          FDCLGrid.Query.Delete;
      end;

      If IsLexem('DeleteConf;', Command) Then
      begin
        if FDCLGrid.Query.CanModify then
          If ShowErrorMessage(10, GetDCLMessageString(msDeleteRecordQ))=1 Then
            FDCLGrid.Query.Delete;
      end;

    end;


  end;


  if Assigned(FDCLGrid) and Assigned(FDCLGrid.CurrentTablePart) and FDCLGrid.CurrentTablePart.Query.Active then
  begin
    If GetRaights>ulReadOnly Then
    begin
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

  if Assigned(FDCLForm) then
  begin
    If IsLexem('OnTop=', Command) then
    begin
{$IFNDEF NOONTOP}
      if (Trim(FindParam('OnTop=', Command))='1') and (FDCLForm.FormStyle=fsNormal) then
          FDCLForm.FormStyle:=fsStayOnTop
      else
        FDCLForm.FormStyle:=fsNormal;
{$ENDIF}
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
    RunCommand(Command);
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

function TDCLCommand.CreateForm(NameSpace, DialogName: String; NoContext: Boolean;
  ParentForm: TDCLForm; Grid: TDCLGrid; ReturnValueParams: TReturnValueParams;
  Modal: Boolean; RetValueProc: TGetValueProc): TDCLForm;
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
        lForm:=TDCLForm.Create(DialogName, NameSpace, ParentForm, FVariables, FForms, DCL, FDBConnector,
          nil, nil, RetValueProc, ReturnValueParams, Modal)
      else
        lForm:=TDCLForm.Create(DialogName, NameSpace, ParentForm, FVariables, FForms, DCL, FDBConnector,
          Grid.Query, Grid.Data, RetValueProc, ReturnValueParams, Modal);

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

function TDCLCommand.ReadConfig(ConfigName, UserId: String): String;
var
  ParamsQuery: TDCLSimlyQuery;
  WhereUser: String;
begin
  Result:='';
  WhereUser:='';
  If Not GPT.NoParamsTable Then
  begin
    If UserID<>'' Then
      WhereUser:=' and '+GPTUserIDField+'='+UserID;

    ParamsQuery:=TDCLSimlyQuery.Create(Self);
    FDBConnector.SetConnector(ParamsQuery);
    ParamsQuery.SQL.Text:='select '+GPTValueField+' from '+GPTTableName+' where '+
      GPT.UpperString+GPTNameField+GPT.UpperStringEnd+'='+GPT.UpperString+':ParamName'+
      GPT.UpperStringEnd+WhereUser;
    ParamsQuery.ParamByName('ParamName').AsString:=ConfigName;
    ParamsQuery.Open;
    Result:=TrimRight(ParamsQuery.Fields[0].AsString);
    ParamsQuery.Close;
    FreeAndNil(ParamsQuery);
  end;
end;

procedure TDCLCommand.WriteConfig(ConfigName, NewValue, UserId: String);
var
  ParamsQuery: TDCLSimlyQuery;
  WhereUser: String;
begin
  WhereUser:='';
  If Not GPT.NoParamsTable Then
  begin
    If UserId<>'' Then
      WhereUser:=' and '+GPTUserIDField+'='+UserId;

    ParamsQuery:=TDCLSimlyQuery.Create(Self);
    FDBConnector.SetConnector(ParamsQuery);
    ParamsQuery.SQL.Text:='select count(*) from '+GPTTableName+' where '+GPT.UpperString+
      GPTNameField+GPT.UpperStringEnd+'='+GPT.UpperString+GPT.StringTypeChar+ConfigName+
      GPT.StringTypeChar+GPT.UpperStringEnd+WhereUser;
    ParamsQuery.Open;
    If ParamsQuery.Fields[0].AsInteger>0 Then
    begin
      ParamsQuery.Close;
      ParamsQuery.SQL.Text:='update '+GPTTableName+' set '+GPTValueField+'='+
        GPT.StringTypeChar+NewValue+GPT.StringTypeChar+' where '+GPT.UpperString+GPTNameField+
        GPT.UpperStringEnd+'='+GPT.UpperString+GPT.StringTypeChar+ConfigName+GPT.StringTypeChar+
        GPT.UpperStringEnd+WhereUser;
      ParamsQuery.ExecSQL;
    end
    Else
    begin
      ParamsQuery.Close;
      If UserID='' Then
        ParamsQuery.SQL.Text:='insert into '+GPTTableName+'('+GPTValueField+', '+
          GPTNameField+') values('+GPT.StringTypeChar+NewValue+GPT.StringTypeChar+', '+
          GPT.StringTypeChar+ConfigName+GPT.StringTypeChar+')'
      Else
        ParamsQuery.SQL.Text:='insert into '+GPTTableName+'('+GPTValueField+', '+
          GPTNameField+', '+GPTUserIDField+') values('+GPT.StringTypeChar+NewValue+
          GPT.StringTypeChar+', '+GPT.StringTypeChar+ConfigName+GPT.StringTypeChar+', '+UserID+')';

      ParamsQuery.ExecSQL;
    end;
    FreeAndNil(ParamsQuery);
  end;
end;

procedure TDCLCommand.DialogCommand(ScrStr: String);
var
  TmpStr, DialogName: String;
  ModalOpen, NoContext: Boolean;
  v1, ModalResult: Integer;
  ReturnValueParams: TReturnValueParams;
  RetValueMethod: TGetValueProc;
  lDCLForm: TDCLForm;
begin
  DialogName:=FindParam('Dialog=', ScrStr);
  ModalOpen:=FindParam('ModalOpen=', ScrStr)='1';
  ReturnValueParams:=nil;
  //If FindParam('Choose=', ScrStr)='1' Then
  If FindParam('ChooseMode=', ScrStr)<>'' Then
  begin
    ReturnValueParams:=TReturnValueParams.Create(FindParam('KeyField=', ScrStr),
      FindParam('ValueField=', ScrStr), FindParam('KeyEditName=', ScrStr), FindParam('ValueEditName=', ScrStr),
      FindParam('KeyModifyField=', ScrStr), FindParam('ValueModifyField=', ScrStr),
      FindParam('KeyVariable=', ScrStr), FindParam('ValueVariable=', ScrStr),
      FindParam('BatchScript=', ScrStr), FindParam('MultiSelect=', ScrStr)='1');
    RetValueMethod:=RetValue;
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
        lDCLForm:=CreateForm(FNameSpace, DialogName, NoContext, FDCLForm, FDCLGrid,
          ReturnValueParams, ModalOpen, RetValueMethod);
    End;
  end
  Else
    lDCLForm:=CreateForm(FNameSpace, DialogName, NoContext, FDCLForm, FDCLGrid,
      ReturnValueParams, ModalOpen, RetValueMethod);

  If Assigned(lDCLForm) Then
  begin
    if ModalOpen then
    begin
      if lDCLForm.Showing then
        lDCLForm.Hide;
      ModalResult:=lDCLForm.ShowModal;

      If (ModalResult=mrOK) and Assigned(lDCLForm.ReturnValue) and (lDCLForm.ReturnValue.Values.Count>0) Then
      begin
        RetValue(lDCLForm.ReturnValue);
      end;
    end;
    FDCLForm:=lDCLForm;
  end;
end;

procedure TDCLCommand.RetValue(ReturnValue: TReturnFormValue);
var
  vc: Integer;
  ReturnValueItem: TGetValueItem;
  Edit: TDCLEdit;
  lDCLForm: TDCLForm;
begin
  If Assigned(ReturnValue) and (ReturnValue.Values.Count>0) Then
  begin
    vc:=ReturnValue.Values.Count;

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

      if (vc>1) and (ReturnValue.BatchScript<>'') then
      begin
        RunCommandScript(ReturnValue.BatchScript);
      end;
    end;

    FDCLForm:=lDCLForm;
  end;
end;

end.

