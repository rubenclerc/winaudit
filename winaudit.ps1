# Configuration globale
$ErrorActionPreference = "SilentlyContinue"
$OutputPath = "C:\Audits\"

# Fonction pour créer le dossier de sortie
function Initialize-AuditEnvironment {
    if (!(Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
}

# Fonction pour afficher le header
function Show-Header {
    Clear-Host
    Write-Host "=======================================" -ForegroundColor Cyan
    Write-Host "   AUDIT DE SERVEURS WINDOWS v1.0     " -ForegroundColor Yellow
    Write-Host "=======================================" -ForegroundColor Cyan
    Write-Host ""
}

# Fonction pour afficher le menu principal
function Show-MainMenu {
    Show-Header
    Write-Host "Sélectionnez le type d'audit à effectuer :" -ForegroundColor White
    Write-Host ""
    Write-Host "1. ADDS (Active Directory Domain Services)" -ForegroundColor Green
    Write-Host "2. DNS (Domain Name System)" -ForegroundColor Green
    Write-Host "3. RDS (Remote Desktop Services)" -ForegroundColor Green
    Write-Host "4. PKI (Public Key Infrastructure)" -ForegroundColor Green
    Write-Host "5. DHCP (Dynamic Host Configuration Protocol)" -ForegroundColor Green
    Write-Host ""
    Write-Host "6. Audit complet (tous les services)" -ForegroundColor Yellow
    Write-Host "7. Configuration et paramètres" -ForegroundColor Magenta
    Write-Host "0. Quitter" -ForegroundColor Red
    Write-Host ""
    Write-Host "=======================================" -ForegroundColor Cyan
}

# Fonction d'audit ADDS
function Start-ADDSAudit {
    Write-Host "Démarrage de l'audit ADDS..." -ForegroundColor Yellow
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $outputFile = "$OutputPath\ADDS_Audit_$timestamp.txt"
    
    try {
        "=== AUDIT ACTIVE DIRECTORY DOMAIN SERVICES ===" | Out-File -FilePath $outputFile
        "Date: $(Get-Date)" | Out-File -FilePath $outputFile -Append
        "" | Out-File -FilePath $outputFile -Append
        
        # Vérification du rôle ADDS
        if (Get-WindowsFeature -Name AD-Domain-Services | Where-Object {$_.InstallState -eq "Installed"}) {
            "✓ Rôle ADDS installé" | Out-File -FilePath $outputFile -Append
            
            # Informations sur le domaine
            $domain = Get-ADDomain -ErrorAction SilentlyContinue
            if ($domain) {
                "Domaine: $($domain.DNSRoot)" | Out-File -FilePath $outputFile -Append
                "Niveau fonctionnel: $($domain.DomainMode)" | Out-File -FilePath $outputFile -Append
            }
            
            # Contrôleurs de domaine
            $dcs = Get-ADDomainController -Filter * -ErrorAction SilentlyContinue
            "Contrôleurs de domaine trouvés: $($dcs.Count)" | Out-File -FilePath $outputFile -Append
            
        } else {
            "✗ Rôle ADDS non installé" | Out-File -FilePath $outputFile -Append
        }
        
        Write-Host "Audit ADDS terminé. Résultats sauvegardés dans: $outputFile" -ForegroundColor Green
    }
    catch {
        Write-Host "Erreur lors de l'audit ADDS: $_" -ForegroundColor Red
    }
}

# Fonction d'audit DNS
function Start-DNSAudit {
    Write-Host "Démarrage de l'audit DNS..." -ForegroundColor Yellow
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $outputFile = "$OutputPath\DNS_Audit_$timestamp.txt"
    
    try {
        "=== AUDIT DNS ===" | Out-File -FilePath $outputFile
        "Date: $(Get-Date)" | Out-File -FilePath $outputFile -Append
        "" | Out-File -FilePath $outputFile -Append
        
        # Vérification du service DNS
        $dnsService = Get-Service -Name DNS -ErrorAction SilentlyContinue
        if ($dnsService) {
            "✓ Service DNS: $($dnsService.Status)" | Out-File -FilePath $outputFile -Append
            
            # Zones DNS
            if (Get-Command Get-DnsServerZone -ErrorAction SilentlyContinue) {
                $zones = Get-DnsServerZone -ErrorAction SilentlyContinue
                "Zones DNS configurées: $($zones.Count)" | Out-File -FilePath $outputFile -Append
            }
        } else {
            "✗ Service DNS non trouvé" | Out-File -FilePath $outputFile -Append
        }
        
        Write-Host "Audit DNS terminé. Résultats sauvegardés dans: $outputFile" -ForegroundColor Green
    }
    catch {
        Write-Host "Erreur lors de l'audit DNS: $_" -ForegroundColor Red
    }
}

# Fonction d'audit RDS
function Start-RDSAudit {
    Write-Host "Démarrage de l'audit RDS..." -ForegroundColor Yellow
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $outputFile = "$OutputPath\RDS_Audit_$timestamp.txt"
    
    try {
        "=== AUDIT REMOTE DESKTOP SERVICES ===" | Out-File -FilePath $outputFile
        "Date: $(Get-Date)" | Out-File -FilePath $outputFile -Append
        "" | Out-File -FilePath $outputFile -Append
        
        # Vérification des rôles RDS
        $rdsRoles = Get-WindowsFeature -Name RDS* | Where-Object {$_.InstallState -eq "Installed"}
        if ($rdsRoles) {
            "✓ Rôles RDS installés:" | Out-File -FilePath $outputFile -Append
            $rdsRoles | ForEach-Object { "  - $($_.DisplayName)" | Out-File -FilePath $outputFile -Append }
        } else {
            "✗ Aucun rôle RDS installé" | Out-File -FilePath $outputFile -Append
        }
        
        Write-Host "Audit RDS terminé. Résultats sauvegardés dans: $outputFile" -ForegroundColor Green
    }
    catch {
        Write-Host "Erreur lors de l'audit RDS: $_" -ForegroundColor Red
    }
}

# Fonction d'audit PKI
function Start-PKIAudit {
    Write-Host "Démarrage de l'audit PKI..." -ForegroundColor Yellow
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $outputFile = "$OutputPath\PKI_Audit_$timestamp.txt"
    
    try {
        "=== AUDIT PKI ===" | Out-File -FilePath $outputFile
        "Date: $(Get-Date)" | Out-File -FilePath $outputFile -Append
        "" | Out-File -FilePath $outputFile -Append
        
        # Vérification du rôle Certificate Services
        $caRole = Get-WindowsFeature -Name ADCS-Cert-Authority | Where-Object {$_.InstallState -eq "Installed"}
        if ($caRole) {
            "✓ Rôle Certificate Authority installé" | Out-File -FilePath $outputFile -Append
            
            # Informations sur la CA
            if (Get-Command Get-CAAuthorityInformationAccess -ErrorAction SilentlyContinue) {
                $caInfo = Get-CAAuthorityInformationAccess -ErrorAction SilentlyContinue
                "CA configurée" | Out-File -FilePath $outputFile -Append
            }
        } else {
            "✗ Rôle Certificate Authority non installé" | Out-File -FilePath $outputFile -Append
        }
        
        Write-Host "Audit PKI terminé. Résultats sauvegardés dans: $outputFile" -ForegroundColor Green
    }
    catch {
        Write-Host "Erreur lors de l'audit PKI: $_" -ForegroundColor Red
    }
}

# Fonction d'audit DHCP
function Start-DHCPAudit {
    Write-Host "Démarrage de l'audit DHCP..." -ForegroundColor Yellow
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $outputFile = "$OutputPath\DHCP_Audit_$timestamp.txt"
    
    try {
        "=== AUDIT DHCP ===" | Out-File -FilePath $outputFile
        "Date: $(Get-Date)" | Out-File -FilePath $outputFile -Append
        "" | Out-File -FilePath $outputFile -Append
        
        # Vérification du service DHCP
        $dhcpService = Get-Service -Name DHCPServer -ErrorAction SilentlyContinue
        if ($dhcpService) {
            "✓ Service DHCP: $($dhcpService.Status)" | Out-File -FilePath $outputFile -Append
            
            # Scopes DHCP
            if (Get-Command Get-DhcpServerv4Scope -ErrorAction SilentlyContinue) {
                $scopes = Get-DhcpServerv4Scope -ErrorAction SilentlyContinue
                "Scopes DHCP configurés: $($scopes.Count)" | Out-File -FilePath $outputFile -Append
            }
        } else {
            "✗ Service DHCP non trouvé" | Out-File -FilePath $outputFile -Append
        }
        
        Write-Host "Audit DHCP terminé. Résultats sauvegardés dans: $outputFile" -ForegroundColor Green
    }
    catch {
        Write-Host "Erreur lors de l'audit DHCP: $_" -ForegroundColor Red
    }
}

# Fonction pour audit complet
function Start-CompleteAudit {
    Write-Host "Démarrage de l'audit complet..." -ForegroundColor Yellow
    Start-ADDSAudit
    Start-DNSAudit
    Start-RDSAudit
    Start-PKIAudit
    Start-DHCPAudit
    Write-Host "Audit complet terminé!" -ForegroundColor Green
}

# Fonction de configuration
function Show-Configuration {
    Show-Header
    Write-Host "Configuration actuelle:" -ForegroundColor White
    Write-Host "Dossier de sortie: $OutputPath" -ForegroundColor Gray
    Write-Host ""
    Write-Host "1. Changer le dossier de sortie"
    Write-Host "2. Retour au menu principal"
    
    $choice = Read-Host "Votre choix"
    
    switch ($choice) {
        "1" {
            $newPath = Read-Host "Nouveau dossier de sortie"
            if (Test-Path $newPath) {
                $script:OutputPath = $newPath
                Write-Host "Dossier de sortie modifié: $newPath" -ForegroundColor Green
            } else {
                Write-Host "Dossier inexistant!" -ForegroundColor Red
            }
            Start-Sleep 2
        }
        "2" { return }
    }
}

# Fonction principale
function Start-AuditProgram {
    Initialize-AuditEnvironment
    
    do {
        Show-MainMenu
        $choice = Read-Host "Entrez votre choix (0-7)"
        
        switch ($choice) {
            "1" { Start-ADDSAudit; Read-Host "Appuyez sur Entrée pour continuer..." }
            "2" { Start-DNSAudit; Read-Host "Appuyez sur Entrée pour continuer..." }
            "3" { Start-RDSAudit; Read-Host "Appuyez sur Entrée pour continuer..." }
            "4" { Start-PKIAudit; Read-Host "Appuyez sur Entrée pour continuer..." }
            "5" { Start-DHCPAudit; Read-Host "Appuyez sur Entrée pour continuer..." }
            "6" { Start-CompleteAudit; Read-Host "Appuyez sur Entrée pour continuer..." }
            "7" { Show-Configuration }
            "0" { 
                Write-Host "Au revoir!" -ForegroundColor Green
                exit 
            }
            default { 
                Write-Host "Choix invalide!" -ForegroundColor Red
                Start-Sleep 2
            }
        }
    } while ($true)
}

# Vérification des privilèges administrateur
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Ce script nécessite des privilèges administrateur!" -ForegroundColor Red
    Write-Host "Veuillez relancer PowerShell en tant qu'administrateur." -ForegroundColor Yellow
    Read-Host "Appuyez sur Entrée pour quitter..."
    exit
}

# Démarrage du programme
Start-AuditProgram
