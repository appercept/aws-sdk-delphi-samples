program SecretsManagerConsole;

uses
  System.StartUpCopy,
  FMX.Forms,
  Form.Main in 'Form.Main.pas' {MainForm},
  Form.NewSecret in 'Form.NewSecret.pas' {NewSecretForm},
  Form.Secret in 'Form.Secret.pas' {SecretForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
