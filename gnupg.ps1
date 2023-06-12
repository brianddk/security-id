# OVERVIEW

# This is a simple script to download gpg4win v4.1.0 in the most paranoid
# way possible.  Since GPG is a bootstrap program, they don't require GPG
# to verify the download but instead use an X509 Authenticode certificate.
# They then go on to list the key properties of that certificate.  This
# script will:

# 1. download the installer
# 2. copy the Authenticode certificate from the installer
# 3. download the verification page
# 4. compare the certificate properties to the verification page
# 5. match fields sha1_fpr, sha2_fpr, s/n, notBefore, and notAfter

# Also note that this script uses the SIMPLEST powershell forms.  Modern
# lessons will likely use other forms such as Cmdlet, or Object Oriented,
# while this uses simple structural programming (function based).  Feel
# free to upgrade these to full classes or Cmdlets.  This was simply an
# introduction to the language. 

# Obviously there are much simpler ways to do this, but since an example
# was needed, I went ahead and wrote an overly complicated script

# REFERENCES
# - learn.microsoft.com/en-us/windows-hardware/drivers/install/authenticode
# - adamtheautomator.com/how-to-sign-powershell-script
# - github.com/PowerShell/PowerShell/releases/tag/v0.5.0
# - learn.microsoft.com/en-us/previous-versions/powershell/module/microsoft.powershell.security/get-authenticodesignature?view=powershell-5.0
# - learn.microsoft.com/en-us/dotnet/api/system.security.cryptography.x509certificates.x509certificate2?view=net-5.0
# - learn.microsoft.com/en-us/dotnet/api/system.bitconverter?view=net-5.0

# We are checking our own errors, so will will allow failures to run.
$ErrorActionPreference = "Continue"


# Given a URL, download a file
function get_file($url) {
  # grab the last part of the URL as the filename
  $file = $url.Split('/')[-1]
  
  # only get the file if you down have the file
  if (!(Test-Path "$file")) {
    
    # Download the file using "wget"
    wget "$url" -UseBasicParsing -OutFile "$file"
    
    # Return filename if GOOD, else return BAD
    return if($?) then {$file} else {$false}
  }
  
  # Only get here if the file is already downloaded, GOOD
  return $file
}


# Verify as many fields in the Authenticode cert as possible
function verify_authenticode() {

  # The file we are downloading to check and the site with the check bits
  $file_uri = "https://files.gpg4win.org/gpg4win-4.1.0.exe"
  $verify_uri = "https://www.gpg4win.org/package-integrity.html"
  
  # Download the file and msg our work.
  $file = (get_file "${file_uri}")
  if($file) {
    Write-Host "  File: $file"
  }
  else {
    Write-Host "FAILED file wget"
    return $false
  }
  
  # Pull the HTML out of the verification site and msg our work
  $html = (wget "$verify_uri").RawContent
  if (!($?)) {
    Write-Host "FAILED verify wget"
    return $false
  }  

  # Save off the authenticode certificate from our download
  $cert = (Get-AuthenticodeSignature "$file").SignerCertificate
  
  # Save off parameters for GetCertHash
  $sha1 = [Security.Cryptography.HashAlgorithmName]::SHA1
  $sha2 = [Security.Cryptography.HashAlgorithmName]::SHA256

  # Make a list of data from the Cert we are going to try to match
  $props = @(
  
    # GetCertHash - get sha1_fpr as bytes[]
    # BitConverter - convert bytes[] to Hex String
    # Replace - substitute the '-' chars with ':' chars
    ([BitConverter]::ToString(${cert}.GetCertHash($sha1))).Replace('-',':')   # sha1_fpr
    ([BitConverter]::ToString(${cert}.GetCertHash($sha2))).Replace('-',':'),  # sha2_fpr

    # ToUniversalTime - Convert times to UTC (GMT) time
    # ToString - For date objects, you can format your stringify functions
    ${cert}.NotBefore.ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss"),      # notBefore
    ${cert}.NotAfter.ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss"),       # notAfter
    
    # No formatting needed
    ${cert}.SerialNumber                                                      # S/N
  )

  # We need to match once for each of the properties we collected
  $need = $props.Length
  
  # Grab the HTML from our verification site
  $html = (wget "$verify_uri").RawContent
  
  # For each property, ignoring case, see if we match text in the verification site
  # "(?i)" is PowerShell RegEx KungFu for "ignore case"
  # For every match, reduce out need by one
  foreach ($prop in $props) {
    if ($html -match "(?i)$prop") {
      $need = $need - 1
    }
  }

  # If we don't need any more matches, then we've matched them all, Return GOOD
  if ($need -eq 0) {
    Write-Host "VERIFIED $file"
    return $true
  }
  
  # If not GOOD, return BAD
  return $false
}

# Entry Point.  Just call verify_authenticde and we are done
$ret = verify_authenticode
