unit uIDCLProtectionEngine;
{$mode Delphi}

interface

uses
  Classes, SysUtils;

type
  IDCLProtectionEngine = interface
    function GetProtectionStatus: Boolean;
    function GetProtectionKey: String;
    function ApplaySoftwareKey(const Key: String): Boolean;
  end;

implementation

end.

