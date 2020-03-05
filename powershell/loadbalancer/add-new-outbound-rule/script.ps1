# This script takes few seconds (around 10 sec) to run.

# Resource Group
# --------------
$rgName = "append"
$location = "japaneast"
$rg = New-AzResourceGroup -Name $rgName -Location $location

# Load Balancer
# -------------
# Create a backend pool
$bepoolName = "backend-pool"
$bepool = New-AzLoadBalancerBackendAddressPoolConfig -Name $bepoolName

# Create a frontend with a Public IP address
$pipName1 = "lb-pip1"
$pip1 = New-AzPublicIpAddress -Name $pipName1 -ResourceGroupName $rgName -AllocationMethod Static -Sku Standard -Location $location
$frontendName1 = "lb-fe1"
$frontend1 = New-AzLoadBalancerFrontendIPConfig -Name $frontendName1 -PublicIpAddress $pip1

# Create outbound rule with IdleTimeoutInMinutes = 5
$outruleName1 = "outrule-1"
$outrule1 = New-AzLoadBalancerOutBoundRuleConfig -Name $outruleName1 -FrontendIPConfiguration $frontend1 -BackendAddressPool $bepool -Protocol All -IdleTimeoutInMinutes 5 -AllocatedOutboundPort 1024

# Create a SLB
$lbName = "public-slb"
New-AzLoadBalancer -Name $lbName -Sku Standard -ResourceGroupName $rgName -Location $location -FrontendIpConfiguration $frontend1  -BackendAddressPool $bepool -OutboundRule $outrule1

# Add a new frontend
# ------------------
$pipName2 = "lb-pip2"
$frontendName2 = "lb-fe2"
$pip2 = New-AzPublicIpAddress -Name $pipName2 -ResourceGroupName $rgName -AllocationMethod Static -Sku Standard -Location $location

Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgName `
| Add-AzLoadBalancerFrontendIPConfig -Name $frontendName2 -PublicIpAddress $pip2 `
| Set-AzLoadBalancer

# Create an outbound rule with IdleTimeoutInMinutes = 15
# ------------------------------------------------------
$outruleName2 = "outrule-2"

$slb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgName
$frontend2 = $slb | Get-AzLoadBalancerFrontendIpConfig -Name $frontendName2
$slb | Add-AzLoadBalancerOutBoundRuleConfig -Name $outruleName2 -FrontendIPConfiguration $frontend2 -BackendAddressPool $bepool -Protocol All -IdleTimeoutInMinutes 15 -AllocatedOutboundPort 1024
$slb | Set-AzLoadBalancer

# Remove resources
# ----------------
Remove-AzResourceGroup -ResourceGroupName $rgName