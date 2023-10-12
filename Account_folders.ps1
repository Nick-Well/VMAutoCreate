param (
	[string]$VMNamn,
	[int]$VMNr,
	[string]$PC2Name,
	[string]$debug,
	[string]$AdminNamn,
	[int]$round,
	[bool]$clean
)
#jag vet att allt dehär kan göras mycket finare... but aint no body got time for dat
if($debug -eq "yes"){
	Write-Host "vmname "$VMNamn
	Write-Host "vmnr "$VMNr
	Write-Host "new name on vm1"$PC2Name
	Write-Host "round "$round
	Write-Host "remove files "$clean
}
$NewName = "User1"
$a = $AdminNamn+"A"
$b = $AdminNamn+"B"
$grup = "transport"
$Path = "C:\Temp\"
$ShareName = "SMBshareThis"

$folderNameRead = "R"
$folderNameReadWrite = "RW"

function main {
	if ($clean) {
		CleanUp
	}
	if ($round -eq 0) {
		setupVMs
	}
	Uppgiften
}




function setupVMs(){
	New-LocalGroup -Name $grup
	$PassUserA = ConvertTo-SecureString -String "123"-AsPlainText -Force
	$PassUserB = ConvertTo-SecureString -String "123"-AsPlainText -Force
	New-LocalUser -Name $a -Password $PassUserA
	New-LocalUser -Name $b -Password $PassUserB
	Add-LocalGroupMember -Group $grup -Member $a,$b
	Add-LocalGroupMember -Group "Users" -Member $a,$b
	Add-LocalGroupMember -Group "Remote Desktop Users" -Member $a,$b
	netsh.exe advfirewall firewall set rule group="Network Discovery" new enable=Yes
	netsh.exe advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes
	Enable-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol" -All -NoRestart
}
function CleanupVM {
	Remove-Item -Path $path\* -Recurse -Force
	Remove-Item -Path $path$folderNameReadWrite -Recurse -Force
	Remove-LocalUser -Name $a
	Remove-LocalUser -Name $b
	Remove-LocalGroupMember -Group $grup -Member $a,$b
	Remove-LocalGroupMember -Group "Users" -Member $a,$b
	Remove-LocalGroupMember -Group "Remote Desktop Users" -Member $a,$b
	Remove-LocalGroup -Name $grup
	Remove-SmbShare -Name $path$folderNameRead
	Remove-SmbShare -Name $path$folderNameReadWrite
	netsh.exe advfirewall firewall set rule group="Network Discovery" new enable=no
	netsh.exe advfirewall firewall set rule group="File and Printer Sharing" new enable=no
	Disable-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol" -All -NoRestart
}
function part1 {
	if($round -eq 0) {
		if($debug -eq "yes"){Write-Host "*Runs part 1"}
		#TODO: more folders and more files
		New-Item -Path $path$folderNameRead -ItemType Directory -ErrorAction Stop
		New-Item -Path "$path$folderNameReadWrite\folder1" -ItemType Directory  -ErrorAction Stop
		New-Item -Path "$path$folderNameReadWrite\folder2a" -ItemType Directory  -ErrorAction Stop
		New-Item -Path "$path$folderNameReadWrite\folder2b" -ItemType Directory  -ErrorAction Stop
		$i = 0
		while($i -le 5){
			New-Item -Path $path$folderNameRead -ItemType File -Name "textfile$i.txt"
			New-Item -Path $path$folderNameReadWrite\folder1 -ItemType File -Name "textfile$i.txt"
			New-Item -Path $path$folderNameReadWrite\folder2a -ItemType File -Name "textfile$i.txt"
			New-Item -Path $path$folderNameReadWrite\folder2b -ItemType File -Name "textfile$i.txt"
			$i++
		}
		if($debug -eq "yes"){Write-Host "*inherit/grant $grup"}
		icacls.exe $path$folderNameRead /inheritancelevel:d
		#icacls.exe $path$folderNameReadWrite /inheritancelevel:d
		icacls.exe $path$folderNameReadWrite /grant $a":F"
		icacls.exe $path$folderNameRead /grant $grup":r"
		icacls.exe $path$folderNameReadWrite /grant $grup":F"
		icacls.exe $path$folderNameReadWrite /grant $a":(r,w)"
		if($debug -eq "yes"){Write-Host "*folder1-2"}
		icacls.exe $path$folderNameReadWrite\folder1 /grant $grup":(r,w)" /inheritancelevel:d
		icacls.exe $path$folderNameReadWrite\folder2a /grant $a":(r,w)" /inheritancelevel:d
		icacls.exe $path$folderNameReadWrite\folder2b /grant $b":(r,w)" /inheritancelevel:d

		icacls.exe "C:\Users\admin\Desktop" /grant $a":F"
	}else{
		if($debug -eq "yes"){Write-Host "*SMBShare $path$folderNameReadWrite"}
		New-SmbShare $ShareName -path $path$folderNameReadWrite -FullAccess $a
		New-SmbShare "DesktopVm1" -Path "C:\Users\admin\Desktop" -FullAccess $a
		if($debug -eq "yes"){Get-SmbShare}
	}

}
function part2 {
	if ($round -eq "0") {
		Rename-Computer -NewName $NewName
		if($debug -eq "yes"){Write-Host "*renamed"}
	}else {
		if($debug -eq "yes"){Write-Host "*Runs part 2"}
		<#
		look i know admin is supost to be adminA och det som behöver göras är att variabeln $a och $b borde skapas i VM_starter
		och skickas hit och i VM-Starter så borde jag bytta inlog på PSseasion till admin vid $runda = 1
		för att den är just nu inlogad som admin och admin finns redan i vm0,1 så kommer deta funka hur som
		#>
		Move-Item -Path "\\User0\$ShareName\*.txt" -Destination "C:\Users\adminA\Desktop\" #from VM1 to local
		Copy-Item -Path "C:\Users\adminA\Desktop\*.txt" -Destination "\\USER0\DesktopVm1\" #from local to VM1
	}

}
function Uppgiften {
	if ($VMNr -eq "0"){
		part1
	}
	else {
		if($debug -eq "yes"){Write-Host "*$NewName"}
		part2
	}
}
main