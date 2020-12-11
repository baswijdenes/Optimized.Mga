function Get-AzureADNestedGroupMembers
{
  [CmdletBinding()]
  param (
    [parameter(Mandatory, Position = 0)]
    $Groups,
    [parameter(Mandatory)]
    [ValidateSet('Users', 'Devices')]
    $ObjectType
  )
  function Get-AzureADNestedGroupMembersInLine
  {
    [CmdletBinding()]
    param (
      [parameter(Mandatory, Position = 0)]
      $Groups,
      [switch]
      $Nested,
      [parameter(Mandatory)]
      $ObjectType
    )
    begin
    {
      try
      {
        if ($Nested -ne $true)
        {
          Write-Verbose 'Get-AzureADNestedGroupMembersInLine: begin: Starting script... Creating UsersList.'
          $script:List = [System.Collections.Generic.List[System.Object]]::new()
        }
      }
      catch
      {
        throw $_.Exception.Message
        exit
      }
    } 
    process 
    {
      try
      {
        foreach ($Group in $Groups)
        {
          Write-Verbose "Get-AzureADNestedGroupMembersInLine: process: Running script for $Group."
          $Grp = Get-AzureADGroup -Filter "DisplayName eq '$Group'" -ErrorAction Stop
          $Members = Get-AzureADGroupMember -ObjectId $Grp.ObjectId -ErrorAction Stop
          foreach ($Member in $Members)
          {
            if ($Member.ObjectType -eq 'User')
            {
              Write-Verbose "Get-AzureADNestedGroupMembersInLine: process: $($Member.DisplayName) is of ObjectType: $($Member.ObjectType)."
              if ($ObjectType -eq 'Users')
              {
                $script:List.Add($member)
              }
            }
            elseif ($Member.ObjectType -eq 'Device')
            {
              Write-Verbose "Get-AzureADNestedGroupMembersInLine: process: $($Member.DisplayName) is of ObjectType: $($Member.ObjectType)."
              if ($ObjectType -eq 'Devices')
              {
                $script:List.Add($member)
              }
            }
            elseif ($Member.ObjectType -eq 'Group' )
            {
              Write-Verbose "Get-AzureADNestedGroupMembersInLine: process: Nested Group found: $($Member.DisplayName)."
              Get-AzureADNestedGroupMembersInLine -Groups $Member.DisplayName -ObjectType $ObjectType -Nested -ErrorAction Stop
            }
            else
            {
              Throw  "Object type is unknown for script. ObjectType = $($Member.Objecttype)."
            }
          }
        }
      }
      catch
      {
        throw $_.Exception.Message
        exit       
      }
    }
    end 
    { 
      Write-Verbose "Get-AzureADNestedGroupMembersInLine: end: Finished Inline script for $Groups."
    }
  }
  Get-AzureADNestedGroupMembersInLine -Groups $Groups -ObjectType $ObjectType -ErrorAction Stop
  Write-Verbose "Get-AzureADNestedGroupMembers: end: Finished search for $ObjectType."
  return  $script:List
}