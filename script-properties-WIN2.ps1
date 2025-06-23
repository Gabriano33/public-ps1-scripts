# Define file paths
$propertiesFile = "standalone.properties"
$batchFile = "standalone.conf.bat_base_WIN"
$baseCliFile = "base-setup.cli"  # Base CLI file
$cliFile = "akn-setup.cli"
$outputEnvFile = "config_PROVA_WIN_OK2.env"

# Step 1: Read all variables from standalone.properties in order
Write-Host "Step 1: Reading variables from $propertiesFile"
$properties = [ordered]@{}  # Use ordered dictionary to maintain order
$propertiesOrder = @()      # Track the order of properties
$customProperties = @()

# Check if the file exists
if (-not (Test-Path $propertiesFile)) {
    Write-Host "ERROR: Properties file not found: $propertiesFile" -ForegroundColor Red
    exit 1
}

# Read and process the properties file - with more debugging
Get-Content $propertiesFile | ForEach-Object {
    Write-Host "Processing line: $_" -ForegroundColor Gray

    # Skip comments
    if ($_ -match "^\s*#") {
        Write-Host "  Skipping comment line" -ForegroundColor DarkGray
        return
    }

    if ($_ -match "^([^=]+)=(.*)$") {
        $varName = $matches[1].Trim()
        $varValue = $matches[2].Trim()

        Write-Host "  Found property: $varName = $varValue" -ForegroundColor Gray

        # Check if this is a custom property
        if ($varName -like "custom_properties_*") {
            Write-Host "  This is a custom property" -ForegroundColor Yellow

            # Se vuota -> spazio
            if ([string]::IsNullOrEmpty($varValue)) {
                Write-Host "  Empty custom property, setting to space" -ForegroundColor Yellow
                $properties[$varName] = '" "'
                $propertiesOrder += $varName
            }
            # Se inizia con -agent o contiene -agentlib -> ignorare del tutto
            elseif ($varValue -match "^-agent" -or $varValue -match "^-agentlib") {
                Write-Host "  Ignoring property starting with -agent/-agentlib: $varValue" -ForegroundColor Yellow
                return
            }
            # Se contiene -D -> elaborare per estrazione JavaProp
            elseif ($varValue -match "-D") {
                Write-Host "  Contains -D flags, extracting Java properties..." -ForegroundColor Yellow
                $properties[$varName] = $varValue
                $propertiesOrder += $varName

                $parts = $varValue -split "-D"
                foreach ($part in $parts) {
                    if ($part -and $part -match "([^=]+)=([^\s]+)") {
                        $javaPropName = $matches[1].Trim()
                        $javaPropValue = $matches[2].Trim()

                        Write-Host "  Extracted: $javaPropName = $javaPropValue" -ForegroundColor Green

                        $upperJavaPropName = $javaPropName.ToUpper()
                        $customProperties += "$upperJavaPropName=$javaPropValue"

                        Write-Host "  Added to custom properties list: $upperJavaPropName=$javaPropValue" -ForegroundColor Green
                    }
                }
            }
            # Altrimenti, salva normalmente
            else {
                $properties[$varName] = $varValue
                $propertiesOrder += $varName
            }
        }
        else {
            $properties[$varName] = $varValue
            $propertiesOrder += $varName
        }
    }
}

# ... REST OF YOUR SCRIPT REMAINS UNCHANGED ...


# Debug output of custom properties
Write-Host "`n--- Extracted Custom Properties (Total: $($customProperties.Count)) ---" -ForegroundColor Cyan
if ($customProperties.Count -eq 0) {
    Write-Host "WARNING: No custom properties were extracted!" -ForegroundColor Yellow
} else {
    foreach ($prop in $customProperties) {
        Write-Host "Custom property: $prop" -ForegroundColor Cyan
    }
}

# Step 2 & 3: Find where these variables are used in the batch file and extract Java property names (standalone.conf.bat_base_WIN)
Write-Host "`nStep 2 & 3: Finding variables in $batchFile and extracting Java properties"
$javaProps = @{}

# Check if batch file exists
if (-not (Test-Path $batchFile)) {
    Write-Host "WARNING: Batch file not found: $batchFile. Skipping Java property mapping." -ForegroundColor Yellow
} else {
    $batchContent = Get-Content $batchFile

    # NEW: Special handling for log_path_xml - Extract exact property name from batch file
    $logPathXmlConfigName = $null
    foreach ($line in $batchContent) {
        if ($line -match "-D(log4j2\.configurationFile)=file://log_path_xml") {
            $logPathXmlConfigName = $matches[1]
            Write-Host "Found special log_path_xml reference in batch file" -ForegroundColor Magenta
            Write-Host "Extracted exact config name: $logPathXmlConfigName" -ForegroundColor Magenta
            
            # Store this special value for later use
            $properties["log_path_xml_special"] = $logPathXmlConfigName
            break
        }
    }
    
    if (-not $logPathXmlConfigName) {
        Write-Host "WARNING: Special log_path_xml reference not found in batch file" -ForegroundColor Yellow
    }

    foreach ($prop in $properties.Keys) {
        # Skip log_path_xml as we've already processed it specially
        if ($prop -eq "log_path_xml" -and $logPathXmlConfigName) {
            continue
        }
        
        # Skip custom_properties
        if ($prop -like "custom_properties_*") {
            continue
        }
        
        $found = $false
        
        # Process each line in the batch file
        foreach ($line in $batchContent) {
            # Check if the line contains our property and a -D flag
            if ($line -match "-D([^=]+)=.*$prop" -or $line -match "=\s*$prop\s*$") {
                try {
                    if ($matches[1]) {
                        $javaProp = $matches[1].Trim()
                        $javaProps[$prop] = $javaProp
                        Write-Host "For $prop found Java property: $javaProp"
                        $found = $true
                        break
                    }
                } catch {
                    # In case there's no capturing group in the match
                }
            }
        }
        
        # If we didn't find a Java property, use the original name
        if (-not $found) {
            Write-Host "For $prop no Java property found in batch file"
            # We'll keep checking in the CLI files
        }
    }
}

# NEW Step: Search for Java properties in the base-setup.cli file
Write-Host "`nSearching for Java properties in $baseCliFile"

# Check if base CLI file exists
if (-not (Test-Path $baseCliFile)) {
    Write-Host "WARNING: Base CLI file not found: $baseCliFile. Skipping this file." -ForegroundColor Yellow
} else {
    $baseCliContent = Get-Content $baseCliFile

    foreach ($prop in $properties.Keys) {
        # Skip if we already found a mapping for this property
        if ($javaProps.ContainsKey($prop) -and $javaProps[$prop] -ne "") {
            continue
        }
        
        # Skip log_path_xml as we've already processed it specially
        if ($prop -eq "log_path_xml" -and $logPathXmlConfigName) {
            continue
        }
        
        # Skip custom_properties
        if ($prop -like "custom_properties_*") {
            continue
        }
        
        $found = $false
        
        # Process each line in the base CLI file
        foreach ($line in $baseCliContent) {
            # Look for system-property definitions that reference this property
            if ($line -match "/system-property=([^:]+):add\(value=.*$prop.*\)") {
                $javaProp = $matches[1].Trim()
                $javaProps[$prop] = $javaProp
                Write-Host "For $prop found Java property in base-setup.cli: $javaProp" -ForegroundColor Cyan
                $found = $true
                break
            }
        }
        
        # If still not found, we'll continue to the next file
        if (-not $found) {
            Write-Host "For $prop no Java property found in base-setup.cli" -ForegroundColor Gray
        }
    }
}

# Step 4: Search for Java properties in the main CLI file and extract environment variable names
Write-Host "`nStep 4: Finding Java properties in $cliFile and extracting environment variables"

# First, check for properties not yet found after checking the batch file and base-setup.cli
foreach ($prop in $properties.Keys) {
    # Skip custom_properties
    if ($prop -like "custom_properties_*") {
        continue
    }
    
    # Skip if we already found a mapping for this property
    if (-not $javaProps.ContainsKey($prop) -or $javaProps[$prop] -eq "") {
        Write-Host "Checking $cliFile for property: $prop that wasn't found earlier" -ForegroundColor Yellow
        
        # Skip our special virtual property and log_path_xml
        if ($prop -eq "log_path_xml_special" -or ($prop -eq "log_path_xml" -and $logPathXmlConfigName)) {
            continue
        }
        
        # Check if CLI file exists
        if (Test-Path $cliFile) {
            $cliContent = Get-Content $cliFile
            $found = $false
            
            # Process each line in the CLI file
            foreach ($line in $cliContent) {
                # Look for system-property definitions that reference this property
                if ($line -match "/system-property=([^:]+):add\(value=.*$prop.*\)") {
                    $javaProp = $matches[1].Trim()
                    $javaProps[$prop] = $javaProp
                    Write-Host "For $prop found Java property in akn-setup.cli: $javaProp" -ForegroundColor Cyan
                    $found = $true
                    break
                }
            }
            
            # If we still didn't find a mapping, use the original name
            if (-not $found) {
                Write-Host "For $prop no Java property found in any files, using original name" -ForegroundColor Yellow
                $javaProps[$prop] = ""  # Use empty string to indicate no mapping found
            }
        }
    }
}

$mappings = @{}

# NEW: Extract actual log file path from CLI file for log4j2.configurationFile
$actualLogPath = $null
if (Test-Path $cliFile) {
    $cliContent = Get-Content $cliFile
    foreach ($line in $cliContent) {
        if ($line -match "/system-property=log4j2\.configurationFile:add\(value=\$\{([^:}]+)(?::([^}]+))?\}\)") {
            $envVar = $matches[1]
            Write-Host "Found log4j2.configurationFile in CLI with env var: $envVar" -ForegroundColor Magenta

            # Now search for the actual file path value from the CLI file and extract just the path part
            foreach ($cliLine in $cliContent) {
                if ($cliLine -match "/system-property=log4j2\.configurationFile:add\(value=\$\{[^:}]+:file:(/+[^}]+)\}\)") {
                    # Extract just the path part without the file: prefix
                    $actualLogPath = $matches[1]
                    Write-Host "Found actual log path from CLI: $actualLogPath" -ForegroundColor Magenta
                    break
                }
            }
            break
        }
    }

    if (-not $actualLogPath) {
        Write-Host "WARNING: Could not find actual log path in CLI file" -ForegroundColor Yellow
    }

    # Now process the CLI files to find environment variable mappings
    foreach ($origVar in $properties.Keys) {
        # Skip our special virtual property
        if ($origVar -eq "log_path_xml_special") { continue }
        
        # Skip custom_properties
        if ($origVar -like "custom_properties_*") { continue }
        
        $javaProp = $javaProps[$origVar]
        $found = $false
        
        if ($javaProp -and $javaProp -ne "") {
            # Process each line in the CLI file
            foreach ($line in $cliContent) {
                # Check if the line contains our Java property
                if ($line -match "/system-property=$javaProp`:add\(value=\$\{([^:}]+)(?::([^}]+))?\}\)") {
                    $envVar = $matches[1]
                    $defaultValue = if ($matches[2]) { $matches[2] } else { "" }
                    
                    $mappings[$origVar] = @{
                        JavaProp = $javaProp
                        EnvVar = $envVar
                        DefaultValue = $defaultValue
                    }
                    
                    Write-Host "For $origVar (Java prop: $javaProp) found ENV var in akn-setup.cli: $envVar with default: $defaultValue"
                    $found = $true
                    break
                }
            }
        }
        
        # If not found in akn-setup.cli, check base-setup.cli for mappings
        if (-not $found -and (Test-Path $baseCliFile)) {
            $baseCliContent = Get-Content $baseCliFile
            
            if ($javaProp -and $javaProp -ne "") {
                # Process each line in the base CLI file
                foreach ($line in $baseCliContent) {
                    # Check if the line contains our Java property
                    if ($line -match "/system-property=$javaProp`:add\(value=\$\{([^:}]+)(?::([^}]+))?\}\)") {
                        $envVar = $matches[1]
                        $defaultValue = if ($matches[2]) { $matches[2] } else { "" }
                        
                        $mappings[$origVar] = @{
                            JavaProp = $javaProp
                            EnvVar = $envVar
                            DefaultValue = $defaultValue
                        }
                        
                        Write-Host "For $origVar (Java prop: $javaProp) found ENV var in base-setup.cli: $envVar with default: $defaultValue" -ForegroundColor Cyan
                        $found = $true
                        break
                    }
                }
            }
        }
        
        # If no mapping found, create a default one
        if (-not $found) {
            # Create a default ENV var name based on pattern analysis
            # Convert to uppercase and use standard naming convention
            $defaultEnvVar = $origVar.ToUpper()
            $mappings[$origVar] = @{
                JavaProp = $javaProp
                EnvVar = $defaultEnvVar
                DefaultValue = ""
            }
            Write-Host "For $origVar no ENV var mapping found in any CLI files, using $defaultEnvVar"
        }
    }
} else {
    Write-Host "WARNING: Main CLI file not found: $cliFile. Using default environment variable mapping." -ForegroundColor Yellow
    
    # If CLI file doesn't exist, create default mappings based on property names
    foreach ($origVar in $properties.Keys) {
        # Skip our special virtual property
        if ($origVar -eq "log_path_xml_special") { continue }
        
        # Skip custom_properties
        if ($origVar -like "custom_properties_*") { continue }
        
        $javaProp = $javaProps[$origVar]
        
        # Create a default ENV var name
        $defaultEnvVar = $origVar.ToUpper()
        $mappings[$origVar] = @{
            JavaProp = $javaProp
            EnvVar = $defaultEnvVar
            DefaultValue = ""
        }
        Write-Host "For $origVar using default ENV var mapping: $defaultEnvVar"
    }
}

# Step 5: Create config file with ALL environment variables in the original order
Write-Host "`nStep 5: Creating $outputEnvFile with ALL environment variables"
$envFileContent = "# Environment variables generated from standalone.properties`n"
$envFileContent += "# Generated on $(Get-Date)`n`n"

# Counter for variables
$varCount = 0

# Use the original property order to write the env file
foreach ($origVar in $propertiesOrder) {
    # Skip our special virtual property
    if ($origVar -eq "log_path_xml_special") { continue }
    
    $propValue = $properties[$origVar]
    
    # Special handling for custom_properties
    if ($origVar -like "custom_properties_*") {
        # If the property is empty or just a space, set a single space
        if ([string]::IsNullOrEmpty($propValue) -or $propValue -eq " ") {
            $envFileContent += "$($origVar.ToUpper())= " + "`n"
        } else {
            # For non-empty custom properties, keep original value
            $envFileContent += "$($origVar.ToUpper())=$propValue`n"
        }
        $varCount++
        Write-Host "Added custom property to env file: $($origVar.ToUpper())=$propValue"
        continue
    }
    
    # Replace quotes if they exist in the property value
    if ($propValue -match '^"(.*)"$') {
        $propValue = $matches[1]
    }
    
    # Get the environment variable name from the mapping or use the uppercase original name
    if ($mappings[$origVar] -and $mappings[$origVar].EnvVar -ne "") {
        $envVar = $mappings[$origVar].EnvVar
    } else {
        $envVar = $origVar.ToUpper()
    }
    
    # Special handling for log_path_xml - Use the actual path from CLI if available
    if ($origVar -eq "log_path_xml" -and $actualLogPath) {
        $propValue = $actualLogPath
        Write-Host "Special handling for log_path_xml: Using actual path from CLI: $propValue" -ForegroundColor Magenta
    }

    # Se la variabile inizia con un commento, ignorala completamente
    if ($propValue -match '^\s*#') {
        Write-Host "Skipping commented variable: $origVar" -ForegroundColor DarkGray
        continue
    }

$envFileContent += "$envVar=$propValue`n"

    $varCount++
    Write-Host "Added to env file: $envVar=$propValue"
}

# Step 6: Add extracted custom properties directly to the file
Write-Host "`nStep 6: Adding custom properties to the file" -ForegroundColor Cyan
if ($customProperties.Count -gt 0) {
    Write-Host "Found $($customProperties.Count) custom properties to add" -ForegroundColor Green
    
    # Join all custom properties with spaces and add to the file
    $customPropsLine = $customProperties -join " "
    $envFileContent += "`n# Extracted custom Java properties`n$customPropsLine`n"
    
    Write-Host "Added custom properties line: $customPropsLine" -ForegroundColor Green
} else {
    Write-Host "No custom properties to add" -ForegroundColor Yellow
}

# Write the env file
try {
    $envFileContent | Out-File -FilePath $outputEnvFile -Encoding utf8
    Write-Host "`nSuccessfully created environment file: $outputEnvFile" -ForegroundColor Green
    Write-Host "Regular variables: $varCount (from $($properties.Count) original properties)" -ForegroundColor Green
    Write-Host "Custom properties: $($customProperties.Count)" -ForegroundColor Green
    
    # Debug - show the first few lines of the created file
    Write-Host "`nPreview of the created file:" -ForegroundColor Cyan
    if (Test-Path $outputEnvFile) {
        Get-Content $outputEnvFile -TotalCount 20 | ForEach-Object {
            Write-Host "  $_" -ForegroundColor Gray
        }
        
        # Check specifically for custom properties in the file
        $fileContent = Get-Content $outputEnvFile -Raw
        if ($fileContent -match "# Extracted custom Java properties") {
            Write-Host "`nCustom properties section found in the file" -ForegroundColor Green
            
            # Find the section and the line after it
            $lines = Get-Content $outputEnvFile
            $foundSection = $false
            foreach ($line in $lines) {
                if ($foundSection) {
                    Write-Host "Custom properties line: $line" -ForegroundColor Green
                    break
                }
                if ($line -eq "# Extracted custom Java properties") {
                    $foundSection = $true
                }
            }
        } else {
            Write-Host "`nWARNING: Custom properties section not found in the file!" -ForegroundColor Red
        }
    } else {
        Write-Host "ERROR: File not created!" -ForegroundColor Red
    }
} catch {
    Write-Host "ERROR writing to file: $_" -ForegroundColor Red
}

# Extra check to ensure all variables were processed
$totalProps = ($properties.Keys | Where-Object { $_ -ne "log_path_xml_special" }).Count
if ($varCount -ne $totalProps) {
    Write-Host "WARNING: Number of processed variables ($varCount) doesn't match number of original properties ($totalProps)" -ForegroundColor Yellow
}