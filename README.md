# passkey_app
An implementation of Apple Passkeys with IBM Security Verify as the relying party FIDO service.


## Prerequisites
The rplying party in this sample app is IBM Security Verify (ISV).  Create a free trial tenant here:
https://www.ibm.com/account/reg/us-en/signup?formid=urx-30041.  You'll need to have an IBMid but this can be done at the same time.

This link explains setting up your tenant:
https://docs.verify.ibm.com/verify/docs/signing-up-for-a-free-trial

### Configure FIDO2
1. From the tenant admin portal, click (to expand) **Authentication**
2. Click **FIDO2 settings**
3. Click **Relying Parties +** to open the modal form
4. Enter a **Display name** for the configuration
5. Enter the **Relying party identifier**, for example `mytenant.verify.ibm.com`
6. In **Allowed origins**, enter the URL of your tenant.  For example `https://mytenant.verify.ibm.com`, then click **Add**
7. Click **Save** to close the dialog

> https://docs.verify.ibm.com/verify/docs/fido2

### Create an identity application
The next steps allow your users to authenticate to ISV.  In the passkey_app, resource owner password credential (ROPC) i.e username and password is configured.
1. From the tenant admin portal, click (to expand) **Applications**
2. Click **Applications**
3. Click **Add application** to open the modal form
4. Click **Custom Application**
5. Click **Add application** button
6. Complete the form as required, entering a **Company name**
7. Click **Sign-on** tab
8. Select **Open ID Connect 1.0** as the **Sign-on method**
9. Enter the application URL, this can be your tenant URL. For example `https://mytenant.verify.ibm.com`
10. Select **Resource owner password credentials (ROPC)** as the **Grant type**
11. Click **Save** to add the new application.
12. Once saved, click **All users are entitled to this application**
13. Click on the **Sign-on** tab, and copy the **Client ID**.  You'll need this in the passkey_app.

### Getting your user ID
1. From the tenant admin portal, click (to expand) **Directory**
2. Click **Users & Groups**
3. Hover over the user from the list of users, click the user details card icon
4. Copy the value of **User ID**. You'll need this in the passkey_app.


## Getting started
1. Open Terminal and clone the repository and open the project file in Xcode.
   ```
   git clone git@github.com:craigaps/passkey_app.git
   xed .
   ```

2. In the project **Signing & Capabilities**, update the following settings:
   - Bundle Identifier
   - Provisioning Profile
   - Associated Domains
   
   
   The value of the associated domain will contain the replying party identifier defined in step 5 of the **Configure FIDO2** section above.  For example: `webcredential:mytenant.verify.ibm.com`
   
   Ensure an `apple-app-site-association` (AASA) file is present on your domain in the .well-known directory, and that it contains an entry for this app’s App ID for the webcredentials service.  For example:
     ```
     "webcredentials": {
        "apps": [ "PP64RT7P8Z.com.ibm.test1" ]
    }
    ```
3. Open the **passkey_appApp** file
4. Replace the **clientId** value with the value from the ISV application settings.
5. Replace the host name of **baseUrl** and **replyingParty** values with your tenant.  For example `mytenant.verify.ibm.com`
6. Replace the `userid` value with the value from the getting your user ID section.

## Resources
[Supporting Security Key Authentication Using Physical Keys](https://developer.apple.com/documentation/authenticationservices/public-private_key_authentication/supporting_security_key_authentication_using_physical_keys)

[Public-Private Key Authentication](
https://developer.apple.com/documentation/authenticationservices/public-private_key_authentication)

[W3C Web Authentication](https://www.w3.org/TR/webauthn-2/)