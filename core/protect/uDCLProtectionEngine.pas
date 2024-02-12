unit uDCLProtectionEngine;
{$mode Delphi}

interface

uses
  Classes, SysUtils, LazFileUtils, strutils,
  uIDCLProtectionEngine, uDCLHardwareKeys, uDCLConst, uDCLMD5, uKeyData;

type

  { TDCLProtectionEngine }

  TDCLProtectionEngine = class(TInterfacedObject, IDCLProtectionEngine)
  private
    ProgDataDir: String;
    HWKeyEngine: TDCLHardwareKeys;

    function GetProtectionStatus: Boolean;
    function GetProtectionKey: String;
    function GetSoftwareKey: String;
    function ApplaySoftwareKey(const Key: String): Boolean;
    function CheckKey(const Key: String): TKeyData;
    function GetKeyData: TKeyData;
    function NormalizeKey(const Key: String): String;
  public
    constructor Create;
    destructor Destroy; override;
  end;


implementation

uses
   DateUtils;

const
  KeyFileName='protection.key';
  KeyFolder='DCL5';

{ TDCLProtectionEngine }

function GetFileData(var Stream: TStream): String;
var
  b: Byte;
begin
  Result:='';
  Stream.Position:=0;
  while (Stream.Position<64) and (Stream.Size>Stream.Position) do
  begin
    b:=Stream.ReadByte;
    Result:=Result+IntToHex(b);
  end;
end;

procedure WriteFileData(const S: String; var Stream: TStream);
var
  i: Integer;
  h: String;
begin
  i:=1;
  while S.Length>=i do
  begin
    h:=Copy(S, i, 2);
    Stream.WriteByte(Hex2Dec(h));
    Inc(i, 2);
  end;
end;

function TDCLProtectionEngine.GetProtectionStatus: Boolean;
begin
  Result:=CheckKey(GetSoftwareKey).RemainDays>-1;
end;

function TDCLProtectionEngine.GetProtectionKey: String;
var
  S: String;
begin
  S:=MD5String(KeyFolder+'\'+MD5String(HWKeyEngine.GetKey)+'\windows');
  Result:=MD5String(S+KeyFolder+'windows');
end;

function TDCLProtectionEngine.GetSoftwareKey: String;
var
  FS: TStream;
begin
  ProgDataDir:=GetAppConfigDir({$IFDEF UNIX}False{$ELSE}True{$ENDIF});
  ProgDataDir:=ExtractFileDir(ExcludeTrailingPathDelimiter(ProgDataDir))+PathDelim+KeyFolder+PathDelim;

  Result:='';
  if DirectoryExists(ProgDataDir) then
  begin
    if FileExists(ProgDataDir+KeyFileName) then
    begin
      FS:=TFileStream.Create(ProgDataDir+KeyFileName, fmOpenRead or fmShareDenyWrite);
      Result:=GetFileData(FS);
      FreeAndNil(FS);
    end;
  end;
end;

function TDCLProtectionEngine.ApplaySoftwareKey(const Key: String): Boolean;
var
  FS: TStream;
begin
  Result:=False;
  if CheckKey(Key.Trim).ExpireDayes>-1 then
  begin
    Result:=True;
    if not DirectoryExists(ProgDataDir) then
      ForceDirectories(ProgDataDir);
    if DirectoryExists(ProgDataDir) then
    begin
      FS:=TFileStream.Create(ProgDataDir+KeyFileName, fmCreate);
      WriteFileData(NormalizeKey(Key.Trim), FS);

      FreeAndNil(FS);
    end;
  end;
end;

function TDCLProtectionEngine.CheckKey(const Key: String): TKeyData;
const
  CharsTab='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
  Periods: Array[1..5] of String=('1w', '1m', '1y', '2y', '3y');
var
  S, S2: String;
  i, d, p: Integer;
  TestResult: Boolean;
begin
  Result:=TKeyData.Create;
  Result.RemainDays:=-1;
  S:=GetProtectionKey;
  for i:=0 to 7 do
  begin
    S:=MD5String(S+KeyFolder+'\'+S+'\');
  end;

  S2:=NormalizeKey(Key);
  TestResult:=S.ToLowerInvariant=S2.ToLowerInvariant;
  Result.KeyType:='tl';

  if not TestResult then
  begin
    for p:=1 to Length(Periods) do
    begin
      for d:=0 to 1096 do
      begin
        S:=GetProtectionKey+';'+Periods[p]+';'+AddChar('0', IntToStr(YearOf(IncDay(Today, -d))-2020), 2)+CharsTab[MonthOf(IncDay(Today, -d))]+CharsTab[DayOf(IncDay(Today, -d))];
        for i:=0 to 7 do
        begin
          S:=MD5String(S+KeyFolder+'\'+S+'\');
        end;

        if S.ToLowerInvariant=S2.ToLowerInvariant then
        begin
          if p=1 then
            Result.RemainDays:=7
          else if p=2 then
            Result.RemainDays:=31
          else if p=3 then
            Result.RemainDays:=366
          else if p=4 then
            Result.RemainDays:=731
          else if p=5 then
            Result.RemainDays:=1096;

          TestResult:=d<=Result.RemainDays;
          if TestResult then
          begin
            Result.RemainDays:=Result.RemainDays-d;
            Result.ExpireDayes:=d;
            Result.KeyType:=Periods[p];
          end;

          Exit;
        end;
      end;
    end;
  end
  else
    Result.RemainDays:=0;
end;

function TDCLProtectionEngine.GetKeyData: TKeyData;
begin
  Result:=CheckKey(GetSoftwareKey);
end;

function TDCLProtectionEngine.NormalizeKey(const Key: String): String;
var
  c: Char;
begin
  Result:='';
  for c in Key.ToLowerInvariant do
  begin
    if (c in ['0'..'9']) or (c in ['a'..'z']) then
      Result:=Result+c;
  end;
end;

constructor TDCLProtectionEngine.Create;
begin
  inherited Create;

  HWKeyEngine:=TDCLHardwareKeys.Create;
end;

destructor TDCLProtectionEngine.Destroy;
begin
  FreeAndNil(HWKeyEngine);
  inherited Destroy;
end;

end.

