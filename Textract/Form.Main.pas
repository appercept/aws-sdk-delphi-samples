unit Form.Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.StdCtrls, FMX.Controls.Presentation, System.Actions, FMX.ActnList,
  AWS.Textract, FMX.Memo.Types, FMX.ScrollBox, FMX.Memo, FMX.ListView.Types,
  FMX.ListView.Appearances, FMX.ListView.Adapters.Base, FMX.ListView,
  System.Generics.Collections;

type
  TMainForm = class(TForm)
    InputDocumentImage: TImage;
    ToolBar1: TToolBar;
    SpeedButton1: TSpeedButton;
    ActionList1: TActionList;
    ActOpen: TAction;
    OpenInputDocumentDialog: TOpenDialog;
    ActDetectDocumentText: TAction;
    MemoOutput: TMemo;
    SpeedButton2: TSpeedButton;
    BlocksListView: TListView;
    Panel1: TPanel;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    procedure ActOpenExecute(Sender: TObject);
    procedure ActDetectDocumentTextExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure BlocksListViewChange(Sender: TObject);
  private
    { Private declarations }
    Client: ITextractClient;
    InputDocumentFileName: string;
    FCurrentBlocks: TList<ITextractBlock>;
    procedure SetCurrentBlocks(const ABlocks: TList<ITextractBlock>);
    property CurrentBlocks: TList<ITextractBlock> read FCurrentBlocks write SetCurrentBlocks;
    procedure RefreshBlocksUI;
    procedure SelectBlock(const ABlock: ITextractBlock);
    procedure OutlinePath(const APath: TList<ITextractPoint>);
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

uses
  System.Math.Vectors;

{$R *.fmx}

procedure TMainForm.ActDetectDocumentTextExecute(Sender: TObject);
var
  LRequest: ITextractDetectDocumentTextRequest;
  LResponse: ITextractDetectDocumentTextResponse;
begin
  LRequest := TTextractDetectDocumentTextRequest.Create;
  LRequest.Document := TTextractDocument.FromFile(InputDocumentFileName);
  LResponse := Client.DetectDocumentText(LRequest);
  if LResponse.IsSuccessful then
    CurrentBlocks := LResponse.Blocks;
end;

procedure TMainForm.ActOpenExecute(Sender: TObject);
begin
  if OpenInputDocumentDialog.Execute then
  begin
    InputDocumentFileName := OpenInputDocumentDialog.FileName;
    InputDocumentImage.Bitmap.LoadFromFile(InputDocumentFileName);
    CurrentBlocks := nil;
    ActDetectDocumentText.Enabled := True;
  end;
end;

procedure TMainForm.BlocksListViewChange(Sender: TObject);
begin
  SelectBlock(CurrentBlocks[BlocksListView.ItemIndex]);
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FCurrentBlocks := TList<ITextractBlock>.Create;
  Client := TTextractClient.Create;
end;

procedure TMainForm.OutlinePath(const APath: TList<ITextractPoint>);
var
  LPolygon: TPolygon;
  I: Integer;
  LPoint: ITextractPoint;
  LBitmap: TBitmap;
  LScaleFactor: Single;
begin
  LBitmap := TBitmap.Create;
  try
    LBitmap.LoadFromFile(InputDocumentFileName);
    LScaleFactor := InputDocumentImage.Bitmap.Canvas.Scale;

    SetLength(LPolygon, APath.Count);
    for I := 0 to APath.Count - 1 do
    begin
      LPoint := APath[I];
      LPolygon[I] := PointF(
        LBitmap.Size.Width * LPoint.X.Value,
        LBitmap.Size.Height * LPoint.Y.Value
      );
    end;
    LBitmap.LoadFromFile(InputDocumentFileName);
    LBitmap.Canvas.BeginScene;
    LBitmap.Canvas.Stroke.Color := TAlphaColors.Red;
    LBitmap.Canvas.Stroke.Thickness := 1.0 * LScaleFactor;
    LBitmap.Canvas.DrawPolygon(LPolygon, 1.0);
    LBitmap.Canvas.Fill.Color := TAlphaColors.Red;
    LBitmap.Canvas.FillPolygon(LPolygon, 0.25);
    LBitmap.Canvas.EndScene;

    InputDocumentImage.Bitmap.Assign(LBitmap);
  finally
    LBitmap.Free;
  end;
end;

procedure TMainForm.RefreshBlocksUI;
begin
  BlocksListView.BeginUpdate;
  try
    BlocksListView.Items.Clear;
    for var LBlock in CurrentBlocks do
    begin
      var LItem := BlocksListView.Items.Add;
      LItem.Text := LBlock.Text;
      LItem.Detail := LBlock.BlockType;
    end;
  finally
    BlocksListView.EndUpdate;
  end;
end;

procedure TMainForm.SelectBlock(const ABlock: ITextractBlock);
begin
  MemoOutput.Text := ABlock.Text;

  if not Assigned(ABlock.Geometry) or not Assigned(ABlock.Geometry.Polygon) then
    Exit;

  OutlinePath(ABlock.Geometry.Polygon);
end;

procedure TMainForm.SetCurrentBlocks(const ABlocks: TList<ITextractBlock>);
begin
  CurrentBlocks.Clear;
  if Assigned(ABlocks) then
    for var LBock in ABlocks do
      CurrentBlocks.Add(LBock);
  RefreshBlocksUI;
end;

end.
