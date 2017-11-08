#======================================================================
# Filename: GeraSolution.ps1
# Script for export Solutions from CRM Dynamics 2013
# Vinicius Borges Pinheiro 03/02/2017
#
# Parameters Description
# $JK -> 1: Jenkins | <>1: Comand Prompt
# $OrgORIG : CRM Dynamics URL for use like origin
# $OrgDEST : CRM Dynamics URL for use like destiny
# $Solution :  Array with solutions names for export, in the order they should be imported 
#
#=======================================================================

param([string]$JK,[string]$OrgORIG,[string]$OrgDEST, [string]$SolutionPath, [string]$Solutions);

#Examples:
#$Solutions = "WebResources,OptionSets,Other,Entities,Dashboards,Reports,PluginAssemblies,SdkMessageProcessingSteps,Templates,Workflows,Roles,SiteMap";
#$OrgORIG = "http://10.82.248.10:5555/TBDEV";
#$OrgDEST = "http://10.82.251.62:5555/TBSITHML";

$solutionFilesFolder = $env:REP_PACOTES + $SolutionPath;

if($JK -eq 1){
    $UserCRM = $env:UserCRM;
    $PassCRM = $env:PassCRM;
}else{
    $cred = get-credential
    $UserCRM = $cred.UserName.ToString();
    $PassCRM = $cred.GetNetworkCredential().Password;
}

# CI Toolkit
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$xrmCIToolkit = "$scriptPath\PowerShell\Xrm.Framework.CI.PowerShell.dll"
Write-Output "Importing CIToolkit: $xrmCIToolkit" 
Import-Module $xrmCIToolkit

Remove-Item "$solutionFilesFolder\*" -include *.zip

$logsDirectory = $PSScriptRoot+"\Logs"
$solutionNames = @($Solutions.Split(","))
$numPck = 1;

#$pwd = Read-Host "Enter password for account $user" 
$connectionStringORIG = 'Url=' + $OrgORIG + '; Username='+$UserCRM+'; Password='+$PassCRM;
$connectionStringDEST = 'Url=' + $OrgDEST + '; Username='+$UserCRM+'; Password='+$PassCRM;

Write-Output "Solution Files Folder: $solutionFilesFolder"
Write-output "====================================================="
Write-output "|Solutions a Processar:"
Write-output "====================================================="
foreach($solution in $SolutionNames){

    $SolutionORIG = Get-XrmSolution  -ConnectionString $connectionStringORIG -UniqueSolutionName $solution;
    $SolutionDEST = Get-XrmSolution  -ConnectionString $connectionStringDEST -UniqueSolutionName $solution;

    $msg = "{0:00} solutionFile:  {1} | Origem: {2} | Destino: {3} " -f $numPck ,$solution.ToString() , $SolutionORIG.Version,$SolutionDEST.Version;

    if($SolutionORIG.Version -ne $SolutionDEST.Version){
       
        Write-Host $msg | Format-Table;
        Write-Host "====================================================="
        $managedSolution = Export-XrmSolution -ConnectionString $connectionStringORIG -IncludeVersionInName $true -Managed $true -OutputFolder $solutionFilesFolder -UniqueSolutionName $solution.ToString();
        $new_name = "{0:00}_{1}" -f $numPck,$managedSolution.ToString();
        Rename-Item "$solutionFilesFolder/$managedSolution" $new_name         
     }
	 $numPck++;
}