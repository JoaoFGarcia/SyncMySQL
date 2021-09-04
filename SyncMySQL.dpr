program SyncMySQL;

uses
  Vcl.Forms,
  System.JSON,
  uMainForm in 'uMainForm.pas' {frmMain},
  Vcl.Themes,
  Vcl.Styles,
  uConfig in 'uConfig.pas' {frmConfig},
  uGlobal in 'uGlobal.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := False;

  Populate;

  Application.Title := 'SyncMySQL';
  TStyleManager.TrySetStyle('Windows10');
  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TfrmConfig, frmConfig);
  Application.Run;
end.



