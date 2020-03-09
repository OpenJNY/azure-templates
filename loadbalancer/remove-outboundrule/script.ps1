$rgName = Read-Host -Prompt "Name of Resource Group name"
$lbName = Read-Host -Prompt "Name of Load Balancer"
$outboundRuleName = Read-Host -Prompt "Name of outbound rule"

Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgName | `
    Remove-AzLoadBalancerOutboundRuleConfig -Name $outboundRuleName | `
    Set-AzLoadBalancer