Unit uLZW;
{$mode delphi}

// Модуль LZW паковщика и распаковщика
interface

uses
  Classes, SysUtils, uBitWriter, uBitReader, uBuffWriter, uBuffReader;

Procedure CompressProc(Var Data: TBuffReader; var Arc: TBitWriter);
Procedure DecompressProc(Var Arc: TBitReader; var Data: TBuffWriter);

implementation

const
  MaxWordSize=16;
  MaxCode=65535;
  TopChar=255;
  ClearDictValue=256;
  //FreezDict=ClearDictValue+1;
  StepWordLength=ClearDictValue+2;
  EndOfStream=ClearDictValue+3;

Type
  DictR=Record
    Up, Left, Right, Code: Word;
    AddChar: Byte;
  End;

  TDecodeBuffer=Array of Byte;

Var
  TestMode, Overflow: Boolean;
  BitSize, AddChar: Byte;
  CurMaxCode, DictPos, MaxDictSize: Word;
  Dict: Array of DictR;

  DecodeBuffer: TDecodeBuffer;

// =========================Dictionary Begin==================================
Function GetMaxDictSize(PowNum: Byte): Word;
const
  BaseNum=2;
var
  i: Byte;
  s: Cardinal;
begin
  s:=1;
  For i:=1 to PowNum do
    s:=s*BaseNum;
  Dec(s);
  GetMaxDictSize:=s;
end;

Procedure InitDict;
Begin
  MaxDictSize:=GetMaxDictSize(MaxWordSize);
  SetLength(Dict, MaxDictSize);
End;

Procedure AddNode(s: Word; C: Byte);
Var
  dc: Word;
Begin
  If DictPos<MaxDictSize then
  Begin
    If Dict[s].Up=ClearDictValue then
    Begin
      // Никого нет на этой ноде
      Dict[s].Up:=DictPos;
      Dict[DictPos].Up:=ClearDictValue;
      Dict[DictPos].Left:=ClearDictValue;
      Dict[DictPos].Right:=ClearDictValue;
      Dict[DictPos].Code:=s;
      Dict[DictPos].AddChar:=C;
    End
    Else
    Begin
      // Кто-то живёт тут
      If C>Dict[Dict[s].Up].AddChar then
      Begin
        // Смотрим куда податься
        // Вперёд
        dc:=Dict[s].Up;
        While Dict[dc].Right<>ClearDictValue do
          dc:=Dict[dc].Right;

        Dict[dc].Right:=DictPos;
        Dict[DictPos].Up:=ClearDictValue;
        Dict[DictPos].Left:=DictPos;
        Dict[DictPos].Right:=ClearDictValue;
        Dict[DictPos].Code:=s;
        Dict[DictPos].AddChar:=C;
      End
      Else
      Begin
        // Назад
        dc:=Dict[s].Up;
        While Dict[dc].Left<>ClearDictValue do
          dc:=Dict[dc].Left;

        Dict[dc].Left:=DictPos;
        Dict[DictPos].Up:=ClearDictValue;
        Dict[DictPos].Left:=ClearDictValue;
        Dict[DictPos].Right:=DictPos;
        Dict[DictPos].Code:=s;
        Dict[DictPos].AddChar:=C;
      End;
    End;
    Inc(DictPos);
  End;
End;

Function FindNode(s: Word; C: Byte): LongInt;
Var
  dc: Word;
Begin
  Result:=-1;
  If Dict[s].Up<>ClearDictValue then
  Begin
    dc:=Dict[s].Up;
    If Dict[dc].AddChar<>C then
    Begin
      If Dict[dc].AddChar<C then
      Begin
        dc:=Dict[dc].Right;
        While dc<>ClearDictValue do
        Begin
          If Dict[dc].AddChar=C then
          Begin
            FindNode:=dc;
            Exit;
          End;
          dc:=Dict[dc].Right;
        End;
      End;
      If Dict[dc].AddChar>C then
      Begin
        dc:=Dict[dc].Left;
        While dc<>ClearDictValue do
        Begin
          If Dict[dc].AddChar=C then
          Begin
            FindNode:=dc;
            Exit;
          End;
          dc:=Dict[dc].Left;
        End;
      End;
    End
    Else
      FindNode:=dc;
  End;
End;

Procedure InitCoder;
Var
  i: Word;
Begin
  BitSize:=9;
  Overflow:=False;
  CurMaxCode:=GetMaxDictSize(BitSize);
  For i:=0 to MaxDictSize-1 do
  Begin
    Dict[i].Code:=0;
    Dict[i].AddChar:=0;

    Dict[i].Up:=ClearDictValue;
    Dict[i].Left:=ClearDictValue;
    Dict[i].Right:=ClearDictValue;
  End;
  For i:=0 to TopChar do
  Begin
    Dict[i].Code:=ClearDictValue;
    Dict[i].AddChar:=i;
  End;
  DictPos:=EndOfStream+1;
End;
// ======================Dictionary End=====================================

Procedure CompressProc(Var Data: TBuffReader; var Arc: TBitWriter);
Var
  Code: Word;
  Index: LongInt;
Begin
  ///TestMode:=False;
  InitDict;

  InitCoder;
  Code:=Data.ReadByte;
  While Data.ReachToEnd<>rteYes do
  Begin
    AddChar:=Data.ReadByte;

    if Data.ReachToEnd=rteYes then break;

    Index:=FindNode(Code, AddChar);
    If Index<>-1 then
    Begin
      Code:=Index;
    End
    Else
    Begin
      If DictPos<MaxCode then
        AddNode(Code, AddChar)
      Else
        Overflow:=True;

      If (Code>CurMaxCode)and(BitSize<MaxWordSize) then
      Begin
        Arc.BitsWrite(StepWordLength, BitSize);
        Inc(BitSize);
        CurMaxCode:=GetMaxDictSize(BitSize);
      End;

      Arc.BitsWrite(Code, BitSize);

      Code:=AddChar;

      If Overflow then
      Begin
        Arc.BitsWrite(AddChar, BitSize);
        Arc.BitsWrite(ClearDictValue, BitSize);
        InitCoder;
      End;
    End;
  End;

  Arc.BitsWrite(Code, BitSize);
  Arc.BitsWrite(EndOfStream, BitSize);

  Arc.Flush;
End;

Procedure DecompressProc(Var Arc: TBitReader; var Data: TBuffWriter);
Var
  NewCode, OldCode: Word;
  DecodeBufferSize: Cardinal;

  Procedure DecodeString(DeCode: Word);
  Var
    dc: Word;
    ReversC, ForwC: Cardinal;
    DS: TDecodeBuffer;
  Begin
    dc:=DeCode;
    DecodeBufferSize:=0;
    Repeat
      SetLength(DS, DecodeBufferSize+1);
      DS[DecodeBufferSize]:=Dict[dc].AddChar;
      dc:=Dict[dc].Code;
      Inc(DecodeBufferSize);
    Until dc=ClearDictValue;
    SetLength(DecodeBuffer, DecodeBufferSize);
    ReversC:=0;
    For ForwC:=DecodeBufferSize-1 downto 0 do
    Begin
      DecodeBuffer[ReversC]:=DS[ForwC];
      Inc(ReversC);
    End;
  End;

  Procedure OutPutDecodeBuffer;
  Var
    le, i: Cardinal;
  Begin
    le:=Length(DecodeBuffer);
    For i:=0 to le-1 do
      Data.WriteByte(DecodeBuffer[i]);
  End;

Begin
  If Arc.ReachToEnd=rteYes then
    Exit;
  TestMode:=False;
  DecodeBufferSize:=0;
  InitDict;

  NewCode:=0;
  InitCoder;

  OldCode:=Arc.BitsReadW(BitSize);
  Data.WriteByte(OldCode);

  AddChar:=Byte(OldCode);

  While NewCode<>EndOfStream do
  Begin
    NewCode:=Arc.BitsReadW(BitSize);

    Case NewCode of
    EndOfStream:
    break;

    ClearDictValue:
    Begin
      InitCoder;
      OldCode:=Arc.BitsReadW(BitSize);
      AddChar:=Byte(OldCode);
      NewCode:=Arc.BitsReadW(BitSize);
    End;

    StepWordLength:
    Begin
      Inc(BitSize);
      CurMaxCode:=GetMaxDictSize(BitSize);
      NewCode:=Arc.BitsReadW(BitSize);
    End;
    End;

    If DictPos<=NewCode then
    Begin
      DecodeString(OldCode);
      Inc(DecodeBufferSize);
      SetLength(DecodeBuffer, DecodeBufferSize);
      DecodeBuffer[DecodeBufferSize-1]:=AddChar;
    End
    Else
      DecodeString(NewCode);

    OutPutDecodeBuffer;

    AddChar:=DecodeBuffer[0];

    AddNode(OldCode, AddChar);

    OldCode:=NewCode;
  End;

  Data.Flush;
End;

end.
