﻿<#
.SYNOPSIS
Remove a Virtual Machine resource with a given deployment name

.DESCRIPTION
Remove a Virtual Machine resource with a given deployment name

.PARAMETER deploymentName
Mandatory. The deployment name to use and find resources to remove

.PARAMETER searchRetryLimit
Optional. The maximum times to retry the search for resources via their removal tag

.PARAMETER searchRetryInterval
Optional. The time to wait in between the search for resources via their remove tags

.EXAMPLE
Remove-VirtualMachine -deploymentname 'keyvault-12345'

Remove a virtual machine with deployment name 'keyvault-12345' from resource group 'validation-rg'
#>
function Remove-VirtualMachine {

    [Cmdletbinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string] $deploymentName,

        [Parameter(Mandatory = $false)]
        [string] $ResourceGroupName = 'validation-rg',

        [Parameter(Mandatory = $false)]
        [int] $searchRetryLimit = 40,

        [Parameter(Mandatory = $false)]
        [int] $searchRetryInterval = 60
    )

    begin {
        Write-Debug ('{0} entered' -f $MyInvocation.MyCommand)

        # Load helper
        . (Join-Path $PSScriptRoot 'Remove-Resource.ps1')
    }

    process {

        # Identify resources
        # ------------------
        $searchRetryCount = 1
        while (-not ($deployments = Get-AzResourceGroupDeploymentOperation -DeploymentName $deploymentName -ResourceGroupName $resourceGroupName -ErrorAction 'SilentlyContinue') -and $searchRetryCount -le $searchRetryLimit) {
            Write-Verbose ('Did not to find VirtualMachine deployment resources by name [{0}] in scope [{1}]. Retrying in [{2}] seconds [{3}/{4}]' -f $deploymentName, $deploymentScope, $searchRetryInterval, $searchRetryCount, $searchRetryLimit) -Verbose
            Start-Sleep $searchRetryInterval
            $searchRetryCount++
        }

        if (-not $deployments) {
            throw "No deployment found for [$deploymentName]"
        }

        $resourcesToRemove = @()
        $unorderedResourceIds = $deployments.TargetResource | Where-Object { $_ -and $_ -notmatch '/deployments/' }

        # We also need to fetch NICs & discs
        $allResources = Get-AzResource -ResourceGroupName $resourceGroupName -Name '*'

        $orderedResourceIds = @(
            # TODO: Add nices & dics
        )
        $resourcesToRemove = $orderedResourceIds | ForEach-Object {
            @{
                resourceId = $_
                name       = $_.Split('/')[-1]
                type       = $_.Split('/')[6..7] -join '/'
            }
        }

        # Remove resources
        # ----------------
        if ($PSCmdlet.ShouldProcess(('[{0}] resources' -f $resourcesToRemove.Count), 'Remove')) {
            Remove-Resource -resourceToRemove $resourcesToRemove -Verbose
        }
    }

    end {
        Write-Debug ('{0} exited' -f $MyInvocation.MyCommand)
    }
}
