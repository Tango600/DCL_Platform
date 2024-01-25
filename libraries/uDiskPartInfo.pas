unit uDiskPartInfo;
{$mode Delphi}

interface

uses
  Classes, SysUtils, FileUtil, Generics.Collections;

type
  
  { TDiskPartInfo }

  TDiskPartInfo = class
  private
    FPartID: String;
    FInfoAvailable: Boolean;

    procedure ReadInfo;
  public
    constructor Create;
    destructor Destroy; override;

    property PartitionID: String read FPartID;
    property InfoAvailable: boolean read FInfoAvailable;
  end;

implementation

{ TDiskPartInfo }

procedure TDiskPartInfo.ReadInfo;
var
  devList, disklist: TStringList;
  p, l: Integer;
  f, f1, s: String;
  devIds: TSortedList<String>;
begin
  disklist:=TStringList.Create;
  devList:=FindAllFiles('/dev/disk/by-id');

  for f in devList do
  begin
    p:=f.LastIndexOf(PathDelim);
    s:=f.Substring(p+1);
    if not s.StartsWith('usb-') then
      disklist.Append(s);
  end;
  FreeAndNil(devList);

  devIds:=TSortedList<String>.Create;
  devIds.Duplicates:=dupIgnore;

  FInfoAvailable:=False;
  for f in disklist do
  begin
    l:=f.Length;
    for f1 in disklist do
    begin
      if (l>f1.Length) and (f.StartsWith(f1)) and (f1<>f) then
      begin
        l:=f1.Length;
        FInfoAvailable:=True;
        devIds.Add(f1);
      end;
    end;
  end;
  FreeAndNil(disklist);

  FPartID:='';
  if FInfoAvailable then
    FPartID:=devIds[0];
  FreeAndNil(devIds);
end;

constructor TDiskPartInfo.Create;
begin
  ReadInfo;
end;

destructor TDiskPartInfo.Destroy;
begin
  inherited Destroy;
end;

end.

