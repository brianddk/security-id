# Gnu Privacy Guard (GPG) / Pretty Good Privacy (PGP)

GPG and PGP both use the same protocol.  Originally PGP set the standard and the software, but it deminished into abandonware about 5 years ago and has been replaced, almost globally, but GPG now.  The overall committee overseeing the standards is [OpenPGP](https://www.openpgp.org/), though most all the software they use is based on [GPG](https://www.gnupg.org/).  The popular Windows installer is called [Gpg4Win](https://www.gpg4win.org/).

## Gpg4Win

In this case, it's likely easier to start at the top, then dig our way down.  Gpg4Win is a pretty comprehensive package that integrates rather nicely into the windows environment.  It offers some pretty clean user interfaces, though some of their terminology is *unique*.  They use the term ***certificate*** where other writeups may use the term ***key***.  So just be prepared to swap those in your head as you read up on it.

Here's the main manual for Gpg4Win.  Thumb through the first 5 chapters.  Read chapter 6, but don't run the installer yet.  Read Section 7.1, but don't make the key/certificate yet.  Also thumb through the GnuPG Handbook, it's much shorter, but has a lot more content.  You can also peak at the "man pages" for a more comprehensive list of options for each command.  I wouldn't study the manpages, just know they are there and where to find them.

* [Gpg4Win Manual version 3.0](
https://files.gpg4win.org/doc/gpg4win-compendium-en.pdf), all GUI (Windows) based commands
* [GnuPG Handbook](https://www.gnupg.org/gph/en/manual.pdf), all shell based commands
* [GnuPG "man pages"](https://www.gnupg.org/documentation/manpage.html)

## Verify Installer

Although the first 5 chapters spoke to the utility of encrypting communication, the more common use is signing communications (Chapter 13).  This becomes useful in the form of an "***integrity check***".  This allows publishers to sign a file when it's published and allows users to verify that what they have is an ***EXACT*** copy of that originally published file.  This is critical because one of the most common attacks for trojans and viruses is to modify install files for popular utilities.

Normally, integrity checks would be done with GPG.  But since you can't verify the GPG installer without GPG, the first verification uses a Windows Authenticode Certificate.  Unlike PGP which uses ***web-of-trust*** (see Ch 5), Authenticode uses the Centralized Certificate Authority (CA) method (see Ch 5).  To simplify the process, Windows automagically trusts Authenticode CAs.

To manually validate the Authenticode certificate:

1. [Download Gpg4win](https://files.gpg4win.org/gpg4win-4.1.0.exe)
2. From Powershell: `Get-AuthenticodeSignature .\gpg4win-4.1.0.exe | % {$_.SignerCertificate} | select *`
3. Compare your results with the [official integrity check page](https://www.gpg4win.org/package-integrity.html)

Which fields match?  Which don't? Jump to exercises below.

## Install Gpg4Win

Now that the installer is verified just follow [chapter 6](https://files.gpg4win.org/doc/gpg4win-compendium-en.pdf).  It should be pretty straight forward, but you may need a reboot.

## Create a Temporary Certificate / Key

Per the [manpage](https://www.gnupg.org/documentation/manuals/gnupg24/gpg.1.html), the `gpg` utility allows you to use a `--homedir` option.  This will allow us to "practice" in a temporary directory until we are happy with the settings and comfortable with the key creation process.  Later we will learn to create our secure key data on a special encrypted storage.  Not strictly required, but it will provide a good introduction to the idea of handling secrets with great care.  Use the `--homedir` option to create a temporary key under the directory name "gpg" in the temp directory.  In powershell the `--homedir` option would look like:

    gpg --homedir "${env:temp}\gpg"
    
This would create a directory calld gpg under the system TEMP directory pointed at by the environment variable "temp".  To follow along with chapter 1 of the [GnuPG Handbook](https://www.gnupg.org/gph/en/manual.pdf), the `--homedir` option can be added to all the commands mentioned.  Such as:

    gpg --homedir "${env:temp}\gpg" --gen-key
    gpg --homedir "${env:temp}\gpg" --gen-revoke
    gpg --homedir "${env:temp}\gpg" --list-keys

# Exercises

1. Record what fields match and don't from the ***Verify Installer*** section.
2. Review [gnupg.ps1](gnupg.ps1) to see the field match done in PowerShell
2. From the [gpg manpage](https://www.gnupg.org/documentation/manuals/gnupg24/gpg.1.html) get all possible options using powershell: `gpg --dump-options | sort`
3. From [manpage](https://www.gnupg.org/documentation/manuals/gnupg24/gpg.1.html), review: `--homedir`, `-k`, `--recv-key`, `--keyserver`, `--list-packets`, `--verify`, `--trusted-key`
4. Use `gpg --homedir "${env:temp}\gpg" --gen-key` to follow along in the first chapter of [GnuPG Handbook](https://www.gnupg.org/gph/en/manual.pdf)
