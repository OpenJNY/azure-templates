$rgName = Read-Host -Prompt "Name of Resource Group name"
$lbName = Read-Host -Prompt "Name of Load Balancer"
$frontendName = Read-Host -Prompt "Name of frontend"

$slb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgName
$frontend = $slb | Get-AzLoadBalancerFrontendIpConfig -Name $frontendName
if ($frontend.PublicIpAddress) {
    $pipRg = $frontend.PublicIpAddress.Id.Split('/')[4] 
    $pipName = $frontend.PublicIpAddress.Id.Split('/')[-1] 
}

# Remove frontend
Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgName | `
    Remove-AzLoadBalancerFrontendIpConfig -Name $frontendName | `
    Set-AzLoadBalancer

# Remove PIP
Remove-AzPublicIpAddress -Name $pipName -ResourceGroupName $pipRg # -Force -AsJob