unit uBuffReader;
{$mode delphi}

interface

uses
  Classes, SysUtils;

type
  EnumReachToEnd = (rteUnk, rteNo, rteYes);

  { TBuffReader }

  TBuffReader = class
  private
    FBufLength, FBuffPos: Longint;
    FInBuffer: Array of Byte;
    FStream: TStream;
    ReachedToEnd: EnumReachToEnd;

    function GetStreamPosition: Int64;
    procedure SetStreamPosition(Value: Int64);

    function GetReachToEnd: EnumReachToEnd;
  protected
    procedure GetBuffer;
    function GetNextByte: Byte;
  public
    constructor Create(const Stream: TStream; DataSize: Int64); overload;

    function Read64: UInt64;
    function ReadWord: Word;
    function ReadByte: Byte;

    procedure Seek(Offset: Int64; Origin: TSeekOrigin);

    property Position: Int64 read GetStreamPosition write SetStreamPosition;
    property ReachToEnd: EnumReachToEnd read GetReachToEnd;
  end;

implementation

const
  MaxBuffer = 10*1024;

{ TBuffReader }

function TBuffReader.GetStreamPosition: Int64;
begin
  Result:=FStream.Position;
end;

procedure TBuffReader.SetStreamPosition(Value: Int64);
begin
  Seek(Value, soBeginning);
end;

procedure TBuffReader.GetBuffer;
Var
  CountBytes: LongInt;
Begin
  CountBytes:=FStream.Read(FInBuffer[0], FBufLength);
  if CountBytes<>0 then
  begin
    FBuffPos:=0;
    FBufLength:=CountBytes;
    ReachedToEnd:=rteNo;
  end
  else
    ReachedToEnd:=rteYes;
end;

function TBuffReader.GetNextByte: Byte;
begin
  if (FBuffPos<0) or (FBuffPos>=FBufLength) then
  begin
    GetBuffer;
    if ReachedToEnd=rteYes then
      Exit(0);
  end;

  Result:=FInBuffer[FBuffPos];
  Inc(FBuffPos);
end;

function TBuffReader.GetReachToEnd: EnumReachToEnd;
begin
  Result:=ReachedToEnd;
end;

function TBuffReader.Read64: UInt64;
var
  B: Byte;
begin
  Result:=GetNextByte;
  B:=GetNextByte;
  Result:=Result shl 8 or B;
  B:=GetNextByte;
  Result:=Result shl 8 or B;
  B:=GetNextByte;
  Result:=Result shl 8 or B;
end;

constructor TBuffReader.Create(const Stream: TStream; DataSize: Int64);
begin
  inherited Create;

  FStream:=Stream;

  if (DataSize<MaxBuffer) and (DataSize<>0) then
    FBufLength:=DataSize
  else
    FBufLength:=MaxBuffer;

  FBuffPos:=-1;
  ReachedToEnd:=rteUnk;

  SetLength(FInBuffer, FBufLength);
end;

function TBuffReader.ReadWord: Word;
var
  B: Byte;
begin
  Result:=GetNextByte;
  B:=GetNextByte;
  Result:=Result shl 8 or B;
end;

function TBuffReader.ReadByte: Byte;
begin
  Result:=GetNextByte;
end;

procedure TBuffReader.Seek(Offset: Int64; Origin: TSeekOrigin);
var
  p, offs: Int64;
begin
  p:=FStream.Position;
  Case Origin of
    soBeginning: begin
      if Offset<0 then
        Exit;
      offs:=Offset;
    end;
    soEnd: begin
      if Offset<0 then
        Exit;
      offs:=FStream.Size-Offset;
    end;
    soCurrent: begin
      offs:=p+Offset;
    end;
  end;

  if (p-FBufLength<=offs) and (p>=offs) then
  begin
    FBuffPos:=offs-(p-FBufLength);
  end
  else
  begin
    FBuffPos:=-1;
    FStream.Position:=offs;
  end;
end;

end.

