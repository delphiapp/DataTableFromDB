unit uDBOtchetRecord;

interface
  uses
    SynCommons, mORMot, Classes;

type
  TVidyOtchetov = 1..11;
const
  strDateTermopr : array[TVidyOtchetov] of ShortString = ('Otchety_nastrk', 'Otchety_termo0', 'Otchety_termo8',
                                                         'Otchety_termo16','Otchety_termo24','Otchety_termo36',
                                                         'Otchety_termo48','Otchety_termo72','Otchety_Koeff','Otchety_HtmKoeff','Otchety_Test');

type
    TDataOtchet = class(TPersistent)
    private
      fHref     : RawUTF8;
      fOtchet   : RawUTF8;
      fResult   : RawUTF8;
      fDateProverki : RawUTF8;
    public
      procedure Clear;
    published
      property Href     : RawUTF8       read fHref         write fHref;
      property Otchet   : RawUTF8       read fOtchet       write fOtchet;
      property Result   : RawUTF8       read fResult       write fResult;
      property DateProverki : RawUTF8   read fDateProverki write fDateProverki;
    end;

  /// here we declare the class containing the data
  // - it just has to inherits from TSQLRecord, and the published
  // properties will be used for the ORM (and all SQL creation)
  // - the beginning of the class name must be 'TSQL' for proper table naming
  // in client/server environnment
  
  TSQLRecordZakaz = class(TSQLRecord)
  private
    fNomerZakaza      : RawUTF8;
    fZakazchik        : RawUTF8;
    fVypolnen         : Boolean;
    FTimeVypoln       : TDateTime;
  published
    property NomerZakaza      : RawUTF8     read fNomerZakaza       write fNomerZakaza;
    property Zakazchik        : RawUTF8     read fZakazchik         write fZakazchik;
    property Vypolnen         : Boolean     read fVypolnen          write fVypolnen;
    property TimeVypoln       : TDateTime   read FTimeVypoln        write FTimeVypoln;
  end;

  TSQLRecordTipoisp = class(TSQLRecord)
  private
    fNameTipoisp          : RawUTF8;
  published
    property NameTipoisp          : RawUTF8           read fNameTipoisp           write fNameTipoisp;
  end;

  TSQLRecordDevice = class(TSQLRecord)
  private
    fIDZakaza         : TSQLRecordZakaz;
    fIDTipoisp        : TSQLRecordTipoisp;
    fSerNomer         : RawUTF8;

    fNumberShkaf      : RawUTF8;
    fPolVShkafu       : Integer;
    fCiklTermopr      : Integer;
    fFinish           : Boolean;
    fDateSetToShkaf   : RawUTF8;
    fVysokIsp         : RawUTF8;

    fGod              : RawUTF8;
    fMesyac           : RawUTF8;
    fProveril         : RawUTF8;
    fKontrNomer       : RawUTF8;
    fNameIniFile      : RawUTF8;

    fBoardsNumber     : TRawUTF8List;

    fOtchety_nastrk     : TDataOtchet;
    fOtchety_termo0     : TDataOtchet;
    fOtchety_termo8     : TDataOtchet;
    fOtchety_termo16    : TDataOtchet;
    fOtchety_termo24    : TDataOtchet;
    fOtchety_termo36    : TDataOtchet;
    fOtchety_termo48    : TDataOtchet;
    fOtchety_termo72    : TDataOtchet;
    fOtchety_Koeff      : TDataOtchet;
    fOtchety_HtmKoeff   : TDataOtchet;
    fOtchety_Test       : TDataOtchet;

    fOptionParam        : TRawUTF8List;
  public
    constructor Create; override;
    destructor Destroy; override;
  published
    property IDZakaza         : TSQLRecordZakaz   read fIDZakaza          write fIDZakaza;
    property IDTipoisp        : TSQLRecordTipoisp read fIDTipoisp         write fIDTipoisp;
    property SerNomer         : RawUTF8           read fSerNomer          write fSerNomer;

  //данные термопрогона
    property NumberShkaf        : RawUTF8   read fNumberShkaf       write fNumberShkaf;
    property PolVShkafu         : Integer   read fPolVShkafu        write fPolVShkafu;
    property CiklTermopr        : Integer   read fCiklTermopr       write fCiklTermopr;
    property Finish             : Boolean   read fFinish            write fFinish;
    property DateSetToShkaf     : RawUTF8   read fDateSetToShkaf    write fDateSetToShkaf;
    property VysokIsp           : RawUTF8   read fVysokIsp          write fVysokIsp;

    property God                : RawUTF8   read fGod               write fGod;
    property Mesyac             : RawUTF8   read fMesyac            write fMesyac;
    property Proveril           : RawUTF8   read fProveril          write fProveril;
    property KontrNomer         : RawUTF8   read fKontrNomer        write fKontrNomer;
    property NameIniFile        : RawUTF8   read fNameIniFile       write fNameIniFile;

    property BoardsNumber       : TRawUTF8List read fBoardsNumber   write fBoardsNumber;

  //данные отчетов
    property Otchety_nastrk     : TDataOtchet read fOtchety_nastrk  write fOtchety_nastrk;
    property Otchety_termo0     : TDataOtchet read fOtchety_termo0  write fOtchety_termo0;
    property Otchety_termo8     : TDataOtchet read fOtchety_termo8  write fOtchety_termo8;
    property Otchety_termo16    : TDataOtchet read fOtchety_termo16 write fOtchety_termo16;
    property Otchety_termo24    : TDataOtchet read fOtchety_termo24 write fOtchety_termo24;
    property Otchety_termo36    : TDataOtchet read fOtchety_termo36 write fOtchety_termo36;
    property Otchety_termo48    : TDataOtchet read fOtchety_termo48 write fOtchety_termo48;
    property Otchety_termo72    : TDataOtchet read fOtchety_termo72 write fOtchety_termo72;
    property Otchety_Koeff      : TDataOtchet read fOtchety_Koeff   write fOtchety_Koeff;
    property Otchety_HtmKoeff   : TDataOtchet read fOtchety_HtmKoeff write fOtchety_HtmKoeff;
    property Otchety_Test       : TDataOtchet read fOtchety_Test    write fOtchety_Test;

    property OptionParam        : TRawUTF8List read fOptionParam    write fOptionParam;
  end;

/// an easy way to create a database model for client and server
function CreateSampleModel: TSQLModel;


implementation

function CreateSampleModel: TSQLModel;
begin
  result := TSQLModel.Create([TSQLRecordZakaz,TSQLRecordTipoisp,TSQLRecordDevice, TSQLAuthGroup, TSQLAuthUser]);
end;

{ TSQLRecordDevice }

constructor TSQLRecordDevice.Create;
begin
  inherited;
  fBoardsNumber:=TRawUTF8List.Create;
  fOptionParam:=TRawUTF8List.Create;

  fOtchety_nastrk:=TDataOtchet.Create;
  fOtchety_termo0:=TDataOtchet.Create;
  fOtchety_termo8:=TDataOtchet.Create;
  fOtchety_termo16:=TDataOtchet.Create;
  fOtchety_termo24:=TDataOtchet.Create;
  fOtchety_termo36:=TDataOtchet.Create;
  fOtchety_termo48:=TDataOtchet.Create;
  fOtchety_termo72:=TDataOtchet.Create;
  fOtchety_Koeff:=TDataOtchet.Create;
  fOtchety_HtmKoeff:=TDataOtchet.Create;
  fOtchety_Test:=TDataOtchet.Create;
end;

destructor TSQLRecordDevice.Destroy;
begin
  fBoardsNumber.Free;
  fOptionParam.Free;

  fOtchety_nastrk.Free;
  fOtchety_termo0.Free;
  fOtchety_termo8.Free;
  fOtchety_termo16.Free;
  fOtchety_termo24.Free;
  fOtchety_termo36.Free;
  fOtchety_termo48.Free;
  fOtchety_termo72.Free;
  fOtchety_Koeff.Free;
  fOtchety_HtmKoeff.Free;
  fOtchety_Test.Free;
  inherited;
end;

{ TDataOtchet }

procedure TDataOtchet.Clear;
begin
  fHref:='';
  fOtchet:='';
  fResult:='';
  fDateProverki:='';
end;

end.
