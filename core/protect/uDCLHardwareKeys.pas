unit uDCLHardwareKeys;
{$mode Delphi}

interface

uses
  Classes, SysUtils,
  hddinfo;

type

  { TDCLHardwareKeys }

  TDCLHardwareKeys = class
  private
    FHDDInfoWin: THDDInfo;
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
  FHDDInfoWin:=THDDInfo.Create;
  FHWData:=FHDDInfoWin.SerialNumber;
end;

destructor TDCLHardwareKeys.Destroy;
begin
  FreeAndNil(FHDDInfoWin);
  inherited Destroy;
end;

function TDCLHardwareKeys.GetKey: String;
begin
  Result:=FHWData;
end;

end.

