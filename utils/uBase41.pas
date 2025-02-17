unit uBase41;
{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

 procedure Encode(var Input, Output: TStream; ReturnLine: Boolean; const StartPos: Integer);
 procedure Decode(var Input, Output: TStream; TextMode: Boolean);

implementation

const
  Base41X='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';

procedure Encode(var Input, Output: TStream; ReturnLine: Boolean; const StartPos: Integer);
var
  p: Integer;
  b, b1: Word;
  S: String;
begin
  p:=StartPos;
  Input.Position:=0;
  b:=0;
  while Input.Read(b, 2)<>0 do
  begin
    b1:=b div (41*41);
    S:=Base41X[b1+1];
    Output.Write(S[1], 1);
    inc(p);

    b1:=(b div 41) mod 41;
    S:=Base41X[b1+1];
    Output.Write(S[1], 1);
    inc(p);

    b1:=b mod 41;
    S:=Base41X[b1+1];
    Output.Write(S[1], 1);
    inc(p);

    if ReturnLine and (p>80) then
    begin
      S:=LineEnding;
      Output.Write(S[1], Length(S));
      p:=0;
    end;
    b:=0;
  end;
end;

function FindSegmentNum(const Segment: String): Integer;
var
  i: Integer;
begin
  i:=0;
  while Base41X[i+1]<>Segment do
  begin
    inc(i);
  end;
  Result:=i;
end;

procedure Decode(var Input, Output: TStream; TextMode: Boolean);
var
  w: Word;
  bp, b: Byte;
  Buffer: Array[1..3] of Word;
begin
  b:=0;
  bp:=1;
  while Input.Read(b, 1)<>0 do
  begin
    if not (b in [Ord('A')..Ord('z')]) then
    begin
      Continue;
    end;

    Buffer[bp]:=FindSegmentNum(Chr(b));
    inc(bp);

    if bp>3 then
    begin
      w:=(Buffer[1]*41*41)+(Buffer[2]*41)+Buffer[3];
      if TextMode and (Input.Position=Input.Size) and (w<=255) then
        Output.WriteBuffer(w, 1)
      else
        Output.WriteBuffer(w, 2);
      bp:=1;
    end;
  end;
  Output.Position:=0;
end;

end.

