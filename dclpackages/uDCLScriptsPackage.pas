unit uDCLScriptsPackage;
{$mode Delphi}

interface

uses
  Classes, SysUtils, LazFileUtils, Generics.Collections;

type
  TRunType=(rtNone, rtCommand, rtDialog);

  { TPackageInfo }

  TPackageInfo=class
    Name, Sign, Hash, Version: String;
    RunOnStart, ForUpdate: Boolean;
    Dependencies: TList<String>;
    constructor Create;
  end;

  { TDCLScriptItem }

  TDCLScriptItem=class
    SQL: Boolean;
    RunType: TRunType;  // 0 - None, 1 - Command, 2 - Dialog
    Id, Ident, Parent, Order: Integer;
    ScriptName, Command: String;
    ScriptText: TStringStream;
    constructor Create;
  end;
  
  { TPackage }

  TPackage=class
    PackageInfo: TPackageInfo;
    Scripts: TList<TDCLScriptItem>;
    constructor Create;
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
    procedure ParseDependenciesSection(TextPackage: TStringList);
    function CalcPackageHash: String;
    function GetBase41Sequence: String;
  public
    constructor Create;

    procedure Load(Package: TStream);
    function EncodePackage(RunOnStart: Boolean): TStream;

    procedure ClearFiles;
    procedure AddFile(FileName: String; RunType: TRunType);
    function AddMenuItem(Title, Command: String; Ident, Parent: Integer): TDCLScriptItem;
    procedure AddUpdate(FileName: String; Order: Integer);

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

const
  KeySection='Key';
  ForUpdateSection='ForUpdate';
  NameSection='Name';
  EndNameSection='EndName';
  UpdateSection='SQLUpdate';
  EndUpdateSection='UpdateEnd';
  OrderSection='Order';
  IdentSection='Ident';
  ParentSection='Parent';
  IdSection='Id';
  RunTypeSection='RunType';
  CommandSection='Command';
  PackageNameSection='Name';
  RunOnStartSection='RunOnStart';
  SignHashSection='Sign';
  DependOnSection='DependOn';

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

{ TPackageInfo }

constructor TPackageInfo.Create;
begin
  Dependencies:=TList<String>.Create;
end;

{ TDCLScriptItem }

constructor TDCLScriptItem.Create;
begin
  ScriptText:=TStringStream.Create('', TEncoding.UTF8);
end;

{ TPackage }

constructor TPackage.Create;
begin
  PackageInfo:=TPackageInfo.Create;
  Scripts:=TList<TDCLScriptItem>.Create;
end;

function TDCLScriptsPackage.GetPackageInfo: TPackageInfo;
begin
  Result:=FPackage.PackageInfo;
end;

function TDCLScriptsPackage.GetSign(Login, Password, Hash: String): String;
begin
  Result:='DCL;'+Login+'\'+Password+'\'+Hash;
end;

procedure TDCLScriptsPackage.SignPackage(Login, Password: String);
var
  S: String;
begin
  S:='';
  FPackage.PackageInfo.Hash:=CalcPackageHash;
  if FPackage.PackageInfo.ForUpdate then
    S:=';AllowUpdate!';
  FPackage.PackageInfo.Sign:=MD5Print(MD5String(GetSign(Login+S, Password, FPackage.PackageInfo.Hash+S)));
end;

function TDCLScriptsPackage.CheckPackage(Login, Password: String): Boolean;
var
  S, sh: String;
begin
  S:='';
  FPackage.PackageInfo.Hash:=CalcPackageHash;
  if FPackage.PackageInfo.ForUpdate then
    S:=';AllowUpdate!';
  sh:=MD5Print(MD5String(GetSign(Login+S, Password, FPackage.PackageInfo.Hash+S)));
  Result:=sh=FPackage.PackageInfo.Sign;
end;

constructor TDCLScriptsPackage.Create;
begin
  FPackage:=TPackage.Create;
  FPackage.PackageInfo:=TPackageInfo.Create;
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

procedure TDCLScriptsPackage.AddUpdate(FileName: String; Order: Integer);
var
  si: TDCLScriptItem;
begin
  si:=TDCLScriptItem.Create;
  si.SQL:=True;
  si.ScriptName:=ExtractFileNameOnly(FileName);
  si.Order:=Order;
  si.ScriptText:=TStringStream.Create('', TEncoding.UTF8);
  si.ScriptText.LoadFromFile(FileName);

  FPackage.Scripts.Add(si);
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
  Base41X, S, HashKey: String;
  b, b1, w: Word;
  TextPackage: TStringList;
begin
  Result:=TMemoryStream.Create;
  if FPackage.PackageInfo.Sign<>'' then
  begin
    TextPackage:=TStringList.Create;
    TextPackage.Clear;

    HashKey:=Copy(FPackage.PackageInfo.Sign, 1, 6);

    S:='';
    if FPackage.PackageInfo.Name<>'' then
      S:=PackageNameSection+'='+FPackage.PackageInfo.Name+';';
    if RunOnStart then
      S:=S+RunOnStartSection+'=1;';
    if FPackage.PackageInfo.ForUpdate then
      S:=S+ForUpdateSection+'=1;';
    TextPackage.Append('['+SignHashSection+'='+FPackage.PackageInfo.Sign+';Version='+PackagesVersion+';'+S+']');
    if FPackage.PackageInfo.Dependencies.Count>0 then
    begin
      S:='['+DependOnSection+'='+S.Join(',', FPackage.PackageInfo.Dependencies.ToArray)+';]';
      TextPackage.Append(S);
    end;

    for I in FPackage.Scripts do
    begin
      S:='';
      if not I.SQL then
      begin
        if I.Id<>0 then
        begin
          S:=S+IdSection+'='+IntToStr(I.Id)+';';
        end;
        if I.RunType<>rtNone then
        begin
          S:=S+RunTypeSection+'='+IntToStr(Ord(I.RunType))+';';
        end;
        if I.Command<>'' then
        begin
          S:=S+CommandSection+'='+I.Command+';';
        end;

        if I.Ident<>0 then
        begin
          S:=S+IdentSection+'='+IntToStr(I.Ident)+';';
        end;
        if I.Parent<>0 then
        begin
          S:=S+ParentSection+'='+IntToStr(I.Parent)+';';
        end;

        TextPackage.Append('['+NameSection+'='+I.ScriptName+';'+KeySection+'='+HashKey+';'+S+']');
        if Assigned(I.ScriptText) then
          TextPackage.Append(I.ScriptText.DataString);
        TextPackage.Append('['+EndNameSection+'='+I.ScriptName+';'+KeySection+'='+HashKey+']');
      end
      else
      begin
        if I.Order<>0 then
          S:=IntToStr(I.Order);

        TextPackage.Append('['+UpdateSection+'='+I.ScriptName+';'+KeySection+'='+HashKey+';'+S+']');
        if Assigned(I.ScriptText) then
          TextPackage.Append(I.ScriptText.DataString);
        TextPackage.Append('['+EndUpdateSection+'='+I.ScriptName+';'+KeySection+'='+HashKey+']');
      end;
    end;

    CompressedPackage:=TMemoryStream.Create;
    RawPackage:=TStringStream.Create(TextPackage.Text, TEncoding.UTF8);
    CompressProc(RawPackage, CompressedPackage);
    RawPackage.Free;
    FreeAndNil(TextPackage);

    Base41X:=GetBase41Sequence;

    S:='DCL5;';
    Result.Write(S[1], 5);

    S:=PackagesVersion+';';
    Result.Write(S[1], 4);

    w:=9;
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
  end
  else
  begin
    S:='Package not signed!';
    Result.Write(S[1], S.Length);
  end;
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
  Base41X, S: String;
  PackageText: TStream;
  TextPackage: TStringList;
  MS: TStream;
  Buffer: Array[1..3] of Word;
  FormatBuffer: Array[1..4] of Byte;
begin
  if Package.Read(FormatBuffer[1], 4)<>0 then
  begin
    if (FormatBuffer[1]=68) and (FormatBuffer[2]=67) and
      (FormatBuffer[3]=76) and (FormatBuffer[4]=53) then
    begin
      b:=1;
      Package.Read(b, 1);
      if Package.Read(FormatBuffer[1], 4)<>0 then
      begin
        if (FormatBuffer[4]=59) then
        begin
          S:='';
          for b:=1 to 3 do
          begin
            S:=S+Chr(FormatBuffer[b]);
          end;

          if PackagesVersion=S then
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
        end;
      end;
    end;
  end;
end;

procedure TDCLScriptsPackage.DisassemblyPackage(TextPackage: TStringList);
var
  b, f: Boolean;
  S, s1, sn, un, HashKey: String;
  ScriptItem: TDCLScriptItem;
begin
  FPackage.Scripts.Clear;
  ParsePackageHeader(TextPackage);
  ParseDependenciesSection(TextPackage);

  HashKey:=Copy(FPackage.PackageInfo.Sign, 1, 6);

  f:=True;
  b:=False;
  sn:='';
  un:='';
  for S in TextPackage do
  begin
    // region Name
    if (Pos('['+NameSection+'=', S)<>0) and (PosEx(KeySection+'='+HashKey, S)<>0) and (PosEx('['+SignHashSection+'=', S)=0) then
    begin
      s1:=FindParam(NameSection+'=', S);
      if s1<>'' then
      begin
        sn:=s1;
        ScriptItem:=TDCLScriptItem.Create;
        ScriptItem.ScriptName:=sn;

        s1:=FindParam(RunTypeSection+'=', S);
        if s1<>'' then
        begin
          ScriptItem.RunType:=TRunType(StrToInt(s1));
        end;

        s1:=FindParam(CommandSection+'=', S);
        if s1<>'' then
        begin
          ScriptItem.Command:=s1;
        end;

        s1:=FindParam(IdSection+'=', S);
        if s1<>'' then
        begin
          ScriptItem.Id:=StrToInt(s1);
        end;
        s1:=FindParam(IdentSection+'=', S);
        if s1<>'' then
        begin
          ScriptItem.Ident:=StrToInt(s1);
        end;

        s1:=FindParam(ParentSection+'=', S);
        if s1<>'' then
        begin
          ScriptItem.Parent:=StrToInt(s1);
        end;

        ScriptItem.ScriptText:=TStringStream.Create('', TEncoding.UTF8);
        b:=True;
        Continue;
      end;
    end;

    if (sn<>'') and (Pos('['+EndNameSection+'=', S)<>0) and (Pos(KeySection+'='+HashKey, S)<>0) then
    begin
      s1:=FindParam(EndNameSection+'=', S);
      if (s1<>'') and (s1=sn) then
      begin
        b:=False;
        FPackage.Scripts.Add(ScriptItem);
        sn:='';
        Continue;
      end;
    end;
    // end region Name

    // region Update
    if (Pos('['+UpdateSection+'=', S)<>0) and (PosEx(KeySection+'='+HashKey, S)<>0) and (PosEx('['+SignHashSection+'=', S)=0) then
    begin
      s1:=FindParam(UpdateSection+'=', S);
      if s1<>'' then
      begin
        un:=s1;
        ScriptItem:=TDCLScriptItem.Create;
        ScriptItem.SQL:=True;
        ScriptItem.ScriptName:=un;

        s1:=FindParam(OrderSection+'=', S);
        if s1<>'' then
        begin
          ScriptItem.Order:=StrToInt(s1);
        end;

        ScriptItem.ScriptText:=TStringStream.Create('', TEncoding.UTF8);
        b:=True;
        Continue;
      end;
    end;

    if (un<>'') and (Pos('['+EndUpdateSection+'=', S)<>0) and (Pos(KeySection+'='+HashKey, S)<>0) then
    begin
      s1:=FindParam(EndUpdateSection+'=', S);
      if (s1<>'') and (s1=un) then
      begin
        b:=False;
        FPackage.Scripts.Add(ScriptItem);
        un:='';
        Continue;
      end;
    end;
    // end region Update

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
      FPackage.PackageInfo.ForUpdate:=FindParam(ForUpdateSection+'=', S)='1';
      FPackage.PackageInfo.Sign:=FindParam(SignHashSection+'=', S);
      FPackage.PackageInfo.Name:=FindParam(PackageNameSection+'=', S);
      FPackage.PackageInfo.RunOnStart:=FindParam(RunOnStartSection+'=', S)='1';
      FPackage.PackageInfo.Version:=FindParam('Version=', S);
      Break;
    end;
  end;
end;

procedure TDCLScriptsPackage.ParseDependenciesSection(TextPackage: TStringList);
var
  S, h: String;
  hashes: Array of String;
begin
  for S in TextPackage do
  begin
    if PosEx('['+DependOnSection+'=', S)=1 then
    begin
      FPackage.PackageInfo.Dependencies.Clear;
      hashes:=FindParam(DependOnSection+'=', S).Split(',');
      for h in hashes do
      begin
        FPackage.PackageInfo.Dependencies.Add(h);
      end;

      Break;
    end;
  end;
end;

end.

