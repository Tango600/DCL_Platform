unit uDCLGlobalConfigTable;

interface

uses
  Graphics, uDCLConst;

type
  TGPT=record
  // EnableSQLTrace,
    DebugMesseges, ExitCnf, UseMessages, IDEReadOnly,
    DialogsSettings, DisableColors, DisableFieldsList, KioskMode,
    DisableUnload, DisableLoad, EasyIdentMode, IBAll, MySQL: Boolean;
    OneCopy: TOneCopyMode;
    Port: Integer;
    MainColor, TablePartColor, GridColor, GridAlternateColor: TColor;
    DateSeparator, TimeSeparator, ThousandSeparator, DecimalSeparator: Char;
    ServerCodePage, DateFormat, TimeFormat, Viewer, MainFormCaption,
    DataBaseName, ScriptDir, DBPath, ServerName, DBType, LangName,
    Signer, SignerPass: String;
    SQLDialect: Byte;
    NoParamsTable, NoUsersTable, DisableLogOnWithoutUser, DisableColorScheme: Boolean;
    DBUserName, DCLUserName, DCLUserPass, EnterPass, LongRoleName,
    IniFileName, BaseID,
    StringTypeChar, Lib32, Lib64,
    TimeStampFormat, DCLLongUserName, UserID, RoleID,
    DCLRoleName, DBPassword, LibPath, AppConfigDir,
    WordOLEExtension, ExcelOLEExtension: String;
    //OfficeDocumentFormat: TOfficeDocumentFormat;
    OfficeFormat: TOfficeFormat;
    AccessLevel: TUserLevelsType;
    MenuType: TMenuType;
  end;

implementation

end.