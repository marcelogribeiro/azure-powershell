workflow LigarVMs
{
    $Cred = Get-AutomationPSCredential -Name 'AutomacaoCredential'
    
    $login = Login-AzureRMAccount -Credential $Cred

    $VMs = Get-AzureRmVM

    foreach($VM in $VMs){
        Write-Output "Ligando maquina virtual: $($VM.Name)"

        $Result = Start-AzureRmVM -Name $VM.Name -ResourceGroupName $VM.ResourceGroupName -ErrorAction Continue
        
        if($Result.IsSuccessStatusCode) {
            Write-Output "Maquina virtual $($VM.Name) ligada com sucesso."
        }
        else {
            Write-Output "ERRO ao ligar maquina virtual $($VM.Name)."
        }
    }    
}