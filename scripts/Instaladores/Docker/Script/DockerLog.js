var scriptArguments = WScript.Arguments;
try {
    if (scriptArguments.length !== 3) {
        throw new Error("Uso: DockerLog.js entrada log codificacao");
    }
    var charset = scriptArguments.Item(2);
    if (charset === "OEM") {
        var shell = new ActiveXObject("WScript.Shell");
        charset = "cp" + shell.RegRead("HKLM\\SYSTEM\\CurrentControlSet\\Control\\Nls\\CodePage\\OEMCP");
    }
    var source = new ActiveXObject("ADODB.Stream");
    source.Type = 2;
    source.Charset = charset;
    source.Open();
    source.LoadFromFile(scriptArguments.Item(0));
    var text = source.ReadText();
    source.Close();

    var encoded = new ActiveXObject("ADODB.Stream");
    encoded.Type = 2;
    encoded.Charset = "utf-8";
    encoded.Open();
    encoded.WriteText(text);
    encoded.Position = 0;
    encoded.Type = 1;
    encoded.Position = 3;

    var destination = new ActiveXObject("ADODB.Stream");
    destination.Type = 1;
    destination.Open();
    destination.LoadFromFile(scriptArguments.Item(1));
    destination.Position = destination.Size;
    if (encoded.Size > 3) {
        destination.Write(encoded.Read());
    }
    destination.SaveToFile(scriptArguments.Item(1), 2);
    destination.Close();
    encoded.Close();
    WScript.Quit(0);
} catch (error) {
    WScript.Echo("ERRO: conversao do log Docker: " + error.message);
    WScript.Quit(1);
}