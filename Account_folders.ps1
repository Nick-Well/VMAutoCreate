param (
	[string]$VMNamn,
	[int]$VMNr,
	[string]$VM2Name,
	[string]$debug,
	[string]$AdminNamn
)
#jag vet att allt dehär kan göras mycket finare... but aint no body got time for dat

$vm2 = "User1"
$a = $AdminNamn+"A"
$b = $AdminNamn+"B"
$grup = "transport"
$Path = "C:\Temp\"
$ShareName = "SMBshareThis"

$folderNameRead = "R"
$folderNameReadWrite = "RW"
function CreatAccounts(){
	try {
		New-LocalGroup -Name $grup
		$PassUserA = ConvertTo-SecureString -String "123"-AsPlainText -Force
		$PassUserB = ConvertTo-SecureString -String "123"-AsPlainText -Force
		New-LocalUser -Name $a -Password $PassUserA
		New-LocalUser -Name $b -Password $PassUserB
		Add-LocalGroupMember -Group $grup -Member $a,$b
		Add-LocalGroupMember -Group "Users" -Member $a,$b
		Add-LocalGroupMember -Group "Remote Desktop Users" -Member $a,$b
	}
	catch {
		if($debug -eq "yes"){Write-Host "a lot of errors"}
	}
	#Add-LocalGroupMember -Group "Administrator" -Member $AdminNamn"0"
	<#if ($VMNr -eq 0) {

	}
	else {

		Add-LocalGroupMember -Group "Administrator" -Member $AdminNamn+"0"
	}#>
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
	try {
		New-Item -Path $path$folderNameRead -ItemType Directory -Name "ReadFiles" -ErrorAction Stop
		New-Item -Path $path$folderNameReadWrite -ItemType Directory -Name "ReadAndWrite" -ErrorAction Stop
	}
	catch {
		if($debug -eq "yes"){Write-Host "*file exsist"}
	}
		#Set-Acl verkar vara 10 gånger krongligare än vad icacls är

	icacls.exe $path$folderNameRead /grant $grup":r" /q
	icacls.exe $path$folderNameReadwr /grant $grup":(r,w)" /q

	try {
		New-SmbShare $ShareName -path $path$folderNameRead -ReadAccess $a -ErrorAction Stop
		New-SmbShare $ShareName -path $path$folderNameReadWrite -ReadAccess $b -ChangeAccess $b -ErrorAction Stop
	}
	catch {
		if($debug -eq "yes"){Write-Host "*file exsist"}
	}
}
function part2 {

}
function Uppgiften {
	netsh.exe advfirewall firewall set rule group="Network Discovery" new enable=Yes
	netsh.exe advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes
	Enable-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol" -All -NoRestart

	if ($VMNr -eq "0"){
		part1
	}
	else {
		if($debug -eq "yes"){Write-Host "*$vm2"}
		if($VM2Name -eq $vm2){
			part2
		}
		else {
			Rename-Computer -NewName $vm2
			if($debug -eq "yes"){Write-Host "*renamed"}
		}

	}
}

#CleanUp
CreatAccounts
Uppgiften

