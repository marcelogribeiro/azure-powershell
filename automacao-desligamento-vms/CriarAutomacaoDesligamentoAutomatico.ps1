##################################################
# Dependencias
##################################################

# Azure Powershell -> https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
# MSOnline -> Install-Module MSOnline
# AzureAD -> Install-Module AzureAD

##################################################
# Variaveis
##################################################

$SubscriptionId = ""

$AutomationUserName = "automacao"
$AutomationUserSenha = “Yywc@291aA” #deve atender a politica de senha

$ResourceGroupName = "automacao"
$AutomationAccountName = "DesligamentoAutomaticoVMs"

$HorarioInicioTrabalho = "08:00:00"
$HorarioFimTrabalho = "17:00:00"

$Location = "eastus2"

##################################################
# Conectando
##################################################

$Account = Login-AzureRmAccount -SubscriptionId $SubscriptionId

##################################################
# Criando o usuário
##################################################

Connect-AzureAD -TenantId $Account.Context.Tenant.Id

$Domain = Get-AzureADDomain

$AutomationUserEmail = "$($AutomationUserName)@$($Domain.Name)"

$PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
$PasswordProfile.Password = $AutomationUserSenha
$PasswordProfile.EnforceChangePasswordPolicy = $false
$PasswordProfile.ForceChangePasswordNextLogin = $false

$AutomationUser = New-AzureADUser -DisplayName $AutomationUserName -PasswordProfile $PasswordProfile -UserPrincipalName $AutomationUserEmail -AccountEnabled $true -MailNickName $AutomationUserName

#Aplicando perfil de acesso

$RoleId = Get-AzureADDirectoryRole | where { $_.DisplayName -ieq "Cloud Application Administrator" }[0]

if($RoleId -eq $null){
    $RoleTemplateId = Get-AzureADDirectoryRoleTemplate | where { $_.DisplayName -ieq "Cloud Application Administrator" }[0]
    $RoleId = Enable-AzureADDirectoryRole -RoleTemplateId $RoleTemplateId.ObjectId
}

Add-AzureADDirectoryRoleMember -ObjectId $RoleId.ObjectId -RefObjectId $AutomationUser.ObjectId

#Access control (IAM)
New-AzureRmRoleAssignment -SignInName $AutomationUserEmail -RoleDefinitionName Owner

##################################################
# Criando o grupo de recurso
##################################################

if((Get-AzureRmResourceGroup | ?{$_.ResourceGroupName -ieq $ResourceGroupName }).Count -eq 0){
    New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location
}

##################################################
# Criando a automação
##################################################

$AutomationAccount = New-AzureRmAutomationAccount -Name $AutomationAccountName -ResourceGroupName $ResourceGroupName -Location $Location

#Credencial

$CredencialPassword = ConvertTo-SecureString $AutomationUserSenha -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $AutomationUserEmail, $CredencialPassword

New-AzureRmAutomationCredential -AutomationAccountName $AutomationAccountName -Name "AutomacaoCredential" -Value $Credential -ResourceGroupName $ResourceGroupName

#Scripts
$CurrentPath = (Get-Item -Path ".\" -Verbose).FullName

Import-AzureRmAutomationRunbook -AutomationAccountName $AutomationAccountName -Name "DesligarVMs" -Path (Join-Path $CurrentPath "DesligarVMs.ps1") -ResourceGroupName $ResourceGroupName -Type PowerShellWorkflow -Published
Import-AzureRmAutomationRunbook -AutomationAccountName $AutomationAccountName -Name "LigarVMs" -Path (Join-Path $CurrentPath "LigarVMs.ps1") -ResourceGroupName $ResourceGroupName -Type PowerShellWorkflow -Published


##################################################
# Criando agendamentos
##################################################
$ExecutionTime = (Get-Date $HorarioInicioTrabalho).AddDays(1)
New-AzureRmAutomationSchedule -AutomationAccountName $AutomationAccountName -Name "InicioHorarioTrabalho" -StartTime $ExecutionTime -ResourceGroupName $ResourceGroupName -DayInterval $true -TimeZone 'America/Sao_Paulo'
$ExecutionTime = (Get-Date $HorarioFimTrabalho).AddDays(1)
New-AzureRmAutomationSchedule -AutomationAccountName $AutomationAccountName -Name "FimHorarioTrabalho" -StartTime $ExecutionTime -ResourceGroupName $ResourceGroupName -DayInterval $true -TimeZone 'America/Sao_Paulo'

Register-AzureRmAutomationScheduledRunbook -AutomationAccountName $AutomationAccountName -Name "LigarVMs" -ScheduleName "InicioHorarioTrabalho" -ResourceGroupName $ResourceGroupName
Register-AzureRmAutomationScheduledRunbook -AutomationAccountName $AutomationAccountName -Name "DesligarVMs" -ScheduleName "FimHorarioTrabalho" -ResourceGroupName $ResourceGroupName

