unit uStringParams;

interface

uses
{$IFDEF FPC}
  LConvEncoding,
{$IFDEF UNIX}
  cwstring,
{$ENDIF}
{$ENDIF}
  SysUtils;

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
Function PosEx(const SubStr, S: String): Cardinal;
function Any(const StrSet, S: String): Boolean;
Function InitCap(const S: String): String;
function NormalizeCase(const S: String): String;
Function TrimSymbols(S: String; TrimS: String): String;
Function IndexInSet(SetValue, S: String; SepChar: String=DefaultValuesSeparator;
  Delim: String=DefaultParamDelim): Integer;
function TrimChars(CharsSet, S:string):String;

Function DoublingApostrof(const S: String):String;
Function DCLStringEquals(S1, S2: String): Boolean;

function IsLexem(const Lexem, S: String): Boolean;

function FindWholeWord(const Example, S: String): Integer;

implementation

const
  StopSimbols=';( )[],=\/+-^<>.%:;&$#@*'#39#10#13;

function IsLexem(const Lexem, S: String): Boolean;
var
  t: String;
begin
  t:=Trim(S);
  Result:=Pos(LowerCase(Lexem), LowerCase(t))=1;
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

Function DCLStringEquals(S1, S2: String): Boolean;
Begin
  Result:=LowerCase(S1)=LowerCase(S2);
End;

function NormalizeCase(const S: String): String;
var
  tmp: String;
  l, i: Integer;
  nextUpper: Boolean;
begin
  Result:='';
  if Length(S)>0 then
  begin
    l:=Length(S);
    tmp:=UpperCase(S[1]);
    if l>1 then
    begin
      nextUpper:=False;
      for i:=2 to l do
      begin
        if S[i]='_' then
        begin
          nextUpper:=True;
          tmp:=tmp+' ';
        end
        else
        begin
          if nextUpper then
            tmp:=tmp+UpperCase(S[i])
          else
            tmp:=tmp+LowerCase(S[i]);

          nextUpper:=False;
        end;
      end;
    end;
    Result:=tmp;
  end;
end;

Function TrimSymbols(S: String; TrimS: String): String;
var
  i: Cardinal;
begin
  for i:=Length(S) downto 1 do
    if Pos(S[i], TrimS)<>0 then
      Delete(S, i, 1);

  Result:=S;
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

Function PosEx(const SubStr, S: String): Cardinal;
begin
  Result:=Pos(LowerCase(SubStr), LowerCase(S));
end;

function Any(const StrSet, S: String): Boolean;
var
  c: Char;
begin
  Result:=False;
  if Length(StrSet)>0 then
  begin
    for c in StrSet do
    begin
      if PosEx(c, S)<>0 then
      begin
        Result:=True;
        break;
      end;
    end;
  end;
end;

Function InitCap(const S: String): String;
begin
  if S<>'' then
    Result:=UpperCase(S[1])+Copy(S, 2, Length(S)-1)
  Else
    Result:='';
end;

Function IndexInSet(SetValue, S: String; SepChar: String=DefaultValuesSeparator;
  Delim: String=DefaultParamDelim): Integer;
var
  p, i, Pos: Cardinal;
  ps: String;
Begin
  Result:=0;
  p:=ParamsCount(SetValue, SepChar, Delim);
  If p>0 then
  Begin
    For i:=1 to p do
    Begin
      Pos:=0;
      ps:=GetParam(SetValue, i, SepChar, Delim);
      If LowerCase(Trim(ps))=LowerCase(Trim(S)) then
      begin
        Result:=i;
        Exit;
      end;
    End;
  End;
End;

function TrimChars(CharsSet, S:string):String;
var
  i:Integer;
begin
  Result:='';
  For i:=1 to Length(S) do
  Begin
    If PosEx(S[i], CharsSet)=0 then
      Result:=Result+S[i];
  End;
end;

Function DoublingApostrof(const S: String):String;
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
