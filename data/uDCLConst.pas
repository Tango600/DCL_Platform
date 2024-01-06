unit uDCLConst;
{$I DefineType.pas}

interface

uses
{$IFDEF IBX}
  {$IFDEF IBXLaz}
  IBVersion,
  {$ENDIF}
{$ENDIF}
{$IFDEF ZEOS}
  ZClasses,
{$ENDIF}
  DBCtrls, DBGrids, LazVersion, SysUtils;

const
{$IFDEF MSWINDOWS}
  DefaultLibraryLocation='gds32.dll';
{$ENDIF}
{$IFDEF UNIX}
  DefaultLibraryLocation='libfbclient.so';
{$ENDIF}
{$IFDEF IBX}
  {$IFDEF IBXLaz}
  AccessLibVersion=IBX_VERSION;
  DBEngineType='IBX for Lazarus';
  {$ELSE}
  DBEngineType='IBX';
  AccessLibVersion='-';
  {$ENDIF}
{$ENDIF}
{$IFDEF ZEOS}
  DBEngineType='ZEOS (Universal)';
  DefaultIBPort=3050;
  DefaultDBType='firebird';
  DefaultDBTInterBaseType='interbase';
  AccessLibVersion=ZEOS_VERSION;
{$ENDIF}
{$IFDEF SQLdbIB}
  DBEngineType='SQLdb IB';
{$ENDIF}
{$IFDEF SQLdb}
  DBEngineType='SQLdb (Universal)';
{$ENDIF}
{$IFDEF ODBC}
  DBEngineType='SQLdb (ODBC)';
{$ENDIF}
{$IFDEF SQLdbFamily}
  AccessLibVersion=laz_version;
{$ENDIF}

{$I revision.inc}

  JPEGCompressionQuality=85;

  ShowFormPanel=True;

  PackagesFileExt='.dsp';
  PackagesVersion='1.4';

  BaiseUIDParamName='BaseUID';

  DBTypeFirebird='firebird';
  DBTypeInterbase='interbase';

  UserLevelsSet='Undefined,Deny,ReadOnly,Write,Execute,Level1,Level2,Level3,Level4,Updater,Signer,Developer';

  InternalAppNameSuffix='FPC';
  IndicatorWidth=DEFINDICATORCOLWIDTH;

  AppBuildDate={$I %DATE%};
  fpcVersion={$I %FPCVERSION%};
  TargetCPU={$I %FPCTARGETCPU%};
  TargetOS={$I %FPCTARGETOS%};
{$IFDEF UNIX}
  CrossDelim='\';
  OSType='posix';
{$ENDIF}
{$IFDEF MSWINDOWS}
  CrossDelim='/';
  OSType='windows';
{$ENDIF}
  GridAlternateColor=$f8f9f9;
  MemFileName='DCL_Run_Unit_'+DBEngineType;

  EncodingUTF8='utf8';
  AppTitle='DCL Platform';
  InternalAppName='DCLPlatform_'+InternalAppNameSuffix;

  ParamPrefix=':';
  FieldObjectPrefix='$';
  VariablePrefix='&';
  ParamsSepareteSimb=';';
  // DefaultValuesSeparator=',';
  // DefaultParamDelim='"';
  ProcPrefix='!!';
  MaskPassChar='#';
  ParamDelim='"';
  TabSize=2;
  FilterResetValue=-1;

  PAGSignatureSize=3;
  PAGSignature=$474150;

  FloatDelimiterFrom=',';
  FloatDelimiterTo='.';
  Quote=#39;

  StopSimbols=';( )[],=\/+-^<>.%:;&$#@*'#39#10#13;

  IntervalTimeToInitScripts=700;
  IntervalTimeNotify=61007;
  TimeToTerminate=5000;
  ExitTime=30;
  AutoResfreshInterval=90*1000;

  MainFormName='MainForm';

  NavigatorEditButtons=[nbEdit, nbDelete, nbInsert, nbPost, nbCancel];
  NavigatorNavigateButtons=[nbFirst, nbLast, nbRefresh];

  DefaultNavigButtonsSet='First,Last,Edit,Delete,Insert,Post,Cancel,Refresh';

  UpdatesDir='Updates';
  DCLDir='DCL5';
  FormConfigDir='Dialogs'+PathDelim;
  DefaultTimeSeparator=':';
  DefaultDateSeparator='.';
  DefaultDateFormat='dd'+DefaultDateSeparator+'mm'+DefaultDateSeparator+'yyyy';
  DefaultTimeFormat='hh'+DefaultTimeSeparator+'mm'+DefaultTimeSeparator+'ss';
  DefaultTimeStampFormat=DefaultDateFormat+' '+DefaultTimeFormat;

  ToolCommandsCount=3;
  ToolButtonsCmd: Array [1..ToolCommandsCount] Of String=('structure', 'print', 'find');

  TransParams=True;

Type
  TEventsEnum=(evtScroll, evtBeforeScroll, evtDelete, evtAfterOpen, evtAfterPost, evtCancel,
    evtInsert, evtLineDblClick, evtBeforePost, evtScrollPart, evtPostPart, evtClose);
  TUserLevelsType=(ulUndefined, ulDeny, ulReadOnly, ulWrite, ulExecute, ulLevel1, ulLevel2, ulLevel3, ulLevel4,
    ulUpdater, ulSigner, ulDeveloper);
  TGridStyle=(gsFields, gsFieldsHorizontal, gsGrid);
  TDataControlType=(dctMainGrid, dctSideGrid, dctTablePart, dctLookupGrid);

  TNotAllowedOperation=(dsoNone, dsoDelete, dsoInsert, dsoEdit);

  TChooseMode=(cmNone, cmChooseAndClose, cmChooseAndContinue);
  TLogOnStatus=(lsUnInitaliced, lsLogonOK, lsRejected, lsNotNeed);
  TPassStatus=(psNone, psConfirmed, psCanceled);
  TFormsNotifyAction=(fnaRefresh, fnaClose, fnaMinimize, fnaMaximaze, fnaSetMDI,
    fnaResetMDI, fnaHide, fnaShow);
  TIsDigitType=(idString, idDigit, idFloatDigit, idHex, idColor, idDateTime, idUserLevel);
  TDataStatus=(dssChanged, dssSaved);
  TNotifyActionsType=(naDone, naScriptRun, naMessage, naExecAndWait, naExec, naExitToTime);
  TQueryType=(qtMain, qtFind, qtDefault);
  TFilterType=(ftNone, ftDBFilter, ftContextFilter, ftComboFilter, ftTempFilter, ftGridFilter);
  TOfficeFormat=(ofNone, ofMSO, ofOO, ofPossible);
  TOfficeDocumentFormat=(odfNone, odfMSO97, odfMSO2007, odfOO, odfPossible);
  TDocumentType=(dtNone, dtSheet, dtText);
  TReportViewMode=(rvmOneRecord, rvmAllDS, rvmGrid, rvmMultitRecordReport, rvmBookmarcks);
  TFieldBoxType=(fbtDBField, fbtDBCheck, fbtOutBox, fbtInputBox, fbtEditBox, fbtSimplyCombo, fbtDBLookup, fbtDBCombo, fbtGrid);
  TGraficFileType=(gftNone, gftBMP, gftJPEG, gftPNG, gftIcon, gftGIF, gftTIFF, gftOther);
  TDCLDataFieldKind=(dftDefault, dftDateTime, dftMemo, dftGrafic, dftRichText, dftLogic, dftFloat, dftPickList);
  TSpoolType=(stNone, stSpool, stText);
  TGroupType=(gtGrafic, gtMemo, gtRichText);
  TFindType=(ftByIndex, ftByName, ftSQL);
  TNewQueryMode=(nqmNew, nqmFromGrid);
  TMessageType=(mbtError=0, mbtWarning=1, mbtInformation=9, mbtConfirmation=10);
  TSimplyFieldType=(sftNotDefine, sftString, sftDigit, sftFloat, sftDateTime, fstBlobMemo);
  TFieldFormat=(fftNone, fftDigit, fftDate, fftTime, fftDateTime, fftTrim, fftFloat);
  TSheetFillStrategy=(sfsInsert, sfsReplace);
  TFieldParsingMode=(fpmNone, fpmCaption, fpmField);
  TPopupMenuAction=(pmaNone, pmaCopy, pmaCut, pmaPaste, pmaUndo, pmaFindCurrCell, pmaDelTempFilter, pmaClearFind);
  TSortOrder=(soNone, soAsc, soDesc);
  TConditionTypes=(ctND, ctEq, ctNotEq, ctGt, ctGtEq, ctLe, ctLeEq, ctIn, ctNotIn,
    ctBt, ctNotBt);
  TPairCondition=(pcNone, pcAnd, pcOr);
  TTransactionType=(trtWrite, trtRead, trtUniversal);
  TMenuType=(mtClassic, mtPanels);

implementation


end.
