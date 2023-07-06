unit uDCLDBUtils;
{$I DefineType.pas}

interface

uses
  SysUtils, DB,
  uDCLConst, uDCLData, uStringParams, uDCLMultiLang;

Function GetNameDSState(State: TDataSetState): String;

implementation

Function GetNameDSState(State: TDataSetState): String;
Const
  StatesCount=12;
Var
  DataSetStateNames: Array [0..StatesCount] Of String;
  StatesSet:String;
  i:Integer;
Begin
  StatesSet:=GetDCLMessageString(msDSStateSet);
  For i:=1 to ParamsCount(GetDCLMessageString(msDSStateSet), ',') do
  Begin
    DataSetStateNames[i-1]:=GetParam(StatesSet, i, ',');
  End;
  Result:=DataSetStateNames[Ord(State)];
End;

end.
