unit uDCLValuesParser;
{$mode Delphi}

interface

uses
  Classes, SysUtils, DateUtils,
  uDCLConst, uDCLData, uDCLTypes, uDCLVariables, uStringParams, SumProps,
  uDCLMD5, uDCLDBConnector;

type

  { TDCLValuseParser }

  TDCLValuseParser = class
  private
    FNameSpace: String;
    FVariables: TVariables;
    FDBConnector: TDCLDBConnector;

    procedure ReplaseSysVars(var ValueSet: String; Query: TDCLDialogQuery);
  public
    constructor Create(NameSpace: String; Variables: TVariables); overload;

    procedure RePlaseParams(var Params: String; Query: TDCLDialogQuery);
    procedure RePlaseVariables(const Namespace: String; var ValueSet: String; Query: TDCLDialogQuery);
    procedure RePlaceProc(var Params: String; Var Factor: Integer; Query: TDCLDialogQuery);

    procedure TranslateVals(var Params: String; Query: TDCLDialogQuery; CheckParams: Boolean);

    procedure SetConnector(DBConnector: TDCLDBConnector);
  end;

implementation

uses
  DB, uDCLDBStructure, uDCLUtils, uSystemUtils, uDCLMultiLang, uDBUtils,
  uDCLDBUtils, uDCLGlobalVariables, uDCLVersion, uDCLConfigTable,
  uExpressionParser;

const
  MaxSysVars=49;
  SysVarsSet: Array [1..MaxSysVars] of String=('_TIME_', '_TIMES_', '_DATE_', '_DATETIME_', // 4
    '_VERSION_', '_ISEMPTY_', '_DCLTABLE_', '_DCLNAMEFIELD_', '_DCLTEXTFIELD_', '_IDENTIFYFIELD_',
    // 10
    '_PARENTFLGFIELD_', '_COMMANDFIELD_', '_USERNAME_', '_PASSWORD_', '_ALIAS_', '_STRINGTYPECHAR_',
    // 16
    '_ROLENAME_', '_ROLEID_', '_ROLESTABLE_', '_ROLESMENU_', '_USERPASS_', '_LONGROLENAME_', // 22
    '_FOB_', '_EOB_', '_VALUESEPARATOR_', '_FULLVERSION_', '_APPPATH_', '_CURRENTSTRING_', // 28
    '_ENGINETYPE_', '_APPNAME_', '_DCL_USER_NAME_', '_DCL_USERS_TABLE_', '_USERID_', // 33
    '_USERNAMEACCESSLEVELS_', '_USERGLOBALACCESSLEVEL_', '_USERACCESSLEVEL_', '_NOTIFYACTIONS_',
    // 37
    '_YESNO_', '_EVALFORMULA_', '_DSSTATE_', '_DSSTATENAME_', '_FULLRAIGHTS_', '_ROLEACCESSLEVEL_',
    // 43
    '_APPDATAPATH_', '_OS_', '_MAC_', '_USERPROFILE_', '_USERDOC_', '_DCLINI_'); // 49

  ProcCount=26;
  ProcNames: Array [1..ProcCount] Of String=('ConvertOraDates', 'ConvertToOraDates', 'ToFloat', // 3
    'ConvertToAccessDate', 'DeleteNonFilesSimb', 'GetFileNameToTranslite', 'ExtractFileName', // 7
    'MoneyToString', 'ByIndex', 'Count', 'IndexOf', 'ReadConfig', 'WriteConfig', 'NVL', 'iif', // 15
    'GetTempFileName', 'DaysInMonth', 'GetMonthName', 'LeadingZero', 'GetAccessLevelByName', // 20
    'MonthByDate', 'Upper', 'Lower', 'MD5File', 'MD5String', 'Eval'); // 26

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
            begin
              Value:=TimeToStr(SysUtils.Time);
              If (Value[5]=':') Then
                SetLength(Value, 4);
              If (Value[6]=':') Then
                SetLength(Value, 5);
            end;
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
            Value:=DCLTable;
            8:
            Value:=DCLNameField;
            9:
            Value:=ScriptField;
            10:
            Value:=IdentifyField;
            11:
            Value:=ParentField;
            12:
            Value:=CommandField;
            13:
            Value:=GPT.DBUserName;
            14:
            Value:=GPT.DBPassword;
            16:
            Value:=GPT.StringTypeChar;
            17:
            Value:=GPT.DCLRoleName;
            18:
            Value:=GPT.RoleID;
            19:
            Value:=RolesTable;
            20:
            Value:=RolesMenuTable;
            21:
            Value:=GPT.DCLUserPass;
            22:
            Value:=GPT.LongRoleName;
            23:
            begin
              if Assigned(Query) then
              begin
                If Query.Bof Then
                  Value:='1'
                Else
                  Value:='0';
              end;
            end;
            24:
            begin
              if Assigned(Query) then
              begin
                If Query.Eof Then
                  Value:='1'
                Else
                  Value:='0';
              end;
            end;
            25:
            Value:=GPT.GetValueSeparator;
            26:
            Value:=DCLVersion;
            27:
            Value:=ExcludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
            28:
            Value:=IntToStr(GPT.CurrentRunningScrString);
            29:
            Value:=DBEngineType;
            30:
            Value:=ExtractFileName(ParamStr(0));  // '_APPNAME_'
            31:
            Value:=GPT.DCLUserName;
            32:
            Value:=UsersTable;
            33:
            Value:=GPT.UserID;
            34:
            Value:=GetDCLMessageString(msAccessLevelsSet);
            35:
            Value:=IntToStr(Ord(GPT.AccessLevel));
            {36:
            Value:=IntToStr(Ord(FDCLForm.UserLevelLocal));}
            37:
            Value:=GetDCLMessageString(msNotifyActionsSet);
            38:
            Value:=GetDCLMessageString(msNoYes);
            {39:
            Value:=FDCLLogOn.EvalFormula;}
            40:begin
              if Assigned(Query) then
                Value:=IntToStr(Ord(Query.State));
            end;
            41:
            Value:=GetNameDSState(Query.State);
            {42:
            Value:=IntToStr(FDCLLogOn.RoleRaightsLevel);
            43:
            Value:=IntToStr(FDCLLogOn.GetFullRaight);}
            44:
            Value:=ExcludeTrailingPathDelimiter(AppConfigDir);
            45:
            Value:=OSType;
            46:
            Value:='';
            47:
            Value:=UserProfileDir; // '_USERPROFILE_'
            48:
            Value:=GetUserDocumentsDir; // '_USERDOC_'
            49:
            Value:=GPT.IniFileName; // _DCLINI_
            end;

            Delete(ValueSet, Pos, Length(LastVariable)+Length(VariablePrefix));
            Insert(Value, ValueSet, Pos);
          end;
        end;
      end;
    end;
  end;
end;

constructor TDCLValuseParser.Create(NameSpace: String; Variables: TVariables);
begin
  FNameSpace:=NameSpace;
  FVariables:=Variables;
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
  var ValueSet: String; Query: TDCLDialogQuery);
var
  Pos, MaxLength: Integer;
  LastVariable, Variable, Variable2: TVariable;
begin
  if Assigned(FVariables) then
  begin
    for Variable in FVariables.VariablesList do
    begin
      while PosEx(VariablePrefix+Variable.Name, ValueSet)<>0 do
      begin
        Pos:=PosEx(VariablePrefix+Variable.Name, ValueSet);

        if Pos<>0 then
        begin
          MaxLength:=0;
          LastVariable:=nil;
          for Variable2 in FVariables.VariablesList do
          begin
            if ((Namespace=Variable2.NameSpace) or (Variable2.NameSpace='')) and (MaxLength<Length(Variable2.Name)) and (PosEx(VariablePrefix+Variable2.Name, ValueSet)<>0) then
            begin
              Pos:=PosEx(VariablePrefix+Variable2.Name, ValueSet);
              LastVariable:=Variable2;
              MaxLength:=Length(Variable2.Name);
            end;
          end;

          if Assigned(LastVariable) then
          begin
            Delete(ValueSet, Pos, MaxLength+Length(VariablePrefix));
            Insert(LastVariable.Value, ValueSet, Pos);
          end;
        end;
      end;
    end;
  end;

  ReplaseSysVars(ValueSet, Query);
end;

procedure TDCLValuseParser.RePlaceProc(var Params: String; var Factor: Integer;
  Query: TDCLDialogQuery);
var
  Proc, Proc2, ResultStr, ProcParams: String;
  Pos, MaxLength, i, FindNum, Skobki, pv1, pv2, EndPos, ParamLen: Integer;
  FunctionParams: Array Of String;
  FunctionParamsCount: Byte;
  DCLConfig: TDCLConfigTable;
Begin
  Inc(Factor);
  ParamLen:=Length(Params);
  for Proc in ProcNames do
  begin
    while PosEx(ProcPrefix+Proc, Params)<>0 do
    begin
      Pos:=PosEx(ProcPrefix+Proc, Params);

      if Pos<>0 then
      begin
        MaxLength:=0;
        FindNum:=-1;
        for i:=1 to Length(ProcNames) do
        begin
          Proc2:=ProcNames[i];
          if (MaxLength<Length(Proc2)) and (PosEx(ProcPrefix+Proc2, Params)<>0) then
          begin
            Pos:=PosEx(ProcPrefix+Proc2, Params);
            FindNum:=i;
            MaxLength:=Length(Proc2);
          end;
        end;

        if FindNum<>-1 then
        begin
          pv1:=Pos;
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
          RePlaceProc(ProcParams, Factor, Query);

          FunctionParamsCount:=ParamsCount(ProcParams);
          SetLength(FunctionParams, FunctionParamsCount+1);
          FunctionParams[0]:=ProcNames[FindNum];
          For pv1:=1 To FunctionParamsCount Do
          Begin
            FunctionParams[pv1]:=GetParam(ProcParams, pv1);
            // RePlaseVariables(FunctionParams[pv1]);
          End;

          Case FindNum Of
          // ConvertOraDates
          1:
          Begin
            ResultStr:=Copy(FunctionParams[1], 9, 2)+'.'+Copy(FunctionParams[1], 6, 2)+'.'+
              Copy(FunctionParams[1], 1, 4);
          End;

          // ConvertToOraDates
          2:
          Begin
            ResultStr:=Copy(FunctionParams[1], 7, 4)+'-'+Copy(FunctionParams[1], 4, 2)+'-'+
              Copy(FunctionParams[1], 1, 2)+' 00:00:00';
          End;

          // tofloat
          3:
          Begin
            //Trim(FunctionParams[1]);
            if PosEx('.', FunctionParams[1])=0 then
              ResultStr:=FunctionParams[1]+'.00'
            Else
            Begin
              ResultStr:=Copy(FunctionParams[1], PosEx('.', FunctionParams[1])+1,
                Length(FunctionParams[1])-PosEx('.', FunctionParams[1])+1);
              If Length(ResultStr)=1 Then
                ResultStr:=ResultStr+'0'
              Else
                ResultStr:=FunctionParams[1];
            End;
          End;

          // ConvertToAccessDate
          4:
          Begin
            If PosEx('.', FunctionParams[1])<>0 Then
              ResultStr:=Copy(FunctionParams[1], 4, 2)+'/'+Copy(FunctionParams[1], 1, 2)+'/'+
                Copy(FunctionParams[1], 7, 4)
            Else
              ResultStr:=FunctionParams[1];
          End;

          // deletenonfilessimb
          5:
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
          End;

          // GetFileNameToTranslite
          6:
          Begin
            ResultStr:=GetFileNameToTranslite(FunctionParams[1]);
          End;

          // ExtractFileName
          7:
          Begin
            ResultStr:=ExtractFileName(FunctionParams[1]);
          End;

          // SumWrite
          8:
          Begin
            ResultStr:=FunctionParams[1];
            If Length(FunctionParams)>2 then
              If FunctionParams[2]<>'' then
                ResultStr:=FunctionParams[1]+'.'+FunctionParams[2];
            ResultStr:=MoneyToString(StrToFloatEx(ResultStr), True, False);
          End;

          // ByIndex
          9:
          Begin
            ResultStr:='';
            For i:=2 to FunctionParamsCount do
            Begin
              ResultStr:=ResultStr+FunctionParams[i]+',';
            End;
            ResultStr:=GetParam(ResultStr, StrToInt(FunctionParams[1]));
          End;

          // Count
          10:
          Begin
            ResultStr:=IntToStr(ParamsCount(FunctionParams[1]));
          End;

          // IndexOf
          11:
          Begin
            ResultStr:='';
            for i:=2 to FunctionParamsCount do
            begin
              If LowerCase(Trim(FunctionParams[1]))=LowerCase(Trim(FunctionParams[i])) then
              Begin
                ResultStr:=IntToStr(i);
                Break;
              End;
            end;
          End;

          12: // ReadConfig
          Begin
            DCLConfig:=TDCLConfigTable.Create(FDBConnector);
            ResultStr:=DCLConfig.ReadConfig(FunctionParams[1], '');
            FreeAndNil(DCLConfig);
          End;

          13: // WriteConfig
          Begin
            DCLConfig:=TDCLConfigTable.Create(FDBConnector);
            DCLConfig.WriteConfig(FunctionParams[1], FunctionParams[2], '');
            FreeAndNil(DCLConfig);
            ResultStr:='';
          End;

          14: // NVL
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
          End;

          15: // iif
          Begin
            If FunctionParamsCount=3 then
            Begin
              if ParseLogicalExpression(FunctionParams[1]) then
                ResultStr:=FunctionParams[2]
              else
                ResultStr:=FunctionParams[3];
            End;
          End;
          16: // GetTempFileName
          Begin
            ResultStr:=GetTempFileName(FunctionParams[1]);
          End;
          17: // DaysInMonth
          Begin
            ResultStr:=IntToStr(DaysInAMonth(StrToInt(FunctionParams[2]), StrToInt(FunctionParams[1])));
          End;
          18: // GetMonthName
          Begin
            ResultStr:=FunctionParams[1];
            pv1:=StrToIntEx(ResultStr);
            If ((pv1>0) and (pv1<13)) then
              ResultStr:=GetLacalaizedMonthName(pv1);
          End;
          19: // LeadingZero
          Begin
            ResultStr:=FunctionParams[1];
            If StrToInt(FunctionParams[2])>0 then
            Begin
              If Length(ResultStr)<StrToInt(FunctionParams[2]) then
                For pv1:=1 to StrToInt(FunctionParams[2]) do
                  ResultStr:='0'+ResultStr;
            End;
          End;
          20: // GetAccessLevelByName
          Begin
            ResultStr:=IntToStr(Ord(TranslateDigitToUserLevel(FunctionParams[1])));
          End;
          21: // MonthByDate
          Begin
            ResultStr:=FunctionParams[1];
            try
              pv1:=MonthOf(StrToDate(ResultStr));
              If ((pv1>0) and (pv1<13)) then
                ResultStr:=GetLacalaizedMonthName(pv1);
            Except
              ResultStr:='';
            End;
          End;
          22:
          Begin
            ResultStr:=AnsiUpperCase(FunctionParams[1]);
          End;
          23:
          Begin
            ResultStr:=AnsiLowerCase(FunctionParams[1]);
          End;
          24:Begin
            If FileExists(FunctionParams[1]) then
            Begin
              ResultStr:=MD5File(FunctionParams[1]);
            End;
          End;
          25:Begin
            ResultStr:=MD5String(FunctionParams[1]);
          End;
          26:Begin // Eval
            ResultStr:='';;
          End;
          End;

          Delete(Params, Pos, MaxLength+Length(ProcPrefix)+1+(EndPos-pv2));
          Insert(GetClearParam(ResultStr), Params, Pos);
        End;
      end;
    end;
  end;
  Dec(Factor);
end;

procedure TDCLValuseParser.TranslateVals(var Params: String;
  Query: TDCLDialogQuery; CheckParams: Boolean);
var
  Factor: Integer;
begin
  RePlaseVariables(FNameSpace, Params, Query);
  if CheckParams and Assigned(Query) then
    RePlaseParams(Params, Query);
  Factor:=0;
  RePlaceProc(Params, Factor, Query);
end;

procedure TDCLValuseParser.SetConnector(DBConnector: TDCLDBConnector);
begin
  FDBConnector:=DBConnector;
end;

end.

