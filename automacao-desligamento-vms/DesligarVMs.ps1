workflow DesligarVMs
{
    $Cred = Get-AutomationPSCredential -Name 'AutomacaoCredential'
    
    $login = Login-AzureRMAccount -Credential $Cred

    $VMs = Get-AzureRmVM

    foreach($VM in $VMs){
        Write-Output "Desligando maquina virtual: $($VM.Name)"

        $Result = Stop-AzureRmVM -Name $VM.Name -ResourceGroupName $VM.ResourceGroupName -Force -ErrorAction Continue
        
        if($Result.IsSuccessStatusCode) {
            Write-Output "Maquina virtual $($VM.Name) desligada com sucesso."
        }
        else {
            Write-Output "ERRO ao desligar maquina virtual $($VM.Name)."
        }
    }    
}