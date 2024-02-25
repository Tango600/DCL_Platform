unit uRunProgram;
{$mode delphi}

interface

uses
  LCLIntf, Classes, Process, SysUtils;

  procedure Run(Command, Param: String; Wait: Boolean);
  procedure OpenFile(DocumentFileName: String);
  procedure OpenWeb(URL: String);

implementation

procedure CommandLineToList(var S: TProcessString; List: TProcessStrings);

  function GetNextWord: TProcessString;
  const
    WhiteSpace=[' ',#9,#10,#13];
    Literals=['"',''''];
  var
    Wstart, wend: Integer;
    InLiteral: Boolean;
    LastLiteral: TProcessChar;
  begin
    WStart:=1;
    While (WStart<=Length(S)) and charinset(S[WStart], WhiteSpace) do
      Inc(WStart);

    WEnd:=WStart;
    InLiteral:=False;
    LastLiteral:=#0;
    While (Wend<=Length(S)) and (Not charinset(S[Wend], WhiteSpace) or InLiteral) do
    begin
      if charinset(S[Wend], Literals) then
      begin
        If InLiteral then
          InLiteral:=not (S[Wend]=LastLiteral)
        else
        begin
          InLiteral:=True;
          LastLiteral:=S[Wend];
        end;
      end;
      inc(wend);
    end;

    Result:=Copy(S, WStart, WEnd-WStart);

    if (Length(Result) > 0)
      and (Result[1] = Result[Length(Result)]) // if 1st char = last char and..
      and (Result[1] in Literals) then // it's one of the literals, then
        Result:=Copy(Result, 2, Length(Result)-2); //delete the 2 (but not others in it)

    While (WEnd<=Length(S)) and (S[Wend] in WhiteSpace) do
      inc(Wend);
    Delete(S, 1, WEnd-1);
  end;

var
  W: TProcessString;
begin
  While Length(S)>0 do
  begin
    W:=GetNextWord;
    If W<>'' then
      List.Add(W);
  end;
end;

procedure Run(Command, Param: String; Wait: Boolean);
var
  Proc: TProcess;
  C, P: TProcessString;
  Params: TStringList;
begin
  Params:=TStringList.Create;

  C:=Command;
  CommandLineToList(C, Params);

  P:=Param;
  CommandLineToList(P, Params);

  if Params.Count>0 then
  begin
    Proc:=TProcess.Create(nil);
    Proc.Executable:=Params[0];
    Params.Delete(0);

    if P<>'' then
    begin
      Params.Append(P);
    end;
    Proc.Parameters:=Params;
    If Wait then
      Proc.Options:=Proc.Options+[poWaitOnExit, poUsePipes];

    Proc.Execute;
    FreeAndNil(Proc);
  end;
  FreeAndNil(Params);
end;

procedure OpenFile(DocumentFileName: String);
begin
  OpenDocument(DocumentFileName);
end;

procedure OpenWeb(URL: String);
begin
  OpenURL(URL);
end;

end.

