unit uConfig;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf,
  FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys,
  FireDAC.VCLUI.Wait, Data.DB, FireDAC.Comp.Client, FireDAC.Phys.MySQL,
  FireDAC.Phys.MySQLDef, uGlobal, dxShellDialogs;

type
  TfrmConfig = class(TForm)
    GroupBox1: TGroupBox;
    Label1: TLabel;
    edtHost: TEdit;
    Label2: TLabel;
    edtUsername: TEdit;
    Label3: TLabel;
    edtPassword: TEdit;
    Label4: TLabel;
    edtDB: TEdit;
    btnTest: TButton;
    btnGravar: TButton;
    GroupBox2: TGroupBox;
    Label5: TLabel;
    edtPath: TEdit;
    Button1: TButton;
    fodPath: TFileOpenDialog;
    procedure btnTestClick(Sender: TObject);
    procedure btnGravarClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmConfig: TfrmConfig;

implementation

{$R *.dfm}

procedure TfrmConfig.btnGravarClick(Sender: TObject);
begin
  TGlobal.DB.Host     := edtHost.Text;
  TGlobal.DB.Username := edtUsername.Text;
  TGlobal.DB.Password := edtPassword.Text;
  TGlobal.DB.Database := edtDB.Text;
  TGlobal.SavePath    := edtPath.Text;
  WriteConfig;
end;

procedure TfrmConfig.btnTestClick(Sender: TObject);
var
  Conn    : TFDConnection;
  oParams : TStrings;
begin
  Conn := TFDConnection.Create(Self);
  Conn.DriverName := 'MySQL';
  Conn.Params.add('Server=' + edtHost.Text);
  Conn.Params.UserName := edtUsername.Text;
  Conn.Params.Password := edtPassword.Text;
  Conn.Params.Database := edtDB.Text;

  try
    Conn.Connected := True;
    ShowMessage('Conexão estabelecida com sucesso!');
  except
    on e: Exception do
    begin
      raise Exception.Create('Erro:' + e.Message);
    end;
  end;
end;

procedure TfrmConfig.Button1Click(Sender: TObject);
begin
  if fodPath.Execute then
    edtPath.Text := fodPath.FileName;
end;

procedure TfrmConfig.FormCreate(Sender: TObject);
begin
  edtPath.Text     := TGlobal.SavePath;
  edtHost.Text     := TGlobal.DB.Host;
  edtUsername.Text := TGlobal.DB.Username;
  edtPassword.Text := TGlobal.DB.Password;
  edtDB.Text       := TGlobal.DB.Database;
end;

end.
