unit DataModules.TextExtraction;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.Types,
  AWS.Textract;

type
  TTextExtractionDM = class(TDataModule)
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private
    FClient: ITextractClient;
    FCurrentBlocks: TList<ITextractBlock>;
    FInputFileName: string;
    property Client: ITextractClient read FClient;
    procedure SetCurrentBlocks(const ABlocks: TList<ITextractBlock>);
    property CurrentBlocks: TList<ITextractBlock> read FCurrentBlocks write SetCurrentBlocks;
    function SelectBlocksAt(const APoint: TPointF): TList<ITextractBlock>;
  public
    function ExtractText(const AFileName: string): Boolean;
    function SelectTextAt(const APoint: TPointF): string;

    property InputFileName: string read FInputFileName;
  end;

var
  TextExtractionDM: TTextExtractionDM;

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}

{$R *.dfm}

{ TTextExtractionDM }

procedure TTextExtractionDM.DataModuleCreate(Sender: TObject);
begin
  FClient := TTextractClient.Create;
  FCurrentBlocks := TList<ITextractBlock>.Create;
end;

procedure TTextExtractionDM.DataModuleDestroy(Sender: TObject);
begin
  FCurrentBlocks.Free;
  FClient := nil;
end;

function TTextExtractionDM.ExtractText(const AFileName: string): Boolean;
var
  LRequest: ITextractDetectDocumentTextRequest;
  LResponse: ITextractDetectDocumentTextResponse;
begin
  FInputFileName := AFileName;
  LRequest := TTextractDetectDocumentTextRequest.Create;
  LRequest.Document := TTextractDocument.FromFile(InputFileName);
  LResponse := Client.DetectDocumentText(LRequest);
  if LResponse.IsSuccessful then
  begin
    CurrentBlocks := LResponse.Blocks;
    Result := True;
  end
  else
    Result := False;
end;

function TTextExtractionDM.SelectBlocksAt(
  const APoint: TPointF): TList<ITextractBlock>;
var
  LBlock: ITextractBlock;
begin
  Result := TList<ITextractBlock>.Create;
  for LBlock in CurrentBlocks do
    if not LBlock.BlockType.Equals('PAGE')
      and (APoint.X >= LBlock.Geometry.BoundingBox.Left.Value)
      and (APoint.X <= LBlock.Geometry.BoundingBox.Left.Value + LBlock.Geometry.BoundingBox.Width.Value)
      and (APoint.Y >= LBlock.Geometry.BoundingBox.Top.Value)
      and (APoint.Y <= LBlock.Geometry.BoundingBox.Top.Value + LBlock.Geometry.BoundingBox.Height.Value) then
        Result.Add(LBlock);
end;

function TTextExtractionDM.SelectTextAt(const APoint: TPointF): string;
var
  LBlocks: TList<ITextractBlock>;
begin
  Result := '';
  LBlocks := SelectBlocksAt(APoint);
  try
    if LBlocks.Count > 0 then
      Result := LBlocks.First.Text;
  finally
    LBlocks.Free;
  end;
end;

procedure TTextExtractionDM.SetCurrentBlocks(
  const ABlocks: TList<ITextractBlock>);
begin
  CurrentBlocks.Clear;
  if Assigned(ABlocks) then
    for var LBock in ABlocks do
      CurrentBlocks.Add(LBock);
end;

end.
