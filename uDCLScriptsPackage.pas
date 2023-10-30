unit uDCLScriptsPackage;
{$mode Delphi}

interface

uses
  Classes, SysUtils, LazFileUtils, Generics.Collections;

type
  TRunType=(rtNone, rtCommand, rtDialog);

  TPackageInfo=class
    Name, Hash, Version: String;
    RunOnStart: Boolean;
  end;

  TDCLScriptItem=class
    RunType: TRunType;  // 0 - None, 1 - Command, 2 - Dialog
    Ident, Parent: Integer;
    ScriptName, Command: String;
    ScriptText: TStringStream;
  end;
  
  TPackage=class
    PackageInfo: TPackageInfo;
    Scripts: TList<TDCLScriptItem>;
  end;

  { TDCLScriptsPackage }

  TDCLScriptsPackage=class
  private
    FPackage: TPackage;

    function GetPackageInfo: TPackageInfo;
    function GetScripts: TList<TDCLScriptItem>;

    function GetSign(Login, Password, Hash: String): String;

    procedure DisassemblyPackage(TextPackage: TStringList);
    procedure ParsePackageHeader(TextPackage: TStringList);
    function CalcPackageHash: String;
    function GetBase41Sequence: String;
  public
    constructor Create;

    procedure Load(Package: TStream);
    function EncodePackage(RunOnStart: Boolean): TStream;

    procedure ClearFiles;
    procedure AddFile(FileName: String; RunType: TRunType);
    function AddMenuItem(Title, Command: String; Ident, Parent: Integer): TDCLScriptItem;
    procedure DeleteScript(Name: String);
    procedure DeleteMenuItem(Id: Integer);
    procedure SetScriptRunType(Name: String; RunType: TRunType);
    procedure Delete(Item: TDCLScriptItem);

    function CheckPackage(Login, Password: String): Boolean;
    procedure SignPackage(Login, Password: String);

    property Scripts: TList<TDCLScriptItem> read GetScripts;
    property PackageInfo: TPackageInfo read GetPackageInfo;
  end;


implementation

uses
  uStringParams, MD5, uLZW, uDCLConst;

function GetDataHash(Data: TStream): String;
var
  Buffer: Array of Byte;
  i, p: LongInt;
  b: Byte;
begin
  Result:='';
  if Assigned(Data) and (Data.Size>0) then
  begin
    p:=0;
    Data.Position:=0;
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

    Result:=MD5Print(MD5Buffer(Buffer[0], p));
  end;
end;

function TDCLScriptsPackage.GetPackageInfo: TPackageInfo;
begin
  Result:=FPackage.PackageInfo;
end;

function TDCLScriptsPackage.GetSign(Login, Password, Hash: String): String;
begin
  Result:=Login+'\'+Password+'\'+Hash;
end;

procedure TDCLScriptsPackage.SignPackage(Login, Password: String);
begin
  FPackage.PackageInfo.Hash:=MD5Print(MD5String(GetSign(Login, Password, CalcPackageHash)));
end;

function TDCLScriptsPackage.CheckPackage(Login, Password: String): Boolean;
var
  h: String;
begin
  h:=MD5Print(MD5String(GetSign(Login, Password, CalcPackageHash)));
  Result:=h=FPackage.PackageInfo.Hash;
end;

constructor TDCLScriptsPackage.Create;
begin
  FPackage:=TPackage.Create;
  FPackage.PackageInfo:=TPackageInfo.Create;
  FPackage.Scripts:=TList<TDCLScriptItem>.Create;
end;

procedure TDCLScriptsPackage.ClearFiles;
begin
  FPackage.Scripts.Clear;
end;

procedure TDCLScriptsPackage.AddFile(FileName: String; RunType: TRunType);
var
  si: TDCLScriptItem;
begin
  si:=TDCLScriptItem.Create;
  si.ScriptName:=ExtractFileNameOnly(FileName);
  si.RunType:=RunType;
  si.ScriptText:=TStringStream.Create('', TEncoding.UTF8);
  si.ScriptText.LoadFromFile(FileName);

  FPackage.Scripts.Add(si);
end;

function TDCLScriptsPackage.AddMenuItem(Title, Command: String; Ident,
  Parent: Integer): TDCLScriptItem;
var
  si: TDCLScriptItem;
begin
  si:=TDCLScriptItem.Create;
  si.Command:=Command;
  si.ScriptName:=Title;
  si.Ident:=Ident;
  si.Parent:=Parent;

  FPackage.Scripts.Add(si);
  Result:=si;
end;

procedure TDCLScriptsPackage.DeleteScript(Name: String);
var
  I: TDCLScriptItem;
begin
  for I in FPackage.Scripts do
  begin
    if (LowerCase(I.ScriptName)=LowerCase(Name)) and (I.Ident=0) then
    begin
      FPackage.Scripts.Remove(I);
      break;
    end;
  end;
end;

procedure TDCLScriptsPackage.DeleteMenuItem(Id: Integer);
var
  I: TDCLScriptItem;
begin
  for I in FPackage.Scripts do
  begin
    if I.Ident=Id then
    begin
      FPackage.Scripts.Remove(I);
      break;
    end;
  end;
end;

procedure TDCLScriptsPackage.SetScriptRunType(Name: String; RunType: TRunType);
var
  I: TDCLScriptItem;
begin
  for I in FPackage.Scripts do
  begin
    I.RunType:=rtNone;
    if (LowerCase(I.ScriptName)=LowerCase(Name)) and (I.Ident=0) then
    begin
      I.RunType:=RunType;
    end;
  end;
end;

procedure TDCLScriptsPackage.Delete(Item: TDCLScriptItem);
begin
  FPackage.Scripts.Remove(Item);
end;

function TDCLScriptsPackage.CalcPackageHash: String;
var
  S, h: String;
  Hashes: TSortedList<String>;
  I: TDCLScriptItem;
begin
  Hashes:=TSortedList<String>.Create;

  for I in FPackage.Scripts do
  begin
    h:=MD5Print(MD5String(I.ScriptName+GetDataHash(I.ScriptText)));
    Hashes.Add(h);
  end;

  Hashes.Sort;
  S:='';
  for h in Hashes do
  begin
    S:=MD5Print(MD5String(h+S));
  end;
  FreeAndNil(Hashes);

  Result:=S;
end;

function TDCLScriptsPackage.GetBase41Sequence: String;
begin
  Result:='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
end;

function TDCLScriptsPackage.EncodePackage(RunOnStart: Boolean): TStream;
var
  RawPackage: TStream;
  I: TDCLScriptItem;
  CompressedPackage: TStream;
  Base41X, S: String;
  b, b1, w: Word;
  TextPackage: TStringList;
begin
  TextPackage:=TStringList.Create;
  TextPackage.Clear;

  S:='';
  if RunOnStart then
    S:='RunOnStart=1;';
  TextPackage.Append('[Sign='+FPackage.PackageInfo.Hash+';Version='+PackagesVersion+';'+S+']');

  for I in FPackage.Scripts do
  begin
    S:='';
    if I.RunType<>rtNone then
    begin
      S:=S+'RunType='+IntToStr(Ord(I.RunType))+';';
    end;
    if I.Command<>'' then
    begin
      S:=S+'Command='+I.Command+';';
    end;

    if I.Ident<>0 then
    begin
      S:=S+'Ident='+IntToStr(I.Ident)+';';
    end;
    if I.Parent<>0 then
    begin
      S:=S+'Parent='+IntToStr(I.Parent)+';';
    end;

    TextPackage.Append('[Name='+I.ScriptName+';'+S+']');
    if Assigned(I.ScriptText) then
      TextPackage.Append(I.ScriptText.DataString);
    TextPackage.Append('[EndName='+I.ScriptName+';]');
  end;

  CompressedPackage:=TMemoryStream.Create;
  RawPackage:=TStringStream.Create(TextPackage.Text, TEncoding.UTF8);
  CompressProc(RawPackage, CompressedPackage);
  RawPackage.Free;
  FreeAndNil(TextPackage);

  Base41X:=GetBase41Sequence;

  Result:=TMemoryStream.Create;
  w:=0;
  CompressedPackage.Position:=0;
  b:=0;
  while CompressedPackage.Read(b, 2)<>0 do
  begin
    b1:=b div (41*41);
    S:=Base41X[b1+1];
    Result.Write(S[1], 1);
    inc(w);

    b1:=(b div 41) mod 41;
    S:=Base41X[b1+1];
    Result.Write(S[1], 1);
    inc(w);

    b1:=b mod 41;
    S:=Base41X[b1+1];
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

procedure TDCLScriptsPackage.Load(Package: TStream);
var
  w: Word;
  bp: Integer;
  b: Byte;
  Base41X: String;
  PackageText: TStream;
  TextPackage: TStringList;
  MS: TStream;
  Buffer: Array[1..3] of Word;
begin
  Base41X:=GetBase41Sequence;

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

  TextPackage:=TStringList.Create;
  TextPackage.Text:=(PackageText as TStringStream).DataString;
  PackageText.Free;

  DisassemblyPackage(TextPackage);
  FreeAndNil(TextPackage);
end;

procedure TDCLScriptsPackage.DisassemblyPackage(TextPackage: TStringList);
var
  b, f: Boolean;
  S, s1, sn: String;
  ScriptItem: TDCLScriptItem;
begin
  FPackage.Scripts.Clear;
  ParsePackageHeader(TextPackage);

  f:=True;
  b:=False;
  sn:='';
  for S in TextPackage do
  begin
    if Pos('[Name=', S)<>0 then
    begin
      s1:=FindParam('Name=', S);
      if s1<>'' then
      begin
        sn:=s1;
        ScriptItem:=TDCLScriptItem.Create;
        ScriptItem.ScriptName:=sn;

        s1:=FindParam('RunType=', S);
        if s1<>'' then
        begin
          ScriptItem.RunType:=TRunType(StrToInt(s1));
        end;

        s1:=FindParam('Command=', S);
        if s1<>'' then
        begin
          ScriptItem.Command:=s1;
        end;

        s1:=FindParam('Ident=', S);
        if s1<>'' then
        begin
          ScriptItem.Ident:=StrToInt(s1);
        end;

        s1:=FindParam('Parent=', S);
        if s1<>'' then
        begin
          ScriptItem.Parent:=StrToInt(s1);
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
        FPackage.Scripts.Add(ScriptItem);
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

function TDCLScriptsPackage.GetScripts: TList<TDCLScriptItem>;
begin
  Result:=FPackage.Scripts;
end;

procedure TDCLScriptsPackage.ParsePackageHeader(TextPackage: TStringList);
var
  S: String;
begin
  for S in TextPackage do
  begin
    if PosEx('[Sign=', S)=1 then
    begin
      FPackage.PackageInfo.Hash:=FindParam('Sign=', S);
      FPackage.PackageInfo.RunOnStart:=FindParam('RunOnStart=', S)='1';
      FPackage.PackageInfo.Version:=FindParam('Version=', S);
      Break;
    end;
  end;
end;

end.

