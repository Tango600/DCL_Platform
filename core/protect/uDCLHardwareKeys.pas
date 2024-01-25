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
  ;

type

  { TDCLHardwareKeys }

  TDCLHardwareKeys = class
  private
    {$IFDEF MSWINDOWS}
    FHDDInfoWin: THDDInfo;
    {$ENDIF}
    {$IFDEF LINUX}
    FPartsInfo: TDiskPartInfo;
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
  FHDDInfoWin:=THDDInfo.Create;
  FHWData:=FHDDInfoWin.SerialNumber;
{$ENDIF}
{$IFDEF LINUX}
  FPartsInfo:=TDiskPartInfo.Create;
  FHWData:=FPartsInfo.PartitionID;
{$ENDIF}
end;

destructor TDCLHardwareKeys.Destroy;
begin
{$IFDEF MSWINDOWS}
  FreeAndNil(FHDDInfoWin);
{$ENDIF}
{$IFDEF LINUX}
  FreeAndNil(FPartsInfo);
{$ENDIF}
  inherited Destroy;
end;

function TDCLHardwareKeys.GetKey: String;
begin
  Result:=FHWData;
end;

end.

