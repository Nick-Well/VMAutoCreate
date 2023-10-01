param (
	[Parameter(Mandatory=$false, Position=0)]
	[string]$PathToFile,
	[Parameter(Mandatory=$false, Position=1)]
	[string]$WinISO
)

#jag vet att det finns procceses och att man kan dela up uppgifter så att saker går fortare.... im a noob and lazy i can wait
#implementeringen skulle vara vid main
$VMName = "vm"

$Path = "C:/Users/$env:username/VM/"

#CreatVM variabler
$ISO = "$Path/Disk/Windows.iso"
$MemoryStartup = 3GB
$NewVHDSize = 13GB
$Gen = 2
$Network = "LOCAL"#kanske skulle ha fixat egen Network men det är inte uppgiften:)
if($WinISO -ne ""){$ISO = $WinISO}
if($PathToFile -ne ""){$Path = $PathToFile}
<#
$VHD = "$Path/Drive/$VMName.vhdx"
$VMPath = "$Path$VMName"
#>

#loginuser har en variabel som inte ska finnas men då jag skapat ison med User1
$AdminNamn = "admin"#konvertera desa två till en fil med ett hashad lösenord... but in not here for best practesis
$AdminPw = "123"

$user1 = $AdminNamn+"A"
#$user2 = $AdminNamn+"B"


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
#"yes" stänger av clear-host och lite andra kommentar och sätter på ett par andra kommentar för mer debug
$debug = "yes"

$clean = $false

function main {
	#Clear-Host
	#jag har alltid använt "i" som en loop varibel. men varför... varför använs i sen j, i loops?
	$VMNr = 0
	while ($VMNr -le $NrOfVms){
		$round = 0
		if ($skip -ne "yes") {
			RemoveVM($VMNr)
			CreatVM($VMNr)
		}
		StopVM($VMNr)
		while ($round -le 1) {
			if($round -eq "1" -and $VMNr -eq 1){
				$user = $user1
			}
			else {
				$user = $AdminNamn
			}
			if($round -eq 1 -or $skip -eq "yes"){$skipCD = "yes"}
			if((StartVM -VMNr $VMNr -skip $skipCD -user $user)){
				if($debug -eq "yes"){Write-Host "its running the vm setup $user for $name$VMNr round $round"}
				SendFile -VMNr $VMNr -round $round -user $user
				if($skipCD -ne "yes"){StopVM($VMNr)}#asså dena koden blir spagheti nu i slutet, är för trött
				Start-Sleep -Seconds 5
			}
			$round++
		}
		#StartVM -VMNr $VMNr -skip "yes"
		if($debug -eq "yes"){Write-Host "done with $VMName$VMNr"}
		$skipCD = "no"
		$VMNr++
	}
	#this needs to be in a loop to clean both vm's after that everythin is done
	cleanUpVMs
	if($debug -eq "yes"){Write-Host "everything is done"}
}
function cleanUpVMs {
	$VMNr = 0
	while ($VMNr -le $NrOfVms) {
		if ($skip -ne "yes") {
			Write-Host "Do you want to clean up files on the vm$VMNr yes/NO"
			$vmclean = ((Read-Host).ToLower()).ToCharArray()[0]
		}
		else {
			$vmclean = "n"
		}
		if($vmclean -eq "y"){
			if((StartVM -VMNr $VMNr -skip "yes")){
				if($debug -eq "yes"){Write-Host "cleaning $name$VMNr"}
				$clean = $true
				SendFile -VMNr $VMNr -clear $clean
			}
		}
		$VMNr++
	}
}
function StartVM {
	param (
		[Parameter(Mandatory=$true, Position=0)]
		[int]
		$VMNr,
		[Parameter(Mandatory=$false, Position=1)]
		[string]
		$skip,
		[Parameter(Mandatory=$false, Position=2)]
		[string]
		$user
		)
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
			Write-Host "Waiting for windows to complet and login"
			Write-Host "Skript is not frozzen C: $dot"
		}
		else{
			Write-host "starting the invoke tests $VMNr"
		}
		if($skip -ne "yes"){
			TASKKILL /IM vmconnect.exe /F
		}
		while($true){
		#finns säkert finare sätt att lösa deta... dvs att kolla om allt är laddat
			Start-Sleep -Seconds 1
			$dot = "." * ([int]$randomloopshit)
			try {
				$folder = Invoke-Command -VMName $VMName -Credential (UserLogin($user)) -ScriptBlock{
					Test-Path -Path "C:\"
				} -ErrorAction Stop
				if ($folder) {
					$proces = Invoke-Command -VMName $VMName -Credential (UserLogin($user)) -ScriptBlock{
						(Get-Service -Name vmicheartbeat).Status
					}-ErrorAction Stop
					#jag sat uppe till klockan 2:40 för att $proces är inte en "Running" String. love this....
					if(([string]$proces) -eq "Running"){
						$procesBool = $true
					}
				}
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
			if($debug -eq "yes"){Write-Host "$VMName Folder is $folder and Process $procesBool"}
			if($folder -and $procesBool){
				return $true
				break
			}
			$randomloopshit++
			if($randomloopshit -cgt 3){
				$randomloopshit = 0
			}
		}
	}
	else {
		Write-Host "Skript restarts, Did not press enter"
		main
	}
}
function SendFile {
	#jag vet deta är inte en bra lösning att convertera $vmname varjegång... men orkar ej
	param (
		[Parameter(Mandatory=$true, Position=0)]
		[int]
		$VMNr,
		[Parameter(Mandatory=$false, Position=1)]
		[int]
		$round,
		[Parameter(Mandatory=$false, Position=2)]
		[bool]
		$clear,
		[Parameter(Mandatory=$false, Position=3)]
		[string]
		$user
	)
	$VMName = $VMName + $VMNr
	if($debug -eq "yes"){Write-Host "SendFile to $VMName"}
	$s = New-PSSession -VMName $VMName -Credential (UserLogin($user))
	#nu när jag anävnder $round borde jag ta bort $HostName för den gör det samma i den andra filen vilket även tar bort $vm2 vilket inte är en bra
	$HostName = Invoke-Command -VMName $VMName -Credential (UserLogin($user)) -ScriptBlock{$env:COMPUTERNAME}
	Invoke-Command -VMName $VMName -Credential (UserLogin($user)) -FilePath $Skript -ArgumentList $VMName, $VMNr, $HostName, $debug, $AdminNamn, $round, $clean
	if($VMNr -eq 0 -and $round -eq 0){
		Copy-Item -ToSession $s -Path .\Send.txt -Destination "C:\Temp\RW\"
	}
}
function UserLogin($user) {
	$Pass = ConvertTo-SecureString -String $AdminPw -AsPlainText -Force
	$Creds = New-Object System.Management.Automation.PSCredential("$user", $Pass)
return $Creds
}
function CheckVMStatus {
	if ($null -eq (Get-VM)){
		Write-Output "theres no VM on the system"
		return $false
	}
	else{
		Write-Output "theres vm's on the system"
		return $true

	}
}#DONE
function RemoveVM ($VMNr) {
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
}#DONE
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
}#DONE
function StopVM ($VMNr) {
	Stop-VM $VMName$VMNr -TurnOff -Force
}#DONE
function RestartVM ($VMNr) {
	Restart-VM $VMName$VMNr -Force
}#DONE
function test {
}

#test
main