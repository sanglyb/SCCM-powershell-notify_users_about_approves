#you should paste here strings from powershell ise started from sccm console.
Import-Module 'C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1' # Import the ConfigurationManager.psd1 module 
Set-Location 'LPK:' # Set the current location to be the site code.
 
function send-message{
    param (
        [PARAMETER(Mandatory=$True,Position=0)][String]$message,
        [PARAMETER(Mandatory=$True,Position=1)][String[]]$email
        )
               
	$MailServer = "mail.yourdomain.com"
	$From = "sccm@yourdomain.com"
	$Subject="����������� � ������� ���������� �� ��������� ����������"
	Send-MailMessage -To $email -From $From -Subject $subject -Body $message -SmtpServer $MailServer -BodyAsHtml -Encoding ([System.Text.Encoding]::UTF8)
}
 
 
$path="C:\some\script\path\"
$lastWriteToCSV=(Get-ChildItem $path\lastvalue.csv).lastwritetime.addhours(-24)
 
$adminEmail=@("admin1@yourdomain.com","admin2@yourdomain.com")
$htmlHead="<html><head><style>
                BODY{font-family: Arial; font-size: 8pt;}
                H1{font-size: 16px;}
                H2{font-size: 14px;}
                H3{font-size: 12px;}
                TABLE{border: 1px solid black; border-collapse: collapse; font-size: 12pt;}
                TH{border: 1px solid black; background: #dddddd; padding: 5px; color: #000000;}
                TD{border: 1px solid black; padding: 5px; }
                </style></head><body>" 
 
$appr=@()
$approves=get-cmapprovalrequest | where-object {$_.lastmodifieddate -gt $lastWriteToCSV} | sort-object lastmodifieddate -desc
if ($approves -ne $null){
	$oldApproves=import-csv "$path\lastvalue.csv"
	if ($oldApproves -ne $null){
		$newApproves=Compare-Object $approves $oldApproves -Property requestguid,currentstate,user,comment,Application -PassThru -erroraction silentlycontinue | Where-Object {$_.sideindicator -eq "<="}
	}
	else {
		$newApproves=$approves
	}
	#$newApproves
	if ($newApproves -ne $null){
	   foreach ($newApprove in $newApproves){
		   $resourceid=(get-cmuser -name $newApprove.user).resourceid
		   $user=get-cmresource $resourceid -fast
		   $message=$null
		   if ($newApprove.currentstate -eq "4"){
			   $message="���������(��) $($user.FullUserName), �� ����������� ����������� �� ��������� ���������� <b>`"$($newApprove.Application)`"</b>. ���������� ���, ��� ��� ������ ��� ���������. <br />��� ��������� ���������� ��������� ����� ������������ ����������� (Software Center), �������� ������������� ����������, � ������� ������ `"����������`""
		   }
		   elseif ($newApprove.currentstate -eq "3"){
			   $message="���������(��) $($user.FullUserName), �� ����������� ����������� �� ��������� ���������� <b>`"$($newApprove.Application)`"</b>. ���������� ���, ��� ��� ������ ��� �������. <br />"
			   if ($newApprove.Comments -ne ""){
				   $message+="����������� ����������� - $($newApprove.Comments) <br />"
			   }
			   $message+="����������� ����� �������� � ����� ��������������� �������������� ������."
		   }
		   elseif ($newApprove.currentstate -eq "1"){
			   $appr+=$newApprove
		   }
		   elseif ($newApprove.currentstate -eq "2"){
			   $messagetoadmin+="$($user.Name) ������� ���� ������ �� ��������� ���������� <b>`"$($newApprove.Application)`"</b>.<br />"
		   }
		  
		   if ($newApprove.currentstate -eq "4" -or $newApprove.currentstate -eq "3"){
			   if ($user.Mail -eq ""){
				   $messagetoadmin += "<br /> �� ������� ��������� ����������� ������������ $($user.name) �� ���������/���������� ������� �� ��������� ���������� <b>`"$($newApprove.Application)`"</b>, �.�. �� ������� ���������� �������� mail � ��������� ������� ������."
			   }
			   else {
				   $email=@($($user.Mail))
				   $message=$htmlHead+$message
				   $email
					send-message $message $email
			   }
			   
		   }
	   }
	   if ($appr -ne ""){
		   $messagetoadmin+="��������� ����� ������� �� ����������� ��������� ����������. ������� ����� � ������� System Center � ���������� �������:<br />"
		   $messagetoadmin+=$appr | select-object application,User,LastModifiedBy,Comments,CurrentState | convertto-html
		   
	   }
	}
	$approves | export-csv $path\lastvalue.csv -notype -encoding UTF8
}
else {
'"SmsProviderObjectPath","Application","CI_UniqueID","Comments","CurrentState","LastModifiedBy","LastModifiedDate","ModelName","RequestGuid","RequestHistory","User","UserSid","PSComputerName","PSShowComputerName"' | out-file $path\lastvalue.csv -encoding UTF8
}

<#$lastWriteToCSV=$lastWriteToCSV.addhours(24)
$oldApproves=get-cmapprovalrequest | where-object {$_.lastmodifieddate -lt $lastWriteToCSV -and $_.CurrentState -eq "1"} | sort-object lastmodifieddate -desc
if ($oldApproves -ne $null){
	$messagetoadmin+="there are requests that need to be approved:<br />"
	$messagetoadmin+=$oldApproves | select-object application,User,LastModifiedBy,Comments,CurrentState | convertto-html 
	
}#>
if ($messagetoadmin -ne "" -and $messagetoadmin -ne $null){
	$messagetoadmin=($htmlHead+"������ ����.<br />"+$messagetoadmin) | out-string
	send-message $messagetoadmin $adminEmail
}

