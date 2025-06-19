#define MyAppName "BetterDiscordAutoInstaller"
#define MyAppVersion "1.5.0"
#define MyAppPublisher "Zwylair"
#define MyAppURL "https://github.com/Zwylair/BetterDiscordAutoInstaller/"
#define MyAppExeName "updater.exe"

[Setup]
AppId={{9EB43811-BD22-4CDF-A552-5A4B070F4664}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={localappdata}\{#MyAppName}
UninstallDisplayIcon={app}\{#MyAppExeName}
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=commandline
OutputDir=C:\Users\jakub\Downloads
OutputBaseFilename=BetterDiscordAutoInstaller
SetupIconFile=C:\Users\jakub\Downloads\logo_small.ico
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon} (Discord shortcut)"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "C:\Programs Portable\BetterDiscordAutoInstaller\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Programs Portable\BetterDiscordAutoInstaller\logo_small.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Programs Portable\BetterDiscordAutoInstaller\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
var
  DiscordPathPage: TInputDirWizardPage;

procedure InitializeWizard;
begin
  DiscordPathPage := CreateInputDirPage(wpSelectDir,
    'Discord Localization',
    'Select Where Discord is installed',
    'Select folder of discord localization. Example: C:\Users\Username\AppData\Local\Discord.',
    False, '');
    
  DiscordPathPage.Add('');
  DiscordPathPage.Values[0] := ExpandConstant('{localappdata}\Discord');
end;

function StringReplace(const S, OldPattern, NewPattern: string): string;
var
  SearchStr: string;
  Offset: Integer;
begin
  SearchStr := S;
  Result := '';
  while SearchStr <> '' do
  begin
    Offset := Pos(OldPattern, SearchStr);
    if Offset = 0 then
    begin
      Result := Result + SearchStr;
      Break;
    end;
    Result := Result + Copy(SearchStr, 1, Offset - 1) + NewPattern;
    Delete(SearchStr, 1, Offset + Length(OldPattern) - 1);
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  JSONPath, DiscordPath, JSONContent: string;
  ShellLink, Target, Icon: string;
  ObjShell, ObjLink: Variant;
  LogFile: string;
begin
  if CurStep = ssPostInstall then
  begin
    // Zapis do settings.json
    DiscordPath := DiscordPathPage.Values[0];
    JSONPath := ExpandConstant('{app}\settings.json');

    JSONContent := '{' + #13#10 +
                   '  "discord_installed_path": "' + StringReplace(DiscordPath, '\', '\\') + '"' + #13#10 +
                   '}';

    SaveStringToFile(JSONPath, JSONContent, False);

    // Usuń istniejący updater.log w {app}, jeśli istnieje
    LogFile := ExpandConstant('{app}\updater.log');
    if FileExists(LogFile) then
    begin
      DeleteFile(LogFile);
    end;

    // Utwórz pusty updater.log w {userappdata}\BetterDiscordAutoInstaller
    LogFile := ExpandConstant('{userappdata}\{#MyAppName}\updater.log');
    SaveStringToFile(LogFile, '', False);

    // Tworzenie skrótu na pulpicie (jeśli wybrano task)
    if IsTaskSelected('desktopicon') then
    begin
      ShellLink := ExpandConstant('{userdesktop}\Discord.lnk');
      Target := ExpandConstant('{app}\{#MyAppExeName}');
      Icon := ExpandConstant('{app}\logo_small.ico');

      try
        ObjShell := CreateOleObject('WScript.Shell');
        ObjLink := ObjShell.CreateShortcut(ShellLink);
        ObjLink.TargetPath := Target;
        ObjLink.WorkingDirectory := ExtractFileDir(Target);
        ObjLink.IconLocation := Icon + ',0';
        ObjLink.Save;
      except
        MsgBox('Failed to create desktop shortcut.', mbError, MB_OK);
      end;
    end;
  end;
end;