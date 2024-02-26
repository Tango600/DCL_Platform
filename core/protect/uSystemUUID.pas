unit uSystemUUID;
{$mode Delphi}

interface

uses
  Classes, SysUtils, process;

type

  { TSystemUUID }

  TSystemUUID = class
  private
    FUUID: String;
    FInfoAvailable: Boolean;

    procedure ReadUUID;
  public
    constructor Create;
    property UUID: String read FUUID;
    property InfoAvailable: boolean read FInfoAvailable;
  end;

implementation

{ TSystemUUID }

procedure TSystemUUID.ReadUUID;
const
  BUF_SIZE=2048;
var
  P: TProcess;
  MS: TMemoryStream;
  BytesRead: longint;
  Buffer: array[1..BUF_SIZE] of Byte;
  T: TStringList;
  S, v: String;
  i: Integer;
begin
  P:=TProcess.Create(nil);
  P.Executable:='ioreg';
  P.Parameters.Add('-d2');
  P.Parameters.Add('-c');
  P.Parameters.Add('IOPlatformExpertDevice');
  P.Options:=[poUsePipes];

  MS:=TMemoryStream.Create;
  P.Execute;
  Sleep(100);
  BytesRead:=P.Output.Read(Buffer, BUF_SIZE);
  MS.Write(Buffer, BytesRead);
  FreeAndNil(P);

  T:=TStringList.Create;
  MS.Position:=0;
  T.LoadFromStream(MS);
  FreeAndNil(MS);

  for S in T do
  begin
    if S.Contains('IOPlatformSerialNumber') then
    begin
      i:=Pos('=', S);
      if i>0 then
      begin
        v:=Copy(S, i+1, Length(S));
        FUUID:=v.Trim.Replace('"', '');
        FInfoAvailable:=True;
      end;

      break;
    end;
  end;
  FreeAndNil(T);
end;

constructor TSystemUUID.Create;
begin
  FInfoAvailable:=False;
  ReadUUID;
end;

end.

