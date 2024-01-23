unit hddinfo;
{$mode delphi}

interface

uses 
  Windows, SysUtils, Classes;

type
  THDDInfo = class(TObject)
  private
    FDriveNumber: byte;
    FFileHandle: cardinal;
    FInfoAvailable: boolean;
    FProductRevision: string;
    FProductId: string;
    FSerialNumber: string;
    FVendorId: string;

    procedure ReadInfo;
    procedure SetDriveNumber(const Value: byte);
  public
    constructor Create;
    property DriveNumber: byte read FDriveNumber write SetDriveNumber;
    property VendorId: string read FVendorId;
    property ProductId: string read FProductId;
    property ProductRevision: string read FProductRevision;
    property SerialNumber: string read FSerialNumber;
    property InfoAvailable: boolean read FInfoAvailable;
  end;

implementation

const
  IOCTL_STORAGE_QUERY_PROPERTY = $2D1400;

type
  STORAGE_PROPERTY_QUERY = packed record
    PropertyId: DWORD;
    QueryType: DWORD;
    AdditionalParameters: array[0..3] of byte;
  end;

  STORAGE_DEVICE_DESCRIPTOR = packed record
    Version: ULONG;
    Size: ULONG;
    DeviceType: byte;
    DeviceTypeModifier: byte;
    RemovableMedia: boolean;
    CommandQueueing: boolean;
    VendorIdOffset: ULONG;
    ProductIdOffset: ULONG;
    ProductRevisionOffset: ULONG;
    SerialNumberOffset: ULONG;
    STORAGE_BUS_TYPE: DWORD;
    RawPropertiesLength: ULONG;
    RawDeviceProperties: array[0..511] of byte;
  end;

function ByteToChar(const B: byte): char;
begin
  Result := Chr(B + $30);
end;

constructor THddInfo.Create;
begin
  inherited;
  SetDriveNumber(0);
end;

procedure THDDInfo.ReadInfo;
type
  PCharArray = ^TCharArray;
  TCharArray = array[0..32767] of char;
var
  Returned: cardinal;
  Status: longbool;
  PropQuery: STORAGE_PROPERTY_QUERY;
  DeviceDescriptor: STORAGE_DEVICE_DESCRIPTOR;
  PCh: PChar;
begin
  FInfoAvailable := False;
  FProductRevision := '';
  FProductId := '';
  FSerialNumber := '';
  FVendorId := '';

  try
    FFileHandle := CreateFile(
      PChar('\\.\PhysicalDrive' + ByteToChar(FDriveNumber)),
      0, FILE_SHARE_READ or
      FILE_SHARE_WRITE, nil, OPEN_EXISTING,
      0, 0);

    if FFileHandle = INVALID_HANDLE_VALUE then RaiseLastOSError;

    ZeroMemory(@PropQuery, SizeOf(PropQuery));
    ZeroMemory(@DeviceDescriptor, SizeOf(DeviceDescriptor));

    DeviceDescriptor.Size := SizeOf(DeviceDescriptor);

    Status := DeviceIoControl(FFileHandle,
      IOCTL_STORAGE_QUERY_PROPERTY, @PropQuery,
      SizeOf(PropQuery), @DeviceDescriptor,
      DeviceDescriptor.Size, Returned,
      nil);

    if not Status then RaiseLastOSError;

    if DeviceDescriptor.VendorIdOffset <> 0 then
    begin
      PCh := @PCharArray(@DeviceDescriptor)^[DeviceDescriptor.VendorIdOffset];
      FVendorId := PCh;
    end;

    if DeviceDescriptor.ProductIdOffset <> 0 then
    begin
      PCh := @PCharArray(@DeviceDescriptor)^[DeviceDescriptor.ProductIdOffset];
      FProductId := Trim(PCh);
    end;

    if DeviceDescriptor.ProductRevisionOffset <> 0 then
    begin
      PCh := @PCharArray(@DeviceDescriptor)^[DeviceDescriptor.ProductRevisionOffset];
      FProductRevision := Trim(PCh);
    end;

    if DeviceDescriptor.SerialNumberOffset <> 0 then
    begin
      PCh := @PCharArray(@DeviceDescriptor)^[DeviceDescriptor.SerialNumberOffset];
      FSerialNumber := Trim(PCh);
    end;

    FInfoAvailable := True;
  finally
    if FFileHandle <> INVALID_HANDLE_VALUE then CloseHandle(FFileHandle);
  end;
end;

procedure THDDInfo.SetDriveNumber(const Value: byte);
begin
  FDriveNumber := Value;
  ReadInfo;
end;

end.
