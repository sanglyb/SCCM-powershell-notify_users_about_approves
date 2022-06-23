# SCCM-powershell-notify_users_about_approves

Script to notify users about approves or declines of application requests.

When someone approves or declines application requests, an email will be sent to the users, who created the request. Also in case of using old SCCM versions, notifications about new requests can be sent to administrators.

The script must be run on behalf of an account which has appropriate rights to read users, their attributes and approve requests. Users must be synced with System Center. 