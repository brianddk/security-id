# Foundational Basis of Security

At the most basic level, information security is about secret keeping.  You are the secret keeper and the rest of the world are advisaries.  As a tool to analyse the difficulties of secret keeping, consider how the secret travels, and where it resides.  When the secret is stored, we term that ***at rest***, and when the secret is in use, we term that ***in transit***, even if networking is not involved.  Transit could refer to the secret being read off of disk (rest) into memory (transit).

Everything about where the secret is at rest, and all environments that it is transmitted through are potential points of attack by an advisary.   All these points of attack is called the ***attack surface***, and termed ***large*** or ***small*** depending on it's properties.

## Attack Surfaces

In a general sense, the larger and more complex the system the secret passes through, the ***larger*** the attack surface is said to be.  For example, a secret kept in a user desktop operating system is said to have a large attack surfice since the advisary can try to attack the tens of millions of lines of code in an operating system to weaken security and get the secret.  By contrast, a small microcontroller may be considered a much smaller attack surface since the amount of code maintaining the security is much smaller and easier to review and audit for weaknesses.

## In Transit / At Rest

Outside of the size of the attack surface, we also consider how the secret is handled in transit and at rest.  For any secret handling operation, we want the data encrypted.  This argument may sound recursive, since the main use of secrets is encryption, so discussing encryption of an ecryption secret just seems to lead to another secret to keep and secure.  And to a degree, this is true.  But many forms of encryption like SSL (the `https` lock icon) are transient and use throw away secrets that are not kept beyond transmission.  Other forms of encryption, like OS drive encryption usually requires a secret kept in your hardware (TPM) so is not something you need to track.

## Safety in Hardware

Since we don't want to chase our tail with encrypting encryption secrets leading to more secrets.  And we want our secret housed in something with the smallest possible attack surface, hardware based encryption is a good first choice.  Many of these devices are VERY well vetted and offer good platforms for much of our cryptography needs.  These can be used with strong passphrases giving the best mix of methodolgies.  The main hardware I'll be discussing here are [Yubikey](
https://support.yubico.com/hc/en-us/articles/360013714579-YubiKey-NEO
), [Onlykey](
https://onlykey.io/collections/all/products/onlykey-color-secure-password-manager-and-2-factor-token-u2f-yubikey-otp-google-auth-make-password-hacking-obsolete?variant=41694199546042
), [Trezor](
https://trezor.io/trezor-model-one
), [Ledger](
https://shop.ledger.com/products/ledger-nano-s-plus
), [Keepkey](
https://keepkey.myshopify.com/collections/frontpage/products/keepkey-the-simple-bitcoin-hardware-wallet
) and [Jade](
https://store.blockstream.com/product/jade-hardware-wallet/
).  These all offer the ability to unlock a password-database, perform OTP operations, and house GnuPG keys.

## Strong Secrets

Historically, most secrets used passwords.  A simple English word.  Attackers quickly discovered those secrets by methods known as ***brute-force*** attacks.  A brute-force attack is simply trying every English word there is.  For most that consists of the 50,000 words most commonly used.  You could expand that to the 100,000 or so that exist as specialty words for various subjects like law and medicine.   But it was quickly discovered that 150,000 is too small of a herd to hide your secret in.  From there passwords were changed from words to scrambly bits of text like `6&Aj774Wrx2t`.  Although this fixed the brute-force attack, the complex pass-symbols was so difficult to recall that people would write them down.  This lead to social engineering attacks, where attackers would get jobs as janitors or the like to lift passwords from post-it notes on monitors.

Nowdays, most security will use passphrases.  A pass-phrase is a simple collection of english words (usually 6 or so) that would be used instead of a password or pass-symbols.  Passphrases are generally easier to remember and type.  For legacy systems that require letters and symbols, you can just throw tokens in with your passphrase.  For example if I want my passphrase to be `usage jump dial couch adapt local` but my bank has a "mixed-case, with symbols and numbers" rule, I can just append the proverbial joke password `P@55w0rd` to the end.  So now my passphrase is `usage jump dial couch adapt local P@55w0rd`.  The process of memorizing this uses something called memory-pegs

## Memory Pegs

Memory pegs use a system of story telling to remember passphrases.  Our passphrase is `usage jump dial couch adapt local P@55w0rd`.  This story might be something as silly as:

> I was doing my bills this month so I checked my internet ***USAGE***.  It was low so I had to ***JUMP*** with joy.  I was out of soap, so I added some ***DIAL*** soap to my list.  Had to check under the ***COUCH*** for my keys, but was able to ***ADAPT*** my schedule since I was late.  Went to the ***LOCAL*** grocery, then realized I've succsufully remembered my ***P@55w0rd***

I know it seems like a lot of work, but if you put one small story or song to memory you will remember it for years.  Obviously we want to have a backup copy of our passphrase, but we might want to avoid storing it digitally.  Anything digital has an attack surface.  As odd as it sounds, the most critical secrets should be kept in a simple code-book in some special firebox or location easy to remember, but away from prying eyes.

## Diceware

The process of generating a truely random passphrase is non-trivial.  To help in this a set of dice and a wordlist can be used to convert random dice throws to words for a passphrase.  [The EFF site](https://www.eff.org/dice) has a good writeup and suggested wordlist.  I personally prefer the [BIP39 diceware wordlist](
https://github.com/brianddk/reddit/blob/32caef9/python/bip39-diceware.txt
) who's words are choosen to be distinguishable and easy to memorize.  The BIP39 list takes 4 dice and a coin (H/T), and you lookup based on the 4 die and coin.

## Entropy

When an attacker is trying to brute-force a password we have to consider how many attempts they can reasonably perform per second.  Although this varies widely, it is generally accepted that a highly funded attack may be able to achieve 1 trillion attempts per second.  Since there are 31,536,000 seconds per year, that comes out to 31.536 x 10^18 attempts per year.  Since those numbers get rather heady, we generally represnt them in powers of 2 (use Log_base2).  In powers of 2, [31.536 x 10^18](https://www.wolframalpha.com/input?i2d=true&i=Log%5C%2840%292%5C%2844%29+31.536+x+Power%5B10%2C18%5D%5C%2841%29) = 2^64.77,  A shorthand for this is "64.77 bits" of entropy, since each power of 2 can be represented in one binary bit.  So if we want our password to survive a one year attack by a well funded attacker, 64.77 bits of entropy is our goal.

To calculate the entropy of a particular word list you take the number of words in the list as the [base](
https://en.wikipedia.org/wiki/Base_%28exponentiation%29
), and the number of words used in the passphrase as the [exponent](https://en.wikipedia.org/wiki/Exponentiation).  So for our BIP39 word list, there are 2048 words in the list and we pick 6, so the number of guesses = 2048^6.  To express this as "bits of entropy" we take [log_base2(2048^6)](https://www.wolframalpha.com/input?i2d=true&i=Log%5C%2840%292%5C%2844%29+Power%5B2048%2C6%5D%5C%2841%29) = 66.  So 66 bits is more than the goal of 64.77 so this passphrase would be "safe" from most directed attacks.

# Exercises

1. Use one of the EFF's four-dice wordlists to make a 6 word passphrase
2. Calculate the bits of entropy in the generated passphrase
3. Use one of the EFF's five-dice wordlists to make a 6 word passphrase
4. Calculate the bits of entropy in the generated passphrase
5. Use the BIP39 four-word-one-coin wordlist to make a 6 word passphrase





















