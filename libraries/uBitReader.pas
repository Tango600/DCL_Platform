unit uBitReader;
{$mode delphi}

interface

uses
  Classes, SysUtils, uBuffReader;

type

  { TBitReader }

  TBitReader = class(TBuffReader)
  private
    ReadCounterBit: Byte;
    FReadBitsBuffer: UInt64;

    function ReadBits(BitsCount: Byte): Uint64;
  public
    constructor Create(const Stream: TStream; DataSize: Int64); overload;

    function BitsRead(BitsCount: Byte): UInt64;
    function BitsReadW(BitsCount: Byte): Word;
    function BitsReadB(BitsCount: Byte): Byte;
  end;

implementation

{ TBitReader }

function TBitReader.ReadBits(BitsCount: Byte): Uint64;
var
  B: Byte;
begin
  if BitsCount<=0 then
    Exit(0);

  { Пока в буфере не хватает бит - читаем их из файла }
  While ReadCounterBit<BitsCount do
  Begin
    B:=GetNextByte;
    FReadBitsBuffer:=FReadBitsBuffer or (B shl ReadCounterBit);
    { Добавляем его в буфер }
    Inc(ReadCounterBit, 8);
  End;
  Result:=FReadBitsBuffer and ((1 shl BitsCount)-1);
  { Получаем из буфера нужное кол-во бит }
  FReadBitsBuffer:=FReadBitsBuffer shr BitsCount;
  { Отчищаем буфер от выданных бит }
  Dec(ReadCounterBit, BitsCount);
end;

constructor TBitReader.Create(const Stream: TStream; DataSize: Int64);
begin
  inherited Create(Stream, DataSize);

  ReadCounterBit:=0;
end;

function TBitReader.BitsRead(BitsCount: Byte): UInt64;
begin
  if BitsCount>64 then
    raise Exception.CreateFmt('TBitReader: недопустимое количество бит: %d', [BitsCount]);

  Result:=ReadBits(BitsCount);
end;

function TBitReader.BitsReadW(BitsCount: Byte): Word;
begin
  if BitsCount>16 then
    raise Exception.CreateFmt('TBitReader: недопустимое количество бит: %d', [BitsCount]);

  Result:=Word(ReadBits(BitsCount));
end;

function TBitReader.BitsReadB(BitsCount: Byte): Byte;
begin
  if BitsCount>8 then
    raise Exception.CreateFmt('TBitReader: недопустимое количество бит: %d', [BitsCount]);

  Result:=Byte(ReadBits(BitsCount));
end;

end.

