unit uBuffWriter;
{$mode delphi}

interface

uses
  Classes, SysUtils;

type

  { TBitWriter }

  TBuffWriter = class
  private
    FDataWrite: UInt64;
    FBufLength, FBuffPos: Longint;
    FOutBuffer: Array of Byte;
    FStream: TStream;

  protected
    procedure OutputBuffer;
    procedure PutNextByte(Value: Byte);
  public
    constructor Create(const Stream: TStream; DataSize: Int64); overload;
    destructor Destroy; override;

    procedure WriteByte(Value: Byte);
    procedure WriteWord(Value: Word);
    procedure Write64(Value: UInt64);

    procedure Flush;

    property WriteBytes: UInt64 read FDataWrite;
  end;

implementation

const
  MaxBuffer = 30*1024;

{ TBitWriter }

constructor TBuffWriter.Create(const Stream: TStream; DataSize: Int64);
begin
  inherited Create;

  FDataWrite:=0;
  FStream:=Stream;

  if (DataSize<MaxBuffer) and (DataSize<>0) then
    FBufLength:=DataSize
  else
    FBufLength:=MaxBuffer;

  FBuffPos:=-1;

  SetLength(FOutBuffer, FBufLength);
end;

destructor TBuffWriter.Destroy;
begin
  OutputBuffer;

  inherited Destroy;
end;

procedure TBuffWriter.WriteByte(Value: Byte);
begin
  PutNextByte(Value);
end;

procedure TBuffWriter.WriteWord(Value: Word);
Var
  B: Byte;
begin
  B:=Value shr 8;
  PutNextByte(B);
  B:=Value and $FF;
  PutNextByte(B);
end;

procedure TBuffWriter.Write64(Value: UInt64);
Var
  B: Byte;
begin
  B:=(Value shr 24) and $FF;
  PutNextByte(B);
  B:=(Value shr 16) and $FF;
  PutNextByte(B);
  B:=(Value shr 8) and $FF;
  PutNextByte(B);
  B:=Value and $FF;
  PutNextByte(B);
end;

procedure TBuffWriter.Flush;
begin
  OutputBuffer;
end;

procedure TBuffWriter.OutputBuffer;
begin
  if FBuffPos>=0 then
    FStream.Write(FOutBuffer[0], FBuffPos+1);
  FBuffPos:=-1;
end;

procedure TBuffWriter.PutNextByte(Value: Byte);
begin
  if FBuffPos+1>=FBufLength then
  begin
    OutputBuffer;
  end;

  Inc(FBuffPos);
  FOutBuffer[FBuffPos]:=Value;
  Inc(FDataWrite);
end;

end.

