unit uDCLValuesParser;
{$mode Delphi}

interface

uses
  Classes, SysUtils, DateUtils, DB, lazutf8,
  uDCLConst, uDCLVariables, uDCLDBAwareTypes, uDCLMD5, uDCLDBConnector;

type

  { TDCLValuseParser }

  TDCLValuseParser = class
  private
    FNameSpace: String;
    FVariables: TVariables;
    FDBConnector: TDCLDBConnector;
    FUserLevel: TUserLevelsType;

    procedure ReplaseSysVars(var ValueSet: String; Query: TDCLDialogQuery);
    procedure RePlaseVariables(const Namespace: String; var ValueSet: String);
  public
    constructor Create(const NameSpace: String; UserLevel: TUserLevelsType; Variables: TVariables); overload;

    procedure RePlaseParams(var Params: String; Query: TDCLDialogQuery);
    procedure ReplaceAllVariables(const Namespace: String; var ValueSet: String; Query: TDCLDialogQuery);
    procedure RePlaceProc(var Params: String; Query: TDCLDialogQuery);

    procedure TranslateVals(var Params: String; Query: TDCLDialogQuery; CheckParams: Boolean);

    procedure SetConnector(DBConnector: TDCLDBConnector);
  end;

implementation

uses
  uDCLUtils, uSystemUtils, uDCLMultiLang, uDBUtils, uConvertEx, uDCLTranscode,
  uDCLDBUtils, uDCLGlobalVariables, uDCLVersion, uDCLConfigTable,
  uExpressionParser, uStringParams, SumProps, uStringUtils;

const
  MaxSysVars=35;
  SysVarsSet: Array [1..MaxSysVars] of String=('_TIME_', '_TIMES_', '_DATE_', '_DATETIME_', // 4
    '_VERSION_', '_ISEMPTY_', '_USERNAME_', '_PASSWORD_', '_STRINGTYPECHAR_', '_ROLENAME_', // 10
    '_ROLEID_', '_USERPASS_', '_LONGROLENAME_', '_FOB_', '_EOB_', '_VALUESEPARATOR_', // 16
    '_APPPATH_', '_ENGINETYPE_', '_APPNAME_', '_DCL_USER_NAME_', '_USERID_', // 21
    '_USERNAMEACCESSLEVELS_', '_USERACCESSLEVEL_', '_NOTIFYACTIONS_', '_YESNO_', // 25
    '_YEAR_', '_DSSTATE_', '_DSSTATENAME_', '_APPDATAPATH_', '_OS_', '_USERPROFILE_', // 31
    '_USERDOC_', '_DCLINI_', '_ACCESSLEVEL_', '_LASTDIALOGRESULT_'); // 35

  ProcCount=27;
  ProcNames: Array [1..ProcCount] Of String=('ToFloat', 'DeleteNoneFilesSimb', 'GetFileNameToTranslite', //3
    'ExtractFileName', 'MoneyToString', 'ByIndex', 'Count', 'IndexOf', 'ReadConfig', 'WriteConfig', // 10
    'NVL', 'iif', 'GetTempFileName', 'DaysInMonth', 'GetMonthName', 'LeadingZero', 'GetAccessLevelByName', // 17
    'Upper', 'Lower', 'MD5File', 'MD5String', 'YearOf', 'MonthOf', 'DayOf', // 24
    'Trim', 'TrimLeft', 'TrimRight'); // 27

{ TDCLValuseParser }

procedure TDCLValuseParser.ReplaseSysVars(var ValueSet: String; Query: TDCLDialogQuery);
var
  Pos, MaxLength, i, FindSysVarNum: Integer;
  Variable, Variable2, LastVariable, Value: String;
begin
  for Variable in SysVarsSet do
  begin
    while PosEx(VariablePrefix+Variable, ValueSet)<>0 do
    begin
      Pos:=PosEx(VariablePrefix+Variable, ValueSet);

      if Pos<>0 then
      begin
        MaxLength:=0;
        LastVariable:='';
        FindSysVarNum:=-1;
        for i:=1 to Length(SysVarsSet) do
        begin
          Variable2:=SysVarsSet[i];
          if (MaxLength<Length(Variable2)) and (PosEx(VariablePrefix+Variable2, ValueSet)<>0) then
          begin
            Pos:=PosEx(VariablePrefix+Variable2, ValueSet);
            LastVariable:=Variable2;
            FindSysVarNum:=i;
            MaxLength:=Length(Variable2);
          end;
        end;

        if LastVariable<>'' then
        begin
          If FindSysVarNum<>-1 Then
          begin
            Case FindSysVarNum of
            1:
            Value:=TimeToStr(SysUtils.Time);
            2:
            Value:=TimeToStr(SysUtils.Time);
            3:
            Value:=DateToStr(Date);
            4:
            Value:=DateTimeToStr(Now);
            5:
            Value:=DCLVersion;
            6:
            begin
              if Assigned(Query) then
              begin
                If (Query.Eof and Query.Bof) Then
                  Value:='1'
                Else
                  Value:='0';
              end;
            end;
            7:
            Value:=GPT.DBUserName;
            8:
            Value:=GPT.DBPassword;
            9:
            Value:=GPT.StringTypeChar;
            10:
            Value:=GPT.DCLRoleName;
            11:
            Value:=GPT.RoleID;
            12:
            Value:=GPT.DCLUserPass;
            13:
            Value:=GPT.LongRoleName;
            14:
            begin
              if Assigned(Query) then
              begin
                If Query.Bof Then
                  Value:='1'
                Else
                  Value:='0';
              end;
            end;
            15:
            begin
              if Assigned(Query) then
              begin
                If Query.Eof Then
                  Value:='1'
                Else
                  Value:='0';
              end;
            end;
            16:
            Value:=',';
            17:
            Value:=ExcludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
            18:
            Value:=DBEngineType;
            19:
            Value:=ExtractFileName(ParamStr(0));  // '_APPNAME_'
            20:
            Value:=GPT.DCLUserName;
            21:
            Value:=GPT.UserID;
            22:
            Value:=GetDCLMessageString(msAccessLevelsSet);
            23:
            Value:=IntToStr(Ord(GPT.AccessLevel));
            24:
            Value:=GetDCLMessageString(msNotifyActionsSet);
            25:
            Value:=GetDCLMessageString(msNoYes);
            26:
            Value:=IntToStr(YearOf(Now));
            27:begin
              if Assigned(Query) then
                Value:=IntToStr(Ord(Query.State));
            end;
            28:
            Value:=GetNameDSState(Query.State);
            29:
            Value:=ExcludeTrailingPathDelimiter(GPT.AppConfigDir);
            30:
            Value:=OSType;
            31:
            Value:=UserProfileDir; // '_USERPROFILE_'
            32:
            Value:=GetUserDocumentsDir; // '_USERDOC_'
            33:
            Value:=GPT.IniFileName; // _DCLINI_
            34:
            if FUserLevel=ulUndefined then
              Value:=IntToStr(Ord(GPT.AccessLevel))
            else
              Value:=IntToStr(Ord(FUserLevel));
            35:
            Value:=IntToStr(Ord(DialogResult));
            end;

            Delete(ValueSet, Pos, Length(LastVariable)+Length(VariablePrefix));
            Insert(Value, ValueSet, Pos);
          end;
        end;
      end;
    end;
  end;
end;

constructor TDCLValuseParser.Create(const NameSpace: String; UserLevel: TUserLevelsType; Variables: TVariables);
begin
  FNameSpace:=NameSpace;
  FVariables:=Variables;
  FUserLevel:=UserLevel;
end;

procedure TDCLValuseParser.RePlaseParams(var Params: String; Query: TDCLDialogQuery);
Var
  Pos, MaxLength: Integer;
  LastField, Value: String;
  Field, Field2: TField;
Begin
  If TransParams then
  If Assigned(Query) then
  begin
    If Query.Active and (Query.FieldCount>0) then
    Begin
      for Field in Query.Fields do
      begin
        while PosEx(ParamPrefix+Field.FieldName, Params)<>0 do
        begin
          Pos:=PosEx(ParamPrefix+Field.FieldName, Params);

          if Pos<>0 then
          begin
            MaxLength:=0;
            LastField:='';
            for Field2 in Query.Fields do
            begin
              if (MaxLength<Length(Field2.FieldName)) and (PosEx(ParamPrefix+Field2.FieldName, Params)<>0) then
              begin
                Pos:=PosEx(ParamPrefix+Field2.FieldName, Params);
                LastField:=Field2.FieldName;
                MaxLength:=Length(Field2.FieldName);
              end;
            end;

            Value:=TrimRight(Query.FieldByName(LastField).AsString);
            Delete(Params, Pos, MaxLength+Length(ParamPrefix));
            Insert(Value, Params, Pos);
          end;
        end;
      end;
    End;
  end;
end;

procedure TDCLValuseParser.RePlaseVariables(const Namespace: String;
  var ValueSet: String);
var
  Pos, MaxLength: Integer;
  Variable, Variable2: String;
  Found, FoundRound: Boolean;
  LastVariableValue: String;
begin
  if Assigned(FVariables) then
  begin
    Pos:=0;
    while PosEx(VariablePrefix, ValueSet)<>0 do
    begin
      FoundRound:=False;
      for Variable in FVariables.VariableNamesList do
      begin
        Pos:=PosEx(VariablePrefix+Variable, ValueSet);

        if Pos<>0 then
        begin
          MaxLength:=0;
          LastVariableValue:='';
          Found:=False;
          for Variable2 in FVariables.VariableNamesList do
          begin
            if FVariables.Exists(Namespace, Variable2) and (MaxLength<Length(Variable2)) and (PosEx(VariablePrefix+Variable2, ValueSet)<>0) then
            begin
              Pos:=PosEx(VariablePrefix+Variable2, ValueSet);
              LastVariableValue:=FVariables.Variables[Namespace, Variable2];
              MaxLength:=Length(Variable2);
              Found:=True;
              FoundRound:=True;
            end;
          end;

          if Found then
          begin
            Delete(ValueSet, Pos, MaxLength+Length(VariablePrefix));
            Insert(LastVariableValue, ValueSet, Pos);
          end;
        end;
      end;

      if not FoundRound then
        break;
    end;
  end;
end;

procedure TDCLValuseParser.ReplaceAllVariables(const Namespace: String;
  var ValueSet: String; Query: TDCLDialogQuery);
begin
  ReplaseSysVars(ValueSet, Query);
  RePlaseVariables(NameSpace, ValueSet);
end;

procedure TDCLValuseParser.RePlaceProc(var Params: String; Query: TDCLDialogQuery);
var
  Proc, Proc2, ResultStr, ProcParams, S: String;
  P, FunctionParamsCount, MaxLength, i, FindNum, Skobki, pv1, pv2, pv3, EndPos, ParamLen: Integer;
  FunctionParams: Array of String;
  DCLConfig: TDCLConfigTable;

  function CompareProcName(ProcIndex: Integer; ProcName: String): Boolean;
  begin
    Result:=ProcNames[ProcIndex].ToLower=ProcName.ToLower;
  end;

Begin
  ParamLen:=Length(Params);
  for Proc in ProcNames do
  begin
    while PosEx(ProcPrefix+Proc, Params)<>0 do
    begin
      P:=PosEx(ProcPrefix+Proc, Params);

      if P<>0 then
      begin
        MaxLength:=0;
        FindNum:=-1;
        for i:=1 to Length(ProcNames) do
        begin
          Proc2:=ProcNames[i];
          if (MaxLength<Length(Proc2)) and (PosEx(ProcPrefix+Proc2, Params)<>0) then
          begin
            P:=PosEx(ProcPrefix+Proc2, Params);
            FindNum:=i;
            MaxLength:=Length(Proc2);
          end;
        end;

        if FindNum<>-1 then
        begin
          pv1:=P;
          Repeat
            Inc(pv1);
          Until (Params[pv1]='(') and (ParamLen>pv1);
          pv2:=pv1;

          Skobki:=0;
          While (pv1<ParamLen) Do
          Begin
            If Params[pv1]=')' Then
            begin
              Dec(Skobki);
              if Skobki=0 then
              begin
                break;
              end;
            end
            Else If Params[pv1]='(' Then
              Inc(Skobki);

            Inc(pv1);
          End;
          EndPos:=pv1;

          ProcParams:=Copy(Params, pv2+1, pv1-pv2-1);
          RePlaceProc(ProcParams, Query);

          FunctionParamsCount:=ParamsCount(ProcParams);
          SetLength(FunctionParams, FunctionParamsCount+1);
          FunctionParams[0]:=ProcNames[FindNum];
          For i:=1 To FunctionParamsCount Do
          Begin
            FunctionParams[i]:=GetParam(ProcParams, i);
          End;

          if CompareProcName(FindNum, 'ToFloat') then
          Begin
            if Pos('.', FunctionParams[1])=0 then
              ResultStr:=FunctionParams[1]+'.00'
            Else
            Begin
              i:=Pos('.', FunctionParams[1]);
              ResultStr:=Copy(FunctionParams[1], Pos('.', FunctionParams[1])+1, 2);
              If Length(ResultStr)=1 Then
                ResultStr:=ResultStr+'0';

              ResultStr:=Copy(FunctionParams[1], 1, i)+ResultStr;
            End;
          End
          else if CompareProcName(FindNum, 'DeleteNoneFilesSimb') then
          Begin
            ParamLen:=Length(FunctionParams[1]);
            While ParamLen<>0 Do
            Begin
              If (FunctionParams[1][ParamLen]='"') Or (FunctionParams[1][ParamLen]=CrossDelim) Or
                (FunctionParams[1][ParamLen]=':') or (FunctionParams[1][ParamLen]='*') Or
                (FunctionParams[1][ParamLen]='>') Or
                (FunctionParams[1][ParamLen]='<') Then
                Delete(FunctionParams[1], ParamLen, 1);
              Dec(ParamLen);
            End;
            ResultStr:=FunctionParams[1];
          End
          else if CompareProcName(FindNum, 'GetFileNameToTranslite') then
          Begin
            ResultStr:=GetFileNameToTranslite(FunctionParams[1]);
          End
          else if CompareProcName(FindNum, 'ExtractFileName') then
          Begin
            ResultStr:=ExtractFileName(FunctionParams[1]);
          End
          else if CompareProcName(FindNum, 'SumWrite') or CompareProcName(FindNum, 'MoneyToString') then
          Begin
            ResultStr:=FunctionParams[1];
            If Length(FunctionParams)>2 then
              If FunctionParams[2]<>'' then
                ResultStr:=FunctionParams[1]+'.'+FunctionParams[2];
            ResultStr:=MoneyToString(StrToFloatEx(ResultStr), True, False);
          End
          else if CompareProcName(FindNum, 'ByIndex') then
          Begin
            ResultStr:='';
            For i:=2 to FunctionParamsCount do
            Begin
              ResultStr:=ResultStr+FunctionParams[i]+',';
            End;
            ResultStr:=GetParam(ResultStr, StrToInt(FunctionParams[1]));
          End
          else if CompareProcName(FindNum, 'Count') then
          Begin
            ResultStr:=IntToStr(Length(FunctionParams)-1);
          End
          else if CompareProcName(FindNum, 'IndexOf') then
          Begin
            ResultStr:='';
            for i:=2 to FunctionParamsCount do
            begin
              If LowerCase(Trim(FunctionParams[1]))=LowerCase(Trim(FunctionParams[i])) then
              Begin
                ResultStr:=IntToStr(i-1);
                Break;
              End;
            end;
          End
          else if CompareProcName(FindNum, 'ReadConfig') then
          Begin
            DCLConfig:=TDCLConfigTable.Create(FDBConnector);
            ResultStr:=DCLConfig.ReadConfig(FunctionParams[1], '');
            FreeAndNil(DCLConfig);
          End
          else if CompareProcName(FindNum, 'WriteConfig') then
          Begin
            DCLConfig:=TDCLConfigTable.Create(FDBConnector);
            DCLConfig.WriteConfig(FunctionParams[1], FunctionParams[2], '');
            FreeAndNil(DCLConfig);
            ResultStr:='';
          End
          else if CompareProcName(FindNum, 'NVL') then
          Begin
            If FunctionParamsCount=2 Then
            If Assigned(Query) then
            If Query.Active then
              If GetFieldFromParam(FunctionParams[1], Query)<>nil then
              Begin
                If GetFieldFromParam(FunctionParams[1], Query).IsNull then
                  ResultStr:=FunctionParams[2]
                Else
                  ResultStr:=GetFieldFromParam(FunctionParams[1], Query).AsString;
              End;
          End
          else if CompareProcName(FindNum, 'iif') then
          Begin
            If FunctionParamsCount=3 then
            Begin
              if ParseLogicalExpression(FunctionParams[1]) then
                ResultStr:=FunctionParams[2]
              else
                ResultStr:=FunctionParams[3];
            End;
          End
          else if CompareProcName(FindNum, 'GetTempFileName') then
          Begin
            ResultStr:=GetTempFileName(FunctionParams[1]);
          End
          else if CompareProcName(FindNum, 'DaysInMonth') then
          Begin
            ResultStr:=IntToStr(DaysInAMonth(StrToInt(FunctionParams[2]), StrToInt(FunctionParams[1])));
          End
          else if CompareProcName(FindNum, 'GetMonthName') then
          Begin
            ResultStr:=FunctionParams[1];
            pv1:=StrToIntEx(ResultStr);
            If ((pv1>0) and (pv1<13)) then
              ResultStr:=GetLacalaizedMonthName(pv1);
          End
          else if CompareProcName(FindNum, 'LeadingZero') then
          Begin
            ResultStr:=FunctionParams[1];
            If StrToInt(FunctionParams[2])>0 then
            Begin
              If Length(ResultStr)<StrToInt(FunctionParams[2]) then
                For pv1:=1 to StrToInt(FunctionParams[2]) do
                  ResultStr:='0'+ResultStr;
            End
            Else
            Begin
              If Length(ResultStr)>1 then
              begin
                pv1:=1;
                For i:=1 to Length(ResultStr) do
                begin
                  if ResultStr[i]='0' then
                    inc(pv1)
                  else
                    break;
                end;
                if pv1<=Length(ResultStr) then
                  ResultStr:=Copy(ResultStr, pv1, Length(ResultStr))
                else
                  ResultStr:='';
              end;
            End;
          End
          else if CompareProcName(FindNum, 'GetAccessLevelByName') then
          Begin
            ResultStr:=IntToStr(Ord(TranslateDigitToUserLevel(FunctionParams[1])));
          End
          else if CompareProcName(FindNum, 'MonthByDate') then
          Begin
            ResultStr:=FunctionParams[1];
            try
              pv1:=MonthOf(StrToDate(ResultStr));
              If ((pv1>0) and (pv1<13)) then
                ResultStr:=GetLacalaizedMonthName(pv1);
            Except
              ResultStr:='';
            End;
          End
          else if CompareProcName(FindNum, 'Upper') then
          Begin
            ResultStr:=UTF8UpperCase(FunctionParams[1]);
          End
          else if CompareProcName(FindNum, 'Lower') then
          Begin
            ResultStr:=UTF8LowerCase(FunctionParams[1]);
          End
          else if CompareProcName(FindNum, 'MD5File') then
          Begin
            If FileExists(FunctionParams[1]) then
            Begin
              ResultStr:=MD5File(FunctionParams[1]);
            End;
          End
          else if CompareProcName(FindNum, 'MD5String') then
          Begin
            ResultStr:=MD5String(FunctionParams[1]);
          End
          else if CompareProcName(FindNum, 'YearOf') then
          Begin
            ResultStr:=IntToStr(YearOf(StrToDate(FunctionParams[1])));
          End
          else if CompareProcName(FindNum, 'MonthOf') then
          begin
            ResultStr:=IntToStr(MonthOf(StrToDate(FunctionParams[1])));
          end
          else if CompareProcName(FindNum, 'DayOf') then
          begin
            ResultStr:=IntToStr(DayOf(StrToDate(FunctionParams[1])));
          end
          else if CompareProcName(FindNum, 'Trim') then
          begin
            If FunctionParamsCount=1 Then
            Begin
              ResultStr:=UTF8Trim(FunctionParams[1]);
            End
            Else
            If (FunctionParamsCount=2) and (FunctionParams[2]<>'') Then
            Begin
              pv1:=1;
              for i:=1 to UTF8Length(FunctionParams[1]) do
              begin
                if FunctionParams[1][i]=UTF8Trim(FunctionParams[2])[1] then
                begin
                  inc(pv1);
                end
                else
                  break;
              end;

              pv3:=UTF8Length(FunctionParams[1]);
              for i:=UTF8Length(FunctionParams[1]) downto 1 do
              begin
                if FunctionParams[1][i]=Trim(FunctionParams[2])[1] then
                begin
                  dec(pv3);
                end
                else
                  break;
              end;

              if pv1<=pv3 then
                ResultStr:=Copy(FunctionParams[1], pv1, pv3-pv1+1);
            End;
          end
          else if CompareProcName(FindNum, 'TrimLeft') then
          begin
            If FunctionParamsCount=1 Then
            Begin
              ResultStr:=UTF8Trim(FunctionParams[1], [u8tKeepEnd]);
            End
            Else
            If (FunctionParamsCount=2) and (FunctionParams[2]<>'') Then
            Begin
              pv1:=1;
              for i:=1 to Length(FunctionParams[1]) do
              begin
                if FunctionParams[1][i]=Trim(FunctionParams[2])[1] then
                begin
                  inc(pv1);
                end
                else
                  break;
              end;

              pv3:=Length(FunctionParams[1]);
              if pv1<=pv3 then
                ResultStr:=Copy(FunctionParams[1], pv1, pv3-pv1+1);
            End;
          end
          else if CompareProcName(FindNum, 'TrimRight') then
          begin
            If FunctionParamsCount=1 Then
            Begin
              ResultStr:=UTF8Trim(FunctionParams[1], [u8tKeepStart]);
            End
            Else
            If (FunctionParamsCount=2) and (FunctionParams[2]<>'') Then
            Begin
              pv1:=1;
              pv3:=UTF8Length(FunctionParams[1]);
              for i:=UTF8Length(FunctionParams[1]) downto 1 do
              begin
                if FunctionParams[1][i]=Trim(FunctionParams[2])[1] then
                begin
                  dec(pv3);
                end
                else
                  break;
              end;

              if pv1<=pv3 then
                ResultStr:=Copy(FunctionParams[1], pv1, pv3-pv1+1);
            End;
          end;

          Delete(Params, P, MaxLength+Length(ProcPrefix)+1+(EndPos-pv2));
          Insert(GetClearParam(ResultStr), Params, P);
        End;
      end;
    end;
  end;
end;

procedure TDCLValuseParser.TranslateVals(var Params: String;
  Query: TDCLDialogQuery; CheckParams: Boolean);
begin
  ReplaceAllVariables(FNameSpace, Params, Query);
  if CheckParams and Assigned(Query) then
    RePlaseParams(Params, Query);
  RePlaceProc(Params, Query);
end;

procedure TDCLValuseParser.SetConnector(DBConnector: TDCLDBConnector);
begin
  FDBConnector:=DBConnector;
end;

end.

