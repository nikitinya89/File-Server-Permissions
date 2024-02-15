#Путь к родительской папке
$path = "\\FS\Share" 

#Адрес контейнера, где создается новая OU
$path1 = "DC=domain,DC=local" 

###

$folder = [System.IO.Path]::GetFileName($path)

#Заменить пробелы и дефисы на подчеркивание
$folder2 = $folder.replace(" ","_").Replace("-","_")

#Адрес контейнера, где создается группа
$path2 = "OU=FS_$folder2`,$path1"

#UNC путь к папке
<# Изменить #> $share_path = "$path"

<# Изменить #> $name = $folder2
$name_r = "FS_$name`_ReadOnly"
$name_m = "FS_$name`_Modify"
$name_f = "FS_$name`_FullControl"
$name_d = "FS_$name`_DenyAll"
$name_fld = "FS_$name`_Folder"
$name_di = "FS_$name`_Deny_Inherited"
$name_fi = "FS_$name`_FullControl_Inherited"
$name_ri = "FS_$name`_Read_Inherited"
$name_mi = "FS_$name`_Modify_Inherited"

#Создание новой OU
New-ADOrganizationalUnit -Name "FS_$folder2" -Path "$path1"

#Создание групп
New-ADGroup $name_r -path $path2 -Description "$share_path (Read Only)" -GroupScope DomainLocal -PassThru –Verbose
New-ADGroup $name_m -path $path2 -Description "$share_path (Modify)" -GroupScope DomainLocal -PassThru –Verbose
New-ADGroup $name_f -path $path2 -Description "$share_path (Full Control)" -GroupScope DomainLocal -PassThru –Verbose
New-ADGroup $name_d -path $path2 -Description "$share_path (Deny)" -GroupScope DomainLocal -PassThru –Verbose
New-ADGroup $name_fld -path $path2 -Description "$share_path (Read Folder Only)" -GroupScope DomainLocal -PassThru –Verbose
#New-ADGroup $name_di -path $path2 -Description "Deny All Folder with Inheritance $share_path" -GroupScope DomainLocal -PassThru –Verbose
#New-ADGroup $name_fi -path $path2 -Description "Full Control All Folder with Inheritance $share_path" -GroupScope DomainLocal -PassThru –Verbose
#New-ADGroup $name_ri -path $path2 -Description "Read All Folder with Inheritance $share_path" -GroupScope DomainLocal -PassThru –Verbose
#New-ADGroup $name_mi -path $path2 -Description "Modify All Folder with Inheritance $share_path" -GroupScope DomainLocal -PassThru –Verbose

#Добавление членов групп
<#
Add-ADGroupMember -Identity $name_d -Members $name_di
Add-ADGroupMember -Identity $name_f -Members $name_fi
Add-ADGroupMember -Identity $name_r -Members $name_ri
Add-ADGroupMember -Identity $name_m -Members $name_mi
#>
Add-ADGroupMember -Identity $name_fld -Members $name_r,$name_m,$name_f
Get-ADGroup -SearchBase $path1 -SearchScope OneLevel -Filter {name -like "*folder"} | Add-ADGroupMember -Members $name_fld
<#
Get-ADGroup -SearchBase $path1 -SearchScope OneLevel -Filter {name -like "*Read_Inherited"} | ForEach-Object {Add-ADGroupMember -Identity $name_ri -Members $PSItem}
Get-ADGroup -SearchBase $path1 -SearchScope OneLevel -Filter {name -like "*Modify_Inherited"} | ForEach-Object {Add-ADGroupMember -Identity $name_mi -Members $PSItem}
Get-ADGroup -SearchBase $path1 -SearchScope OneLevel -Filter {name -like "*FullControl_Inherited"} | ForEach-Object {Add-ADGroupMember -Identity $name_fi -Members $PSItem}
Get-ADGroup -SearchBase $path1 -SearchScope OneLevel -Filter {name -like "*Deny_Inherited"} | ForEach-Object {Add-ADGroupMember -Identity $name_di -Members $PSItem} 
#>


#Названия групп для назначения разрешений
$FullControl_Group = $null
$FullControl_Group = $name_f
$ReadOnly_Group = $null
$ReadOnly_Group = $name_r
$Modify_Group = $null
$Modify_Group = $name_m
$DenyAll_Group = $null
$DenyAll_Group = $name_d
$Folder_Group = $null
$Folder_Group = $name_fld

#Создание разрешений
$FullControl = $null
$FullControl = New-Object System.Security.AccessControl.FileSystemAccessRule ($FullControl_Group,"FullControl","ContainerInherit,ObjectInherit","None","Allow")
$ReadOnly= $null
$ReadOnly = New-Object System.Security.AccessControl.FileSystemAccessRule ($ReadOnly_Group,"ReadAndExecute,Synchronize","ContainerInherit,ObjectInherit","None","Allow")
#$Modify_folder = $null
#$Modify_folder = New-Object System.Security.AccessControl.FileSystemAccessRule ($Modify_Group,"Write,ReadAndExecute,Synchronize","Allow")
#$Modify_subfolder = $null
#$Modify_subfolder = New-Object System.Security.AccessControl.FileSystemAccessRule ($Modify_Group,"DeleteSubdirectoriesAndFiles,Modify,Synchronize","ContainerInherit,ObjectInherit","InheritOnly","Allow")
$Modify = $null
$Modify = New-Object System.Security.AccessControl.FileSystemAccessRule ($Modify_Group,"DeleteSubdirectoriesAndFiles, Write, ReadAndExecute, Synchronize","ContainerInherit,ObjectInherit","None","Allow")
$DenyAll = $null
$DenyAll = New-Object System.Security.AccessControl.FileSystemAccessRule ($DenyAll_Group,"FullControl","ContainerInherit,ObjectInherit","None","Deny")
$Folder = $null
$Folder = New-Object System.Security.AccessControl.FileSystemAccessRule ($Folder_Group,"Read,Synchronize","Allow")

#Получение текущих разрешений
$ACL = Get-Acl $share_path

#Добавление новых разрешений
$ACL.AddAccessRule($FullControl)
$ACL.AddAccessRule($ReadOnly)
#$ACL.AddAccessRule($Modify_folder)
#$ACL.AddAccessRule($Modify_subfolder)
$ACL.AddAccessRule($Modify)
$ACL.AddAccessRule($DenyAll)
$ACL.AddAccessRule($Folder)
$ACL | Set-Acl $share_path -Verbose
