<!-- 目标路径: notes/azure/managed-identity-local-setup-windows.md -->

# Local Setup Guide: Running Managed Identity Demo on Windows

## 1. Install Azure CLI

1. Open browser, go to: https://aka.ms/installazurecliwindows
2. Download the `.msi` installer and run it
3. Follow the installation wizard (all defaults are fine)
4. After installation, open **Command Prompt** or **PowerShell** and verify:
   ```bash
   az --version
   ```
   You should see version info printed. If not, restart your terminal and try again.

## 2. Log in to your Azure account

```bash
az login
```

This opens a browser window automatically. Log in with your personal Azure account (the same one you use for portal.azure.com).

After login, the terminal will show a list of your subscriptions. Verify the correct subscription is selected:
```bash
az account show
```

If you have multiple subscriptions and need to switch:
```bash
# Replace <subscription-id> with your actual subscription ID from Azure Portal
az account set --subscription "<subscription-id>"
```

## 3. Grant your account the Service Bus role in Azure Portal

This step tells Azure: "my personal account is allowed to send/receive messages on this Service Bus namespace."

1. Go to portal.azure.com → navigate to your Service Bus Namespace (`ken-learning-sb-std`)
2. Left menu → **Access control (IAM)**
3. Click **"+ Add"** → **"Add role assignment"**
4. Tab **"Role"** → search for **"Azure Service Bus Data Owner"** → select it → click Next
5. Tab **"Members"** → Assign access to: **User, group, or service principal** → click **"+ Select members"**
6. Search for your personal Azure account email → select it → click Select → Review + assign

> Azure Service Bus Data Owner allows both sending and receiving messages.
> This is fine for learning. In production, use more restrictive roles (Data Sender / Data Receiver separately).

## 4. Install the Azure.Identity NuGet package

In your Visual Studio project (`ServiceBusSenderDemo` or `ServiceBusReceiverDemo`), open **Package Manager Console** and run:

```bash
Install-Package Azure.Identity
```

Or right-click the project → **Manage NuGet Packages** → search **Azure.Identity** → Install.

## 5. Get your fully qualified namespace hostname

1. Azure Portal → `ken-learning-sb-std` → **Overview**
2. Find the **"Host name"** field
3. It looks like: `ken-learning-sb-std.servicebus.windows.net`
4. Copy this value — you will use it in the code instead of a connection string

## 6. Run the Managed Identity Sender demo

Use the code from `src/azure/ServiceBusManagedIdentitySenderDemo.cs`.

Replace the placeholder:
```csharp
// Replace this placeholder with your actual hostname from Step 5
string fullyQualifiedNamespace = "ken-learning-sb-std.servicebus.windows.net";
```

Run the project. Expected output:
```
Message sent via Managed Identity: Order #2001 created - sent via Managed Identity
```

## 7. Run the Managed Identity Receiver demo

Use the code from `src/azure/ServiceBusManagedIdentityReceiverDemo.cs`.

Replace the placeholder the same way as Step 6.

Run the project. Expected output:
```
[email-subscription] Message received via Managed Identity: Order #2001 created - sent via Managed Identity
```

## 8. How DefaultAzureCredential works locally

When you run the code on your home PC after `az login`, `DefaultAzureCredential` automatically detects your Azure CLI login and uses it to get a token from Azure AD. No connection string needed.

```
Your code (DefaultAzureCredential)
    ↓ detects az login session
Azure CLI credentials
    ↓ requests token
Azure AD (Entra ID)
    ↓ returns temporary token
Azure Service Bus
    ↓ validates token, grants access
Message sent / received ✅
```

## 9. Common errors and fixes

| Error | Likely cause | Fix |
|---|---|---|
| `CredentialUnavailableException` | Not logged in via Azure CLI | Run `az login` again |
| `UnauthorizedException 401` | Role not assigned yet | Check Step 3, wait 1-2 minutes after assigning role for it to take effect |
| `NamespaceNotFound 404` | Wrong hostname in code | Double check the hostname from Portal Overview page |
| `TransportType error` | Company network blocking port 5671 | Already handled: code uses `AmqpWebSockets` |

## 10. Verify everything is working

Run in this order:
1. Run Sender → should print "Message sent via Managed Identity"
2. Run Receiver (`email-subscription`) → should print "Message received via Managed Identity"
3. Run Sender again → send another message
4. Run Receiver (`inventory-subscription`) → should also receive the same message

This confirms the full Managed Identity + Topic + Subscription flow is working end to end.

---
*Note created: 2026-07-03*
