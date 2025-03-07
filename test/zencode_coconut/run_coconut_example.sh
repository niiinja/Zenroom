#!/usr/bin/env zsh

# Comments use names from the Coconut paper: https://arxiv.org/pdf/1802.07344.pdf

echo
echo "=========================================="
echo "= COCONUT INTEGRATION TESTS - CREDENTIALS"
echo "=========================================="
echo

verbose=1

alias zenroom="$1"

scenario="Generate credential issuer keypair"
echo $scenario
cat <<EOF | zenroom -z -d$verbose | tee madhatter.keys
Scenario 'coconut': $scenario
Given that I am known as 'MadHatter'
When I create my new issuer keypair
Then print my data
EOF

# Note for devs: the output is verification cryptographic object (alpha, beta, g2) 
scenario="Publish the credential issuer verification key"
echo $scenario
cat <<EOF | zenroom -z -d$verbose -k madhatter.keys | tee madhatter_verification.keys
Scenario 'coconut': $scenario
Given that I am known as 'MadHatter'
and I have my valid 'ca_verify'
Then print my data
EOF

scenario="Generate credential request keypair"
echo $scenario
cat <<EOF | zenroom -z -d$verbose | tee alice.keys
Scenario 'coconut': $scenario
		 Given that I am known as 'Alice'
		 When I create my new keypair
		 Then print my data
EOF

scenario="Generate credential request keypair"
echo $scenario
cat <<EOF | zenroom -z -d$verbose | tee strawman.keys
Scenario 'coconut': $scenario
		 Given that I am known as 'Strawman'
		 When I create my new keypair
		 Then print my data
EOF

scenario="Generate credential request keypair"
echo $scenario
cat <<EOF | zenroom -z -d$verbose | tee lionheart.keys
Scenario 'coconut': $scenario
		 Given that I am known as 'Lionheart'
		 When I create my new keypair
		 Then print my data
EOF

# from here onwards all credential holders (participants) ask the
# issuer to sign their credential keys and aggregate the signature
# (sigmatilde) into their keyring

scenario="Request a credential blind signature"
echo $scenario
cat <<EOF | zenroom -z -d$verbose -k alice.keys | tee alice_blindsign_request.json
Scenario 'coconut': $scenario
		 Given that I am known as 'Alice'
		 and I have my valid 'credential_keypair'
		 When I generate a credential signature request
		 Then print the 'credential_signature_request'
EOF

scenario="Issuer signs a credential"
echo $scenario
cat <<EOF | zenroom -z -d$verbose -k madhatter.keys -a alice_blindsign_request.json | tee madhatter_signed_credential.json
Scenario 'coconut': $scenario
		 Given that I am known as 'MadHatter'
		 and I have my valid 'ca_keypair'
		 and I have a valid 'credential_signature_request'
		 When I sign the credential
		 Then print my 'credential_signature'
		 and print my 'ca_verify'
EOF

# Dev note: this generates sigma (AggCred(σ1, . . . , σt) → (σ):) 
scenario="Receive the signature and archive the credential"
echo $scenario
cat <<EOF | zenroom -z -d$verbose -k alice.keys -a madhatter_signed_credential.json | tee /tmp/alice.keys
Scenario 'coconut': $scenario
		 Given that I am known as 'Alice'
		 and I have my valid 'credential_keypair'
		 and I have inside 'MadHatter' a valid 'credential_signature'
		 When I aggregate the credential in 'credentials'
		 Then print my 'credential_keypair'
		 and print my 'credentials'
EOF
mv /tmp/alice.keys . # restore to avoid overwrite 

scenario="Request a credential blind signature"
echo $scenario
cat <<EOF | zenroom -z -d$verbose -k strawman.keys | tee strawman_blindsign_request.json
Scenario 'coconut': $scenario
		 Given that I am known as 'Strawman'
		 and I have my valid 'credential_keypair'
		 When I generate a credential signature request
		 Then print the 'credential_signature_request'
EOF

scenario="Issuer signs a credential"
echo $scenario
cat <<EOF | zenroom -z -d$verbose -k madhatter.keys -a strawman_blindsign_request.json | tee madhatter_signed_credential.json
Scenario 'coconut': $scenario
		 Given that I am known as 'MadHatter'
		 and I have my valid 'ca_keypair'
		 and I have a valid 'credential_signature_request'
		 When I sign the credential
		 Then print my 'credential_signature'
		 and print my 'ca_verify'
EOF

# Dev note: this generates sigma (AggCred(σ1, . . . , σt) → (σ):) 
scenario="Receive the signature and archive the credential"
echo $scenario
cat <<EOF | zenroom -z -d$verbose -k strawman.keys -a madhatter_signed_credential.json | tee /tmp/strawman.keys
Scenario 'coconut': $scenario
		 Given that I am known as 'Strawman'
		 and I have my valid 'credential_keypair'
		 and I have inside 'MadHatter' a valid 'credential_signature'
		 When I aggregate the credential in 'credentials'
		 Then print my 'credential_keypair'
		 and print my 'credentials'
EOF
mv /tmp/strawman.keys . # restore to avoid overwrite 

scenario="Request a credential blind signature"
echo $scenario
cat <<EOF | zenroom -z -d$verbose -k lionheart.keys | tee lionheart_blindsign_request.json
Scenario 'coconut': $scenario
		 Given that I am known as 'Lionheart'
		 and I have my valid 'credential_keypair'
		 When I generate a credential signature request
		 Then print the 'credential_signature_request'
EOF

scenario="Issuer signs a credential"
echo $scenario
cat <<EOF | zenroom -z -d$verbose -k madhatter.keys -a lionheart_blindsign_request.json | tee madhatter_signed_credential.json
Scenario 'coconut': $scenario
		 Given that I am known as 'MadHatter'
		 and I have my valid 'ca_keypair'
		 and I have a valid 'credential_signature_request'
		 When I sign the credential
		 Then print my 'credential_signature'
		 and print my 'ca_verify'
EOF

# Dev note: this generates sigma (AggCred(σ1, . . . , σt) → (σ):) 
scenario="Receive the signature and archive the credential"
echo $scenario
cat <<EOF | zenroom -z -d$verbose -k lionheart.keys -a madhatter_signed_credential.json | tee /tmp/lionheart.keys
Scenario 'coconut': $scenario
		 Given that I am known as 'Lionheart'
		 and I have my valid 'credential_keypair'
		 and I have inside 'MadHatter' a valid 'credential_signature'
		 When I aggregate the credential in 'credentials'
		 Then print my 'credential_keypair'
		 and print my 'credentials'
EOF
mv /tmp/lionheart.keys . # restore to avoid overwrite 



# Dev note: this generates theta (❖ ProveCred(vk, m, φ0) → (Θ, φ0):
scenario="Generate a blind proof of the credentials"
echo $scenario
cat <<EOF | zenroom -z -d$verbose -k alice.keys -a madhatter_verification.keys | tee alice_proof.json
Scenario 'coconut': $scenario
		 Given that I am known as 'Alice'
		 and I have my valid 'credential_keypair'
		 and I have my valid 'credentials'
		 and I have inside 'MadHatter' a valid 'ca_verify'
		 When I aggregate verifiers from 'ca_verify'
		 and I generate a credential proof
		 Then print the 'credential_proof'
EOF

# Dev note: this checks if theta contains the statement, and returns a boolean VerifyCred(vk, Θ, φ0) 
scenario="Verify a blind proof of the credentials"
echo $scenario
cat <<EOF | zenroom -z -d$verbose -k alice_proof.json -a madhatter_verification.keys
Scenario 'coconut': $scenario
		 Given I have a valid 'credential_proof'
		 and I have inside 'MadHatter' a valid 'ca_verify'
		 When I aggregate verifiers from 'ca_verify'
		 and I verify the credential proof is correct		 
		 Then print 'result' 'OK'
EOF

