unit Forms.Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, System.Actions, FMX.ActnList,
  FMX.Memo.Types, FMX.ScrollBox, FMX.Memo,
  AWS.CognitoIdentity, AWS.S3, Forms.Auth, FMX.WebBrowser;

type
  TMainForm = class(TForm)
    ToolBar1: TToolBar;
    ActionList1: TActionList;
    ActSignInOut: TAction;
    SpeedButton1: TSpeedButton;
    ContentMemo: TMemo;
    ContentBrowser: TWebBrowser;
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure ActSignInOutUpdate(Sender: TObject);
    procedure ActSignInOutExecute(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    FCredentials: ICognitoAWSCredentials;
    FS3Client: IS3Client;
    FCurrentBucket: IS3Bucket;
    function GetS3Client: IS3Client;
    function GetAudienceForBucket(const ABucket: IS3Bucket): string;
    procedure RefreshBuckets;
    procedure SetCurrentBucket(const ABucket: IS3Bucket);
    function GetIsSignedIn: Boolean;
    procedure SignIn;
    procedure SignOut;
    function NewAuthForm: TAuthForm;
    property Credentials: ICognitoAWSCredentials read FCredentials;
    property S3Client: IS3Client read GetS3Client;
    property CurrentBucket: IS3Bucket read FCurrentBucket write SetCurrentBucket;
    property IsSignedIn: Boolean read GetIsSignedIn;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

uses Settings;

procedure TMainForm.ActSignInOutExecute(Sender: TObject);
begin
  if IsSignedIn then
    SignOut
  else
    SignIn;
end;

procedure TMainForm.ActSignInOutUpdate(Sender: TObject);
begin
  if IsSignedIn then
    ActSignInOut.Text := 'Sign Out'
  else
    ActSignInOut.Text := 'Sign In';
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FCredentials := TCognitoAWSCredentials.Create(IdentityPoolId, Region);
end;

function TMainForm.GetAudienceForBucket(const ABucket: IS3Bucket): string;
begin
  try
    var LResponse := S3Client.GetBucketTagging(ABucket.Name);
    if LResponse.IsSuccessful then
      Result := LResponse.TagSet['Audience'];
  except
    on ES3Exception do
      Result := '';
  end;
end;

function TMainForm.GetIsSignedIn: Boolean;
begin
  Result := Credentials.Logins.Count > 0;
end;

function TMainForm.GetS3Client: IS3Client;
var
  LS3Options: IS3Options;
begin
  if not Assigned(FS3Client) then
  begin
    LS3Options := TS3Options.Create;
    LS3Options.Credentials := Credentials;
    LS3Options.Region := Region;
    FS3Client := TS3Client.Create(LS3Options);
  end;

  Result := FS3Client;
end;

function TMainForm.NewAuthForm: TAuthForm;
begin
  Result := TAuthForm.Create(Self);
  Result.Domain := Domain;
  Result.ClientId := ClientId;
  Result.ClientSecret := ClientSecret;
  Result.RedirectURI := CallbackURI;
end;

procedure TMainForm.RefreshBuckets;
var
  LAudience: string;
begin
  try
    var LResponse := S3Client.ListBuckets;
    if LResponse.IsSuccessful then
    begin
      if Credentials.Logins.Count = 0 then
        LAudience := 'Guests'
      else
        LAudience := 'KnownUsers';

      for var LBucket in LResponse.Buckets do
      begin
        if CompareText(GetAudienceForBucket(LBucket), LAudience) = 0 then
        begin
          CurrentBucket := LBucket;
          Exit;
        end;
      end;
    end;
  except
    on E: ES3Exception do
      CurrentBucket := nil;
  end;
end;

procedure TMainForm.SetCurrentBucket(const ABucket: IS3Bucket);
begin
  FCurrentBucket := ABucket;
  ContentMemo.Lines.Clear;
  if Assigned(FCurrentBucket) then
  begin
    try
      var LResponse := S3Client.GetObject(ABucket.Name, 'index.html');
      var LContent := TStringList.Create;
      try
        LContent.LoadFromStream(LResponse.Body);
        ContentBrowser.LoadFromStrings(LContent.Text, '');
      finally
        LContent.Free;
      end;
    except
      on E: ES3Exception do
      begin
        ContentMemo.Lines.Add(CurrentBucket.Name);
        ContentMemo.Lines.Add('');
        ContentMemo.Lines.Add(E.Message);
      end;
    end;
  end;
end;

procedure TMainForm.SignIn;
var
  LAuthForm: TAuthForm;
begin
  LAuthForm := NewAuthForm;
  LAuthForm.Mode := TAuthFormMode.SignIn;
  LAuthForm.ShowModal(
    procedure(ModalResult: TModalResult)
    begin
      if ModalResult = mrOk then
      begin
        Credentials.AddLogin(
          ProviderName,
          LAuthForm.IdToken
        );
        RefreshBuckets;
      end;
    end
  );
end;

procedure TMainForm.SignOut;
var
  LAuthForm: TAuthForm;
begin
  LAuthForm := NewAuthForm;
  LAuthForm.Mode := TAuthFormMode.SignOut;
  LAuthForm.ShowModal(
    procedure(ModalResult: TModalResult)
    begin
      if ModalResult = mrOk then
      begin
        Credentials.ClearLogins;
        RefreshBuckets;
      end;
    end
  );
end;

procedure TMainForm.Timer1Timer(Sender: TObject);
begin
  RefreshBuckets;
  Timer1.Enabled := False;
end;

end.
