unit uDCLDBStructure;
{$mode Delphi}

interface

const
  UserAdminField='ACCESSLEVEL';

  DCL_TablePrefix='DCL_';

  DCLTable=DCL_TablePrefix+'SCRIPTS';

  IdField='NUMSEQ';
  IdentifyField='IDENT';
  ParentField='PARENT';
  DCLNameField='DCLNAME';
  CommandField='COMMAND';
  ScriptField='DCLTEXT';

  INITable=DCL_TablePrefix+'INI_PROFILES';
  IniKeyField='INI_ID';
  IniUserFieldName='INI_USER_ID';
  IniDialogNameField='INI_DIALOG_NAME';
  IniParamValField='INI_PARAM_VALUE';

  RolesTable=DCL_TablePrefix+'ROLES';
  RolesMenuTable=DCL_TablePrefix+'ROLESMENU';
  UsersTable=DCL_TablePrefix+'USERS';
  RolesIDFiled='RolesID';
  RolesMenuIDFiled='RoleID';
  RoleNameField='RoleName';
  LongRoleNameField='LONGROLENAME';
  RoleMenuItemIDField='MenuItemID';

  UserIDField='UID';
  UserNameField='DCL_USER_NAME';
  LongUserNameField='DCL_LONG_USER_NAME';
  UserPassField='DCL_USER_PASS';
  DBUSER_NAME_Field='DBUSER_NAME';
  DBPASS_Field='DBPASS';
  UserRoleField='DCL_ROLE';
  DCLROLE_ACCESSLEVEL_FIELD='ROLE_ACCESSLEVEL';

  RolesToUsersTable=DCL_TablePrefix+'ROLES_TO_USERS';
  RolesToUsersUserIDField='ru_userid';
  RolesToUsersRoleIDField='ru_roleid';

  BinStorageTable=DCL_TablePrefix+'TEMPLATES';
  BinDataId='TEID';
  BinStorageNameField='TEMPL_NAME';
  BinDataField='TEMPL_DATA';

  GPTTableName=DCL_TablePrefix+'GLOBAL_PARAMS';
  GPTNameField='PARAM_NAME';
  GPTValueField='PARAM_VALUE';
  GPTUserIDField='PARAM_USERID';

  NotifycationsTable=DCL_TablePrefix+'NOTIFYCATIONS';


implementation

end.

