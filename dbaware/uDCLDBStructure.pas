unit uDCLDBStructure;

interface

const
  DCL_TablePrefix='DCL_';

  DCLTable=DCL_TablePrefix+'SCRIPTS';
  IdField='ID_SCR';
  IdentifyField='IDENT';
  ParentField='PARENT';
  DCLNameField='SCR_NAME';
  CommandField='COMMAND';
  ScriptField='SCR_TEXT';
  ScrLastUpdField='UPDATES';

  RolesTable=DCL_TablePrefix+'ROLES';
  RolesIDFiled='ID_Role';
  RoleNameField='Role_Name';
  LongRoleNameField='LONG_ROLE_NAME';
  RolesLastUpdField='LAST_UPDATE';

  RolesMenuTable=DCL_TablePrefix+'ROLESMENU';
  RolesMenuIDFiled='RoleID';
  RoleMenuItemIDField='MenuItem_ID';

  UsersTable=DCL_TablePrefix+'USERS';
  UserIDField='UID';
  UserNameField='DCL_USER_NAME';
  LongUserNameField='DCL_LONG_USER_NAME';
  UserPassField='DCL_USER_PASS';
  UserAdminField='ACCESS_LEVEL';

  ShowInListField='SHOW_IN_LIST';

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

  UpdatePackageTable=DCL_TablePrefix+'UPDATE_PACKAGES';
  IDPackageField='PU_ID';
  PackageNameField='PACKAGE_NAME';
  PackageHashField='PACKAGE_HASH';
  PackageUpdateState='STATE';
  PackageLastUpdate='UPDATE_DATE';

  UpdateScriptsTable=DCL_TablePrefix+'PACKAGE_SCRIPTS';
  UpdateScriptIDField='PS_ID';
  PackageIDField='PACKAGE_ID';
  UpdateScriptNameField='SCRIPT_NAME';
  UpdateScriptTypeField='SCRIPT_TYPE';

implementation

end.

