unit uStringParams;

interface

uses
  SysUtils, uStringUtils;

const
  DefaultParamsSeparator=';';
  DefaultValuesSeparator=',';
  DefaultParamDelim='"';

Function FindParam(const KeyWord, StrParam: String): String;
Function GetParam(const ParamsSet: String; ParamNo: Integer;
  SeparateChar: String=DefaultValuesSeparator; ParamDelim: String=DefaultParamDelim): String;
Function ParamsCount(const ParamsSet: String; SeparateChar: String=DefaultValuesSeparator;
  ParamDelim: String=DefaultParamDelim): Integer;
Function GetClearParam(const Param: String; ParamDelim: String=DefaultParamDelim): String;
Function IndexInSet(const SetValue, S: String; const SepChar: String=DefaultValuesSeparator;
  const Delim: String=DefaultParamDelim): Integer;

Function DoublingApostrof(const S: String): String;

function IsLexem(const Lexem, S: String): Boolean;

function FindWholeWord(const Example, S: String): Integer;

implementation

const
  StopSimbols=';( )[],=\/+-^<>.%:;&$#@*'#39#10#13;

function IsLexem(const Lexem, S: String): Boolean;
var
  p: Integer;
  t: String;
begin
  Result:=False;
  t:=Trim(S);
  p:=Pos(LowerCase(Lexem), LowerCase(t));
  if p=1 then
    Result:=True
  else
  begin
    if p>1 then
    begin
      if Pos(t[p-1], StopSimbols)<>0 then
        Result:=True;
    end;
  end;
end;

function FindWholeWord(const Example, S: String): Integer;
var
  p, l, el: Integer;
begin
  Result:=0;
  l:=Length(S);
  el:=Length(Example);
  p:=PosEx(Example, S);
  if p>0 then
  begin
    if p+el-1=l then
    begin
      if p=1 then
        Result:=p
      else
      begin
        if Pos(S[p-1], StopSimbols)<>0 then
          Result:=p;
      end;
    end
    else
    begin
      if p+el-1<l then
      begin
        if Pos(S[p+el], StopSimbols)<>0 then
        begin
          if (p=1) or (Pos(S[p-1], StopSimbols)<>0) then
            Result:=p;
        end;
      end;
    end;
  end;
end;

Function FindParam(const KeyWord, StrParam: String): String;
var
  Start, EndStr, lp, StartPos: Integer;
  vStrParam: String;
  Find, StorkeShodow:Boolean;
begin
  Result:='';
  StartPos:=1;
  Find:=False;
  vStrParam:=DefaultParamsSeparator+StrParam+DefaultParamsSeparator;
  Start:=PosEx(KeyWord, Copy(vStrParam, StartPos, Length(vStrParam)));
  If Start<>0 then
  begin
    Repeat
      Result:='';
      Start:=PosEx(KeyWord, Copy(vStrParam, StartPos, Length(vStrParam)));
      If Start<>0 then
      If Pos(vStrParam[Start-2+StartPos], StopSimbols)<>0 then
      Begin
        StorkeShodow:=False;
        lp:=Length(vStrParam);
        EndStr:=Start+StartPos-1+Length(KeyWord);
        While (vStrParam[EndStr]<>DefaultParamsSeparator) or StorkeShodow do
        begin
          if EndStr-1=lp then
            break;
          Result:=Result+vStrParam[EndStr];

          if StorkeShodow and (vStrParam[EndStr]='''') then
            StorkeShodow:=False
          else
            if not StorkeShodow and (vStrParam[EndStr]='''') then
              StorkeShodow:=True;

          Inc(EndStr);
        end;
        Find:=True;
      End;
      Inc(StartPos);
    Until (Find) or (StartPos>Length(vStrParam));
  end;
end;

Function ParamsCount(const ParamsSet: String; SeparateChar: String=DefaultValuesSeparator;
  ParamDelim: String=DefaultParamDelim): Integer;
var
  DelimLeft, DelimRight: Char;
  pices: Array of String;
begin
  if ParamDelim='' then
    ParamDelim:=DefaultParamDelim;

  if Length(ParamDelim)=2 then
  begin
    DelimLeft:=ParamDelim[1];
    DelimRight:=ParamDelim[2];
  end
  Else
  begin
    DelimLeft:=ParamDelim[1];
    DelimRight:=ParamDelim[1];
  end;

  if SeparateChar='' then
    SeparateChar:=DefaultValuesSeparator;

  pices:=ParamsSet.Split(SeparateChar, DelimLeft, DelimRight, 0, TStringSplitOptions.None);
  Result:=Length(pices);
end;

Function GetClearParam(const Param: String; ParamDelim: String=DefaultParamDelim): String;
var
  DelimLeft, DelimRight: Char;
begin
  if Length(ParamDelim)=2 then
  begin
    DelimLeft:=ParamDelim[1];
    DelimRight:=ParamDelim[2];
  end
  Else
  begin
    DelimLeft:=ParamDelim[1];
    DelimRight:=ParamDelim[1];
  end;
  Result:=Param;
  if Length(Param)>=2 then
    if (Param[1]=DelimLeft)and(Param[Length(Param)]=DelimRight) then
      Result:=Copy(Param, 2, Length(Param)-2)
    Else
      Result:=Param;
end;

Function GetParam(const ParamsSet: String; ParamNo: Integer;
  SeparateChar: String=DefaultValuesSeparator; ParamDelim: String=DefaultParamDelim): String;
var
  l: Integer;
  DelimLeft, DelimRight: Char;
  pices: Array of String;
begin
  if ParamsSet='' then
  Begin
    Result:='';
    Exit;
  End;

  If ParamNo=0 then
  Begin
    Result:='';
    Exit;
  End;

  if ParamDelim='' then
    ParamDelim:=DefaultParamDelim;

  if Length(ParamDelim)=2 then
  begin
    DelimLeft:=ParamDelim[1];
    DelimRight:=ParamDelim[2];
  end
  Else
  begin
    DelimLeft:=ParamDelim[1];
    DelimRight:=ParamDelim[1];
  end;

  if SeparateChar='' then
    SeparateChar:=DefaultValuesSeparator;

  pices:=ParamsSet.Split(SeparateChar, DelimLeft, DelimRight, ParamNo, TStringSplitOptions.None);
  l:=Length(pices);
  Result:=pices[l-1];
end;

Function IndexInSet(const SetValue, S: String; const SepChar: String=DefaultValuesSeparator;
  const Delim: String=DefaultParamDelim): Integer;
var
  p, i: Cardinal;
  ps: String;
Begin
  Result:=0;
  p:=ParamsCount(SetValue, SepChar, Delim);
  If p>0 then
  Begin
    For i:=1 to p do
    Begin
      ps:=GetParam(SetValue, i, SepChar, Delim);
      If LowerCase(Trim(ps))=LowerCase(Trim(S)) then
      begin
        Result:=i;
        Exit;
      end;
    End;
  End;
End;

Function DoublingApostrof(const S: String): String;
var
  i, l:Integer;
begin
  Result:='';
  l:=Length(S);
  For i:=1 to l do
  begin
    Result:=Result+S[i];
    If S[i]=#39 then
      Result:=Result+#39;
  end;
end;

end.
