unit uBitWriter;
{$mode delphi}

interface

uses
  Classes, SysUtils, uBuffWriter;

type

  { TBitWriter }

  TBitWriter = class(TBuffWriter)
  private
    FWriteCounterBit: Byte;
    FWriteBitsBuffer: UInt64;
  public
    constructor Create(const Stream: TStream; DataSize: Int64); overload;
    destructor Destroy; override;

    procedure BitsWrite(Value: UInt64; BitsCount: Byte);
    procedure Flush;
  end;

implementation

{ TBitWriter }

constructor TBitWriter.Create(const Stream: TStream; DataSize: Int64);
begin
  inherited Create(Stream, DataSize);
  FWriteCounterBit:=0;
end;

destructor TBitWriter.Destroy;
begin
  OutputBuffer;

  inherited Destroy;
end;

procedure TBitWriter.BitsWrite(Value: UInt64; BitsCount: Byte);
Var
  B: Byte;
  BitBuffer: UInt64;
begin
  BitBuffer:=Value;
  FWriteBitsBuffer:=FWriteBitsBuffer or (BitBuffer shl FWriteCounterBit);
  { Добавляем в буфер новые биты }
  Inc(FWriteCounterBit, BitsCount);
  While (FWriteCounterBit>=8) do
  Begin
    B:=Byte(FWriteBitsBuffer and $FF); { Получаем первый байт из буфера }
    PutNextByte(B);
    FWriteBitsBuffer:=FWriteBitsBuffer shr 8;
    { Отчищам буфер от записанных бит }
    Dec(FWriteCounterBit, 8);
  End;
end;

procedure TBitWriter.Flush;
begin
  if FWriteCounterBit>0 then
  begin
    PutNextByte(Byte(FWriteBitsBuffer));
    FWriteCounterBit:=0;
    FWriteBitsBuffer:=0;
  end;

  inherited;
end;

end.

