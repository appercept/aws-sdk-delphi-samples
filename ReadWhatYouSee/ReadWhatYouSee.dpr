program ReadWhatYouSee;

uses
  System.StartUpCopy,
  FMX.Forms,
  Forms.Main in 'Forms.Main.pas' {MainForm},
  DataModules.TextExtraction in 'DataModules.TextExtraction.pas' {TextExtractionDM: TDataModule},
  DataModules.Translation in 'DataModules.Translation.pas' {TranslationDM: TDataModule},
  DataModules.TextToSpeech in 'DataModules.TextToSpeech.pas' {TextToSpeechDM: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TTextExtractionDM, TextExtractionDM);
  Application.CreateForm(TTranslationDM, TranslationDM);
  Application.CreateForm(TTextToSpeechDM, TextToSpeechDM);
  Application.Run;
end.
