unit uDCLHardwareKeys;
{$mode Delphi}

interface

uses
  Classes, SysUtils,
{$IFDEF MSWINDOWS}
  hddinfo
{$ENDIF}
{$IFDEF LINUX}
  uDiskPartInfo
{$ENDIF}
{$IFDEF DARWIN}
  uSystemUUID
{$ENDIF}
  ;

type

  { TDCLHardwareKeys }

  TDCLHardwareKeys = class
  private
    FHWInfo:
    {$IFDEF MSWINDOWS}
    THDDInfo;
    {$ENDIF}
    {$IFDEF LINUX}
    TDiskPartInfo;
    {$ENDIF}
    {$IFDEF DARWIN}
    TSystemUUID;
    {$ENDIF}

    FHWData: String;
  public
    constructor Create;
    destructor Destroy; override;

    function GetKey: String;
  end;

implementation

{ TDCLHardwareKeys }

constructor TDCLHardwareKeys.Create;
begin
{$IFDEF MSWINDOWS}
  FHWInfo:=THDDInfo.Create;
  FHWData:=FHWInfo.SerialNumber;
{$ENDIF}
{$IFDEF LINUX}
  FHWInfo:=TDiskPartInfo.Create;
  FHWData:=FHWInfo.PartitionID;
{$ENDIF}
{$IFDEF DARWIN}
  FHWInfo:=TSystemUUID.Create;
  FHWData:=FHWInfo.UUID;
{$ENDIF}
end;

destructor TDCLHardwareKeys.Destroy;
begin
  FreeAndNil(FHWInfo);
  inherited Destroy;
end;

function TDCLHardwareKeys.GetKey: String;
begin
  Result:=FHWData;
end;

end.

