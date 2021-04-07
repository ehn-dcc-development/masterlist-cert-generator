Simple eMRTD PKI
================

The present script and configuration files will generate a simple PKI conforming to the ICAO Document 9303 
part 12 specifications regarding PKI objects.

The following PKI objects will be generated:
- Country Signing Certificate Authority self-signed certificate (CSCA)
- Document Signer Certificate (DSC)
- Master List SIgner Certificate (MLSC)
- Barcode Signer Certificate (BSC)
- Certificate Revocation List

The script uses RSA and RSA with SHA256 for CSCA, DSC and MLSC and EC with SHA256
for BSC.

The full list of signing algorithms for PKI objects is specified in ICAO Document 9303 Part 12.
Key types and related signing algorithms can be changed in this script by changing
appropriately the openssl configuration files and command execution parameters.

The PKI objects generated with the simple Create_eMRTD_PKI.sh script provided here
have been tested for conformity with the ICAO 9303 Document Part 12 specifications 
using a test suite according according to the specifications in "ICAO TECHNICAL REPORT Radio Frequency Protocol
and Application Test Standard for eMRTD – Part 5 Tests for PKI Objects".

Changing the configuration files in the /etc folder, other than for the parameters 
described below, might result in the generation of certificates which are no 
longer compliant with the specifications.

Getting Started
===============
Save the /etc folder and the Create_eMRTD_PKI.sh script in the same directory.
Execute the script.
You will be prompted for confirmation in some steps and to introduce DN values for
DSC, MLSC and BSC. openssl is configured to check that the Country of the signing
CSCA and the values introduced for the "Country" field in the generation of the 
certificate request match. If they don't match, the certificate will not be generated.

The execution of the script will create the following directories:
- certs: where certificates and certificate signing requests are stored
- csca:  where the csca databases and private keys are stored
- crl:   where the crls will be stored

The /etc folder contains the configuration files for the four different types of
certificates generated.

Edit the csca.conf file to change the CSCA DN values or the duration of validity
for all types of certificates.

Edit the Create_eMRTD_PKI.sh script to set the starting value for the validity
of the private key to the current date (**PRIV_KEY_START**).

Prerequisites
=============
Openssl

Installing
==========
No installation is required

Usage
=====
sh ./Create_eMRTD_PKI.sh

