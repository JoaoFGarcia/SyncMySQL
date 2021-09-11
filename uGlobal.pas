unit uGlobal;

interface

uses System.JSON, Classes, SysUtils;

type
  TDB = record
  public
    Host: string;
    Username: string;
    Password: string;
    Database: string;
  end;

type
  TGlobal = class
  public
  class var
    SavePath: string;
    Interval: Integer;
    DB: TDB;
  end;

function ParseConfig(Path: String; DefaultValue : String = ''): String;
procedure WriteConfig();
procedure Populate();

implementation

function ParseConfig(Path: String; DefaultValue : String = ''): String;
var
  JSonValue  : TJSonValue;
  JSONString : string;
  Branch     : string;

  stream     : TFileStream;

  Flags : Word;
begin
  try
    try
      Flags := fmOpenRead;

      if not FileExists(GetCurrentDir + '\config.json') then
        Flags := Flags or fmCreate;

      stream := TFileStream.Create(GetCurrentDir + '\config.json', Flags);

      if stream.Size > 0 then
      begin
        SetLength(JSONString, stream.Size div 2);
        stream.Read(Pointer(JSONString)^, stream.Size);
      end;

      JSonValue := TJSonObject.ParseJSONValue(JSONString);
      Result := JSonValue.GetValue<string>(Path, DefaultValue);
    except
      Result := DefaultValue;
    end;
  finally
    FreeAndNil(JSonValue);
    FreeAndNil(stream);
  end;
end;

procedure WriteConfig();
var
  mainObject : TJSonObject;
  dbObject   : TJSonObject;
  teste  : TJsonPair;

  stream     : TFileStream;
  json       : String;
begin
  mainObject := TJSonObject.Create;
  dbObject   := TJSonObject.Create;
  stream     := TFileStream.Create(GetCurrentDir + '\config.json', fmCreate or fmOpenWrite or fmShareDenyWrite);
  try
    dbObject.AddPair('Host'     , TGlobal.DB.Host);
    dbObject.AddPair('UserName' , TGlobal.DB.UserName);
    dbObject.AddPair('Password' , TGlobal.DB.Password);
    dbObject.AddPair('DatabaseName' , TGlobal.DB.Database);

    mainObject.AddPair('SavePath', TGlobal.SavePath);
    mainObject.AddPair('Interval', IntToStr(TGlobal.Interval));
    mainObject.AddPair('Database', dbObject);

    json := (mainObject.ToJSON());
    stream.writebuffer(PChar(json)^, Length(json) * 2);
  finally
    FreeAndNil(mainObject);
    FreeAndNil(stream);
  end;
end;

procedure Populate();
begin
  TGlobal.SavePath    := ParseConfig('SavePath', '');
  TGlobal.Interval    := StrToInt(ParseConfig('Interval', '0'));
  TGlobal.DB.Host     := ParseConfig('Database.Host', '127.0.0.1');
  TGlobal.DB.Username := ParseConfig('Database.UserName', 'root');
  TGlobal.DB.Password := ParseConfig('Database.Password');
  TGlobal.DB.Database := ParseConfig('Database.DatabaseName');
end;

end.
