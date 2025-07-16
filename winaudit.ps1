# WinAudit - Windows Server Audit Tool
# Version 1.0
# Author: System Administrator

# Global configuration
$ErrorActionPreference = "SilentlyContinue"
$OutputPath = "C:\WinAudit\"
$ScriptName = "WinAudit"

# Function to create output directory
function Initialize-AuditEnvironment {
    if (!(Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
}

# Function to display header
function Show-Header {
    Clear-Host
    Write-Host "=======================================" -ForegroundColor Cyan
    Write-Host "      WINAUDIT - SERVER AUDIT v1.0    " -ForegroundColor Yellow
    Write-Host "=======================================" -ForegroundColor Cyan
    Write-Host ""
}

# Function to display main menu
function Show-MainMenu {
    Show-Header
    Write-Host "Select the type of audit to perform:" -ForegroundColor White
    Write-Host ""
    Write-Host "1. ADDS (Active Directory Domain Services)" -ForegroundColor Green
    Write-Host "2. DNS (Domain Name System)" -ForegroundColor Green
    Write-Host "3. RDS (Remote Desktop Services)" -ForegroundColor Green
    Write-Host "4. PKI (Public Key Infrastructure)" -ForegroundColor Green
    Write-Host "5. DHCP (Dynamic Host Configuration Protocol)" -ForegroundColor Green
    Write-Host ""
    Write-Host "6. Complete audit (all services)" -ForegroundColor Yellow
    Write-Host "7. Configuration and settings" -ForegroundColor Magenta
    Write-Host "8. View audit reports" -ForegroundColor Cyan
    Write-Host "0. Exit" -ForegroundColor Red
    Write-Host ""
    Write-Host "=======================================" -ForegroundColor Cyan
}

# Function for ADDS audit
function Start-ADDSAudit {
    Write-Host "Starting ADDS audit..." -ForegroundColor Yellow
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $outputFile = "$OutputPath\ADDS_Audit_$timestamp.txt"
    
    try {
        "=== ACTIVE DIRECTORY DOMAIN SERVICES AUDIT ===" | Out-File -FilePath $outputFile
        "Date: $(Get-Date)" | Out-File -FilePath $outputFile -Append
        "Server: $env:COMPUTERNAME" | Out-File -FilePath $outputFile -Append
        "" | Out-File -FilePath $outputFile -Append
        
        # Check ADDS role
        $addsRole = Get-WindowsFeature -Name AD-Domain-Services -ErrorAction SilentlyContinue
        if ($addsRole -and $addsRole.InstallState -eq "Installed") {
            "✓ ADDS role installed" | Out-File -FilePath $outputFile -Append
            
            # Domain information
            $domain = Get-ADDomain -ErrorAction SilentlyContinue
            if ($domain) {
                "Domain: $($domain.DNSRoot)" | Out-File -FilePath $outputFile -Append
                "Domain Mode: $($domain.DomainMode)" | Out-File -FilePath $outputFile -Append
                "Forest Mode: $($domain.Forest)" | Out-File -FilePath $outputFile -Append
            }
            
            # Domain controllers
            $dcs = Get-ADDomainController -Filter * -ErrorAction SilentlyContinue
            if ($dcs) {
                "Domain Controllers found: $($dcs.Count)" | Out-File -FilePath $outputFile -Append
                foreach ($dc in $dcs) {
                    "  - $($dc.Name) ($($dc.Site))" | Out-File -FilePath $outputFile -Append
                }
            }
            
            # FSMO roles
            $fsmo = Get-ADForest -ErrorAction SilentlyContinue
            if ($fsmo) {
                "FSMO Roles:" | Out-File -FilePath $outputFile -Append
                "  - Schema Master: $($fsmo.SchemaMaster)" | Out-File -FilePath $outputFile -Append
                "  - Domain Naming Master: $($fsmo.DomainNamingMaster)" | Out-File -FilePath $outputFile -Append
            }
            
        } else {
            "✗ ADDS role not installed" | Out-File -FilePath $outputFile -Append
        }
        
        # Check Active Directory Web Services
        $adws = Get-Service -Name ADWS -ErrorAction SilentlyContinue
        if ($adws) {
            "AD Web Services: $($adws.Status)" | Out-File -FilePath $outputFile -Append
        }
        
        Write-Host "ADDS audit completed. Results saved to: $outputFile" -ForegroundColor Green
    }
    catch {
        Write-Host "Error during ADDS audit: $_" -ForegroundColor Red
    }
}

# Function for DNS audit
function Start-DNSAudit {
    Write-Host "Starting DNS audit..." -ForegroundColor Yellow
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $outputFile = "$OutputPath\DNS_Audit_$timestamp.txt"
    
    try {
        "=== DNS AUDIT ===" | Out-File -FilePath $outputFile
        "Date: $(Get-Date)" | Out-File -FilePath $outputFile -Append
        "Server: $env:COMPUTERNAME" | Out-File -FilePath $outputFile -Append
        "" | Out-File -FilePath $outputFile -Append
        
        # Check DNS service
        $dnsService = Get-Service -Name DNS -ErrorAction SilentlyContinue
        if ($dnsService) {
            "✓ DNS Service: $($dnsService.Status)" | Out-File -FilePath $outputFile -Append
            
            # DNS zones
            if (Get-Command Get-DnsServerZone -ErrorAction SilentlyContinue) {
                $zones = Get-DnsServerZone -ErrorAction SilentlyContinue
                if ($zones) {
                    "DNS Zones configured: $($zones.Count)" | Out-File -FilePath $outputFile -Append
                    foreach ($zone in $zones) {
                        "  - $($zone.ZoneName) ($($zone.ZoneType))" | Out-File -FilePath $outputFile -Append
                    }
                }
            }
            
            # DNS forwarders
            if (Get-Command Get-DnsServerForwarder -ErrorAction SilentlyContinue) {
                $forwarders = Get-DnsServerForwarder -ErrorAction SilentlyContinue
                if ($forwarders.IPAddress) {
                    "DNS Forwarders: $($forwarders.IPAddress -join ', ')" | Out-File -FilePath $outputFile -Append
                }
            }
            
        } else {
            "✗ DNS service not found" | Out-File -FilePath $outputFile -Append
        }
        
        # Check DNS client settings
        $dnsClient = Get-DnsClientServerAddress -ErrorAction SilentlyContinue
        if ($dnsClient) {
            "DNS Client Configuration:" | Out-File -FilePath $outputFile -Append
            foreach ($adapter in $dnsClient) {
                if ($adapter.ServerAddresses) {
                    "  - $($adapter.InterfaceAlias): $($adapter.ServerAddresses -join ', ')" | Out-File -FilePath $outputFile -Append
                }
            }
        }
        
        Write-Host "DNS audit completed. Results saved to: $outputFile" -ForegroundColor Green
    }
    catch {
        Write-Host "Error during DNS audit: $_" -ForegroundColor Red
    }
}

# Function for RDS audit
function Start-RDSAudit {
    Write-Host "Starting RDS audit..." -ForegroundColor Yellow
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $outputFile = "$OutputPath\RDS_Audit_$timestamp.txt"
    
    try {
        "=== REMOTE DESKTOP SERVICES AUDIT ===" | Out-File -FilePath $outputFile
        "Date: $(Get-Date)" | Out-File -FilePath $outputFile -Append
        "Server: $env:COMPUTERNAME" | Out-File -FilePath $outputFile -Append
        "" | Out-File -FilePath $outputFile -Append
        
        # Check RDS roles
        $rdsRoles = Get-WindowsFeature -Name RDS* | Where-Object {$_.InstallState -eq "Installed"}
        if ($rdsRoles) {
            "✓ RDS roles installed:" | Out-File -FilePath $outputFile -Append
            $rdsRoles | ForEach-Object { "  - $($_.DisplayName)" | Out-File -FilePath $outputFile -Append }
        } else {
            "✗ No RDS roles installed" | Out-File -FilePath $outputFile -Append
        }
        
        # Check Terminal Services
        $termService = Get-Service -Name TermService -ErrorAction SilentlyContinue
        if ($termService) {
            "Terminal Services: $($termService.Status)" | Out-File -FilePath $outputFile -Append
        }
        
        # Check RDP configuration
        $rdpEnabled = Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -ErrorAction SilentlyContinue
        if ($rdpEnabled) {
            if ($rdpEnabled.fDenyTSConnections -eq 0) {
                "✓ RDP is enabled" | Out-File -FilePath $outputFile -Append
            } else {
                "✗ RDP is disabled" | Out-File -FilePath $outputFile -Append
            }
        }
        
        # Check RDS licensing
        if (Get-Command Get-RDLicenseConfiguration -ErrorAction SilentlyContinue) {
            $licensing = Get-RDLicenseConfiguration -ErrorAction SilentlyContinue
            if ($licensing) {
                "RDS Licensing Mode: $($licensing.Mode)" | Out-File -FilePath $outputFile -Append
            }
        }
        
        Write-Host "RDS audit completed. Results saved to: $outputFile" -ForegroundColor Green
    }
    catch {
        Write-Host "Error during RDS audit: $_" -ForegroundColor Red
    }
}

# Function for PKI audit
function Start-PKIAudit {
    Write-Host "Starting PKI audit..." -ForegroundColor Yellow
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $outputFile = "$OutputPath\PKI_Audit_$timestamp.txt"
    
    try {
        "=== PUBLIC KEY INFRASTRUCTURE AUDIT ===" | Out-File -FilePath $outputFile
        "Date: $(Get-Date)" | Out-File -FilePath $outputFile -Append
        "Server: $env:COMPUTERNAME" | Out-File -FilePath $outputFile -Append
        "" | Out-File -FilePath $outputFile -Append
        
        # Check Certificate Services role
        $caRole = Get-WindowsFeature -Name ADCS-Cert-Authority -ErrorAction SilentlyContinue
        if ($caRole -and $caRole.InstallState -eq "Installed") {
            "✓ Certificate Authority role installed" | Out-File -FilePath $outputFile -Append
            
            # Certificate Services information
            $caService = Get-Service -Name CertSvc -ErrorAction SilentlyContinue
            if ($caService) {
                "Certificate Services: $($caService.Status)" | Out-File -FilePath $outputFile -Append
            }
            
            # CA configuration
            if (Get-Command Get-CAAuthorityInformationAccess -ErrorAction SilentlyContinue) {
                $caConfig = Get-CAAuthorityInformationAccess -ErrorAction SilentlyContinue
                if ($caConfig) {
                    "CA Authority Information Access configured" | Out-File -FilePath $outputFile -Append
                }
            }
            
        } else {
            "✗ Certificate Authority role not installed" | Out-File -FilePath $outputFile -Append
        }
        
        # Check other PKI roles
        $pkiRoles = Get-WindowsFeature -Name ADCS* | Where-Object {$_.InstallState -eq "Installed"}
        if ($pkiRoles) {
            "PKI roles installed:" | Out-File -FilePath $outputFile -Append
            $pkiRoles | ForEach-Object { "  - $($_.DisplayName)" | Out-File -FilePath $outputFile -Append }
        }
        
        # Check certificate store
        $certs = Get-ChildItem -Path Cert:\LocalMachine\My -ErrorAction SilentlyContinue
        if ($certs) {
            "Certificates in Personal store: $($certs.Count)" | Out-File -FilePath $outputFile -Append
        }
        
        Write-Host "PKI audit completed. Results saved to: $outputFile" -ForegroundColor Green
    }
    catch {
        Write-Host "Error during PKI audit: $_" -ForegroundColor Red
    }
}

# Function for DHCP audit
function Start-DHCPAudit {
    Write-Host "Starting DHCP audit..." -ForegroundColor Yellow
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $outputFile = "$OutputPath\DHCP_Audit_$timestamp.txt"
    
    try {
        "=== DHCP AUDIT ===" | Out-File -FilePath $outputFile
        "Date: $(Get-Date)" | Out-File -FilePath $outputFile -Append
        "Server: $env:COMPUTERNAME" | Out-File -FilePath $outputFile -Append
        "" | Out-File -FilePath $outputFile -Append
        
        # Check DHCP service
        $dhcpService = Get-Service -Name DHCPServer -ErrorAction SilentlyContinue
        if ($dhcpService) {
            "✓ DHCP Service: $($dhcpService.Status)" | Out-File -FilePath $outputFile -Append
            
            # DHCP scopes
            if (Get-Command Get-DhcpServerv4Scope -ErrorAction SilentlyContinue) {
                $scopes = Get-DhcpServerv4Scope -ErrorAction SilentlyContinue
                if ($scopes) {
                    "DHCP Scopes configured: $($scopes.Count)" | Out-File -FilePath $outputFile -Append
                    foreach ($scope in $scopes) {
                        "  - $($scope.Name): $($scope.StartRange) - $($scope.EndRange) (State: $($scope.State))" | Out-File -FilePath $outputFile -Append
                    }
                }
            }
            
            # DHCP reservations
            if (Get-Command Get-DhcpServerv4Reservation -ErrorAction SilentlyContinue) {
                $reservations = Get-DhcpServerv4Reservation -ErrorAction SilentlyContinue
                if ($reservations) {
                    "DHCP Reservations: $($reservations.Count)" | Out-File -FilePath $outputFile -Append
                }
            }
            
            # DHCP server options
            if (Get-Command Get-DhcpServerv4OptionValue -ErrorAction SilentlyContinue) {
                $options = Get-DhcpServerv4OptionValue -ErrorAction SilentlyContinue
                if ($options) {
                    "DHCP Server Options configured: $($options.Count)" | Out-File -FilePath $outputFile -Append
                }
            }
            
        } else {
            "✗ DHCP service not found" | Out-File -FilePath $outputFile -Append
        }
        
        Write-Host "DHCP audit completed. Results saved to: $outputFile" -ForegroundColor Green
    }
    catch {
        Write-Host "Error during DHCP audit: $_" -ForegroundColor Red
    }
}

# Function for complete audit
function Start-CompleteAudit {
    Write-Host "Starting complete audit..." -ForegroundColor Yellow
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $summaryFile = "$OutputPath\Complete_Audit_Summary_$timestamp.txt"
    
    "=== COMPLETE AUDIT SUMMARY ===" | Out-File -FilePath $summaryFile
    "Date: $(Get-Date)" | Out-File -FilePath $summaryFile -Append
    "Server: $env:COMPUTERNAME" | Out-File -FilePath $summaryFile -Append
    "" | Out-File -FilePath $summaryFile -Append
    
    Start-ADDSAudit
    Start-DNSAudit
    Start-RDSAudit
    Start-PKIAudit
    Start-DHCPAudit
    
    "Complete audit finished. Individual reports generated." | Out-File -FilePath $summaryFile -Append
    Write-Host "Complete audit finished! Summary saved to: $summaryFile" -ForegroundColor Green
}

# Function to view audit reports
function Show-AuditReports {
    Show-Header
    Write-Host "Available audit reports:" -ForegroundColor White
    Write-Host ""
    
    $reports = Get-ChildItem -Path $OutputPath -Filter "*.txt" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    
    if ($reports) {
        for ($i = 0; $i -lt $reports.Count -and $i -lt 10; $i++) {
            $report = $reports[$i]
            Write-Host "$($i + 1). $($report.Name) - $($report.LastWriteTime)" -ForegroundColor Gray
        }
        Write-Host ""
        Write-Host "Enter report number to view (1-$([Math]::Min(10, $reports.Count))), or 0 to return:" -ForegroundColor White
        
        $choice = Read-Host "Your choice"
        
        if ($choice -gt 0 -and $choice -le $reports.Count) {
            $selectedReport = $reports[$choice - 1]
            Show-Header
            Write-Host "=== $($selectedReport.Name) ===" -ForegroundColor Yellow
            Write-Host ""
            Get-Content $selectedReport.FullName | Write-Host
            Write-Host ""
            Read-Host "Press Enter to continue..."
        }
    } else {
        Write-Host "No audit reports found." -ForegroundColor Yellow
        Read-Host "Press Enter to continue..."
    }
}

# Function for configuration
function Show-Configuration {
    Show-Header
    Write-Host "Current configuration:" -ForegroundColor White
    Write-Host "Output directory: $OutputPath" -ForegroundColor Gray
    Write-Host "Script name: $ScriptName" -ForegroundColor Gray
    Write-Host ""
    Write-Host "1. Change output directory"
    Write-Host "2. Open output directory"
    Write-Host "3. Clear all audit reports"
    Write-Host "0. Return to main menu"
    
    $choice = Read-Host "Your choice"
    
    switch ($choice) {
        "1" {
            $newPath = Read-Host "New output directory path"
            if (Test-Path $newPath) {
                $script:OutputPath = $newPath
                Write-Host "Output directory changed to: $newPath" -ForegroundColor Green
            } else {
                Write-Host "Directory does not exist! Creating..." -ForegroundColor Yellow
                try {
                    New-Item -ItemType Directory -Path $newPath -Force | Out-Null
                    $script:OutputPath = $newPath
                    Write-Host "Directory created and set as output path." -ForegroundColor Green
                } catch {
                    Write-Host "Failed to create directory!" -ForegroundColor Red
                }
            }
            Start-Sleep 2
        }
        "2" {
            if (Test-Path $OutputPath) {
                Invoke-Item $OutputPath
            } else {
                Write-Host "Output directory does not exist!" -ForegroundColor Red
                Start-Sleep 2
            }
        }
        "3" {
            $confirm = Read-Host "Are you sure you want to delete all audit reports? (y/N)"
            if ($confirm -eq 'y' -or $confirm -eq 'Y') {
                Get-ChildItem -Path $OutputPath -Filter "*.txt" | Remove-Item -Force
                Write-Host "All audit reports deleted." -ForegroundColor Green
            }
            Start-Sleep 2
        }
        "0" { return }
    }
}

# Main function
function Start-WinAudit {
    Initialize-AuditEnvironment
    
    do {
        Show-MainMenu
        $choice = Read-Host "Enter your choice (0-8)"
        
        switch ($choice) {
            "1" { Start-ADDSAudit; Read-Host "Press Enter to continue..." }
            "2" { Start-DNSAudit; Read-Host "Press Enter to continue..." }
            "3" { Start-RDSAudit; Read-Host "Press Enter to continue..." }
            "4" { Start-PKIAudit; Read-Host "Press Enter to continue..." }
            "5" { Start-DHCPAudit; Read-Host "Press Enter to continue..." }
            "6" { Start-CompleteAudit; Read-Host "Press Enter to continue..." }
            "7" { Show-Configuration }
            "8" { Show-AuditReports }
            "0" { 
                Write-Host "Goodbye!" -ForegroundColor Green
                exit 
            }
            default { 
                Write-Host "Invalid choice!" -ForegroundColor Red
                Start-Sleep 2
            }
        }
    } while ($true)
}

# Check for administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires administrator privileges!" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    Read-Host "Press Enter to exit..."
    exit
}

# Start WinAudit
Start-WinAudit