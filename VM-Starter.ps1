#jag vet att det finns procceses och att man kan dela up uppgifter så att saker går fortare.... im a noob and lazy i can wait
#implementeringen skulle vara vid main
$VMName = "vm"

$Path = "C:/Users/$env:username/VM/"

#CreatVM variabler
$ISO = "$Path/Disk/Windows.iso"
$MemoryStartup = 3GB
$NewVHDSize = 30GB
$Gen = 2
$Network = "LOCAL"#kanske skulle ha fixat egen Network men det är inte uppgiften:)

<#
$VHD = "$Path/Drive/$VMName.vhdx"
$VMPath = "$Path$VMName"
#>

#loginuser har en variabel som inte ska finnas men då jag skapat ison med User1
$AdminNamn = "admin"#konvertera desa två till en fil med ett hashad lösenord... but in not here for best practesis
$AdminPw = "123"

$Skript = "Account_folders.ps1"

#Gör dena varibalen om jag nongång i framtiden känner för att använda 🤢 windows. för att skapa flera vms än 2.
$NrOfVms = 2

#ignor this this is shit programers like like and list starts with 0 and not 1
$NrOfVms = $NrOfVms - 1
<#
"yes" för att skipa att få frågan om att trycka enter och popup för att trycka i vmet
och även stänga av raderingen av VM:et och skapandet
#>
$skip = "yes"
#"yes" stänger av clear-host och lite andra commentar och sätter på ett par andra kommentar för mer debug
$debug = "no"

function main {
	#jag har alltid använt "i" som en loop varibel. men varför... varför använs i sen j, i loops?
	$i = 0
	while ($i -le $NrOfVms){
		if ($skip -ne "yes") {
			CleanUp($i)
			CreatVM($i)
		}
		StopVM($i)
		if(StartVM($i)){
			if($debug -eq "yes"){Write-Host "its running the vm setup for $name$i"}
			SendFile($i)
			Start-Sleep -Seconds 5
			RestartVM($i)

		}
		#test($i)
		if($debug -eq "yes"){Write-Host "done with $VMName$i"}
		$i++
	}
	if($debug -eq "yes"){Write-Host "everything is done"}

}
function UserLogin ($PCNr) {
	$Pass = ConvertTo-SecureString -String $AdminPw -AsPlainText -Force
	$Creds = New-Object System.Management.Automation.PSCredential("$AdminNamn$PCNr", $Pass)
return $Creds
}
function CheckVMStatus() {
	if ($null -eq (Get-VM)){
		Write-Output "theres no VM on the system"
		return $false
	}
	else{
		Write-Output "theres vm's on the system"
		return $true

	}
}
function CleanUp ($VMNr) {
	#Tänkte egentligen att använda += men verka inte funka så som jag tänkte
	$VMName = $VMName + $VMNr
	$VHD = "$Path/Drive/$VMName.vhdx"
	if((CheckVMStatus)){
		try {
			Stop-VM -Name $VMName -Force -ErrorAction Ignore
			Remove-VM -Name $VMName -Force -ErrorAction Ignore
		}
		catch {
			Write-Host "VM already stoped or doesnt exist"
			Write-Host "no cleaning needed for $VMName"
		}
	}
	try {
		Remove-Item -Path "$Path$VMName","$VHD" -Exclude *.iso -Recurse -ErrorAction Ignore
	}
	catch {
		Write-Host "Nothing to clean in $Path$VMName, $VHD"
	}
}
function CreatVM ($VMNr) {
	$VMName = $VMName + $VMNr
	$VHD = "$Path/Drive/$VMName.vhdx"
	$VMPath = "$Path$VMName"

	New-VM -Name $VMName -MemoryStartupBytes $MemoryStartup -Path $VMPath -newVHDPath $VHD -NewVHDSizeBytes $NewVHDSize -Generation $Gen -SwitchName $Network

	if($true -eq (CheckVMStatus)){
		Add-VMDvdDrive -VMName $VMName -Path $ISO

		$vmDrive = Get-VMDvdDrive -VMName $VMName
		#hadde problem med att iso:n inte ville boota i gen 1 så gjorde den typ compatible med både...
		try {
			Set-VMFirmware $VMName -BootOrder $vmDrive -EnableSecureBoot Off
		}
		catch {
			try {
				Set-VMBios "$VMName" -StartupOrder CD -ErrorAction Stop
			}
			catch {
				Write-Host "it complains about VMBios and VMFirmware for $VMName"
			}
		}
	}
}
function StartVM ($VMNr) {
	$folder = $false
	$procesBool = $false
	$VMName = $VMName + $VMNr
	[int]$randomloopshit = 0
	Start-VM $VMName

	if($skip -eq "yes"){
		$ans = ""
	}
	else {
		vmconnect.exe $env:computername "$VMName"
		<#
		skit samma här borde man egentligen vara någon slaggs "sendkeys"
		men då jag inte vill ladda ner onödig skit så får de la nöja dig med en pop up:D
		#>

		#Stealing this from a clssmate
		Write-Host "press ENTER if you have passd the CD DVD sheats"
		$ans = Read-Host
	}
	#3 steps... i know its bad but its not and if if if statment :D
	if ($ans -eq "") {
		if($debug -ne "yes"){
			Clear-Host
		}
		else{
			Write-host "starting the invoke tests"
		}
		if($skip -ne "yes"){
			TASKKILL /IM vmconnect.exe /F
		}
		while($true){
		#finns säkert finare sätt att lösa deta... dvs att kolla om allt är laddat
			Start-Sleep -Seconds 1
			$dot = "." * ([int]$randomloopshit)
			try {
				$folder = Invoke-Command -VMName $VMName -Credential (UserLogin) -ScriptBlock{
					Test-Path -Path "C:\"
				} -ErrorAction Stop
				if ($folder) {
					$proces = Invoke-Command -VMName $VMName -Credential (UserLogin) -ScriptBlock{
						(Get-Service -Name vmicheartbeat).Status
					}-ErrorAction Stop
					#jag sat uppe till klockan 2:40 för att $proces är inte en "Running" String. love this....
					if(([string]$proces) -eq "Running"){
						$procesBool = $true
					}
				}
				#Vet du vad som skulle vara riktigt roligt. om jag över tänkte dehär 👍
				#För jag debuga de här i typ en timme. så lets not talk about it
			}
			catch {
				if($debug -ne "yes"){
				Clear-Host
				Write-Host "Waiting for windows to complet and login"
				Write-Host "Skript is not frozzen C: $dot"
				}
				else{
					Start-Sleep -Seconds 1
					Write-Host "$dot"
				}
			}
			if($folder -and $procesBool){
				return $true
				break
			}
			$randomloopshit++
			if($randomloopshit -cgt 3){
				$randomloopshit = 0
			}
		}
		if($debug -eq "yes"){Write-Host "Folder is $folder and Process $procesBool"}
	}
	else {
		Write-Host "Skript restarts, Did not press enter"
		main
	}
}
function SendFile ($VMNr, [int]$round) {
	#jag vet deta är inte en bra lösning... men orkar ej
	$VMName = $VMName + $VMNr

	if($debug -eq "yes"){Write-Host "SendFile to $VMName"}
	$HostName = Invoke-Command -VMName $VMName -Credential (UserLogin) -ScriptBlock{$env:COMPUTERNAME}
	Invoke-Command -VMName $VMName -Credential (UserLogin) -FilePath $Skript -ArgumentList $VMName, $VMNr, $HostName, $debug, $AdminNamn
	if($debug -eq "yes"){Write-Host "complet SendFile $VMName"}
}
function StopVM($VMNr) {
	Stop-VM $VMName$VMNr -Force
}
function RestartVM($VMNr) {
	Restart-VM $VMName$VMNr -Force
}
function test ($VMNr) {
	SendFile($VMNr)
}

#test
main