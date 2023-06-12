# OVERVIEW

# This is a simple script to download the following Yubikey utilities:

# - Minidriver - USB driver so device shows up in Windows
# - PIV-tool - "Smart Card" utility to managing certificates
# - CLI Manager - A console based manager for Yubkikey device
# - GUI Manager - A graphical based manager for device
 
# The Minidriver uses Authenticode, but provides the hash of the file
# instead of the Authenticode details.  A "hash" is an algorithm that
# will produce a hex number based on the bytes of a file.  Hashes are
# meant to be impossible to duplicate without the exact same file.  To
# verify the minidriver, we will take the hash and compare it to the
# one provided in the "_.sha256" file.

# The other three files have a GPG signature file along with the download.
# To check the GPG signature, here are the pertinent GPG switches

# * `--homedir` - you can run GPG from a temp directory if it's not fully set up
# * `-k` - key lookup.  Given a key, subkey or UID, this will show the containing key
# * `--recv-key` - download a key from an internet server
# * `--keyserver` - name the server to download keys from 
# * `--list-packets` - displays the key id of the key that made the signature
# * `--verify` - ensure that `sig` file properly signed the file it claims to
# * `--trusted-key` - assume the named key is trusted for easier verification

# For the PIV file that provides a hash, all we do is download the hash,
# calculate the hash then compare the two.  For the GPG signed files the
# process is as follows:

# 1. Build a list of known publisher keys from the Yubikey info site
# 2. Download the file and signature file
# 3. Determine the key that made the signature
# 4. Download and import the signing key into our keyring
# 5. Determine if the signing key is part of a known publisher key
# 6. Determine if the signed file, passes a file verification check
# 7. If check passes, and signing key IS a publisher, than declare GOOD

# Also note that this script uses the SIMPLEST powershell forms.  Modern
# lessons will likely use other forms such as Cmdlet, or Object Oriented,
# while this uses simple structural programming (function based).  Feel
# free to upgrade these to full classes or Cmdlets.  This was simply an
# introduction to the language. 

# Obviously there are much simpler ways to do this, but since an example
# was needed, I went ahead and wrote an overly complicated script

# REFERENCES
# - gnupg.org/documentation/manuals/gnupg/GPG-Configuration-Options.html#index-homedir-1
# - gnupg.org/documentation/manuals/gnupg/Operational-GPG-Commands.html#index-list_002dkeys
# - gnupg.org/documentation/manuals/gnupg/Operational-GPG-Commands.html#index-recv_002dkeys
# - gnupg.org/documentation/manuals/gnupg/GPG-Configuration-Options.html#index-keyserver-1
# - gnupg.org/documentation/manuals/gnupg/Operational-GPG-Commands.html#index-list_002dpackets
# - gnupg.org/documentation/manuals/gnupg/Operational-GPG-Commands.html#index-verify
# - gnupg.org/documentation/manuals/gnupg/GPG-Configuration-Options.html#index-trusted_002dkey

# We are checking our own errors, so will will allow failures to run.
$ErrorActionPreference = "Continue"


# Test to see if the subkey is contained in one of the "blessed" keys from:
#   https://developers.yubico.com/Software_Projects/Software_Signing.html
function test_key($subkey) {
  # Make a list of signing keys from Software_Signing.html
  $publishers = @(
    "0a3b0262bca1705307d5ff06bca00fd4b2168c0a",
    "1d7308b0055f5aef36944a8f27a9c24d9588ea0f",
    "20ee325b86a81bcbd3e56798f04367096fba95e8",
    "268583b64786f50f807456da8ced3a80d41c0dcb",
    "355c8c0186cc96cba49f9cd8daa17c2953914d9d",
    "57a9deed4c6d962a923bb691816f3ed99921835e",
    "78d997d53e9c0a2a205392ed14a19784723c9988",
    "7fbb6186957496d58c751ac20e777dd85755aa4a",
    "9e885c0302f9bb9167529c2d5cba11e6adc7bcd1",
    "af511d2cbc0f973e5d308054325c8e4ae2e6437d",
    "b6042e2bd1fdbc2bca8588b2ff8d3b45b7b875a9",
    "b70d62aa6a31ad6b9e4f9f4bdc8888925d25ca7a",
    "ff8af719ae5828181b894d831ce39268a0973948"
  )
  
  # gpg -k will dump the key containing the subkey
  # findstr /r /c will select the line starting with blanks
  # Trim and lowercase the results to just get the key
  $key = (gpg --homedir quickgpg -k $subkey 2>&1 | findstr /r /c:"^      ").Trim().ToLower()
  
  # If the key containing the subkey is a publisher, GOOD, else BAD
  if ($publishers -contains $key) {
    return $true
  }
  return $false
}


# Get a key from a known keyserver
function get_key($key) {
  # List of keyservers operational in 2023
  $keyservers = @(
    "keyserver.ubuntu.com",
    "keys.openpgp.org",
    "pgp.mit.edu"
  )
  
  # Try to get the key from each server
  foreach ($server in $keyservers) {
    gpg --homedir quickgpg --keyserver $server --recv-key $key 2>&1 | Out-Null
  }
  
  # Return GOOD if our key is a publisher else BAD
  return (test_key $key)
}


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


# Check the signatures of files with GPG signatures
function check_gpg_signed() {
  # List of URLs to GPG signed files
  $gpg_signed = @(
    "https://developers.yubico.com/yubico-piv-tool/Releases/yubico-piv-tool-2.3.1-win64.msi",
    "https://developers.yubico.com/yubikey-manager/Releases/yubikey-manager-5.1.1-win64.msi",
    "https://developers.yubico.com/yubikey-manager-qt/Releases/yubikey-manager-qt-1.2.5-win64.exe"
  )
  
  # Do work on each URL in the list
  foreach ($url in $gpg_signed)
  {
    # Assume we are returning GOOD
    $ret = $true
    
    # Get file and message our work
    $file = (get_file "${url}")
    Write-Host "  File: $file"
    
    # Get sig and message our work
    $sig = (get_file "${url}.sig")
    Write-Host "  Sig: $sig"
    
    # If either failed, return BAD
    if ($file -eq $false -or $sig -eq $false) {
      Write-Host "FAILED wget"
      return $false
    }
    
    # gpg.. List the packets in the sig
    # findstr.. select the line with text "fpr"
    # echo split trim.. Select the last word of the line, trimming off params 
    #  Place key in variable, and message our work
    $key = (gpg --list-packets $sig | findstr /i "fpr" | %{echo $_.Split(' ')[-1].Trim(')')})
    Write-Host "  Key: $key"
    
    # If we don't have the key, get the key
    if (!(test_key $key)) {
      $ret = (get_key $key)
    }
    
    # If we couldn't get the key, BAD
    if ($ret -eq $false) {
      Write-Host "FAILED to acquire key: $key"
      return $false
    }
    
    # --homedir does this all in a junk directory we don't care about
    # --trusted-key allows the sig check to work without trusting the key explicitly
    # --verify runs the sig check
    gpg --homedir quickgpg --trusted-key $key --verify $sig $file 2>&1 | Out-Null
    
    # We want the Win32 exit code specifically, not the powershell rc
    if ($LASTEXITCODE -ne 0)
    {    
      # For Win32, rc == 0 is GOOD, rc != 0 is BAD
      Write-Host "FAILED to verify $file"
      return $false
    }

    # Print Authenticode Certificate
    $authcode = (Get-AuthenticodeSignature "$file").SignerCertificate.Thumbprint
    Write-Host "  Authenticode: $authcode"
    
    # If things aren't BAD, they are GOOD
    Write-Host "VERIFIED: $file"    
  }
  
  # Bubble up, just in case
  return $ret
}


# Check the hash of files with SHA256 hashes
function check_hashed() {
  # Get the file from the URL and msg our work
  $uri = "https://downloads.yubico.com/support/YubiKey-Minidriver-4.1.1.210-x64.msi"
  $file = (get_file "${uri}")
  Write-Host "  File: $file"

  # Get the hash file from the URL and msg our work
  $hash = (get_file "${uri}_.sha256")
  Write-Host "  Hash: $hash"
  
  # If either failed... BAD
  if ($file -eq $false -or $hash -eq $false) {
    Write-Host "FAILED wget"
    return $false
  }
  
  # Read the data out of the hash file
  $data = (Get-Content -Path $hash)
  
  # Calculate the hash of our download
  $sha256 = (Get-FileHash $file).Hash
  
  # "(?i)" RegEx kung-fu, just means ignore caseon the match
  # Check to see if our calculated hash appears in the "data" from the hash file
  if ($data -match "(?i)$sha256") {
  
    # Print Authenticode Certificate
    $authcode = (Get-AuthenticodeSignature "$file").SignerCertificate.Thumbprint
    Write-Host "  Authenticode: $authcode"
    
    # If our hash is mentioned GOOD
    Write-Host "VERIFIED: $file"
    return $true
  }  
  
  # If things aren't GOOD they are BAD
  return $false
}

# Check the GPG signed files
$ret = check_gpg_signed

# Check the SAH256 hashed files
$ret = check_hashed
