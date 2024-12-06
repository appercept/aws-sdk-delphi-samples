unit Forms.Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.ListView.Types,
  FMX.ListView.Appearances, FMX.ListView.Adapters.Base, System.Actions,
  FMX.ActnList, FMX.Objects, FMX.ListView, AWS.Rekognition, System.Generics.Collections;

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
    ActDetectLabels: TAction;
    SpeedButton2: TSpeedButton;
    CheckShowConfidences: TCheckBox;
    procedure ActOpenImageExecute(Sender: TObject);
    procedure ActDetectLabelsExecute(Sender: TObject);
    procedure DetectedListChange(Sender: TObject);
    procedure CheckShowConfidencesChange(Sender: TObject);
  private
    FImageFileName: string;
    FDetectedLabels: TList<IRekognitionLabel>;
    procedure SetDetectedLabels(const ADetectedLabels: TList<IRekognitionLabel>);
    function GetLabelCategory(const ALabel: IRekognitionLabel): string;
  public
    procedure SelectLabel(const ALabel: IRekognitionLabel);
    property DetectedLabels: TList<IRekognitionLabel> read FDetectedLabels write SetDetectedLabels;
  end;

var
  MainForm: TMainForm;

implementation

uses
  System.Math.Vectors;

{$R *.fmx}

procedure TMainForm.ActDetectLabelsExecute(Sender: TObject);
var
  LClient: IRekognitionClient;
  LStream: TMemoryStream;
  LResponse: IRekognitionDetectLabelsResponse;
begin
  ActDetectLabels.Enabled := False;
  LClient := TRekognitionClient.Create;
  LStream := TMemoryStream.Create;
  Image.Bitmap.SaveToStream(LStream);
  LResponse := LClient.DetectLabels(TRekognitionImage.FromStream(LStream));
  if LResponse.IsSuccessful then
    DetectedLabels := TList<IRekognitionLabel>.Create(LResponse.Labels);
end;

procedure TMainForm.ActOpenImageExecute(Sender: TObject);
begin
  if OpenImageDialog.Execute then
  begin
    FImageFileName := OpenImageDialog.FileName;
    Image.Bitmap.LoadFromFile(FImageFileName);
    DetectedLabels := nil;
    ActDetectLabels.Enabled := True;
  end;
end;

procedure TMainForm.CheckShowConfidencesChange(Sender: TObject);
begin
  if (DetectedList.ItemCount > 0) and (DetectedList.ItemIndex > -1) then
    SelectLabel(DetectedLabels[DetectedList.ItemIndex]);
end;

procedure TMainForm.DetectedListChange(Sender: TObject);
begin
  SelectLabel(DetectedLabels[DetectedList.ItemIndex]);
end;

function TMainForm.GetLabelCategory(const ALabel: IRekognitionLabel): string;
var
  LCategory: IRekognitionLabelCategory;
  LCategoryNames: TList<string>;
begin
  LCategoryNames := TList<string>.Create;
  try
    for LCategory in ALabel.Categories do
      LCategoryNames.Add(LCategory.Name);

    Result := string.Join(', ', LCategoryNames.ToArray);
  finally
    LCategoryNames.Free;
  end;
end;

procedure TMainForm.SelectLabel(const ALabel: IRekognitionLabel);

  procedure OutlineInstance(const AInstance: IRekognitionInstance;
    const ACanvas: TCanvas);
  var
    LInstanceRect: TRectF;
    LTextRect: TRectF;
  begin
    LInstanceRect := RectF(
      AInstance.BoundingBox.Left.Value * ACanvas.Bitmap.Size.Width,
      AInstance.BoundingBox.Top.Value * ACanvas.Bitmap.Size.Height,
      (AInstance.BoundingBox.Left.Value + AInstance.BoundingBox.Width.Value) * ACanvas.Bitmap.Size.Width,
      (AInstance.BoundingBox.Top.Value + AInstance.BoundingBox.Height.Value) * ACanvas.Bitmap.Size.Height
    );
    ACanvas.BeginScene;
    ACanvas.Stroke.Color := TAlphaColors.Red;
    ACanvas.Stroke.Thickness := 1.0;
    ACanvas.DrawRect(LInstanceRect, 1.0);
    ACanvas.Fill.Color := TAlphaColors.Red;
    ACanvas.FillRect(LInstanceRect, 0.25);

    if CheckShowConfidences.IsChecked then
    begin
      LTextRect := RectF(
        AInstance.BoundingBox.Left.Value * ACanvas.Bitmap.Size.Width,
        ((AInstance.BoundingBox.Top.Value + AInstance.BoundingBox.Height.Value) * ACanvas.Bitmap.Size.Height) - 50,
        (AInstance.BoundingBox.Left.Value * ACanvas.Bitmap.Size.Width) + 100,
        ((AInstance.BoundingBox.Top.Value + AInstance.BoundingBox.Height.Value) * ACanvas.Bitmap.Size.Height)
      );
      ACanvas.Font.Size := 36;
      ACanvas.Font.Family := 'Arial';
      ACanvas.Fill.Color := TAlphaColors.White;
      ACanvas.Fill.Kind := TBrushKind.Solid;
      ACanvas.FillText(LTextRect, Format('%.2f', [AInstance.Confidence.Value]), False, 1.0, [], TTextAlign.Center, TTextAlign.Center);
    end;

    ACanvas.EndScene;
  end;

var
  LInstance: IRekognitionInstance;
  LBitmap: TBitmap;
begin
  if not Assigned(ALabel) or not Assigned(ALabel.Instances) then
    Exit;

  LBitmap := TBitmap.Create;
  try
    LBitmap.LoadFromFile(FImageFileName);
    for LInstance in ALabel.Instances do
      OutlineInstance(LInstance, LBitmap.Canvas);
    Image.Bitmap.Assign(LBitmap);
  finally
    LBitmap.Free;
  end;
end;

procedure TMainForm.SetDetectedLabels(const ADetectedLabels: TList<IRekognitionLabel>);
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
        LItem.Detail := GetLabelCategory(LLabel);
      end;
  finally
    DetectedList.EndUpdate;
  end;
end;

end.
