unit uSingleInstance;
{$mode Delphi}

interface

uses
  Classes, SysUtils;

type

  { TSingleInstanceMutex }

  TSingleInstanceMutex = class
  private
    FFilePath: String;
    FFileStream: TFileStream;

    function CheckMutex: Boolean;
  public
    constructor Create(const MutexFileName: String);
    destructor Destroy; override;

    property Check: Boolean read CheckMutex;
  end;

implementation

{ TSingleInstanceMutex }

function TSingleInstanceMutex.CheckMutex: Boolean;
var
  fMask: UInt16;
begin
  fMask:=fmOpenReadWrite or fmShareExclusive;
  if not FileExists(FFilePath) then
    fMask:=fMask or fmCreate;

  try
    FFileStream:=TFileStream.Create(FFilePath, fMask);
    {$IFDEF MSWINDPWS}
    FileSetAttr(FFilePath, faHidden);
    {$ENDIF}
    Result:=False;
  except
    Result:=True;
  end;
end;

constructor TSingleInstanceMutex.Create(const MutexFileName: String);
begin
  inherited Create;
  FFileStream:=nil;
  FFilePath:=MutexFileName;
end;

destructor TSingleInstanceMutex.Destroy;
begin
  FreeAndNil(FFileStream);
  if FileExists(FFilePath) then
    DeleteFile(FFilePath);
  inherited Destroy;
end;

end.

