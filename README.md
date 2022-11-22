# test-aai

Example SATOSA instance

## Prerequisites

You'll need Ubuntu Desktop, Docker CE, certbot, a NAT mapping for ports 80/tcp and 443/tcp, and a hostname in DNS.

## Deployment

1. Get a certificate and make its private key readable by unprivileged users.
   ```bash
   echo -n 'Hostname? '; read HOSTNAME
   echo -n 'Your email? '; read EMAIL
   sudo certbot certonly --standalone \
       --non-interactive \
       --agree-tos \
       -m "${EMAIL}" \
       --keep-until-expiring \
       --renew-with-new-domains \
       --cert-name test-aai \
       -d "${HOSTNAME}"
   sudo chmod a+r /etc/letsencrypt/live/test-aai/privkey.pem
   ```

2. Build the container image from this repo.
   ```bash
   sudo docker rmi test-aai
   sudo docker build -t test-aai .
   ```

3. Enter the hostname and run the image interactively.
   ```bash
   echo -n 'Hostname? '; read HOSTNAME
   sudo docker run \
       -it --rm -p 443:8443 \
       -v /etc/letsencrypt/live/test-aai/fullchain.pem:/etc/https.crt \
       -v /etc/letsencrypt/live/test-aai/privkey.pem:/etc/https.key \
       -e BASE_URL=https://${HOSTNAME} \
       test-aai \
           -b0.0.0.0:8443 \
           --certfile /etc/https.crt \
           --keyfile /etc/https.key \
           satosa.wsgi:app
   ```

## Usage

SATOSA's service provider (SP) metadata is available at `https://$HOSTNAME/sp_metadata`, and its identity provider (IdP) metadata is available at `https://$HOSTNAME/idp_metadata`.  Register both the SP and IdP metadata with [SAMLtest](https://samltest.id/upload.php).  **NOTE:** This must be done whenever the container is restarted unless SAML keying material is kept on persistent storage.

Perform an [IdP test](https://samltest.id/start-idp-test/) by specifying the entity ID of the proxy's front end, `https://$HOSTAME/Saml2IDP/proxy.xml`.  The SAMLtest SP will request authentication by your proxy IdP, causing your proxy SP to request authentication by the SAMLtest IdP.  If everything works right, you will end up back at the SAMLtest SP.  The process looks something like this:

```
SAMLtest SP ----AuthnRequest---> +------------------------|-----------------------+ ----AuthnRequest---> SAMLtest IdP
                                 | SATOSA front end (IdP) |  SATOSA back end (SP) |
SAMLtest SP <---AuthnResponse--- +------------------------|-----------------------+ <---AuthnResponse--- SAMLtest IdP
```
