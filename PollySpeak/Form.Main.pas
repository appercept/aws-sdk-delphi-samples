unit Form.Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types,
  System.Actions, FMX.ActnList, FMX.StdCtrls, FMX.Controls.Presentation,
  FMX.ScrollBox, FMX.Memo, FMX.Media, FMX.ListView.Types, FMX.ListBox,
  FMX.Layouts, AWS.Polly, System.Generics.Collections, FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base, FMX.ListView;

type
  TMainForm = class(TForm)
    MemoText: TMemo;
    BtnSpeak: TButton;
    ActionList1: TActionList;
    ActSpeak: TAction;
    MediaPlayer1: TMediaPlayer;
    RbStandard: TRadioButton;
    RbNeural: TRadioButton;
    LblEngine: TLabel;
    VoicesListView: TListView;
    Panel1: TPanel;
    Splitter1: TSplitter;
    CbEnableMarkup: TCheckBox;
    procedure ActSpeakExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure VoicesListViewChange(Sender: TObject);
    procedure MemoTextKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
  private
    { Private declarations }
    Client: IPollyClient;
    Voices: TList<IPollyVoice>;
    FVoice: IPollyVoice;
    procedure LoadVoices;
    procedure SelectVoice(const AName: string);
    procedure SetVoice(const AVoice: IPollyVoice);
    property Voice: IPollyVoice read FVoice write SetVoice;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

uses
  System.IOUtils;

{$R *.fmx}

procedure TMainForm.ActSpeakExecute(Sender: TObject);
var
  LRequest: IPollySynthesizeSpeechRequest;
  LResponse: IPollySynthesizeSpeechResponse;
  LAudioFile: TFileStream;
  LFileName: string;
begin
  LRequest := TPollySynthesizeSpeechRequest.Create;
  if RbStandard.IsChecked then
    LRequest.Engine := 'standard'
  else
    LRequest.Engine := 'neural';
  LRequest.LanguageCode := Voice.LanguageCode;
  if CbEnableMarkup.IsChecked then
    LRequest.TextType := 'ssml';
  LRequest.OutputFormat := 'mp3';
  LRequest.Text := MemoText.Text;
  LRequest.VoiceId := Voice.Id;
  LResponse := Client.SynthesizeSpeech(LRequest);
  if LResponse.IsSuccessful then
  begin
    LFileName := Format('PollySpeak%s.mp3', [FormatDateTime('yyyymmddhhnnsszzz', Now)]);
    LAudioFile := TFileStream.Create(LFileName, fmCreate);
    try
      LAudioFile.CopyFrom(LResponse.AudioStream);
    finally
      LAudioFile.Free;
    end;
    MediaPlayer1.FileName := LFileName;
    MediaPlayer1.Play;
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  Client := TPollyClient.Create;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  LoadVoices;
end;

procedure TMainForm.LoadVoices;
var
  LRequest: IPollyDescribeVoicesRequest;
  LResponse: IPollyDescribeVoicesResponse;
  LMore: Boolean;
begin
  if not Assigned(Voices) then
    Voices := TList<IPollyVoice>.Create;

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

  try
    VoicesListView.BeginUpdate;
    VoicesListView.Items.Clear;
    for var LVoice in Voices do
    begin
      var LItem := VoicesListView.Items.Add;
      LItem.Text := LVoice.Name;
      LItem.Detail := Format('%s (%s) - %s', [LVoice.LanguageName, LVoice.LanguageCode, LVoice.Gender]);
    end;
  finally
    VoicesListView.EndUpdate;
  end;
end;

procedure TMainForm.MemoTextKeyUp(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  if (KeyChar = #13) and (ssCtrl in Shift) then
    ActSpeak.Execute;
end;

procedure TMainForm.SelectVoice(const AName: string);
begin
  for var LVoice in Voices do
    if LVoice.Name.Equals(AName) then
    begin
      Voice := LVoice;
      Exit;
    end;
end;

procedure TMainForm.SetVoice(const AVoice: IPollyVoice);
begin
  ActSpeak.Enabled := False;
  RbNeural.Enabled := False;
  RbStandard.Enabled := False;
  FVoice := AVoice;
  if Voice.SupportedEngines.Contains('standard') then
    RbStandard.Enabled := True;
  if Voice.SupportedEngines.Contains('neural') then
    RbNeural.Enabled := True;
  if RbStandard.Enabled then
    RbStandard.IsChecked := True
  else
    RbNeural.IsChecked := True;
  ActSpeak.Enabled := True;
end;

procedure TMainForm.VoicesListViewChange(Sender: TObject);
begin
  SelectVoice(VoicesListView.Items[VoicesListView.ItemIndex].Text);
end;

end.
