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
    procedure ActOpenImageExecute(Sender: TObject);
    procedure ActDetectLabelsExecute(Sender: TObject);
    procedure DetectedListChange(Sender: TObject);
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
  LResponse: IRekognitionDetectLabelsResponse;
begin
  ActDetectLabels.Enabled := False;
  LClient := TRekognitionClient.Create;
  LResponse := LClient.DetectLabels(TRekognitionImage.FromFile(FImageFileName));
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

  procedure OutlineBoundingBox(const ABoundingBox: IRekognitionBoundingBox;
    const ACanvas: TCanvas);
  var
    LPolygon: TPolygon;
  begin
    SetLength(LPolygon, 4);
    LPolygon[0] := PointF(
      ABoundingBox.Left.Value * ACanvas.Bitmap.Size.Width,
      ABoundingBox.Top.Value * ACanvas.Bitmap.Size.Height
    );
    LPolygon[1] := PointF(
      (ABoundingBox.Left.Value + ABoundingBox.Width.Value) * ACanvas.Bitmap.Size.Width,
      ABoundingBox.Top.Value * ACanvas.Bitmap.Size.Height
    );
    LPolygon[2] := PointF(
      (ABoundingBox.Left.Value + ABoundingBox.Width.Value) * ACanvas.Bitmap.Size.Width,
      (ABoundingBox.Top.Value + ABoundingBox.Height.Value) * ACanvas.Bitmap.Size.Height
    );
    LPolygon[3] := PointF(
      ABoundingBox.Left.Value * ACanvas.Bitmap.Size.Width,
      (ABoundingBox.Top.Value + ABoundingBox.Height.Value) * ACanvas.Bitmap.Size.Height
    );
    ACanvas.BeginScene;
    ACanvas.Stroke.Color := TAlphaColors.Red;
    ACanvas.Stroke.Thickness := 1.0;
    ACanvas.DrawPolygon(LPolygon, 1.0);
    ACanvas.Fill.Color := TAlphaColors.Red;
    ACanvas.FillPolygon(LPolygon, 0.25);
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
      OutlineBoundingBox(LInstance.BoundingBox, LBitmap.Canvas);
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
