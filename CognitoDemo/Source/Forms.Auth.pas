unit Forms.Auth;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Appercept.Cognito.HostedUI, FMX.StdCtrls, FMX.Controls.Presentation;

type
  TAuthFormMode = (SignIn, SignOut);

  TAuthForm = class(TForm)
    CognitoHostedUI1: TCognitoHostedUI;
    ToolBar1: TToolBar;
    SpeedButton1: TSpeedButton;
    procedure FormShow(Sender: TObject);
    procedure CognitoHostedUI1Login(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure CognitoHostedUI1Logout(Sender: TObject);
  private
    FMode: TAuthFormMode;
    function GetClientId: string;
    procedure SetClientId(const AClientId: string);
    function GetClientSecret: string;
    procedure SetClientSecret(const AClientSecret: string);
    function GetDomain: string;
    procedure SetDomain(const ADomain: string);
    function GetRedirectURI: string;
    procedure SetRedirectURI(const ARedirectURI: string);
    function GetAccessToken: string;
    function GetIdToken: string;
    function GetRefreshToken: string;
  public
    property Mode: TAuthFormMode read FMode write FMode;
    property ClientId: string read GetClientId write SetClientId;
    property ClientSecret: string read GetClientSecret write SetClientSecret;
    property Domain: string read GetDomain write SetDomain;
    property RedirectURI: string read GetRedirectURI write SetRedirectURI;
    property AccessToken: string read GetAccessToken;
    property IdToken: string read GetIdToken;
    property RefreshToken: string read GetRefreshToken;
  end;

var
  AuthForm: TAuthForm;

implementation

{$R *.fmx}

procedure TAuthForm.CognitoHostedUI1Login(Sender: TObject);
begin
  ModalResult := mrOk;
end;

procedure TAuthForm.CognitoHostedUI1Logout(Sender: TObject);
begin
  ModalResult := mrOk;
end;

procedure TAuthForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
end;

procedure TAuthForm.FormShow(Sender: TObject);
begin
  case Mode of
    SignIn: CognitoHostedUI1.Authorize;
    SignOut: CognitoHostedUI1.Logout;
  end;
end;

function TAuthForm.GetAccessToken: string;
begin
  Result := CognitoHostedUI1.AccessToken;
end;

function TAuthForm.GetClientId: string;
begin
  Result := CognitoHostedUI1.ClientId;
end;

function TAuthForm.GetClientSecret: string;
begin
  Result := CognitoHostedUI1.ClientSecret;
end;

function TAuthForm.GetDomain: string;
begin
  Result := CognitoHostedUI1.Domain;
end;

function TAuthForm.GetIdToken: string;
begin
  Result := CognitoHostedUI1.IdToken;
end;

function TAuthForm.GetRedirectURI: string;
begin
  Result := CognitoHostedUI1.RedirectURI;
end;

function TAuthForm.GetRefreshToken: string;
begin
  Result := CognitoHostedUI1.RefreshToken;
end;

procedure TAuthForm.SetClientId(const AClientId: string);
begin
  CognitoHostedUI1.ClientId := AClientId;
end;

procedure TAuthForm.SetClientSecret(const AClientSecret: string);
begin
  CognitoHostedUI1.ClientSecret := AClientSecret;
end;

procedure TAuthForm.SetDomain(const ADomain: string);
begin
  CognitoHostedUI1.Domain := ADomain;
end;

procedure TAuthForm.SetRedirectURI(const ARedirectURI: string);
begin
  CognitoHostedUI1.RedirectURI := ARedirectURI;
end;

end.
