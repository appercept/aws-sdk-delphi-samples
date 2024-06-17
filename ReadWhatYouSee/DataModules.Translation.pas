unit DataModules.Translation;

interface

uses
  System.SysUtils, System.Classes,
  AWS.Translate;

type
  TTranslationDM = class(TDataModule)
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private
    FClient: ITranslateClient;
    FDetectedLanguageCode: string;
    FSourceLanguageCode: string;
    FTargetLanguageCode: string;
    FTranslatedText: string;
    property Client: ITranslateClient read FClient;
  public
    function TranslateText(const AText: string): Boolean;

    property DetectedLanguageCode: string read FDetectedLanguageCode;
    property SourceLanguageCode: string read FSourceLanguageCode write FSourceLanguageCode;
    property TargetLanguageCode: string read FTargetLanguageCode write FTargetLanguageCode;
    property TranslatedText: string read FTranslatedText;
  end;

var
  TranslationDM: TTranslationDM;

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}

{$R *.dfm}

procedure TTranslationDM.DataModuleCreate(Sender: TObject);
begin
  FSourceLanguageCode := 'auto';
  FTargetLanguageCode := 'en';
  FClient := TTranslateClient.Create;
end;

procedure TTranslationDM.DataModuleDestroy(Sender: TObject);
begin
  FClient := nil;
end;

function TTranslationDM.TranslateText(const AText: string): Boolean;
var
  LRequest: ITranslateTranslateTextRequest;
  LResponse: ITranslateTranslateTextResponse;
begin
  FDetectedLanguageCode := '';
  FTranslatedText := '';
  LRequest := TTranslateTranslateTextRequest.Create(
    SourceLanguageCode,
    TargetLanguageCode,
    AText
  );
  LResponse := Client.TranslateText(LRequest);
  if LResponse.IsSuccessful then
  begin
    if SourceLanguageCode.Equals('auto') then
      FDetectedLanguageCode := LResponse.SourceLanguageCode;
    FTranslatedText := LResponse.TranslatedText;
    Result := True;
  end
  else
    Result := False;
end;

end.
