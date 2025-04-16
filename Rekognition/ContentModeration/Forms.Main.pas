unit Forms.Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.ListView.Types,
  FMX.ListView.Appearances, FMX.ListView.Adapters.Base, System.Actions,
  FMX.ActnList, FMX.Objects, FMX.ListView, AWS.Rekognition, System.Generics.Collections,
  FMX.Effects, FMX.Filter.Effects;

type
  TMainForm = class(TForm)
    ToolBar1: TToolBar;
    SpeedButton1: TSpeedButton;
    DetectedList: TListView;
    Image: TImage;
    Splitter1: TSplitter;
    Actions: TActionList;
    ActOpenImage: TAction;
    OpenImageDialog: TOpenDialog;
    ActDetectModerationLabels: TAction;
    SpeedButton2: TSpeedButton;
    CheckReveal: TCheckBox;
    ImageBlurEffect: TGaussianBlurEffect;
    procedure ActOpenImageExecute(Sender: TObject);
    procedure CheckRevealChange(Sender: TObject);
    procedure ActDetectModerationLabelsExecute(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    FImageFileName: string;
    FDetectedLabels: TList<IRekognitionModerationLabel>;
    procedure SetDetectedLabels(const ADetectedLabels: TList<IRekognitionModerationLabel>);
  public
    property DetectedLabels: TList<IRekognitionModerationLabel> read FDetectedLabels write SetDetectedLabels;
  end;

var
  MainForm: TMainForm;

implementation

uses
  System.Math.Vectors;

{$R *.fmx}

procedure TMainForm.ActDetectModerationLabelsExecute(Sender: TObject);
var
  LClient: IRekognitionClient;
  LResponse: IRekognitionDetectModerationLabelsResponse;
begin
  ActDetectModerationLabels.Enabled := False;
  LClient := TRekognitionClient.Create;
  LResponse := LClient.DetectModerationLabels(TRekognitionImage.FromFile(FImageFileName));
  if LResponse.IsSuccessful then
  begin
    DetectedLabels := TList<IRekognitionModerationLabel>.Create(LResponse.ModerationLabels);
    if DetectedLabels.Count = 0 then
      CheckReveal.IsChecked := True;
  end;
end;

procedure TMainForm.ActOpenImageExecute(Sender: TObject);
begin
  if OpenImageDialog.Execute then
  begin
    FImageFileName := OpenImageDialog.FileName;
    CheckReveal.IsChecked := False;
    Image.Bitmap.LoadFromFile(FImageFileName);
    DetectedLabels := nil;
    ActDetectModerationLabels.Enabled := True;
  end;
end;

procedure TMainForm.CheckRevealChange(Sender: TObject);
begin
  ImageBlurEffect.Enabled := not CheckReveal.IsChecked;
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if Assigned(FDetectedLabels) then
    FDetectedLabels.Free;
end;

procedure TMainForm.SetDetectedLabels(const ADetectedLabels: TList<IRekognitionModerationLabel>);
begin
  if Assigned(FDetectedLabels) then
    FDetectedLabels.Free;
  FDetectedLabels := ADetectedLabels;
  DetectedList.BeginUpdate;
  try
    DetectedList.Items.Clear;
    if Assigned(FDetectedLabels) then
      for var LLabel in FDetectedLabels do
      begin
        var LItem := DetectedList.Items.Add;
        LItem.Text := LLabel.Name;
        LItem.Detail := Format('%f%% Confidence', [LLabel.Confidence.Value]);
      end;
  finally
    DetectedList.EndUpdate;
  end;
end;

end.
