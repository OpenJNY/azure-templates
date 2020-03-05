# This script takes few seconds (around 10 sec) to run.
$DEPLOY_VM = $false

# Resource Group
# --------------

$rgName = "outbound-rules-with-different-idletimeouts"
$location = "japaneast"
$rg = New-AzResourceGroup -Name $rgName -Location $location

if ($DEPLOY_VM -eq $true) {
    # ref: https://docs.microsoft.com/ja-jp/azure/virtual-machines/scripts/virtual-machines-windows-powershell-sample-create-vm
    # Create VNet
    $subnet = New-AzVirtualNetworkSubnetConfig -Name default -AddressPrefix "192.168.0.0/24"
    $vnet = New-AzVirtualNetwork -Name vnet -ResourceGroupName $rgName -Location $location -AddressPrefix "192.168.0.0/16" -Subnet $subnet

    # Create Virtual Machine
    $username = "contoso"
    $password = "Password!234"
    $secpass = ConvertTo-SecureString –String $password –AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential($username, $secpass)

    $vmName = "winserver"
    $nicName = "${vmName}-nic"
    $nic = New-AzNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $location -SubnetId $vnet.Subnets[0].Id
    $vmconfig = New-AzVMConfig -VMName $vmName -VMSize Standard_B2s | `
        Set-AzVMOperatingSystem -Windows -ComputerName $vmName -Credential $cred | `
        Set-AzVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2016-Datacenter -Version latest | `
        Add-AzVMNetworkInterface -Id $nic.Id
    New-AzVM -ResourceGroupName $rgName -Location $location -VM $vmconfig
}

# Load Balancer
# -------------

# Create a backend pool
$bepoolName = "backend-pool"
$bepool = New-AzLoadBalancerBackendAddressPoolConfig -Name $bepoolName

# Create Public IP addresses
$pipName1 = "lb-pip1"
$pipName2 = "lb-pip2"
$pip1 = New-AzPublicIpAddress -Name $pipName1 -ResourceGroupName $rgName -AllocationMethod Static -Sku Standard -Location $location
$pip2 = New-AzPublicIpAddress -Name $pipName2 -ResourceGroupName $rgName -AllocationMethod Static -Sku Standard -Location $location

# Create frontends corresponding to the PIPs
$frontendName1 = "fe1"
$frontendName2 = "fe2"
$frontend1 = New-AzLoadBalancerFrontendIPConfig -Name $frontendName1 -PublicIpAddress $pip1
$frontend2 = New-AzLoadBalancerFrontendIPConfig -Name $frontendName2 -PublicIpAddress $pip2

# Create outbound rules with different IdleTimeoutInMinues
$outruleName1 = "outrule-1"
$outruleName2 = "outrule-2"
$outrule1 = New-AzLoadBalancerOutBoundRuleConfig -Name $outruleName1 -FrontendIPConfiguration $frontend1 -BackendAddressPool $bepool -Protocol All -IdleTimeoutInMinutes 5 -AllocatedOutboundPort 1024
$outrule2 = New-AzLoadBalancerOutBoundRuleConfig -Name $outruleName2 -FrontendIPConfiguration $frontend2 -BackendAddressPool $bepool -Protocol All -IdleTimeoutInMinutes 15 -AllocatedOutboundPort 1024

# Create SLB
$lbName = "standard-public-lb"
New-AzLoadBalancer -Name $lbName -Sku Standard -ResourceGroupName $rgName -Location $location -FrontendIpConfiguration $frontend1, $frontend2 -BackendAddressPool $bepool -OutboundRule $outrule1, $outrule2

if ($DEPLOY_VM -eq $true) {
    # Place the VM within the back-end pool.
    Set-AzNetworkInterfaceIpconfig -Name ipconfig1 -NetworkInterface $nic -SubnetId $vnet.Subnets[0].Id -LoadBalancerBackendAddressPoolId $bepool.Id
    $nic | Set-AzNetworkInterface
}

# 結果
Write-Output (Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgName | Get-AzLoadBalancerOutboundRuleConfig)

# Remove Resources
# ----------------
# Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgName `
#     | Remove-AzLoadBalancerOutboundRuleConfig -Name $outruleName1 `
#     | Remove-AzLoadBalancerOutboundRuleConfig -Name $outruleName2 `
#     | Remove-AzLoadBalancerFrontendIpConfig -Name $frontendName1 `
#     | Remove-AzLoadBalancerFrontendIpConfig -Name $frontendName2 `
#     | Set-AzLoadBalancer
# 
# Remove-AzPublicIpAddress -Name $pipName1 -ResourceGroupName $RgName -Force -AsJob
# Remove-AzPublicIpAddress -Name $pipName2 -ResourceGroupName $RgName -Force -AsJob

Remove-AzResourceGroup -ResourceGroupName $rgName1