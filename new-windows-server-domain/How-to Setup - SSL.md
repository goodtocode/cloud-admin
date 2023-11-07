**************
 SSL Cert Import
**************
Import-PfxCertificate -FilePath C:\mycert.pfx -Password (ConvertTo-SecureString -String 'mypassword' -AsPlainText -Force) -CertStoreLocation Cert:\CurrentUser\My


IIS:
1. Generate from IIS (ServerName->Server Certificates->Create Certificate Request)
* Common Name - www.domain.com
* Organization - The legally registered name of your organization/company. 
* Organizational unit - IT 
* City, State, Country
* RSA: 8000+
2. Filename: www.domain.com
3. Submit to GoDaddy. Credits->RequestCert->UploadIIS Generated->Pending->Completed->Download
4. Unzip downloaded ZIP
5. IIS -> Server Name -> SErver Certificates -> Complete CRS Request
* Filename = *.crt, *.cer
* Friendly name: www.domain.com
* Select a credential store (Personal or Web Hosting): Personal
6 Now shows up in server certificate list

MMC:
MMC -> Add/Remove Snapin -> Certificates
Personal -> Advanced -> Create Request
1. Proceed without enrollment policy. 
2. (No template) CNG key from the Template list.
 - CNG for All other (including Web Sites)
 - Legacy for Microsoft TMG, RDP, or ADFS on Azure
3. PKCS #10 as the Request format. 
4. Click the Details DOWN ARROW and then the Properties button. - 
5. Enter a name for your certificate in Friendly name box on the General tab.
7. Click the Subject tab.
7a. Under Subject name (* required):
 - CN = www.goodtocode.com (or *.goodtocode.com for wildcard)
 - O = GoodToCode Source
 - OU = IT
 - S = California
 - L = Rancho Santa Margarita
 - C = US
7b. (OPTIONAL: multi-domain) Under Alternative Name
 - DNS: www.SITE.com
 - DNS: cart.SITE.com
 - DNS: cloud.SITE.com
8. Click the Extensions tab.
8a. Key usage: 
 - Data encipherment
 - Digital signature
 - Key encipherment
 - CHECK Make these key usages critical
8b. Extended key usage
 X(?) - Server Authentication
9. Basic constraints: 
 - Click the Enable this extension checkbox.
10. Click the Private key tab.
10a. Under Key options 
 - Select 2048 as the Key size.
 - Click the Make private key exportable checkbox.
10b. Under Select hash algorithm 
 - select sha256 from the Hash Algorithm list.
17. OK - NExt
18 Base 64

**** If doesnt show in IIS, Get SN from Cert and run:  
 - certutil -repairstore my "6331e4b911210144f7ac00d66d9c589a"
 - Comodo: 6331e4b911210144f7ac00d66d9c589a
 - Self-signed: 7f3a0439c991a69b41d69e417567f2a1
 - Get Smart Cart popup
 - Stop SmartCard service

CODE (MMC):
1. Instead of selecting Active Directory Enrollment Policy select Proceed without enrollment policy. 
2. Select (No template) CNG key from the Template list.
3. Select PKCS #10 as the Request format. 
4. Click the Details arrow and then the Properties button. - 
5. Enter a name for your certificate in Friendly name box on the General tab.
6. Click the Subject tab.
7. Under Subject name, 
 - Common name: GoodToCode Source
 - Organizational unit: IT
 - Locality: RSM CA 92688
 - State: CA
 - Country: US
9. Click the Extensions tab.
 - Key usage: Digital signature and click the Add button.
 - Extended key usage: select Code signing and click the Add button.
 - Basic constraints: click the Enable this extension checkbox.
13. Click the Private key tab.
 - Under Key options select 2048 as the Key size.
 - Click the Make private key exportable checkbox.
 - Under Select hash algorithm select sha256 from the Hash Algorithm list.
17. OK
18 Base 64

**************
 SSL Cert
**************
Error: "A specified logon session does not exist. It may already have been terminated. (Exception from HRESULT: 0x80070520)"
1. Generated CSR
2. Imported MMC or Certutil (both same results)
3. Exported to PFX
 - Enter password PASSWORD_HERE
 - Select Export ??? checkbox (it worked before)
4. CERTUTIL -f -p "PASSWORD_HERE" -importpfx "c:\sites\Exported.pfx"
 - Imported WITH private key
5. Works now
#
# Future Reference
#
# Bind 1 - get thumbprint; `
$hostname = "www.goodtocode.com"; `
$iisSite = "www.goodtocode.com"; `
dir cert:\localmachine\my; `
$cert = (Get-ChildItem cert:\LocalMachine\My | where-object { $_.Subject -like "*$hostname*" } | Select-Object -First 1).Thumbprint; `
write-host $cert; `
# Bind 2a - to hostname; `
$guid = [guid]::NewGuid().ToString("B"); `
netsh http add sslcert hostnameport="${hostname}:443" certhash=$cert certstorename=MY appid="$guid";

# OR Bind 2b - to IP; `
New-WebBinding -name $iisSite -Protocol https  -HostHeader $hostname -Port 443 -SslFlags 1;

**************
 Remove
**************
netsh http delete sslcert hostnameport=test.west-wind.com:443

**************
 Tips
**************
certutil -addstore MY c:\sites\146152158repl_1.cer
certutil -verifykeys
certutil -getreg ca\cacerthash
certutil -repairstore my "Your CA Cert hash here from the previous command"
certutil -store My
certutil -repairstore My 2 00daf4c78f32e5f5b3564b0b88944a1f34
certutil -repairstore My 2 51803654f342f78b09964dab5f60c1972736135b




Had same problem, but required a delete of the private key in addition to importing the PFX. 

Environment: IIS on Windows Server 2016 Core
Problem: Private Key was not in correct folder And certutil -repairstore gave Smart Cart popup with "access denied" error

Fix: 
    Generate CSR correctly & get .CER file with the Private Key    (critical step)
    From MMC.exe -> Add/Remove Snapin -> Certificates Right-click Personal -> Import, import the CER file (can also use certutil -addstore MY "filename.cer")
    Note: At this point, it shows in IIS but won't bind due to bad Private Key location
    MMC.exe -> Personal -> Certificate right-click -> Export (select all checkboxes)  
    Note: This step will delete private key  
    MMC.exe -> Personal -> Delete your certificate  
    MMC.exe -> Import (can also use CERTUTIL -f -p "pfx password" -importpfx "filename.pfx")
    Certificate and Private Key are imported properly
    Now you can bind the cert in IIS