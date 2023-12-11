unit uDCLGlobalConfigTable;

interface

uses
  uDCLConst;

type
  TGPT=record
  // EnableSQLTrace,
    DebugMesseges, ExitCnf, UseMessages,
    DialogsSettings, DisableColors, DisableFieldsList,
    DisableUnload, DisableLoad, EasyIdentMode, DisableIniPasword, IBAll: Boolean;
    OneCopy, Port: Integer;
    DateSeparator, TimeSeparator, ThousandSeparator, DecimalSeparator: Char;
    ServerCodePage, DateFormat, TimeFormat, Viewer, MainFormCaption,
    DataBaseName, ScriptDir, DBPath, ServerName, DBType: String;
    SQLDialect: Byte;
    NoParamsTable, NoUsersTable, DisableLogOnWithoutUser: Boolean;
    DBUserName, DCLUserName, DCLUserPass, EnterPass, LongRoleName, GetValueSeparator,
    IniFileName, BaseID,
    StringTypeChar,
    TimeStampFormat, DCLLongUserName, UserID, RoleID,
    DCLRoleName, DBPassword, LibPath,
    WordOLEExtension, ExcelOLEExtension: String;
    OfficeDocumentFormat: TOfficeDocumentFormat;
    OfficeFormat: TOfficeFormat;
    AccessLevel: TUserLevelsType;
  end;

implementation

end.

