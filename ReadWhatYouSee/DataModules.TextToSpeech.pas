unit DataModules.TextToSpeech;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  AWS.Polly;

type
  TTextToSpeechDM = class(TDataModule)
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private
    FClient: IPollyClient;
    FLanguageCode: string;
    FVoice: IPollyVoice;
    FVoices: TList<IPollyVoice>;
    procedure LoadVoices;
    function SelectAllVoicesForLanguage(const ALanguageCode: string): TList<IPollyVoice>;
    function SelectVoiceForLanguage(const ALanguageCode: string): IPollyVoice;
    procedure SetLanguageCode(const ALanguageCode: string);
    function VoiceSupportsLanguage(const ALanguageCode: string): Boolean;
    property Client: IPollyClient read FClient;
    property Voices: TList<IPollyVoice> read FVoices;
  public
    function ConvertTextToSpeech(const AText: string; out AFileName: string): Boolean;

    property LanguageCode: string read FLanguageCode write SetLanguageCode;
    property Voice: IPollyVoice read FVoice;
  end;

var
  TextToSpeechDM: TTextToSpeechDM;

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}

{$R *.dfm}

function TTextToSpeechDM.ConvertTextToSpeech(const AText: string; out AFileName: string): Boolean;
var
  LRequest: IPollySynthesizeSpeechRequest;
  LResponse: IPollySynthesizeSpeechResponse;
  LAudioFile: TFileStream;
begin
  LRequest := TPollySynthesizeSpeechRequest.Create;
  if Voice.SupportedEngines.Contains('neural') then
    LRequest.Engine := 'neural'
  else
    LRequest.Engine := 'standard';
  LRequest.LanguageCode := Voice.LanguageCode;
  LRequest.OutputFormat := 'mp3';
  LRequest.Text := AText;
  LRequest.VoiceId := Voice.Id;
  LResponse := Client.SynthesizeSpeech(LRequest);
  if LResponse.IsSuccessful then
  begin
    AFileName := Format('ReadWhatYouSee%s.mp3', [FormatDateTime('yyyymmddhhnnsszzz', Now)]);
    LAudioFile := TFileStream.Create(AFileName, fmCreate);
    try
      LAudioFile.CopyFrom(LResponse.AudioStream);
    finally
      LAudioFile.Free;
    end;
    Result := True;
  end
  else
    Result := False;
end;

procedure TTextToSpeechDM.DataModuleCreate(Sender: TObject);
begin
  FClient := TPollyClient.Create;
  FVoices := TList<IPollyVoice>.Create;
  LoadVoices;
end;

procedure TTextToSpeechDM.DataModuleDestroy(Sender: TObject);
begin
  FVoices.Free;
  FClient := nil;
end;

procedure TTextToSpeechDM.LoadVoices;
var
  LRequest: IPollyDescribeVoicesRequest;
  LResponse: IPollyDescribeVoicesResponse;
  LMore: Boolean;
begin
  LRequest := TPollyDescribeVoicesRequest.Create;
  LMore := True;
  while LMore do
  begin
    LResponse := Client.DescribeVoices(LRequest);
    if LResponse.IsSuccessful then
    begin
      Voices.AddRange(LResponse.Voices);
      LRequest.NextToken := LResponse.NextToken;
      LMore := not LRequest.NextToken.IsEmpty;
    end
    else
      LMore := False;
  end;
end;

function TTextToSpeechDM.SelectAllVoicesForLanguage(
  const ALanguageCode: string): TList<IPollyVoice>;
var
  LVoice: IPollyVoice;
begin
  Result := TList<IPollyVoice>.Create;
  for LVoice in Voices do
  begin
    if LVoice.LanguageCode.Equals(ALanguageCode) then
      Result.Add(LVoice);
  end;
end;

function TTextToSpeechDM.SelectVoiceForLanguage(
  const ALanguageCode: string): IPollyVoice;
var
  LVoices: TList<IPollyVoice>;
  LVoice: IPollyVoice;
begin
  LVoices := SelectAllVoicesForLanguage(ALanguageCode);
  try
    if LVoices.Count = 0 then
      Exit(nil);

    for LVoice in LVoices do
      if LVoice.SupportedEngines.Contains('neural') then
        Exit(LVoice);
    Result := LVoices.First;
  finally
    LVoices.Free;
  end;
end;

procedure TTextToSpeechDM.SetLanguageCode(const ALanguageCode: string);
begin
  FLanguageCode := ALanguageCode;
  if not VoiceSupportsLanguage(ALanguageCode) then
    FVoice := SelectVoiceForLanguage(FLanguageCode);
end;

function TTextToSpeechDM.VoiceSupportsLanguage(
  const ALanguageCode: string): Boolean;
begin
  if not Assigned(FVoice) then
    Exit(False);

  Result := Voice.LanguageCode.Equals(ALanguageCode);
end;

end.
