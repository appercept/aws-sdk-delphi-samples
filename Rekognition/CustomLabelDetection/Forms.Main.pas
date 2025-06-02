unit Forms.Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.ListView.Types,
  FMX.ListView.Appearances, FMX.ListView.Adapters.Base, System.Actions,
  FMX.ActnList, FMX.Objects, FMX.ListView, AWS.Rekognition, System.Generics.Collections,
  AWS.Types;

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
    ActDetectCustomLabels: TAction;
    SpeedButton2: TSpeedButton;
    CheckShowAllModels: TCheckBox;
    Splitter2: TSplitter;
    ProjectVersionsList: TListView;
    procedure ActOpenImageExecute(Sender: TObject);
    procedure ActDetectCustomLabelsExecute(Sender: TObject);
    procedure DetectedListChange(Sender: TObject);
    procedure CheckShowAllModelsChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ProjectVersionsListChange(Sender: TObject);
    procedure ActDetectCustomLabelsUpdate(Sender: TObject);
  private
    FClient: IRekognitionClient;
    FImageFileName: string;
    FDetectedLabels: TList<IRekognitionCustomLabel>;
    FProjects: TDictionary<TARN, string>;
    FProjectVersions: TList<IRekognitionProjectVersionDescription>;
    FFilteredProjectVersions: TList<IRekognitionProjectVersionDescription>;
    FSelectedProjectVersion: IRekognitionProjectVersionDescription;
    procedure RefreshProjects;
    procedure RefreshProjectVersions;
    procedure UpdateProjectVersionList;
    procedure SetDetectedLabels(
      const ADetectedLabels: TList<IRekognitionCustomLabel>);
    procedure SetSelectedProjectVersion(
      const ASelectedProjectVersion: IRekognitionProjectVersionDescription);
    property Client: IRekognitionClient read FClient;
    property SelectedProjectVersion: IRekognitionProjectVersionDescription read FSelectedProjectVersion write SetSelectedProjectVersion;
  public
    procedure SelectLabel(const ALabel: IRekognitionCustomLabel);
    property DetectedLabels: TList<IRekognitionCustomLabel> read FDetectedLabels write SetDetectedLabels;
  end;

var
  MainForm: TMainForm;

implementation

uses
  System.Math.Vectors;

{$R *.fmx}

procedure TMainForm.ActDetectCustomLabelsExecute(Sender: TObject);
var
  LResponse: IRekognitionDetectCustomLabelsResponse;
begin
  ActDetectCustomLabels.Enabled := False;
  LResponse := Client.DetectCustomLabels(
    TRekognitionImage.FromFile(FImageFileName),
    SelectedProjectVersion.ProjectVersionArn
  );
  if LResponse.IsSuccessful then
    DetectedLabels := TList<IRekognitionCustomLabel>.Create(LResponse.CustomLabels);
end;

procedure TMainForm.ActDetectCustomLabelsUpdate(Sender: TObject);
begin
  ActDetectCustomLabels.Enabled := not FImageFileName.IsEmpty
    and FileExists(FImageFileName)
    and Assigned(SelectedProjectVersion)
    and SelectedProjectVersion.Status.Equals('RUNNING');
end;

procedure TMainForm.ActOpenImageExecute(Sender: TObject);
begin
  if OpenImageDialog.Execute then
  begin
    FImageFileName := OpenImageDialog.FileName;
    Image.Bitmap.LoadFromFile(FImageFileName);
    DetectedLabels := nil;
    UpdateActions;
  end;
end;

procedure TMainForm.CheckShowAllModelsChange(Sender: TObject);
begin
  UpdateProjectVersionList;
end;

procedure TMainForm.DetectedListChange(Sender: TObject);
begin
  SelectLabel(DetectedLabels[DetectedList.ItemIndex]);
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FClient := TRekognitionClient.Create;
  FProjects := TDictionary<TARN, string>.Create;
  FProjectVersions := TList<IRekognitionProjectVersionDescription>.Create;
  FFilteredProjectVersions := TList<IRekognitionProjectVersionDescription>.Create;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FFilteredProjectVersions.Free;
  FProjectVersions.Free;
  FProjects.Free;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  RefreshProjects;
  RefreshProjectVersions;
  UpdateProjectVersionList;
end;

procedure TMainForm.ProjectVersionsListChange(Sender: TObject);
begin
  SelectedProjectVersion := FFilteredProjectVersions[ProjectVersionsList.ItemIndex];
end;

procedure TMainForm.RefreshProjects;
var
  LRequest: IRekognitionDescribeProjectsRequest;
  LResponse: IRekognitionDescribeProjectsResponse;
begin
  FProjects.Clear;
  LRequest := TRekognitionDescribeProjectsRequest.Create;
  LRequest.AddFeature('CUSTOM_LABELS');
  LRequest.MaxResults := 100;
  repeat
    LResponse := Client.DescribeProjects(LRequest);
    if LResponse.IsSuccessful then
    begin
      for var LProject in LResponse.ProjectDescriptions do
        FProjects.Add(LProject.ProjectArn, LProject.ProjectArn.ResourceId);

      LRequest.NextToken := LResponse.NextToken;
    end;
  until LRequest.NextToken.IsEmpty;
end;

procedure TMainForm.RefreshProjectVersions;
var
  LProject: TPair<TARN, string>;
  LResponse: IRekognitionDescribeProjectVersionsResponse;
  LNextToken: string;
begin
  FProjectVersions.Clear;
  LNextToken := '';
  for LProject in FProjects do
  begin
    repeat
      LResponse := Client.DescribeProjectVersions(LProject.Key, 100, LNextToken);
      if LResponse.IsSuccessful then
      begin
        FProjectVersions.AddRange(LResponse.ProjectVersionDescriptions);
        LNextToken := LResponse.NextToken;
      end;
    until LNextToken.IsEmpty;
  end;
end;

procedure TMainForm.SelectLabel(const ALabel: IRekognitionCustomLabel);

  procedure OutlineGeometry(const ACanvas: TCanvas);
  var
    LInstanceRect: TRectF;
  begin
    LInstanceRect := RectF(
      ALabel.Geometry.BoundingBox.Left.Value * ACanvas.Bitmap.Size.Width,
      ALabel.Geometry.BoundingBox.Top.Value * ACanvas.Bitmap.Size.Height,
      (ALabel.Geometry.BoundingBox.Left.Value + ALabel.Geometry.BoundingBox.Width.Value) * ACanvas.Bitmap.Size.Width,
      (ALabel.Geometry.BoundingBox.Top.Value + ALabel.Geometry.BoundingBox.Height.Value) * ACanvas.Bitmap.Size.Height
    );
    ACanvas.BeginScene;
    ACanvas.Stroke.Color := TAlphaColors.Red;
    ACanvas.Stroke.Thickness := 1.0;
    ACanvas.DrawRect(LInstanceRect, 1.0);
    ACanvas.Fill.Color := TAlphaColors.Red;
    ACanvas.FillRect(LInstanceRect, 0.25);

    ACanvas.EndScene;
  end;

var
  LBitmap: TBitmap;
begin
  if not Assigned(ALabel) or not Assigned(ALabel.Geometry) then
    Exit;

  LBitmap := TBitmap.Create;
  try
    LBitmap.LoadFromFile(FImageFileName);
    OutlineGeometry(LBitmap.Canvas);
    Image.Bitmap.Assign(LBitmap);
  finally
    LBitmap.Free;
  end;
end;

procedure TMainForm.SetDetectedLabels(const ADetectedLabels: TList<IRekognitionCustomLabel>);
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

procedure TMainForm.SetSelectedProjectVersion(
  const ASelectedProjectVersion: IRekognitionProjectVersionDescription);
begin
  FSelectedProjectVersion := ASelectedProjectVersion;
  UpdateActions;
end;

procedure TMainForm.UpdateProjectVersionList;
begin
  FFilteredProjectVersions.Clear;
  if CheckShowAllModels.IsChecked then
    FFilteredProjectVersions.AddRange(FProjectVersions)
  else
  begin
    for var LProjectVersion in FProjectVersions do
      if LProjectVersion.Status.Equals('RUNNING') then
        FFilteredProjectVersions.Add(LProjectVersion);
  end;

  ProjectVersionsList.BeginUpdate;
  try
    ProjectVersionsList.Items.Clear;
    for var LProjectVersion in FFilteredProjectVersions do
    begin
      var LItem := ProjectVersionsList.Items.Add;
      LItem.Text := LProjectVersion.ProjectVersionArn.ResourceId;
      LItem.Detail := Format('%s: %s', [LProjectVersion.Status, LProjectVersion.StatusMessage]);
    end;
  finally
    ProjectVersionsList.EndUpdate;
  end;
  if (FFilteredProjectVersions.Count > 0) and (ProjectVersionsList.ItemIndex >= 0) then
    SelectedProjectVersion := FFilteredProjectVersions[ProjectVersionsList.ItemIndex];
end;

end.
