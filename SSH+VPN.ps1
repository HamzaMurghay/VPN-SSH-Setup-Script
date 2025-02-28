Write-Host "This is a script to automatically download SSH and setup a public authentication key for one user to login`n`n"

# $Key_obtain_method = Read-Host "Would you like to obtain the public key file via scp or access it from the local directory? [1/2]"

# If ($Key_obtain_method -eq 1)
# {
# 	$Remote_Host_IP = Read-Host "Enter the IP Address of the remote machine with public key (must be on same local network)"
# 	$Remote_User = Read-Host "Enter username of the remote machine with public key"
# 	$Remote_File_Path = Read-Host "Enter the Absolute file path of the key stored on remote machine"
# 	scp "$Remote_User@Remote_Host_IP:$Remote_File_Path" .
# 	Move-Item .\*.pub C:\ProgramData\ssh
# }
#
# Else 
# {
# 	$Local_File_Path = Read-Host "Enter the Absolute file path of the key stored on local machine"
# 	Move-Item $Local_File_Path C:\ProgramData\ssh
# }	


$user_name = Read-Host "Enter your Windows username"


# --------------- Add SSH login key into record --------------------


cd C:\ProgramData\ssh
type .\*.pub >> administrators_authorized_keys

icacls administrators_authorized_keys /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F"


# --------------- Download PsExec and Move to PATH -----------------


$psexecUrl = "https://download.sysinternals.com/files/PSTools.zip"
$downloadFolder = "C:\Users\$user_name\Downloads"  
$zipFilePath = "$downloadFolder\PSTools.zip"
$extractFolder = "$downloadFolder"  

Write-Host "`nDownloading PsExec..."
Invoke-WebRequest -Uri $psexecUrl -OutFile $zipFilePath


Write-Host "Extracting PsExec..."
Expand-Archive -Path $zipFilePath -DestinationPath $extractFolder

Remove-Item -Path $zipFilePath

Move-Item -Path "C:\Users\$user_name\Downloads\PsExec.exe" -Destination "C:\Windows\System32" -Force


# --------------- Download SSH Server ------------------------------


Write-Host "Installing OpenSSH Server...Please wait, this may take a while..."
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

Write-Host "Starting the OpenSSH Server service..."
Start-Service sshd

Write-Host "Setting OpenSSH Server service to start automatically..."
Set-Service -Name sshd -StartupType 'Automatic'

Write-Host "Configuring the firewall for SSH..."
if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue | Select-Object Name, Enabled)) {
    Write-Output "Firewall Rule 'OpenSSH-Server-In-TCP' does not exist, creating it..."
    New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
} else {
    Write-Output "Firewall rule 'OpenSSH-Server-In-TCP' has been created and exists."
}


# --------------- Download Tailscale and Login ---------------------


# Define the download URL and output file path
$installerUrl = "https://pkgs.tailscale.com/stable/tailscale-setup-latest.exe"
$installerPath = "$env:TEMP\tailscale-setup.exe"

# Download the Tailscale installer
Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath

# Install Tailscale silently
Start-Process -FilePath $installerPath -ArgumentList "/quiet" -Wait

# Set Tailscale service to start automatically
Set-Service -Name "Tailscale" -StartupType Automatic

# Start the Tailscale service
Start-Service -Name "Tailscale"

# Confirm installation
tailscale status

Write-Host "`n`nNow all that's left for you to do is `n1) Login and Authenticate the email for VPN connection `n2) Run psexec and accept terms and conditions"

Start-Sleep -Seconds 5  


# Authenticate
tailscale up

# ------------------------------------------------------------------
