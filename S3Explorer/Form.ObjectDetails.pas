unit Form.ObjectDetails;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.TabControl,
  AWS.S3, FMX.Controls.Presentation, FMX.StdCtrls, System.Rtti, FMX.Grid.Style,
  FMX.Grid, FMX.ScrollBox, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf,
  FireDAC.DApt.Intf, Data.Bind.EngExt, Fmx.Bind.DBEngExt, Fmx.Bind.Grid,
  System.Bindings.Outputs, Fmx.Bind.Editors, Data.Bind.Components,
  Data.Bind.Grid, Data.Bind.DBScope, Data.DB, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client, System.Actions, FMX.ActnList;

type
  TObjectDetailsForm = class(TForm)
    TabControl1: TTabControl;
    TiProperties: TTabItem;
    PropertiesGrid: TStringGrid;
    TblProperties: TFDMemTable;
    BindSourceDB1: TBindSourceDB;
    BindingsList1: TBindingsList;
    LinkGridToDataSourceBindSourceDB1: TLinkGridToDataSource;
    ObjectToolBar: TToolBar;
    BtnDownload: TSpeedButton;
    ObjectActionList: TActionList;
    ActionDownload: TAction;
    DownloadAsDialog: TSaveDialog;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure ActionDownloadExecute(Sender: TObject);
  private
    { Private declarations }
    FBucketObject: IS3Object;
    function GetS3URI(const ABucket, AKey: string): string;
    function HumanSize(const ASizeInBytes: Integer): string;
    procedure SetBucketObject(const AObject: IS3Object);
    procedure SetProperty(const AProperty, AValue: string);
  public
    { Public declarations }
    property BucketObject: IS3Object read FBucketObject write SetBucketObject;
  end;

var
  ObjectDetailsForm: TObjectDetailsForm;

implementation

uses
  Math,
  System.IOUtils,
  System.Net.URLClient;

{$R *.fmx}

{ TObjectDetailsForm }

procedure TObjectDetailsForm.ActionDownloadExecute(Sender: TObject);
begin
  DownloadAsDialog.FileName := TPath.GetFileName(BucketObject.Key);
  if DownloadAsDialog.Execute then
  begin
    BucketObject.DownloadFile(DownloadAsDialog.FileName);
  end;
end;

procedure TObjectDetailsForm.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
end;

procedure TObjectDetailsForm.FormCreate(Sender: TObject);
begin
  TblProperties.CreateDataSet;
end;

function TObjectDetailsForm.GetS3URI(const ABucket, AKey: string): string;
begin
  Result := Format('s3://%s/%s', [ABucket, AKey]);
end;

function TObjectDetailsForm.HumanSize(const ASizeInBytes: Integer): string;
const
  Scale: array[0..5] of string = ('B', 'KiB', 'MiB', 'GiB', 'TiB', 'PiB');
var
  LExp: Integer;
begin
  LExp := 0;
  while ASizeInBytes > Power(1024, LExp + 1) do
    Inc(LExp);

  Result := Format('%.2f %s', [ASizeInBytes / IntPower(1024, LExp), Scale[LExp]]);
end;

procedure TObjectDetailsForm.SetBucketObject(const AObject: IS3Object);
begin
  FBucketObject := AObject;
  if Assigned(BucketObject) then
  begin
    Caption := Format('Object: %s', [BucketObject.Key]);
    SetProperty(
      'Amazon Resource Name (ARN)',
      Format('arn:aws:s3:::%s/%s', [BucketObject.Bucket.Name, BucketObject.Key])
    );
    SetProperty('AWS Region', BucketObject.Bucket.Location);
    SetProperty('Entity tag (Etag)', BucketObject.ETag);
    SetProperty('Key', BucketObject.Key);
    if BucketObject.LastModified.HasValue then
      SetProperty('Last Modified', FormatDateTime('c', BucketObject.LastModified.Value));
    SetProperty('S3 URI', GetS3URI(BucketObject.Bucket.Name, BucketObject.Key));
    if BucketObject.Size.HasValue then
      SetProperty('Size', HumanSize(BucketObject.Size.Value));
  end;
end;

procedure TObjectDetailsForm.SetProperty(const AProperty, AValue: string);
begin
  TblProperties.Append;
  TblProperties.Fields[0].AsString := AProperty;
  TblProperties.Fields[1].AsString := AValue;
  TblProperties.Post;
end;

end.
