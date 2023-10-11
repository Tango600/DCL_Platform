unit uDCLScriptSigner;
{$mode Delphi}

interface

uses
  Classes, SysUtils, LazFileUtils, Generics.Collections;

type
  TPackageInfo=class
    PackageName, PackageHash: String;
  end;

  TDCLScriptItem=class
    PackageInfo: TPackageInfo;
    RunOnStart: Boolean;
    RunType: Byte;  // 0 - ND (Dialog), 1 - Command, 2 - Dialog
    Ident, Parent: Integer;
    ScriptName: String;
    ScriptText: TStringStream;
  end;

function EncodePackage(Package: TStringList): TStream;
function DecodePackage(Package: TStream): TStringList;

function CombineFiles(Files: TStringList): TStringList;
function DisassemblyPackage(Package: TStringList): TDictionary<String, TDCLScriptItem>;

function CheckPackage(Login, Password: String; Package: TStringList): Boolean;
function SignPackage(Login, Password: String; Package: TStringList): TStringList;

function GetPackageVersion(Package: TStringList): String;
function GetPackageSignedHash(Package: TStringList): String;

implementation

uses
  uStringParams, MD5, uLZW;

function GetDataHash(Data: TStream): String;
var
  Buffer: Array of Byte;
  i, p: LongInt;
  b: Byte;
begin
  p:=0;
  SetLength(Buffer, Data.Size);
  for i:=1 to Data.Size do
  begin
    b:=Data.ReadByte;
    if b>=32 then
    begin
      Buffer[p]:=b;
      inc(p);
    end;
  end;
  Data.Free;

  Result:=MD5Print(MD5Buffer(Buffer[0], p));
end;

function CombineFiles(Files: TStringList): TStringList;
var
  fn, sn: String;
  F: TStringStream;
begin
  Result:=TStringList.Create;
  for fn in Files do
  begin
    if FileExists(fn) then
    begin
      sn:=ExtractFileNameOnly(fn);
      Result.Append('[Name='+sn+';]');
      F:=TStringStream.Create('', TEncoding.UTF8);
      F.LoadFromFile(fn);
      Result.Append(F.DataString);
      Result.Append('[EndName='+sn+';]');
      FreeAndNil(F);
    end;
  end;
end;

function GetSign(Login, Password, Hash: String): String;
begin
  Result:=Login+'\'+Password+'\'+Hash;
end;

function SignPackage(Login, Password: String; Package: TStringList): TStringList;
var
  ScriptStrings: TStringList;
  SS: TStringStream;
  i, l: Integer;
  S, sn, h: String;
  Hashes: TDictionary<String, String>;
begin
  Result:=TStringList.Create;
  Hashes:=TDictionary<String, String>.Create;

  sn:='';
  l:=-1;
  for i:=1 to Package.Count do
  begin
    S:=Package[i-1];
    Result.Append(Package[i-1]);

    if Pos('[Name=', Package[i-1])=1 then
    begin
      sn:=FindParam('Name=', Package[i-1]);
      ScriptStrings:=TStringList.Create;
      Continue;
    end;

    if Pos('[EndName=', Package[i-1])=1 then
    begin
      if FindParam('EndName=', Package[i-1])<>'' then
      begin
        SS:=TStringStream.Create(ScriptStrings.Text, TEncoding.UTF8);
        SS.Position:=0;
        h:=GetDataHash(SS);
        if (sn<>'') and (h<>'') then
          Hashes.Add(sn, h);

        Continue;
      end;
    end;

    if sn<>'' then
    begin
      ScriptStrings.Append(Package[i-1]);
    end;

    if PosEx('[Sign=', Package[i-1])=1 then
    begin
      S:=FindParam('Sign=', Package[i-1]);
      if S<>'' then
      begin
        l:=i-1;
      end;
    end;
  end;

  S:='';
  for h in Hashes.Values do
  begin
    S:=MD5Print(MD5String(h+S));
  end;

  h:='[Sign='+MD5Print(MD5String(GetSign(Login, Password, S)))+';Version=1.3;]';
  if l>=0 then
  begin
    Result[l]:=h;
  end
  else
  begin
    Result.Insert(0, h);
  end;
end;

function GetPackageVersion(Package: TStringList): String;
var
  S: String;
begin
  Result:='';
  for S in Package do
  begin
    if PosEx('[Sign=', S)=1 then
    begin
      Result:=FindParam('Version=', S);
      break;
    end;
  end;
end;

function GetPackageSignedHash(Package: TStringList): String;
var
  S: String;
begin
  Result:='';
  for S in Package do
  begin
    if PosEx('[Sign=', S)=1 then
    begin
      Result:=FindParam('Sign=', S);
      break;
    end;
  end;
end;

function CheckPackage(Login, Password: String; Package: TStringList): Boolean;
var
  ScriptStrings: TStringList;
  SS: TStringStream;
  S, sign, sn, h: String;
  Hashes: TDictionary<String, String>;
begin
  Hashes:=TDictionary<String, String>.Create;

  sn:='';
  for S in Package do
  begin
    if Pos('[Name=', S)=1 then
    begin
      sn:=FindParam('Name=', S);
      ScriptStrings:=TStringList.Create;
      Continue;
    end;

    if Pos('[EndName=', S)=1 then
    begin
      if FindParam('EndName=', S)<>'' then
      begin
        SS:=TStringStream.Create(ScriptStrings.Text, TEncoding.UTF8);
        SS.Position:=0;
        h:=GetDataHash(SS);
        if (sn<>'') and (h<>'') then
          Hashes.Add(sn, h);

        Continue;
      end;
    end;

    if sn<>'' then
    begin
      ScriptStrings.Append(S);
    end;

    if PosEx('[Sign=', S)=1 then
    begin
      sign:=FindParam('Sign=', S);
    end;
  end;

  S:='';
  for h in Hashes.Values do
  begin
    S:=MD5Print(MD5String(h+S));
  end;

  h:=MD5Print(MD5String(GetSign(Login, Password, S)));
  Result:=h=sign;
end;

function EncodePackage(Package: TStringList): TStream;
var
  RawPackage: TStream;
  CompressedPackage: TStream;
  Base16X, S: String;
  b, b1, w: Word;
begin
  CompressedPackage:=TMemoryStream.Create;
  RawPackage:=TStringStream.Create(Package.Text, TEncoding.UTF8);
  CompressProc(RawPackage, CompressedPackage);
  RawPackage.Free;

  Base16X:='';
  for b:=Ord('A') to Ord('Z') do
  begin
    Base16X:=Base16X+Chr(b);
  end;
  for b:=Ord('a') to Ord('z') do
  begin
    Base16X:=Base16X+Chr(b);
  end;

  Result:=TMemoryStream.Create;
  w:=0;
  CompressedPackage.Position:=0;
  b:=0;
  while CompressedPackage.Read(b, 2)<>0 do
  begin
    b1:=b div (41*41);
    S:=Base16X[b1+1];
    Result.Write(S[1], 1);
    inc(w);

    b1:=(b div 41) mod 41;
    S:=Base16X[b1+1];
    Result.Write(S[1], 1);
    inc(w);

    b1:=b mod 41;
    S:=Base16X[b1+1];
    Result.Write(S[1], 1);
    inc(w);

    if w>80 then
    begin
      S:=LineEnding;
      Result.Write(S[1], Length(S));
      w:=0;
    end;
    b:=0;
  end;
  CompressedPackage.Free;
end;

function FindSegmentNum(Base41, Segment: String): Integer;
var
  i: Integer;
begin
  i:=0;
  while Base41[i+1]<>Segment do
  begin
    inc(i);
  end;
  Result:=i;
end;

function DecodePackage(Package: TStream): TStringList;
var
  w: Word;
  bp: Integer;
  b: Byte;
  Base41X: String;
  PackageText: TStream;
  MS: TStream;
  Buffer: Array[1..3] of Word;
begin
  Base41X:='';
  for b:=Ord('A') to Ord('Z') do
  begin
    Base41X:=Base41X+Chr(b);
  end;
  for b:=Ord('a') to Ord('z') do
  begin
    Base41X:=Base41X+Chr(b);
  end;

  MS:=TMemoryStream.Create;

  bp:=1;
  while Package.Read(b, 1)<>0 do
  begin
    if b<Ord('A') then
    begin
      Continue;
    end;

    Buffer[bp]:=FindSegmentNum(Base41X, Chr(b));
    inc(bp);

    if bp>3 then
    begin
      w:=(Buffer[1]*41*41)+(Buffer[2]*41)+Buffer[3];
      MS.WriteBuffer(w, 2);
      bp:=1;
    end;
  end;
  MS.Position:=0;

  PackageText:=TStringStream.Create('', TEncoding.UTF8);

  DecompressProc(MS, PackageText);
  MS.Free;

  Result:=TStringList.Create;
  Result.Text:=(PackageText as TStringStream).DataString;
  PackageText.Free;
end;

function DisassemblyPackage(Package: TStringList): TDictionary<String, TDCLScriptItem>;
var
  b, f: Boolean;
  S, s1, sn: String;
  ScriptItem: TDCLScriptItem;
  PackageInfo: TPackageInfo;
begin
  Result:=TDictionary<String, TDCLScriptItem>.Create;
  PackageInfo:=TPackageInfo.Create;
  PackageInfo.PackageHash:=GetPackageSignedHash(Package);

  f:=True;
  b:=False;
  sn:='';
  for S in Package do
  begin
    if Pos('[Name=', S)<>0 then
    begin
      s1:=FindParam('Name=', S);
      if s1<>'' then
      begin
        sn:=s1;
        ScriptItem:=TDCLScriptItem.Create;
        ScriptItem.PackageInfo:=PackageInfo;
        ScriptItem.ScriptName:=sn;
        s1:=FindParam('Run=', S);
        ScriptItem.RunOnStart:=s1<>'';

        s1:=FindParam('RunType=', S);
        if s1<>'' then
        begin
          ScriptItem.RunType:=StrToInt(s1);
        end;

        ScriptItem.ScriptText:=TStringStream.Create('', TEncoding.UTF8);
        b:=True;
        Continue;
      end;
    end;

    if Pos('[EndName=', S)<>0 then
    begin
      s1:=FindParam('EndName=', S);
      if (s1<>'') and (s1=sn) then
      begin
        b:=False;
        Result.Add(sn, ScriptItem);
        Continue;
      end;
    end;

    if b and Assigned(ScriptItem) and Assigned(ScriptItem.ScriptText) then
    begin
      if not f then
        ScriptItem.ScriptText.WriteString(LineEnding);

      ScriptItem.ScriptText.WriteString(S);
      f:=False;
    end;
  end;
end;

end.

