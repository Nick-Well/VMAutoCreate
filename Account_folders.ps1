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
	Write-Host $VMNamn
	Write-Host $VMNr
	Write-Host $PC2Name
	Write-Host $debug
	Write-Host $round
	Write-Host $clean
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
	Remove-Item -Path $path$folderNameRead -Recurse -Force
	Remove-Item -Path $path$folderNameReadWrite -Recurse -Force
	Remove-LocalUser -Name $a
	Remove-LocalUser -Name $b
	Remove-LocalGroupMember -Group $grup -Member $a,$b
	#Remove-LocalGroupMember -Group "Users" -Member $a,$b
	#Remove-LocalGroupMember -Group "Remote Desktop Users" -Member $a,$b
	Remove-LocalGroup -Name $grup
	Remove-SmbShare -Name $path$folderNameRead
	Remove-SmbShare -Name $path$folderNameReadWrite
	netsh.exe advfirewall firewall set rule group="Network Discovery" new enable=no
	netsh.exe advfirewall firewall set rule group="File and Printer Sharing" new enable=no
	Disable-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol" -All -NoRestart
}
function part1 {
	if($debug -eq "yes"){Write-Host "*Runs part 1"}
	if ($round -eq 0) {
		New-Item -Path $path$folderNameRead -ItemType Directory -Name "ReadFiles" -ErrorAction Stop
		New-Item -Path $path$folderNameReadWrite -ItemType Directory -Name "ReadAndWrite" -ErrorAction Stop

		icacls.exe $path$folderNameRead /grant $grup":r" /q
		icacls.exe $path$folderNameReadwr /grant $grup":(r,w)" /q

		New-SmbShare $ShareName -path $path$folderNameRead -ReadAccess $a -ErrorAction Stop
		New-SmbShare $ShareName -path $path$folderNameReadWrite -ReadAccess $b -ChangeAccess $b -ErrorAction Stop
		New-SmbShare $ShareName -Path C:\Users\admin -FullAccess $a
	}

}
function part2 {
	if($debug -eq "yes"){Write-Host "*Runs part 2"}
	Copy-Item -Path "\\User0\RW\*" -Destination "C:\Users\adminA\Desktop" #from VM1 to local
	Remove-Item "\\User0\RW\*" -Force
	Copy-Item -Path "C:\Users\adminA\Desktop\*.txt" -Destination "\\USER0\Users\admin\Desktop\" #from local to VM1
}
function Uppgiften {
	if ($VMNr -eq "0"){
		part1
	}
	else {
		if($debug -eq "yes"){Write-Host "*$NewName"}
		if($PC2Name -eq $NewName){
			part2
		}
		else {
			Rename-Computer -NewName $NewName
			if($debug -eq "yes"){Write-Host "*renamed"}
		}
	}
}
main