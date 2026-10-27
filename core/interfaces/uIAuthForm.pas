unit uIAuthForm;
{$mode delphi}

interface

uses
  Classes, SysUtils;

type
  EnuAuthFormResult = (afrNone, afrCancel, afrAccept, afrChangePassword);

  { RAuthData }

  RAuthData = record
    Accept: EnuAuthFormResult;
    Login, Password: String;
    procedure Clear;
  end;

  IAuthForm = interface
    function ShowAuthForm: RAuthData;

    function GetLogin: String;
    function GetPassword: String;
    function GetFormResult: RAuthData;

    property Login: String read GetLogin;
    property Password: String read GetPassword;
    property FormResult: RAuthData read GetFormResult;
  end;

implementation

{ RAuthData }

procedure RAuthData.Clear;
begin
  Accept:=afrNone;
  Login:='';
  Password:='';
end;

end.

