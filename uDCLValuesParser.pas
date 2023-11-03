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
  public
    constructor Create(NameSpace: String; Variables: TVariables); overload;

    procedure RePlaseParams(var Params: String; Query: TDCLDialogQuery);
    procedure RePlaseVariables(const Namespace: String; var Value: String; Query: TDCLDialogQuery);
    procedure RePlaceProc(var Params: String; Var Factor: Integer; Query: TDCLDialogQuery);

    procedure TranslateVals(var Params: String; Query: TDCLDialogQuery; CheckParams: Boolean);

    procedure SetConnector(DBConnector: TDCLDBConnector);
  end;

implementation

uses
  uDCLDBStructure, uDCLUtils, uSystemUtils, uDateTimeHelper, uDCLMultiLang,
  uDBUtils, uDCLDBUtils, uDCLGlobalVariables, uDCLVersion, uDCLConfigTable,
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

  ProcCount=27;
  ProcNames: Array [1..ProcCount] Of String=('ConvertOraDates', 'ConvertToOraDates', 'ToFloat', // 3
    'ConvertToAccessDate', 'DeleteNonFilesSimb', 'GetFileNameToTranslite', 'ExtractFileName', // 7
    'MoneyToString', 'ByIndex', 'Count', 'IndexOf', 'ReadConfig', 'WriteConfig', 'NVL', 'iif', // 15
    'GetTempFileName', 'DaysInAMonth', 'GetMonthName', 'LeadingZero', 'GetAccessLevelByName', // 20
    'DaysInMonth', 'MonthByDate', 'Upper', 'Lower', 'MD5File', 'MD5String', 'Eval'); // 27

{ TDCLValuseParser }

constructor TDCLValuseParser.Create(NameSpace: String; Variables: TVariables);
begin
  FNameSpace:=NameSpace;
  FVariables:=Variables;
end;

procedure TDCLValuseParser.RePlaseParams(var Params: String; Query: TDCLDialogQuery);
Var
  ReplaseField, TmpStr, FieldNameLoc: String;
  StartSel, ParamLen, StartSearch, pv1, pv2, pv3, VarNameLength, MaxMatch: Word;
  FindParNum: Integer;
  FindVar: Boolean;
Begin
  If Assigned(Query) Then
    If (Query.FieldCount>0)And Query.Active Then
      If TransParams Then
      Begin
        StartSearch:=Pos(ParamPrefix, Params);
        While Pos(ParamPrefix, Copy(Params, StartSearch, Length(Params)))<>0 Do
        Begin
          StartSearch:=StartSearch+Pos(ParamPrefix, Copy(Params, StartSearch, Length(Params)))-1;
          StartSel:=StartSearch+Length(ParamPrefix)-1;
          ParamLen:=Length(Params);
          If ParamLen<>0 Then
          Begin
            pv3:=0;
            FindParNum:=-1;
            MaxMatch:=0;

            While (Query.FieldCount-1>=pv3) Do
            Begin
              FindVar:=True;
              pv2:=1;
              pv1:=StartSel+1;
              While (FindVar)And(pv1<=ParamLen)And(pv2<=Length(Query.Fields[pv3].FieldName)) Do
              Begin
                FindVar:=False;
                If Length(Query.Fields[pv3].FieldName)>=pv2 Then
                Begin
                  FieldNameLoc:=Query.Fields[pv3].FieldName;
                  If UpperCase(Params[pv1])=UpperCase(FieldNameLoc[pv2]) Then
                  Begin
                    FindVar:=True;
                    If MaxMatch<pv1 Then
                    Begin
                      MaxMatch:=pv1;
                      FindParNum:=pv3;
                    End;
                  End;
                End;
                Inc(pv1);
                Inc(pv2);
              End;
              Inc(pv3);
            End;

            If FindParNum<>-1 Then
            Begin
              VarNameLength:=MaxMatch-StartSel;
              ReplaseField:=Copy(Params, StartSel+1, VarNameLength);
            End
            Else
            Begin
              VarNameLength:=0;
              ReplaseField:='';
            End;

            If FieldExists(ReplaseField, Query) Then
            Begin
              Delete(Params, StartSel, VarNameLength+1);
              TmpStr:=TrimRight(Query.FieldByName(ReplaseField).AsString);
              Insert(TmpStr, Params, StartSel);
              Inc(StartSearch, Length(TmpStr)+Length(ParamPrefix));
              TmpStr:='';
            End
            Else
              Inc(StartSearch, Length(ParamPrefix)+0);
          End;
        End;
      End;
end;

procedure TDCLValuseParser.RePlaseVariables(const Namespace: String;
  var Value: String; Query: TDCLDialogQuery);
var
  ReplaseVar, TmpStr: String;
  StartSel, ParamLen, StartSearch, pv1, pv2, sysVarI, VarNameLength, MaxMatch, FindSysVarNum: Integer;
  VarExists, SysVar, FindVar: Boolean;
  FindVarNum, variable: TVariable;
begin
  StartSearch:=Pos(VariablePrefix, Value);
  While Pos(VariablePrefix, Copy(Value, StartSearch, Length(Value)))<>0 do
  begin
    StartSearch:=StartSearch+Pos(VariablePrefix, Copy(Value, StartSearch,
        Length(Value)))-1;
    StartSel:=StartSearch+Length(VariablePrefix)-1;
    ParamLen:=Length(Value);
    SysVar:=False;
    If ParamLen<>0 Then
    begin
      FindVarNum:=nil;
      MaxMatch:=0;

      if Assigned(FVariables) then
      begin
        for variable in FVariables.VariablesList do
        begin
          FindVar:=True;
          pv2:=1;
          pv1:=StartSel+1;
          While (FindVar)and(pv1<=ParamLen)and(pv2<=Length(variable.Name)) do
          begin
            FindVar:=False;
            If Length(variable.Name)>=pv2 Then
            begin
              If ((Namespace=variable.NameSpace) or (Namespace='')) and (UpperCase(Value[pv1])=UpperCase(variable.Name[pv2])) Then
              begin
                FindVar:=True;
                If MaxMatch<pv1 Then
                begin
                  MaxMatch:=pv1;
                  FindVarNum:=variable;
                end;
              end;
            end;
            inc(pv1);
            inc(pv2);
          end;
        end;
      end;

      FindSysVarNum:=-1;
      If not Assigned(FindVarNum) Then
      begin
        sysVarI:=1;
        While (MaxSysVars>=sysVarI) do
        begin
          FindVar:=True;
          pv2:=1;
          pv1:=StartSel+1;
          While (FindVar)and(pv1<=ParamLen)and(pv2<=Length(SysVarsSet[sysVarI])) do
          begin
            FindVar:=False;
            If Length(SysVarsSet[sysVarI])>=pv2 Then
            begin
              If UpperCase(Value[pv1])=UpperCase(SysVarsSet[sysVarI][pv2]) Then
              begin
                FindVar:=True;
                If MaxMatch<pv1 Then
                begin
                  MaxMatch:=pv1;
                  FindSysVarNum:=sysVarI;
                  SysVar:=True;
                end;
              end;
            end;
            inc(pv1);
            inc(pv2);
          end;
          inc(sysVarI);
        end;
      end;

      If Assigned(FindVarNum) Then
      begin
        VarNameLength:=MaxMatch-StartSel;
        ReplaseVar:=Copy(Value, StartSel+1, VarNameLength);
      end
      Else
      begin
        VarNameLength:=0;
        ReplaseVar:='';
      end;

      If FindSysVarNum<>-1 Then
      begin
        Case FindSysVarNum of
        1:
        begin
          TmpStr:=TimeToStr_(SysUtils.Time);
          If (TmpStr[5]=':') Then
            SetLength(TmpStr, 4);
          If (TmpStr[6]=':') Then
            SetLength(TmpStr, 5);
        end;
        2:
        TmpStr:=TimeToStr_(SysUtils.Time);
        3:
        TmpStr:=DateToStr_(Date);
        4:
        TmpStr:=TimeStampToStr(Now);
        5:
        TmpStr:=DCLVersion;
        6:
        begin
          if Assigned(Query) then
          begin
            If (Query.Eof and Query.Bof) Then
              TmpStr:='1'
            Else
              TmpStr:='0';
          end;
        end;
        7:
        TmpStr:=DCLTable;
        8:
        TmpStr:=DCLNameField;
        9:
        TmpStr:=ScriptField;
        10:
        TmpStr:=IdentifyField;
        11:
        TmpStr:=ParentField;
        12:
        TmpStr:=CommandField;
        13:
        TmpStr:=GPT.DBUserName;
        14:
        TmpStr:=GPT.DBPassword;
        16:
        TmpStr:=GPT.StringTypeChar;
        17:
        TmpStr:=GPT.DCLRoleName;
        18:
        TmpStr:=GPT.RoleID;
        19:
        TmpStr:=RolesTable;
        20:
        TmpStr:=RolesMenuTable;
        21:
        TmpStr:=GPT.DCLUserPass;
        22:
        TmpStr:=GPT.LongRoleName;
        23:
        begin
          if Assigned(Query) then
          begin
            If Query.Bof Then
              TmpStr:='1'
            Else
              TmpStr:='0';
          end;
        end;
        24:
        begin
          if Assigned(Query) then
          begin
            If Query.Eof Then
              TmpStr:='1'
            Else
              TmpStr:='0';
          end;
        end;
        25:
        TmpStr:=GPT.GetValueSeparator;
        26:
        TmpStr:=DCLVersion;
        27:
        TmpStr:=ExcludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
        28:
        TmpStr:=IntToStr(GPT.CurrentRunningScrString);
        29:
        TmpStr:=DBEngineType;
        30:
        TmpStr:=ExtractFileName(ParamStr(0));  // '_APPNAME_'
        31:
        TmpStr:=GPT.DCLUserName;
        32:
        TmpStr:=UsersTable;
        33:
        TmpStr:=GPT.UserID;
        34:
        TmpStr:=GetDCLMessageString(msAccessLevelsSet);
        35:
        TmpStr:=IntToStr(Ord(GPT.AccessLevel));
        {36:
        TmpStr:=IntToStr(Ord(FDCLForm.UserLevelLocal));}
        37:
        TmpStr:=GetDCLMessageString(msNotifyActionsSet);
        38:
        TmpStr:=GetDCLMessageString(msNoYes);
        {39:
        TmpStr:=FDCLLogOn.EvalFormula;}
        40:begin
          if Assigned(Query) then
            TmpStr:=IntToStr(Ord(Query.State));
        end;
        41:
        TmpStr:=GetNameDSState(Query.State);
        {42:
        TmpStr:=IntToStr(FDCLLogOn.RoleRaightsLevel);
        43:
        TmpStr:=IntToStr(FDCLLogOn.GetFullRaight);}
        44:
        TmpStr:=ExcludeTrailingPathDelimiter(AppConfigDir);
        45:
        TmpStr:=OSType;
        46:
        TmpStr:='';
        47:
        TmpStr:=UserProfileDir; // '_USERPROFILE_'
        48:
        TmpStr:=GetUserDocumentsDir; // '_USERDOC_'
        49:
        TmpStr:=GPT.IniFileName; // _DCLINI_
        end;

        VarNameLength:=Length(SysVarsSet[FindSysVarNum]);
      end;

      if Assigned(FVariables) then
        VarExists:=FVariables.Exists(FNamespace, ReplaseVar);
      If SysVar Then
      begin
        VarExists:=True;
      end;

      If VarExists Then
      begin
        Delete(Value, StartSel, VarNameLength+Length(VariablePrefix));
        if Assigned(FVariables) then
          If Not SysVar Then
            TmpStr:=FVariables.Variables[Namespace, ReplaseVar];
        Insert(TmpStr, Value, StartSel);
        inc(StartSearch, Length(TmpStr)+Length(VariablePrefix));
        TmpStr:='';
      end
      Else
        inc(StartSearch, Length(VariablePrefix)+1);
    end;
  end;
end;

procedure TDCLValuseParser.RePlaceProc(var Params: String; var Factor: Integer;
  Query: TDCLDialogQuery);
var
  ReplaseProc, Param, ResultStr, TmpStr2: String;
  StartSel, ParamLen, StartSearch, pv1, pv2, pv3, pv4, FindProcNum, Skobki, VarNameLength,
    MaxMatch: Word;
  FindVar: Boolean;
  FunctionParams: Array Of String;
  FunctionParamsCount: Byte;
  DCLConfig: TDCLConfigTable;
Begin
  Inc(Factor);
  StartSearch:=Pos(ProcPrefix, Params);
  While Pos(ProcPrefix, Copy(Params, StartSearch, Length(Params)))<>0 Do
  Begin
    StartSearch:=StartSearch+Pos(ProcPrefix, Copy(Params, StartSearch, Length(Params)))-1;
    StartSel:=StartSearch+Length(ProcPrefix);

    ParamLen:=Length(Params);
    If ParamLen<>0 Then
    Begin
      pv3:=1;
      FindProcNum:=0;
      MaxMatch:=0;

      While (ProcCount>=pv3) Do
      Begin
        FindVar:=True;
        pv2:=1;
        pv1:=StartSel;
        While (FindVar)And(pv1<=ParamLen)And(pv2<=Length(ProcNames[pv3])) Do
        Begin
          FindVar:=False;
          If Length(ProcNames[pv3])>=pv2 Then
          Begin
            If UpperCase(Params[pv1])=UpperCase(ProcNames[pv3][pv2]) Then
            Begin
              FindVar:=True;
              If MaxMatch<pv1 Then
              Begin
                MaxMatch:=pv1;
                FindProcNum:=pv3;
              End;
            End;
          End;
          Inc(pv1);
          Inc(pv2);
        End;
        Inc(pv3);
      End;

      If FindProcNum<>0 Then
      Begin
        VarNameLength:=MaxMatch-StartSel+1;
        ReplaseProc:=Copy(Params, StartSel, VarNameLength);
        pv2:=1;
        FindVar:=False;
        While (pv2<=ProcCount)And(FindVar=False) Do
        Begin
          If UpperCase(ReplaseProc)=UpperCase(ProcNames[pv2]) Then
          Begin
            FindVar:=True;
            FindProcNum:=pv2;
          End;
          Inc(pv2);
        End;
        If FindVar Then
        Begin
          Dec(StartSel, Length(ProcPrefix));
          Delete(Params, StartSel, Length(ProcPrefix));
          Dec(MaxMatch, Length(ProcPrefix));
        End;
      End
      Else
      Begin
        VarNameLength:=0;
        ReplaseProc:='';
      End;

      pv1:=MaxMatch;

      Skobki:=0;
      Repeat
        If Params[pv1]='(' Then
          Skobki:=1;
        Inc(pv1);
      Until (Params[pv1]<>'(')And(ParamLen+1>=pv1);
      pv2:=pv1;

      While (Skobki<>0)And(pv1<=ParamLen) Do
      Begin
        If Params[pv1]=')' Then
          Dec(Skobki)
        Else If Params[pv1]='(' Then
          Inc(Skobki);

        Inc(pv1);
      End;
      MaxMatch:=pv1;

      Param:=Copy(Params, pv2, pv1-pv2-1);
      RePlaceProc(Param, Factor, Query);

      FunctionParamsCount:=ParamsCount(Param);
      SetLength(FunctionParams, FunctionParamsCount+1);
      FunctionParams[0]:=ProcNames[FindProcNum];
      For pv1:=1 To FunctionParamsCount Do
      Begin
        FunctionParams[pv1]:=GetParam(Param, pv1);
        // RePlaseVariables(FunctionParams[pv1]);
      End;

      If Skobki=0 Then
        Case FindProcNum Of
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
          Trim(FunctionParams[1]);
          If Pos('.', FunctionParams[1])=0 Then
            ResultStr:=FunctionParams[1]+'.00'
          Else
          Begin
            ResultStr:=Copy(FunctionParams[1], Pos('.', FunctionParams[1])+1,
              Length(FunctionParams[1])-Pos('.', FunctionParams[1])+1);
            If Length(ResultStr)=1 Then
              ResultStr:=ResultStr+'0'
            Else
              ResultStr:=FunctionParams[1];
          End;
        End;

        // ConvertToAccessDate
        4:
        Begin
          If Pos('.', FunctionParams[1])<>0 Then
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
            { (FunctionParams[1][ParamLen]='&') or } (FunctionParams[1][ParamLen]='>') Or
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
          TmpStr2:=FunctionParams[1];
          If Length(FunctionParams)>2 then
            If FunctionParams[2]<>'' then
              TmpStr2:=FunctionParams[1]+'.'+FunctionParams[2];
          ResultStr:=MoneyToString(StrToFloatEx(TmpStr2), True, False);
        End;

        // ByIndex
        9:
        Begin
          TmpStr2:='';
          For pv3:=2 To FunctionParamsCount Do
          Begin
            TmpStr2:=TmpStr2+FunctionParams[pv3]+',';
          End;
          ResultStr:=GetParam(TmpStr2, StrToInt(FunctionParams[1]));
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
          pv4:=0;
          For pv3:=2 To FunctionParamsCount Do
          Begin
            pv2:=ParamsCount(FunctionParams[pv3]);
            For pv1:=1 To pv2 Do
            Begin
              If AnsiLowerCase(FunctionParams[1])
                =AnsiLowerCase(GetParam(FunctionParams[pv3], pv1)) Then
              Begin
                ResultStr:=IntToStr(pv1+pv4);
                Break;
              End;
            End;
            Inc(pv4, pv2);
          End;
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
        17, 21: // DaysInMonth
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
        22: // MonthByDate
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
        23:
        Begin
          ResultStr:=AnsiUpperCase(FunctionParams[1]);
        End;
        24:
        Begin
          ResultStr:=AnsiLowerCase(FunctionParams[1]);
        End;
        25:Begin
          If FileExists(FunctionParams[1]) then
          Begin
            ResultStr:=MD5File(FunctionParams[1]);
          End;
        End;
        26:Begin
          ResultStr:=MD5String(FunctionParams[1]);
        End;
        27:Begin // Eval
          ///ResultStr:=Calculate(FunctionParams[1]);
        End;
        End;

      Delete(Params, StartSel, MaxMatch-StartSel);
//      If Factor=1 then
      Insert(GetClearParam(ResultStr), Params, StartSel);
//      Else Insert(ResultStr, CallProc, StartSel);

      Inc(StartSearch, Length(ResultStr)+1);
    End;
  End;
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

