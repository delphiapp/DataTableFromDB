program ServerDB;

uses
  Windows,
  Forms,
  SysUtils,
  mORMot,
  SynSQlite3,
  mORMotSQLite3,
  DB,
  SynDBVCL,
  SynDBSQLite3,
  SynDB,
  SynCommons,
  Dialogs,
  mORMotHttpServer,
  uServerDB in 'uServerDB.pas' {frmMain},
  uDBOtchetRecord in 'uDBOtchetRecord.pas';

{$R *.res}


procedure ConnectDB;
begin
  frmMain.Model := CreateSampleModel;
  sqlite3 := TSQLite3LibraryDynamic.Create;
  frmMain.Database := TSQLRestServerDB.Create(frmMain.Model, IncludeTrailingBackslash(frmMain.DirDBName)+DBName);//,True,'report');
  if not Assigned(frmMain.Database) then
    raise Exception.Create('Ошибка при соединении или создании БД отчета');
  TSQLRestServerDB(frmMain.Database).CreateMissingTables;
  TSQLRestServerDB(frmMain.Database).NoAJAXJSON:=False;
  TSQLRestServerDB(frmMain.Database).DB.BackupBackground(ExtractFilePath(Application.ExeName)+'report_reserv.db3',1024,10,nil);
  frmMain.SQLiteHTTPServer := TCustomHttpServer.Create(IPPortServer,[TSQLRestServerDB(frmMain.Database)],'+',{useHttpSocket}useHttpApiRegisteringURI,32,secNone,'report');
  frmMain.SQLiteHTTPServer.AccessControlAllowOrigin := '*'; // for AJAX requests to work
  frmMain.SQLiteHTTPServer.RootRedirectToURI('report/indexdb.html'); // redirect localhost:777
end;

var
  HM: THandle;

function Check: boolean;
begin
  HM := OpenMutex(MUTEX_ALL_ACCESS, false, 'ServerDB');
  Result := (HM <> 0);
  if HM = 0 then HM := CreateMutex(nil, false, 'ServerDB');
end;

begin
  if Check then exit;
  if ParamCount>0 then
    if ParamStr(1)='/unregserver' then
    begin
      UnRegServer;
      Exit;
    end;
  Application.Initialize;
  Application.Title := 'Сервер БД';
  Application.CreateForm(TfrmMain, frmMain);
  Application.ShowMainForm:=False;
  if ParamCount>0 then if ParamStr(1)='/regserver' then RegServer;
  ConnectDB;
  Application.Run;
end.
