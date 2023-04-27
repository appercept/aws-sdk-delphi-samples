unit Form.Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.ListBox,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.ListView.Types, FMX.Edit,
  FMX.Layouts, AWS.S3, FMX.ListView.Appearances, FMX.ListView.Adapters.Base,
  FMX.ListView, FMX.TreeView, FMX.TabControl, System.ImageList, FMX.ImgList,
  System.Actions, FMX.ActnList;

type
  TMainForm = class(TForm)
    BucketSelector: TComboBox;
    Label1: TLabel;
    EditPrefix: TEdit;
    TvPrefixes: TTreeView;
    LbObjects: TListBox;
    Panel1: TPanel;
    Splitter1: TSplitter;
    StatusBar: TStatusBar;
    LblStatus: TLabel;
    TabControl1: TTabControl;
    TiObjects: TTabItem;
    ToolBar1: TToolBar;
    SpeedButton1: TSpeedButton;
    ActionList1: TActionList;
    ActRefreshBuckets: TAction;
    ActUploadFile: TAction;
    ImageList1: TImageList;
    SpeedButton2: TSpeedButton;
    UploadDialog: TOpenDialog;
    procedure BucketSelectorChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure TvPrefixesChange(Sender: TObject);
    procedure LbObjectsDblClick(Sender: TObject);
    procedure ActRefreshBucketsExecute(Sender: TObject);
    procedure ActUploadFileExecute(Sender: TObject);
  private
    { Private declarations }
    FClient: IS3Client;
    FBucket: IS3Bucket;
    FBucketClient: IS3Client;
    FObjects: IS3Objects;
    FPrefix: string;
    function GetObject(const AKey: string): IS3Object;
    procedure SetObjects(const AObjects: IS3Objects);
    property Client: IS3Client read FClient;
    property BucketClient: IS3Client read FBucketClient;
    property Bucket: IS3Bucket read FBucket;
    property Objects: IS3Objects read FObjects write SetObjects;
    property Prefix: string read FPrefix;

    { UI }
    procedure ClearPrefixes;
    procedure ClearObjects;
    function PrefixFromNode(const ANode: TTreeViewItem): string;
    procedure RenderPrefixes(const APrefixes: TS3CommonPrefixes);
    procedure RenderObjects(const AObjects: IS3Objects);
    procedure SetStatus(const AStatus: string);

    { S3 }
    procedure RefreshBuckets;
    procedure RefreshObjects;
    procedure ChangeBucket(const ABucket: string);
    procedure ChangePrefix(const APrefix: string);
    function PrefixKey(const APrefix, AKey: string): string;
    function RemoveLeadingSeperator(const APrefix: string): string;
    function RemoveTrailingSeperator(const APrefix: string): string;
    function StripPrefix(const APrefix, AKey: string): string;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

uses
  Form.ObjectDetails,
  System.Generics.Collections,
  System.IOUtils, Form.FileUpload;

{$R *.fmx}

procedure TMainForm.ActRefreshBucketsExecute(Sender: TObject);
begin
  RefreshBuckets;
end;

procedure TMainForm.ActUploadFileExecute(Sender: TObject);
var
  LFileUploadForm: TFileUploadForm;
  LFileName, LKey: string;
begin
  if UploadDialog.Execute then
  begin
    LFileName := TPath.GetFileName(UploadDialog.FileName);
    LKey := PrefixKey(Prefix, LFileName);
    LFileUploadForm := TFileUploadForm.Create(nil);
    LFileUploadForm.UploadFile(
      UploadDialog.FileName,
      Bucket.Name,
      LKey,
      BucketClient
    );
  end;
end;

procedure TMainForm.BucketSelectorChange(Sender: TObject);
begin
  ClearPrefixes;
  ChangeBucket(BucketSelector.Selected.Text);
end;

procedure TMainForm.ChangeBucket(const ABucket: string);
var
  LOptions: IS3Options;
begin
  SetStatus(Format('Changing bucket to %s...', [ABucket]));

  // IMPORTANT: Interacting with a bucket requires a client configured for the
  // region in which the bucket is located. We query the location of the bucket
  // and construct a TS3Client for the region.
  var LocationResponse := Client.GetBucketLocation(ABucket);
  if LocationResponse.IsSuccessful then
  begin
    LOptions := TS3Options.Create;
    // If the LocationConstraint is returned empty, the bucket is located in
    // `us-east-1`.
    if LocationResponse.LocationConstraint.IsEmpty then
      LOptions.Region := 'us-east-1'
    else
      LOptions.Region := LocationResponse.LocationConstraint;
    FBucketClient := TS3Client.Create(LOptions);
  end;
  FBucket := TS3Bucket.Create(ABucket, BucketClient);

  // ChangePrefix triggers fetching the bucket contents.
  ChangePrefix('');
end;

procedure TMainForm.ChangePrefix(const APrefix: string);
begin
  SetStatus(Format('Changing prefix to %s...', [APrefix]));
  FPrefix := APrefix;
  EditPrefix.Text := Prefix;
  ClearObjects;
  RefreshObjects;
end;

procedure TMainForm.ClearObjects;
begin
  LbObjects.Clear;
end;

procedure TMainForm.ClearPrefixes;
var
  LRootItem: TTreeViewItem;
begin
  TvPrefixes.Clear;
  LRootItem := TTreeViewItem.Create(Self);
  LRootItem.Text := '/';
  TvPrefixes.AddObject(LRootItem);
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FClient := TS3Client.Create;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  RefreshBuckets;
end;

function TMainForm.GetObject(const AKey: string): IS3Object;
begin
  if not Assigned(Objects) then
    Exit(nil);

  for var LObject in Objects do
    if LObject.Key.Equals(AKey) then
      Exit(LObject);

  Result := nil;
end;

procedure TMainForm.LbObjectsDblClick(Sender: TObject);
begin
  if Assigned(LbObjects.Selected) then
  begin
    var LObjForm := TObjectDetailsForm.Create(nil);
    LObjForm.BucketObject := GetObject(PrefixKey(Prefix, LbObjects.Selected.Text));
    LObjForm.Show;
  end;
end;

function TMainForm.PrefixKey(const APrefix, AKey: string): string;
var
  LPrefix: string;
begin
  LPrefix := RemoveTrailingSeperator(APrefix);
  if LPrefix.IsEmpty then
    Exit(AKey);

  Result := Format('%s/%s', [LPrefix, RemoveLeadingSeperator(AKey)]);
end;

function TMainForm.PrefixFromNode(const ANode: TTreeViewItem): string;
var
  LReversedPath: TStack<string>;
  LNode: TTreeViewItem;
  LResult: TStringBuilder;
begin
  if not Assigned(ANode) then
    Exit('');

  LResult := TStringBuilder.Create('/');
  try
    LReversedPath := TStack<string>.Create;
    try
      LNode := ANode;
      while Assigned(LNode) do
      begin
        LReversedPath.Push(LNode.Text);
        LNode := LNode.ParentItem;
      end;

      while LReversedPath.Count > 0 do
      begin
        var LPart := LReversedPath.Pop;
        if not LPart.Equals('/') then
        begin
          LResult.Append(LPart);
          LResult.Append('/');
        end;
      end;
    finally
      LReversedPath.Free;
    end;

    Result := LResult.ToString;
  finally
    LResult.Free;
  end;
end;

procedure TMainForm.RefreshBuckets;

  function IndexOfBucket(const ABucketName: string): Integer;
  var
    I: Integer;
  begin
    Result := -1;
    for I := 0 to BucketSelector.Items.Count - 1 do
      if BucketSelector.Items[I].Equals(ABucketName) then
      begin
        Result := I;
        Break;
      end;
  end;

var
  LResponse: IS3ListBucketsResponse;
begin
  SetStatus('Refreshing buckets...');
  BucketSelector.BeginUpdate;
  try
    BucketSelector.Clear;
    LResponse := Client.ListBuckets;
    if LResponse.IsSuccessful then
    begin
      for var LBucket in LResponse.Buckets do
        BucketSelector.Items.Add(LBucket.Name);
    end;
    if Assigned(Bucket) then
      BucketSelector.ItemIndex := IndexOfBucket(Bucket.Name);
  finally
    BucketSelector.EndUpdate;
  end;
end;

procedure TMainForm.RefreshObjects;
var
  LRequest: IS3ListObjectsV2Request;
  LResponse: IS3ListObjectsV2Response;
begin
  // NOTE: S3 is not a filesystem but it does provide some methods for querying
  // it as if it were.
  LRequest := TS3ListObjectsV2Request.Create(Bucket.Name);
  // Set the request Delimiter to `/` to reflect the common directory seperator.
  LRequest.Delimiter := '/';
  // Specify the current Prefix (directory path) to fetch objects for.
  LRequest.Prefix := RemoveLeadingSeperator(Prefix);
  LResponse := BucketClient.ListObjectsV2(LRequest);
  if LResponse.IsSuccessful then
  begin
    // The response's CommonPrefixes provides a list of lower-level prefixes
    // (sub-directories).
    RenderPrefixes(LResponse.CommonPrefixes);
  end;

  // The `ListObjectsV2` request will only contain a single page of objects.
  // Multiple calls are required to retrieve the contents of a prefix
  // (directory) containing greater than 1,000. While we could just call the
  // following `TS3Bucket.Objects` function which will automatically page
  // through the results returning a full list of objects, we need to call the
  // `ListObjectsV2` response to retrieve the CommonPrefixes.
  // While calling Objects here immediately after ListObjectsV2 is inefficient,
  // it is performed here for convenience.
  Objects := Bucket.Objects(LRequest);
end;

function TMainForm.RemoveLeadingSeperator(const APrefix: string): string;
begin
  if APrefix.StartsWith('/') then
    Result := APrefix.Substring(1)
  else
    Result := APrefix;
end;

function TMainForm.RemoveTrailingSeperator(const APrefix: string): string;
begin
  if APrefix.IsEmpty or APrefix.Equals('/') then
    Exit('');

  if APrefix[APrefix.Length] = '/' then
    Result := APrefix.Substring(1, APrefix.Length - 2)
  else
    Result := APrefix;
end;

procedure TMainForm.RenderObjects(const AObjects: IS3Objects);
begin
  SetStatus(Format('Loading %d objects...', [AObjects.Count]));
  LbObjects.BeginUpdate;
  try
    LbObjects.Items.Clear;
    for var LObject in AObjects do
      LbObjects.Items.Add(StripPrefix(Prefix, LObject.Key));
  finally
    LbObjects.EndUpdate;
  end;
end;

procedure TMainForm.RenderPrefixes(const APrefixes: TS3CommonPrefixes);

  function FindPrefixNode(const APrefixPart: string; AParent: TTreeViewItem): TTreeViewItem;
  var
    I: Integer;
    LItem: TTreeViewItem;
  begin
    if Assigned(AParent) then
    begin
      for I := 0 to AParent.Count - 1 do
      begin
        LItem := AParent.Items[I];
        if LItem.Text.Equals(APrefixPart) then
          Exit(LItem);
      end;
    end
    else
    begin
      for I := 0 to TvPrefixes.Count - 1 do
      begin
        LItem := TvPrefixes.Items[I];
        if LItem.Text.Equals(APrefixPart) then
          Exit(LItem);
      end;
    end;

    Result := nil;
  end;

  function RenderPrefixPart(const APrefixPart: string; AParent: TTreeViewItem): TTreeViewItem;
  begin
    if APrefixPart.IsEmpty then
      Exit(nil);

    Result := FindPrefixNode(APrefixPart, AParent);

    if not Assigned(Result) then
    begin
      Result := TTreeViewItem.Create(Self);
      Result.Text := APrefixPart;
      if Assigned(AParent) then
        AParent.AddObject(Result)
      else
        TvPrefixes.AddObject(Result);
    end;
  end;

  procedure RenderPrefix(const APrefix: string);
  var
    LPrefixPath: TArray<string>;
    LItem: TTreeViewItem;
  begin
    LItem := TvPrefixes.Items[0];
    LPrefixPath := APrefix.Split(['/']);
    for var LPrefixPart in LPrefixPath do
      LItem := RenderPrefixPart(LPrefixPart, LItem);
  end;

begin
  TvPrefixes.BeginUpdate;
  try
    for var LCommonPrefix in APrefixes do
      RenderPrefix(LCommonPrefix.Prefix);
  finally
    TvPrefixes.EndUpdate;
  end;
end;

procedure TMainForm.SetObjects(const AObjects: IS3Objects);
begin
  FObjects := AObjects;
  RenderObjects(Objects);
end;

procedure TMainForm.SetStatus(const AStatus: string);
begin
  LblStatus.Text := AStatus;
end;

function TMainForm.StripPrefix(const APrefix, AKey: string): string;
begin
  if APrefix.IsEmpty or AKey.IsEmpty or (APrefix.Length >= AKey.Length) then
    Exit(AKey);

  Result := AKey.Substring(APrefix.Length - 1);
end;

procedure TMainForm.TvPrefixesChange(Sender: TObject);
begin
  ChangePrefix(PrefixFromNode(TvPrefixes.Selected));
end;

end.
