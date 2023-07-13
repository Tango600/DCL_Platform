unit uDCLValuesParser;
{$I DefineType.pas}

interface

uses
  Classes, SysUtils, StrUtils, DateUtils,
  uDCLConst, uDCLData, uDCLTypes, uDCLVariables, uStringParams, SumProps,
  uDCLMD5;

type

  { TDCLValuseParser }

  TDCLValuseParser = class
  private
    FNameSpace: String;
    FVariables: TVariables;
  public
    constructor Create(NameSpace: String; Variables: TVariables); overload;

    procedure RePlaseParams(var Params: String; Query: TDCLDialogQuery);
    procedure RePlaseVariables(const Namespace: String; var Value: String; Query: TDCLDialogQuery);
    procedure RePlaceProc(var Params: String; Var Factor: Integer; Query: TDCLDialogQuery);

    procedure TranslateVals(var Params: String; Query: TDCLDialogQuery; CheckParams: Boolean);
  end;

implementation

uses
  uDCLDBStructure, uDCLUtils, uSystemUtils, uDateTimeHelper, uDCLMultiLang,
  uDBUtils, uDCLDBUtils, uDCLGlobalVariables;

const
  MaxSysVars=50;
  SysVarsSet: Array [1..MaxSysVars] of String=('_TIME_', '_TIMES_', '_DATE_', '_DATETIME_', // 4
    '_VERSION_', '_ISEMPTY_', '_DCLTABLE_', '_DCLNAMEFIELD_', '_DCLTEXTFIELD_', '_IDENTIFYFIELD_',
    // 10
    '_PARENTFLGFIELD_', '_COMMANDFIELD_', '_USERNAME_', '_PASSWORD_', '_ALIAS_', '_STRINGTYPECHAR_',
    // 16
    '_ROLENAME_', '_ROLEID_', '_ROLESTABLE_', '_ROLESMENU_', '_USERPASS_', '_LONGROLENAME_', // 22
    '_FOB_', '_EOB_', '_VALUESEPARATOR_', '_FULLVERSION_', '_APPPATH_', '_CURRENTSTRING_', // 28
    '_ENGINETYPE_', '_SCRIPTRESULT_', '_DCL_USER_NAME_', '_DCL_USERS_TABLE_', '_USERID_', // 33
    '_USERNAMEACCESSLEVELS_', '_USERGLOBALACCESSLEVEL_', '_USERACCESSLEVEL_', '_NOTIFYACTIONS_',
    // 37
    '_YESNO_', '_EVALFORMULA_', '_DSSTATE_', '_DSSTATENAME_', '_FULLRAIGHTS_', '_ROLEACCESSLEVEL_',
    // 43
    '_APPDATAPATH_', '_OS_', '_MAC_', '_USERPROFILE_', '_USERDOC_', '_DCLINI_', '_APPNAME_'); // 50

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
        TmpStr:=Version;
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
        TmpStr:=Version;
        27:
        TmpStr:=ExcludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
        28:
        TmpStr:=IntToStr(GPT.CurrentRunningScrString);
        29:
        TmpStr:=DBEngineType;
        30:
        TmpStr:=EvalResultScript;
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
        50:
        TmpStr:=ApplicationName;  // '_APPNAME_'
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
  ReplaseProc, Param, TmpStr, TmpStr2, TmpStr3: String;
  StartSel, ParamLen, StartSearch, pv1, pv2, pv3, pv4, FindProcNum, Skobki, VarNameLength,
    MaxMatch: Word;
  FindVar: Boolean;
  FunctionParams: Array Of String;
  FunctionParamsCount: Byte;
  Sign:TSign;
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
          TmpStr:=Copy(FunctionParams[1], 9, 2)+'.'+Copy(FunctionParams[1], 6, 2)+'.'+
            Copy(FunctionParams[1], 1, 4);
        End;

        // ConvertToOraDates
        2:
        Begin
          TmpStr:=Copy(FunctionParams[1], 7, 4)+'-'+Copy(FunctionParams[1], 4, 2)+'-'+
            Copy(FunctionParams[1], 1, 2)+' 00:00:00';
        End;

        // tofloat
        3:
        Begin
          Trim(FunctionParams[1]);
          If Pos('.', FunctionParams[1])=0 Then
            TmpStr:=FunctionParams[1]+'.00'
          Else
          Begin
            TmpStr:=Copy(FunctionParams[1], Pos('.', FunctionParams[1])+1,
              Length(FunctionParams[1])-Pos('.', FunctionParams[1])+1);
            If Length(TmpStr)=1 Then
              TmpStr:=TmpStr+'0'
            Else
              TmpStr:=FunctionParams[1];
          End;
        End;

        // ConvertToAccessDate
        4:
        Begin
          If Pos('.', FunctionParams[1])<>0 Then
            TmpStr:=Copy(FunctionParams[1], 4, 2)+'/'+Copy(FunctionParams[1], 1, 2)+'/'+
              Copy(FunctionParams[1], 7, 4)
          Else
            TmpStr:=FunctionParams[1];
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
          TmpStr:=FunctionParams[1];
        End;

        // GetFileNameToTranslite
        6:
        Begin
          TmpStr:=GetFileNameToTranslite(FunctionParams[1]);
        End;

        // ExtractFileName
        7:
        Begin
          TmpStr:=ExtractFileName(FunctionParams[1]);
        End;

        // SumWrite
        8:
        Begin
          TmpStr2:=FunctionParams[1];
          If Length(FunctionParams)>2 then
            If FunctionParams[2]<>'' then
              TmpStr2:=FunctionParams[1]+'.'+FunctionParams[2];
          TmpStr:=MoneyToString(StrToFloatEx(TmpStr2), True, False);
        End;

        // ByIndex
        9:
        Begin
          TmpStr2:='';
          For pv3:=2 To FunctionParamsCount Do
          Begin
            TmpStr2:=TmpStr2+FunctionParams[pv3]+',';
          End;
          TmpStr:=GetParam(TmpStr2, StrToInt(FunctionParams[1]));
        End;

        // Count
        10:
        Begin
          TmpStr:=IntToStr(ParamsCount(FunctionParams[1]));
        End;

        // IndexOf
        11:
        Begin
          TmpStr:='';
          pv4:=0;
          For pv3:=2 To FunctionParamsCount Do
          Begin
            pv2:=ParamsCount(FunctionParams[pv3]);
            For pv1:=1 To pv2 Do
            Begin
              If AnsiLowerCase(FunctionParams[1])
                =AnsiLowerCase(GetParam(FunctionParams[pv3], pv1)) Then
              Begin
                TmpStr:=IntToStr(pv1+pv4);
                Break;
              End;
            End;
            Inc(pv4, pv2);
          End;
        End;

        12: // ReadConfig
        Begin
          {If FunctionParamsCount=1 Then
            TmpStr:=DCLMainLogOn.ReadConfig(FunctionParams[1], '')
          Else
            TmpStr:=DCLMainLogOn.ReadConfig(FunctionParams[1], FunctionParams[2]);}
        End;

        13: // WriteConfig
        Begin
          {If FunctionParamsCount=2 Then
            DCLMainLogOn.WriteConfig(FunctionParams[1], FunctionParams[2], '')
          Else
            DCLMainLogOn.WriteConfig(FunctionParams[1], FunctionParams[2], FunctionParams[3]);}

          TmpStr:='';
        End;

        14: // NVL
        Begin
          If FunctionParamsCount=2 Then
          If Assigned(Query) then
          If Query.Active then
            If GetFieldFromParam(FunctionParams[1], Query)<>nil then
            Begin
              If GetFieldFromParam(FunctionParams[1], Query).IsNull then
                TmpStr:=FunctionParams[2]
              Else
                TmpStr:=GetFieldFromParam(FunctionParams[1], Query).AsString;
            End;
        End;

        15: // iif
        Begin
          If FunctionParamsCount=3 Then
          Begin
            pv1:=LastDelimiter('<>=', FunctionParams[1]);
            If pv1<>0 then
            Begin
              Sign:=TSign(AnsiIndexStr(FunctionParams[1], Signs));

              pv1:=Pos(Signs[Sign], FunctionParams[1]);
              pv2:=Length(Signs[Sign]);
              TmpStr2:=Copy(FunctionParams[1], 1, pv1-1);
              TmpStr3:=Copy(FunctionParams[1], pv1+pv2+1, Length(FunctionParams[1]));
              TmpStr2:=Trim(AnsiLowerCase(TmpStr2));
              TmpStr3:=Trim(AnsiLowerCase(TmpStr3));

              If Sign=sEquals then
              Begin
                If TmpStr2=TmpStr3 then
                  TmpStr:=FunctionParams[2]
                Else
                  TmpStr:=FunctionParams[3];
              End
              Else If Sign=sLess then
              Begin
                If TmpStr2>TmpStr3 then
                  TmpStr:=FunctionParams[2]
                Else
                  TmpStr:=FunctionParams[3];
              End
              Else If Sign=sGreater then
              Begin
                If TmpStr2<TmpStr3 then
                  TmpStr:=FunctionParams[2]
                Else
                  TmpStr:=FunctionParams[3];
              End
              Else If Sign=sNotEqual then
              Begin
                If TmpStr2<>TmpStr3 then
                  TmpStr:=FunctionParams[2]
                Else
                  TmpStr:=FunctionParams[3];
              End
              Else If Sign=sGreaterEq then
              Begin
                If TmpStr2<=TmpStr3 then
                  TmpStr:=FunctionParams[2]
                Else
                  TmpStr:=FunctionParams[3];
              End
              Else If Sign=sLessEq then
              Begin
                If TmpStr2>=TmpStr3 then
                  TmpStr:=FunctionParams[2]
                Else
                  TmpStr:=FunctionParams[3];
              End;
            End;
          End;
        End;
        16: // GetTempFileName
        Begin
          TmpStr:=GetTempFileName(FunctionParams[1]);
        End;
        17, 21: // DaysInMonth
        Begin
          TmpStr:=IntToStr(DaysInAMonth(StrToInt(FunctionParams[2]), StrToInt(FunctionParams[1])));
        End;
        18: // GetMonthName
        Begin
          tmpStr:=FunctionParams[1];
          pv1:=StrToIntEx(tmpStr);
          If ((pv1>0) and (pv1<13)) then
            TmpStr:=GetLacalaizedMonthName(pv1);
        End;
        19: // LeadingZero
        Begin
          TmpStr:=FunctionParams[1];
          If StrToInt(FunctionParams[2])>0 then
          Begin
            If Length(TmpStr)<StrToInt(FunctionParams[2]) then
              For pv1:=1 to StrToInt(FunctionParams[2]) do
                TmpStr:='0'+TmpStr;
          End;
        End;
        20: // GetAccessLevelByName
        Begin
          TmpStr:=IntToStr(Ord(TranslateDigitToUserLevel(FunctionParams[1])));
        End;
        22: // MonthByDate
        Begin
          tmpStr:=FunctionParams[1];
          try
            pv1:=MonthOf(StrToDate(tmpStr));
            If ((pv1>0) and (pv1<13)) then
              TmpStr:=GetLacalaizedMonthName(pv1);
          Except
            TmpStr:='';
          End;
        End;
        23:
        Begin
          TmpStr:=AnsiUpperCase(FunctionParams[1]);
        End;
        24:
        Begin
          TmpStr:=AnsiLowerCase(FunctionParams[1]);
        End;
        25:Begin
          If FileExists(FunctionParams[1]) then
          Begin
            TmpStr:=MD5File(FunctionParams[1]);
          End;
        End;
        26:Begin
          TmpStr:=MD5String(FunctionParams[1]);
        End;
        27:Begin // Eval
          ///TmpStr:=Calculate(FunctionParams[1]);
        End;
        End;

      Delete(Params, StartSel, MaxMatch-StartSel);
//      If Factor=1 then
      Insert(GetClearParam(TmpStr), Params, StartSel);
//      Else Insert(TmpStr, CallProc, StartSel);

      Inc(StartSearch, Length(TmpStr)+1);
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

end.

