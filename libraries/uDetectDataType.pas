unit uDetectDataType;
{$mode Delphi}

interface

uses
  Classes, SysUtils, StrUtils, Graphics, LazStringUtils;

function IsColor(const S: String): Boolean;
function IsHex(const S: String): Boolean;
function IsDigit(const S: String): Boolean;
function IsFloat(const S: String): Boolean;
function IsTime(const S: String): Boolean;
function IsDate(const S: String): Boolean;
function IsDateTime(const S: String): Boolean;

implementation

function IsColor(const S: String): Boolean;
var
  c: Char;
  Color: TColor;
begin
  Result:=False;
  if S='' then Exit(False);

  if LazStartsStr('$', S) and (Length(S)=7) then
  begin
    for c in S.ToLower do
    begin
      if not (c in ['$', '0'..'9', 'a'..'f']) then
      begin
        Exit(False);
      end;
    end;
    Exit(True);
  end;

  if LazStartsStr('cl', S) then
  begin
    try
      Color:=StringToColor(S);
      Exit(True);
    except
      Exit(False);
    end;
  end;
end;

function IsHex(const S: String): Boolean;
var
  c: Char;
begin
  Result:=False;
  if S='' then Exit(False);

  if LazStartsStr('$', S) and (Length(S) mod 2=1) then
  begin
    for c in S.ToLower do
    begin
      if not (c in ['$', '0'..'9', 'a'..'f']) then
      begin
        Exit(False);
      end;
    end;
    Exit(True);
  end;
end;

function IsDigit(const S: String): Boolean;
var
  c: Char;
begin
  Result:=False;
  if S='' then Exit(False);

  if LazStartsStr('-', S) or (S[1] in ['0'..'9']) then
  begin
    for c in S.ToLower do
    begin
      if not (c in ['0'..'9', 'e']) then
      begin
        Exit(False);
      end;
    end;
    Exit(True);
  end;
end;

function IsFloat(const S: String): Boolean;
var
  f: Double;
  FS: TFormatSettings;
  tmpS: String;
begin
  Result:=False;
  if S='' then Exit(False);
  FS:=DefaultFormatSettings;
  tmpS:=S;

  if ((Pos(FS.DecimalSeparator, tmpS)<>0) or (Pos('.', tmpS)<>0) or (Pos('e', tmpS.ToLower)<>0)) and (LazStartsStr('-', tmpS) or (tmpS[1] in ['0'..'9', '.'])) then
  begin
    if Pos('.', S)<>0 then
      tmpS:=StringReplace(tmpS, '.', FS.DecimalSeparator, [rfReplaceAll]);
    Result:=TryStrToFloat(tmpS, f);
  end;
end;

function IsDate(const S: String): Boolean;
var
  c: Char;
  FS: TFormatSettings;
  i: Integer;
  DT: TDateTime;
begin
  Result:=False;
  if S='' then Exit(False);
  FS:=DefaultFormatSettings;
  i:=Length(S);

  if (i in [8, 10]) and (Pos(FS.DateSeparator, S)<>0) and (S[1] in ['0'..'9']) then
  begin
    i:=0;
    for c in S.ToLower do
    begin
      if not (c in ['0'..'9', FS.DateSeparator]) then
      begin
        Exit(False);
      end;
      if c=FS.DateSeparator then
        Inc(i);
    end;
    if (i=2) and (S[3]=FS.DateSeparator) and (S[6]=FS.DateSeparator) then
    begin
      try
        DT:=StrToDate(S, FS);
        Exit(True);
      except
        Exit(False);
      end;
    end;
  end;
end;

function IsTime(const S: String): Boolean;
var
  c: Char;
  FS: TFormatSettings;
  i: Integer;
  DT: TDateTime;
begin
  Result:=False;
  if S='' then Exit(False);
  FS:=DefaultFormatSettings;
  i:=Length(S);

  if (i>=3) and (Pos(FS.TimeSeparator, S)<>0) and (S[1] in ['0'..'9']) then
  begin
    i:=0;
    for c in S.ToLower do
    begin
      if not (c in ['0'..'9', FS.TimeSeparator]) then
      begin
        Exit(False);
      end;
    end;
    try
      DT:=StrToTime(S, FS);
      Exit(True);
    except
      Exit(False);
    end;
  end;
end;

function IsDateTime(const S: String): Boolean;
var
  FS: TFormatSettings;
  DT: TDateTime;
  i: Integer;
begin
  Result:=False;
  if S='' then Exit(False);
  FS:=DefaultFormatSettings;

  i:=Length(S);
  if (i>5) and (Pos(FS.DateSeparator, S)<>0) and (Pos(FS.TimeSeparator, S)<>0) and (S[1] in ['0'..'9']) then
  begin
    try
      DT:=StrToDateTime(S, FS);
      Exit(True);
    except
      Exit(False);
    end;
  end;
end;

end.

