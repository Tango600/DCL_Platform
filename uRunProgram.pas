unit uRunProgram;
{$I DefineType.pas}

interface

uses
{$IFDEF FPC}
  LCLIntf,
{$ENDIF}
{$IFnDEF FPC}
{$IFDEF MSWINDOWS}
  Windows, ShellApi, ShlObj,
{$ENDIF}
{$ENDIF}
  Classes, Process, SysUtils;

{$IFnDEF FPC}
type
  TProcessString=String;
  TProcessChar=char;
  TProcessStrings=TStringList;
{$ENDIF}

  procedure Run(Command, Param: String; Wait: Boolean);
  procedure OpenFile(DocumentFileName: String);

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
  P: TProcessString;
  Params: TStringList;
begin
  Params:=TStringList.Create;

  Proc:=TProcess.Create(nil);

  P:=Param;
  CommandLineToList(P, Params);

  if (Params.Count>0) and (Command='') then
  begin
    Proc.Executable:=Params[0];
    Params.Delete(0);
  end
  else
    Proc.Executable:=Command;

  if P<>'' then
  begin
    Params.Append(P);
  end;
  Proc.Parameters:=Params;
  If Wait then
    Proc.Options:=Proc.Options+[poWaitOnExit, poUsePipes];

  Proc.Execute;

  FreeAndNil(Params);
  FreeAndNil(Proc);
end;

{$IFnDEF FPC}
procedure ExecApp(const App: String; const CurrDir: String);
var
  SI: TStartupInfo;
  PI: TProcessInformation;
  CmdLine: String;
  cd:PChar;
begin
  Assert(App <> '');
  cd:=nil;

  CmdLine := App;
  UniqueString(CmdLine);

  FillChar(SI, SizeOf(SI), 0);
  FillChar(PI, SizeOf(PI), 0);
  SI.cb := SizeOf(SI);
  SI.dwFlags := STARTF_USESHOWWINDOW;
  SI.wShowWindow := SW_SHOWNORMAL;

  SetLastError(ERROR_INVALID_PARAMETER);
  if (CurrDir<>'') and FileExists(CurrDir) then
  begin
    cd:=PChar(CurrDir);
  end;

  {$WARN SYMBOL_PLATFORM OFF}
  Win32Check(CreateProcess(nil, PChar(CmdLine), nil, nil, False, CREATE_DEFAULT_ERROR_MODE {$IFDEF UNICODE}or CREATE_UNICODE_ENVIRONMENT{$ENDIF}, nil, cd, SI, PI));
  {$WARN SYMBOL_PLATFORM ON}
  CloseHandle(PI.hThread);
  CloseHandle(PI.hProcess);
end;
{$ENDIF}

procedure OpenFile(DocumentFileName: String);
begin
{$IFDEF FPC}
  OpenDocument(DocumentFileName);
{$ELSE}
  ExecApp(DocumentFileName, ExtractFilePath(DocumentFileName));
{$ENDIF}
end;

end.

