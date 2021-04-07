#!/bin/sh
################################################################################
################################################################################
#
# Create_ICAO_PKI.sh : create a PKI with CSCA, DS, MLS and DS certificates 
# conforming to ICAO 9303 Part12 specifications
# CSCA: Country Signing Certificate Authority
#       the root of the PKI hierarchy and trust anchor for document signature 
#       validation
# DS:   Document Signer, entity signing the  Document Security Object in an 
#       eMRTD.
#       the DS certificate (DSC) is signed by the CSCA
# MLS:  Master List SIgner, entity signing the master list issued by a country, 
#       the MLS certificate (MLSC) is signed by the CSCA
# BS:   Barcode Signer, entity signing the 2D barcode (visible digital seal), 
#       the BS certificate (BSC) is signed by the CSCA.
#       The BSC has a restriction on the DN which must contain only country (C)
#       and commonName (CN). Moreover, the commonName must be a two-letter UTF8 
#       string for all certificates, country is a printablestring two-letter 
#       code according to ISO 3166
#   
#       Release date: 1-4-2021
#       Author: Antonia Rana
#
################################################################################
################################################################################


#create directory structure
echo "Create the directory structure"
echo 
mkdir ./certs
mkdir ./crl
mkdir ./csca
mkdir ./csca/db
mkdir ./csca/private
echo "Done creating ./certs, ./crl, ./csca, ./csca/db, ./csca/private"
echo 

#initialise databases and values
echo "Initialise CSCA databases and values"
echo 
cp /dev/null ./csca/db/csca.db
cp /dev/null ./csca/db/csca.db.attr
echo $(date +%s) > ./csca/db/csca.crt.srl
echo 01 > ./csca/db/csca.crl.srl
echo "Done"
echo 

#set start and end of validity
#genealisedTime, format:yyyymmddhhMMssZ
#
#PRIV_KEY_START:    start of validity for private keys
#CA_PRIV_KEY_END:   end of validity for CSCA private key
#DS_PRIV_KEY_END:   end of validity for DS private key
#MLS_PRIV_KEY_END:  end of validity for MLS private key
#
#must be encoded in the respective certificates
#
 
export PRIV_KEY_START=20210401000000Z
export CA_PRIV_KEY_END=20230401000000Z
export DS_PRIV_KEY_END=20210701000000Z
export MLS_PRIV_KEY_END=20210701000000Z

################################################################################
################################################################################
# CSCA 
################################################################################
################################################################################

echo "-------------------------------------------------------------------------"
echo "Creating CSCA key pair"
echo "-------------------------------------------------------------------------"
echo 
openssl req -new -config ./etc/csca.conf -out ./certs/csca.csr -keyout ./csca/private/csca.key && echo "Done creating CSCA key pair" || echo "Failed creating CSCA key pair"
echo 

echo "Creating CSCA self-signed certificate"
echo 
openssl ca -selfsign -config ./etc/csca.conf -in ./certs/csca.csr -out ./certs/csca.crt -extensions csca_ext && echo "Done creating CSCA self-signed certificate" || echo "Failed creating CSCA self-signed certificate"
echo 

################################################################################
################################################################################
# DS 
################################################################################
################################################################################

echo "-------------------------------------------------------------------------"
echo "Creating DS key pair"
echo "-------------------------------------------------------------------------"
echo 
openssl req -new -config ./etc/d_signer.conf -out ./certs/DSC.csr -keyout ./csca/private/DSC.key && echo "Done creating DS key pair" || echo "Failed creating DS key pair"
echo 

echo "Signing DS certificate"
echo 
openssl ca -config ./etc/csca.conf -in ./certs/DSC.csr -out ./certs/DSC.crt -extensions document_signer_ext -days 1830 && echo "Done creating DS certificate" || echo "Failed creating DS certificate"
echo 

################################################################################
################################################################################
# MLS
################################################################################
################################################################################

echo "-------------------------------------------------------------------------"
echo "Creating MLS key pair"
echo "-------------------------------------------------------------------------"
echo 
openssl req -new -config ./etc/ml_signer.conf -out ./certs/MLSC.csr -keyout ./csca/private/MLSC.key && echo "Done creating MLS key pair" || echo "Failed creating MLS key pair"
echo 

echo "Signing MLS certificate"
echo 
openssl ca -config ./etc/csca.conf -in ./certs/MLSC.csr -out ./certs/MLSC.crt -extensions masterlist_signer_ext -days 1830 && echo "Done creating MLS certificate" || echo "Failed creating MLS certificate"
echo 

################################################################################
################################################################################
# BS
################################################################################
################################################################################
  
echo "-------------------------------------------------------------------------"
echo "Creating BS key pair"
echo "-------------------------------------------------------------------------"
echo 
openssl ecparam -name prime256v1 -genkey -noout -out ./csca/private/BSC.key
echo "Creating BS key pair"
echo 

echo "Exporting BS public key"
echo 
openssl ec -in ./csca/private/BSC.key -pubout -out ./certs/BSC-pub.pem
echo "Done exporting BS public key"
echo 

echo "Creating BS certificate request"
echo "Enter a two-letter string for Country and a two-letter string for commonName"
echo 
openssl req -config ./etc/barcode_signer.conf -new -key ./csca/private/BSC.key -out ./certs/BSC.csr && echo "Done creating BS certificate request" || echo "Failed creating BS certificate request" 
echo 

echo "Signing BS certificate"
echo 
openssl ca -config ./etc/csca.conf -in ./certs/BSC.csr -out ./certs/BSC.crt -days 1095 && echo "Done signing BS certificate request" || echo "Failed signing BS certificate" 
echo

################################################################################
################################################################################
# CRL
################################################################################
################################################################################

echo "-------------------------------------------------------------------------"
echo "Creating CRL"
echo "-------------------------------------------------------------------------"
echo 
openssl ca -config ./etc/csca.conf -gencrl -keyfile ./csca/private/csca.key -cert ./certs/csca.crt -out ./crl/crl.crl




