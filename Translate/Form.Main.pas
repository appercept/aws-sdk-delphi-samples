unit Form.Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types,
  FMX.ScrollBox, FMX.Memo, FMX.Controls.Presentation, FMX.Edit, FMX.ComboEdit,
  FMX.StdCtrls, FMX.ListBox, System.Actions, FMX.ActnList,
  AWS.Translate;

type
  TMainForm = class(TForm)
    MemoTextSource: TMemo;
    MemoTranslatedText: TMemo;
    BtnSwitchLanguages: TButton;
    ComboSourceLanguage: TComboBox;
    ComboTargetLanguage: TComboBox;
    ActionList1: TActionList;
    ActSwitchLanguages: TAction;
    ActTranslate: TAction;
    procedure ComboSourceLanguageChange(Sender: TObject);
    procedure ActSwitchLanguagesExecute(Sender: TObject);
    procedure ActTranslateExecute(Sender: TObject);
    procedure MemoTextSourceKeyDown(Sender: TObject; var Key: Word;
      var KeyChar: Char; Shift: TShiftState);
    procedure FormCreate(Sender: TObject);
  private
    FClient: ITranslateClient;
    FDetectedLanguageCode: string;
    function GetAutoSourceLabel: string;
    property AutoSourceLabel: string read GetAutoSourceLabel;
    property Client: ITranslateClient read FClient;
    procedure LoadLanguages;
    function ExtractLanguageCode(const ALanguageDisplay: string): string;
    function GetSourceLanguageCode: string;
    function GetTargetLanguageCode: string;
    procedure SetDetectedLanguageCode(const ADetectedLanguageCode: string);
    property SourceLanguageCode: string read GetSourceLanguageCode;
    property TargetLanguageCode: string read GetTargetLanguageCode;
    property DetectedLanguageCode: string read FDetectedLanguageCode write SetDetectedLanguageCode;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

procedure TMainForm.ActSwitchLanguagesExecute(Sender: TObject);
var
  LLanguageIdx: Integer;
  LSourceText: string;
begin
  LLanguageIdx := ComboSourceLanguage.ItemIndex;
  ComboSourceLanguage.ItemIndex := ComboTargetLanguage.ItemIndex + 1;
  ComboTargetLanguage.ItemIndex := LLanguageIdx - 1;
  LSourceText := MemoTextSource.Text;
  MemoTextSource.Text := MemoTranslatedText.Text;
  MemoTranslatedText.Text := LSourceText;
end;

procedure TMainForm.ActTranslateExecute(Sender: TObject);
var
  LRequest: ITranslateTranslateTextRequest;
  LResponse: ITranslateTranslateTextResponse;
begin
  LRequest := TTranslateTranslateTextRequest.Create(
    SourceLanguageCode,
    TargetLanguageCode,
    MemoTextSource.Text
  );
  LResponse := Client.TranslateText(LRequest);
  if LResponse.IsSuccessful then
  begin
    if SourceLanguageCode.Equals('auto') then
      DetectedLanguageCode := LResponse.SourceLanguageCode;
    MemoTranslatedText.Text := LResponse.TranslatedText;
  end;
end;

procedure TMainForm.ComboSourceLanguageChange(Sender: TObject);
begin
  ActSwitchLanguages.Enabled := ComboSourceLanguage.ItemIndex <> 0;
end;

function TMainForm.ExtractLanguageCode(const ALanguageDisplay: string): string;
begin
  Result := ALanguageDisplay.Split([':'])[0];
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FClient := TTranslateClient.Create;
  LoadLanguages;
end;

function TMainForm.GetAutoSourceLabel: string;
begin
  if DetectedLanguageCode.IsEmpty then
    Result := 'auto: Detect Language Automatically'
  else
    Result := Format('auto: Detect Language Automatically (%s)', [DetectedLanguageCode]);
end;

function TMainForm.GetSourceLanguageCode: string;
begin
  Result := ExtractLanguageCode(ComboSourceLanguage.Selected.Text);
end;

function TMainForm.GetTargetLanguageCode: string;
begin
  Result := ExtractLanguageCode(ComboTargetLanguage.Selected.Text);
end;

procedure TMainForm.LoadLanguages;

  procedure SelectLanguageCode(const AComboBox: TComboBox; const ALanguageCode: string);
  var
    I: Integer;
  begin
    for I := 0 to AComboBox.Items.Count - 1 do
      if ExtractLanguageCode(AComboBox.Items[I]).Equals(ALanguageCode) then
      begin
        AComboBox.ItemIndex := I;
        Exit;
      end;
  end;

var
  LResponse: ITranslateListLanguagesResponse;
  LLanguage: ITranslateLanguage;
  LSourceLanguageCode, LTargetLanguageCode: string;
begin
  LSourceLanguageCode := SourceLanguageCode;
  LTargetLanguageCode := TargetLanguageCode;
  ComboSourceLanguage.BeginUpdate;
  ComboTargetLanguage.BeginUpdate;
  ComboSourceLanguage.Items.Clear;
  ComboTargetLanguage.Items.Clear;
  ComboSourceLanguage.Items.Add(AutoSourceLabel);
  LResponse := Client.ListLanguages;
  if LResponse.IsSuccessful then
  begin
    for LLanguage in LResponse.Languages do
    begin
      if LLanguage.LanguageCode.Equals('auto') then
        Continue;

      var LLanguageLabel := Format('%s: %s', [LLanguage.LanguageCode, LLanguage.LanguageName]);
      ComboSourceLanguage.Items.Add(LLanguageLabel);
      ComboTargetLanguage.Items.Add(LLanguageLabel);
    end;
  end;
  SelectLanguageCode(ComboSourceLanguage, LSourceLanguageCode);
  SelectLanguageCode(ComboTargetLanguage, LTargetLanguageCode);
  ComboTargetLanguage.EndUpdate;
  ComboSourceLanguage.EndUpdate;
end;

procedure TMainForm.MemoTextSourceKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  if (Key = 13) and not (ssShift in Shift) then
  begin
    Key := 0;
    KeyChar := #0;
    ActTranslate.Execute;
  end;
end;

procedure TMainForm.SetDetectedLanguageCode(
  const ADetectedLanguageCode: string);
begin
  FDetectedLanguageCode := ADetectedLanguageCode;
  ComboSourceLanguage.BeginUpdate;
  ComboSourceLanguage.Items[0] := AutoSourceLabel;
  ComboSourceLanguage.EndUpdate;
end;

end.
