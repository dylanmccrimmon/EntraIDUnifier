function Get-ImmutableID {
    Param( 
        [Parameter(Mandatory,ValueFromPipeline)]
        [System.Guid]$GUID
    )

    Return [system.convert]::ToBase64String(([GUID]($GUID)).tobytearray())
}