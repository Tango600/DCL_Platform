unit uDCLQueryUtils;
{$mode Delphi}

interface

uses
  Classes, SysUtils,
  uDCLDBStructure, uDCLGlobalVariables;

function GetRolesQueryText(Where, UserID: String): String;

implementation

function GetRolesQueryText(Where, UserID: String): String;
begin
  If GPT.DCLUserName='' Then
  begin
    Result:='select * from '+DCLTable+' where '+Where+' order by '+IdentifyField+', '+ParentField;
  end
  else
  begin
    If GPT.MultiRolesMode Then
    begin
      Result:='select s.* from '+DCLTable+' s, '+RolesMenuTable+' rm, '+RolesTable+' r, '+UsersTable+' u, '+
        RolesToUsersTable+' ru '+' where r.'+RolesIDFiled+'=rm.'+RolesMenuIDFiled+' and rm.'+RoleMenuItemIDField+'=s.'+
        IdField+' and ru.'+RolesToUsersRoleIDField+'=r.'+RolesIDFiled+' and u.'+UserIDField+
        '=ru.'+RolesToUsersUserIDField+' and u.'+UserIDField+'='+UserID+' and '+Where+' order by s.'+IdentifyField+', s.'+ParentField;
    end
    Else
    begin
      Result:='select s.* from '+DCLTable+' s, '+RolesMenuTable+' rm, '+RolesTable+' r, '+UsersTable+' u '+
      'where r.'+RolesIDFiled+'=rm.'+RolesMenuIDFiled+' and rm.'+RoleMenuItemIDField+'=s.'+
        IdField+' and u.'+UserRoleField+'=r.'+RolesIDFiled+' and u.'+UserIDField+'='+
        UserID+' and '+Where+' order by s.'+IdentifyField+', s.'+ParentField;
    end;
  end;
end;

end.

