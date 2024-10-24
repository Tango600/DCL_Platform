unit uIDCLProtectionEngine;
{$mode Delphi}

interface

uses
  Classes, SysUtils,
  uKeyData;

type
  IDCLProtectionEngine = interface
    function GetProtectionStatus: Boolean;
    function GetProtectionKey: String;
    function ApplaySoftwareKey(const Key: String): Boolean;
    function GetKeyData: TKeyData;
    function ValidateKey(const Key: String): Boolean;
  end;

implementation

end.

