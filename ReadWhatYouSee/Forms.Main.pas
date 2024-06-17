unit Forms.Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Objects, System.Actions, FMX.ActnList,
  FMX.Layouts, FMX.Media, FMX.ListBox;

type
  TMainForm = class(TForm)
    Splitter1: TSplitter;
    ToolBar1: TToolBar;
    SubjectImage: TImage;
    StatusLabel: TLabel;
    MainActions: TActionList;
    ActOpenFile: TAction;
    BtnOpenFile: TSpeedButton;
    OpenImageDialog: TOpenDialog;
    SelectedTextHeading: TLabel;
    SelectedTextLabel: TLabel;
    TranslatedTextHeading: TLabel;
    ContextLayout: TLayout;
    TranslatedTextLabel: TLabel;
    SpeechPlayer: TMediaPlayer;
    TargetLanguageComboBox: TComboBox;
    procedure SubjectImageMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Single);
    procedure ActOpenFileExecute(Sender: TObject);
    procedure SubjectImageClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure TargetLanguageComboBoxChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FIsReady: Boolean;
    FSelectedText: string;
    FTranslatedText: string;
    function GetImageTarget: TRectF;
    function GetImageCoordinates(X, Y: Single): TPointF;
    function GetRelativeImageCoordinates(X, Y: Single): TPointF;
    procedure SetSelectedText(const ASelectedText: string);
    procedure SetTranslatedText(const ATranslatedText: string);
    property IsReady: Boolean read FIsReady;
    property SelectedText: string read FSelectedText write SetSelectedText;
    property TranslatedText: string read FTranslatedText write SetTranslatedText;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

uses
  DataModules.TextExtraction,
  DataModules.Translation,
  DataModules.TextToSpeech;

procedure TMainForm.ActOpenFileExecute(Sender: TObject);
begin
  if OpenImageDialog.Execute then
  begin
    SubjectImage.Bitmap.LoadFromFile(OpenImageDialog.FileName);
    if TextExtractionDM.ExtractText(OpenImageDialog.FileName) then
    begin
      StatusLabel.Text := 'Ready!';
      FIsReady := True;
    end
    else
    begin
      StatusLabel.Text := 'Error.';
      FIsReady := False;
    end;
  end;
end;

procedure TMainForm.TargetLanguageComboBoxChange(Sender: TObject);
var
  LSpeechLanguageCode, LTranslationLanguageCode: string;
begin
  LSpeechLanguageCode := TargetLanguageComboBox.Selected.Text.Split([':'])[0];
  LTranslationLanguageCode := LSpeechLanguageCode.Split(['-'])[0];
  TranslationDM.TargetLanguageCode := LTranslationLanguageCode;
  TextToSpeechDM.LanguageCode := LSpeechLanguageCode;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FIsReady := False;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  TranslationDM.TargetLanguageCode := 'en';
  TextToSpeechDM.LanguageCode := 'en-GB';
end;

function TMainForm.GetImageCoordinates(X, Y: Single): TPointF;
var
  LTargetRect: TRectF;
begin
  if SubjectImage.Bitmap.Width = 0 then
    Exit(TPointF.Create(-1, -1));

  LTargetRect := GetImageTarget;
  if (X >= LTargetRect.Left) and (X <= LTargetRect.Right) and (Y >= LTargetRect.Top) and (Y <= LTargetRect.Bottom) then
    Result := TPointF.Create(
      (X - LTargetRect.Left) / LTargetRect.Width * SubjectImage.Bitmap.Width,
      (Y - LTargetRect.Top) / LTargetRect.Height * SubjectImage.Bitmap.Height
    )
  else
    Result := TPointF.Create(-1, -1);
end;

function TMainForm.GetImageTarget: TRectF;
var
  LTargetSize: TSizeF;
  LControlAspectRatio, LImageAspectRatio: Single;
  LScale: Single;
begin
  LControlAspectRatio := SubjectImage.Width / SubjectImage.Height;
  LImageAspectRatio := SubjectImage.Bitmap.Width / SubjectImage.Bitmap.Height;

  if LImageAspectRatio > LControlAspectRatio then
  begin
    LScale := SubjectImage.Width / SubjectImage.Bitmap.Width;
    LTargetSize := TSizeF.Create(SubjectImage.Width, SubjectImage.Bitmap.Height * LScale);
    Result := TRectF.Create(
      0,
      (SubjectImage.Height - LTargetSize.Height) / 2,
      SubjectImage.Width,
      (SubjectImage.Height + LTargetSize.Height) / 2
    );
  end
  else
  begin
    LScale := SubjectImage.Height / SubjectImage.Bitmap.Height;
    LTargetSize := TSizeF.Create(SubjectImage.Bitmap.Width * LScale, SubjectImage.Height);
    Result := TRectF.Create(
      (SubjectImage.Width - LTargetSize.Width) / 2,
      0,
      (SubjectImage.Width + LTargetSize.Width) / 2,
      SubjectImage.Height
    );
  end;
end;

function TMainForm.GetRelativeImageCoordinates(X, Y: Single): TPointF;
var
  LTargetRect: TRectF;
begin
  if SubjectImage.Bitmap.Width = 0 then
    Exit(TPointF.Create(-1, -1));

  LTargetRect := GetImageTarget;
  if (X >= LTargetRect.Left) and (X <= LTargetRect.Right) and (Y >= LTargetRect.Top) and (Y <= LTargetRect.Bottom) then
    Result := TPointF.Create(
      (X - LTargetRect.Left) / LTargetRect.Width,
      (Y - LTargetRect.Top) / LTargetRect.Height
    )
  else
    Result := TPointF.Create(-1, -1);
end;

procedure TMainForm.SetSelectedText(const ASelectedText: string);
begin
  FSelectedText := ASelectedText;
  ContextLayout.BeginUpdate;
  try
    SelectedTextLabel.Text := FSelectedText;
    if not FSelectedText.IsEmpty and TranslationDM.TranslateText(FSelectedText) then
      TranslatedText := TranslationDM.TranslatedText
    else
      TranslatedText := '';
  finally
    ContextLayout.EndUpdate;
  end;
end;

procedure TMainForm.SetTranslatedText(const ATranslatedText: string);
var
  LAudioFileName: string;
begin
  FTranslatedText := ATranslatedText;
  if not FTranslatedText.IsEmpty then
  begin
    SelectedTextHeading.Text := Format('Selected Text (%s):', [TranslationDM.DetectedLanguageCode]);
    TranslatedTextHeading.Text := Format('Translated Text (%s):', [TranslationDM.TargetLanguageCode]);
    TranslatedTextLabel.Text := FTranslatedText;
    if TextToSpeechDM.ConvertTextToSpeech(FTranslatedText, LAudioFileName) then
    begin
      SpeechPlayer.FileName := LAudioFileName;
      SpeechPlayer.Play;
    end;
  end
  else
  begin
    SelectedTextHeading.Text := 'Selected Text:';
    TranslatedTextHeading.Text := 'Translated Text:';
    TranslatedTextLabel.Text := 'N/A';
  end;
end;

procedure TMainForm.SubjectImageClick(Sender: TObject);
var
  LMousePos, LRelativeImageCoords: TPointF;
begin
  if not IsReady then
    Exit;

  LMousePos := SubjectImage.ScreenToLocal(Screen.MousePos);
  LRelativeImageCoords := GetRelativeImageCoordinates(LMousePos.X, LMousePos.Y);
  SelectedText := TextExtractionDM.SelectTextAt(LRelativeImageCoords);
end;

procedure TMainForm.SubjectImageMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Single);
var
  LImageCoords, LRelativeImageCoords: TPointF;
begin
  LImageCoords := GetImageCoordinates(X, Y);
  LRelativeImageCoords := GetRelativeImageCoordinates(X, Y);
  StatusLabel.Text := Format('%f, %f (%f, %f)', [LImageCoords.X, LImageCoords.Y, LRelativeImageCoords.X, LRelativeImageCoords.Y]);
end;

end.
