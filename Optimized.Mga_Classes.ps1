<##region enum
enum MethodTypes {
    Get
    Post
    Put
    Delete
    Patch
}
#endregion enum
#region classes
class MgaRunspaces {
    [MethodTypes]$Method
    [string]$URL
    [object]$InputObject
}
#endregion classes
#>