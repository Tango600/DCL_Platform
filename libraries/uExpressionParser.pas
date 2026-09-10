unit uExpressionParser;
{$mode Delphi}

interface

uses
  Classes, SysUtils, Generics.Collections,
  uDCLConst;

type
  { TCondition }

  TCondition=class
    FieldNameLeft: String;
    ConditionType: TConditionTypes;
    Values: TList<String>;
    ItemCondition: TPairCondition;

    constructor Create;
  end;

 function ParseLogicalExpression(const S: String): Boolean;
 function LogicalParser(S: String): TList<TCondition>;
 function CalcLogicalExpression(var Conditions: TList<TCondition>): Boolean;
 function CompareNumbersOrStrings(const ValueLeft, ValueRight: String; ConditionType: TConditionTypes): Boolean;

implementation

uses
   uStringParams, uStringUtils, uDCLUtils;

function LogicalParser(S: String): TList<TCondition>;
var
  LeftMode, RightMode, NotExists, InString: Boolean;
  LeftSide, RightSide: String;
  p, l, i: Integer;
  ConditionType: TConditionTypes;
  ConditionItem: TCondition;
  LastConditionPair: TPairCondition;
begin
  Result:=TList<TCondition>.Create;
  LastConditionPair:=pcNone;

  S:=S+'&';
  LeftMode:=True;
  RightMode:=False;
  InString:=False;
  NotExists:=False;
  LeftSide:='';
  l:=Length(S);
  p:=1;
  ConditionType:=ctND;
  RightSide:='';
  while p<=l do
  begin
    if S[p]='(' then
    begin
      LeftMode:=False;
      RightMode:=True;
    end
    else
    if S[p]=')' then
    begin
      if NotExists then
        ConditionType:=ctNotIn
      else
        ConditionType:=ctIn;
      LeftMode:=False;
      RightMode:=False;
    end
    else
    if S[p]='[' then
    begin
      LeftMode:=False;
      RightMode:=True;
    end
    else
    if S[p]=']' then
    begin
      if NotExists then
        ConditionType:=ctNotBt
      else
        ConditionType:=ctBt;
      LeftMode:=False;
      RightMode:=False;
    end
    else
    if S[p]='=' then
    begin
      if NotExists then
        ConditionType:=ctNotEq
      else
        ConditionType:=ctEq;
      LeftMode:=False;
      RightMode:=True;
    end
    else
    if S[p]='<' then
    begin
      ConditionType:=ctLe;
      LeftMode:=False;
      RightMode:=True;

      if S[p+1]='=' then
      begin
        ConditionType:=ctLeEq;
        Inc(p);
      end;
      if S[p+1]='>' then
      begin
        ConditionType:=ctNotEq;
        Inc(p);
      end;
    end
    else
    if S[p]='>' then
    begin
      ConditionType:=ctGt;
      LeftMode:=False;
      RightMode:=True;

      if S[p+1]='=' then
      begin
        ConditionType:=ctGtEq;
        Inc(p);
      end;
    end
    else
    if S[p] in ['&', '|'] then
    begin
      ConditionItem:=TCondition.Create;
      ConditionItem.FieldNameLeft:=LeftSide;
      ConditionItem.ConditionType:=ConditionType;

      case ConditionType of
      ctEq, ctNotEq, ctGt, ctGtEq, ctLe, ctLeEq: begin
        ConditionItem.Values.Add(GetClearParam(RightSide, ''''));
      end;
      ctBt, ctNotBt, ctNotIn, ctIn: begin
        for i:=1 to ParamsCount(RightSide) do
        begin
          ConditionItem.Values.Add(GetClearParam(GetParam(RightSide, i), ''''));
        end;
      end;
      end;

      ConditionItem.ItemCondition:=LastConditionPair;

      Result.Add(ConditionItem);

      LeftMode:=True;
      RightMode:=False;
      LeftSide:='';
      RightSide:='';
      ConditionType:=ctND;
      NotExists:=False;

      if S[p]='&' then
        LastConditionPair:=pcAnd;
      if S[p]='|' then
        LastConditionPair:=pcOr;
    end
    else
    begin
      if S[p]='!' then
      begin
        if LeftMode then
        begin
          if not InString then
          begin
            LeftMode:=False;
            NotExists:=True;
          end;
        end;
      end;

      if (S[p]<>' ') or InString then
      begin
        if LeftMode then
        begin
          LeftSide:=LeftSide+S[p];
        end
        else
        if RightMode then
        begin
          RightSide:=RightSide+S[p];
        end;
      end;

      if S[p]='''' then
      begin
        InString:=not InString;
      end;
    end;

    inc(p);
  end;
end;

function GetPairCondition(ItemCondition: TPairCondition; CurrResult, LastResult: Boolean): Boolean;
begin
  case ItemCondition of
  pcNone: begin
    Result:=CurrResult;
  end;
  pcAnd: begin
    Result:=LastResult and CurrResult;
  end;
  pcOr: begin
    Result:=LastResult or CurrResult;
  end;
  end;
end;

function CalcLogicalExpression(var Conditions: TList<TCondition>): Boolean;
var
  CondItem: TCondition;
  S: String;
  LastResult, LocalResult: Boolean;
begin
  LastResult:=True;
  for CondItem in Conditions do
  begin
    if CondItem.Values.Count>0 then
    begin
      case CondItem.ConditionType of
      ctEq: begin
        LastResult:=GetPairCondition(CondItem.ItemCondition, CompareNumbersOrStrings(CondItem.FieldNameLeft, CondItem.Values[0], CondItem.ConditionType), LastResult);
      end;
      ctNotEq: begin
        LastResult:=GetPairCondition(CondItem.ItemCondition, CompareNumbersOrStrings(CondItem.FieldNameLeft, CondItem.Values[0], CondItem.ConditionType), LastResult);
      end;
      ctGt: begin
        LastResult:=GetPairCondition(CondItem.ItemCondition, CompareNumbersOrStrings(CondItem.FieldNameLeft, CondItem.Values[0], CondItem.ConditionType), LastResult);
      end;
      ctGtEq: begin
        LastResult:=GetPairCondition(CondItem.ItemCondition, CompareNumbersOrStrings(CondItem.FieldNameLeft, CondItem.Values[0], CondItem.ConditionType), LastResult);
      end;
      ctLe: begin
        LastResult:=GetPairCondition(CondItem.ItemCondition, CompareNumbersOrStrings(CondItem.FieldNameLeft, CondItem.Values[0], CondItem.ConditionType), LastResult);
      end;
      ctLeEq: begin
        LastResult:=GetPairCondition(CondItem.ItemCondition, CompareNumbersOrStrings(CondItem.FieldNameLeft, CondItem.Values[0], CondItem.ConditionType), LastResult);
      end;
      ctBt, ctNotBt: begin
        case CondItem.ConditionType of
        ctBt: begin
          if CondItem.Values.Count=2 then
          begin
            LastResult:=GetPairCondition(CondItem.ItemCondition, CompareNumbersOrStrings(CondItem.FieldNameLeft, CondItem.Values[0], ctGtEq) and CompareNumbersOrStrings(CondItem.FieldNameLeft, CondItem.Values[1], ctLeEq), LastResult);
          end
          else
            LastResult:=GetPairCondition(CondItem.ItemCondition, False, LastResult);
        end;
        ctNotBt: begin
          if CondItem.Values.Count=2 then
          begin
            LastResult:=GetPairCondition(CondItem.ItemCondition, not CompareNumbersOrStrings(CondItem.FieldNameLeft, CondItem.Values[0], ctGtEq) and CompareNumbersOrStrings(CondItem.FieldNameLeft, CondItem.Values[1], ctLeEq), LastResult);
          end
          else
            LastResult:=GetPairCondition(CondItem.ItemCondition, False, LastResult);
        end;
        end;
      end;
      ctNotIn, ctIn: begin
        LocalResult:=CondItem.ConditionType=ctNotIn;
        for S in CondItem.Values do
        begin
          if CompareNumbersOrStrings(S, CondItem.FieldNameLeft, ctEq) then
          begin
            LocalResult:=CondItem.ConditionType=ctIn;
            break;
          end;
        end;
        LastResult:=GetPairCondition(CondItem.ItemCondition, LocalResult, LastResult);
      end;
      end;
    end
    else
    begin
      LastResult:=GetPairCondition(CondItem.ItemCondition, True, LastResult);
    end;
  end;

  Result:=LastResult;
end;

function CompareNumbersOrStrings(const ValueLeft, ValueRight: String;
  ConditionType: TConditionTypes): Boolean;
var
  LeftValueType, RightValueType: TIsDigitType;
  i1, i2: LongInt;
  r1, r2: Real;
begin
  Result:=True;
  LeftValueType:=GetStringDataType(ValueLeft);
  RightValueType:=GetStringDataType(ValueRight);

  if (LeftValueType=idDigit) and (RightValueType=idDigit) then
  begin
    if TryStrToInt(ValueLeft, i1) and TryStrToInt(ValueRight, i2) then
    begin
      case ConditionType of
      ctEq: begin
        Result:=i1=i2;
      end;
      ctNotEq: begin
        Result:=i1<>i2;
      end;
      ctGt: begin
        Result:=i1>i2;
      end;
      ctGtEq: begin
        Result:=i1>=i2;
      end;
      ctLe: begin
        Result:=i1<i2;
      end;
      ctLeEq: begin
        Result:=i1<=i2;
      end;
      end;

      Exit;
    end;
  end;

  if (LeftValueType=idFloatDigit) and (RightValueType=idFloatDigit) then
  begin
    if TryStrToFloat(ValueLeft, r1) and TryStrToFloat(ValueRight, r2) then
    begin
      case ConditionType of
      ctEq: begin
        Result:=r1=r2;
      end;
      ctNotEq: begin
        Result:=r1<>r2;
      end;
      ctGt: begin
        Result:=r1>r2;
      end;
      ctGtEq: begin
        Result:=r1>=r2;
      end;
      ctLe: begin
        Result:=r1<r2;
      end;
      ctLeEq: begin
        Result:=r1<=r2;
      end;
      end;

      Exit;
    end;
  end;

  case ConditionType of
  ctEq: begin
    Result:=DCLCompareStrings(ValueLeft, ValueRight)=0;
  end;
  ctNotEq: begin
    Result:=DCLCompareStrings(ValueLeft, ValueRight)<>0;
  end;
  ctGt: begin
    Result:=DCLCompareStrings(ValueLeft, ValueRight)=-1;
  end;
  ctGtEq: begin
    Result:=DCLCompareStrings(ValueLeft, ValueRight)<=0;
  end;
  ctLe: begin
    Result:=DCLCompareStrings(ValueLeft, ValueRight)=1;
  end;
  ctLeEq: begin
    Result:=DCLCompareStrings(ValueLeft, ValueRight)>=0;
  end;
  end;
end;

function ParseLogicalExpression(const S: String): Boolean;
var
  Conds: TList<TCondition>;
begin
  Conds:=LogicalParser(S);
  Result:=CalcLogicalExpression(Conds);
end;

{ TCondition }

constructor TCondition.Create;
begin
  Values:=TList<String>.Create;
end;

end.
