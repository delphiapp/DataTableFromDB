unit uServerDB;

interface

uses Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, mORMot, mORMotHttpServer, StdCtrls,
  ExtCtrls, SynCrtSock, SynCommons;

type

  TFormatUrlRequest = record

    iDraw: Cardinal;

    sDataColumn: array of string;
    sNameColumn: array of string;
    bUseSeachColumn: array of Boolean;
    bUseOrderColumn: array of Boolean;
    sSearchValueColumn: array of string;
    bUseRegExColumn: array of Boolean;

    iOrderColumn: Integer;
    sOrderDirection: string;
    iStartIndex: Integer;
    iLengthPage: Integer;
    sSearch: string;
    bUseRegEx: Boolean;

    function GetColumnCount(sl: TStringList): Integer;
    function InitRequestFromURI(const sReq:string):Boolean;
    procedure DecodeRequestTo(aReq:string;const sl:TStringList);
  end;

  TfrmMain = class(TForm)
    chkAutoStart: TCheckBox;
    btnExit: TButton;
    lbeIPHost: TLabeledEdit;
    lbeIPPort: TLabeledEdit;
    lbeDBName: TLabeledEdit;
    btnDir: TButton;
    procedure btnExitClick(Sender: TObject);
    procedure btnDirClick(Sender: TObject);
    procedure chkAutoStartMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
    DirDBName : TFileName;
    Model: TSQLModel;
    Database: TSQLRest;
    SQLiteHTTPServer: TSQLHttpServer;
    UrlRequest: TFormatUrlRequest;
  end;

  TCustomHttpServer = class(TSQLHttpServer)
  private
    procedure ParseURL(sReq: string; var dt: Byte;var lSerNomer: string; var lTipoisp: string;
                      var lZakaz: string;var lMes:string; var lGod:string);
    function CreateSQLQuery(sReq: string): string;
    function  GetIDAndDateTermoprTroughtSQL(sReq: string;var dt:Byte):RawUTF8;
    procedure UpdateProtocolToDB(aHTMLString: RawUTF8; sReq:string);
    function IsRequestProtocol(sReq:string):Boolean;
    procedure CorrectPathFor_IE_Chrome_MozillaNew(aCtxt: THttpServerRequest; var sReq:string);
    procedure LoadOtchetWithCKEditorToBrowser(aCtxt: THttpServerRequest;aOtchet:RawUTF8);
    function LoadFileNotFound(sReq:string):RawUTF8;
  protected
    /// override the server response - must be thread-safe
    function Request(Ctxt: THttpServerRequest): Cardinal; override;
  end;

function PathRemoveExtension(const Path: string): string;
procedure RegServer;
procedure UnRegServer;

var frmMain: TfrmMain;

const
  DirDelimiter  = '\';
  strProtokoly  = 'Протоколы';
  IPPortServer  ='7777';
  DBName        = 'report.db';

implementation

uses SynWinSock, Registry, StrUtils, uDBOtchetRecord, FileCtrl;

{$R *.dfm}

function PathRemoveExtension(const Path: string): string;
var I: Integer;
begin
  I := LastDelimiter(':.' + DirDelimiter, Path);
  if (I > 0) and (Path[I] = '.') then Result := Copy(Path, 1, I - 1)
  else Result := Path;
end;

procedure RegServer;
var Reg: TRegistry;
begin
  Reg := TRegistry.Create;
  with Reg do begin
    RootKey := HKEY_LOCAL_MACHINE;
    OpenKey('\Software\Microsoft\Windows\CurrentVersion\Run', true);
    WriteString(PathRemoveExtension(ExtractFileName(Application.ExeName)),
      Application.ExeName);
    CloseKey;
    Free;
  end;
end;

procedure UnRegServer;
var Reg: TRegistry;
begin
  Reg := TRegistry.Create;
  with Reg do begin
    RootKey := HKEY_LOCAL_MACHINE;
    OpenKey('\Software\Microsoft\Windows\CurrentVersion\Run', true);
    DeleteValue(PathRemoveExtension(ExtractFileName(Application.ExeName)));
    CloseKey;
    Free;
  end;
end;

procedure TfrmMain.btnDirClick(Sender: TObject);
var sDir:string;
begin
  if SelectDirectory('Папка расположения БД', DirDBName,sDir)then
  begin
    DirDBName:=sDir;
    lbeDBName.Text := IncludeTrailingBackslash(DirDBName)+DBName;
    Application.MessageBox('Изменения вступят в силу при перезапуске',
      PChar(Application.Title), MB_OK + MB_ICONINFORMATION);
  end;
end;

procedure TfrmMain.btnExitClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.chkAutoStartMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if chkAutoStart.Checked then RegServer else UnRegServer;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
var Reg: TRegistry;
begin
  DirDBName:=ExtractFileDir(Application.ExeName);
  Reg := TRegistry.Create;
  with Reg do begin
    RootKey := HKEY_LOCAL_MACHINE;
    OpenKey('\Software\Microsoft\Windows\CurrentVersion\Run', true);
    chkAutoStart.Checked :=
      (Application.ExeName = ReadString
      (PathRemoveExtension(ExtractFileName(Application.ExeName))));
    CloseKey;
    Free;
  end;
  lbeIPHost.Text := GetHostName;
  lbeIPPort.Text := IPPortServer;
  lbeDBName.Text:=ExtractFilePath(Application.ExeName)+DBName;
  if chkAutoStart.Checked then
    PostMessage(Handle,WM_SYSCOMMAND,SC_MINIMIZE,0);
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FreeAndNil(SQLiteHTTPServer);
  FreeAndNil(Database);
  FreeAndNil(Model);    
end;

{ TCustomHttpServer }

procedure TCustomHttpServer.CorrectPathFor_IE_Chrome_MozillaNew(aCtxt: THttpServerRequest; var sReq: string);
var ndx,numslash: Integer;
begin
  sReq := ReplaceText(sReq, '\', '/');
  ndx:=Pos('?',sReq);  if ndx>0 then Delete(sReq,ndx,MaxInt); //delete param after sign "?"
//  if ContainsText(aCtxt.InHeaders,'MSIE') or ContainsText(aCtxt.InHeaders,'Chrome') then
//  begin
    numslash:=0;
    ndx:=Pos('/',sReq);
    if ndx>0 then inc(numslash);
    repeat
      ndx:=PosEx('/',sReq,ndx+1);
      if ndx>0 then inc(numslash);
      if numslash=6 then
      begin
        sReq:=Copy(sReq,ndx+1,MaxInt); //delete param after sign "?"
        break;
      end;
    until ndx=0;
//  end;
end;

function TCustomHttpServer.CreateSQLQuery(sReq: string): string;
var lGod, lMesyac, lZakaz, lTipoisp, lSerNomer: string; dt: Byte;
begin
  ParseURL(sReq, dt, lSerNomer, lTipoisp, lZakaz, lMesyac, lGod);
  if (lZakaz <> '') and (lTipoisp <> '') and (lSerNomer <> '') then begin
    Result := Format
      ('SELECT %s from Device WHERE IDZAKAZA IN (SELECT ID FROM Zakaz WHERE NomerZakaza=''%s'') and '
      + 'IDTipoisp IN (SELECT ID FROM TIPOISP WHERE NameTipoisp=''%s'') and SerNomer=''%s''',
      [strDateTermopr[dt], StringToUTF8(lZakaz), StringToUTF8(lTipoisp),lSerNomer]);
  end;
end;

function TCustomHttpServer.GetIDAndDateTermoprTroughtSQL(sReq: string; var dt: Byte): RawUTF8;
var lGod, lMesyac, lZakaz, lTipoisp, lSerNomer: string;
begin
  ParseURL(sReq, dt, lSerNomer, lTipoisp, lZakaz, lMesyac, lGod);
  if (lZakaz <> '') and (lTipoisp <> '') and (lSerNomer <> '') then begin
    Result := Format
      ('SELECT ID from Device WHERE IDZAKAZA IN (SELECT ID FROM Zakaz WHERE NomerZakaza=''%s'') and '
      + 'IDTipoisp IN (SELECT ID FROM TIPOISP WHERE NameTipoisp=''%s'') and SerNomer=''%s''',
      [StringToUTF8(lZakaz), StringToUTF8(lTipoisp),lSerNomer]);
  end;
end;

function TCustomHttpServer.IsRequestProtocol(sReq: string): Boolean;
begin
  Result:=False;
  if StrUtils.ContainsText(sReq, '.nastrk') or
      StrUtils.ContainsText(sReq, '.termopr') or
      StrUtils.ContainsText(sReq, '.koeff') or
      StrUtils.ContainsText(sReq, '.htmlkoeff') then Result:=True;
end;

function TCustomHttpServer.LoadFileNotFound(sReq:string): RawUTF8;
begin
  Result:=StringToUTF8
  ('<html><head><meta http-equiv="content-type" content="text/html; '
  + 'charset=UTF-8"/></head><body><h1>' + sReq +
  '</h1><h2>Файл в БД не найден</h2>'+
  '</body></html>');
end;

procedure TCustomHttpServer.LoadOtchetWithCKEditorToBrowser(aCtxt: THttpServerRequest;
  aOtchet: RawUTF8);
begin
  aCtxt.OutContent :=StringToUTF8('<html>' + #13#10 +
  '<head>' + #13#10 +
      '<title>Редактор шаблона </title>' + #13#10 +
      '<meta http-equiv="content-type" content="text/html; charset=UTF-8" />' + #13#10 +
      '<script src="jquery-1.11.3.min.js" type="text/javascript"></script>' + #13#10 +
      '<script src="jquery.flot.js" type="text/javascript"></script>' + #13#10 +      
      '<script src="ckeditor.js" type="text/javascript"></script>' + #13#10 +
      '<script src="adapters/jquery.js"></script>'+#13#10+
  '</head>' + #13#10 +
  '<body >' + #13#10 +
      '	<style>' + #13#10 +
      '' + #13#10 +
      '		div.editable' + #13#10 +
      '		{' + #13#10 +
      '			border: solid 2px transparent;' + #13#10 +
      '			padding-left: 15px;' + #13#10 +
      '			padding-right: 15px;' + #13#10 +
      '		}' + #13#10 +
      '' + #13#10 +
      '		div.editable:hover' + #13#10 +
      '		{' + #13#10 +
      '			border-color: black;' + #13#10 +
      '		}' + #13#10 +
      '' + #13#10 +
      '	</style>' + #13#10 +
      '<div class="editorcontents" id="editorcontents">');

    if aOtchet<>'' then
      aCtxt.OutContent :=aCtxt.OutContent+ifthen(aOtchet[1]='<',aOtchet,'<pre>'+aOtchet+'</pre>');

    aCtxt.OutContent :=aCtxt.OutContent+StringtoUtf8('</div>' + #13#10 +
      '	<script>' + #13#10 +
      'var editor; var bsave=true;' + #13#10 +
      'window.onbeforeunload = function () {' + #13#10 +
        'return (bsave ? null : "Измененные данные не сохранены. Закрыть страницу?");' + #13#10 +
      '};'+ #13#10 +
      'replaceDiv( editorcontents);'+ #13#10 +
      '		function replaceDiv( div ) {' + #13#10 +
      '			if ( editor )' + #13#10 +
      '				editor.destroy();' + #13#10 +
      '			editor = CKEDITOR.replace( div , '+
      '{ on: {' + #13#10 +
      '''instanceReady'': function (evt) {'+#13#10 +
      '    evt.editor.execCommand(''maximize'');'+#13#10 +
      '    evt.editor.commands.save.enable();'+#13#10 +
      '// Create a new command with the desired exec function' + #13#10 +
      '    var overridecmd = new CKEDITOR.command(editor, {' + #13#10 +
      '    exec: function(editor){' + #13#10 +
      '// Replace this with your desired save button code' + #13#10 +
      '//get the text from ckeditor you want to save' + #13#10 +
      '   var data = editor.getData();' + #13#10 +
      '//get the current url' + #13#10 +
      '   var page = document.URL;'+
      '//Now we are ready to post to the server...' + #13#10 +
      '   $.ajax({' + #13#10 +
             'url: page,//the url to post at... configured in config.js' + #13#10 +
             'type: ''PUT'',' + #13#10 +
             'data: data' + #13#10 +
      '   })' + #13#10 +
      '   .done(function(response) {' + #13#10 +
             'bsave=true;'+#13#10 +
             'evt.editor.commands.save.disable();'+#13#10 +
             'alert("Успешно сохранено");' + #13#10 +
      '   })' + #13#10 +
      '   .fail(function() {' + #13#10 +
             'alert("Ошибка сохранения");' + #13#10 +
              'bsave=false;'+
      '   })' + #13#10 +
      '   .always(function() {' + #13#10 + 
      '   });'+
      '}' + #13#10 +
      '});' + #13#10 +
      '// Replace the old save''s exec function with the new one' + #13#10 +
      'evt.editor.commands.save.exec = overridecmd.exec;'+
      '},' + #13#10 +
          '''key'' : function(evt) {' + #13#10 +
              'evt.editor.commands.save.enable();' + #13#10 +
              'bsave=false;'+
      '},' + #13#10 +
      '''change'' : function(evt) {' + #13#10 +
          'evt.editor.commands.save.enable();' + #13#10 +
          'bsave=false;' + #13#10 +
      '},'+ #13#10 +
          '''mode'' : function(evt) {' + #13#10 +
              'evt.editor.commands.save.enable();' + #13#10 +
              'if ( this.mode == ''source'' ) {' + #13#10 +
                      'var editable = evt.editor.editable();' + #13#10 +
                      'editable.attachListener( editable,''input'', function() {' + #13#10 +
                          '// Handle changes made in the source mode.' + #13#10 +
                          'bsave=false;' + #13#10 +
                      '} );' + #13#10 +
              '}'+#13#10 +
      '}'+ #13#10 +
      '}'+ #13#10 +
      '});'+
      '		}' + #13#10 +
      '	</script>' + #13#10 +
    '</body>' + #13#10 +
  '</html>');
end;

function TCustomHttpServer.Request(Ctxt: THttpServerRequest): Cardinal;
var FileName: String; TableJSON: TSQLTableJSON;
  sReq: String; sl: TStringList; FSQLQuery: RawUTF8;
  lData_Otchet: TDataOtchet; IsValid: Boolean;
  sSortColumn : string; lDevice: TSQLRecordDevice;
begin
  if (Ctxt.Method = 'GET') and IdemPChar(pointer(Ctxt.URL), '/REPORT/') then
  begin
    // http.sys will send the specified file from kernel mode
    sReq := UTF8ToString(UrlDecode(Copy(Ctxt.URL, 8, MaxInt)));
    if StrUtils.ContainsText(sReq, 'dataurl') then
    begin
      with frmMain, Database do
      begin
        UrlRequest.InitRequestFromURI(sReq);

        case UrlRequest.iOrderColumn of
          1: sSortColumn:='Device.ID';
          2: sSortColumn:='Zakaz.NomerZakaza';
          3: sSortColumn:='Zakaz.Zakazchik';
          4: sSortColumn:='Device.SerNomer';
          5: sSortColumn:='Tipoisp.NameTipoisp';
          6: sSortColumn:='Device.God';
          7: sSortColumn:='Device.Mesyac';
          else sSortColumn:='Device.ID';
        end;

        if UrlRequest.sSearch <> '' then
            TableJSON := ExecuteList([TSQLRecordZakaz, TSQLRecordTipoisp, TSQLRecordDevice],
            Format('SELECT *, Zakaz.NomerZakaza, Zakaz.Zakazchik, Tipoisp.NameTipoisp '
            + 'FROM Device INNER JOIN Zakaz,Tipoisp ON Device.IDZAKAZA=ZAKAZ.ID AND Device.IDTIPOISP=TIPOISP.ID where device.sernomer LIKE ''%s'' LIMIT %d OFFSET %d',
            [StringToUTF8('%' + UrlRequest.sSearch + '%'),
            UrlRequest.iLengthPage, UrlRequest.iStartIndex]))
        else TableJSON := ExecuteList([TSQLRecordZakaz, TSQLRecordTipoisp, TSQLRecordDevice],
            Format('SELECT *, Zakaz.NomerZakaza, Zakaz.Zakazchik, Tipoisp.NameTipoisp '
            + 'FROM Device INNER JOIN Zakaz,Tipoisp ON Device.IDZAKAZA=ZAKAZ.ID AND Device.IDTIPOISP=TIPOISP.ID '
            + 'ORDER BY %s %s LIMIT %d OFFSET %d', [sSortColumn,IfThen(UrlRequest.sOrderDirection <> 'asc','DESC'),
                     UrlRequest.iLengthPage, UrlRequest.iStartIndex]));
        Ctxt.OutContent :=
          Format('{"sEcho": %d,"iTotalRecords": %d,"iTotalDisplayRecords": %d,"aaData":%s}',
          [UrlRequest.iDraw, TableJSON.RowCount, TableRowCount(Model['Device']), TableJSON.GetJSONValues(true)]);
      end;
      Ctxt.OutContentType := JSON_CONTENT_TYPE;
    end else if IsRequestProtocol(sReq) then //
    begin
      FSQLQuery := CreateSQLQuery(sReq);
      if FSQLQuery<>'' then
      begin
        TableJSON := frmMain.Database.ExecuteList
          ([TSQLRecordZakaz, TSQLRecordTipoisp, TSQLRecordDevice], FSQLQuery);
        try
          if Assigned(TableJSON) then begin
            lData_Otchet := TDataOtchet.Create;
            try
              JSONToObject(lData_Otchet, PUtf8Char(TableJSON.GetU(1, 0)), IsValid);
              if IsValid then begin
                LoadOtchetWithCKEditorToBrowser(Ctxt,lData_Otchet.Otchet);
                Ctxt.OutContentType := HTML_CONTENT_TYPE;
                Result := 200;
              end else begin
                Result := 204; //нет содержимого отчета или кривые данные отчета
                Ctxt.OutContent := LoadFileNotFound(sReq);
                Ctxt.OutContentType := HTML_CONTENT_TYPE;
              end;
            finally
              lData_Otchet.Free;
            end;
          end else begin
            Result := 404;
            Ctxt.OutContent := LoadFileNotFound(sReq);
            Ctxt.OutContentType := HTML_CONTENT_TYPE;
          end;
        finally
          TableJSON.Free;
        end;
      end;
    end else
    begin //for .js, .css, .jpg and so on
      CorrectPathFor_IE_Chrome_MozillaNew(Ctxt,sReq);
      FileName := Format('%s%s%s',[ExtractFilePath(ParamStr(0)),'Resource\HTML\report\',sReq]);
      if FileExists(FileName) then
      begin
        Ctxt.OutContent := StringFromFile(FileName);
        Ctxt.OutContentType :=GetMimeContentType(nil,0,FileName);
      end else Result := 404;
    end;
    Result := 200;
  end else
    if (Ctxt.Method = 'PUT') and IdemPChar(pointer(Ctxt.URL), '/REPORT/') then
    begin
      sReq := UTF8ToString(UrlDecode(Copy(Ctxt.URL, 8, MaxInt)));
      if IsRequestProtocol(sReq) then
      begin
        UpdateProtocolToDB(Ctxt.InContent,sReq);
        Result := 200;
      end;
    end else
    // call the associated TSQLRestServer instance(s)
      Result := inherited Request(Ctxt);
end;

procedure TCustomHttpServer.UpdateProtocolToDB(aHTMLString: RawUTF8; sReq: string);
var
  RecordDevice:TSQLRecordDevice; fSQLQuery:RawUTF8; TableJSON:TSQLTableJSON; lID:Integer; dt:Byte;
begin
  fSQLQuery:=GetIDAndDateTermoprTroughtSQL(sReq,dt);
  if FSQLQuery <>'' then
    TableJSON :=frmMain.Database.ExecuteList([TSQLRecordZakaz, TSQLRecordTipoisp, TSQLRecordDevice],FSQLQuery);
  if Assigned(TableJSON) then
  begin
    lID:=TableJSON.GetAsInteger(1,0);//ID
    if lID<>0 then
    begin
      if (lID=0) or (aHTMLString='') or (dt=0) then Exit;
      RecordDevice:=TSQLRecordDevice.Create(frmMain.Database,lID);
      try
        with RecordDevice do
        case dt of
          1: begin Otchety_nastrk.Otchet:=aHTMLString; Otchety_nastrk.Result:='Success';  end;
          2: begin Otchety_termo0.Otchet:=aHTMLString; Otchety_termo0.Result:='Success';  end;
          3: begin Otchety_termo8.Otchet:=aHTMLString; Otchety_termo8.Result:='Success';  end;
          4:begin Otchety_termo16.Otchet:=aHTMLString; Otchety_termo16.Result:='Success';  end;
          5:begin Otchety_termo24.Otchet:=aHTMLString; Otchety_termo24.Result:='Success';  end;
          6:begin Otchety_termo36.Otchet:=aHTMLString; Otchety_termo36.Result:='Success';  end;
          7:begin Otchety_termo48.Otchet:=aHTMLString; Otchety_termo48.Result:='Success';  end;
          8:begin Otchety_termo72.Otchet:=aHTMLString; Otchety_termo72.Result:='Success';  end;
          9: begin Otchety_Koeff.Otchet:=aHTMLString;  Otchety_Koeff.Result:='Success';  end;
          10: begin Otchety_HtmKoeff.Otchet:=aHTMLString;  Otchety_HtmKoeff.Result:='Success';  end;
          11:   begin Otchety_Test.Otchet:=aHTMLString; Otchety_Test.Result:='Success';  end;          
        end;
        frmMain.Database.Update(RecordDevice);
      finally
        RecordDevice.free;
      end;
    end;
  end;
end;

procedure TCustomHttpServer.ParseURL(sReq: string; var dt: Byte;
var lSerNomer: string; var lTipoisp: string; var lZakaz: string;var lMes:string; var lGod:string);
var
  I: Integer;
  iPosEnd: Integer;
  iPosStart: Integer;
  lEtap: string;
  lEtapRassh: string;
begin
  sReq := ReplaceText(sReq, '\', '/');
  iPosStart := Pos('/', sReq);
  if iPosStart > 0 then iPosStart := iPosStart + 1;
  iPosEnd := PosEx('/', sReq, iPosStart);
  for I := 1 to 6 do
  begin
    case I of
      1: lGod := Copy(sReq, iPosStart, iPosEnd - iPosStart);
      2: lMes := Copy(sReq, iPosStart, iPosEnd - iPosStart);
      3: lZakaz := Copy(sReq, iPosStart, iPosEnd - iPosStart);
      4: lTipoisp := Copy(sReq, iPosStart, iPosEnd - iPosStart);
      5: lSerNomer := Copy(sReq, iPosStart, iPosEnd - iPosStart);
      6: lEtapRassh := Copy(sReq, iPosStart, MaxInt);
    end;
    iPosStart := iPosEnd + 1;
    iPosEnd := PosEx('/', sReq, iPosStart);
  end;
  if ContainsText(lEtapRassh, 'nastrk') then
    dt := 1
  else if ContainsText(lEtapRassh, 'termopr') then
  begin
    iPosStart := Pos('_', lEtapRassh);
    iPosEnd := PosEx('.', lEtapRassh, iPosStart);
    lEtap := Copy(lEtapRassh, iPosStart + 1, iPosEnd - iPosStart - 1);
    case StrToIntDef(lEtap, -1) of
      0: dt := 2;
      8: dt := 3;
      16:dt := 4;
      24: dt := 5;
      36: dt := 6;
      48: dt := 7;
      72: dt := 8;
    else
      if lEtap <> 'temp' then
        raise Exception.Create('Не могу разобрать тип проверки')
      else
        dt := 11;
    end;
  end else
    if ContainsText(lEtapRassh, 'htmlkoeff') then dt:=10
      else if ContainsText(lEtapRassh, 'koeff') then dt:=9;//если сначала искать koeff то найдет соотв-ие даже если будет htmlkoeff, мы так не делаем
end;

{ TFormatUrlRequest }

procedure TFormatUrlRequest.DecodeRequestTo(aReq: string; const sl: TStringList);
var ndx: Integer;
begin
  if (aReq<>'') and Assigned(sl)  then
  begin
    ndx := Pos('&', aReq);
    while ndx <> 0 do begin
      sl.Add(Copy(aReq, 1, ndx - 1));
      Delete(aReq, 1, ndx);
      ndx := Pos('&', aReq);
    end;
    if aReq<>'' then sl.Add(aReq);

    if sl.Count <> 0 then begin
      ndx := Pos('?', sl[0]);
      if ndx <> 0 then sl[0] := Copy(sl[0], ndx + 1, MaxInt);
    end;
  end;
end;

function TFormatUrlRequest.GetColumnCount(sl: TStringList): Integer;
var indx, indx2: Integer; s: string;
begin
  if Assigned(sl) then begin
    s := sl.Strings[sl.Count - 7];
    indx := Pos('columns[', s);
    if indx > 0 then indx2 := PosEx(']', s, indx + 8);
    if indx2 > 0 then s := Copy(s, indx + 8, indx2 - indx - 8);
    Result := StrToIntDef(s, 0) + 1;
  end;
end;

function TFormatUrlRequest.InitRequestFromURI(const sReq:string): Boolean;
var
  I, icolcolumn: Integer;
  sl: TStringList;
begin
  sl := TStringList.Create;
  try
    DecodeRequestTo(sReq,sl);

    icolcolumn := GetColumnCount(sl);

    if icolcolumn<>0 then
    begin
      iDraw := StrToInt(sl.Values['draw']);
      SetLength(sDataColumn, icolcolumn);
      SetLength(sNameColumn, icolcolumn);
      SetLength(bUseSeachColumn, icolcolumn);
      SetLength(bUseOrderColumn, icolcolumn);
      SetLength(sSearchValueColumn, icolcolumn);
      SetLength(bUseRegExColumn, icolcolumn);
      for I := 0 to icolcolumn - 1 do begin
        sDataColumn[I] := sl.Values[Format('columns[%d][data]', [I])];
        sNameColumn[I] := sl.Values[Format('columns[%d][name]', [I])];
        bUseSeachColumn[I] :=
          sl.Values[Format('columns[%d][searchable]', [I])] = 'true';
        bUseOrderColumn[I] :=
          sl.Values[Format('columns[%d][orderable]', [I])] = 'true';
        sSearchValueColumn[I] :=
          sl.Values[Format('columns[%d][search][value]', [I])];
        bUseRegExColumn[I] := sl.Values[Format('columns[%d][search][regex]',
          [I])] = 'true';
      end;
      iOrderColumn := StrToInt(sl.Values['order[0][column]']);
      sOrderDirection := sl.Values['order[0][dir]'];
      iStartIndex := StrToInt(sl.Values['start']);
      iLengthPage := StrToInt(sl.Values['length']);
      sSearch := sl.Values['search[value]'];
      bUseRegEx := sl.Values['search[regex]'] = 'true';
    end;
  finally
    sl.free;
  end;
end;

end.
